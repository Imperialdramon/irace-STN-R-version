#########################################################################
# Irace Caster - STN File Generator for Single Algorithms
# Authors: Pablo Estobar
# Date: May 2025
# Description:
# This script processes the output from multiple runs of a single
# algorithm executed with irace (.Rdata files). It reads:
#   - The execution result files (text format)
#   - The parameters configuration file
#   - The location mapping file
# Using this data, the script generates a consolidated STN file.
#########################################################################

# ---------- Load required packages --------
## Check if 'irace' is installed and if version is >= 4.2
if (!requireNamespace("irace", quietly = TRUE)) {
  stop("Error: The irace package is not installed. Please install it with 'install.packages(\"irace\")'", call. = FALSE)
} else if (packageVersion("irace") < "4.2") {
  stop(paste0("Error: irace version must be >= 4.2. Current version is ", packageVersion("irace")), call. = FALSE)
}

library(irace)

# ---------- Load functions from functions.R ----------
## Important: Always functions.R must be in the same folder as this script
source("R/functions.R")

# ---------- Processing inputs from command line ----------
args <- commandArgs(trailingOnly = TRUE) # Take command line arguments

# Validate number of arguments
if (length(args) < 3) {
  stop("Error: Missing arguments. Please provide the following:
      1) Input folder containing the irace output files
      2) Parameters file name
      3) Output folder
      4) (Optional) Selection criteria (min|max|mean|median|mode), default = min
      5) (Optional) Significancy (number of decimals), default = 2", call. = FALSE)
}

# Validate input folder (convert to absolute path)
irace_folder <- normalizePath(args[1], mustWork = TRUE)

# Validate parameters file (convert to absolute path)
parameters_file <- normalizePath(args[2], mustWork = TRUE)

# Validate output folder (convert to absolute path)
output_folder <- normalizePath(args[3], mustWork = TRUE)

# Validate criteria
criteria <- ifelse(length(args) > 3, args[4], "min")
if (!criteria %in% c("min", "max", "mean", "median", "mode")) {
  stop("Error: Invalid criteria. Options are: min, max, mean, median, mode", call. = FALSE)
}

# Validate significancy
significancy <- ifelse(length(args) > 4, as.numeric(args[5]), 2)
if (is.na(significancy) || !is.numeric(significancy)) {
  stop("Error: Invalid significancy. Please provide a numeric value.", call. = FALSE)
}

# Read the parameters file
parameters <- read_parameters_file(parameters_file = parameters_file)

# Process the data
stn_file <- generate_stn_file(irace_folder, parameters, criteria, significancy)

# Save the STN file
save_file(stn_file, output_folder)

# parameters_file <- "Tests/parameters.csv"
# parameters <- read_parameters_file(parameters_file)
# #parameters$domains$ants
# stn_file <- generate_stn_file(
#   #irace_folder = "Test-irace/",
#   irace_folder = "Tests/irace-files/ACOTSP-N/",
#   parameters = parameters,
#   criteria = "mean",
#   significancy = 2
# )
# save_file(stn_file, "Test-irace/")