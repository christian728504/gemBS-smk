rule gembs_map:
    input:
        signal="results/indexes/.continue",
    output:
        bam="results/mapping/{barcode}/{barcode}.bam",
        csi="results/mapping/{barcode}/{barcode}.bam.csi",
        md5="results/mapping/{barcode}/{barcode}.bam.md5",
        singal="results/mapping/{barcode}/.continue"
    resources:
        mapping_jobs = 1
    container: "docker://clarity001/gembs:latest"
    shell:
        """
        gemBS map --barcode {wildcards.barcode}
        touch {output.singal}
        """