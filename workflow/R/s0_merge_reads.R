## Rscript to merge reads
# This script allows for:
#   - An input directory containing multiple directories of reads
#   - Changing sample names to human-readable names (using a user-provided 
#     dictionary) 
#   - Merging based on user-specified lanes (can merge specific lanes if desired)


## Usage: 
# Navigate to the chromatin-assembly/ directory:
# $ cd /Users/che318/Repos/chromatin-assembly/

# Assuming the user is within the chromatin-assembly/ dir, use:
# $ Rscript workflow/R/s0_merge_reads.R config=config/chromatin_assembly_config.yml out=/path/to/output.txt 
# For example:
# $ Rscript workflow/R/s0_merge_reads.R config=config/chromatin_assembly_config.yml out=/Users/che318/Repos/chromatin-assembly/log/s0_merge_samples_gecko.txt 

#### OPEN LIBRARIES ####
library(yaml)


#### PREPARE CONFIG FILE ####
# Parse input argument - chromatin_assembly_config.yml directory
args <- commandArgs(trailingOnly = TRUE)

### For testing:
# # On Macbook:
# args = c("config=/Users/che318/Repos/chromatin-assembly/config/chromatin_assembly_config.yml", "out=/Users/che318/Repos/chromatin-assembly/log/s0_merge_samples_gecko.txt")
# # On Petrichor:
# args = c("config=/scratch3/che318/chromatin-assembly/config/chromatin_assembly_config.yml", "out=/scratch3/che318/chromatin-assembly/log/s0_merge_samples_gecko.txt")
###

# check for the command args
if ( (length(grep("config", args)) == 0) |
     (length(grep("out", args)) == 0) ){
  stop(
    c(
      " \n",
      "Supply arguments to script:",
      " \n",
      "$ Rscript workflow/R/s0_merge_reads.R config=/path/to/chromatin-assembly/config/chromatin_assembly_config.yml out=/path/to/output.txt"
    ), 
    call.=FALSE
  )
}

arg_config_file <- strsplit(grep("config", args, value = T), "=")[[1]][2]
arg_out_log <- strsplit(grep("out", args, value = T), "=")[[1]][2]

print("Running s0_merge_reads.R")
print(paste0("Config file: ", arg_config_file))

if (file.exists(arg_config_file) == FALSE){
  stop(
    c(
      " \n",
      "Supplied config file does not exist",
      " \n",
      "Check file: ",
      " \n",
      arg_config_file
    ), 
    call.=FALSE
  )
}

# Open config file
config <- read_yaml(arg_config_file)


#### EXTRACT PARAMETERS FROM CONFIG FILE ####
print("Extracting parameters")

# Extract params
param_species <- config$ref_species
param_repoDir <- config$repo_dir
param_readDir <- config$merge_reads$read_dir
param_mergeAcrossDirs <- config$merge_reads$merge_across_dirs # merge across subdirs: T/F
param_mergeAllLanes <- config$merge_reads$merge_all_lanes # merge all lanes: T/F
param_readLanes <- config$merge_reads$read_lanes # lanes to merge (for all samples)
param_useSampleName <- config$merge_reads$use_names # output sample names: T/F
param_specifySampleLanes <- config$merge_reads$specify_sample_lanes # merge lanes for individual samples: T/F
param_s0_dir <- config$output_dir$step0
param_outdir <- paste0(dirname(param_repoDir), "/", 
                       basename(param_repoDir), "/",
                       "results/",
                       param_species, "/",
                       param_s0_dir, "/")

# Extract sample details
sample_id <-  config$merge_reads$merge_sample_ids # sample IDs
param_sampleNames <- config$merge_reads$sample_names # sample ID and name pairs
if (identical(param_sampleNames, list()) == FALSE){
  sample_names <- data.frame(
    sample_id = names(unlist(param_sampleNames)), 
    sample_name = unname(unlist(param_sampleNames))
  )
} else {
  sample_names <- NA
}
param_sampleLanes <- config$merge_reads$sample_lanes # sample ID and lane pairs
if (identical(param_sampleLanes, list()) == FALSE){
  sample_lanes <- data.frame(
    sample_id = names(unlist(param_sampleLanes)), 
    sample_lanes =unname(unlist(param_sampleLanes))
  )
} else {
  sample_lanes <- NA
}

print(paste0("Repo dir: ", param_repoDir))
print("")


#### ERROR CHECKING ###
print("Checking input")

if (length(list.files(param_readDir, recursive = T)) == 0){
  stop(
    c(
      " \n",
      "No files in supplied read directory",
      " \n",
      "Check directory: ",
      " \n",
      param_readDir
    ), 
    call.=FALSE
  )
}

if (length(grep("fastq|fastq.gz", list.files(param_readDir, recursive = T))) == 0){
  stop(
    c(
      " \n",
      "No .fastq or .fastq.gz files in supplied read directory",
      " \n",
      "Check directory: ",
      " \n",
      param_readDir
    ), 
    call.=FALSE
  )
}

if (length(sample_id) == 0){
  stop(
    c(
      " \n",
      "No sample IDs provided",
      " \n",
      "Enter sample IDs into config file",
      " \n",
      "For example",
      "\n",
      "merge_sample_ids: ['id01', 'id02', 'id03']"
    ), 
    call.=FALSE
  )
}

if (length(which(is.na(sample_id))) > 0){
  stop(
    c(
      " \n",
      "Some sample ids are not parseable",
      " \n",
      "Check sample IDs into config file"
    ), 
    call.=FALSE
  )
}

if (param_useSampleName == TRUE){
  if (class(sample_names) == "logical"){
    stop(
      c(
        " \n",
        "No sample names provided",
        " \n",
        "Enter sample names into config file",
        " \n",
        "For example",
        "\n",
        "sample_names: ['id01':'name01', 'id02':'name02', 'id03':'name03']"
      ), 
      call.=FALSE
    )
  }
}

if ( (identical(param_sampleNames, list(0))) & 
     (param_useSampleName == TRUE) ){
  stop(
    c(
      " \n",
      "No sample names provided",
      " \n",
      "Enter sample names into config file",
      " \n",
      "For example:",
      " \n",
      "sample_name: ['id01':'name01', 'id02':'name02']"
    ), 
    call.=FALSE
  )
}

if ( (identical(param_sampleLanes, list(0))) & 
     (param_specifySampleLanes == TRUE) ){
  stop(
    c(
      " \n",
      "No sample lanes provided",
      " \n",
      "Enter sample names into config file",
      " \n",
      "For example:",
      " \n",
      "sample_lanes: ['id01': '1', 'id02': '1,2', 'id03': '1,2,3']"
    ), 
    call.=FALSE
  )
}

if (param_mergeAllLanes == FALSE & 
    param_specifySampleLanes == FALSE &
    identical(param_readLanes, list()) ){
  stop(
    c(
      " \n",
      "Incorrect lane merging specified",
      " \n",
      "You must specify which lanes to merge e.g.",
      " \n",
      "  read_lanes: ['1','2','3','4','5','6','7','8']"
    ), 
    call.=FALSE
  )
}

if (param_specifySampleLanes == TRUE & 
    identical(param_sampleLanes, list())){
  stop(
    c(
      " \n",
      "Incorrect lane merging specified",
      " \n",
      "You must specify the sample_lanes e.g.",
      " \n",
      "  sample_lanes: ['id01': '1', 'id02': '1,2', 'id03': '1,2,3']"
    ), 
    call.=FALSE
  )
}

if (param_specifySampleLanes == TRUE & 
    param_mergeAllLanes == TRUE){
  stop(
    c(
      " \n",
      "Incorrect lane merging specified",
      " \n",
      "You have both `merge_across_dirs: TRUE` and `specify_sample_lanes: TRUE`",
      " \n",
      "Only one of these options can be used at once. Change one of these to FALSE."
    ), 
    call.=FALSE
  )
}


#### MERGE READS ####
print("Merging reads")

## Create the output dirs
sys_mkdir <- paste0("mkdir -p ", param_outdir)
system(sys_mkdir)

## Create a log dir
log_dir <- paste0(param_repoDir, "log/", param_s0_dir, "/")
sys_mkdir_log <- paste0("mkdir -p ", log_dir)
system(sys_mkdir_log)

## Identify read directories
if (param_mergeAcrossDirs == TRUE){
  ## To merge reads ACROSS dirs
  ## One R1/R2 file per sample name 
  ## i.e., if you have multiple dirs within reads/, and the same sample name
  ## is present within these dirs, then those files will be combined
  # Use the read_dir
  dirs_to_iterate <- param_readDir
} else if (param_mergeAcrossDirs == FALSE){
  ## To merge reads WITHIN dirs
  ## i.e., One R1/R2 file per sample name per directory (for directories inside the reads/ directory)
  # List directories within the read_dir
  internal_dirs <-  gsub("//", "/", list.dirs(param_readDir))
  dirs_to_iterate <- internal_dirs[internal_dirs != param_readDir]
  # fix directory path format
  dirs_to_iterate <- unlist(lapply(dirs_to_iterate, function(p){paste0(dirname(p), "/", basename(p), "/")}))
}

## Iterate over directories to collect reads by sample_id
for (d in dirs_to_iterate){
  # Print dir name
  print(paste0("Processing directory ", d))
  
  ## Create output files for this directory
  if (param_mergeAcrossDirs == TRUE){
    d_out_dir <- param_outdir
    d_log_dir <- log_dir
  } else if (param_mergeAcrossDirs == FALSE){
    d_out_dir <- paste0(param_outdir, basename(d), "/")
    d_log_dir <- paste0(log_dir, basename(d), "/")
  }
  system(paste0("mkdir -p ", d_out_dir))
  system(paste0("mkdir -p ", d_log_dir))
  
  ## Get all fastq/fastq.gz files within d
  d_all_files <- list.files(d, recursive = T)
  d_read_paths <- grep("fastq|fastq.gz", d_all_files, value = T)
  
  ## Iterate through each sample_id to extract reads
  for (s in sample_id){
    # List all files with that sample id
    s_all_reads <- d_read_paths[grep(s, basename(d_read_paths))]
    # Identify which lanes to keep
    if (param_mergeAllLanes == TRUE){
      # merge_all_lanes = TRUE
      # Do not check: read_lanes, specify_sample_lanes, sample_lanes
      s_lane_reads <- s_all_reads
    } else if ( (param_mergeAllLanes == FALSE) & 
                (identical(param_readLanes,list()) == FALSE) ){
      # merge_all_lanes = FALSE
      # read_lanes provided
      # Do not check: specify_sample_lanes, sample_lanes
      lane_nums <- unlist(param_readLanes)
      lane_str  <- paste0("_L", sprintf("%03s", lane_nums))
      s_lane_reads <- s_all_reads[grep(paste0(lane_str, collapse = "|"), basename(s_all_reads))]
    }
    else if ( (param_mergeAllLanes == FALSE) & 
              (param_specifySampleLanes == TRUE) & 
              (identical(param_sampleLanes,list()) == FALSE) ){
      # merge_all_lanes = FALSE
      # specify_sample_lanes = TRUE
      # sample_lanes provided
      # Do not check: read_lanes
      lane_txt <- sample_lanes[which(sample_lanes$sample_id == s),"sample_lanes"]
      lane_nums <- unlist(strsplit(lane_txt, ","))
      lane_str  <- paste0("_L", sprintf("%03s", lane_nums))
      s_lane_reads <- s_all_reads[grep(paste0(lane_str, collapse = "|"), basename(s_all_reads))]
    } else {
      # There must be some issue with the logic. Stop the program.
      stop(
        c(
          " \n",
          "Problem with parameters for merge_reads in config file",
          " \n",
          "Check the merging parameters. You may be missing variables or have specified incompatible options.",
          " \n",
          "Further details about the merging options are provided in the repository README.md"
        ), 
        call.=FALSE
      )
    }
    
    ## Prepare reads for concatenation
    # Separate by R1 and R2
    s_r1 <- s_lane_reads[grep("_R1", basename(s_lane_reads))]
    s_r2 <- s_lane_reads[grep("_R2", basename(s_lane_reads))]
    # Construct output file names
    if (param_useSampleName == TRUE){
      s_name <- sample_names[which(sample_names$sample_id == s),"sample_name"]
      s_r1_op_path <- paste0(d_out_dir, s_name, "_merged_R1.fastq.gz")
      s_r2_op_path <- paste0(d_out_dir, s_name, "_merged_R2.fastq.gz")
      s_r1_log <- paste0(d_log_dir, s_name, "_merged_R1.txt")
      s_r2_log <- paste0(d_log_dir, s_name, "_merged_R2.txt")
    } else {
      s_r1_op_path <- paste0(d_out_dir, s, "_merged_R1.fastq.gz")
      s_r2_op_path <- paste0(d_out_dir, s, "_merged_R2.fastq.gz")
      s_r1_log <- paste0(d_log_dir, s, "_merged_R1.txt")
      s_r2_log <- paste0(d_log_dir, s, "_merged_R2.txt")
    }
    # Construct command lines
    # $ cat "$data_dir/${sample}_L00"*"_R1.fastq.gz" > "$output_dir/${sample}_R1_merged.fastq.gz"
    sys_r1_merge <- paste0(
      "cat ",
      paste(paste0(d, s_r1), collapse = " "),
      " > ",
      s_r1_op_path
    )
    system(sys_r1_merge)
    # $ cat "$data_dir/${sample}_L00"*"_R2.fastq.gz" > "$output_dir/${sample}_R2_merged.fastq.gz"
    sys_r2_merge <- paste0(
      "cat ",
      paste(paste0(d, s_r2), collapse = " "),
      " > ",
      s_r2_op_path
    )
    system(sys_r2_merge)
    # Output record of what was copied into each file
    write(
      c(paste0("# ", d), s_r1),
      file = s_r1_log
    )
    write(
      c(paste0("# ", d), s_r2),
      file = s_r2_log
    )
  } # end: for (s in sample_id){
} # end: for (d in dirs_to_iterate){

# Ensure output log dir exists:
system(paste0("mkdir -p ", dirname(arg_out_log), "/"))

# Create a line about the merged lanes to add to the output log
if ( (param_mergeAllLanes == FALSE) & 
  (identical(param_readLanes, list()) == FALSE) ){
  merge_lanes <- paste0("merged read lanes: ",  paste(unlist(param_readLanes), collapse = ","))
}else {
  merge_lanes <- NULL
}

# Output report file as log:
output_log <- c(
  "# Merge reads parameter report",
  "pipeline: chromatin-assembly",
  "rule: s0_merge_samples",
  paste0("species: ", param_species),
  paste0("sample ids: ", paste(sample_id, collapse = ", ")),
  paste0("merge across directories: ", param_mergeAcrossDirs),
  paste0("merge all lanes: ", param_mergeAllLanes),
  merge_lanes,
  paste0("specify lanes for sample ids: ", param_specifySampleLanes),
  paste0("use sample name: ", param_useSampleName),
  paste0("repository directory: ", param_repoDir),
  paste0("input directory: ", param_readDir),
  paste0("output directory: ", param_outdir),
  paste0("logs directory: ", log_dir),
  ""
)

write(
  output_log,
  file = arg_out_log
)
print("")
print(paste0("Output directory: ", param_outdir))
print(paste0("Output log: ", arg_out_log))
print(paste0("Individual sample logs: ", log_dir))

if (param_useSampleName == TRUE){
  # Output sample ID/name df
  sample_name_csv_path <- paste0(dirname(arg_out_log), "/", param_s0_dir, "_", param_species, "_SampleIDs.csv")
  write.csv(sample_names, file = sample_name_csv_path)
  print(paste0("Sample ID/name csv: ", sample_name_csv_path))
}

if (param_specifySampleLanes == TRUE){
  # Output sample ID/lane df
  sample_lane_csv_path <- paste0(dirname(arg_out_log), "/", param_s0_dir, "_", param_species, "_SampleLanes.csv")
  write.csv(sample_lanes, file = sample_lane_csv_path)
  print(paste0("Sample ID/lanes csv: ", sample_lane_csv_path))
}

