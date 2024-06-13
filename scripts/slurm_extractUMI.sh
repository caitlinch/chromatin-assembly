#!/bin/bash

# Usage: sbatch slurm_extractUMI.sh

#SBATCH --job-name=UMIext
#SBATCH --time=3-00:00:00
#SBATCH --mem=512GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=64
#SBATCH --array=1-6

# one may use %j instead of %A in below
#SBATCH --error=/scratch1/sti089/ACC_Pvitticeps_June2022/umi/log/%A_%a.err
#SBATCH --out=/scratch1/sti089/ACC_Pvitticeps_June2022/umi/log/%A_%a.out

module load picard/2.26.9
module load fgbio/1.3.0

WORK_DIR="/scratch1/sti089/ACC_Pvitticeps_June2022"
READ_DIR="${WORK_DIR}/merged_reads"
UMI_DIR="${WORK_DIR}/umi"

READS1=`ls -1 ${READ_DIR}/${SLURM_ARRAY_TASK_ID}_*_R1.fastq`
if [[ $READS1 =~ \/([[:digit:]]+_[^\/]+)_R1.fastq ]]; then
    BASENAME=${BASH_REMATCH[1]}
else
    echo "unable to parse string $READS1"
fi

echo "basename $BASENAME"

cd ${UMI_DIR}

/bin/date

CMD1="JAVAOPTS=-Xmx2g java -jar $PICARD_HOME/picard.jar FastqToSam \
	F1= ${READ_DIR}/${SLURM_ARRAY_TASK_ID}_*_R1.fastq \
	F2= ${READ_DIR}/${SLURM_ARRAY_TASK_ID}_*_R2.fastq \
	O= ${BASENAME}_unmapped.bam \
	SM= ${BASENAME}"

echo "Executing command [$CMD1]..."
eval "$CMD1"
echo '  ...completed'

/bin/date

CMD2="JAVAOPTS=-Xmx50g java -jar $FGBIO_HOME/fgbio-1.3.0.jar ExtractUmisFromBam \
	--input=${BASENAME}_unmapped.bam --output=${BASENAME}_unmapped.withUMI.bam \
	--read-structure=8M143T 8M143T --molecular-index-tags=ZA ZB --single-tag=RX"

echo "Executing command [$CMD2]..."
eval "$CMD2"
echo '  ...completed'

/bin/date

CMD3="JAVAOPTS=-Xmx2g java -jar $PICARD_HOME/picard.jar SamToFastq \
	I= ${BASENAME}_unmapped.withUMI.bam \
	F= ${BASENAME}_withUMI_R1.fastq \
	F2= ${BASENAME}_withUMI_R2.fastq" 

echo "Executing command [$CMD3]..."
eval "$CMD3"
echo '  ...completed'

/bin/date
