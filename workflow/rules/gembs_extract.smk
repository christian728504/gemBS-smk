rule gembs_extract:
    input:
        indexes_singal="results/indexes/.continue",
        mapping_signal="results/mapping/{barcode}/.continue",
        calls_signal="results/calls/{barcode}/.continue"
    output:
        signal="results/extract/{barcode}/.continue",
        bed_gz=[
            "results/extract/{barcode}/{barcode}_chg.bed.gz",
            "results/extract/{barcode}/{barcode}_chh.bed.gz",
            "results/extract/{barcode}/{barcode}_cpg.bed.gz",
        ],
        no_header=[
            "results/extract/{barcode}/{barcode}_chg_no_header.bed.gz",
            "results/extract/{barcode}/{barcode}_chh_no_header.bed.gz",
            "results/extract/{barcode}/{barcode}_cpg_no_header.bed.gz",
        ],
        bigwigs=[
            "results/extract/{barcode}/{barcode}_neg.bw",
            "results/extract/{barcode}/{barcode}_pos.bw",
        ]
    params:
        phred_threshold=f"--phred-threshold {config.get('gembs_extract_phred_threshold')}" if config.get("gembs_extract_phred_threshold", False) else "",
        min_informative=f"--min-inform {config.get('gembs_extract_min_inform')}" if config.get("gembs_extract_min_inform", False) else "",
    shell:
        """
        gemBS extract --barcode {wildcards.barcode} {params.phred_threshold} {params.min_informative}
        for i in {output.bed_gz}; do
            base=$(basename "$i" .bed.gz)
            gzip -dck "$i" | tail -n +2 | gzip -n > results/extract/{wildcards.barcode}/"$base"_no_header.bed.gz
        done
        touch {output.signal}
        """
