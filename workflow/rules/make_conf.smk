rule make_conf:
    output:
        conf="results/gembs.conf"
    container: "docker://clarity001/gembs:latest"
    run:
        from jinja2 import Template
        import gzip
        import os

        def get_underconversion_sequence(file):
            with gzip.open(file, "rt") as f:
                return f.readline().strip().lstrip(">")
    
        template_path = "resources/gembs.conf.j2"
        with open(template_path, 'r') as f:
            template = Template(f.read())
        
        rendered = template.render(config=config, get_underconversion_sequence=get_underconversion_sequence)
        
        os.makedirs(os.path.dirname(output.conf), exist_ok=True)
        with open(output.conf, 'w') as f:
            f.write(rendered)