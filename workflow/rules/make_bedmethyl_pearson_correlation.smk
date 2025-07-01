rule make_bedmethyl_pearson_correlation:
    input:
        bedmethyls=make_bedmethyl_pearson_correlation
    output:
        csv="results/{experiment}_pearson_correlation_qc.csv"
    resources:
        threads=8,
        cores=8,
        mem_mb=16000
    container: "docker://clarity001/gembs:latest"
    script:
        "scripts/make_bedmethyl_pearson_correlation_v2.py"