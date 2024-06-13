#!/bin/bash

# Usage: sbatch  slurm_correctGCBias.sh

#SBATCH --job-name=correctGCbias
#SBATCH --time=12:00:00
#SBATCH --mem=48GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --array=1-6

# one may use %j instead of %A in below
#SBATCH --error=/scratch2/sti089/ACC_Pvitticeps_June2022/GCcorrect/log/%A_%a.err
#SBATCH --out=/scratch2/sti089/ACC_Pvitticeps_June2022/GCcorrect/log/%A_%a.out

WORK_DIR="/scratch2/sti089/ACC_Pvitticeps_June2022"
BAM_DIR="${WORK_DIR}/dedup"
GC_CORRECT_DIR="${WORK_DIR}/GCcorrect"
GC_COMPUTE_DIR="${WORK_DIR}/GCcompute"
BIT_DIR="${WORK_DIR}/bit"

module load python/3.9.4
module load samtools/1.12

BAM_FILE=`ls -1 ${BAM_DIR}/${SLURM_ARRAY_TASK_ID}_*_dedup.bam`

if [[ $BAM_FILE =~ \/([[:digit:]]+_[^\/]+)_dedup.bam ]]; then
    BASENAME=${BASH_REMATCH[1]}
else
    echo "unable to parse string $BAM_FILE"
fi

echo "basename $BASENAME"

/bin/date
CMD="correctGCBias_kalign -p ${SLURM_CPUS_PER_TASK} -b ${BAM_DIR}/${SLURM_ARRAY_TASK_ID}_*_dedup.bam --effectiveGenomeSize 1716675060 -g ${BIT_DIR}/GCF_900067755.1_pvi1.1_genomic_RM_nhmm_adapt.2bit --GCbiasFrequenciesFile ${GC_COMPUTE_DIR}/${SLURM_ARRAY_TASK_ID}_*.txt -o ${GC_CORRECT_DIR}/${BASENAME}_gc_corrected.bam"
echo "Executing command [$CMD]..."
eval "$CMD"
echo '	...completed'
/bin/date
