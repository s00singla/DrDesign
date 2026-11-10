# Data Preparation & Trial Validation

Start with the experimental unit

## Question and data
A row should represent a recorded experimental unit. Choose the trait columns and the identifiers that together identify that unit. Replication-wide tables can be converted to long format.

## Read and report the results
Inspect the validation summary and repeated-identifier table before fitting a model. Repeated identifiers may be subsamples, not additional independent replications. The exclusion ledger is part of the analysis record.

## Scope and assumptions
Review omissions explicitly. This tool does not decide whether an outlier is erroneous and does not impute missing observations.

## Setup
```r
source("tools/example-cases.R")
load_drdesign()
```

## data-preparation

[Example CSV](../data/data-preparation.csv) · [R script](../code/data-preparation.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- research_example("data-preparation")
result <- run_data_preparation(data,c("Yield","Height"),c("Genotype","Rep"))
```

### Validation summary

[Full-precision CSV](../data/data-preparation-table-1.csv)

| Check | Count |
| --- | --- |
| Input observations | 36 |
| Retained observations | 36 |
| Excluded observations | 0 |
| Rows sharing identifiers | 0 |

### Repeated identifiers

[Full-precision CSV](../data/data-preparation-table-2.csv)

No rows to report.

### Design counts

[Full-precision CSV](../data/data-preparation-table-3.csv)

| Genotype | Rep | Freq |
| --- | --- | --- |
| G01 | R1 | 1.000 |
| G02 | R1 | 1.000 |
| G03 | R1 | 1.000 |
| G04 | R1 | 1.000 |
| G05 | R1 | 1.000 |
| G06 | R1 | 1.000 |
| G07 | R1 | 1.000 |
| G08 | R1 | 1.000 |
| G09 | R1 | 1.000 |
| G10 | R1 | 1.000 |

First 10 rows shown. Download the CSV for every row.

### Exclusions

[Full-precision CSV](../data/data-preparation-table-4.csv)

No rows to report.

### Reviewed data

[Full-precision CSV](../data/data-preparation-table-5.csv)

| Genotype | Rep | Yield | Height | Maturity |
| --- | --- | --- | --- | --- |
| G01 | R1 | 22.691 | 50.556 | 102.324 |
| G02 | R1 | 20.013 | 47.566 | 102.328 |
| G03 | R1 | 23.957 | 55.490 | 99.823 |
| G04 | R1 | 24.046 | 59.147 | 96.930 |
| G05 | R1 | 22.649 | 52.990 | 96.123 |
| G06 | R1 | 27.087 | 53.629 | 97.962 |
| G07 | R1 | 25.236 | 62.330 | 100.571 |
| G08 | R1 | 25.931 | 62.159 | 101.368 |
| G09 | R1 | 29.522 | 56.210 | 99.436 |
| G10 | R1 | 26.708 | 60.624 | 96.368 |

First 10 rows shown. Download the CSV for every row.

### Software versions

[Full-precision CSV](../data/data-preparation-table-6.csv)

| Source / term | Package | Version |
| --- | --- | --- |
|  | R | 4.5.3 |
| shiny | shiny | 1.13.0 |
| agricolae | agricolae | 1.3.7 |
| metan | metan | 1.19.0 |
| lme4 | lme4 | 2.0.1 |
| emmeans | emmeans | 2.0.2 |
| SpATS | SpATS | 1.0.20 |
| DiallelAnalysisR | DiallelAnalysisR | 0.6.0 |

### Analysis settings

[Full-precision CSV](../data/data-preparation-table-7.csv)

| Setting | Value |
| --- | --- |
| Traits | Yield, Height |
| Identifiers | Genotype, Rep |
| Wide_conversion | FALSE |

## wide-to-long

[Example CSV](../data/wide-to-long.csv) · [R script](../code/wide-to-long.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- read_pasted_table(default_data$RBD)
result <- run_data_preparation(data,c("Rep1","Rep2","Rep3"),"trt",wide=TRUE)
```

### Validation summary

[Full-precision CSV](../data/wide-to-long-table-1.csv)

| Check | Count |
| --- | --- |
| Input observations | 12 |
| Retained observations | 12 |
| Excluded observations | 0 |
| Rows sharing identifiers | 0 |

### Repeated identifiers

[Full-precision CSV](../data/wide-to-long-table-2.csv)

No rows to report.

### Design counts

[Full-precision CSV](../data/wide-to-long-table-3.csv)

| trt | Replication | Freq |
| --- | --- | --- |
| T1 | Rep1 | 1.000 |
| T2 | Rep1 | 1.000 |
| T3 | Rep1 | 1.000 |
| T4 | Rep1 | 1.000 |
| T1 | Rep2 | 1.000 |
| T2 | Rep2 | 1.000 |
| T3 | Rep2 | 1.000 |
| T4 | Rep2 | 1.000 |
| T1 | Rep3 | 1.000 |
| T2 | Rep3 | 1.000 |

First 10 rows shown. Download the CSV for every row.

### Exclusions

[Full-precision CSV](../data/wide-to-long-table-4.csv)

No rows to report.

### Reviewed data

[Full-precision CSV](../data/wide-to-long-table-5.csv)

| trt | Replication | Response |
| --- | --- | --- |
| T1 | Rep1 | 25.400 |
| T1 | Rep2 | 26.100 |
| T1 | Rep3 | 24.800 |
| T2 | Rep1 | 28.200 |
| T2 | Rep2 | 27.500 |
| T2 | Rep3 | 29.100 |
| T3 | Rep1 | 21.000 |
| T3 | Rep2 | 22.400 |
| T3 | Rep3 | 20.800 |
| T4 | Rep1 | 30.500 |

First 10 rows shown. Download the CSV for every row.

### Software versions

[Full-precision CSV](../data/wide-to-long-table-6.csv)

| Source / term | Package | Version |
| --- | --- | --- |
|  | R | 4.5.3 |
| shiny | shiny | 1.13.0 |
| agricolae | agricolae | 1.3.7 |
| metan | metan | 1.19.0 |
| lme4 | lme4 | 2.0.1 |
| emmeans | emmeans | 2.0.2 |
| SpATS | SpATS | 1.0.20 |
| DiallelAnalysisR | DiallelAnalysisR | 0.6.0 |

### Analysis settings

[Full-precision CSV](../data/wide-to-long-table-7.csv)

| Setting | Value |
| --- | --- |
| Traits | Response |
| Identifiers | trt, Replication |
| Wide_conversion | TRUE |

## Reporting conventions
Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.

[Validation and limitations](../VALIDATION.md)
