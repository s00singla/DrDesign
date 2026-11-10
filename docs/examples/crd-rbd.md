# CRD / RBD

Compare treatments using the experimental error

## Question and data
Enter one row per treatment and one column per replication. Use CRD for unrestricted randomization or RBD for complete blocks. Treatment identifiers must be unique.

## Read and report the results
Report the design, treatment and error df, SS, MS, F and p-value. Treatment means have model-based SE and t confidence limits. State LSD, Duncan or Tukey explicitly; LSD and Duncan do not provide the same familywise protection as Tukey.

## Scope and assumptions
Shared letters indicate that the comparison did not reject a difference; they do not prove equivalence. An insignificant omnibus test does not establish equality. No automatic model-based outlier deletion occurs.

## Setup
```r
source("tools/example-cases.R")
load_drdesign()
```

## CRD-LSD

[Example CSV](../data/CRD-LSD.csv) · [R script](../code/CRD-LSD.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- read_pasted_table(default_data[["CRD"]])
result <- run_design_analysis(data, "CRD", comparison_method="LSD")
```

### dataset

[Full-precision CSV](../data/CRD-LSD-table-1.csv)

| Treatment | Rep | Value |
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

### anova

[Full-precision CSV](../data/CRD-LSD-table-2.csv)

| df | SS | MS | F | p-value | Source / term |
| --- | --- | --- | --- | --- | --- |
| 3 | 148.009 | 49.336 | 101.203 | <0.001 | Trt |
| 8 | 3.900 | 0.487 | NA | NA | Residuals |

### stats

[Full-precision CSV](../data/CRD-LSD-table-3.csv)

| Statistic | Value |
| --- | --- |
| Replications detected | 3.000 |
| Grand Mean | 26.492 |
| Mean Square Error (MSE) | 0.487 |
| Standard Error of Mean - SE(m) | 0.403 |
| Standard Error of Difference - SE(d) | 0.570 |
| Coefficient of Variation - CV (%) | 2.636 |

### means

[Full-precision CSV](../data/CRD-LSD-table-4.csv)

| Treatment | Value | std | r | se | LCL | UCL | Min | Max | Q25 | Q50 | Q75 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3.000 | 0.403 | 24.504 | 26.363 | 24.800 | 26.100 | 25.100 | 25.400 | 25.750 |
| T2 | 28.267 | 0.802 | 3.000 | 0.403 | 27.337 | 29.196 | 27.500 | 29.100 | 27.850 | 28.200 | 28.650 |
| T3 | 21.400 | 0.872 | 3.000 | 0.403 | 20.470 | 22.330 | 20.800 | 22.400 | 20.900 | 21.000 | 21.700 |
| T4 | 30.867 | 0.351 | 3.000 | 0.403 | 29.937 | 31.796 | 30.500 | 31.200 | 30.700 | 30.900 | 31.050 |

### groups

[Full-precision CSV](../data/CRD-LSD-table-5.csv)

| Treatment | Value | Group |
| --- | --- | --- |
| T4 | 30.867 | a |
| T2 | 28.267 | b |
| T1 | 25.433 | c |
| T3 | 21.400 | d |

### lsd_stats

[Full-precision CSV](../data/CRD-LSD-table-6.csv)

| Source / term | Metric | Value |
| --- | --- | --- |
| MSerror | MSerror | 0.487 |
| Df | Df | 8.000 |
| Mean | Mean | 26.492 |
| CV | CV | 2.636 |
| t.value | t value | 2.306 |
| LSD | LSD | 1.315 |

### treatment_summary

[Full-precision CSV](../data/CRD-LSD-table-7.csv)

| Treatment | Mean | SD | N | SE | CI lower | CI upper | df |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3 | 0.403 | 24.504 | 26.363 | 8 |
| T2 | 28.267 | 0.802 | 3 | 0.403 | 27.337 | 29.196 | 8 |
| T3 | 21.400 | 0.872 | 3 | 0.403 | 20.470 | 22.330 | 8 |
| T4 | 30.867 | 0.351 | 3 | 0.403 | 29.937 | 31.796 | 8 |

### Diagnostics and model notes

- Model: CRD at alpha 0.05 using LSD comparisons

## CRD-DMRT

[Example CSV](../data/CRD-DMRT.csv) · [R script](../code/CRD-DMRT.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- read_pasted_table(default_data[["CRD"]])
result <- run_design_analysis(data, "CRD", comparison_method="DMRT")
```

### dataset

[Full-precision CSV](../data/CRD-DMRT-table-1.csv)

| Treatment | Rep | Value |
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

### anova

[Full-precision CSV](../data/CRD-DMRT-table-2.csv)

| df | SS | MS | F | p-value | Source / term |
| --- | --- | --- | --- | --- | --- |
| 3 | 148.009 | 49.336 | 101.203 | <0.001 | Trt |
| 8 | 3.900 | 0.487 | NA | NA | Residuals |

### stats

[Full-precision CSV](../data/CRD-DMRT-table-3.csv)

| Statistic | Value |
| --- | --- |
| Replications detected | 3.000 |
| Grand Mean | 26.492 |
| Mean Square Error (MSE) | 0.487 |
| Standard Error of Mean - SE(m) | 0.403 |
| Standard Error of Difference - SE(d) | 0.570 |
| Coefficient of Variation - CV (%) | 2.636 |

### means

[Full-precision CSV](../data/CRD-DMRT-table-4.csv)

| Treatment | Value | std | r | se | Min | Max | Q25 | Q50 | Q75 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3.000 | 0.403 | 24.800 | 26.100 | 25.100 | 25.400 | 25.750 |
| T2 | 28.267 | 0.802 | 3.000 | 0.403 | 27.500 | 29.100 | 27.850 | 28.200 | 28.650 |
| T3 | 21.400 | 0.872 | 3.000 | 0.403 | 20.800 | 22.400 | 20.900 | 21.000 | 21.700 |
| T4 | 30.867 | 0.351 | 3.000 | 0.403 | 30.500 | 31.200 | 30.700 | 30.900 | 31.050 |

### groups

[Full-precision CSV](../data/CRD-DMRT-table-5.csv)

| Treatment | Value | Group |
| --- | --- | --- |
| T4 | 30.867 | a |
| T2 | 28.267 | b |
| T1 | 25.433 | c |
| T3 | 21.400 | d |

### lsd_stats

[Full-precision CSV](../data/CRD-DMRT-table-6.csv)

| Metric | Value |
| --- | --- |
| MSerror | 0.487 |
| Df | 8.000 |
| Mean | 26.492 |
| CV | 2.636 |

### treatment_summary

[Full-precision CSV](../data/CRD-DMRT-table-7.csv)

| Treatment | Mean | SD | N | SE | CI lower | CI upper | df |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3 | 0.403 | 24.504 | 26.363 | 8 |
| T2 | 28.267 | 0.802 | 3 | 0.403 | 27.337 | 29.196 | 8 |
| T3 | 21.400 | 0.872 | 3 | 0.403 | 20.470 | 22.330 | 8 |
| T4 | 30.867 | 0.351 | 3 | 0.403 | 29.937 | 31.796 | 8 |

### Diagnostics and model notes

- Model: CRD at alpha 0.05 using DMRT comparisons

## CRD-Tukey

[Example CSV](../data/CRD-Tukey.csv) · [R script](../code/CRD-Tukey.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- read_pasted_table(default_data[["CRD"]])
result <- run_design_analysis(data, "CRD", comparison_method="Tukey")
```

### dataset

[Full-precision CSV](../data/CRD-Tukey-table-1.csv)

| Treatment | Rep | Value |
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

### anova

[Full-precision CSV](../data/CRD-Tukey-table-2.csv)

| df | SS | MS | F | p-value | Source / term |
| --- | --- | --- | --- | --- | --- |
| 3 | 148.009 | 49.336 | 101.203 | <0.001 | Trt |
| 8 | 3.900 | 0.487 | NA | NA | Residuals |

### stats

[Full-precision CSV](../data/CRD-Tukey-table-3.csv)

| Statistic | Value |
| --- | --- |
| Replications detected | 3.000 |
| Grand Mean | 26.492 |
| Mean Square Error (MSE) | 0.487 |
| Standard Error of Mean - SE(m) | 0.403 |
| Standard Error of Difference - SE(d) | 0.570 |
| Coefficient of Variation - CV (%) | 2.636 |

### means

[Full-precision CSV](../data/CRD-Tukey-table-4.csv)

| Treatment | Value | std | r | se | Min | Max | Q25 | Q50 | Q75 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3.000 | 0.403 | 24.800 | 26.100 | 25.100 | 25.400 | 25.750 |
| T2 | 28.267 | 0.802 | 3.000 | 0.403 | 27.500 | 29.100 | 27.850 | 28.200 | 28.650 |
| T3 | 21.400 | 0.872 | 3.000 | 0.403 | 20.800 | 22.400 | 20.900 | 21.000 | 21.700 |
| T4 | 30.867 | 0.351 | 3.000 | 0.403 | 30.500 | 31.200 | 30.700 | 30.900 | 31.050 |

### groups

[Full-precision CSV](../data/CRD-Tukey-table-5.csv)

| Treatment | Value | Group |
| --- | --- | --- |
| T4 | 30.867 | a |
| T2 | 28.267 | b |
| T1 | 25.433 | c |
| T3 | 21.400 | d |

### lsd_stats

[Full-precision CSV](../data/CRD-Tukey-table-6.csv)

| Metric | Value |
| --- | --- |
| MSerror | 0.487 |
| Df | 8.000 |
| Mean | 26.492 |
| CV | 2.636 |
| MSD | 1.826 |

### treatment_summary

[Full-precision CSV](../data/CRD-Tukey-table-7.csv)

| Treatment | Mean | SD | N | SE | CI lower | CI upper | df |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3 | 0.403 | 24.504 | 26.363 | 8 |
| T2 | 28.267 | 0.802 | 3 | 0.403 | 27.337 | 29.196 | 8 |
| T3 | 21.400 | 0.872 | 3 | 0.403 | 20.470 | 22.330 | 8 |
| T4 | 30.867 | 0.351 | 3 | 0.403 | 29.937 | 31.796 | 8 |

### Diagnostics and model notes

- Model: CRD at alpha 0.05 using Tukey comparisons

## RBD-LSD

[Example CSV](../data/RBD-LSD.csv) · [R script](../code/RBD-LSD.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- read_pasted_table(default_data[["RBD"]])
result <- run_design_analysis(data, "RBD", comparison_method="LSD")
```

### dataset

[Full-precision CSV](../data/RBD-LSD-table-1.csv)

| Treatment | Rep | Value |
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

### anova

[Full-precision CSV](../data/RBD-LSD-table-2.csv)

| df | SS | MS | F | p-value | Source / term |
| --- | --- | --- | --- | --- | --- |
| 2 | 0.602 | 0.301 | 0.547 | 0.605 | Rep |
| 3 | 148.009 | 49.336 | 89.748 | <0.001 | Trt |
| 6 | 3.298 | 0.550 | NA | NA | Residuals |

### stats

[Full-precision CSV](../data/RBD-LSD-table-3.csv)

| Statistic | Value |
| --- | --- |
| Replications detected | 3.000 |
| Grand Mean | 26.492 |
| Mean Square Error (MSE) | 0.550 |
| Standard Error of Mean - SE(m) | 0.428 |
| Standard Error of Difference - SE(d) | 0.605 |
| Coefficient of Variation - CV (%) | 2.799 |

### means

[Full-precision CSV](../data/RBD-LSD-table-4.csv)

| Treatment | Value | std | r | se | LCL | UCL | Min | Max | Q25 | Q50 | Q75 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3.000 | 0.428 | 24.386 | 26.481 | 24.800 | 26.100 | 25.100 | 25.400 | 25.750 |
| T2 | 28.267 | 0.802 | 3.000 | 0.428 | 27.219 | 29.314 | 27.500 | 29.100 | 27.850 | 28.200 | 28.650 |
| T3 | 21.400 | 0.872 | 3.000 | 0.428 | 20.353 | 22.447 | 20.800 | 22.400 | 20.900 | 21.000 | 21.700 |
| T4 | 30.867 | 0.351 | 3.000 | 0.428 | 29.819 | 31.914 | 30.500 | 31.200 | 30.700 | 30.900 | 31.050 |

### groups

[Full-precision CSV](../data/RBD-LSD-table-5.csv)

| Treatment | Value | Group |
| --- | --- | --- |
| T4 | 30.867 | a |
| T2 | 28.267 | b |
| T1 | 25.433 | c |
| T3 | 21.400 | d |

### lsd_stats

[Full-precision CSV](../data/RBD-LSD-table-6.csv)

| Source / term | Metric | Value |
| --- | --- | --- |
| MSerror | MSerror | 0.550 |
| Df | Df | 6.000 |
| Mean | Mean | 26.492 |
| CV | CV | 2.799 |
| t.value | t value | 2.447 |
| LSD | LSD | 1.481 |

### treatment_summary

[Full-precision CSV](../data/RBD-LSD-table-7.csv)

| Treatment | Mean | SD | N | SE | CI lower | CI upper | df |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3 | 0.428 | 24.386 | 26.481 | 6 |
| T2 | 28.267 | 0.802 | 3 | 0.428 | 27.219 | 29.314 | 6 |
| T3 | 21.400 | 0.872 | 3 | 0.428 | 20.353 | 22.447 | 6 |
| T4 | 30.867 | 0.351 | 3 | 0.428 | 29.819 | 31.914 | 6 |

### Diagnostics and model notes

- Model: RBD at alpha 0.05 using LSD comparisons

## RBD-DMRT

[Example CSV](../data/RBD-DMRT.csv) · [R script](../code/RBD-DMRT.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- read_pasted_table(default_data[["RBD"]])
result <- run_design_analysis(data, "RBD", comparison_method="DMRT")
```

### dataset

[Full-precision CSV](../data/RBD-DMRT-table-1.csv)

| Treatment | Rep | Value |
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

### anova

[Full-precision CSV](../data/RBD-DMRT-table-2.csv)

| df | SS | MS | F | p-value | Source / term |
| --- | --- | --- | --- | --- | --- |
| 2 | 0.602 | 0.301 | 0.547 | 0.605 | Rep |
| 3 | 148.009 | 49.336 | 89.748 | <0.001 | Trt |
| 6 | 3.298 | 0.550 | NA | NA | Residuals |

### stats

[Full-precision CSV](../data/RBD-DMRT-table-3.csv)

| Statistic | Value |
| --- | --- |
| Replications detected | 3.000 |
| Grand Mean | 26.492 |
| Mean Square Error (MSE) | 0.550 |
| Standard Error of Mean - SE(m) | 0.428 |
| Standard Error of Difference - SE(d) | 0.605 |
| Coefficient of Variation - CV (%) | 2.799 |

### means

[Full-precision CSV](../data/RBD-DMRT-table-4.csv)

| Treatment | Value | std | r | se | Min | Max | Q25 | Q50 | Q75 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3.000 | 0.428 | 24.800 | 26.100 | 25.100 | 25.400 | 25.750 |
| T2 | 28.267 | 0.802 | 3.000 | 0.428 | 27.500 | 29.100 | 27.850 | 28.200 | 28.650 |
| T3 | 21.400 | 0.872 | 3.000 | 0.428 | 20.800 | 22.400 | 20.900 | 21.000 | 21.700 |
| T4 | 30.867 | 0.351 | 3.000 | 0.428 | 30.500 | 31.200 | 30.700 | 30.900 | 31.050 |

### groups

[Full-precision CSV](../data/RBD-DMRT-table-5.csv)

| Treatment | Value | Group |
| --- | --- | --- |
| T4 | 30.867 | a |
| T2 | 28.267 | b |
| T1 | 25.433 | c |
| T3 | 21.400 | d |

### lsd_stats

[Full-precision CSV](../data/RBD-DMRT-table-6.csv)

| Metric | Value |
| --- | --- |
| MSerror | 0.550 |
| Df | 6.000 |
| Mean | 26.492 |
| CV | 2.799 |

### treatment_summary

[Full-precision CSV](../data/RBD-DMRT-table-7.csv)

| Treatment | Mean | SD | N | SE | CI lower | CI upper | df |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3 | 0.428 | 24.386 | 26.481 | 6 |
| T2 | 28.267 | 0.802 | 3 | 0.428 | 27.219 | 29.314 | 6 |
| T3 | 21.400 | 0.872 | 3 | 0.428 | 20.353 | 22.447 | 6 |
| T4 | 30.867 | 0.351 | 3 | 0.428 | 29.819 | 31.914 | 6 |

### Diagnostics and model notes

- Model: RBD at alpha 0.05 using DMRT comparisons

## RBD-Tukey

[Example CSV](../data/RBD-Tukey.csv) · [R script](../code/RBD-Tukey.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- read_pasted_table(default_data[["RBD"]])
result <- run_design_analysis(data, "RBD", comparison_method="Tukey")
```

### dataset

[Full-precision CSV](../data/RBD-Tukey-table-1.csv)

| Treatment | Rep | Value |
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

### anova

[Full-precision CSV](../data/RBD-Tukey-table-2.csv)

| df | SS | MS | F | p-value | Source / term |
| --- | --- | --- | --- | --- | --- |
| 2 | 0.602 | 0.301 | 0.547 | 0.605 | Rep |
| 3 | 148.009 | 49.336 | 89.748 | <0.001 | Trt |
| 6 | 3.298 | 0.550 | NA | NA | Residuals |

### stats

[Full-precision CSV](../data/RBD-Tukey-table-3.csv)

| Statistic | Value |
| --- | --- |
| Replications detected | 3.000 |
| Grand Mean | 26.492 |
| Mean Square Error (MSE) | 0.550 |
| Standard Error of Mean - SE(m) | 0.428 |
| Standard Error of Difference - SE(d) | 0.605 |
| Coefficient of Variation - CV (%) | 2.799 |

### means

[Full-precision CSV](../data/RBD-Tukey-table-4.csv)

| Treatment | Value | std | r | se | Min | Max | Q25 | Q50 | Q75 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3.000 | 0.428 | 24.800 | 26.100 | 25.100 | 25.400 | 25.750 |
| T2 | 28.267 | 0.802 | 3.000 | 0.428 | 27.500 | 29.100 | 27.850 | 28.200 | 28.650 |
| T3 | 21.400 | 0.872 | 3.000 | 0.428 | 20.800 | 22.400 | 20.900 | 21.000 | 21.700 |
| T4 | 30.867 | 0.351 | 3.000 | 0.428 | 30.500 | 31.200 | 30.700 | 30.900 | 31.050 |

### groups

[Full-precision CSV](../data/RBD-Tukey-table-5.csv)

| Treatment | Value | Group |
| --- | --- | --- |
| T4 | 30.867 | a |
| T2 | 28.267 | b |
| T1 | 25.433 | c |
| T3 | 21.400 | d |

### lsd_stats

[Full-precision CSV](../data/RBD-Tukey-table-6.csv)

| Metric | Value |
| --- | --- |
| MSerror | 0.550 |
| Df | 6.000 |
| Mean | 26.492 |
| CV | 2.799 |
| MSD | 2.096 |

### treatment_summary

[Full-precision CSV](../data/RBD-Tukey-table-7.csv)

| Treatment | Mean | SD | N | SE | CI lower | CI upper | df |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T1 | 25.433 | 0.651 | 3 | 0.428 | 24.386 | 26.481 | 6 |
| T2 | 28.267 | 0.802 | 3 | 0.428 | 27.219 | 29.314 | 6 |
| T3 | 21.400 | 0.872 | 3 | 0.428 | 20.353 | 22.447 | 6 |
| T4 | 30.867 | 0.351 | 3 | 0.428 | 29.819 | 31.914 | 6 |

### Diagnostics and model notes

- Model: RBD at alpha 0.05 using Tukey comparisons

## Reporting conventions
Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.

[Validation and limitations](../VALIDATION.md)
