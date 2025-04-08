## Quick script to take in user-supplied input parameters, then use them to
# update SLURM jobscripts for that user.

# Parse input arguments
args = commandArgs(trailingOnly=TRUE)

if (length(args) == 0) {
  # Test if there is at least one argument: if not, return an error
  stop(
    c(
      " \n",
      "Supply arguments to script:",
      "$ Rscript resources/user_update_jobscripts.R mail-user={email@email.com} mail-type={FAIL} account={account}",
      "To remove an argument from the SLURM scripts, set it to FALSE",
      "For example, to receive no emails: ",
      "$ Rscript resources/user_update_jobscripts.R mail-user=FALSE mail-type=FALSE account={account}"
    ), 
    call.=FALSE
  )
} else if (length(args) != 3){
  # Test that there are 3 input arguments: if not, return an error
  stop(
    c(
      "Supply arguments to script:",
      " \n",
      "    $ Rscript resources/user_update_jobscripts.R mail-user={email@email.com} mail-type={FAIL} account={account}",
      " \n",
      "For example:",
      " \n",
      "    $ Rscript resources/user_update_jobscripts.R mail-user=test@test.com.au mail-type=END,FAIL,TIME_LIMIT account=OD-XXXXXX",
      " \n",
      "",
      " \n",
      "To remove an argument from the SLURM scripts, set it to FALSE",
      " \n",
      "",
      " \n",
      "To receive no emails: ",
      " \n",
      "    $ Rscript resources/user_update_jobscripts.R mail-user=FALSE mail-type=FALSE account={account}",
      " \n"
    ), 
    call.=FALSE
  )
} else {
  email_address = strsplit(args[[1]], "=")[[1]][2]
  email_prefs = strsplit(args[[2]], "=")[[1]][2]
  account_num = strsplit(args[[3]], "=")[[1]][2]
  
  print(
    paste0(
      "New email address: ", 
      (if ((email_address) == "FALSE"){NA} else {email_address})
    )
  )
  print(
    paste0(
      "New email preferences: ",
      (if ((email_prefs) == "FALSE"){NA} else {email_prefs})
    )
  )
  print(
    paste0(
      "New account number: ",
      (if ((account_num) == "FALSE"){NA} else {account_num})
    )
  )
  
  repo_dir <- getwd()
  if (identical(basename(repo_dir), "chromatin-assembly") == FALSE){
    # If repo_dir doesn't end in "chromatin-assembly", raise error
    stop(
      paste0(
        " \n",
        "Navigate to the chromatin-assembly directory before running this script:",
        " \n",
        "    $ cd /scratch3/che318/chromatin-assembly/",
        " \n",
        "    $ Rscript resources/user_update_jobscripts.R mail-user={email@email.com} mail-type={FAIL} account={account} "
      ), 
      call.=FALSE
    )
  } else {
    # Update output log directory
    slurm_log_dir <- paste0(repo_dir, "/logs/")
    print(paste0("New SLURM log directory: ", slurm_log_dir))
    
    # List all jobscripts
    jobscripts_in_dir <- paste0(repo_dir, "/jobscripts/templates/")
    jobscripts_out_dir <- paste0(repo_dir, "/jobscripts/")
    jobscripts_paths <- paste0(jobscripts_in_dir, list.files(jobscripts_in_dir))
    
    # Open each jobscript and update details:
    for (j in jobscripts_paths){
      j_lines <- readLines(j)
      new_j_lines <- c(j_lines, "") # add empty line just in case
      
      # Check that if mail type is present, so is email address:
      email_address_present <- !(identical(email_address, "FALSE"))
      email_prefs_present <- !(identical(email_prefs, "FALSE"))
      if (
        email_address_present == FALSE & 
        email_prefs_present == TRUE
      ){
        # Raise error - need to provide email address if using email prefs
        stop(
          paste0(
            " \n",
            "If using mail-type flag, email address must be provided with mail-user flag:",
            " \n",
            "    $ Rscript resources/user_update_jobscripts.R mail-user={email@email.com} mail-type={FAIL} account={account} ",
            " \n",
            " \n",
            "To remove email notifications from all jobscripts:",
            " \n",
            "    $ Rscript resources/user_update_jobscripts.R mail-user=FALSE mail-type=FALSE account={account} "
          ), 
          call.=FALSE
        )
      } else if (
        email_address_present == TRUE & 
        email_prefs_present == FALSE
      ){
        # Raise error - need to provide email prefs if using email address
        stop(
          paste0(
            " \n",
            "If using mail-user flag, mail preferences must be provided with mail-type flag:",
            " \n",
            "    $ Rscript resources/user_update_jobscripts.R mail-user={email@email.com} mail-type={FAIL} account={account} ",
            " \n",
            " \n",
            "To remove email notifications from all jobscripts:",
            " \n",
            "    $ Rscript resources/user_update_jobscripts.R mail-user=FALSE mail-type=FALSE account={account} "
          ), 
          call.=FALSE
        )
      } else {
        # Both email address and mail type are input
        # OR
        # Neither email address and mail type are input
        
        # Update email address
        if (identical(email_address, "FALSE") == FALSE){
          new_j_lines[grep("#SBATCH --mail-user=", new_j_lines)] <-
            paste0("#SBATCH --mail-user=", email_address)
        } else {
          new_j_lines <- 
            new_j_lines[
              setdiff(
                1:length(new_j_lines), 
                grep("#SBATCH --mail-user=", new_j_lines))
            ]
        }
        
        # Update mail type
        if (identical(email_prefs, "FALSE") == FALSE){
          new_j_lines[grep("#SBATCH --mail-type=", new_j_lines)] <-
            paste0("#SBATCH --mail-type=", email_prefs)
        } else{
          new_j_lines <- 
            new_j_lines[
              setdiff(
                1:length(new_j_lines), 
                grep("#SBATCH --mail-type=", new_j_lines)
              )
            ]
        }
        # Update account number
        if (identical(account_num, "FALSE") == FALSE){
          new_j_lines[grep("#SBATCH --account=", new_j_lines)] <-
            paste0("#SBATCH --account=", account_num)
        } else{
          new_j_lines <- 
            new_j_lines[
              setdiff(
                1:length(new_j_lines), 
                grep("#SBATCH --account=", new_j_lines)
              )
            ]
        }
        # Update SLURM output error and output file paths
        new_j_lines[grep("#SBATCH --error=", new_j_lines)] <- 
          paste0("#SBATCH --error=", slurm_log_dir, "slurm_%j_%x.err")
        new_j_lines[grep("#SBATCH --out=", new_j_lines)] <- 
          paste0("#SBATCH --out=", slurm_log_dir, "slurm_%j_%x.out")
        # Write new file
        j_out_path <- paste0(jobscripts_out_dir, basename(j))
        write(new_j_lines, file = j_out_path)
      } # end: check have email address if email prefs are provided
    } # end: iterating through jobscripts
    # Output csv file of new params
    email_present =
      op_df <- data.frame(
        "SLURM_parameter" = c(
          "--mail-user",
          "--mail-type",
          "--account",
          "--error",
          "--out"
        ),
        "new_value" = c(
          (if ((email_address) == "FALSE"){NA} else {email_address}), 
          (if ((email_prefs) == "FALSE"){NA} else {email_prefs}),
          (if ((account_num) == "FALSE"){NA} else {account_num}),
          paste0(slurm_log_dir, "slurm_%j_%x.err"), 
          paste0(slurm_log_dir, "slurm_%j_%x.out")
        ),
        "present_in_jobscripts" = c(
          !(email_address == "FALSE"), 
          !(email_prefs == "FALSE"),
          !(account_num == "FALSE"),
          TRUE,
          TRUE
        )
      )
    
    write.csv(
      op_df,
      file = paste0(jobscripts_out_dir, "jobscript_user_params.csv")
    )
    
    print("")
    print(
      paste0(
        "Saved record of user input to ",
        paste0(jobscripts_out_dir, "jobscript_user_params.csv")
      )
    )
    
  } # end: check that within chromatin-assembly directory
} # else: length of arguments check

