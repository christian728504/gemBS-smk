
rule mapping:
    input:
        signal="results/indexes/.continue",
        gem_index=rules.indexing.output.gem_index,
        chromsizes=rules.indexing.output.chromsizes,
        r1=get_r1,
        r2=get_r2
    output:
        mapping=directory("results/mapping/{barcode}"),
        bam="results/mapping/{barcode}/{barcode}.bam",
        bam_csi="results/mapping/{barcode}/{barcode}.bam.csi",
        md5="results/mapping/{barcode}/{barcode}.bam.md5",
        json="results/mapping/{barcode}/{barcode}.json",
        signal="results/mapping/{barcode}/.continue"
    params:
        dataset=lambda w: dataset_lookup.get(w.barcode),
        barcode=lambda w: w.barcode,
        tmpdir=config['tmpdir']
    resources:
        mapping_jobs=1,
        threads=88,
        cores=88,
        mem_mb=256000,
        slurm_extra="--cpu-freq=High --exclusive",
        tmpdir=config['tmpdir']
    # container: "docker://clarity001/gembs:latest"
    conda: "envs/gem-mapper.yml"
    log: "results/logfiles/mapping/{barcode}.log"
    shell:
        """
        exec >> {log} 2>&1

        echo "$(date): Rule started"

        OUTPUT_DIR={params.tmpdir}/{output.mapping}
        
        mkdir -p "$OUTPUT_DIR"
        cp {input.gem_index} {input.chromsizes} {input.r1} {input.r2} $OUTPUT_DIR

        echo "$(date): Copied files to /tmp"

        gem-mapper \
            --threads {resources.threads} \
            -I $OUTPUT_DIR/$(basename {input.gem_index}) \
            --i1 $OUTPUT_DIR/$(basename {input.r1}) \
            --i2 $OUTPUT_DIR/$(basename {input.r2}) \
            --paired-end-alignment \
            --report-file $OUTPUT_DIR/$(basename {output.json}) \
            --sam-read-group-header "@RG\tID:{params.dataset}\tSM:\tBC:{params.barcode}\tPU:{params.dataset}" | \
        ./workflow/rules/scripts/read_filter.py $OUTPUT_DIR/$(basename {input.chromsizes}) | \
        samtools sort -o $OUTPUT_DIR/$(basename {output.bam}) \
            -T "$OUTPUT_DIR/sort" \
            --threads {resources.threads} \
            --write-index -
        
        echo "$(date): gem-mapper completed"
        
        md5sum $OUTPUT_DIR/$(basename {output.bam}) > $OUTPUT_DIR/$(basename {output.md5})

        echo "$(date): md5sum completed"

        ./workflow/rules/scripts/make_average_coverage.py \
            --bamfile $OUTPUT_DIR/$(basename {output.bam}) \
            --chromsizes $OUTPUT_DIR/$(basename {input.chromsizes}) \
            --threads {resources.threads} \
            --gem_mapper_json $OUTPUT_DIR/$(basename {output.json})

        echo "$(date): average coverage completed"

        rm -rf $OUTPUT_DIR/$(basename {input.r1}) \
                $OUTPUT_DIR/$(basename {input.r2}) \
                $OUTPUT_DIR/$(basename {input.gem_index}) \
                $OUTPUT_DIR/$(basename {input.chromsizes})
        cp -t {output.mapping} "$OUTPUT_DIR"/* 
        rm -rf "$OUTPUT_DIR"
        
        echo "$(date): Rule finished"
        touch {output.signal}
        """