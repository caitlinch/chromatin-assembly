#!/bin/bash

# Usage: sbatch slurm_pipeline_S5.sh

# NOTE: Depending on your data, you may need to update the resources in this job script or
#       in the Snakemake slurm profile (chromatin-assembly/profiles/slurm/config.yaml)

#SBATCH --job-name=CA_S5
#SBATCH --time=3-00:00:00
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

# ---------------- Pipeline Steps ------------------- #
## Assuming that output from Steps 0, 1, 3 and 4 is present, run:
# Step 5 - Remove PCR and optical duplicates from alignment with Picard
snakemake \
    --slurm --profile profiles/slurm/ \
    --until s5_alignment_deduplication \
    --omit s2_raw_read_QC,s6a_two_bit_genome,s6b_effective_genome_size
