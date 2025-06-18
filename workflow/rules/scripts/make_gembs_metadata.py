from snakemake.script import snakemake

import polars as pl
 
def main():       
    try:
        slim_metadata = pl.read_csv(snakemake.input.samples, separator="\t")
    except Exception as e:
        raise ValueError(f"Failed to read samples file: {e}")

    grouped_read = slim_metadata.group_by(
        "Biological replicate(s)", "Technical replicate(s)", maintain_order=True
    ).agg(
        "File path", "File accession", "Experiment accession"
    )

    base_df = grouped_read.with_columns([
        (pl.col("Experiment accession").list.first() + 
            pl.lit("_") + 
            pl.col("Technical replicate(s)").cast(pl.String)).alias("Dataset"),
        pl.col("File accession").list.join("_").alias("Name")
    ]).with_columns(
        pl.col("Name").hash(seed=33).alias("Barcode")
    )

    base_df = base_df.with_columns(
        pl.col("File path").list.len().alias("file_count")
    )

    single_end_mask = base_df["file_count"] == 1
    single_end_df = base_df.filter(single_end_mask).with_columns(
        pl.col("File path").list.get(0).alias("File")
    ).select(["Barcode", "Name", "Dataset", "File"])

    paired_end_mask = base_df["file_count"] == 2
    paired_end_df = base_df.filter(paired_end_mask).with_columns([
        pl.col("File path").list.get(0).alias("File1"),
        pl.col("File path").list.get(1).alias("File2")
    ]).select(["Barcode", "Name", "Dataset", "File1", "File2"])

    if len(single_end_df) > 0 and len(paired_end_df) == 0:
        gembs_metadata = single_end_df.cast(pl.String)
    elif len(single_end_df) == 0 and len(paired_end_df) > 0:
        gembs_metadata = paired_end_df.cast(pl.String)
    # gemBS can only process one single-end or paired-end data at a time
    # running multiple experiments in one snakemake run is not supported yet
    # elif len(single_end_df) > 0 and len(paired_end_df) > 0:
    #     single_end_expanded = single_end_df.with_columns([
    #         pl.col("File").alias("File1"),
    #         pl.lit(None, dtype=pl.String).alias("File2")
    #     ]).select(["Barcode", "Name", "Dataset", "File1", "File2"])
    #     gembs_metadata = pl.concat([single_end_expanded, paired_end_df]).cast(pl.String)
    else:
        raise ValueError("No valid samples found after processing")

    try:
        gembs_metadata.write_csv(snakemake.output.csv)
    except Exception as e:
        raise ValueError(f"Failed to write output CSV: {e}")

if __name__ == "__main__":
    main()