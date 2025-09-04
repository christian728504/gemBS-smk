import polars as pl
import argparse
import subprocess
from pathlib import Path
import os
from collections import defaultdict
import tempfile

METHYLATION_TYPES = ["CG", "CHG", "CHH"]

def read_bedmethyl(bed_gz_path):
    bed_schema = {
        "chr": pl.Utf8,
        "start": pl.UInt32,
        "end": pl.UInt32,
        "name": pl.Utf8,
        "score": pl.UInt16,
        "strand": pl.Utf8,
        "thick_start": pl.UInt32,
        "thick_end": pl.UInt32,
        "color": pl.Utf8,
        "coverage": pl.UInt32,
        "methylation_level": pl.Float32,
        "ref_genotype": pl.Utf8,
        "sample_genotype": pl.Utf8,
        "quality_score": pl.Float32
    }

    df = pl.read_csv(
        bed_gz_path,
        separator='\t',
        has_header=False,
        skip_rows=1,
        schema=bed_schema
    ).with_columns(
        pl.col("methylation_level") / 100,
    )

    return df

def main(args):
    os.makedirs(args.outdir, exist_ok=True)
    
    methyl_type_to_methyl_file = {
        "CHH": args.chh,
        "CHG": args.chg,
        "CG": args.cpg
    }
    
    methyl_type_to_methyl_df = defaultdict()
    for methyl_type in methyl_type_to_methyl_file.keys():
        df = read_bedmethyl(methyl_type_to_methyl_file[methyl_type])
        print(f"Loaded bedmethyl file for type {methyl_type}")
        df = df.with_columns(
            pl.lit(methyl_type).alias("type")
        )
        df = df.select("chr", "start", "end", "type", "methylation_level", "strand", "coverage")
        methyl_type_to_methyl_df[methyl_type] = df
        
    print("Loaded all bedmethyl files")
    
    methylc_df = pl.concat(list(methyl_type_to_methyl_df.values()))
    print(f"Concatenated bedmethyl files into methylc file")
    
    sorted_methylc_df = methylc_df.sort(["chr", "start"], descending=[False, False])
    print(f"Sorted methylc file by chr and start")
    
    methylc_file = args.outdir / f"{args.barcode}_methylc.bed"
    sorted_methylc_df.write_csv(methylc_file, separator="\t", include_header=False)
    print(f"Wrote methylc file: {methylc_file}")
    
    subprocess.check_call(f"bgzip -f -@ {args.threads} {str(methylc_file)}", shell=True)
    subprocess.check_call(f"tabix -@ {args.threads} -p bed {str(methylc_file)}.gz", shell=True)
    print("bgzipped and indexed methylc file")
    
    neg_coverage_df = sorted_methylc_df.filter(pl.col("strand") == "-").select("chr", "start", "end", "coverage")
    pos_coverage_df = sorted_methylc_df.filter(pl.col("strand") == "+").select("chr", "start", "end", "coverage")
    
    neg_coverage_tempfile = tempfile.NamedTemporaryFile()
    pos_coverage_tempfile = tempfile.NamedTemporaryFile()
    
    neg_coverage_df.write_csv(neg_coverage_tempfile.name, separator="\t", include_header=False)
    pos_coverage_df.write_csv(pos_coverage_tempfile.name, separator="\t", include_header=False)
    
    neg_coverage_bigwig = args.outdir / f"{args.barcode}_coverage_neg.bw"
    pos_coverage_bigwig = args.outdir / f"{args.barcode}_coverage_pos.bw"
    
    neg_coverage_cmd = f"bigtools bedgraphtobigwig -t {args.threads} {neg_coverage_tempfile.name} {args.chromsizes} {neg_coverage_bigwig}"
    pos_coverage_cmd = f"bigtools bedgraphtobigwig -t {args.threads} {pos_coverage_tempfile.name} {args.chromsizes} {pos_coverage_bigwig}"
    print(f"Running command: {neg_coverage_cmd}")
    subprocess.check_call(neg_coverage_cmd, shell=True)
    print(f"Running command: {pos_coverage_cmd}")
    subprocess.check_call(pos_coverage_cmd, shell=True)
    
    neg_coverage_tempfile.close()
    pos_coverage_tempfile.close()
    
    print("Finished")
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--barcode", required=True)
    parser.add_argument("--chh", required=True)
    parser.add_argument("--chg", required=True)
    parser.add_argument("--cpg", required=True)
    parser.add_argument("--chromsizes", required=True)
    parser.add_argument("--threads", default=1, type=int)
    parser.add_argument("--outdir", required=True, type=Path)
    args = parser.parse_args()
    main(args)