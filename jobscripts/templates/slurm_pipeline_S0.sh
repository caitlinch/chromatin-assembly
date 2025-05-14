#!/bin/bash

# Usage: sbatch slurm_pipeline_S0.sh

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S0
#SBATCH --time=01:00:00
#SBATCH --mem=5MB # memory for Snakemake - not memory required for individual pipeline steps
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

# ---------------- Pipeline Steps ------------------- #
# Run:
#       Step 0 - Merge reads
snakemake --slurm --profile profiles/slurm/ --use-conda --until s0_merge_samples --omit s1_mask_repeats,s2_raw_read_QC,s3_extract_UMI
