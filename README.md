# Irace Caster – STN File Generator for Single Algorithms

## Description

This project allows the processing of multiple independent irace runs (`.Rdata` files) and generates a consolidated output file in the STN (Search Trajectory Network) format. The process considers the configurations by iteration, their quality evaluated through the executions, the location code associated with each configuration, and whether it was part of the elite set in each iteration.

The goal is to compile all runs into a single structured network file (STN), which can later be used for analyzing the behavior of the algorithm and its search trajectory.

---

## Requirements

- R version ≥ 4.0
- irace version ≥ 4.2

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

Rscript R/main.R <irace_folder> <parameters_file> <output_folder> [criteria] [significancy] [original_elite] [original_type] [type_permutation_value]

### Required Arguments:

| Argument               | Description                                                                                  | Default       |
|------------------------|----------------------------------------------------------------------------------------------|---------------|
| `irace_folder`         | Folder containing the irace output files (`.Rdata`).                                         | —             |
| `parameters_file`      | CSV file defining the parameter configurations.                                              | —             |
| `output_folder`        | Folder where the output STN file will be generated.                                          | —             |
| `criteria`             | Selection method for configuration quality (`min`, `max`, `mean`, `median`, `mode`).         | `min`         |
| `significancy`         | Number of decimal places for rounding the quality values.                                    | 2             |
| `original_elite`       | Whether to use the original elite status for nodes (`TRUE` or `FALSE`).                      | `FALSE`       |
| `original_type`        | Whether to use the original type for nodes (`TRUE` or `FALSE`).                              | `FALSE`       |
| `type_permutation_value` | Integer index selecting the priority order for types when `original_type = FALSE`.         | 1             |

---

### Type Priority Permutations

The `type_permutation_value` corresponds to one of the following priority orders used to decide the relative importance of node types when combining results. This affects how locations inherit the "best" type from their nodes.

| Index | Type Priority Order                      |
|-------|-----------------------------------------|
| 1     | `c("START", "STANDARD", "END")`         |
| 2     | `c("START", "END", "STANDARD")`         |
| 3     | `c("STANDARD", "START", "END")`         |
| 4     | `c("STANDARD", "END", "START")`         |
| 5     | `c("END", "START", "STANDARD")`         |
| 6     | `c("END", "STANDARD", "START")`         |

For example, if `type_permutation_value = 3`, the priority order is: `"STANDARD"` < `"START"` < `"END"`.

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

Run | Fitness1 | Solution1 | Elite1  | Type1  | Fitness2 | Solution2 | Elite2   | Type2
----|----------|-----------|---------|--------|----------|-----------|----------|--------
1   | 12.34    | 0123X     | ELITE   | START  | 15.67    | 0124X     | REGULAR  | STANDARD

Where:
- **RUN**: Run identifier (sequential number of the input file).
- **Fitness1** / **Fitness2**: Quality values of the configuration, selected according to the chosen criteria.
- **Solution1** / **Solution2**: Generated location codes based on the configuration parameters.
- **Elite1** / **Elite2**:  
  A location is marked as `ELITE` if at least one configuration within it is elite; otherwise, it is marked as `REGULAR`.   If the `original_elite` option is enabled (`TRUE`), the elite status will be assigned based on each configuration’s original (individual) elite value, rather than using the aggregated rule at the location level.
- **Type1** / **Type2**: Reflects the relative position in the trajectory, where types follow the order: `START` < `END` < `STANDARD`.  
  A location inherits the best (i.e., highest) type among all its nodes. For example, if any node in the location has type `END`, the location will be assigned `END`. If the `original_type` option is enabled (`TRUE`), the type will correspond to each configuration’s own trajectory type, instead of being aggregated at the location level.

---

## Example Execution

Rscript R/main.R Tests/ACOTSP-N/Data Tests/parameters.csv Tests/ACOTSP-N/Results mean 2 FALSE FALSE 1

This command will process the irace runs, calculate the location qualities using the mean, and round the values to 2 decimal places, using the first permutation of types to priorize the updates of locations.

---

## Notes

- Input paths can be relative or absolute.
- The script automatically verifies the existence of the input folder, parameters file, and output folder.
- If a configuration does not have children in the next iteration but belongs to the first iteration, it connects to itself in the STN network.
