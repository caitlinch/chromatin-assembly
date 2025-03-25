#!/bin/bash

# Usage: sbatch slurm_pipeline_S1-2.sh

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S1-S2
#SBATCH --time=15-00:00:00
#SBATCH --mem=80GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=20
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j.out

# ----------------Modules------------------------- #
module load python

# ---------------- Pipeline Steps ------------------- #
# Run:
#       Step 1 - Repeat masking with RepeatMasker and suffix array
#       Step 2 - Quality control using FastQC
snakemake --slurm --profile profiles/slurm/ --until s2_raw_read_QC --omit s0_merge_samples

