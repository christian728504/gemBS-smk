"""
Calculates Pearson correlation of sites with ≥10X coverage between CpG bedmethyl files.
Inspired by https://github.com/ENCODE-DCC/mirna-seq-pipeline/blob/dev/src/calculate_correlation.py
"""
from snakemake.script import snakemake

import polars as pl
from qc_utils import QCMetric, QCMetricRecord

DF_COLUMN_NAMES = ("chrom", "start", "end", "coverage", "methylation_percentage")

def load_bedmethyl(path: str) -> pl.DataFrame:
    """
    Loads position information (columns 0-2), coverage (column 10), and methylation
    percentage of the input bedMethyl file, for file specifications see
    https://www.encodeproject.org/data-standards/wgbs/ .
    """
    df = pl.read_csv(
        path,
        separator="\t",
        has_header=False,
        skip_rows=1,
        columns=[0, 1, 2, 9, 10],
        new_columns=DF_COLUMN_NAMES
    )
    return df

def calculate_pearson(bedmethyl1: pl.DataFrame, bedmethyl2: pl.DataFrame) -> float:
    """
    Filters both bedfiles for entries where coverage is GTE 10, then does an inner join
    to get the positions to line up, which takes the intersection of loci, and
    calculates the correlation.
    """
    bedmethyl1 = bedmethyl1.filter(pl.col("coverage") >= 10)
    bedmethyl2 = bedmethyl2.filter(pl.col("coverage") >= 10)
    merged = bedmethyl1.join(bedmethyl2, on=["chrom", "start", "end"])
    pearson_correlation: float = merged.select(pl.corr("methylation_percentage", "methylation_percentage_right", method="pearson")).item()
    return pearson_correlation

def make_pearson_qc(pearson_correlation: float) -> QCMetricRecord:
    qc_record = QCMetricRecord()
    pearson_metric = QCMetric(
        "pearson_correlation", {"pearson_correlation": pearson_correlation}
    )
    qc_record.add(pearson_metric)
    return qc_record

def main():
    """
    We already integration test this in the WDL tests, no need for Python test coverage.
    """
    bedmethyl1 = load_bedmethyl(snakemake.input.bedmethyls[0])
    bedmethyl2 = load_bedmethyl(snakemake.input.bedmethyls[1])
    pearson_correlation = calculate_pearson(bedmethyl1, bedmethyl2)
    qc_record = make_pearson_qc(pearson_correlation)
    qc_record.save(snakemake.output.pearson_correlation_qc)

if __name__ == "__main__":
    main()