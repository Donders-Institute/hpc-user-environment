# Utility function to retrieve data for job bookkeeping
#
# [Input]
#  - default_jobname: the string used as job name, if
#                     SLURM_JOB_NAME is not available.
# [Output]
#  - workdir: the directory in which the script runs 
#  - jobid  : SLURM job ID or the system process ID
#  - jobname: SLURM job name or the given jobname
get_bookkeep_info <- function(default_jobname = "") {
    ## Resolve workdir (PWD directory, or SLURM_SUBMIT_DIR)
    wdir <- Sys.getenv("PWD")
    if (Sys.getenv("SLURM_SUBMIT_DIR") != "") {
        wdir <- Sys.getenv("SLURM_SUBMIT_DIR")
    }

    ## Resolve job/process identifier (process ID $$ or SLURM_JOBID)
    jid <- system("echo $$", intern = TRUE)[1]
    if (Sys.getenv("SLURM_JOBID") != "") {
        jid <- paste(Sys.getenv("SLURM_JOBID"), Sys.getenv("SLURM_STEPID"), Sys.getenv("SLURM_TASK_PID"), sep=":")
    }

    ## Resolve job name (caller function or SLURM_JOB_NAME)
    jname <- default_jobname
    if (Sys.getenv("SLURM_JOB_NAME") != "") {
        jname <- Sys.getenv("SLURM_JOB_NAME")
    }

    info <- list("workdir" = wdir, "jobid" = jid, "jobname" = jname)

    return(info)
}

# Utility function to parse Rscript command-line arguments
#
# [Output]
#  - script: name of the current R script
#  - args  : arguments provided to the current R script
parse_arguments <- function() {
    args <- commandArgs(FALSE)
    sname <- sub("--file=", "", args[grep("--file=", args)])
    if (match("--args", args, nomatch = -1) != -1) {
        args <- args[match("--args", args) + 1:length(args)]
    }
    return(list("script" = sname, "args" = args))
}

# Utility function to save R objects in an .RData file
#
# [Input]
#  - objects: a character vector containing object names to be saved to the .RData file
#  - path: the path of the file in which the objects will be saved 
#  - job_bookkeep_info: the job bookkeeping info list by which the path of the file is 
#                       constructed.
#  - append: TRUE for appending objects to the file
#
#  One of "path" and "job_bookkeep_info" is required. 
#
# [Output]
#  - script: name of the current R script
#  - args  : arguments provided to the current R script
save_objects <- function(objects, path = NA, job_bookkeep_info = NA, append = FALSE) {
    if (!identical(job_bookkeep_info, NA)) {
        outfile <- paste(job_bookkeep_info$jobname, 
                         paste('r', job_bookkeep_info$jobid, sep = ""), 
                         "RData", 
                         sep = ".")
        path <- file.path(job_bookkeep_info$workdir, outfile)
    }

    if (is.na(path)) {
        stop("output file path not specified")
    } else {
        if (file.exists(path) && append) {
            cat("appending objects ", paste0(objects, collapse = ","), " to ", path, " ...")
            # Load existing objects in environment "o"
            load(path, envir = o <- new.env())
            # Overwrite/add objects in "o"
            for (obj in objects) {
                assign(obj, get(obj), envir = o)
            }
            # Save objects in environment "o"
            save(list = ls(o), envir = o, file = path)
            cat("done\n")
        } else {
            cat("saving objects ", paste0(objects, collapse = ","), " to ", path, " ...")
            save(list = objects, file = path)
            cat("done\n")
        }
    }
}

