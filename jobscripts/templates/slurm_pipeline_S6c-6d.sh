#!/bin/bash

# Usage: sbatch slurm_pipeline_S6c-6d.sh

# IMPORTANT: before running this step, use the output from Step 6b to update the effective genome
#            size value in the file "config/chromatin_assembly_config.yml", in Section 4: Intermediate output

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S6c-S6d
#SBATCH --time=20:00:00
#SBATCH --mem=5MB # memory for Snakemake - not memory required for individual pipeline steps
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.out

# ----------------Modules------------------------- #
module load python

# ---------------- Pipeline Steps ------------------- #
# Assuming that output from Steps 1-6b is present, run:
#       Step 6c - Compute GC bias with deeptools
#       Step 6d - Correct GC bias with deeptools
# Otherwise, run Steps 1-6d
snakemake --slurm --profile profiles/slurm/ --until s6d_correct_GC_bias --omit s0_merge_samples

