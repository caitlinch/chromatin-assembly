#!/bin/bash

## Usage: sh S0_MergeSamples.sh {species_name} {provide_merge_dict} {name_dict_file} {data_dir} {output_dir} {log_dir} {sample_ID_keep_first_segment_only}
#   provide_merge_dict: Whether merging dictionary has been provided to defined which lanes/samples to merge (true or false)
#   sample_ID_keep_first_segment_only: true (Sample ID is everything before first underscore) or false (Sample ID is everything before second underscore)

## Example usage:
# repo_dir=/scratch3/che318/chromatin-assembly
# sh S0_MergeSamples.sh "gecko" true "${repo_dir}/data/gecko/gecko_sample_dict.txt" "${repo_dir}/data/gecko/reads" "${repo_dir}/results/gecko/0_merged_reads" "${repo_dir}/logs" true

# Collect input parameters from command line args
script_name=$0
species_name=$1
provide_merge_dict=$2
name_dict_file=$3
data_dir=$4
output_dir=$5
log_dir=$6
sample_ID_keep_first_segment_only=$7


# Print input parameters
echo "Running script ${script_name}"
echo ""
echo "Species name: ${species_name}"
echo "Provide merge dict: ${provide_merge_dict}"
echo "Species dictionary: ${name_dict_file}"
echo "Reads dir: ${data_dir}"
echo "Output dir: ${output_dir}"
echo "Log dir: ${log_dir}"
echo ""


# Create output and log directory (if they don't already exist)
echo "Preparing directories"
mkdir -p $output_dir
mkdir -p $log_dir


# Collect sample IDs
echo "Collecting sample IDs"
if [ "$sample_ID_keep_first_segment_only" == "true" ] ||
    [ "$sample_ID_keep_first_segment_only" == "True" ] ||
    [ "$sample_ID_keep_first_segment_only" == "TRUE" ]; then
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


# Output whether sample dictionary is provided
if [ "$provide_merge_dict" == "True" ] || \
    [ "$provide_merge_dict" == "true" ]|| \
    [ "$provide_merge_dict" == "TRUE" ] && \
    test -f "$name_dict_file" ; then 
    echo "Merge dictionary provided: TRUE"
    echo "Merge dictionary file: ${name_dict_file}"
else
        echo "Merge dictionary provided: FALSE"
fi
echo ""


# Define array to keep problem IDs 
# i.e., those that don't have lane names with "L000" (where 000 can be any 3 digit number)
declare -a problem_samples=()


# Merge reads
for s_id in ${samples}; do 
    echo "Sample ID: ${s_id}"
    declare -a R1_files=()
    declare -a R2_files=()
    if [ "$provide_merge_dict" == "True" ] || \
    [ "$provide_merge_dict" == "true" ]|| \
    [ "$provide_merge_dict" == "TRUE" ] && \
    test -f "$name_dict_file" ; then 
        echo "Checking merge dictionary for sample ${s_id}"
        if grep "${s_id}" -q $name_dict_file; then 
            s_name_str=$(grep "^${s_id}|" $name_dict_file | awk -F '|' '{print $2}')
            if [ -z "$s_name_str" ]; then
                echo "Sample name: ${s_id}"
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
    else
        echo "Merge dictionary provided: FALSE"
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
            problem_samples+=( $(echo $s_id) )
            error_message="ERROR: No files for this sample contain lane numbers in the format LXXX, where X is a digit from 0-9. No merging performed."
            echo "${error_message}" > "$log_dir/${species_name}.${s_output_id}_merged_R1.log"
            echo "${error_message}"> "$log_dir/${species_name}.${s_output_id}_merged_R2.log"
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


if [[ ${#problem_samples[@]} -gt 0 ]]; then
  echo "WARNING: There were issues merging the following samples:"
    for ps in "${problem_samples[@]}"; do
        echo "${ps}"
    done
    echo "Please refer to the error logs for these samples."
    echo ""
fi


echo "Program complete :)"

