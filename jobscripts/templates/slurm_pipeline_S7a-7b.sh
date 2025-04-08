#!/bin/bash

# Usage: sbatch slurm_pipeline_S7a-7b.sh

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S7a-S7b
#SBATCH --time=03:00:00
#SBATCH --mem=5MB # memory for Snakemake - not memory required for individual pipeline steps
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.out

# ----------------Modules------------------------- #
module load python

# ---------------- Pipeline Steps ------------------- #
# Assuming that output from Steps 1-6d is present, run:
#       Step 7a - Calculate alignment statistics with Picard 
#       Step 7b - Estimate mean nuclear genome cover with Picard 
snakemake --slurm --profile profiles/slurm/ --until s7a_size_metrics --omit s0_merge_samples
snakemake --slurm --profile profiles/slurm/ --until s7b_read_count --omit s0_merge_samples
