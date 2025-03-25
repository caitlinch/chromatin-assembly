#!/bin/bash

# Usage: sbatch slurm_pipeline_S0.sh

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S0
#SBATCH --time=01:00:00
#SBATCH --mem=20GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j.out

# ----------------Modules------------------------- #
module load python

# ---------------- Pipeline Steps ------------------- #
# Run:
#       Step 0 - Merge reads
snakemake --slurm --profile profiles/slurm/ --until s0_merge_samples

