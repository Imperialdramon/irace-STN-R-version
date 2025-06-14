# nolint start

#########################################################################
# STN-i Generator Script for Single Algorithm Executions
# Author: Pablo Estobar
#
# Description:
# This script processes the output of irace executions for a single
# algorithm. It uses:
#   - Execution result files from irace runs (text format)
#   - Parameter configuration file
#   - Location mapping file (optional, if used inside `read_parameters_file`)
#
# It consolidates the trajectory data into a Search Trajectory Network (STN-i),
# applying a priority scheme over node types and aggregating fitness based on
# a specified criteria.
#
# Usage:
# Rscript generate_stn_i.R --input=<irace_output_folder> 
#                          --parameters=<parameters_file> 
#                          --output=<output_folder>
#                          [--output_file=<name>] 
#                          [--criteria=<aggregation_criteria>] 
#                          [--significance=<digits>]
#
# Arguments:
# --input        : (Required) Folder path containing irace execution outputs.
# --parameters   : (Required) Path to the parameters file used by irace.
# --output       : (Required) Path to the output folder for the generated STN file.
# --output_file  : (Optional) File name for the resulting .txt file (default: "stn_i_file.txt").
# --criteria     : (Optional) Aggregation function for fitness values across runs.
#                  Options: "min", "max", "mean", "median", "mode". Default is "min".
# --significance : (Optional) Numeric precision used for rounding values. Default is 2.
#
# Requirements:
# - R with the `irace` package (version >= 4.2).
# - Auxiliary functions must be available in "R/functions.R".
#
# Output:
# - A single `.txt` file stored in the output folder.
#
# Notes:
# - The script assumes a fixed priority order for node topology: STANDARD < START < END.
# - The structure and attributes of the final STN-i are compatible with downstream
#   visualization and analysis tools for STN-based workflows.
#########################################################################

# ---------- Load required packages ----------
if (!requireNamespace("irace", quietly = TRUE)) {
  stop("Error: The irace package is not installed. Please install it with 'install.packages(\"irace\")'", call. = FALSE)
} else if (packageVersion("irace") < "4.2") {
  stop(paste0("Error: irace version must be >= 4.2. Current version is ", packageVersion("irace")), call. = FALSE)
}

library(irace)

# ---------- Load utility functions ----------
source("R/functions.R")

# ---------- Parse command line arguments ----------
parse_arguments <- function(args) {
  parsed <- list()
  for (arg in args) {
    if (grepl("^--", arg)) {
      parts <- strsplit(sub("^--", "", arg), "=")[[1]]
      if (length(parts) == 2) {
        parsed[[parts[1]]] <- parts[2]
      } else {
        stop(paste("Invalid argument format:", arg), call. = FALSE)
      }
    }
  }
  return(parsed)
}

args <- commandArgs(trailingOnly = TRUE)
params <- parse_arguments(args)

# ---------- Validate required arguments ----------
required_args <- c("input", "parameters", "output")

for (param_name in required_args) {
  if (is.null(params[[param_name]])) {
    stop(paste("Missing required argument: --", param_name, sep = ""), call. = FALSE)
  }
}

# ---------- Assign and normalize paths ----------
input_folder <- normalizePath(params$input, mustWork = TRUE)
parameters_file <- normalizePath(params$parameters, mustWork = TRUE)
output_folder <- normalizePath(params$output, mustWork = TRUE)
output_file_name <- ifelse(!is.null(params$output_file), params$output_file, "stn_i_file.txt")

# ---------- Optional parameters ----------
criteria <- ifelse(!is.null(params$criteria), params$criteria, "min")
if (!criteria %in% c("min", "max", "mean", "median", "mode")) {
  stop("Invalid criteria. Options: min, max, mean, median, mode", call. = FALSE)
}

significance <- ifelse(!is.null(params$significance), as.numeric(params$significance), 2)
if (is.na(significance)) {
  stop("Invalid significance. Must be numeric.", call. = FALSE)
}

# ---------- Load parameters file ----------
parameters <- read_parameters_file(parameters_file = parameters_file)

# ---------- Generate STN-i file ----------
type_priority <- c("STANDARD", "START", "END")

stn_file <- generate_stn_file(
  irace_folder = input_folder,
  parameters = parameters,
  criteria = criteria,
  significancy = significance,
  type_priority = type_priority
)

# ---------- Save result ----------

# Create output folder if it does not exist
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
  message("Output folder created: ", output_folder)
}

output_file_path <- file.path(output_folder, output_file_name)

save_file(stn_file = stn_file, output_file_path = output_file_path)

# nolint end
