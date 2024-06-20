#!/bin/bash

# Usage: sbatch slurm_fastqc.sh

#SBATCH --job-name=fastqc
#SBATCH --time=12:00:00
#SBATCH --mem=12GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=3
#SBATCH --array=1-48

# one may use %j instead of %A in below
#SBATCH --error=/scratch3/sti089/ACC_Pvitticeps_June2022/fastqc/log/%A_%a.err
#SBATCH --out=/scratch3/sti089/ACC_Pvitticeps_June2022/fastqc/log/%A_%a.out

WORK_DIR="/scratch3/sti089/ACC_Pvitticeps_June2022"
FASTQC_DIR="${WORK_DIR}/fastqc"
READS_DIR="${WORK_DIR}/orig_reads"
RESULTS_DIR="${FASTQC_DIR}"

module load fastqc/0.11.9 

CMD="fastqc -t 2 ${READS_DIR}/${SLURM_ARRAY_TASK_ID}_*_R1.fastq ${READS_DIR}/${SLURM_ARRAY_TASK_ID}_*_R2.fastq -o ${RESULTS_DIR}"
echo "Executing command [$CMD]..."
eval "$CMD"
echo '	...completed'
