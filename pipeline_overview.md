# WGBS Pipeline Complete Breakdown (WDL-based)

## Pipeline Overview

This is an ENCODE WGBS pipeline (v1.1.7) implemented in WDL that processes whole genome bisulfite sequencing data using the gemBS toolkit. The pipeline supports both WGBS and RRBS modes with configurable resource allocation.

## Main Inputs

- **`reference`**: Reference genome FASTA file
- **`fastqs`**: 3D array structure: `Array[Array[Array[File]]]`
  - Biological replicate → Technical replicate → FASTQ files (1 for SE, 2 for PE)
- **`sample_names`**: Array of sample identifiers
- **`indexed_reference`**: Pre-built gemBS index (optional)
- **`indexed_contig_sizes`**: Chromosome sizes file (optional)
- **`extra_reference`**: Additional reference sequences (optional)

## Pipeline Flow and Dependencies

### Phase 1: Configuration Setup

These tasks run first and their outputs are used by subsequent steps.

#### `make_conf`

- **Purpose**: Generate gemBS configuration file
- **Inputs**:
  - `reference`: Reference genome path
  - `extra_reference`: Optional additional sequences
  - `num_threads`: gemBS thread count (default: 8)
  - `num_jobs`: gemBS job count (default: 3)
  - `include_file`: Configuration template (IHEC_standard.conf or IHEC_RRBS.conf)
  - `underconversion_sequence_name`: Control sequence name
  - `benchmark_mode`: Performance testing flag
- **Outputs**:
  - `gembs_conf`: gemBS configuration file
- **Command**: `make_conf.py` script

#### `make_metadata_csv` (conditional: !index_only)

- **Purpose**: Create sample metadata CSV
- **Inputs**:
  - `sample_names`: Sample identifiers
  - `fastqs`: FASTQ file structure (JSON serialized)
  - `barcode_prefix`: Sample barcode prefix (default: "sample_")
- **Outputs**:
  - `metadata_csv`: Sample metadata in CSV format
- **Command**: `make_metadata_csv.py` script

### Phase 2: Index Preparation

Either use existing index or create new one.

#### `index` (conditional: !defined(indexed_reference))

- **Purpose**: Build gemBS reference index
- **Inputs**:
  - `configuration_file`: Output from `make_conf`
  - `reference`: Reference genome
  - `extra_reference`: Optional additional sequences
- **Outputs**:
  - `gembs_indexes`: Compressed index tarball
  - `contig_sizes`: Chromosome sizes file
- **Command**: `gemBS index`
- **Note**: Creates dummy metadata.csv for index creation

#### `prepare` (conditional: !index_only)

- **Purpose**: Initialize gemBS project
- **Inputs**:
  - `configuration_file`: Output from `make_conf`
  - `metadata_file`: Output from `make_metadata_csv`
  - `reference`: Reference genome
  - `index`: Index tarball (from `index` or `indexed_reference`)
  - `extra_reference`: Additional sequences
- **Outputs**:
  - `gemBS_json`: gemBS project configuration
- **Command**: `gemBS prepare`

### Phase 3: Per-Sample Processing (Scatter)

The following tasks run in parallel for each biological replicate using a scatter block.

#### `map`

- **Purpose**: Align bisulfite-treated reads
- **Inputs**:
  - `fastqs`: Flattened FASTQ files for sample
  - `sample_barcode`: Generated barcode (barcode_prefix + sample_name)
  - `sample_name`: Sample identifier
  - `index`: Reference index
  - `reference`: Reference genome
  - `gemBS_json`: Project configuration from `prepare`
  - `sort_threads`: BAM sorting threads
  - `sort_memory`: BAM sorting memory
- **Outputs**:
  - `bam`: Aligned reads
  - `csi`: BAM index
  - `bam_md5`: BAM checksum
  - `qc_json`: Mapping QC metrics
- **Command**: `gemBS map`

#### `calculate_average_coverage`

- **Purpose**: Calculate genome-wide coverage statistics
- **Inputs**:
  - `bam`: BAM file from `map`
  - `chrom_sizes`: Chromosome sizes
- **Outputs**:
  - `average_coverage_qc`: Coverage statistics JSON
- **Command**: `calculate_average_coverage.py`

#### `bscaller`

- **Purpose**: Call methylation states and variants
- **Inputs**:
  - `reference`: Reference genome
  - `gemBS_json`: Project configuration
  - `bam`: BAM file from `map`
  - `csi`: BAM index from `map`
  - `index`: Reference index
  - `sample_barcode`: Sample barcode
- **Outputs**:
  - `bcf`: Methylation calls in BCF format
  - `bcf_csi`: BCF index
  - `bcf_md5`: BCF checksum
- **Command**: `gemBS call`

#### `extract`

- **Purpose**: Extract methylation data in multiple formats
- **Inputs**:
  - `gemBS_json`: Project configuration
  - `reference`: Reference genome
  - `contig_sizes`: Chromosome sizes
  - `bcf`: BCF file from `bscaller`
  - `bcf_csi`: BCF index from `bscaller`
  - `sample_barcode`: Sample barcode
  - `phred_threshold`: Quality threshold (optional)
  - `min_inform`: Minimum informative coverage (optional)
- **Outputs**:
  - **Strand-specific bigWig**:
    - `plus_strand_bw`: Plus strand methylation signal
    - `minus_strand_bw`: Minus strand methylation signal
  - **Context-specific bigBed**:
    - `cpg_bb`: CpG methylation bigBed
    - `chg_bb`: CHG methylation bigBed  
    - `chh_bb`: CHH methylation bigBed
  - **Context-specific BED (with/without headers)**:
    - `cpg_bed`, `cpg_bed_no_header`: CpG methylation BED
    - `chg_bed`, `chg_bed_no_header`: CHG methylation BED
    - `chh_bed`, `chh_bed_no_header`: CHH methylation BED
  - **gemBS-style text files**:
    - `cpg_txt`, `cpg_txt_tbi`: CpG methylation with index
    - `non_cpg_txt`, `non_cpg_txt_tbi`: Non-CpG methylation with index
- **Command**: `gemBS extract`

#### `make_coverage_bigwig`

- **Purpose**: Generate coverage tracks for genome browsers
- **Inputs**:
  - `encode_bed`: CpG BED file from `extract`
  - `chrom_sizes`: Chromosome sizes
- **Outputs**:
  - `coverage_bigwig`: Coverage signal in bigWig format
- **Command**: `bedGraphToBigWig` via custom script

#### `qc_report`

- **Purpose**: Generate comprehensive QC reports
- **Inputs**:
  - `map_qc_json`: QC metrics from `map`
  - `gemBS_json`: Project configuration
  - `reference`: Reference genome
  - `contig_sizes`: Chromosome sizes
  - `sample_barcode`: Sample barcode
- **Outputs**:
  - `map_html_assets`: HTML report files
  - `portal_map_qc_json`: Parsed QC metrics
  - `map_qc_insert_size_plot_png`: Insert size distribution plot
  - `map_qc_mapq_plot_png`: Mapping quality plot
- **Command**: `gemBS map-report` + `parse_map_qc_html.py`

### Phase 4: Multi-Sample Analysis (Conditional)

Only runs if exactly 2 samples are present.

#### `calculate_bed_pearson_correlation`

- **Purpose**: Calculate correlation between biological replicates
- **Inputs**:
  - `bed1`: First replicate CpG BED
  - `bed2`: Second replicate CpG BED
- **Outputs**:
  - `bed_pearson_correlation_qc`: Correlation statistics
- **Command**: `calculate_bed_pearson_correlation.py`

## Pipeline Execution Modes

### Standard Mode (default)

Processes all samples through complete pipeline.

### Index-Only Mode (`index_only = true`)

Only generates reference index, skips sample processing.

### Benchmark Mode (`benchmark_mode = true`)

Enables performance profiling during execution.

## Resource Configuration

The pipeline provides granular resource control for each task:

### CPU/Memory/Disk defaults

- **make_conf**: 1 CPU, 2GB RAM, 10GB disk
- **make_metadata_csv**: 1 CPU, 2GB RAM, 10GB disk
- **index**: 8 CPU, 64GB RAM, 500GB disk
- **prepare**: 8 CPU, 32GB RAM, 500GB disk
- **map**: 8 CPU, 64GB RAM, 500GB disk
- **bscaller**: 8 CPU, 32GB RAM, 500GB disk
- **extract**: 8 CPU, 96GB RAM, 500GB disk
- **make_coverage_bigwig**: 4 CPU, 8GB RAM, 50GB disk
- **qc_report**: 1 CPU, 4GB RAM, 50GB disk
- **calculate_average_coverage**: 1 CPU, 8GB RAM, 200GB disk
- **calculate_bed_pearson_correlation**: 1 CPU, 16GB RAM, 50GB disk

## Data Flow Diagram

```txt
Reference Genome + FASTQ files
         ↓
    [make_conf] ──────────────┐
         ↓                    ↓
    [make_metadata_csv]   [index] (if needed)
         ↓                    ↓
    [prepare] ←──────────────┘
         ↓
    ┌────┴────┐ (scatter per sample)
    ↓         ↓
[map] ────→ [calculate_average_coverage]
    ↓
[bscaller]
    ↓
[extract] ────→ [make_coverage_bigwig]
    ↓
[qc_report]
    ↓
[calculate_bed_pearson_correlation] (if 2 samples)
```

## Output Structure

```txt
outputs/
├── configuration/
│   ├── gembs.conf
│   ├── gembs_metadata.csv
│   └── gemBS.json
├── indexes/
│   ├── indexes.tar.gz
│   └── *.contig.sizes
├── per_sample/ (for each sample)
│   ├── mapping/
│   │   ├── *.bam + *.csi + *.md5
│   │   └── *.json (QC metrics)
│   ├── calls/
│   │   ├── *.bcf + *.csi + *.md5
│   ├── extract/
│   │   ├── *_cpg.bed.gz + *_cpg.bb
│   │   ├── *_chg.bed.gz + *_chg.bb  
│   │   ├── *_chh.bed.gz + *_chh.bb
│   │   ├── *_cpg.txt.gz + *.tbi
│   │   ├── *_non_cpg.txt.gz + *.tbi
│   │   ├── *_pos.bw (plus strand)
│   │   └── *_neg.bw (minus strand)
│   ├── coverage/
│   │   └── coverage.bw
│   ├── qc/
│   │   ├── *.html (reports)
│   │   ├── *.png (plots)
│   │   └── *.json (metrics)
│   └── average_coverage_qc.json
└── bed_pearson_correlation_qc.json (if applicable)
```

## Key Configuration Parameters

From the included config file (`IHEC_standard.conf` or `IHEC_RRBS.conf`):

- **Mapping**: `non_stranded = False`, quality thresholds
- **Calling**: MAPQ ≥ 10, base quality ≥ 13, trimming parameters
- **Extraction**: Strand-specific output, Phred ≥ 10, multiple output formats

## Docker/Singularity Support

- **Image**: `encodedcc/wgbs-pipeline:1.1.7`
- **Singularity**: `docker://encodedcc/wgbs-pipeline:1.1.7`
- All dependencies pre-installed in container
