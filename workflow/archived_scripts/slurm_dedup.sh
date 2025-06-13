#!/bin/bash

# Usage: sbatch slurm_dedup.sh

#SBATCH --job-name=dedup
#SBATCH --time=12:00:00
#SBATCH --mem=48GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=5
#SBATCH --array=1-6

# one may use %j instead of %A in below
#SBATCH --error=/scratch2/sti089/ACC_Pvitticeps_June2022/dedup/log/%A_%a.err
#SBATCH --out=/scratch2/sti089/ACC_Pvitticeps_June2022/dedup/log/%A_%a.out

module load picard/2.26.10

WORK_DIR="/scratch2/sti089/ACC_Pvitticeps_June2022"
BAM_DIR="${WORK_DIR}/kalign"
DEDUP_DIR="${WORK_DIR}/dedup"
LOG_DIR="${DEDUP_DIR}/log"

BAM_FILE=`ls -1 ${BAM_DIR}/${SLURM_ARRAY_TASK_ID}_*_sorted.bam`

if [[ $BAM_FILE =~ \/([[:digit:]]+_[^\/]+)_sorted.bam ]]; then
    BASENAME=${BASH_REMATCH[1]}
else
    echo "unable to parse string $BAM_FILE"
fi

echo "basename $BASENAME"

/bin/date
CMD="JAVAOPTS=-Xmx100g java -jar $PICARD_HOME/picard.jar MarkDuplicates\
	I= ${BAM_DIR}/${SLURM_ARRAY_TASK_ID}_*_sorted.bam \
	O= ${DEDUP_DIR}/${BASENAME}_dedup.bam \
	M= ${LOG_DIR}/${BASENAME}_removeduplicates.metrics.txt \
	REMOVE_DUPLICATES=TRUE \
	BARCODE_TAG=RX"

echo "Executing command [$CMD]..."
eval "$CMD"
echo '  ...completed'
/bin/date


