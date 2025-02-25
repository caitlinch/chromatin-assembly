#!/bin/bash

# Usage: sbatch SLURM_MERGE_SAMPLES.sh

#SBATCH --job-name=merge_samples
#SBATCH --time=01:00:00
#SBATCH --mem=20GB
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mail-user=livia.gerber@csiro.au
#SBATCH --mail-type=END
#SBATCH --account=OD-232072

# one may use %j or %A in below
#SBATCH --error=/scratch3/ger094/Pogona/log/merge_samples.err
#SBATCH --out=/scratch3/ger094/Pogona/log/merge_samples.out

# ----------------Modules------------------------- #
# Add module load commands if necessary
# Example: module load gzip

# ----------------Your Commands------------------- #

# Path to the directory where the data is stored
data_dir="/scratch3/ger094/Pogona/Data/RRBS/AGRF_CAGRF23110335_22NG3KLT3"

# Path to the directory where the merged files will be stored
output_dir="/scratch3/ger094/Pogona/Results/MergedSamples/AllSamples"

# Initialise an empty array for unique sample names
declare -a samples

# Populate the samples array with unique prefixes
for file in "$data_dir"/*_L00*_R*.fastq.gz; do
    sample=$(echo "$(basename "$file")" | sed -E 's/_L[0-9]{3}_[IR][12].fastq.gz//')
    if [[ ! " ${samples[*]} " =~ " ${sample} " ]]; then
        samples+=("$sample")
    fi
done

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

for sample in "${samples[@]}"; do
    # Merge read 1 files for each sample
    cat "$data_dir/${sample}_L00"*"_R1.fastq.gz" > "$output_dir/${sample}_R1_merged.fastq.gz"

    # Merge read 2 files for each sample
    cat "$data_dir/${sample}_L00"*"_R2.fastq.gz" > "$output_dir/${sample}_R2_merged.fastq.gz"
done

echo "Merging completed."
