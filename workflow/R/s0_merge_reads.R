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
# $ Rscript workflow/R/s0_merge_reads.R repo_dir=/path/to/chromatin-assembly/ config=config/chromatin_assembly_config.yml out=/path/to/output.txt 
# For example:
# $ Rscript workflow/R/s0_merge_reads.R repo_dir=/scratch3/che318/chromatin-assembly/ config=config/chromatin_assembly_config.yml out=/Users/che318/Repos/chromatin-assembly/log/s0_merge_samples_gecko.txt 



#### PREPARE CONFIG FILE ####
# Parse input argument - chromatin_assembly_config.yml directory
# args = c("config=/Users/che318/Repos/chromatin-assembly/config/chromatin_assembly_config.yml", "out=/Users/che318/Repos/chromatin-assembly/log/s0_merge_samples_gecko.txt")
# args = c("config=/scratch3/che318/chromatin-assembly/config/chromatin_assembly_config.yml", "out=/scratch3/che318/chromatin-assembly/log/s0_merge_samples_gecko.txt")
args <- commandArgs(trailingOnly = TRUE)

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
config <- readLines(arg_config_file)
# Replace double quotes with single
config <- gsub('\\"', "'", config)

# Identify empty lines
empty_lines <- which(config == "")



#### EXTRACT PARAMETERS FROM CONFIG FILE ####
print("Extracting parameters")

# Extract individual params
param_Species <- gsub(" |'", "", strsplit(grep(
  "# ref_species:",
  grep("ref_species: ", config, value = T),
  value = T,
  invert = T
), ":")[[1]][2])
param_repoDir <- gsub(" |'", "", strsplit(grep(
  "# repo_dir:",
  grep("repo_dir: ", config, value = T),
  value = T,
  invert = T
), ":")[[1]][2])
param_useSampleName <- as.logical(gsub(" |'", "", strsplit(grep(
  "# use_names:",
  grep("use_names:", config, value = T),
  value = T,
  invert = T
), ":")[[1]][2]))
param_performMerge <- as.logical(gsub(" |'", "", strsplit(grep(
  "# perform_merge:",
  grep("perform_merge:", config, value = T),
  value = T,
  invert = T
), ":")[[1]][2]))
param_mergeAcrossDirs <- as.logical(gsub(" |'", "", strsplit(grep(
  "# merge_across_dirs:",
  grep("merge_across_dirs:", config, value = T),
  value = T,
  invert = T
), ":")[[1]][2]))
param_readDir <- gsub(" |'", "", strsplit(grep(
  "# read_dir:",
  grep("read_dir: ", config, value = T),
  value = T,
  invert = T
), ":")[[1]][2])
param_readDir_full <- param_readDir # Full path input in config file
param_specifyLanes <- as.logical(gsub(" |'", "", strsplit(grep(
  "# specify_lanes:",
  grep("specify_lanes:", config, value = T),
  value = T,
  invert = T
), ":")[[1]][2]))
param_readLanes <- unlist(strsplit(gsub(" |'|\\[|\\]", "", strsplit(grep(
  "# read_lanes:",
  grep("read_lanes:", config, value = T),
  value = T,
  invert = T
), ":")[[1]][2]), ","))
param_s0Dir <- gsub(" |'", "", strsplit(
  grep("step0:", config[grep("output_dir:", config):length(config)], 
       value = T
  ), ":")[[1]][2])
param_Outdir <- paste0(param_repoDir, "results/", param_Species, "/", param_s0Dir, "/")

# Extract sample ids
sample_id_start <- which(
  config == 
    grep("# sample_ids:", grep("sample_ids:", config, value = T), value = T, invert = T)
)
if (gsub(" ", "", config[sample_id_start]) == "sample_ids:[]"){
  # No sample ids provided (empty dictionary)
  sample_id = NA
} else {
  sample_id_end <- empty_lines[which(empty_lines > sample_id_start)][1]-1
  sample_id_lines <- config[sample_id_start:sample_id_end]
  sample_id_txt <- 
    gsub("'", "", 
         gsub(" ", "", 
              gsub("\\] ", "", 
                   gsub(
                     "sample_ids: \\[", "", 
                     sample_id_lines
                   )
              )
         )
    )
  sample_id <- unlist(strsplit(sample_id_txt, ","))
}

# Extract sample names
sample_name_start <- which(
  config == 
    grep("# sample_names:", grep("sample_names:", config,  value = T), value = T, invert = T)
)
if (config[sample_name_start] == "sample_names:[]"){
  # No sample names provided (empty dictionary)
  sample_name_df = NA
} else {
  sample_name_end <- empty_lines[which(empty_lines > sample_name_start)][1]-1
  sample_name_lines <- config[sample_name_start:sample_name_end]
  sample_name_txt <- 
    gsub("'", "", 
         gsub(" ", "", 
              gsub("\\] ", "", 
                   gsub(
                     "sample_names: \\[", "", 
                     sample_name_lines
                   )
              )
         )
    )
  sample_name_pairs <- unlist(strsplit(sample_name_txt, ","))
  sample_name_df <- data.frame(
    "sample_name" = unlist(lapply(strsplit(sample_name_pairs, ":"), function(x){x[1]})),
    "sample_id" = unlist(lapply(strsplit(sample_name_pairs, ":"), function(x){x[2]}))
  )
}


print(paste0("Repo dir: ", param_repoDir))
print("")


#### ERROR CHECKING ###
print("Checking input")

if (length(list.files(param_readDir_full, recursive = T)) == 0){
  stop(
    c(
      " \n",
      "No files in supplied read directory",
      " \n",
      "Check directory: ",
      " \n",
      param_readDir_full
    ), 
    call.=FALSE
  )
}

if (length(grep("fastq|fastq.gz", list.files(param_readDir_full, recursive = T))) == 0){
  stop(
    c(
      " \n",
      "No .fastq or .fastq.gz files in supplied read directory",
      " \n",
      "Check directory: ",
      " \n",
      param_readDir_full
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
      "Enter sample IDs into config file"
    ), 
    call.=FALSE
  )
}

if (length(sample_id) == 1){
  # sample id length = 1
  if (is.na(sample_id) == TRUE){
    # sample id = NA
    stop(
      c(
        " \n",
        "No sample IDs provided",
        " \n",
        "Enter sample IDs into config file"
      ), 
      call.=FALSE
    )
  }
}

if (length(which(is.na(sample_id) == TRUE)) == length(sample_id)){
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

if (param_useSampleName == TRUE &
    length(which(is.na(sample_id) == TRUE)) == length(sample_id)){
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

if (class(sample_name_df) == "logical" & 
    length(sample_name_df) == 1){
  if (is.na(sample_name_df) == TRUE){
    stop(
      c(
        " \n",
        "No sample names provided",
        " \n",
        "Enter sample names into config file",
        " \n",
        "For example:",
        " \n",
        "sample_name: ['sample01':'R111111', 'sample02':'R222222']"
      ), 
      call.=FALSE
    )
  }
}


#### MERGE READS ####
print("Merging reads")

if (param_performMerge == TRUE){
  ## Create the output dirs
  sys_mkdir <- paste0("mkdir -p ", param_Outdir)
  system(sys_mkdir)
  
  ## Create a log dir
  log_dir <- paste0(param_repoDir, "log/", param_s0Dir, "/")
  sys_mkdir_log <- paste0("mkdir -p ", log_dir)
  system(sys_mkdir_log)
  
  ## Identify read directories
  if (param_mergeAcrossDirs == TRUE){
    ## To merge reads ACROSS dirs
    ## One R1/R2 file per sample name 
    ## i.e., if you have multiple dirs within reads/, and the same sample name
    ## is present within these dirs, then those files will be combined
    # Use the read_dir
    dirs_to_iterate <- param_readDir_full
  } else if (param_mergeAcrossDirs == FALSE){
    ## To merge reads WITHIN dirs
    ## i.e., One R1/R2 file per sample name per directory (for directories inside the reads/ directory)
    # List directories within the read_dir
    internal_dirs <-  gsub("//", "/", list.dirs(param_readDir_full))
    dirs_to_iterate <- internal_dirs[internal_dirs != param_readDir_full]
  }
  # Iterate over directories to collect reads by sample_id
  for (d in dirs_to_iterate){
    # Print dir name
    print(paste0("Processing directory ", d))
    
    # Create output files for this directory
    if (param_mergeAcrossDirs == TRUE){
      d_out_dir <- param_Outdir
      d_log_dir <- log_dir
    } else if (param_mergeAcrossDirs == FALSE){
      d_out_dir <- paste0( , basename(d), "/")
      d_log_dir <- paste0(log_dir, basename(d), "/")
    }
    system(paste0("mkdir -p ", d_out_dir))
    system(paste0("mkdir -p ", d_log_dir))
    
    # Merge reads across dirs
    d_all_files <- list.files(d, recursive = T)
    d_read_paths <- grep("fastq|fastq.gz", d_all_files, value = T)
    
    # Iterate through each sample_id to extract reads
    for (s in sample_id){
      # List all files with that sample id
      s_all_reads <- d_read_paths[grep(s, basename(d_read_paths))]
      if (param_specifyLanes == TRUE){
        # If only keeping specific lanes, extract those now
        keep_lanes <- paste0("_L", sprintf("%03s", param_readLanes))
        s_lane_reads <- s_all_reads[grep(paste0(keep_lanes, collapse = "|"), basename(s_all_reads))]
      } else {
        # Keep all lanes
        s_lane_reads <- s_all_reads
      }
      # Separate R1 and R2
      s_r1 <- s_lane_reads[grep("_R1", basename(s_lane_reads))]
      s_r2 <- s_lane_reads[grep("_R2", basename(s_lane_reads))]
      # Construct output file names
      if (param_useSampleName == TRUE){
        s_name <- sample_name_df$sample_name[which(sample_name_df$sample_id == s)]
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
        paste0(d, s_r1),
        file = s_r1_log
      )
      write(
        paste0(d, s_r2),
        file = s_r2_log
      )
    } # end: for (s in sample_id){
  } # end: for (d in dirs_to_iterate){
  
  # Ensure output log dir exists:
  system(paste0("mkdir -p ", dirname(arg_out_log), "/"))
  
  # Output report file as log:
  output_log <- c(
    "# Merge reads parameter report",
    "pipeline: chromatin-assembly",
    "rule: s0_merge_samples",
    paste0("species: ", param_Species),
    paste0("sample ids: ", paste(sample_id, collapse = ", ")),
    paste0("merge reads: ", param_performMerge),    
    paste0("merge across directories: ", param_mergeAcrossDirs),
    paste0("File paths use sample ID: ", !param_useSampleName),
    paste0("File paths use sample name: ", param_useSampleName),
    paste0("specify lanes: ", param_specifyLanes),
    paste0("selected_lanes: ", if (param_specifyLanes == TRUE){paste(param_readLanes, collapse = ", ")} else {NA}),
    paste0("read directory: ", param_readDir_full),
    paste0("output directory: ", param_Outdir),
    paste0("logs directory: ", log_dir),
    ""
  )
  write(
    output_log,
    file = arg_out_log
  )
  print("")
  print(paste0("Output directory: ", param_Outdir))
  print(paste0("Output log: ", arg_out_log))
  print(paste0("Individual sample logs: ", log_dir))
} # end: if (param_performMerge == TRUE){


