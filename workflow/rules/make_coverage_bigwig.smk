rule make_coverage_bigwig:
    input:
        indexes_singal="results/indexes/.continue",
        mapping_signal="results/mapping/{barcode}/.continue",
        calls_signal="results/calls/{barcode}/.continue",
        extract_signal="results/extract/{barcode}/.continue",
        cpg_bed="results/extract/{barcode}/{barcode}_cpg.bed.gz"
    output:
        bigwig="results/extract/{barcode}/{barcode}_cpg.bw"
    params:
        chrom_sizes=f"results/indexes/{REFERENCE_BASENAME}.gemBS.contig_sizes"
    # threads: 24
    container: "docker://clarity001/gembs:latest"
    shell:
        """
        pigz -dc -p {threads} {input.cpg_bed} |
        tail -n +2 |
        qsvlite select -d '\t' -n 1,2,3,10 |
        qsvlite fmt -t '\t' |
        sort -k1,1 -k2,2n |
        bigtools bedgraphtobigwig --sorted all --nthreads {threads} - {params.chrom_sizes} {output.bigwig}
        """