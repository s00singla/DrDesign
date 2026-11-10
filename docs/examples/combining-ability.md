# Combining Ability

Estimate effects for a clearly defined parental set

## Question and data
Choose a balanced crosses-only line × tester trial, or Griffing Method II with parents and one F1 per nonreciprocal cross in every replicate. Parent identifiers and replication are required.

## Read and report the results
Report fixed GCA and SCA effects, residual-model SEs, confidence intervals and Holm-adjusted effect tests. The diallel implementation derives uncertainty from residual covariance rather than the package's replication-MS standard-error field.

## Scope and assumptions
The effects describe the tested parents. They are not estimates of additive and dominance variance in a randomly sampled population. Reciprocal effects, other Griffing methods and multi-environment combining ability are outside this implementation.

## Setup
```r
source("tools/example-cases.R")
load_drdesign()
```

## line-tester

[Example CSV](../data/line-tester.csv) · [R script](../code/line-tester.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- research_example("combining-ability")
result <- run_combining_ability(data)
```

### Results ANOVA

[Full-precision CSV](../data/line-tester-table-1.csv)

| Source / term | df | SS | MS | F | p-value |
| --- | --- | --- | --- | --- | --- |
| Rep | 2 | 8.320 | 4.160 | 12.308 | <0.001 |
| Parent1 | 2 | 72.840 | 36.420 | 107.755 | <0.001 |
| Parent2 | 2 | 19.444 | 9.722 | 28.765 | <0.001 |
| Parent1:Parent2 | 4 | 2.36e-04 | 5.90e-05 | 1.75e-04 | 1.000 |
| Residuals | 16 | 5.408 | 0.338 | NA | NA |

### Results AdjustedMeans

[Full-precision CSV](../data/line-tester-table-2.csv)

| Parent1 | Parent2 | Estimated mean | SE | df | CI lower | CI upper |
| --- | --- | --- | --- | --- | --- | --- |
| L1 | T1 | 22.958 | 0.336 | 16 | 22.246 | 23.669 |
| L2 | T1 | 24.970 | 0.336 | 16 | 24.258 | 25.681 |
| L3 | T1 | 26.984 | 0.336 | 16 | 26.272 | 27.695 |
| L1 | T2 | 24.000 | 0.336 | 16 | 23.288 | 24.711 |
| L2 | T2 | 26.015 | 0.336 | 16 | 25.304 | 26.727 |
| L3 | T2 | 28.030 | 0.336 | 16 | 27.318 | 28.741 |
| L1 | T3 | 25.042 | 0.336 | 16 | 24.330 | 25.753 |
| L2 | T3 | 27.050 | 0.336 | 16 | 26.339 | 27.762 |
| L3 | T3 | 29.055 | 0.336 | 16 | 28.344 | 29.767 |

Results are averaged over the levels of: Rep

Confidence level used: 0.95

### Results Effects

[Full-precision CSV](../data/line-tester-table-3.csv)

| contrast | estimate | SE | df | CI lower | CI upper | t | p-value | p-value (Holm) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Line GCA L1 | -2.012 | 0.158 | 16 | -2.347 | -1.676 | -12.714 | <0.001 | <0.001 |
| Line GCA L2 | 3.11e-04 | 0.158 | 16 | -0.335 | 0.336 | 0.002 | 0.998 | 1.000 |
| Line GCA L3 | 2.011 | 0.158 | 16 | 1.676 | 2.347 | 12.713 | <0.001 | <0.001 |
| Tester GCA T1 | -1.041 | 0.158 | 16 | -1.376 | -0.706 | -6.579 | <0.001 | <0.001 |
| Tester GCA T2 | 0.003 | 0.158 | 16 | -0.332 | 0.339 | 0.021 | 0.983 | 1.000 |
| Tester GCA T3 | 1.038 | 0.158 | 16 | 0.702 | 1.373 | 6.558 | <0.001 | <0.001 |
| SCA L1 T1 | -0.001 | 0.224 | 16 | -0.475 | 0.473 | -0.004 | 0.997 | 1.000 |
| SCA L2 T1 | -0.001 | 0.224 | 16 | -0.475 | 0.473 | -0.005 | 0.996 | 1.000 |
| SCA L3 T1 | 0.002 | 0.224 | 16 | -0.472 | 0.476 | 0.009 | 0.993 | 1.000 |
| SCA L1 T2 | -0.003 | 0.224 | 16 | -0.478 | 0.471 | -0.015 | 0.988 | 1.000 |

First 10 rows shown. Download the CSV for every row.

Results are averaged over the levels of: Rep

Confidence level used: 0.95

### Exclusions

[Full-precision CSV](../data/line-tester-table-4.csv)

No rows to report.

### Reviewed data

[Full-precision CSV](../data/line-tester-table-5.csv)

| Rep | Parent1 | Parent2 | Value |
| --- | --- | --- | --- |
| R1 | L1 | T1 | 23.909 |
| R2 | L1 | T1 | 22.243 |
| R3 | L1 | T1 | 22.721 |
| R1 | L2 | T1 | 25.989 |
| R2 | L2 | T1 | 24.456 |
| R3 | L2 | T1 | 24.463 |
| R1 | L3 | T1 | 27.991 |
| R2 | L3 | T1 | 26.712 |
| R3 | L3 | T1 | 26.249 |
| R1 | L1 | T2 | 24.913 |

First 10 rows shown. Download the CSV for every row.

### Software versions

[Full-precision CSV](../data/line-tester-table-6.csv)

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

[Full-precision CSV](../data/line-tester-table-7.csv)

| Setting | Value |
| --- | --- |
| Method | line-tester |
| Model | Fixed parental effects; balanced single environment |
| Alpha | 0.05 |

### Diagnostics and model notes

- Fixed parental set: inference concerns the tested parents. GCA/SCA effects do not by themselves establish additive/dominance variance in a wider population.

## diallel

[Example CSV](../data/diallel.csv) · [R script](../code/diallel.R)

Synthetic teaching data; not observations from a field experiment.

```r
pairs <- which(upper.tri(matrix(0,4,4),diag=TRUE),arr.ind=TRUE)
data <- do.call(rbind,lapply(1:3,function(r)data.frame(Rep=paste0("R",r),Parent1=paste0("P",pairs[,1]),Parent2=paste0("P",pairs[,2]),Value=20+pairs[,1]+pairs[,2]+sin(seq_len(nrow(pairs))*r))))
result <- run_combining_ability(data,method="diallel")
```

### Results ANOVA

[Full-precision CSV](../data/diallel-table-1.csv)

| Source / term | df | SS | MS | F | p-value |
| --- | --- | --- | --- | --- | --- |
| gca | 3 | 25.702 | 8.567 | 43.489 | <0.001 |
| sca | 6 | 0.627 | 0.104 | 0.530 | 0.778 |
| Error | 18 | 3.546 | 0.197 | NA | NA |

### Results AdjustedMeans

[Full-precision CSV](../data/diallel-table-2.csv)

| Cross | Estimated mean | SE | df | CI lower | CI upper |
| --- | --- | --- | --- | --- | --- |
| 1:1 | 22.631 | 0.444 | 18 | 21.698 | 23.563 |
| 1:2 | 22.958 | 0.444 | 18 | 22.025 | 23.890 |
| 1:3 | 23.899 | 0.444 | 18 | 22.966 | 24.831 |
| 1:4 | 25.828 | 0.444 | 18 | 24.896 | 26.761 |
| 2:2 | 24.091 | 0.444 | 18 | 23.159 | 25.024 |
| 2:3 | 24.716 | 0.444 | 18 | 23.783 | 25.648 |
| 2:4 | 25.932 | 0.444 | 18 | 24.999 | 26.864 |
| 3:3 | 25.478 | 0.444 | 18 | 24.545 | 26.410 |
| 3:4 | 27.206 | 0.444 | 18 | 26.273 | 28.138 |
| 4:4 | 27.794 | 0.444 | 18 | 26.861 | 28.726 |

Results are averaged over the levels of: Rep

Confidence level used: 0.95

### Results Effects

[Full-precision CSV](../data/diallel-table-3.csv)

| contrast | estimate | SE | df | CI lower | CI upper | t | p-value | p-value (Holm) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GCA P1 | -1.220 | 0.157 | 18 | -1.550 | -0.890 | -7.774 | <0.001 | <0.001 |
| GCA P2 | -0.580 | 0.157 | 18 | -0.909 | -0.250 | -3.694 | 0.002 | 0.020 |
| GCA P3 | 0.252 | 0.157 | 18 | -0.078 | 0.581 | 1.604 | 0.126 | 1.000 |
| GCA P4 | 1.548 | 0.157 | 18 | 1.218 | 1.878 | 9.864 | <0.001 | <0.001 |
| SCA P1 P1 | 0.017 | 0.281 | 18 | -0.572 | 0.607 | 0.062 | 0.951 | 1.000 |
| SCA P1 P2 | -0.296 | 0.380 | 18 | -1.094 | 0.503 | -0.778 | 0.446 | 1.000 |
| SCA P1 P3 | -0.186 | 0.380 | 18 | -0.985 | 0.612 | -0.490 | 0.630 | 1.000 |
| SCA P1 P4 | 0.447 | 0.380 | 18 | -0.352 | 1.246 | 1.176 | 0.255 | 1.000 |
| SCA P2 P2 | 0.197 | 0.281 | 18 | -0.392 | 0.787 | 0.703 | 0.491 | 1.000 |
| SCA P2 P3 | -0.009 | 0.380 | 18 | -0.808 | 0.789 | -0.025 | 0.981 | 1.000 |

First 10 rows shown. Download the CSV for every row.

Results are averaged over the levels of: Rep

Confidence level used: 0.95

### Results TrialANOVA

[Full-precision CSV](../data/diallel-table-4.csv)

| Source / term | df | SS | MS | F | p-value |
| --- | --- | --- | --- | --- | --- |
| Rep | 2 | 0.178 | 0.089 | 0.150 | 0.861 |
| Cross | 9 | 78.986 | 8.776 | 14.850 | <0.001 |
| Residuals | 18 | 10.638 | 0.591 | NA | NA |

### Exclusions

[Full-precision CSV](../data/diallel-table-5.csv)

No rows to report.

### Reviewed data

[Full-precision CSV](../data/diallel-table-6.csv)

| Rep | Parent1 | Parent2 | Value |
| --- | --- | --- | --- |
| R1 | P1 | P1 | 22.841 |
| R1 | P1 | P2 | 23.909 |
| R1 | P2 | P2 | 24.141 |
| R1 | P1 | P3 | 23.243 |
| R1 | P2 | P3 | 24.041 |
| R1 | P3 | P3 | 25.721 |
| R1 | P1 | P4 | 25.657 |
| R1 | P2 | P4 | 26.989 |
| R1 | P3 | P4 | 27.412 |
| R1 | P4 | P4 | 27.456 |

First 10 rows shown. Download the CSV for every row.

### Software versions

[Full-precision CSV](../data/diallel-table-7.csv)

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

[Full-precision CSV](../data/diallel-table-8.csv)

| Setting | Value |
| --- | --- |
| Method | diallel |
| Model | Fixed parental effects; balanced single environment |
| Alpha | 0.05 |

### Diagnostics and model notes

- Fixed parental set: inference concerns the tested parents. GCA/SCA effects do not by themselves establish additive/dominance variance in a wider population.

## Reporting conventions
Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.

[Validation and limitations](../VALIDATION.md)
