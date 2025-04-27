# Irace Caster – STN File Generator for Single Algorithms

## Description

This project allows the processing of multiple independent irace runs (`.Rdata` files) and generates a consolidated output file in the STN (Search Trajectory Network) format. The process considers the configurations by iteration, their quality evaluated through the executions, the location code associated with each configuration, and whether it was part of the elite set in each iteration.

The goal is to compile all runs into a single structured network file (STN), which can later be used for analyzing the behavior of the algorithm and its search trajectory.

---

## Requirements

- R version ≥ 4.0
- irace version ≥ 4.2
- Optional: package `here` (not required by default)

---

## Project Structure

/Tesis/irace-STN-R-version/
├── R/
│   ├── main.R           # Main execution script
│   ├── functions.R      # Functions for reading, processing, and saving
├── Tests/               # Example test files
│   ├── parameters.csv   # Parameter definition file
│   ├── irace-files/     # Directory with irace output files (.Rdata)

---

## How to Execute

From the project root, using Rscript:

Rscript R/main.R <irace_folder> <parameters_file> <output_folder> [criteria] [significancy]

### Required Arguments:
1) irace_folder: Folder containing the irace output files (`.Rdata`).
2) parameters_file: CSV file defining the parameter configuration.
3) output_folder: Folder where the output STN file will be generated.
4) (Optional) criteria: Selection method for configuration quality (`min`, `max`, `mean`, `median`, `mode`). Default: `min`.
5) (Optional) significancy: Number of decimal places for rounding the quality values. Default: 2.

---

## Parameters File Format (`parameters.csv`)

NAME        | CONDITIONAL | TYPE | VALUES_ARRAY         | LOCATIONS_ARRAY
------------|-------------|------|-----------------------|-------------------------------
algorithm   | FALSE       | c    | (as,mmas,eas,ras,acs) | (as:0,mmas:1,eas:2,ras:3,acs:4)
ants        | FALSE       | i    | (5,100)               | (10,2)
alpha       | FALSE       | r    | (0.00,5.00)           | (0.1,2)

### Parameter Types:
- c: Categorical
- o: Ordinal
- i: Integer
- r: Real

### VALUES_ARRAY interpretation:
- For `c` and `o`: VALUES_ARRAY is a list of possible parameter values (e.g., `(as, mmas, eas, ras, acs)`).
- For `i` and `r`: VALUES_ARRAY defines the minimum and maximum range of the parameter (e.g., `(5,100)` for integers between 5 and 100).

### LOCATIONS_ARRAY interpretation:
- For `c` and `o`: LOCATIONS_ARRAY is a dictionary that maps each parameter value to a numeric location code (e.g., `as:0, mmas:1, eas:2, ras:3, acs:4`).
- For `i` and `r`: LOCATIONS_ARRAY defines `(step, significance)`, where:
  - step: the subrange step size for dividing the parameter domain.
  - significance: the number of decimals considered for scaling and encoding.

---

## Output File Format (`stn_file.txt`)

The output file is a tab-delimited (`\t`) text file with the following columns:

RUN | VALUE1 | LOCATION1 | ELITE1 | TYPE1  | VALUE2 | LOCATION2 | ELITE2 | TYPE2
----|--------|-----------|--------|--------|--------|-----------|--------|--------
1   | 12.34  | 0123X     | TRUE   | START  | 15.67  | 0124X     | FALSE  | MIDDLE

Where:
- RUN: Run identifier (sequential number of the input file).
- VALUE1 / VALUE2: Quality values of the configuration, selected according to the chosen criteria.
- LOCATION1 / LOCATION2: Generated location codes based on the configuration parameters.
- ELITE1 / ELITE2: TRUE if at least one configuration in that location was elite; FALSE otherwise.
- TYPE1 / TYPE2: Indicates the position in the trajectory (`START`, `MIDDLE`, or `END`).

---

## Example Execution

Rscript R/main.R Tests/irace-files/ACOTSP-N/Data Tests/parameters.csv Tests/irace-files/ACOTSP-N/Results mean 2

This command will process the irace runs, calculate the location qualities using the mean, and round the values to 2 decimal places.

---

## Notes

- Input paths can be relative or absolute.
- The script automatically verifies the existence of the input folder, parameters file, and output folder.
- If a configuration does not have children in the next iteration but belongs to the first iteration, it connects to itself in the STN network.