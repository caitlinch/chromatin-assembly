# chromatin-assembly pipeline
# Documentation

# Caitlin Cherryh, June 2024
# Original scripts by Erin Hahn and Jiri Stiller

## Set up


## Configuration file


## Calling Snakemake
Snakemake starts by seeing whether your desired output file exists.
If it doesn't it looks for the steps to generate that output file. 
It follows this process until it identifies a file it does have, then works forwards from there.

## Running Slurm


## Help! This pipeline doesn't use the right command line arguments for my data
All rules in this pipeline were developed from Erin and Jiri's scripts, which are included in this repository: see workflow/scripts/
If your data requires different parameters, you can update them within your copy of the Snakefile

For example: Step 4 is align reads with kalign
The default command has the settings: ngskit4b kalign -c25 -l25 -d50 -U4
If you wanted to change the minimum chimeric length, you can edit this command in the Snakemake file
e.g.  ngskit4b kalign -c50 -l25 -d50 -U4 -i[.....]
Save your changes and run the pipeline as described above.

