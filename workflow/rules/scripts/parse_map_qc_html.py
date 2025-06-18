from snakemake.script import snakemake

import json
from bs4 import BeautifulSoup
import pandas as pd
from io import StringIO

TABLE_HEADINGS = [
    "Mapping Stats (Reads)",
    "Uniquely Mapping Fragments (MAPQ >= 20)",
    "Mapping Stats (Reads)",
    "Bisulfite Conversion Rate",
    "Correct Pairs",
    "Read Lengths",
    "Mismatch Distribution",
]

def to_dataframes(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')
    tables_dict = {}

    for h1 in soup.find_all('h1'):
        header_text = h1.get_text(strip=True)
        
        if header_text in TABLE_HEADINGS:
            next_table = h1.find_next_sibling('table')
            
            if next_table:
                try:
                    table_html = StringIO(next_table.prettify())
                    df_list = pd.read_html(table_html)
                    
                    if df_list:
                        df = df_list[0]
                        tables_dict[header_text] = df
                        
                except Exception as e:
                    print(f"Error parsing '{header_text}': {e}")
                    
    return tables_dict

def main():
    base_dir = snakemake.config["gembs_base"]
    barcode = snakemake.wildcards.barcode
    
    html_path = f"{base_dir}/report/mapping/{barcode}/{barcode}.html"
    
    with open(html_path, 'r') as f:
        html_content = f.read()
    tables_dict = to_dataframes(html_content)
    
    json_dict = {}
    for k, v in tables_dict.items():
        json_dict[k] = v.to_dict(orient='list')
        
    with open(snakemake.output.json, 'w') as f:
        json.dump(json_dict, f, indent=4)

if __name__ == '__main__':
    main()