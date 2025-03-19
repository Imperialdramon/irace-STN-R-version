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
# Using this data, the script generates a consolidated STN file,
# which compiles all irace run results into a structured format.
# Input:
#   - Directory containing:
#       * Execution result files (.Rdata files)
#       * Parameters file (text format)
#       * Location file (text format)
#       * Output directory
# Output:
#   - STN file (text format), saved in the specified output directory.
#########################################################################

# ---------- Load required packages --------
## Check if 'irace' is installed
if (!requireNamespace("irace", quietly = TRUE)) {
  stop("Error: The irace package ar not installed. Install with 'install.packages('irace')'", call. = FALSE)
}
# Load the 'irace' package
library(irace)

# ---------- Processing inputs from command line ----------
args <- commandArgs(trailingOnly = TRUE)   # Take command line arguments
# Test if there are two arguments if not, return an error
if (length(args) < 4) {
  stop("Error: Missing arguments. Please provide the following arguments: \
      1) Input folder containing the irace output files \
      2) Parameters file name \
      3) Location file name \
      4) Output folder \
      5) (Optional) Type of criteria used to select the best value of configuration for location (default is minimum) \
      6) (Optional) Significancy used for the configuration value (default is 2 decimals)",
    call. = FALSE
  )
}
# Test if the input folder exists
irace_folder <- args[1]
if (!dir.exists(irace_folder)) {
  stop("Error: Input folder does not exist", call. = FALSE)
}
# Test if the parameters file exists
parameters_path <- args[2]
if (!file.exists(parameters_path)) {
  stop("Error: Parameters file does not exist", call. = FALSE)
}
# Test if the location file exists
locations_path <- args[3]
if (!file.exists(locations_path)) {
  stop("Error: Location file does not exist", call. = FALSE)
}
# Test if the output folder exists
output_folder <- args[4]
if (!dir.exists(output_folder)) {
  stop("Error: Output folder does not exist", call. = FALSE)
}
# Test if the criteria is valid
criteria <- ifelse(length(args) > 4, args[5], "min")
if (!criteria %in% c("min", "max")) {
  stop("Error: Invalid criteria. Please use 'min' or 'max'", call. = FALSE)
}
# Test if the significancy is valid
significancy <- ifelse(length(args) > 5, as.numeric(args[6]), 2)
if (!is.numeric(significancy)) {
  stop("Error: Invalid significancy. Please use a numeric value", call. = FALSE)
}

# ---------- Process irace output files ----------
stn_file <- generate_stn_file(irace_folder, parameter_path, location_file, output_folder, criteria, significancy)
save_file(stn_file, output_folder)

# ---------- Functions definitions ----------
# Function to process all .Rdata files and generate the STN file
# input: irace_folder - Path to the folder containing the .Rdata files
#        parameters_path - Path to the parameters file
#        locations_path - Path to the locations file
#        output_folder - Path to the output folder
#        criteria - Criteria used to select the best value of configuration for location
#        significancy - Significancy used for the configuration value
# output: stn_file - Data frame with the STN file
generate_stn_file <- function(irace_folder, parameters_path, locations_path, output_folder, criteria, significancy) {
  # Read the .Rdata files
  rdata_files <- list.files(irace_folder, pattern = "\\.Rdata$", full.names = TRUE)
  if (length(rdata_files) == 0) {
    stop("Error: No .Rdata files found in the input folder", call. = FALSE)
  }

  # Read the parameters
  params <- read_parameters_file(parameters_path = parameters_path)

  # Read the locations
  locations <- read_locations_file(locations_path = locations_path)

  message("Processing ", length(rdata_files), " .Rdata files (equivalent to the same runs quantity)")

  stn_file <- data.frame()

  # TODO:
  # 1. Leer el archivo .Rdata.
  # 2. Extraer los IDs de las élites por iteración -> elite_ids.
  # 3. Extraer los IDs de las demás configuraciones por iteración -> config_ids.
  # 4. Obtener los parámetros de cada configuración -> parameters.
  # 5. Calcular la ubicación de cada configuración -> location.
  # 6. Almacenar los valores de cada ubicación en la lista de un diccionario -> locations:list(values)
  # 7. Generar el archivo STN del archivo actual, estableciendo conexiones:
  #    - Las configuraciones iniciales no élites se conectan consigo mismas.
  #    - Las conexiones entre iteraciones siempre conectan con elites usando el parent_id.
  #    - Agregar los parámetros START y END, con START para todas las de iteración 1 y END para las últimas élites.
  # 8. Agregar el STN del archivo actual al archivo STN final -> stn_file.
  # 9. Repetir el proceso para cada archivo .Rdata.
  # 10. Calcular el valor final de cada locación usando el diccionario de locaciones.
  # 11. Generar el archivo STN final, conservando el ID de la run y todos los datos a lo largo de las iteraciones.

  # Formato de salida
  # RUN VALUE1 LOCATION1 ELITE1 TYPE1 VALUE2 LOCATION2 ELITE2 TYPE2
  # Donde:
  # - RUN: ID de la run
  # - VALUE1: Valor de la configuración de inicio
  # - LOCATION1: Código de la locación de la configuración de inicio
  # - ELITE1: Indicador de élite de la configuración de inicio (TRUE|FALSE)
  # - TYPE1: Tipo configuración (START|END|MID)
  # - VALUE2: Valor de la configuración de fin
  # - LOCATION2: Código de la locación de la configuración de fin
  # - ELITE2: Indicador de élite de la configuración de fin (TRUE|FALSE)
  # - TYPE2: Tipo configuración (START|END|MID)
  # IMPORTANTE: Las configuraciones de inicio pueden no ser élite, si es así se conectan consigo mismas.
  # IMPORTANTE: Las configuraciones del medio siempre estarán conectadas con las élites.
  # IMPORTANTE: Las configuraciones de fin siempre son élite.

  for (rdata_file in rdata_files) {
    # Load the .Rdata file
    rdata <- read_logfile(rdata_file)
  }

  return(stn_file)
}

# Function to read and process the parameters file
# input: parameters_path - Path to the parameters file
# output: params - Data frame with the parameters
read_parameters_file <- function(parameters_path) {
  # TODO: Implementar la lectura del archivo de parámetros
  read.table(parameters_path, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
}

# Function to read and process the locations file
# input: locations_path - Path to the locations file
# output: locations - Data frame with the locations
read_locations_file <- function(locations_path) {
  # TODO: Implementar la lectura del archivo de locaciones
  read.table(locations_path, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
}

# Function to save the STN file
# input: stn_file - Data frame with the STN file
#        output_folder - Path to the output folder
save_file <- function(stn_file, output_folder) {
  # TODO: Implementar la escritura del archivo STN
  stn_file_path <- file.path(output_folder, "stn_file.txt")
  write.table(stn_file, stn_file_path, sep = "\t", row.names = FALSE)
  message("STN file saved in: ", stn_file_path)
}
