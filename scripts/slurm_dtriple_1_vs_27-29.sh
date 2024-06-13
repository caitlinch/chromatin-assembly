#!/bin/bash

# Usage: sbatch slurm_dtriple_1_vs_27-29.sh

#SBATCH --job-name=dtriple
#SBATCH --time=60:00:00
#SBATCH --mem=48GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2

# one may use %j instead of %A in below
#SBATCH --error=/scratch2/sti089/ACC_Pvitticeps_June2022/dtriple/1_vs_27-29/log/%A_%a.err
#SBATCH --out=/scratch2/sti089/ACC_Pvitticeps_June2022/dtriple/1_vs_27-29/log/%A_%a.out

BASE_DIR="/scratch2/sti089/ACC_Pvitticeps_June2022"
TEST_DIR="${BASE_DIR}/GCcorrect/bed/test/1/"
INPUT_DIR="${BASE_DIR}/GCcorrect/bed/input/27-29/"
RESULTS_DIR="${BASE_DIR}/dtriple/1_vs_27-29/"

module load danpos/3.1.1

CMD="danpos.py dtriple ${TEST_DIR}:${INPUT_DIR} -o ${RESULTS_DIR}"
echo "Executing command [$CMD]..."
eval "$CMD"
echo '	...completed'
