#!/bin/bash

# Usage: sbatch slurm_pipeline_S5-6b.sh

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S5-S6b
#SBATCH --time=14-00:00:00
#SBATCH --mem=48GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=5
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j_S5-S6b.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j_S5-S6b.out

# ----------------Modules------------------------- #
module load python

# ---------------- Pipeline Steps ------------------- #
# Assuming that output from Steps 1-4 is present, run:
#       Step 5 - Remove PCR and optical duplicates from alignment with Picard (slurm_depup.sh)
#       Step 6a - Generate 2Bit genome with faToTwoBit
#       Step 6b - Calculate effective genome size with faCount
# Otherwise, run Steps 1-6b
snakemake --slurm --profile profiles/slurm/ --until s6b_effective_genome_size --omit s0_merge_samples

