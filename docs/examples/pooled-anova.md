# Pooled ANOVA

Combine seasons with a stated inferential scope

## Question and data
Provide Season, Rep, Treatment and Value. Every treatment must be represented in every season. The current model treats seasons, treatments and nested blocks as fixed.

## Read and report the results
Report seasonal error MS and df alongside the combined sequential ANOVA. The residual median-centred Levene calculation is a diagnostic; it does not automatically authorize pooling.

## Scope and assumptions
Inference is conditional on the observed seasons. For a random sample of environments, use a mixed-model approach with an appropriate genotype-by-environment structure.

## Setup
```r
source("tools/example-cases.R")
load_drdesign()
```

## pooled-anova

[Example CSV](../data/pooled-anova.csv) · [R script](../code/pooled-anova.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- read_pasted_table(pooled_example)
result <- run_pooled_anova(data)
```

### dataset

[Full-precision CSV](../data/pooled-anova-table-1.csv)

| Season | Rep | Treatment | Value |
| --- | --- | --- | --- |
| Kharif-2024 | R1 | T1 | 25.400 |
| Kharif-2024 | R2 | T1 | 26.100 |
| Kharif-2024 | R1 | T2 | 28.200 |
| Kharif-2024 | R2 | T2 | 27.800 |
| Rabi-2025 | R1 | T1 | 24.900 |
| Rabi-2025 | R2 | T1 | 25.500 |
| Rabi-2025 | R1 | T2 | 29.000 |
| Rabi-2025 | R2 | T2 | 28.600 |

### anova

[Full-precision CSV](../data/pooled-anova-table-2.csv)

| df | SS | MS | F | p-value | Source / term |
| --- | --- | --- | --- | --- | --- |
| 1 | 0.031 | 0.031 | 0.113 | 0.769 | Season |
| 1 | 17.111 | 17.111 | 61.941 | 0.016 | Treatment |
| 2 | 0.033 | 0.016 | 0.059 | 0.944 | Season:Rep |
| 1 | 0.911 | 0.911 | 3.299 | 0.211 | Season:Treatment |
| 2 | 0.553 | 0.276 | NA | NA | Residuals |

### error_summary

[Full-precision CSV](../data/pooled-anova-table-3.csv)

| Season | Error MS | Error DF |
| --- | --- | --- |
| Kharif-2024 | 0.303 | 1.000 |
| Rabi-2025 | 0.250 | 1.000 |

### homogeneity

[Full-precision CSV](../data/pooled-anova-table-4.csv)

| Metric | Value |
| --- | --- |
| Residual median-centred Levene F | 7.82e+29 |
| df | 1.000 |
| p-value | <0.001 |
| Interpretation | Diagnostic only: inspect residuals and experimental design before pooling. |

### treatment_means

[Full-precision CSV](../data/pooled-anova-table-5.csv)

| Treatment | Mean |
| --- | --- |
| T1 | 25.475 |
| T2 | 28.400 |

### season_treatment_means

[Full-precision CSV](../data/pooled-anova-table-6.csv)

| Season | Treatment | Mean |
| --- | --- | --- |
| Kharif-2024 | T1 | 25.750 |
| Kharif-2024 | T2 | 28.000 |
| Rabi-2025 | T1 | 25.200 |
| Rabi-2025 | T2 | 28.800 |

### Diagnostics and model notes

- ANOVA F-tests on an essentially perfect fit are unreliable
- Pooled across 2 seasons at alpha 0.05. Fixed season, treatment and nested block model with sequential sums of squares; inference is conditional on the observed seasons. Residual Levene test is diagnostic only. Diagnostics: ANOVA F-tests on an essentially perfect fit are unreliable

## Reporting conventions
Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.

[Validation and limitations](../VALIDATION.md)
