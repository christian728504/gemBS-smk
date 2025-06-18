rule parse_map_qc_html:
    input:
        signal=config["gembs_base"] + "/report/.continue"
    output:
        json=config["gembs_base"] + "/report/mapping/{barcode}/{barcode}_map_qc.json",
    script:
        "scripts/parse_map_qc_html.py"