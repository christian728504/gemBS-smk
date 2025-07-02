# Snakemake workflow: WGBS-smk

[![Snakemake](https://img.shields.io/badge/snakemake-≥8.0.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/snakemake-workflows/snakemake-workflow-template/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/snakemake-workflows/snakemake-workflow-template/actions/workflows/main.yml)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![workflow catalog](https://img.shields.io/badge/Snakemake%20workflow%20catalog-darkgreen)](https://snakemake.github.io/snakemake-workflow-catalog/docs/workflows/<owner>/<repo>)

A Snakemake workflow for processing whole genome bisulfite sequencing data.

- [Snakemake workflow: WGBS-smk](#snakemake-workflow-wgbs-smk)
  - [Usage](#usage)
  - [Deployment options](#deployment-options)
  - [Authors](#authors)
  - [TODO](#todo)

## Usage

Detailed information about input data and workflow configuration can also be found in the [`config/README.md`](config/README.md).

## Deployment options

Adjust options in the default config file `config/config.yml`.
Before running the complete workflow, you can perform a dry run using:

```bash
snakemake --dry-run
```

To run the workflow with test files using **conda**:

```bash
snakemake --cores 2 --sdm conda --directory .test
```

## Authors

- Christian Ramirez

## TODO

- [ ] 