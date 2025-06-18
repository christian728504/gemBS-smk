def get_barcodes(wildcards):
    path = checkpoints.make_gembs_metadata.get(**wildcards).output.csv
    schema = {"Barcode": pl.String}
    barcodes = pl.read_csv(path, schema_overrides=schema)["Barcode"].unique().to_list()
    return barcodes

rule gembs_report:
    input:
        indexes_signal="results/indexes/.continue",
        mapping_singals=expand("results/mapping/{barcode}/.continue", barcode=get_barcodes),
        calls_singals=expand("results/calls/{barcode}/.continue", barcode=get_barcodes),
        extract_signals=expand("results/extract/{barcode}/.continue", barcode=get_barcodes)
    output:
        report_dir=directory(f"{config['gembs_base']}/report"),
        signal=f"{config["gembs_base"]}/report/.continue"
    params:
        project=f"--project {config.get('project')}" if config.get("project", False) else "",
    shell:
        """
        gemBS report {params.project}
        touch {output.signal}
        """