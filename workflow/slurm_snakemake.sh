#!/bin/bash

# Usage: sbatch workflow/slurm_snakemake.sh

#SBATCH --job-name="1_repeatmasker"
#SBATCH --time=2-00:00:00 # 2 days
#SBATCH --mem=80GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=20

# one may use %j instead of %A in below
#SBATCH --error=/scratch3/che318/snakemake_tut/results/smt_%A_%a.err
#SBATCH --out=/scratch3/che318/snakemake_tut/results/smt_%A_%a.out

module load python
cd /scratch3/che318/snakemake_tut/
snakemake -s workflow/Snakefile --reason --printshellcmds /scratch3/che318/snakemake_tut/results/b_a.txt


