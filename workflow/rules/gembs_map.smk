rule gembs_map:
    input:
        signal=rules.gembs_prepare_and_index.output.signal,
    output:
        bam="results/mapping/{barcode}/{barcode}.bam",
        csi="results/mapping/{barcode}/{barcode}.bam.csi",
        md5="results/mapping/{barcode}/{barcode}.bam.md5",
        singal="results/mapping/{barcode}/.continue"
    resources:
        mapping_jobs = 1
    shell:
        """
        gemBS map --barcode {wildcards.barcode}
        touch {output.singal}
        """