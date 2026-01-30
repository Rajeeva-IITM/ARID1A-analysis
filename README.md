# ARID1A GSMM analysis

This repository contains the code to build and analyse Genome Scale Metabolic Models (GSMMs) for cancer lines with ARID1A genes knocked out.

## Repository structure

- `data/`: RNASeq data and Recon3D models used for analysis
- `matlab/`: MATLAB code to build cell-line-specific GSMMs from RNASeq data
- `python/`: Python code for flux sampling and data processing
- `r_code/`: R project with analysis code for sampling comparison and enrichment analysis
- `outputs/`: Intermediate results (built models, flux sampling output)
- `results/`: Final analysis results (CSVs, plots)

## Requirements

- **MATLAB** (tested on R2023b) with the [COBRA Toolbox](https://opencobra.github.io/cobratoolbox/)
- **Python 3.12** via conda
- **R 4.3.2** with renv
- **Gurobi solver** with a valid license (free academic licenses available at [gurobi.com](https://www.gurobi.com/academia/academic-program-and-licenses/))

## Setup

### 1. Configuration

Copy the example environment file and fill in your local paths:

```bash
cp .env.example .env
```

Edit `.env` to set `COBRATOOLBOX_PATH` and `GUROBI_LICENSE` to your local installations.

### 2. Python environment

```bash
conda env create -f conda_env.yaml -n conda_env
conda activate conda_env
```

### 3. R environment

Open the R project in `r_code/` and restore packages:

```r
renv::restore()
install.packages("ggvenn")
install.packages("showtext")
```

### 4. MATLAB

Ensure the [COBRA Toolbox](https://opencobra.github.io/cobratoolbox/) is installed and the path is set in `.env`.

## Workflow

**Important**: Run each language's scripts from within its own folder.

### Step 1: Build context-specific models (MATLAB)

```bash
cd matlab
```

Run `build_context_models.m` to build cell-line-specific GSMMs from expression data, then `characterize_contextual_models.m` to evaluate them (growth rates, active reactions).

### Step 2: Flux sampling (Python)

```bash
cd python
```

1. `python preprocess_rnaseq.py` — Preprocesses RNASeq data with Recon gene IDs
2. `python model_sampling.py --help` — Performs OptGPSampler flux sampling on built models (see `--help` for arguments)
3. `python process_sampled_data.py` — Combines sampled flux data across conditions

### Step 3: Statistical analysis (R)

```bash
cd r_code
```

The analysis scripts in `Analysis code/` source helper functions from `sampling_analysis/` and `enrichment_analysis/`. Run them in this order:

1. `source('sampling_analysis/sampling_analysis.r')` — Loads comparison and bootstrap functions
2. `source('Analysis code/arid1a_cell_line.R')` — Main ARID1A WT vs KO analysis
3. `source('Analysis code/clus_vs_disp.R')` — Clustered vs dispersed comparison
4. `source('Analysis code/macir.R')` — MACIR dataset analysis

## TODO

- [ ] Better code annotations
- [ ] Cleaning up unnecessary code
- [ ] Configuring pre-commit to ensure clean commits
