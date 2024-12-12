# ARID1A GSMM analysis

This repository contains the code to build and analyse Genome Scale Metabolic Models (GSMMs) for cancer lines with ARID1A genes knocked out.

The repo is organised into the following folders:
- `data`: Which contains mainly the RNASeq and the Recon3D models used for further analysis
- `matlab`: Which contains all the MATLAB codes required to build the cell line specific GSMMs from the RNASeq
- `outputs`: Which contains all the intermediate results such as the built models and the flux sampling results
- `python`: The python code for performing Flux Sampling and some simple analysis
- `r_code`: A R Project containing most of the anlaysis code for - enrichment analysis and sampling. Also contains some preliminary code to create reports but one safely ignore it if not interested
- `results`: A folder for all the results obtained

Some of the code requires one to create `.env` file that should contain the variables:
- `COBRATOOLBOX_PATH`: Path to the local installation of CobraToolBox (This is the compulsory one)
- The others as per the needs of the user

List of things to do code-wise:
- [ ] Better code annotations
- [ ] Cleaning up unnecessary ones
- [ ] Configuring pre-commit to ensure clean commits
