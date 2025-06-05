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
      5) (Optional) Significancy (number of decimals), default = 2
      6) (Optional) Index of permutation with the order of importance of the types, default = 2
        The permutations are:
        1) START, STANDARD, END
        2) START, END, STANDARD
        3) STANDARD, START, END
        4) STANDARD, END, START
        5) END, START, STANDARD
        6) END, STANDARD, START
      ", call. = FALSE)
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

# Validate significancy
type_permutation_value <- ifelse(length(args) > 5, as.numeric(args[6]), 3)
if (is.na(type_permutation_value) || !is.numeric(type_permutation_value) || type_permutation_value < 1 || type_permutation_value > 6) {
  stop("Error: Invalid type permutation value. Please provide a numeric value between 1 and 6.", call. = FALSE)
}

# Permutations of types
types_permutations <- list(
  c("START", "STANDARD", "END"),
  c("START", "END", "STANDARD"),
  c("STANDARD", "START", "END"),
  c("STANDARD", "END", "START"),
  c("END", "START", "STANDARD"),
  c("END", "STANDARD", "START")
)

# Validate type permutation value
type_priority <- types_permutations[[type_permutation_value]]
if (is.null(type_priority)) {
  stop("Error: Invalid type permutation value.", call. = FALSE)
}

# Read the parameters file
parameters <- read_parameters_file(parameters_file = parameters_file)

# Process the data
stn_file <- generate_stn_file(
  irace_folder=irace_folder,
  parameters=parameters,
  criteria=criteria,
  significancy=significancy,
  type_priority=type_priority
)

# Save the STN file
save_file(
  stn_file=stn_file,
  output_folder=output_folder
)
