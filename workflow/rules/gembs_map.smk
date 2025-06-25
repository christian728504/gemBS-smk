rule gembs_map:
    input:
        signal="results/indexes/.continue",
    output:
        bam="results/mapping/{barcode}/{barcode}.bam",
        csi="results/mapping/{barcode}/{barcode}.bam.csi",
        md5="results/mapping/{barcode}/{barcode}.bam.md5",
        singal="results/mapping/{barcode}/.continue"
    resources:
        mapping_jobs=1
    container: "docker://clarity001/gembs:latest"
    log: "results/logfiles/extract/{barcode}.log"
    shell:
        """
        exec >> {log} 2>&1
        gemBS map --barcode {wildcards.barcode}
        touch {output.singal}
        """