rule gembs_extract:
    input:
        indexes_singal="results/indexes/.continue",
        mapping_signal="results/mapping/{barcode}/.continue",
        calls_signal="results/calls/{barcode}/.continue",
        bcf="results/calls/{barcode}/{barcode}.bcf",
        bcf_csi="results/calls/{barcode}/{barcode}.bcf.csi",
        chromsizes=rules.indexing.output.chromsizes,
    output:
        signal="results/extract/{barcode}/.continue",
        cpgfile="results/extract/{barcode}/{barcode}_cpg.txt.gz",
        noncpgfile="results/extract/{barcode}/{barcode}_non_cpg.txt.gz",
        bed_gz=[
            "results/extract/{barcode}/{barcode}_chg.bed.gz",
            "results/extract/{barcode}/{barcode}_chh.bed.gz",
            "results/extract/{barcode}/{barcode}_cpg.bed.gz"
        ],
        bigwigs=[
            "results/extract/{barcode}/{barcode}_neg.bw",
            "results/extract/{barcode}/{barcode}_pos.bw",
            "results/extract/{barcode}/{barcode}_coverage_cpg.bw"
        ]
    resources:
        threads=64,
        cores=64,
        mem_mb=128000
    params:
        tmpdir=config['tmpdir'],
        barcode=lambda w: w.barcode,
        phred_threshold=f'--threshold {config['extract']['phred_threshold']}' if config['extract']['phred_threshold'] else '',
        mode='--mode strand-specific' if config['extract']['strand_specific'] else '',
        bw_mode='--bw-mode strand-specific' if config['extract']['bw_strand_specific'] else ''
    container: "docker://clarity001/gembs:latest"
    log: "results/logfiles/extract/{barcode}.log"
    shell:
        """
        exec >> {log} 2>&1

        OUTPUT_DIR={params.tmpdir}/results/extract/{params.barcode}
        mkdir -p "$OUTPUT_DIR"

        cp {input.bcf} {input.bcf_csi} {input.chromsizes} $OUTPUT_DIR

        mextr \
            --loglevel info \
            --compress \
            --md5 \
            --cpgfile $OUTPUT_DIR/$(basename {output.cpgfile}) \
	        --noncpgfile $OUTPUT_DIR/$(basename {output.noncpgfile}) \
            --bed-methyl $OUTPUT_DIR/{params.barcode} \
            --tabix \
            --threads {resources.threads} \
            {params.phred_threshold} \
            {params.mode} \
            {params.bw_mode} \
            $OUTPUT_DIR/$(basename {input.bcf})
        
        pigz -dc $OUTPUT_DIR/$(basename {output.bed_gz[2]}) |
        tail -n +2 |
        qsvlite select -d '\t' -n 1,2,3,10 |
        qsvlite fmt -t '\t' |
        sort -k1,1 -k2,2n |
        bigtools bedgraphtobigwig \
            --sorted all \
            --nthreads $(({resources.threads} / 2)) \
            - $OUTPUT_DIR/$(basename {input.chromsizes}) $OUTPUT_DIR/$(basename {output.bigwigs[2]})

        rm -rf $OUTPUT_DIR/$(basename {input.chromsizes}) $OUTPUT_DIR/$(basename {input.bcf}) $OUTPUT_DIR/$(basename {input.bcf_csi})
        cp -t results/extract/{params.barcode} "$OUTPUT_DIR"/* 
        rm -rf "$OUTPUT_DIR"

        touch {output.signal}
        """
