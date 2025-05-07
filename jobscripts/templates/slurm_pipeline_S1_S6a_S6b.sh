#!/bin/bash

# Usage: sbatch slurm_pipeline_S1_S6a_S6b.sh

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S1-S2
#SBATCH --time=100:00:00
#SBATCH --mem=5MB # memory for Snakemake - not memory required for individual pipeline steps
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.out

# ----------------Modules------------------------- #
module load python

# ---------------- Pipeline Steps ------------------- #
# Run:
#       Step 1 - Repeat masking with RepeatMasker and suffix array
#       Step 6a - Generate 2Bit genome with faToTwoBit
#       Step 6b - Calculate effective genome size with faCount
snakemake --slurm --profile profiles/slurm/ --until s1_mask_repeats
snakemake --slurm --profile profiles/slurm/ --use-conda --until s6a_two_bit_genome --omit s0_merge_samples
snakemake --slurm --profile profiles/slurm/ --use-conda --until s6b_effective_genome_size --omit s0_merge_samples

