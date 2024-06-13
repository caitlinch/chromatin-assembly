#!/bin/bash

# Usage: sbatch  slurm_sizemetrics.sh

#SBATCH --job-name=metrics
#SBATCH --time=01:00:00
#SBATCH --mem=6GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --array=1-6

# one may use %j instead of %A in below
#SBATCH --error=/scratch2/sti089/ACC_Pvitticeps_June2022/dedup/metrics/log/%A_%a.err
#SBATCH --out=/scratch2/sti089/ACC_Pvitticeps_June2022/dedup/metrics/log/%A_%a.out

WORK_DIR="/scratch2/sti089/ACC_Pvitticeps_June2022/dedup"
BAM_DIR="${WORK_DIR}"
SPECIES="pogo_dedup"
OUT_DIR="${WORK_DIR}/metrics"

module load picard/2.26.10
module load R

BAM_FILE=`ls -1 ${BAM_DIR}/${SLURM_ARRAY_TASK_ID}_*_dedup.bam`

if [[ $BAM_FILE =~ \/([[:digit:]]+_[^\/]+).bam ]]; then
    BASENAME=${BASH_REMATCH[1]}
else
    echo "unable to parse string $BAM_FILE"
fi

echo "basename $BASENAME"

CMD="JAVAOPTS=-Xmx20g java -jar $PICARD_HOME/picard.jar CollectInsertSizeMetrics \
      I=${BAM_FILE} \
      O=${OUT_DIR}/${SPECIES}_${BASENAME}_insert_size_metrics.txt \
      H=${OUT_DIR}/${SPECIES}_${BASENAME}_insert_size_histogram.pdf"

echo "Executing command [$CMD]..."
eval "$CMD"
echo '  ...completed'
/bin/date
