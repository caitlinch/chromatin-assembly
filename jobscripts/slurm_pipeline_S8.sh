#!/bin/bash

# Usage: sbatch slurm_pipeline_S8.sh

# IMPORTANT: If you do not want to perform peak analysis with DANPOS, do not run this file

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S8
#SBATCH --time=60:00:00
#SBATCH --mem=48GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j_S8.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j_S8.out

# ----------------Modules------------------------- #
module load python

# ---------------- Pipeline Steps ------------------- #
# Assuming that output from Steps 1-7b is present, run:
#       Step 8 - Peak analysis with DANPOS
# Otherwise, run Steps 1-8
snakemake --slurm --profile profiles/slurm/ --until s8_peak_analysis --omit s0_merge_samples
