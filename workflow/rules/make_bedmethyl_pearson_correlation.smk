def make_bedmethyl_pearson_correlation(wildcards):
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
        .filter(pl.col("Experiment") == wildcards.experiment)
        .select("Barcode")
        .item()
    )
    outputs = [f"results/extract/{barcode}/{barcode}_cpg.bed.gz" for barcode in grouped]
    return outputs

rule make_bedmethyl_pearson_correlation:
    input:
        bedmethyls=make_bedmethyl_pearson_correlation
    output:
        csv="results/{experiment}_pearson_correlation_qc.csv"
    container: "docker://clarity001/gembs:latest"
    script:
        "scripts/make_bedmethyl_pearson_correlation_v2.py"