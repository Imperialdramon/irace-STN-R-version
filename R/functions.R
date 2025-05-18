#' Reads and processes a parameters definition file for irace tuning.
#'
#' This function reads a CSV file that defines the parameters to be used in an irace tuning scenario,
#' processing both categorical/ordinal values and numerical ranges (integer or real).
#' Additionally, it constructs a structured dictionary (`param_domains`) that includes
#' the parameter domains and location settings, with built-in validations for correct formats.
#'
#' @param parameters_file `character(1)`\cr
#'   Path to the parameters CSV file (semicolon-separated).
#'
#' @return A list with two elements:
#'   \describe{
#'     \item{`params`}{A `data.frame` containing the processed parameters.}
#'     \item{`domains`}{A list of parameter domains, with structured values and locations
#'       depending on the parameter type (`c`, `o`, `i`, `r`).}
#'   }
#'
#' @export
read_parameters_file <- function(parameters_file) {
  # Read the parameters file
  params <- read.csv2(parameters_file, header = TRUE, stringsAsFactors = FALSE)
  # Auxiliary function to clean up the values
  clean_array <- function(x) {
    x <- gsub("[()]", "", x) # Delete parentheses
    trimws(x) # Trim leading and trailing whitespace
  }
  # Auxiliary function to parse the location dictionary
  parse_location_dict <- function(loc_vector) {
    loc_split <- strsplit(loc_vector, ":")
    # Validate that each element has exactly two parts (name and value)
    if (any(sapply(loc_split, length) != 2)) {
      stop("Error: Formato incorrecto en LOCATIONS_ARRAY (debe ser 'name:value')", call. = FALSE)
    }
    # Convert to named list
    loc_list <- sapply(loc_split, function(x) as.numeric(x[2]))
    names(loc_list) <- sapply(loc_split, function(x) x[1])
    return(loc_list)
  }
  # Initialize the domains list
  domains <- list()
  # Iterate through each parameter and process the values and locations
  params$VALUES_ARRAY <- mapply(function(type, values, locations, name) {
    values <- clean_array(values)
    locations <- clean_array(locations)
    # If the parameter is categorical or ordinal
    # then interpret the values and locations as vectors
    if (type %in% c("c", "o")) {
      values_vec <- strsplit(values, ",")[[1]]
      loc_vector <- strsplit(locations, ",")[[1]]
      loc_dict <- parse_location_dict(loc_vector)
      # Validate that the number of values matches the number of locations
      if (length(values_vec) != length(loc_dict)) {
        stop(paste("Error: Desajuste entre VALUES y LOCATIONS en parámetro:", name), call. = FALSE)
      }
      # Save in the domains structure
      domains[[name]] <<- list(
        values = values_vec,
        locations = loc_dict
      )
      return(values_vec)
    # If the parameter is integer or real
    } else if (type %in% c("i", "r")) {
      values_nums <- as.numeric(strsplit(values, ",")[[1]])
      locations_nums <- as.numeric(strsplit(locations, ",")[[1]])
      # Validate that the number of values and locations is correct
      if (length(values_nums) != 2) {
        stop(paste("Error: VALUES debe tener (min,max) para parámetro:", name), call. = FALSE)
      }
      # Validate that the number of locations is correct
      if (length(locations_nums) != 2) {
        stop(paste("Error: LOCATIONS debe tener (significance, step) para parámetro:", name), call. = FALSE)
      }
      # Save in the domains structure
      domains[[name]] <<- list(
        values = list(min = values_nums[1], max = values_nums[2]),
        locations = list(step = locations_nums[1], significance = locations_nums[2])
      )
      return(values_nums)
    } else {
      stop(paste("Error: Tipo de parámetro desconocido:", type), call. = FALSE)
    }
  }, params$TYPE, params$VALUES_ARRAY, params$LOCATIONS_ARRAY, params$NAME, SIMPLIFY = FALSE)
  # Convert the parameters data frame to a list
  params$LOCATIONS_ARRAY <- lapply(seq_len(nrow(params)), function(i) {
    type <- params$TYPE[i]
    if (type %in% c("c", "o")) {
      loc_vector <- strsplit(clean_array(params$LOCATIONS_ARRAY[i]), ",")[[1]]
      return(loc_vector)
    } else if (type %in% c("i", "r")) {
      return(as.numeric(strsplit(clean_array(params$LOCATIONS_ARRAY[i]), ",")[[1]]))
    }
  })
  return(list(
    params = params,
    domains = domains
  ))
}

#' Generate location code from configuration
#'
#' This function generates a location code based on the configuration values
#' and the parameter domains.
#'
#' @param config A configuration object containing the .ID.
#' @param iraceResults An iraceResults object containing the results of the tuning run.
#' @param parameters A list containing the parameter domains and their locations.
#'
#' @return A string representing the location code.
#'
#' @export
get_location_code <- function(config, iraceResults, parameters) {
  location_code <- ""
  # Obtain the configuration values for the current configuration 
  config_values <- getConfigurationById(iraceResults, as.numeric(config$.ID.), drop.metadata = FALSE)
  # For each parameter, get the location code
  for (param_name in names(config_values)) {
    # Skip if the parameter is not in the parameters list
    if (!(param_name %in% names(parameters$domains))) {
      next
    }
    param_type <- parameters$params$TYPE[parameters$params$NAME == param_name]
    param_value <- config_values[[param_name]]
    # If the parameter is categorical or ordinal
    if (param_type %in% c("c", "o")) {
      loc_dict <- parameters$domains[[param_name]]$locations
      # If the parameter value is NA or "<NA>", use Xs for the code
      if (is.na(param_value) || param_value == "<NA>") {
        max_digits <- nchar(as.character(max(loc_dict)))
        code_part <- paste0(rep("X", max_digits), collapse = "")
      }
      # Otherwise, find the corresponding location code for the value
      else {
        if (param_value %in% names(loc_dict)) {
          code_num <- loc_dict[[param_value]]
          max_value <- max(loc_dict)
          max_digits <- nchar(as.character(max_value))
          current_digits <- nchar(as.character(code_num))
          difference <- max_digits - current_digits
          code_part <- paste0(strrep("0", difference), code_num)
        } else {
          max_digits <- nchar(as.character(max(loc_dict)))
          code_part <- paste0(rep("X", max_digits), collapse = "")
        }
      }
    }
    # If the parameter is integer or real
    else if (param_type %in% c("i", "r")) {
      param_domain <- parameters$domains[[param_name]]
      lower_bound <- param_domain$values$min
      upper_bound <- param_domain$values$max
      significance <- param_domain$locations$significance
      step <- param_domain$locations$step
      # Validate that the parameter domains are correctly defined
      if (is.na(lower_bound) || is.na(upper_bound) || is.na(significance) || is.na(step)) {
        stop(paste0("Error: Parameter domain not properly defined for: ", param_name))
      }
      # If the parameter value is NA or "<NA>", use Xs for the code
      if (is.na(param_value) || param_value == "<NA>") {
        max_upper_scaled <- as.integer(upper_bound * (10^significance))
        # Validate the max upper scaled value
        if (is.na(max_upper_scaled) || max_upper_scaled <= 0) {
          stop(paste0("Error: max_upper_scaled invalid for parameter ", param_name))
        }
        total_digits <- nchar(as.character(max_upper_scaled))
        if (is.na(total_digits) || total_digits <= 0) {
          stop(paste0("Error: total_digits invalid for parameter ", param_name))
        }
        code_part <- paste0(rep("X", total_digits), collapse = "")
      } else {
        # Calculate the subrange index and the scaled value
        subrange_index <- floor((as.numeric(param_value) - lower_bound) / step)
        calculated_value <- lower_bound + subrange_index * step
        scaled_value <- as.integer(calculated_value * (10^significance))
        max_upper_scaled <- as.integer(upper_bound * (10^significance))
        # Validate the scaled value and max upper scaled value
        if (is.na(scaled_value) || is.na(max_upper_scaled)) {
          stop(paste0("Error: scaled_value or max_upper_scaled is NA for parameter ", param_name,
                      " (scaled_value = ", scaled_value, 
                      ", max_upper_scaled = ", max_upper_scaled, ")"))
        }
        current_digits <- nchar(as.character(scaled_value))
        max_upper_digits <- nchar(as.character(max_upper_scaled))
        # Validate the digits
        if (is.na(current_digits) || is.na(max_upper_digits)) {
          stop(paste0("Error: digits NA for parameter ", param_name,
                      " (scaled_value = ", scaled_value, 
                      ", max_upper_scaled = ", max_upper_scaled, ")"))
        }
        difference <- max_upper_digits - current_digits
        if (is.na(difference)) {
          stop(paste0("Error: difference is NA for parameter ", param_name))
        }
        if (difference < 0) {
          stop(paste0("Error: difference negative (", difference, ") for parameter ", param_name, 
                      " (scaled_value = ", scaled_value, 
                      ", max_upper_scaled = ", max_upper_scaled, ")"))
        }
        code_part <- paste0(strrep("0", difference), scaled_value)
      }
    }
    # If the parameter type is not supported
    else {
      stop(paste0("Error: Unsupported parameter type: ", param_type))
    }
    # Append the code part to the total location code
    location_code <- paste0(location_code, code_part)
  }
  return(location_code)
}

#' Generate STN File
#'
#' This function processes all `.Rdata` files in a specified folder and generates an STN file
#' based on the provided parameters and criteria.
#'
#' @param irace_folder A string specifying the path to the folder containing the `.Rdata` files.
#' @param parameters A data frame containing the parameters and their domains, including values and locations.
#' @param criteria A string specifying the criteria used to select the best configuration value for each location.
#'        Possible values are `"min"`, `"max"`, `"mean"`, `"median"`, or `"mode"`.
#'        Defaults to `"min"`.
#' @param significancy An integer specifying the number of decimal places to round the configuration values.
#'        Defaults to 2.
#' @param original_elite A boolean indicating whether to use the original elite status for nodes.
#'        Defaults to `FALSE`.
#' @param original_type A boolean indicating whether to use the original type for nodes.
#'        Defaults to `FALSE`.
#' @param type_priority A character vector specifying the order of importance for the types.
#'        The default order is `c("START", "STANDARD", "END")`.
#'
#' @return A data frame representing the STN file.
#'
#' @details
#' The function reads `.Rdata` files from the specified folder, processes the data based on the given
#' parameters and criteria, and generates an STN file. The STN file contains the best configuration
#' values for each location, rounded to the specified number of decimal places.
#'
#' @examples
#' \dontrun{
#' # Example usage:
#' irace_folder <- "path/to/irace/folder"
#' parameters <- read_parameters_file("path/to/parameters.csv")
#' criteria <- "mean"
#' stn_file <- generate_stn_file(irace_folder, parameters, criteria, significancy = 3, original_type = FALSE, original_elite = FALSE, type_priority = c("START", "STANDARD", "END"))
#' }
#'
#' @export
generate_stn_file <- function(irace_folder, parameters, criteria = "min", significancy = 2, original_elite = FALSE, original_type = FALSE, type_priority = c("START", "STANDARD", "END")) {
  # Auxiliary function to get the priority of the type
  get_type_rank <- function(type, priority) {
    match(type, priority)
  }
  # Auxiliary function to apply selection criteria
  apply_selection <- function(values, criteria) {
    if (length(values) == 0) return(NA)
    switch(criteria,
      "min" = min(values),
      "max" = max(values),
      "mean" = mean(values),
      "median" = median(values),
      "mode" = as.numeric(names(sort(table(values), decreasing = TRUE)[1])),
      stop("Invalid criteria specified"))
  }
  # Check if the input folder exists
  rdata_files <- list.files(irace_folder, pattern = "\\.Rdata$", full.names = TRUE)
  if (length(rdata_files) == 0) stop("Error: No .Rdata files found in the input folder", call. = FALSE)
  message("Processing ", length(rdata_files), " .Rdata files (runs)")
  # Initialize the STN file and other variables
  stn_file <- data.frame()
  location_results <- list() # Store location results (qualities and ELITE status)
  configurations_per_run <- list()
  # --------- First: Collect data for all runs ---------
  # For each run, read the .Rdata file and extract configurations
  for (run_idx in seq_along(rdata_files)) {
    iraceResults <- read_logfile(rdata_files[run_idx])
    elite_ids <- unlist(iraceResults$allElites)
    total_iterations <- length(iraceResults$allElites)
    run_configurations <- list()
    # For each iteration, get the configurations
    for (iteration in 1:total_iterations) {
      configs <- getConfigurationByIteration(iraceResults, iteration, drop.metadata = FALSE)
      config_dict <- list()
      # For each configuration, get the location code and results
      for (config_idx in 1:nrow(configs)) {
        config <- configs[config_idx, ]
        location_code <- get_location_code(config, iraceResults, parameters)
        experiment_results <- iraceResults$experiments[, as.character(config$.ID.)]
        experiment_results <- experiment_results[!is.na(experiment_results)]
        if (iteration == 1) {
          type <- "START"
        } else if (iteration == total_iterations) {
          type <- "END"
        } else {
          type <- "STANDARD"
        }
        if (config$.ID. %in% elite_ids) {
          elite <- "ELITE"
        } else {
          elite <- "REGULAR"
        }
        # Initialize location entry if it does not exist
        if (!location_code %in% names(location_results)) {
          location_results[[location_code]] <- list(
            QUALITIES = experiment_results,
            ELITE = elite,
            TYPE = type
          )
        } else {
          # Append qualities to the location entry
          location_results[[location_code]]$QUALITIES <- c(location_results[[location_code]]$QUALITIES, experiment_results)
          # Update ELITE if necessary
          if (!original_elite) {
            # Update ELITE status if the current elite status is more important than the existing one
            if (elite == "ELITE" && location_results[[location_code]]$ELITE == "REGULAR") {
              location_results[[location_code]]$ELITE <- "ELITE"
            }
          }
          # Update TYPE if if necessary
          if (!original_type) {
            # Update TYPE if the current type is more important than the existing one
            current_type <- location_results[[location_code]]$TYPE
            if (get_type_rank(type, type_priority) > get_type_rank(current_type, type_priority)) {
              location_results[[location_code]]$TYPE <- type
            }
          }
        }
        # if (location_code == "43160038005103500010XXXXXX101" && type == "END") {
        #   print(iteration)
        #   print(config$.ID.)
        #   print(elite)
        #   print(config$.PARENT.)
        # }
        # Store the configuration in the dictionary for this iteration
        config_dict[[as.character(config$.ID.)]] <- list(
          LOCATION_CODE = location_code,
          ELITE = elite,
          TYPE = type,
          PARENT_ID = config$.PARENT.
        )
      }
      run_configurations[[iteration]] <- config_dict
    }
    configurations_per_run[[run_idx]] <- run_configurations
  }
  # --------- Second: compute location qualities and apply significancy ---------
  location_quality <- sapply(names(location_results), function(loc_code) {
    qualities <- location_results[[loc_code]]$QUALITIES
    value <- apply_selection(qualities, criteria)
    value <- round(value, significancy)
    value <- formatC(value, format = "f", digits = significancy)
    return(value)
  })
  # --------- Third: Generate the STN file ---------
  # For each run, iterate through the configurations and generate the STN file
  for (run_idx in seq_along(configurations_per_run)) {
    run_configurations <- configurations_per_run[[run_idx]]
    total_iterations <- length(run_configurations)
    # For each iteration, iterate through the configurations
    for (iteration in 1:total_iterations) {
      current_configs <- run_configurations[[iteration]]
      if (iteration == 1) {
        prev_configs <- NULL
      } else {
        prev_configs <- run_configurations[[iteration - 1]]
      }
      # For each configuration in the current iteration
      for (config_id in names(current_configs)) {
        current <- current_configs[[config_id]]
        if (iteration == 1) {
          # Check if the current configuration is descarted (no children)
          if (current$ELITE == "REGULAR") {
            line <- data.frame(
              Run = run_idx,
              Fitness1 = location_quality[current$LOCATION_CODE],
              Solution1 = current$LOCATION_CODE,
              Elite1 = ifelse(original_elite, current$ELITE, location_results[[current$LOCATION_CODE]]$ELITE),
              Type1 = ifelse(original_type, current$TYPE, location_results[[current$LOCATION_CODE]]$TYPE),
              Iteration1 = 1,
              Fitness2 = location_quality[current$LOCATION_CODE],
              Solution2 = current$LOCATION_CODE,
              Elite2 = ifelse(original_elite, current$ELITE, location_results[[current$LOCATION_CODE]]$ELITE),
              Type2 = ifelse(original_type, current$TYPE, location_results[[current$LOCATION_CODE]]$TYPE),
              Iteration2 = 1
            )
            stn_file <- rbind(stn_file, line)
          }
        } else {
          parent_id <- current$PARENT_ID
          # If the parent is found, connect to it
          if (!is.na(parent_id) && parent_id %in% names(prev_configs)) {
            parent <- prev_configs[[as.character(parent_id)]]
            line <- data.frame(
              Run = run_idx,
              Fitness1 = location_quality[parent$LOCATION_CODE],
              Solution1 = parent$LOCATION_CODE,
              Elite1 = ifelse(original_elite, parent$ELITE, location_results[[parent$LOCATION_CODE]]$ELITE),
              Type1 = ifelse(original_type, parent$TYPE, location_results[[parent$LOCATION_CODE]]$TYPE),
              Iteration1 = iteration - 1,
              Fitness2 = location_quality[current$LOCATION_CODE],
              Solution2 = current$LOCATION_CODE,
              Elite2 = ifelse(original_elite, current$ELITE, location_results[[current$LOCATION_CODE]]$ELITE),
              Type2 = ifelse(original_type, current$TYPE, location_results[[current$LOCATION_CODE]]$TYPE),
              Iteration2 = iteration
            )
            stn_file <- rbind(stn_file, line)
          } else {
            # If the parent is not found and the current configuration is elite, it connects to itself.
            # Because the configuration exists from a much earlier iteration than the current ones.
            if (current$ELITE == "ELITE") {
              line <- data.frame(
                Run = run_idx,
                Fitness1 = location_quality[current$LOCATION_CODE],
                Solution1 = current$LOCATION_CODE,
                Elite1 = ifelse(original_elite, current$ELITE, location_results[[current$LOCATION_CODE]]$ELITE),
                Type1 = ifelse(original_type, current$TYPE, location_results[[current$LOCATION_CODE]]$TYPE),
                Iteration1 = iteration - 1,
                Fitness2 = location_quality[current$LOCATION_CODE],
                Solution2 = current$LOCATION_CODE,
                Elite2 = ifelse(original_elite, current$ELITE, location_results[[current$LOCATION_CODE]]$ELITE),
                Type2 = ifelse(original_type, current$TYPE, location_results[[current$LOCATION_CODE]]$TYPE),
                Iteration2 = iteration
              )
              stn_file <- rbind(stn_file, line)
            }
          }
        }
      }
    }
  }
  return(stn_file)
}

#' Save the STN file to disk
#'
#' This function saves the generated STN file (data frame) as a text file with column names.
#'
#' @param stn_file A data frame containing the STN information.
#' @param output_folder A string specifying the path to the output folder.
#'
#' @return None. The function writes the file to disk.
#'
#' @examples
#' \dontrun{
#' save_file(stn_file, "output/")
#' }
save_file <- function(stn_file, output_folder) {
  # Check if output folder exists, if not, create it
  if (!dir.exists(output_folder)) {
    dir.create(output_folder, recursive = TRUE)
    message("Output folder created: ", output_folder)
  }
  # Define output file path
  stn_file_path <- file.path(output_folder, "stn_file.txt")
  # Write the STN file with column names as the first line
  write.table(stn_file, file = stn_file_path, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
  message("STN file successfully saved in: ", stn_file_path)
}
