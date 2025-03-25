#!/bin/bash

# Usage: sbatch slurm_pipeline_S3-4.sh

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S3-S4
#SBATCH --time=100:00:00
#SBATCH --mem=512GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=64
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.out

# ----------------Modules------------------------- #
module load python

# ---------------- Pipeline Steps ------------------- #
# Assuming that output from Steps 1-2 is present, run:
#       Step 3 - UMI extraction with FGBio and Picard
#       Step 4 - Align reads with kalign 
# Otherwise, run Steps 1-4
snakemake --slurm --profile profiles/slurm/ --until s4_read_alignment --omit s0_merge_samples

