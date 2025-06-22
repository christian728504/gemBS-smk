# How the --text-metadata is parsed: https://github.com/heathsc/gemBS-rs/blob/master/rust/gemBS/src/commands/prepare/metadata.rs
# Accepted column names (`from_str` method): https://github.com/heathsc/gemBS-rs/blob/master/rust/gemBS/src/common/defs.rs#L34

# checkpoint make_gembs_metadata:
#     input:
#         samples=config["samples"]
#     output:
#         csv="results/gembs_metadata.csv"
#     script:
#         "scripts/make_gembs_metadata.py"

checkpoint make_gembs_metadata:
    input:
        samples=config["samples"]
    output:
        csv="results/gembs_metadata.csv",
    container: "docker://clarity001/gembs:latest"
    run:
        import polars as pl
        from pathlib import Path
        import os

        site_to_acccession_map = {
            "CCH_0001_WB_01": "EB100001",
            "CCH_0002_WB_01": "EB100002",
            "CCH_0003_WB_01": "EB100003",
            "CKD_0001_WB_01": "EB100004",
            "CKD_0002_WB_01": "EB100005",
            "CKD_0003_WB_01": "EB100006",
            "EXP_0001_WB_01": "EB100007",
            "EXP_0002_WB_01": "EB100008",
            "EXP_0003_WB_01": "EB100009",
            "MOM_0001_WB_01": "EB100010",
            "MOM_0002_WB_01": "EB100011",
            "MOM_0003_WB_01": "EB100012",
            "UIC_0004_WB_01": "EB100013",
            "UIC_0005_WB_01": "EB100014",
            "UIC_0006_WB_01": "EB100015"
        }

        site_to_acccession_map = {v: k for k, v in site_to_acccession_map.items()}

        fastq_files = sorted(list(Path(config["samples"]).glob("*.fastq.gz")))
        fastq_files = [str(file) for file in fastq_files]

        records = []
        for file in fastq_files:
            basename = os.path.basename(file)
            parts = basename.split("_")
            record = {
                "Project": parts[0],
                "Assay": "WGBS",
                "Barcode": parts[1],
                "Dataset": site_to_acccession_map[parts[1]],
                "Read": parts[2].split(".")[0],
                "File": file
            }
            records.append(record)
            
        wgbs_metadata = pl.from_dicts(records).pivot(
                index=["Barcode", "Project", "Assay", "Dataset"],
                on="Read", 
                values="File",
                maintain_order=True
            ).rename({"R1": "File1", "R2": "File2", }).drop("Project", "Assay")

        wgbs_metadata.write_csv(output.csv)