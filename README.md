# chromatin-assembly

TODO DOCO Put citation here

---

**Table of Contents:**

- [Summary](#summary)
- [Pipeline development and testing](#pipeline-development-and-testing)
- [Quickstart guide for the time-impaired](#quickstart-guide-for-the-time-impaired)
- [Merging reads](#merging-reads)
- [Updating Slurm jobscripts](#updating-slurm-jobscripts)
- [Pipeline steps](#pipeline-steps)
- [Snakemake command lines](#snakemake-command-lines)
- [Having problems?](#having-problems)
  - [Troubleshooting](#troubleshooting)
  - [Potential issues](#potential-issues)

----

## Summary

This is a Snakemake pipeline to perform chromatin assembly and analysis. 

This document is a quick-start guide to get the pipeline running. Detailed 
documentation is provided in the `doco/` directory.

----

## Pipeline development and testing
This pipeline was developed to be run on:

- the Petrichor server (at CSIRO)
- Using Slurm
- Using environment modules

It has not been tested in other environments.

#### Running the pipeline on other HPC systems

For convenience adapting the pipeline to other HPC environments, we provide an 
(untested!) version of the pipeline for use on other environments. This version
is located at `chromatin-assembly/workflow/conda_only_version/` and uses conda
environments (instead of environment modules) so it is more transferable. 

The main files for the conda-only version of the pipeline are:

- The Snakefile
  - `workflow/conda_only_version/Snakefile`
- The config file
  - `workflow/conda_only_version/chromatin-assembly_config.yml`
- The conda environments
  - `workflow/conda_only_version/envs/`

See `doco/08_use_on_alternative_HPCs.Rmd` for details on using this version of 
the pipeline.



----

## Quickstart guide for the time-impaired

**Note:** These steps have been tested on Petrichor and locally (MacOS v15.3.1, Apple M2 Pro Chip).

1. Download the [caitlinch/chromatin-assembly](https://github.com/caitlinch/chromatin-assembly) GitHub repository and move it to where you want to run your pipeline 
    - For example, my directory is `/scratch3/che318/chromatin-assembly/`
2. Navigate in terminal to the `chromatin-assembly/` directory
    - **Command**: `cd /scratch3/che318/chromatin-assembly/`
3. Add your data to the `data/` directory
    - Within the chromatin-assembly directory, create a directory called `data/` 
    - Create a new directory within `data/`, named after your species (e.g., `data/gecko/`). 
    - Inside the species folder, create two folders: `reads/`, and `reference_genome/`
    - Copy your data into the relevant files. 
    - The directories should look like something like this (where `{species}` is replaced with your species name):
      - `chromatin-assembly/data/{species}/reads/` – contains raw reads (`.fastq.gz`), both experimental data and input control for DANPOS3 (peak analysis)
      - `chromatin-assembly/data/{species}/reference_genome/` – contains reference genome in fasta (`.fasta`, `.fsa`, `.fna` etc.) file format
4. Specify parameters for your dataset
    - Open the file `config/chromatin_assembly_config.yml` and update file paths and parameters for your data
5. Update Snakemake profiles
    - Snakemake uses profiles to determine what computational resources to use for each step on each system
    - Update the account ID in each of the following files:
      - `chromatin-assembly/profiles/hpc_test/config.yaml` -- profile for dry runs and testing
      - `chromatin-assembly/profiles/slurm/config.yaml` -- profile for pipeline runs
6. Use Snakemake to generate conda environments needed for pipeline Steps 1 and 6
    - **Load python module:** `module load python`
    - **Generate conda environments:** `snakemake --use-conda --conda-create-envs-only -c1`
7. Generate Slurm job scripts using the R script `resources/user_update_jobscripts.R`:
    - **Command**: `module load R`
    - **Command**: `Rscript resources/user_update_jobscripts.R mail-user={email@email.com} mail-type={when_mail} account={account}`
	  - Replace each set of curly brackets with your preferred Slurm details
	  - **e.g.,** `Rscript resources/user_update_jobscripts.R mail-user=test@test.com mail-type=FAIL account=OD-123456`
	  - See "Updating Slurm jobscripts" below for more details
8. Perform a dry run of the full pipeline:
    - Load Python module to access Snakemake: `module load python`
    - **In terminal**: `snakemake -n -p -c1`
    - **By job script**: `sbatch jobscripts/pipeline_dry_run.sh`
9. Perform Step 0 (Merge reads):
    - **Command**: `sbatch jobscripts/slurm_pipeline_S0.sh`
10. Perform Step 1 (read masking), Step 6a (generate two bit genome) and Step 6b (calculate genome size):
    - **Command**: `sbatch jobscripts/slurm_pipeline_S1_S6a_S6b.sh`    
11. Perform Step 2 (read QC):
  - **Command**: `sbatch jobscripts/slurm_pipeline_S2.sh`    
12. Perform Step 3 (UMI extraction), Step 4 (align reads) and Step 5 (remove duplicates):  
  - **Command**: `sbatch jobscripts/slurm_pipeline_S3-5.sh`    
13. Update the effective genome size value
    - Open file `config/chromatin_assembly_config.yml`
    - Update effective genome size value in "Section 4: Intermediate output"
    - Effective genome size is extracted from output of Step 6b, and calculated as the number of non-N bases in the genome
        - i.e., (Total length) - (Total N)
14. Perform Step 6c (compute GC bias) and Step 6d (correct GC bias)
    - **Command**: `sbatch jobscripts/slurm_pipeline_S6c-6d.sh`
15. Perform Step 7a (calculate alignment statistics) and 7b (estimate mean nuclear genome covert): 
    - **Command**: `sbatch jobscripts/slurm_pipeline_S7a-7b.sh`
16. *(Optional)* Perform Step 8 (peak analysis with DANPOS):
    - Update DANPOS run parameters in config file
      - Open file `config/chromatin_assembly_config.yml`
      - Go to "Input control for peak analysis with DANPOS (Step 8)" and enter desired sample IDs and test name.
    - **Command**: `sbatch jobscripts/slurm_pipeline_S8.sh`


#### Running multiple Snakemake instances
*See the documentation: [How does Snakemake lock the working directory?](https://snakemake.readthedocs.io/en/stable/project_info/faq.html#how-does-snakemake-lock-the-working-directory)*

Snakemake locks a working directory by input and output files. It's not possible
to run multiple instances that want to create the same output files. 

However, you can run two instances that generate separate and disjoint sets of 
output files.

For example, you may wish to run at the same time:

- Step 2 (Raw read QC) using `jobscripts/slurm_pipeline_S2.sh`
- Steps 1, 6a, and 6b (reference genome processing) using `jobscripts/slurm_pipeline_S2.sh`

You can do this at your own risk by adding the command line option `--nolock`

e.g., to run Step 1 (mask repeats) without locking:

```
snakemake --slurm --profile profiles/slurm/ --until s1_mask_repeats --nolock
```

If you use the `--nolock` option, be very careful that there are no rules running
in both instances of Snakemake. 

To test this, you can do a dry run and compare thelist of rules that will be 
run in each instance. Also check the input/output files and make sure there are 
no overlapping files between the two instances.

#### Recommendations on running the pipeline
You can run the whole pipeline using the jobscript `slurm_run_all_steps.sh`.
This is not recommended unless you already know the effective genome size, as
Steps 6c and 6d require those as input. If you do not have the correct effective
genome size, Steps 6c and 6d will run with whatever value is present in the 
`config/chromatin_assembly_config.yml` file, which may not be correct for your data

To run the pipeline in as few steps as possible:

- Follow steps 1-7 from the Quickstart Guide above 
- Run pipeline steps 0 - 6b:
    - **Command:** `snakemake --slurm --profile profiles/slurm/ --use-conda --until s6b_effective_genome_size`
    - The `--use-conda` flag is important for Steps 0, 6a and 6b!
    - If the above command doesn't run Step 2 (due to input/output dependencies), run it separately with
    `snakemake --slurm --profile profiles/slurm/ --until s2_raw_read_QC`
- Update the effective genome size value in the file `config/chromatin_assembly_config.yml`
- Run pipeline steps 6c - 8
    - Due to the rule dependencies, you will have to enter multiple Snakemake commands
    to run these steps
    - **Command:** `snakemake --slurm --profile profiles/slurm/ --until s6d_correct_GC_bias`
    - **Command:** `snakemake --slurm --profile profiles/slurm/ --until s7a_size_metrics`
    - **Command:** `snakemake --slurm --profile profiles/slurm/ --until s7b_read_count`
    - **Command:** `snakemake --slurm --profile profiles/slurm/ --until s8_peak_analysis`

Petrichor has a wall time limit of 160 hours. Running the pipeline in two chunks
like this means you may hit a wall time limit. 

-----

## Merging reads

For all analyses:

- Specify the input directory in `read_dir` e.g., `read_dir: /full/path/to/chromatin-assembly/data/gecko/reads/`
- Input the sample IDs you want to analyse in `merge_sample_ids` e.g., `merge_sample_ids: ["id01", "id02", "id03"]`
- **If you want to combine reads from multiple subdirectories inside the `read_dir`:**
  - Set `merge_across_dirs: TRUE`
  - Replace sample IDs with nice human readable names
  - Set `use_names: TRUE`
  - Provide names in `sample_names` e.g., `sample_names: ["id01": "name01", "id02": "name02", "id03": "name03"]`
  
There are multiple options for merging reads:

- **Merge reads from all lanes for all samples**
  - Output:  one R1/R2 file for each sample ID, all lanes merged
  - Set `merge_all_lanes: TRUE`
  - Set `read_lanes: []`
  - Set `specify_sample_lanes: FALSE`
  - Set `sample_lanes: []`
- **Merge reads from specific lanes for all samples**
  - Output:  one R1/R2 file for each sample ID, only specific lanes merged, same lanes for each sample ID
  - Set `merge_all_lanes: FALSE`
  - Specify lanes to merge in `read_lanes` e.g., `read_lanes: ["1", "2", "3", "4", "5", "6", "7", "8"]`
  - Set `specify_sample_lanes: FALSE`
  - Set `sample_lanes: []`
- **Merge reads from different user-specified lanes for each sample**
  - Output:  one R1/R2 file for each sample ID, merging specific lanes, different lanes for different sample IDs
  - Set `merge_all_lanes: FALSE`
  - Set `read_lanes: []`
  - Set `specify_sample_lanes: TRUE`
  - Specify `sample_lanes` with lanes to merge for each sample ID e.g., `sample_lanes: ["R114096":"1,2,3", "R122595":"4,5,6", "R122596":"7,8"]`
- **Use only a single lane from a single flow cell (no merging)**
  - Output:  one R1/R2 file for each sample ID from a given lane/flow cell, identical to input R1/R2
  - Set `merge_all_lanes: FALSE`
  - Set `read_lanes: []`
  - Set `specify_sample_lanes: FALSE`
  - Specify `sample_lanes` with lanes to merge for each sample ID e.g., `sample_lanes: ["R114096":"1", "R122595":"2", "R122596":"3"]`

-----

## Updating Slurm jobscripts

This pipeline comes with a script (`resources/user_update_jobscripts.R`) to generate Slurm job scripts with your user details.

To run this script:

```
module load R
Rscript resources/user_update_jobscripts.R mail-user={email@email.com} mail-type={when_mail} account={account}
```

Arguments:

- `{email@email.com}` - your email e.g., `mail-user=test@test.com`
- `{when_mail}` - your email preferences e.g., `mail-type=END` or `mail-type=FAIL,END,TIME_LIMIT`
- `{account}` - account ID for Slurm accounting e.g., `account=OD-123456`

Putting this together, a sample command would be:

```
module load R
Rscript resources/user_update_jobscripts.R mail-user=test@test.com mail-type=FAIL,TIME_LIMIT account=OD-123456
```

#### Disabling all Slurm emails

If you do not wish to receive any emails from Slurm, set `mail-user=FALSE` and `mail-type=FALSE`:

```
module load R
Rscript resources/user_update_jobscripts.R mail-user=FALSE mail-type=FALSE account=OD-123456
```

----

## Pipeline steps

- `s0_merge_samples`: Read collation (**Step 0**)
- `s1_mask_repeats`: Repeat masking and suffix array creation (**Step 1**)
- `s2_raw_read_QC`: Perform quality control using FastQC (**Step 2**)
- `s3_extract_UMI`: UMI extraction with FGBio and Picard (**Step 3**)
- `s4_read_alignment`: Align reads with kalign (**Step 4**)
- `s5_alignment_deduplication`: Remove PCR and optical duplicates from alignment with Picard (**Step 5**)
- `s6a_two_bit_genome`: Generate 2Bit genome with faToTwoBit (**Step 6a**)
- `s6b_effective_genome_size`: Calculate effective genome size with faCount (**Step 6b**)
- `s6c_compute_GC_bias`: Compute GC bias with deeptools (**Step 6c**)
- `s6d_correct_GC_bias`: Correct GC bias with deeptools (**Step 6d**)
- `s7a_size_metrics`: Calculate alignment statistics with Picard (**Step 7a**)
- `s7b_read_count`: Estimate mean nuclear genome coverage (**Step 7b**)
- `s8_peak_analysis`: Peak analysis using DANPOS3 (**Step 8**)

----

## Snakemake command lines

*See the Snakemake documentation for v7.24.0 (Petrichor version as of 16/04/2025) here:* 
[Command line interface](https://snakemake.readthedocs.io/en/v7.24.0/executing/cli.html)

*See the latest version of the Snakemake documentation here:*
[Command line interface](https://snakemake.readthedocs.io/en/stable/executing/cli.html)

Note: These commands must be run with the `chromatin-assembly/` directory as the working directory

**Load the python module, which is required by Snakemake:**

```
module load python
```

**Perform a dry run:**

A dry run is a fast way to check the pipeline. Snakemake parses the pipeline and 
determines what would happen if the pipeline was to be run. Then, Snakemake 
outputs a snapshot of what would be executed and what files would be created.

There are different command line options depending on your desired output.

To output a table listing the steps to be executed:

```
snakemake -c1 -n --quiet
```

To output table listing steps to be executed, plus each rule that would be 
executed and a list of all output files:

```
snakemake -c1 -n
```

To output table of steps to be executed, plus each rule that would be executed 
(including shell command for each rule) and a list of all output files:

```
snakemake -c1 -n -p
```

**Print a summary table showing status of all files created by the workflow:**

```
snakemake --summary
```

**List all output files for which the rule body (run or shell) have changed in the Snakefile:**

```
snakemake --list-code-changes
```

**Output a graph of the relationships/dependencies between rules:**

```
module load graphviz
snakemake --forceall --rulegraph | dot -Tpdf > rulegraph.pdf
```

**Output a graph showing the path each input sample takes through the pipeline:**

Note: this is most useful for around 1-5 samples. Each additional sample adds ~9
nodes to the graph, so the graph becomes visually cluttered quickly.

```
module load graphviz
snakemake --forceall --dag | dot -Tpdf > dag.pdf
```

-----

## Having problems?

### Troubleshooting:

- Try running a dry run with the command `snakemake -n -p -c1` - sometimes you 
might be missing a file or have an incorrect file path

### Potential issues:

- **Snakemake not found?**
  - Check Python module is loaded: `module load python`
  - Check job script includes the line `module load python`
- **Not enough resources supplied in job scripts?**
  - Update resources in SBATCH lines
- **Not enough resources supplied to Snakemake?**
  - Update resources in the `profiles/slurm/config.yaml` file
- **Names of read files don't match?**
	- This pipeline was tested on reads with the structure: `{sample_id}_{some_text}_L00{num}_R{1|2}.fastq.gz`
	- For example, `R114096_22W5TWLT3_TTCTGCGTCG-TTCGTACACC_L003_R1.fastq.gz`
	- If you have data with a different file name structure, you may have issues running the pipeline.
	- Potential pitfall: your read filenames have an extra argument after the R1/R2 e.g., `SampleName_S1_L001_R1_001.fastq.gz`
- **Names of merged read files don't match?**
	- This pipeline names merged reads (i.e., the output from Step 0) with the structure: `{sample_id}_merged_R{1|2}.fastq.gz`
	- For example, `R114096_merged_R1.fastq.gz`
	- If you have merged reads with different naming structure, the pipeline will not work
	- Potential pitfall: your merged reads have the file path naming structure: `{sample_id}_R{1|2}_merged.fastq.gz`
- **Added new input files after executing all/part of the pipeline?**
  - Snakemake does not automatically rerun jobs when new input files are added
  - To get a list of the output files that are affected: `snakemake --list-input-changes`
  - To force a rerun of the new input files: `snakemake -n --forcerun $(snakemake --list-input-changes)`
- **Snakemake locked directory and can't run new job?**
  - Try rerunning the Snakemake command with the additional command line. parameter `--unlock`
      - `--unlock` can be used to remove a stale lock, e.g., if the machine powered off or a job was killed while a Snakemake instance was still running
  - Not working? Delete contents of the hidden directory `.snakemake/locks/` and try again
- **Issues generating conda environments with Snakemake?**
  - Delete contents of the hidden directory `.snakemake/conda/` and try again
- **Can't run Step 0 because R isn't available?**
  - Check whether the conda environments have been created in the hidden directory `.snakemake/conda/`
  - Try to generate the conda environments using `snakemake --use-conda --conda-create-envs-only -c1`
  - The conda environment "merge_reads" is provided at `workflow/envs/merge_reads.yaml`
  - If this environment isn't working, try creating the environment and manually exporting it:
    - To manually create the environment: `conda env create --file workflow/envs/merge_reads.yaml`
    - To re-export the environment: `conda activate merge_reads; conda env export > workflow/envs/merge_reads.yaml`
- **Can't run Step 6a or Step 6b because faCount and faToTwoBit aren't installed?**
  - Check whether the conda environments have been created in the hidden directory `.snakemake/conda/`
  - Try to generate the conda environments using `snakemake --use-conda --conda-create-envs-only -c1` 
  - The conda environment "Step6" is provided at `workflow/envs/Step6.yaml`
  - If this environment isn't working, try creating the environment and manually exporting it:
    - To manually create the environment: `conda env create --name Step6 --file workflow/envs/Step6.yaml`
    - To re-export the environment: `conda activate Step6; conda env export > workflow/envs/Step6.yaml`
