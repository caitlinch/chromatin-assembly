#!/bin/bash

## Usage: sh S0_input_test.sh species_name path/to/species_dict /path/to/reads /path/to/output/dir /path/to/logs/dir

echo "Script name: $0"
echo "Species name: $1"
echo "Species dictionary: $2"
echo "Reads dir: $3"
echo "Output dir: $4"
echo "Log dir: $5"
echo "Total number of arguments: $#"
echo "All arguments as a string: $*"
echo "All arguments as separate words: $@"

