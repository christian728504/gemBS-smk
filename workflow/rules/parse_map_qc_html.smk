rule parse_map_qc_html:
    input:
        signal="results/report/.continue"
    output:
        json="results/report/mapping/{barcode}/{barcode}_map_qc.json",
    container: "docker://clarity001/gembs:latest"
    script:
        "scripts/parse_map_qc_html.py"