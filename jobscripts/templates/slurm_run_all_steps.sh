#!/bin/bash

# Usage: sbatch slurm_run_all_steps.sh

# IMPORTANT: We recommend running the pipeline in individual steps. We have separated the pipeline
#            into multiple job scripts to faciliate this (see chromatin-assembly/jobscripts files 
#            containing "pipeline" in filename)

# NOTE: Check individual steps for required resources in dir chromatin-assembly/profiles/slurm/
#       The listed resources were used for a dry (test) run and are insufficient for data analysis

#SBATCH --job-name=chrm_assm
#SBATCH --time=100:00:00 
#SBATCH --mem=10MB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=ALL
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.out

# ----------------Modules------------------------- #
module load python

# ---------------- Entire Pipeline ------------------- #
# To perform the entire pipeline in one run (Steps 0 - 8)

## Dry run
# Perform a dry run
snakemake -n -p -c1

## To run chromatin-assembly pipeline (Steps 0-8):
snakemake --slurm --profile profiles/slurm/ --use-conda



