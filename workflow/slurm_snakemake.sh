#!/bin/bash

# Usage: sbatch workflow/slurm_snakemake.sh

#SBATCH --job-name=snakemaketut
#SBATCH --time=00:10:00 # 10 minutes
#SBATCH --mem=100KB # 0.1 MB, 0.0001 GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1

# one may use %j instead of %A in below
#SBATCH --error=/scratch3/che318/snakemake_tut/results/smt_%A_%a.err
#SBATCH --out=/scratch3/che318/snakemake_tut/results/smt_%A_%a.out

cd /scratch3/che318/snakemake_tut/
snakemake -s workflow/Snakefile --reason --printshellcmds /scratch3/che318/snakemake_tut/results/b_a.txt



