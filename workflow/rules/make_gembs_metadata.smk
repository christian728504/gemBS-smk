import polars as pl
# How the --text-metadata is parsed: https://github.com/heathsc/gemBS-rs/blob/master/rust/gemBS/src/commands/prepare/metadata.rs
# Accepted column names (`from_str` method): https://github.com/heathsc/gemBS-rs/blob/master/rust/gemBS/src/common/defs.rs#L34

checkpoint make_gembs_metadata:
    input:
        samples=config["samples"]
    output:
        csv="results/gembs_metadata.csv"
    script:
        "scripts/make_gembs_metadata.py"