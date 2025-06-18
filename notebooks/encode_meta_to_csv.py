# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.17.2
#   kernelspec:
#     display_name: .venv
#     language: python
#     name: python3
# ---

# %%
import polars as pl

# %%
metadata = pl.read_csv("/zata/zippy/ramirezc/gembs_smk/.test/?type=Experiment&%40id=%2Fexperiments%2FENCSR765JPC%2F&files.output_type=reads&files.output_category=raw+data", separator="\t")

# %%
metadata.head()

# %%
slim_metadata = metadata.select("File accession", "File download URL", "Biological replicate(s)", "Technical replicate(s)", "Run type", "Paired end", "Paired with")
slim_metadata.write_csv("metadata.tsv", separator="\t")

# %%
with_paths = metadata.with_columns(
   ("/zata/zippy/ramirezc/gembs_smk/.test/" + pl.col("File accession") + ".fastq.gz").alias("File path"),
   pl.col("Paired with").str.split("/").list[-2]
)
slim_metadata = with_paths.select("File accession", "Experiment accession", "File path", "Biological replicate(s)", "Technical replicate(s)", "Run type", "Paired end", "Paired with")
slim_metadata.write_csv("metadata.tsv", separator="\t")


# %%
slim_metadata = pl.read_csv("metadata.tsv", separator="\t")

# # Add one if single-ended
# add_one = slim_metadata.with_columns(
#     pl.when(pl.col("Run type") == "single-ended").then(
#         pl.lit(1).alias("Paired end")
#     ).otherwise(
#         pl.col("Paired end")
#     )
# )
# add_one.head()

grouped_read = slim_metadata.group_by(
        "Biological replicate(s)", "Technical replicate(s)"
    ).agg(
        "File path", "File accession", "Experiment accession"
    ).with_columns([
        pl.when(pl.col("File accession").list.len() == 1)
        .then(pl.col("File path").list.get(0))
        .alias("File"),
    
        pl.when(pl.col("File accession").list.len() == 2)
        .then(pl.col("File path").list.get(0))
        .alias("File1"),
    
        pl.when(pl.col("File accession").list.len() == 2)
        .then(pl.col("File path").list.get(1))
        .alias("File2"),
        
        pl.col("Experiment accession").list.first().alias("Dataset"),
        pl.col("File accession").list.join("_").alias("Name")
    ]).with_columns(
        pl.col("Name").hash(seed=33).alias("Barcode")
    )
grouped_read.head()

if grouped_read["File"].has_nulls:
    gembs_metadata = grouped_read.select(
        "Barcode", "Name", "Dataset", "File1", "File2"
    )
elif grouped_read["File1"].has_nulls and grouped_read["File2"].has_nulls:
    gembs_metadata = grouped_read.select(
        "Barcode", "Name", "Dataset", "File"
    )
gembs_metadata.head()


grouped_read =  metadata.filter(pl.col("Paired end") == 1).with_columns([
    pl.col("File accession").hash(seed=33).alias("Barcode"),
    pl.col("File accession").alias("Name"),
    pl.col("Experiment accession").alias("Dataset"),
    pl.col("File path").alias("File1")
]).join(slim_metadata.filter(pl.col("Paired end") == 2).select("Paired with", pl.col("File path").alias("File2")),
    left_on="File accession",
    right_on="Paired with",
    how="left"
).select("Barcode", "Name", "Dataset", "File1", "File2")
grouped_read

.rename({
    ""
}).write_csv(output.csv, sep="\t")

# %%
# Test regex parsing
import os

before = "results/GRCh38_no_alt_analysis_set_GCA_000001405.15.fasta.gz"
after = os.path.basename(before)
print(before)
print(after)

import re

pattern = r"\.(fa|fasta|fa\.gz|fasta\.gz)$"

test_files = [
    "GRCh38_no_alt_analysis_set_GCA_000001405.15.fasta.gz",
    "reference.fasta",
    "genome.fa.gz", 
    "sample.fa",
    "data.txt"  # Invalid extension
]

for filename in test_files:
    basename = re.sub(pattern, '', filename)
    print(f"{filename} -> {basename}")

# %%

# %%
