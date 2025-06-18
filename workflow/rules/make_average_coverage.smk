rule make_average_coverage:
    input:
        singal="results/mapping/{barcode}/.continue",
        bam="results/mapping/{barcode}/{barcode}.bam",
    output:
        qc="results/mapping/{barcode}/average_coverage.json"
    threads: 16
    script:
        "scripts/make_average_coverage.py"