import polars as pl

def get_mapping_outputs(wildcards):
    path = checkpoints.make_gembs_metadata.get(**wildcards).output.csv
    schema = {"Barcode": pl.String}
    barcodes = pl.read_csv(path, schema_overrides=schema)["Barcode"].unique().to_list()
    bam, csi, md5 = [], [], []
    for barcode in barcodes:
        bam.append(config["gembs_base"] + "/mapping" + f"/{barcode}/{barcode}.bam")
        csi.append(config["gembs_base"] + "/mapping" + f"/{barcode}/{barcode}.bam.csi")
        md5.append(config["gembs_base"] + "/mapping" + f"/{barcode}/{barcode}.bam.md5")
    outputs = bam + csi + md5
    return outputs

def get_average_coverage_outputs(wildcards):
    path = checkpoints.make_gembs_metadata.get(**wildcards).output.csv
    schema = {"Barcode": pl.String}
    barcodes = pl.read_csv(path, schema_overrides=schema)["Barcode"].unique().to_list()
    outputs = [f"results/mapping/{barcode}/average_coverage.json" for barcode in barcodes]
    print(outputs)
    return outputs

def get_call_outputs(wildcards):
    path = checkpoints.make_gembs_metadata.get(**wildcards).output.csv
    schema = {"Barcode": pl.String}
    barcodes = pl.read_csv(path, schema_overrides=schema)["Barcode"].unique().to_list()
    bcf, csi, md5 = [], [], []
    for barcode in barcodes:
        bcf.append(config["gembs_base"] + "/calls" + f"/{barcode}/{barcode}.bcf")
        csi.append(config["gembs_base"] + "/calls" + f"/{barcode}/{barcode}.bcf.csi")
        md5.append(config["gembs_base"] + "/calls" + f"/{barcode}/{barcode}.bcf.md5")
    outputs = bcf + csi + md5
    print(outputs)
    return outputs

def get_extract_outputs(wildcards):
    path = checkpoints.make_gembs_metadata.get(**wildcards).output.csv
    schema = {"Barcode": pl.String}
    barcodes = pl.read_csv(path, schema_overrides=schema)["Barcode"].unique().to_list()
    outputs = []
    for barcode in barcodes:
        outputs.append(config["gembs_base"] + "/extract" + f"/{barcode}/.continue")
    print(outputs)
    return outputs

def get_coverage_bigwigs(wildcards):
    path = checkpoints.make_gembs_metadata.get(**wildcards).output.csv
    schema = {"Barcode": pl.String}
    barcodes = pl.read_csv(path, schema_overrides=schema)["Barcode"].unique().to_list()
    outputs = [f"{config["gembs_base"]}/extract/{barcode}/{barcode}_cpg.bw" for barcode in barcodes]
    print(outputs)
    return outputs

def get_bedmethyl_pearson_correlation_outputs(wildcards):
    path = checkpoints.make_gembs_metadata.get(**wildcards).output.csv
    schema = {"Barcode": pl.String}
    metadata = pl.read_csv(path, schema_overrides=schema)
    gembs_metadata = pl.read_csv(path, schema_overrides=schema)
    grouped = (
        gembs_metadata
        .with_columns(
            pl.col("Dataset").str.split("_").list.get(0).alias("Experiment")
        )
        .group_by("Experiment")
        .agg("Barcode")
        .to_dicts()
    )
    outputs = []
    for group in grouped:
        if len(group["Barcode"]) == 2:
            outputs.append(f"{config["gembs_base"]}/{group["Experiment"]}_pearson_correlation_qc.json")
    print(outputs)
    return outputs

# def get_report_outputs(wildcards):
#     path = checkpoints.make_gembs_metadata.get(**wildcards).output.csv
#     schema = {"Barcode": pl.String}
#     barcodes = pl.read_csv(path, schema_overrides=schema)["Barcode"].unique().to_list()
#     isize, mapq, html = [], [], []
#     for barcode in barcodes:
#         isize.append(f"{config["gembs_base"]}/report/mapping/{barcode}/images/{barcode}_isize.png")
#         mapq.append(f"{config["gembs_base"]}/report/mapping/{barcode}/images/{barcode}_mapq.png")
#         html.append(f"{config["gembs_base"]}/report/mapping/{barcode}/{barcode}.html")
#     outputs = isize + mapq + html
#     print(outputs)
#     return outputs

def get_parse_map_qc_html_outputs(wildcards):
    path = checkpoints.make_gembs_metadata.get(**wildcards).output.csv
    schema = {"Barcode": pl.String}
    barcodes = pl.read_csv(path, schema_overrides=schema)["Barcode"].unique().to_list()
    outputs = [f"{config["gembs_base"]}/report/mapping/{barcode}/{barcode}_map_qc.json" for barcode in barcodes]
    print(outputs)
    return outputs