#!/bin/bash

## Usage: sh S0_MergeSamples.sh {species_name} {samples_txt} {use_merge_dict} {name_dict_file} {data_dir} {output_dir} {log_dir}
#   use_merge_dict: Whether merging dictionary has been provided to defined which lanes/samples to merge ("yes" or "no")

# Collect input parameters from command line args
script_name=$0
species_name=$1
samples_txt=$2
use_merge_dict=$3
name_dict_file=$4
data_dir=$5
output_dir=$6
log_dir=$7


# Print input parameters
echo "Running script ${script_name}"
echo ""
echo "Species name: ${species_name}"
echo "Samples record: ${samples_txt}"
echo "Use merge dict: ${use_merge_dict}"
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
mapfile -t samples < $samples_txt


# Print each sample ID
echo "Sample IDs:"
for s_id in ${samples[@]}; do echo $s_id; done
echo "" 


# Output whether sample dictionary is provided
if [ "$use_merge_dict" == "yes" ] || \
    [ "$use_merge_dict" == "Yes" ]|| \
    [ "$use_merge_dict" == "YES" ] ||
    [ "$use_merge_dict" == "y" ] ||
    [ "$use_merge_dict" == "Y" ]&& \
    test -f "$name_dict_file" ; then 
    echo "Merge dictionary provided: TRUE"
    echo "Merge dictionary file: ${name_dict_file}"
    check_dict=true
else
    echo "Merge dictionary provided: FALSE"
    check_dict=false
fi
echo ""


# Define array to keep problem IDs 
# i.e., those that don't have lane names with "L000" (where 000 can be any 3 digit number)
declare -a problem_samples=()


# Merge reads
for s_id in ${samples[@]}; do 
    echo "Sample ID: ${s_id}"
    declare -a R1_files=()
    declare -a R2_files=()
    if [ "$check_dict" == "true" ] ; then 
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

