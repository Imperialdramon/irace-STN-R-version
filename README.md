# irace-STN-i – STN-i File Generator for Single Algorithms

## Overview

**irace-STN-i** is a tool designed to generate STN-i files from multiple independent runs of the [irace](https://github.com/MLopez-Ibanez/irace) configurator. It consolidates configuration data across iterations — considering fitness values, elite status, and encoded parameter-based locations — to build a trajectory-based output in the STN-i format. This output enables structural and behavioral analysis of the search process of a given algorithm.

This tool requires a modified version of irace that stores `raceData`, available at:  
[https://github.com/Imperialdramon/irace-with-raceData](https://github.com/Imperialdramon/irace-with-raceData)

---

## Requirements

- R version ≥ 4.0  
- irace version ≥ 4.2 (custom version with raceData support)

---

## Project Structure

```
irace-STN-i/
├── R/
│   ├── main.R           # Entry point script (uses --param=value arguments)
│   ├── functions.R      # Utility functions for reading, processing, and saving
│
├── Experiments/
│   ├── AlgorithmName/
│   │   ├── ScenarioName/
│   │   │   ├── Data/           # Contains irace output files (.RData)
│   │   │   ├── Result/         # Output folder for the STN-i result
│   ├── Parameters/             # CSV file with parameter values and location encodings
```

---

## How to Execute

```bash
Rscript R/main.R \
  --input=<irace_folder> \
  --parameters=<parameters_file> \
  --output=<output_folder> \
  [--criteria=mean] \
  [--significance=2] \
  [--output_file=custom_name.txt]
```

### Required Arguments

| Argument         | Description                                                                                   | Default         |
|------------------|-----------------------------------------------------------------------------------------------|------------------|
| `--input`        | Folder containing `.RData` output files from irace                                            | —                |
| `--parameters`   | Path to CSV file with parameter definitions and location encodings                            | —                |
| `--output`       | Folder to store the resulting STN-i file                                                      | —                |
| `--criteria`     | Aggregation method for configuration quality: `min`, `max`, `mean`, `median`, `mode`         | `min`            |
| `--significance` | Number of decimal places to round fitness values                                              | `2`              |
| `--output_file`  | Output file name for the STN-i file (e.g., `STN-i-L0.txt`)                                    | `stn_i_file.txt`   |

---

### Type Priority Policy

Type precedence follows:  
`STANDARD` < `START` < `END`  
Locations with multiple candidates inherit the highest type priority.

---

## Parameters File Format (`parameters.csv`)

| NAME      | CONDITIONAL | TYPE | VALUES_ARRAY              | LOCATIONS_ARRAY                         |
|-----------|-------------|------|---------------------------|------------------------------------------|
| algorithm | FALSE       | c    | (as,mmas,eas,ras,acs)     | (as:0,mmas:1,eas:2,ras:3,acs:4)          |
| ants      | FALSE       | i    | (5,100)                   | (10,2)                                   |
| alpha     | FALSE       | r    | (0.00,5.00)               | (0.1,2)                                  |

### Types:
- `c`: Categorical
- `o`: Ordinal
- `i`: Integer
- `r`: Real

### Interpretation:
- **VALUES_ARRAY**:
  - For `c`, `o`: list of possible values
  - For `i`, `r`: (min, max) numeric range
- **LOCATIONS_ARRAY**:
  - For `c`, `o`: mapping from value to location code
  - For `i`, `r`: `(step, significance)` for discretization

---

## Output File Format (`stn_file.txt`)

Tab-separated columns:

```
Run | Path | Fitness1 | Solution1 | Elite1 | Original_Elite1 | Type1 | Original_Type1 | Iteration1 | Fitness2 | Solution2 | Elite2 | Original_Elite2 | Type2 | Original_Type2 | Iteration2
```

Example:

```
1	TRUE	12.34	0123X	ELITE	ELITE	START	START	1	15.67	0124X	REGULAR	REGULAR	END	STANDARD	2
```

### Column descriptions:
- `Run`: Sequential run ID
- `Path`: Whether to include the arc (TRUE/FALSE)
- `Fitness1 / Fitness2`: Aggregated fitness value per location
- `Solution1 / Solution2`: Encoded parameter-based location
- `Elite1 / Elite2`: Derived elite status at location level
- `Original_Elite1 / 2`: Original configuration elite status
- `Type1 / Type2`: Inferred location type from all contained configurations
- `Original_Type1 / 2`: Original configuration type

---

## Example Execution

```bash
Rscript R/main.R \
  --input=Experiments/ACOTSP/E1-BL-N/Data \
  --parameters=Experiments/ACOTSP/Parameters/L0.csv \
  --output=Experiments/ACOTSP/E1-BL-N/Result \
  --criteria=mean \
  --significance=2 \
  --output_file=STN-i-L0.txt
```

---

## Notes

- Input and output paths may be relative or absolute.
- The script checks for existence of required files and directories.
- Configurations with no children that belong to the first iteration will be self-connected in the STN-i file.
