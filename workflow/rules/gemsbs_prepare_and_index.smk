rule gembs_prepare_and_index:
    input:
        conf=rules.make_conf.output.conf,
        csv=rules.make_gembs_metadata.output.csv,
    output:
        indexes=directory("results/indexes"),
        signal="results/indexes/.continue"
    shell:
        """
        gemBS prepare --config {input.conf} --text-metadata {input.csv}
        gemBS index
        touch {output.signal}
        """
