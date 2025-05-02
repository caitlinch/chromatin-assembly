# chromatin-assembly/resources

This directory contains the following files:

- `adapters/adap_cont_rna.fa`
  - Adapters used for Step 1: Repeat masking with RepeatMasker (`s1_mask_repeats`)
  - You can use any adapters you like for your analysis! To use your own 
  adapters:
    - Copy the adapter file you want to use into the directory 
    `chromatin-assembly/resources/adapters/`
    - Update the adapter file in the `chromatin-assembly-config.yml` file, 
    under the heading "Adapters"
- `slurm_snakemake_conda.yaml`
  - A conda environment containing the Snakemake executor. This executor is 
  necessary to run Snakemake versions 8+.
  - The version of Snakemake on Petrichor (as of 02/05/2025) is v7.24.0
  - This environment is provided so the pipeline can be used with later versions
  of Snakemake (v8+), but is currently not needed.
- `slurm_snakemake_modules.txt`
  - Exported list of modules needed to generate visualisations and run the 
  Snakemake pipeline
  - The module `python` is needed for Snakemake
  - The module `graphviz` is used for saving DAGs and rulegraphs of the
  pipeline, but is not needed to run the pipeline. 
  - Generated with command 
  `modules list > chromatin-assembly/resources/slurm_snakemake_modules.txt`
- `user_update_jobscripts.R`
  - R script to update jobscripts with your own account and email details
  - See `chromatin-assembly/README.me` for more details

