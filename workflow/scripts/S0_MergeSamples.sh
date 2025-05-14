#!/bin/bash

# Usage: sbatch S0_MergeSamples.sh

#SBATCH --job-name=CA_S0
#SBATCH --time=01:00:00
#SBATCH --mem=20GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=caitlin.cherryh@csiro.au
#SBATCH --mail-type=END
#SBATCH --account=OD-232072

# one may use %j or %A in below
#SBATCH --error=/scratch3/ger094/Pogona/log/merge_samples.err
#SBATCH --out=/scratch3/ger094/Pogona/log/merge_samples.out

# ----------------Modules------------------------- #
# Add module load commands if necessary

# ----------------Input Variables------------------- #
# Path to the directory containing raw reads
#data_dir="/Users/che318/Repos/chromatin-assembly/data/gecko/reads"
data_dir="/Users/che318/Repos/chromatin-assembly/data/Pcoll/reads"

# Path to the directory where the merged files will be stored
# Should be: /path/to/chromatin-assembly/results/{species}/0_mergedReads
#output_dir="/Users/che318/Repos/chromatin-assembly/results/gecko/0_mergedReads"
output_dir="/Users/che318/Repos/chromatin-assembly/results/Pcoll/0_mergedReads"

## Create directory for logs
log_dir="/Users/che318/Repos/chromatin-assembly/logs/0_mergedReads/"

# ----------------Your Commands------------------- #
# Create output and log directory (if they don't already exist)
echo "Preparing directories"
mkdir -p "$output_dir"
mkdir -p "$log_dir"

# Find all .fastq.gz files (in the $data_dir and in subdirectories)
echo "Collecting .fastq.gz files"
all_fastq=$(find $data_dir -type f -name "*.fastq.gz")

# Initialise an empty array for unique sample names
declare -a samples=()

# Collect sample IDs - that is, everything before the first underscore
# Deprecated regex line: sample=$(echo "$(basename "$file")" | sed -E 's/_[A-Za-z0-9]+_[ACTG]+-[ACTG]+_L[0-9]{3}_[IR][12]\.fastq\.gz//')
echo "Collecting sample IDs"
for file in $(echo $all_fastq); do
    sample=$(echo "$(basename "$file")" | awk -F'_' {'print $1'})
    if [[ ! " ${samples[*]} " =~ " ${sample} " ]]; then
        echo $sample
        samples+=("$sample")
    fi
done

# Concatenate R1 and R2 files for each sample (+ output log of which files were concatenated)
echo "Merging reads per sample:"
for sample in "${samples[@]}"; do
    echo $sample
    cat `find $data_dir | grep $sample | grep "_R1" | sort` > "$output_dir/${sample}_merged_R1.fastq.gz"
    find $data_dir | grep $sample | grep "_R1" | sort > "$log_dir/${sample}_merged_R1.log"
    cat `find $data_dir | grep $sample | grep "_R2" | sort` > "$output_dir/${sample}_merged_R2.fastq.gz"
    find $data_dir | grep $sample | grep "_R2" | sort > "$log_dir/${sample}_merged_R2.log"
done
echo "Merging complete"
echo "Log directory: ${log_dir}"

