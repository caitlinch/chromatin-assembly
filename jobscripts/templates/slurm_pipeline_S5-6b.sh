#!/bin/bash

# Usage: sbatch slurm_pipeline_S5-6b.sh

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S5-S6b
#SBATCH --time=160:00:00
#SBATCH --mem=5MB # memory for Snakemake - not memory required for individual pipeline steps
#SBATCH --nodes=1
#SBATCH --cpus-per-task=5
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --account=OD-233464
#SBATCH --error=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.err
#SBATCH --out=/scratch3/che318/chromatin-assembly/log/slurm_%j_%x.out

# ----------------Modules------------------------- #
module load python

# ---------------- Pipeline Steps ------------------- #
# Assuming that output from Steps 1-4 is present, run:
#       Step 5 - Remove PCR and optical duplicates from alignment with Picard (slurm_depup.sh)
#       Step 6a - Generate 2Bit genome with faToTwoBit
#       Step 6b - Calculate effective genome size with faCount
# Otherwise, run Steps 1-6b

# Note: These three steps do not have interconnected dependencies (i.e., 6b is not dependent on 6a)
#       so to run all three I specifically instruct Snakemake to run each step independently.
#       All three steps are required to run Step 6c (Compute GC bias with deeptools)
#       We cannot skip ahead to Step 6C, as we need to manually enter the effective genome size 
#       (output from Step 6b) into the config/chromatin_assembly_config.yml files
snakemake --slurm --profile profiles/slurm/ --until s5_alignment_deduplication --omit s0_merge_samples
snakemake --slurm --profile profiles/slurm/ --until s6a_two_bit_genome --omit s0_merge_samples
snakemake --slurm --profile profiles/slurm/ --until s6b_effective_genome_size --omit s0_merge_samples

