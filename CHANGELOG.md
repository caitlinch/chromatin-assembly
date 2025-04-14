
# Change Log
All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).
  
## [Unreleased] - yyyy-mm-dd
 
### Added
- R script (`workflow/R/s0_merge_reads.R`) to merge reads into one R1 and one R2 file per sample name 
- `README.md` now contains full quick-start guide with some troubleshooting tips
- Example of user input data in `data/template/`
 
### Changed
- Updated documentation
    - Updated pipeline structure and repository structure in `doco/start_here.Rmd`
 
### Fixed
- Added multi-sample input
    - Restructured all rules to operate per sample (i.e., given a list of samples, the pipeline now applies each step for each sample)
 
 
## [0.1.0] - 2025-04-08

First release. Both minor and major improvements still pending.

### Added
- Snakemake pipeline to perform archival chromatin assembly
  - Pipeline currently runs successfully for one sample from Steps 1 to 7b
- User documentation
- Job script templates 
- R script allowing users to update job script templates with their SLURM details
- Profiles for running the pipeline on the CSIRO Petrichor HPC and locally
- A copy of the scripts this pipeline was developed from
