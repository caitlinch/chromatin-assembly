# chromatin-assembly

TODO DOCO Put citation here

---

**Table of Contents:**

- [Summary](#summary)
- [Pipeline development and testing](#pipeline-development-and-testing)
- [Quickstart guide for the time-impaired](#quickstart-guide-for-the-time-impaired)
- [Merging reads](#merging-reads)
- [Inputting sample IDs](#inputting-sample-ids)
- [Updating Slurm jobscripts](#updating-slurm-jobscripts)
- [Pipeline steps](#pipeline-steps)
- [Running Snakemake pipelines](#running-snakemake-pipelines)
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

See `doco/08_use_on_alternative_HPCs.Rmd` for details on using this version of 
the pipeline.


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
is accessible using the HPC system you will run the pipeline on)
      
### 4. Specify parameters for your dataset
Open the file `config/chromatin_assembly_config.yml` and update file paths
and parameters for your data. 

The key parameters to update are:

  - `repo_dir` - path to `chromatin-assembly/` directory
  - `ref_species` - name of reference species (e.g., `"mouse"`, `"yeast"`)
  - `binomial_species_name` - scientific name of species
  - `effective_genome_size` - calculated in Step 6b (details below)
  - `read_dir` - full path to directory containing reads
  - `merge_dict` - full path to file defining read merging (see [Input samples](#input-samples) 
  below for details)
  - `use_merge_dict` - `
  - `reference_genome_id` - human-readable name for reference genome
  - `reference_genome_path` - full path to reference genome (fasta format)
  - `input_samples` - samples to run pipeline on (see [Input samples](#input-samples)
    below for details)
  - `peak_analysis` - specify which samples to use for peak analysis with DANPOS
  (if desired)

*(Optional)* If you want to control the read merging, create a 
`sample_dict.txt` file for your data:

  - Copy the `data/template/template_sample_dict.txt` file into your data directory,
  giving it an appropriate name
  - Update the file contents referring to [Input samples](#input-samples) below for details

*(Optional)* If you want to change the program parameters in "Section 3: Program parameters", 
refer to the file `doco/05_advanced_use.Rmd` for details on changing program

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

### 11. Perform quality control for reads
- Perform Step 2 (read QC):
  - **Command**: `sbatch jobscripts/slurm_pipeline_S2.sh`    

### 12. Align reads
- Perform Step 3 (UMI extraction), Step 4 (align reads) and Step 5 (remove 
duplicates):  
  - **Command**: `sbatch jobscripts/slurm_pipeline_S3-5.sh`    

### 13. Specify effective genome size 
- Update the effective genome size value
    - Open file `config/chromatin_assembly_config.yml`
    - Update effective genome size value in "Section 1: Input data and parameters"
    - Effective genome size is extracted from output of Step 6b, and calculated 
    as the number of non-N bases in the genome
        - i.e., (Total length) - (Total N)

### 14. Correct alignments for GC bias
- Perform Step 6c (compute GC bias) and Step 6d (correct GC bias)
    - **Command**: `sbatch jobscripts/slurm_pipeline_S6c-6d.sh`

### 15. Calculate alignment statistics
- Perform Step 7a (calculate alignment statistics) and 7b (estimate mean 
nuclear genome covert): 
    - **Command**: `sbatch jobscripts/slurm_pipeline_S7a-7b.sh`

### 16. *(Optional)* Peak analysis
- Perform Step 8 (peak analysis with DANPOS):
    - Update DANPOS run parameters in config file
      - Open file `config/chromatin_assembly_config.yml`
      - Go to "Input control for peak analysis with DANPOS (Step 8)" and enter 
      desired sample IDs and test name.
    - **Command**: `sbatch jobscripts/slurm_pipeline_S8.sh`

-----

## Merging reads

By default, Step 0 (Merge reads) does the following:

- Read through all subdirectories in the read directory and collect sample IDs
(defined as everything before the first underscore in the basename of each file)
- For each sample id:
  - Find all `R1` files, [sort](https://man7.org/linux/man-pages/man1/sort.1.html)
  the list, then merge with [cat](https://man7.org/linux/man-pages/man1/cat.1.html)
  - Find all `R2` files, [sort](https://man7.org/linux/man-pages/man1/sort.1.html)
  the list, then merge with [cat](https://man7.org/linux/man-pages/man1/cat.1.html)
  
By default, Snakemake will set sample IDs equal to the portion of the filepath
before the first underscore. For example, the filename 
`R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L001_R1.fastq.gz` will have the sample
ID `R114096`.

If you want to merge all reads for all samples 

### Controlling which lanes are merged
You can control which files are merged by providing a `sample_dict.txt`:

- Copy and rename the template provided at `data/template/template_sample_dict.txt`
- In the config file `config/chromatin_assembly_config.yml`, edit the parameter
`merge_dict` to be the full path to your version of the `sample_dict.txt`
- Update your version of the `sample_dict.txt`

**Important:** You do not need to provide a `sample_dict.txt` file. By default, 
the pipeline will merge all reads as described above. Only include samples in 
the `sample_dict.txt` file when you want control over:

- the output filename
- merging within/across directories
- specifying certain lanes to merge

This is an example `sample_dict.txt` file:

```
sample_ID|sample_name|lanes
R98765|Sample01|1,2,3
S12345|Sample02|1
templateREF|REF|
```

There are three columns:

- `sample_ID`: chunk of a filename used for file identification
  - a unique identifier for each sample
  - e.g., for the filename `R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L001_R1.fastq.gz`,
  the sample ID could be `R114096`, `R114096_22W5TWLT2`, or 
  `R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC`
- `sample_name` : *(optional)* name of output file
  - If specified, `R1` output file will be named `{sample_name}_merged_R1.fastq.gz`
  - If left empty, `R1` output file will be named `{sample_ID}_merged_R1.fastq.gz`
- `lanes` : *(optional)* which lanes to merge. 
  - Only use numbers and commas e.g., `1,2,3`
  - If left empty, all lanes will be merged

### Using the `sample_dict.txt` file

The following examples use the example directory `species/data/reads/` below,
which has:

- two samples (`R114096` and `R122595`)
- reads for each sample spread across both subdirectories `22W5TWLT2/` and 
`33W5V5LT3/`
- Each sample has `R1` and `R2` files for three lanes (`L001`, `L002`, `L003`). 

```
species/data/reads/
  │
  └───22W5TWLT2
  │   │   R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L001_R1.fastq.gz
  │   │   R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L001_R2.fastq.gz
  │   │   R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L002_R1.fastq.gz
  │   │   R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L002_R2.fastq.gz
  │   │   R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L003_R1.fastq.gz
  │   │   R114096_22W5TWLT2_TTCTGCGTCG-TTCGTACACC_L003_R2.fastq.gz
  |   |   R122595_22W5TWLT2_ACGCATACTT-AAGTACGAGA_L001_R1.fastq.gz 
  |   |   R122595_22W5TWLT2_ACGCATACTT-AAGTACGAGA_L001_R2.fastq.gz 
  |   |   R122595_22W5TWLT2_ACGCATACTT-AAGTACGAGA_L002_R1.fastq.gz
  |   |   R122595_22W5TWLT2_ACGCATACTT-AAGTACGAGA_L002_R2.fastq.gz 
  |   |   R122595_22W5TWLT2_ACGCATACTT-AAGTACGAGA_L003_R1.fastq.gz
  |   |   R122595_22W5TWLT2_ACGCATACTT-AAGTACGAGA_L003_R2.fastq.gz 
  │   
  └───33W5V5LT3
      │   R114096_33W5V5LT3_TTCTGCGTCG-TTCGTACACC_L001_R1.fastq.gz
      │   R114096_33W5V5LT3_TTCTGCGTCG-TTCGTACACC_L001_R2.fastq.gz
      │   R114096_33W5V5LT3_TTCTGCGTCG-TTCGTACACC_L002_R1.fastq.gz
      │   R114096_33W5V5LT3_TTCTGCGTCG-TTCGTACACC_L002_R2.fastq.gz
      │   R114096_33W5V5LT3_TTCTGCGTCG-TTCGTACACC_L003_R1.fastq.gz
      │   R114096_33W5V5LT3_TTCTGCGTCG-TTCGTACACC_L003_R2.fastq.gz
      |   R122595_33W5V5LT3_ACGCATACTT-AAGTACGAGA_L001_R1.fastq.gz
      |   R122595_33W5V5LT3_ACGCATACTT-AAGTACGAGA_L001_R2.fastq.gz
      |   R122595_33W5V5LT3_ACGCATACTT-AAGTACGAGA_L002_R1.fastq.gz
      |   R122595_33W5V5LT3_ACGCATACTT-AAGTACGAGA_L002_R2.fastq.gz
      |   R122595_33W5V5LT3_ACGCATACTT-AAGTACGAGA_L003_R1.fastq.gz
      |   R122595_33W5V5LT3_ACGCATACTT-AAGTACGAGA_L003_R2.fastq.gz
```

##### Use Case 1: I want to merge all reads for all samples
In this case, we want to merge all lanes for all samples across all directories
(the default behaviour) - so we do **not** need to supply a `sample_dict.txt` file.

|   |   | 
|----|----|
| Input | A read directory containing multiple subdirectories, with samples spread across subdirectories |
| Desired output | One `R1` and one `R2` file per sample |
| Sample IDs | All   |
| Rename output files | False |
| Lanes to merge | All |
| Output files | `R114096_merged_R1.fastq.gz`, `R114096_merged_R2.fastq.gz`, `R122595_merged_R1.fastq.gz`, `R122595_merged_R2.fastq.gz` |

`sample_dict.txt`:

```
sample_ID|sample_name|lanes
```

##### Use Case 2: I want to merge reads across subdirectories, using a `sample_dict.txt`
|   |   | 
|----|----|
| Input | A read directory containing multiple subdirectories, with samples spread across subdirectories |
| Desired output | One `R1` and one `R2` file per sample |
| Sample IDs | `R114096`, `R122595`   |
| Rename output files | False |
| Lanes to merge | All |
| Output files | `R114096_merged_R1.fastq.gz`, `R114096_merged_R2.fastq.gz`, `R122595_merged_R1.fastq.gz`, `R122595_merged_R2.fastq.gz` |


`sample_dict.txt`:
```
sample_ID|sample_name|lanes
R114096||
R122595||
```

##### Use Case 3: I want to merge reads within subdirectories

|   |   | 
|----|----|
| Input | A read directory containing multiple subdirectories, with samples spread across subdirectories |
| Desired output | One `R1` and one `R2` file per sample per directory |
| Sample IDs | `R114096`, `R122595`   |
| Rename output files | False |
| Lanes to merge | All |
| Output files | `R114096_22W5TWLT2_merged_R1.fastq.gz`, `R114096_22W5TWLT2_merged_R2.fastq.gz`, `R114096_33W5V5LT3_merged_R1.fastq.gz`, `R114096_33W5V5LT3_merged_R2.fastq.gz`, `R122595_22W5TWLT2_merged_R1.fastq.gz`, `R122595_22W5TWLT2_merged_R2.fastq.gz`, `R122595_33W5V5LT3_merged_R1.fastq.gz`, `R122595_33W5V5LT3_merged_R2.fastq.gz` |

`sample_dict.txt`:
```
sample_ID|sample_name|lanes
R114096_22W5TWLT2|| 
R114096_33W5V5LT3|| 
R122595_22W5TWLT2|| 
R122595_33W5V5LT3|| 
```

##### Use Case 4: I want to merge only specific lanes

Lanes to merge are specified in the third column. Use numbers and commas only i.e.,
`1,2`

|   |   | 
|----|----|
| Input | A read directory containing multiple subdirectories, with samples spread across subdirectories |
| Desired output | One `R1` and one `R2` file per sample |
| Sample IDs | `R114096`, `R122595`   |
| Rename output files | False |
| Lanes to merge | 1,2 |
| Output files | `R114096_merged_R1.fastq.gz`, `R114096_merged_R2.fastq.gz`, `R122595_merged_R1.fastq.gz`, `R122595_merged_R2.fastq.gz` |

`sample_dict.txt`:
```
sample_ID|sample_name|lanes
R114096||1,2
R1225953||1,2
```

##### Use Case 5: I want to rename my output files

Sample names are specified in the second column.

|   |   | 
|----|----|
| Input | A read directory containing multiple subdirectories, with samples spread across subdirectories |
| Desired output | One `R1` and one `R2` file per sample |
| Sample IDs | `R114096`, `R122595`   |
| Rename output files | True |
| Lanes to merge | All |
| Output files | `Sample001_merged_R1.fastq.gz`, `Sample001_merged_R2.fastq.gz`, `Sample002_merged_R1.fastq.gz`, `Sample002_merged_R2.fastq.gz` |

`sample_dict.txt`:
```
sample_ID|sample_name|lanes
R114096|Sample001|
R1225953|Sample002|
```

##### Use Case 6: I want to rename my output files and merge specific lanes

Here we combine Use Case 4 and Use Case 5 to specify sample names and lanes for
each `sample_ID`.

|   |   | 
|----|----|
| Input | A read directory containing multiple subdirectories, with samples spread across subdirectories |
| Desired output | One `R1` and one `R2` file per sample |
| Sample IDs | `R114096`, `R122595`   |
| Rename output files | True |
| Lanes to merge | 1,2 |
| Output files | `Sample001_merged_R1.fastq.gz`, `Sample001_merged_R2.fastq.gz`, `Sample002_merged_R1.fastq.gz`, `Sample002_merged_R2.fastq.gz` |

`sample_dict.txt`:
```
sample_ID|sample_name|lanes
R114096|Sample001|1,2 
R1225953|Sample002|1,2 
```

------

## Inputting sample IDs

The pipeline is controlled by the config file `config/chromatin-assembly-config.yml`.
The section `## Input data paths and details ##` controls which samples are run
through the pipeline

### Key points

The key points to remember when inputting sample IDs into the config file are:

* Enter **all** sample IDs that you wish to use for downstream analysis. That includes:
  * Samples you wish to use as experimental input for DANPOS
  * Samples you wish to use as control for DANPOS
* You **must**

* Check your indentation (see code block below for example of correct indentation)
  * The `input_samples` array can span multiple lines,
* If you're having issues with the config file being read, check:
  * Indentation - the program can be sensitive to the level of indentation
  * Missing characters:
    * Check all opened brackets `[` have a closing bracket `]`
    * Check all strings are completed by being enclosed in quotes - there should 
    be no hanging `"`
  * Array formatting
    * Check the formatting and indentation of your `input_samples` array. 
    * Check that you have both the opening `[` and closing `]` bracket
    * Check commas - there should one comma between each entry in the array, and 
    no comma after the last entry
  
Here's some examples of formatting and indentation:
```
### Indenting properly ###
reference_genome_id: "ref_genome_ID"
reference_genome_path: "/path/to/ref/genome.fna"
input_samples: ["exp001", "exp002", "exp003", "cont001", "cont002", "cont003"] 

### Array formatting and indentation ###

## Single-lane array formatting 
input_samples: ["exp001", "exp002", "exp003","cont001", "cont002", "cont001"]

## Multi-line array formatting (you can have more lines and/or more elements in each line)
input_samples: [
  "exp001", "exp002", "exp003",
  "cont001", "cont002", "cont001"
]
```

### Entering sample IDs to run through the pipeline

To run a sample through the pipeline, the sample ID must be input into the 
`config/chromatin-assembly-config.yml` file.

The section of the file for input data looks like this:

```
## Input data paths and details ##
# reference_genome_id: human-readable identifier for reference genome
# reference_genome_path: full path to reference genome
# input_samples: The samples to be run through the pipeline 
reference_genome_id: "ref_genome_ID"
reference_genome_path: "/path/to/ref_genome.fna"
input_samples: ["133143", "133133"] 
```

It's important that **any** samples you want to use as either control or
analysis for DANPOS are run through the whole pipeline, so they should be
entered in the `input_samples` array.

Say you have six samples (3 experimental and 3 control) you want to use for DANPOS:

- **Experimental**
  - `exp001`
  - `exp002`
  - `exp003`
- **Control**
  - `cont001`
  - `cont002`
  - `cont003`

Your input section would look like this:

```
reference_genome_id: "ref_genome_ID"
reference_genome_path: "/path/to/ref/genome.fna"
input_samples: ["exp001", "exp002", "exp003", "cont001", "cont002", "cont003"] 
```

### What if I renamed my sample IDs during the merge step?

If you rename your files during the merge step, you must provide the **new sample names**
into the config file.

Say you have six replicates as above: 

- **Experimental**
  - `exp001`
  - `exp002`
  - `exp003`
- **Control**
  - `cont001`
  - `cont002`
  - `cont003`

You want to include the state where each sample was collected in the merged file 
name, so you use the following dictionary to rename samples during the merge 
step (S0):

`sample_dict.txt`:
```
sample_ID|sample_name|lanes
exp001|NSW_exp001|
exp002|VIC_exp002| 
exp003|TAS_exp003|
cont001|NSW_cont001|
cont002|VIC_cont002|
cont003|TAS_cont003|
```

This results in the following merged files:

- `NSW_exp001_merged_R1.fastq.gz`, `NSW_exp001_merged_R2.fastq.gz`
- `VIC_exp002_merged_R1.fastq.gz`, `VIC_exp002_merged_R2.fastq.gz`
- `TAS_exp003_merged_R1.fastq.gz`, `TAS_exp003_merged_R2.fastq.gz`
- `NSW_cont001_merged_R1.fastq.gz`, `NSW_cont001_merged_R2.fastq.gz`
- `VIC_cont002_merged_R1.fastq.gz`, `VIC_cont002_merged_R2.fastq.gz`
- `TAS_cont003_merged_R1.fastq.gz`, `TAS_cont003_merged_R2.fastq.gz`

You must now use the updated sample names in the 
`config/chromatin-assembly-config.yml` file, like this:

```
reference_genome_id: "ref_genome_ID"
reference_genome_path: "/path/to/ref/genome.fna"
input_samples: ["NSW_exp001", "VIC_exp002", "TAS_exp003", "NSW_cont001", "VIC_cont002", "TAS_cont003"] 
```

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

------

## Running Snakemake pipelines

#### Rerunning steps

The output for each step is saved in a directory titled by the name of that step.
These names are provided in the `config/chromatin_assembly_config.yml` file in
"Section 2: Output names".

The relative path to each of these directories is: `chromatin-assembly/results/{ref_species}/{stepX}/`, 
where `{ref_species}` is the species name and `{StepX}` is the name of the step.

Unless you are changing program parameters or input data, you **should not** need
to change these output names.

Snakemake is smart - it checks to see whether the desired output files exist. If 
they do, it won't overwrite them by running that step (unless the step has changed in
some way).

If you want to rerun a step with a different set of input parameters, you can 
update the output directory for that step in the config file, which will allow 
you to run that step with the new settings.

To force Snakemake to rerun a rule, use the flag `-R {rulename}` or 
`--forcerun {rulename}` (where `{rulename}` is the name of the rule - see 
[Pipeline steps](#pipeline-steps) for all rule names).

For example, to force Snakemake to rerun all jobs of rule `somerule` plus
everything downstream:

```
snakemake -R somerule
```

Other parameters can be added to the Snakemake command as required. For example, 
to use Slurm to force the rerun of `somerule` and everything downstream:

```
snakemake --slurm --profile profiles/slurm/ -R somerule
```

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

To test this, you can do a dry run and compare the list of rules that will be 
run in each instance. Also check the input/output files and make sure there are 
no overlapping files between the two instances.

#### Running the pipeline in two chunks
You can run the pipeline in two steps using the scripts 
`jobscripts/templates/slurm_run_all_part1.sh` and 
`jobscripts/templates/slurm_run_all_part2.sh`.

To do so:

- Follow Steps 1-8 from the Quickstart Guide above 
- Run pipeline until the point of outputting the effective genome size:
    - **Command:** `sbatch jobscripts/slurm_run_all_part1.sh`
- Update the effective genome size value in the file `config/chromatin_assembly_config.yml`
as per Step 13 in the Quickstart Guide above
- Run the rest of the pipeline:
    - **Command:** `sbatch jobscripts/slurm_run_all_part2.sh`

-----

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

- What directory are you in? You should be in the directory `chromatin-assembly`.
Check with the command `pwd`:

```
> pwd
/path/to/chromatin-assembly
```

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
- **SLURM jobs repeatedly timing out**
  - The default queue on Petrichor has a time limit of 160 hours. You can submit 
  long jobs to the `ext` queue (see 
  [Extended Partitions](https://confluence.csiro.au/pages/viewpage.action?spaceKey=SC&title=Job+queues#Jobqueues-ExtendedPartitions)
  on Confluence), which allows jobs of up to 30 days (`30-00:00:00`)
  - There's two type of jobs that can time out - the main jobscript (which 
  controls Snakemake) and child jobs (submitted by Snakemake to execute pipeline 
  steps). 
  - Fix the main jobscript timing out:
    - Add a line specifying the slurm partition to the top of your script: `#SBATCH --partition=ext`
    - Extend the time for your job e.g., to set a time of 25 days use `#SBATCH --time=25-00:00:00`
  - Fix rules timing out:
    - Open the `profiles/slurm/config.yaml`
    - Go to the section specifying resources for the step that needs more time 
    (see [Pipeline steps](#pipeline-steps) above for step names)
    - Specify the partition to be used: e.g., for Step 4, to use the`ext` partition
    add the line `- s4_read_alignment:slurm_partition=ext`
    - Extend the time for the job e.g., to specify 400 hours for Step 4, edit
    the `s4_read_alignment:runtime` specified to be `- s4_read_alignment:runtime=400h`
    - **Note:** The maximum runtime for a rule will be 720 hours (30 days x 24 hours)
    - Check that the indentation is consistent! Each line specifying rule 
    resources should have the same indentation levels
    - Save the file and try running your jobs
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
- **Can't generate conda environments?**
  - Try following the instructions from the Confluence [Conda and python in HPC](https://confluence.csiro.au/display/IMT/Conda+and+python+in+HPC)
  page:
    - Load the miniforge module: `module load miniforge3; source /apps/miniforge3/enable_miniforge.sh`
    - Try creating the conda environments again
  - Try creating a test conda environment:
      - **Load miniforge3:** `module load miniforge3; source /apps/miniforge3/enable_miniforge.sh`
      - **Create env:** `conda create --name test_env`
      - If you can't create any conda environments at all, that's an issue for 
      Scientific Computing
- **Issues generating conda environments with Snakemake?**
  - If there's issues because conda environments weren't properly installed,
  delete the contents of the hidden directory `.snakemake/conda/`
  - Then, create conda envs with `snakemake --use-conda --conda-create-envs-only -c1`
- **Can't run Step 6a or Step 6b because faCount and faToTwoBit aren't installed?**
  - Check whether the conda environments have been created in the hidden directory `.snakemake/conda/`
  - Try to generate the conda environments using `snakemake --use-conda --conda-create-envs-only -c1` 
  - The conda environment "Step6" is provided at `workflow/envs/Step6.yaml`
  - If this environment isn't working, try creating the environment and manually exporting it:
    - To manually create the environment: `conda env create --name Step6 --file workflow/envs/Step6.yaml`
    - To re-export the environment: `conda activate Step6; conda env export > workflow/envs/Step6.yaml`

