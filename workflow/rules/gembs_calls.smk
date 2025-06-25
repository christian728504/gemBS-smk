rule gembs_calls:
    input:
        mapping_signal="results/mapping/{barcode}/.continue",
        indexes_singal="results/indexes/.continue"
    output:
        signal="results/calls/{barcode}/.continue",
        bcf="results/calls/{barcode}/{barcode}.bcf",
        bcf_csi="results/calls/{barcode}/{barcode}.bcf.csi",
        bcf_md5="results/calls/{barcode}/{barcode}.bcf.md5"
    container: "docker://clarity001/gembs:latest"
    log: "results/logfiles/calls/{barcode}.log"
    shell:
        """
        exec >> {log} 2>&1
        gemBS call --barcode {wildcards.barcode}
        touch {output.signal}
        """