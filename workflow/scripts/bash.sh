READS1=`ls -1 /Users/caitlin/Repositories/chromatin-assembly/results/test_rules/step2_FastQC_*_R1.fastq`
if [[ $READS1 =~ \/([[:digit:]]+_[^\/]+)_R1.fastq ]]; then
    BASENAME=${BASH_REMATCH[1]}
else
    echo "unable to parse string $READS1"
fi