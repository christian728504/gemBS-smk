rule gembs_prepare:
    input:
        conf=rules.make_conf.output.conf,
        csv=rules.make_gembs_metadata.output.csv,
    output:
        dotfile=".gemBS/gemBS.mp"
    container: "docker://clarity001/gembs:latest"
    shell:
        """
        gemBS prepare --config {input.conf} --text-metadata {input.csv}
        """

def get_gembs_index_input():
   if config.get("gembs_index"):
       return [f"{config['gembs_index']}", ".gemBS/gemBS.mp"]
   return ".gemBS/gemBS.mp"

rule gembs_index:
    input:
        get_gembs_index_input()
    output:
        indexes=directory("results/indexes"),
        signal="results/indexes/.continue"
    container: "docker://clarity001/gembs:latest"
    params:
        index=config.get('gembs_index')
    log: "results/logfiles/indexes.log"
    shell:
        """
        exec >> {log} 2>&1
        if [ -f "{params.index}" ]; then
            lz4 -d {params.index} -c | tar xvf - -C results/
            touch results/indexes
        else
            gemBS index
        fi
        touch {output.signal}
        """

# rule gembs_index:
#     input:
#         dotfile=".gemBS/gemBS.mp"
#     output:
#         indexes=directory("results/indexes"),
#         signal="results/indexes/.continue"
#     container: "docker://clarity001/gembs:latest"
#     shell:
#         """
#         gemBS index
#         touch {output.signal}
#         """
