#########################################################################
# Irace Caster - STN File Generator for Single Algorithms
# Author: Pablo Estobar
# Date: May 2025
# Description:
# This script processes the output from multiple runs of a single
# algorithm executed with irace (.Rdata files). It reads:
#   - The execution result files (text format)
#   - The parameters configuration file
#   - The location mapping file
# Using this data, the script generates a consolidated STN file.
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
output_file_name <- ifelse(!is.null(params$output_file), params$output_file, "stn_file.stn")

# ---------- Optional parameters ----------
criteria <- ifelse(!is.null(params$criteria), params$criteria, "min")
if (!criteria %in% c("min", "max", "mean", "median", "mode")) {
  stop("Invalid criteria. Options: min, max, mean, median, mode", call. = FALSE)
}

significance <- ifelse(!is.null(params$significance), as.numeric(params$significance), 2)
if (is.na(significance)) {
  stop("Invalid significance. Must be numeric.", call. = FALSE)
}

type_order_index <- ifelse(!is.null(params$type_order), as.numeric(params$type_order), 3)
if (is.na(type_order_index) || type_order_index < 1 || type_order_index > 6) {
  stop("Invalid type_order. Must be a number between 1 and 6.", call. = FALSE)
}

# ---------- Define type order permutations ----------
type_order_list <- list(
  c("START", "STANDARD", "END"),
  c("START", "END", "STANDARD"),
  c("STANDARD", "START", "END"),
  c("STANDARD", "END", "START"),
  c("END", "START", "STANDARD"),
  c("END", "STANDARD", "START")
)
type_priority <- type_order_list[[type_order_index]]

# ---------- Load parameters file ----------
parameters <- read_parameters_file(parameters_file = parameters_file)

# ---------- Generate STN file ----------
stn_file <- generate_stn_file(
  irace_folder = input_folder,
  parameters = parameters,
  criteria = criteria,
  significancy = significance,
  type_priority = type_priority
)

# ---------- Save result ----------
save_file(
  stn_file = stn_file,
  output_folder = output_folder,
  output_file = output_file_name
)
