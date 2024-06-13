#!/bin/bash

# Usage: sbatch  slurm_read_count_GCcorrect.sh

#SBATCH --job-name=view
#SBATCH --time=01:00:00
#SBATCH --mem=6GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --array=1-6

# one may use %j instead of %A in below
#SBATCH --error=/scratch2/sti089/ACC_Pvitticeps_June2022/GCcorrect/read_count/log/%A_%a.err
#SBATCH --out=/scratch2/sti089/ACC_Pvitticeps_June2022/GCcorrect/read_count/log/%A_%a.out

WORK_DIR="/scratch2/sti089/ACC_Pvitticeps_June2022/GCcorrect"
BAM_DIR="${WORK_DIR}"
OUT_DIR="${WORK_DIR}/read_count"

module load samtools/1.12

BAM_FILE=`ls -1 ${BAM_DIR}/${SLURM_ARRAY_TASK_ID}_*_gc_corrected.bam`

if [[ $BAM_FILE =~ \/([[:digit:]]+_[^\/]+).bam ]]; then
    BASENAME=${BASH_REMATCH[1]}
else
    echo "unable to parse string $BAM_FILE"
fi

echo "basename $BASENAME"

CMD="samtools view -c ${BAM_FILE} -o ${OUT_DIR}/${BASENAME}_count.txt"
echo "Executing command [$CMD]..."
eval "$CMD"
echo '  ...completed'
/bin/date
