# chromatin-assembly

Caitlin Cherryh, Kate O'Hara, Jiri Stiller, Erin Hahn 2026. Chromatin assembly pipeline. Version 1.0.0. GitHub repository. https://github.com/caitlinch/chromatin-assembly

---

**Table of Contents:**

- [Summary](#summary)
- [Pipeline development and testing](#pipeline-development-and-testing)
- [Pipeline steps](#pipeline-steps)
- [Quickstart guide for the time-impaired](#quickstart-guide-for-the-time-impaired)
- [Merging reads](#merging-reads)
- [Selecting sample IDs](#selecting-sample-ids)
- [Updating Slurm jobscripts](#updating-slurm-jobscripts)
- [Running Snakemake pipelines](#running-snakemake-pipelines)
- [Snakemake command lines](#snakemake-command-lines)
- [Having problems?](#having-problems)

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
is located at `chromatin-assembly/alternative_HPCs/` and uses conda
environments (instead of environment modules) so it is more transferable. 

See `doco/08_use_on_alternative_HPCs.Rmd` for details on using this version of 
the pipeline.

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

## Quickstart guide for the time-impaired

**Note:** These steps have been tested on Petrichor and locally (MacOS v15.3.1, Apple M2 Pro Chip).

### 1. Download the repository
- Download the [caitlinch/chromatin-assembly](https://github.com/caitlinch/chromatin-assembly) 
GitHub repository and move it to where you want to run your pipeline 
    - For example, my directory is `/scratch3/che318/chromatin-assembly/`
    
### 2. Navigate to the directory
- Navigate in terminal to the `chromatin-assembly/` directory
- **Command**: `cd /scratch3/che318/chromatin-assembly/`

### 3. Make your data accessible to the pipeline
You can store your data anywhere that is accessible to the HPC running the 
pipeline.

On Petrichor, that means moving your data to `/scratch3/`

The two main options are:

1. Move data to the `chromatin-assembly/` directory
2. Store your data anywhere

#### Option 1: Use the `chromatin-assembly/` directory
- Within the chromatin-assembly directory, create a directory called `data/` 
    - Create a new directory within `data/`, named after your species (e.g., 
    `data/gecko/`). 
    - Inside the species folder, create two folders: `reads/`, and `reference_genome/`
    - Copy your data into the relevant files. 
    - The directories should look like something like this (where `{species}` is 
    replaced with your species name):
      - `chromatin-assembly/data/{species}/reads/` – contains raw reads 
      (`.fastq.gz`), both experimental data and input control for DANPOS3 (peak 
      analysis)
      - `chromatin-assembly/data/{species}/reference_genome/` – contains reference 
      genome in fasta (`.fasta`, `.fsa`, `.fna` etc.) file format

#### Option 2: Store your data anywhere
- Move or copy your data to any directory (making sure that the directory
is accessible using the HPC system you will run the pipeline on). 
- Note the file paths to the directories containing:
  - Reads 
  - Reference genome
      
### 4. Specify parameters for your dataset
Open the file `config/chromatin_assembly_config.yml` and update file paths
and parameters for your data. 

*(Optional)* If you want to control the read merging, create a 
`sample_dict.txt` file for your data:

  - Copy the `data/template/template_sample_dict.txt` file into your data directory,
  giving it an appropriate name
  - Update the file contents referring to [Input samples](#input-samples) below for details

*(Optional)* If you want to change the program parameters in "Section 3: Program parameters", 
refer to the file `doco/05_advanced_use.Rmd` for details on changing program

*(Mandatory)* The key parameters to update are:

  - `repo_dir` - path to `chromatin-assembly/` directory
  - `ref_species` - name of reference species (e.g., `"mouse"`, `"yeast"`)
  - `binomial_species_name` - scientific name of species
  - `effective_genome_size` - calculated in Step 6b (details below)
  - `reference_genome_id` - human-readable name for reference genome
  - `reference_genome_path` - full path to reference genome (fasta format)
  - `input_samples` - samples to run pipeline on (see [Input samples](#input-samples)
    below for details)
  - `read_dir` - full path to directory containing reads e.g., `"/path/to/reads/"`
  - `merge_dict` - optional file defining sample names and lanes for merging
    - if using merge dictionary, provide full path to file defining read merging 
    e.g., `"/path/to/sample_dict.txt"`
    - If not using merge dictionary, set as `"NA"`
    - See [Input samples](#input-samples) below for details
  - `use_merge_dict` - `"yes"` if using merge dictionary, otherwise `"no"`
  - `peak_analysis` - specify which samples to use for peak analysis with DANPOS
  (if desired)

### 5. Update Snakemake profiles
- Snakemake uses profiles to determine what computational resources to use for 
each step on each system
- Update the account ID in the profile for pipeline runs:
`chromatin-assembly/profiles/slurm/config.yaml`

### 6. Prepare conda environments
- Use Snakemake to generate conda environments needed for pipeline Step 6
    - **Load python module:** `module load python`
    - **Load miniforge3 module:** `module load miniforge3; source /apps/miniforge3/enable_miniforge.sh`
    - **Generate conda environments:** `snakemake --use-conda --conda-create-envs-only -c1`

### 7. Prepare Slurm job scripts
- Generate Slurm job scripts using the R script `resources/user_update_jobscripts.R`:
    - **Command**: `module load R`
    - **Command**: `Rscript resources/user_update_jobscripts.R mail-user={email@email.com} mail-type={when_mail} account={account}`
	  - Replace each set of curly brackets with your preferred Slurm details
	  - **e.g.,** `Rscript resources/user_update_jobscripts.R mail-user=test@test.com mail-type=FAIL account=OD-123456`
	  - See "Updating Slurm jobscripts" below for more details

### 8. Test pipeline with a dry run
- Perform a dry run of the full pipeline:
    - Load Python module to access Snakemake: `module load python`
    - **In terminal**: `snakemake -n -p -c1`
    - **By job script**: `sbatch jobscripts/slurm_pipeline_dry_run.sh`

### 9. Merge reads
- Perform Step 0 (Merge reads):
    - **Command**: `sbatch jobscripts/slurm_pipeline_S0.sh`

### 10. Prepare reference genome
- Perform Step 1 (read masking), Step 6a (generate two bit genome) and Step 6b 
(calculate genome size):
    - **Command**: `sbatch jobscripts/slurm_pipeline_S1_S6a_S6b.sh`    

### 11. Specify effective genome size 
- Update the effective genome size value
    - Open file `config/chromatin_assembly_config.yml`
    - Update effective genome size value in "Section 1: Input data and parameters"
    - Effective genome size is extracted from output of Step 6b, and calculated 
    as the number of non-N bases in the genome
        - i.e., (Total length) - (Total N)

### 12. Perform quality control for reads
- Perform Step 2 (read QC):
  - **Command**: `sbatch jobscripts/slurm_pipeline_S2.sh`    

### 13. UMI extraction
- Perform Step 3 (UMI extraction):  
  - **Command**: `sbatch jobscripts/slurm_pipeline_S3.sh`    
  
### 14. Align reads
- Perform Step 4 (align reads):  
  - **Command**: `sbatch jobscripts/slurm_pipeline_S4.sh`    
  
### 15. Deduplication
- Perform Step 5 (remove duplicates):  
  - **Command**: `sbatch jobscripts/slurm_pipeline_S5.sh`    

### 16. Correct alignments for GC bias
- Perform Step 6c (compute GC bias) and Step 6d (correct GC bias)
    - **Command**: `sbatch jobscripts/slurm_pipeline_S6c-6d.sh`

### 17. Calculate alignment statistics
- Perform Step 7a (calculate alignment statistics) and 7b (estimate mean 
nuclear genome covert): 
    - **Command**: `sbatch jobscripts/slurm_pipeline_S7a-7b.sh`

### 18. *(Optional)* Peak analysis
- Perform Step 8 (peak analysis with DANPOS):
    - Update DANPOS run parameters in config file
      - Open file `config/chromatin_assembly_config.yml`
      - Go to "Input control for peak analysis with DANPOS (Step 8)" and enter 
      desired sample IDs and test name.
    - **Command**: `sbatch jobscripts/slurm_pipeline_S8.sh`

-----

## Merging reads

The default merge read settings will:

- Extract the input sample IDs from the config file
- Iterate through each input ID and:
  - Collect all R1 files (all lanes, all subdirectories) and concatenate them with `cat`
  - Collect all R2 files (all lanes, all subdirectories) and concatenate them with `cat`

To use the default merge read settings, use the following parameters:
```
merge_reads: 
  read_dir: "/path/to/reads/"
  merge_dict: "NA"
  use_merge_dict: "no"
```

**IMPORTANT:** Remember to replace the string `"/path/to/reads/"` with the 
path to your reads directory!

For detailed documentation on setting read merging parameters, see the file 
`doco/00_merge_reads.Rmd`.

-----

## Selecting sample IDs

Sample IDs should be a unique identifier for each sample. A good sample ID
is a chunk from the start of a filename, that is shared across all reads for
that sample.

For example, if you have a file named `R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L001_R1.fastq.gz`,
good sample IDs would be `R114096` or `R114096_22W5TWLT2`.

**IMPORTANT:** a good sample ID must be unique!

For example, say you have the following files:

- `R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L001_R1.fastq.gz`
- `R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L002_R1.fastq.gz`
- `R114096_33W5V5LT3_TTCTGCGTCG-TTCGTACACC_L001_R1.fastq.gz`
- `R114096_33W5V5LT3_TTCTGCGTCG-TTCGTACACC_L002_R1.fastq.gz`

You have two choices for sample IDs:

- Use one sample ID `R114096`
  - All four files will be merged together
  - One output file: `R114096_merged_R1.fastq.gz`
- Use two sample IDs `R114096_22W5TWLT2` and `R114096_33W5V5LT3`
  - The first two files will be merged together, and the second two files will be 
  merged together
  - Two output files: `R114096_22W5TWLT2_merged.fastq.gz` and 
  `R114096_33W5V5LT3_merged.fastq.gz`

For detailed documentation on selecting sample IDs, see the file 
`doco/00_input_samples.Rmd`.

------

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

------

## Running Snakemake pipelines

For documentation on running Snakemake pipelines, see the file `doco/00_running_snakemake_pipelines.Rmd`.

-----

## Having problems?

See the file `doco/00_troubleshooting.Rmd`.

-----
