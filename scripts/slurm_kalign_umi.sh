#!/bin/bash

# Usage: sbatch  slurm_kalign_umi.sh

#SBATCH --job-name=kalign_umi
#SBATCH --time=7-00:00:00
#SBATCH --mem=512GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=64
#SBATCH --array=1-6

# one may use %j instead of %A in below
#SBATCH --error=/scratch2/sti089/ACC_Pvitticeps_June2022/kalign/log/%A_%a.err
#SBATCH --out=/scratch2/sti089/ACC_Pvitticeps_June2022/kalign/log/%A_%a.out

READ_DIR="/scratch1/sti089/ACC_Pvitticeps_June2022/umi"
ALIGN_DIR="/scratch2/sti089/ACC_Pvitticeps_June2022/kalign"
DB_DIR="/scratch1/sti089/ACC_Pvitticeps/kit4b_200218_db"
LOG_DIR="${ALIGN_DIR}/log"

module load kit4b/200218

READS1=`ls -1 ${READ_DIR}/${SLURM_ARRAY_TASK_ID}_*_withUMI_R1.fastq`

if [[ $READS1 =~ \/([[:digit:]]+_[^\/]+)_withUMI_R1.fastq ]]; then
    BASENAME=${BASH_REMATCH[1]}
else
    echo "unable to parse string $READS1"
fi

echo "basename $BASENAME"

/bin/date
CMD="ngskit4b kalign -c25 -l25 -d50 -U4 -i${READ_DIR}/${BASENAME}_withUMI_R1.fastq -u${READ_DIR}/${BASENAME}_withUMI_R2.fastq -I ${DB_DIR}/GCF_900067755.1_pvi1.1_genomic_RM_nhmm_adapt -o ${ALIGN_DIR}/${BASENAME}_pe_c25_l25_d50_U4.sam -T ${SLURM_CPUS_PER_TASK} -F ${LOG_DIR}/${BASENAME}_kalign_pe_c25_l25_d50_U4.log"
echo "Executing command [$CMD]..."
eval "$CMD"
echo '	...completed'
/bin/date
