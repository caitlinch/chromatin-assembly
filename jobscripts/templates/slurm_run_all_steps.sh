#!/bin/bash

# Usage: sbatch slurm_run_all_steps.sh

# NOTE: Check individual steps for required resources in dir chromatin-assembly/profiles/slurm/config.yaml

#SBATCH --job-name=chrm_assm
#SBATCH --partition=ext
#SBATCH --time=30-00:00:00
#SBATCH --mem=10MB # memory for Snakemake - not memory required for individual pipeline steps
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/logs/slurm_%j_%x.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/logs/slurm_%j_%x.out

# ----------------Modules------------------------- #
module load python
module load miniforge3
source /apps/miniforge3/enable_miniforge.sh

# ---------------- Entire Pipeline ------------------- #
# To perform the entire pipeline in one run (Steps 0 - 8)

## Perform a dry run
snakemake -n -p -c1

## Run chromatin-assembly pipeline (Steps 0-8):
snakemake --slurm --profile profiles/slurm/ --use-conda
