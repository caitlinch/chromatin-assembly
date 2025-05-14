#!/bin/bash

# Usage: sbatch slurm_waterdragon_RM.sh

#SBATCH --job-name=repeatmasker
#SBATCH --time=2-00:00:00
#SBATCH --mem=80GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=20

# one may use %j instead of %A in below
#SBATCH --error=/datasets/work/efsp-faire/work/sti089/genomes/water_dragon/RM/log/rm_%A_%a.err
#SBATCH --out=/datasets/work/efsp-faire/work/sti089/genomes/water_dragon/RM/log/rm_%A_%a.out

WORK_DIR="/datasets/work/efsp-faire/work/sti089"
INPUT_DIR="${WORK_DIR}/genomes/water_dragon"
OUT_DIR="${INPUT_DIR}/RM"
LIB_DIR="${WORK_DIR}/adapters"

module load repeatmasker/4.1.0

/bin/date
CMD="RepeatMasker -pa ${SLURM_CPUS_PER_TASK} -qq -dir ${OUT_DIR} -lib ${LIB_DIR}/adap_cont_rna.fa  ${INPUT_DIR}/EWD_hifiasm_HiC.fasta"
echo "Executing command [$CMD]..."
eval "$CMD"
echo '  ...completed'
/bin/date
