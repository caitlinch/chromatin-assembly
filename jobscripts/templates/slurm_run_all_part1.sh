#!/bin/bash

# Usage: sbatch slurm_run_all_part1.sh

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_1
#SBATCH --time=30-00:00:00
#SBATCH --partition=ext
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
#       Step 1 - Repeat masking with RepeatMasker and suffix array
#       Step 6a - Generate 2Bit genome with faToTwoBit
#       Step 6b - Calculate effective genome size with faCount
snakemake --slurm --profile profiles/slurm/ --until s1_mask_repeats
snakemake --slurm --profile profiles/slurm/ --use-conda --until s6a_two_bit_genome --omit s0_merge_samples
snakemake --slurm --profile profiles/slurm/ --use-conda --until s6b_effective_genome_size --omit s0_merge_samples

# Run:
#       Step 2 - Quality control using FastQC
snakemake --slurm --profile profiles/slurm/ --until s2_raw_read_QC --omit s1_mask_repeats,s3_extract_UMI

# Run:
#       Step 3 - UMI extraction with FGBio and Picard
#       Step 4 - Align reads with kalign 
#       Step 5 - Remove PCR and optical duplicates from alignment with Picard
snakemake --slurm --profile profiles/slurm/ --until s5_alignment_deduplication --omit s2_raw_read_QC,s6a_two_bit_genome,s6b_effective_genome_size
