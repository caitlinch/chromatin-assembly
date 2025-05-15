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
# Species name
#species_name="gecko"
species_name="Pcoll"

# Path to the directory containing raw reads
#data_dir="/scratch3/che318/chromatin-assembly/data/gecko/reads"
data_dir="/scratch3/che318/chromatin-assembly/data/Pcoll/reads"

# Path to the directory where the merged files will be stored
# Should be: /path/to/chromatin-assembly/results/{species}/0_mergedReads
#output_dir="/scratch3/che318/chromatin-assembly/results/gecko/0_mergedReads"
output_dir="/scratch3/che318/chromatin-assembly/results/Pcoll/0_mergedReads"

## Create directory for logs
#log_dir="/Users/che318/Repos/chromatin-assembly/logs/0_mergedReads"
log_dir="/scratch3/che318/chromatin-assembly/logs/0_mergedReads"

sample_ID_keep_first_segment_only=true
name_dict_file="/scratch3/che318/chromatin-assembly/dict"

temp_name_dict="sample_ID|sample_name|sample_lanes
122||8 
111|11One|1 
222|22Two|1,2 
333|33Three|1,2,3 
444|44Four|1,2,3,4 
555|55Five|1,2,3,4,5 
666|66Six|1,2,3,4,5,6 
777||1,2,3,4,5,6,7 
888||1,2,3,4,5,6,7,8 
999|99Nine|
"

# ----------------Your Commands------------------- #
# Create output and log directory (if they don't already exist)
echo "Preparing directories"
mkdir -p $output_dir
mkdir -p $log_dir

echo "Collecting sample IDs"
if [ "$sample_ID_keep_first_segment_only" == "true" ]; then
    echo "Sample ID selection: anything before the first underscore"
    echo "e.g., sample ID is '111' for file 111_22W5TWLT3_TCACACGTGG-TGTATAGGTC_L005_R1.fastq.gz"
    echo "e.g., sample ID is 'PCollREF' for file PCollREF_R2.fastq.gz"
    samples=$(find $data_dir -type f -name "*gz" -exec basename {} \; | \
        grep -i -e "_R1_" -e "_R1\." -e "\.R1\." -e "\.R1_" | \
        awk -F '_' '{print $1}' | \
        sort | \
        uniq )
else
    echo "Sample ID selection: anything before the second underscore"
    echo "e.g., sample ID is '111_22W5TWLT3' for file 111_22W5TWLT3_TCACACGTGG-TGTATAGGTC_L005_R1.fastq.gz"
    echo "e.g., sample ID is 'PCollREF' for file PCollREF_R2.fastq.gz"
    echo "Note: the following strings are removed from sample IDs: '_R1', '.R1.', '.fastq.gz' "
    echo ""
     samples=$(find $data_dir -type f -name "*gz" -exec basename {} \; | \
        grep -i -e "_R1_" -e "_R1\." -e "\.R1\." -e "\.R1_" | \
        awk -F '_' '{print $1"_"$2}' | \
        sort | \
        uniq | \
        sed 's/\.fastq\.gz//' | \
        sed 's/\_R1//' | \
        sed 's/\.R1//' )   
fi

# Print each sample ID
echo "Sample IDs:"
for s_id in ${samples}; do echo $s_id; done
echo "" 

# Merge reads
for s_id in ${samples}; do 
    echo "Sample ID: ${s_id}"
    declare -a R1_files=()
    declare -a R2_files=()
    if grep "${s_id}" -q $name_dict_file; then 
        s_name_str=$(grep "^${s_id}|" $name_dict_file | awk -F '|' '{print $2}')
        if [ -z "$s_name_str" ]; then
            echo "Sample name: -"
            s_output_id=$s_id
        else
            echo "Sample name: ${s_name_str}"
            s_output_id=$s_name_str
        fi
        s_lane_str=$(grep "^${s_id}|" $name_dict_file | awk -F '|' '{print $3}')
        if [ -z "$s_lane_str" ]; then
            echo "Merge lanes provided: FALSE"
            merge_lanes_provided=false
        else
            merge_lanes_provided=true
            echo "Merge lanes provided: TRUE"
            echo "Sample lanes: ${s_lane_str}"
            for lane in $(echo $s_lane_str | tr ',' '\n' | sort); do
                R1_files+=( $(find $data_dir -type f | \
                    grep $s_id | \
                    grep -i -e "[_\.]R1[_\.]" | \
                    grep -i -e $(printf '[_\.]L%03d[_\.]' $lane) ) )
                R2_files+=( $(find $data_dir -type f | \
                    grep $s_id | \
                    grep -i -e "[_\.]R2[_\.]" | \
                    grep -i -e $(printf '[_\.]L%03d[_\.]' $lane) ) )
                apply_cat_command=true
            done
        fi
    else 
        echo "Merge lanes provided: FALSE"
        merge_lanes_provided=false
        s_output_id=$s_id
    fi
    if [ $merge_lanes_provided == "false" ]; then
        echo "Collect all available lanes: TRUE"
        if (find ${data_dir} -type f -exec basename {} \; | grep "${s_id}" | grep -P -q "L[0-9]{3}"); then
            echo "Files with 'L000' pattern found: TRUE"
            sample_all_lanes=$(find ${data_dir} -type f -exec basename {} \; | \
                grep "${s_id}" | \
                grep -oP -i -e "[_\.]L[0-9]{3}[_\.]" | \
                sort | \
                uniq | \
                sed 's/[\._]//g' | \
                sed 's/[Ll]//' | \
                tr '\n' ' ')
            echo "Merging all possible lanes: $(echo $(echo $sample_all_lanes | sed 's/_//g'))"
            R1_files+=( $(find ${data_dir} | \
                grep "${s_id}" | \
                grep -P -i -e "[_\.]L[0-9]{3}[_\.]" | \
                grep -i -e "[_\.]R1[_\.]" | \
                sort) )
            R2_files+=( $(find ${data_dir} | \
                grep "${s_id}" | \
                grep -P -i -e "[_\.]L[0-9]{3}[_\.]" | \
                grep -i -e "[_\.]R2[_\.]" | \
                sort) )
            apply_cat_command=true
        else 
            echo "Files with 'L000' pattern found: FALSE"
            echo "No files for this sample contain lane numbers in the format LXXX, where X is a digit from 0-9"
            apply_cat_command=false
        fi
    fi
    if [ "$apply_cat_command" == "true" ]; then
        echo "Concatenating files for ${s_id}"
        cat $(echo "${R1_files[@]}") > "$output_dir/${s_output_id}_merged_R1.fastq.gz"
        printf "%s\n" ${R1_files[@]}  > "$log_dir/${species_name}.${s_output_id}_merged_R1.log"
        cat $(echo "${R2_files[@]}") > "$output_dir/${s_output_id}_merged_R2.fastq.gz"
        printf "%s\n" ${R2_files[@]}  > "$log_dir/${species_name}.${s_output_id}_merged_R2.log"
        echo "Merging complete for ${s_id}"
    else
        echo "No merging performed for ${s_id}"
    fi
    echo ""
done




