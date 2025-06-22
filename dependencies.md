# Environment

## CLI tools

- bigtools v0.5.6
    - `cargo install bigtools`
    - replaces UCSC tools `bedGraphToBigWig` (better perfromance)
- gemBS
    - [gemBS-rs](https://github.com/heathsc/gemBS-rs)
    - Similar performance, better reliablity and more recent version of the gemBS pipeline
- qsv
    - `cargo build --release --locked --bin qsvlite -F lite`
    - replaces `xsv` (depracated)
- pigz
    - [pigz](https://zlib.net/pigz/pigz.tar.gz)
    - replaces `gzip` (better perfromance)

## Python packages

```toml
[project]
name = "gembs-smk"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
requires-python = ">=3.12"
dependencies = [
    "beautifulsoup4>=4.13.4",
    "bgzip>=0.5.0",
    "bioframe>=0.8.0",
    "hvplot>=0.11.3",
    "ipykernel>=6.29.5",
    "jinja2>=3.1.6",
    "lxml>=5.4.0",
    "multiprocess>=0.70.18",
    "pandas>=2.3.0",
    "polars>=1.30.0",
    "pyarrow>=20.0.0",
    "pysam>=0.23.3",
    "qc-utils>=20.9.1",
    "scipy>=1.15.3",
    "snakemake>=9.5.1",
]
```
