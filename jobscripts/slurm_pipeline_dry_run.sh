#!/bin/bash

# Usage: sbatch slurm_pipeline_dry_run.sh

# NOTE: To perform a dry read without read merging, change line 26 to: 
# snakemake -n -p -c1 --omit s0_merge_samples

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_dryRun
#SBATCH --time=00:01:00
#SBATCH --mem=1MB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.out

# ----------------Modules------------------------- #
module load python

# ---------------- Dry Run ------------------- #
snakemake -n -p -c1
