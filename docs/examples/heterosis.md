# Heterosis

State the reference and the direction of improvement

## Question and data
Use a balanced replicated trial containing both parents, separate hybrids and optionally a commercial check. Select the reference entries and whether a lower response is better.

## Read and report the results
Heterosis is 100 × (hybrid/reference − 1). Report mid-parent, observed better-parent and standard-check comparisons separately, with mean differences, SEs and Holm-adjusted difference tests. Percentage intervals use the delta method.

## Scope and assumptions
Percentage uncertainty is unstable near a zero reference. Better-parent intervals condition on the observed selected parent. Negative heterosis can be desirable for a lower-is-better trait; statistical significance alone does not establish usefulness.

## Setup
```r
source("tools/example-cases.R")
load_drdesign()
```

## heterosis

[Example CSV](../data/heterosis.csv) · [R script](../code/heterosis.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- research_example("heterosis")
result <- run_heterosis(data,"G01","G02",c("G03","G04"),check="G05")
```

### Heterosis estimates

[Full-precision CSV](../data/heterosis-table-1.csv)

| Hybrid | Comparison | Reference Mean | Difference | Difference SE | p-value (difference) | Heterosis Percent | Approx SEPercent | Approx Lower | Approx Upper | p-value (Holm) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| G03 | Mid-parent | 22.055 | 1.124 | 1.269 | 0.386 | 5.095 | 5.854 | -7.046 | 17.236 | 1.000 |
| G03 | Better-parent | 22.135 | 1.043 | 1.466 | 0.484 | 4.713 | 6.779 | -9.345 | 18.771 | 1.000 |
| G03 | Standard | 24.431 | -1.252 | 1.466 | 0.402 | -5.125 | 5.847 | -17.251 | 7.001 | 1.000 |
| G04 | Mid-parent | 22.055 | 2.239 | 1.269 | 0.092 | 10.150 | 5.956 | -2.201 | 22.502 | 0.550 |
| G04 | Better-parent | 22.135 | 2.158 | 1.466 | 0.155 | 9.750 | 6.951 | -4.666 | 24.165 | 0.775 |
| G04 | Standard | 24.431 | -0.137 | 1.466 | 0.926 | -0.561 | 5.982 | -12.967 | 11.844 | 1.000 |

### Adjusted means

[Full-precision CSV](../data/heterosis-table-2.csv)

| Genotype | Estimated mean | SE | df | CI lower | CI upper |
| --- | --- | --- | --- | --- | --- |
| G01 | 21.974 | 1.036 | 22 | 19.825 | 24.123 |
| G02 | 22.135 | 1.036 | 22 | 19.986 | 24.284 |
| G03 | 23.178 | 1.036 | 22 | 21.029 | 25.328 |
| G04 | 24.293 | 1.036 | 22 | 22.144 | 26.443 |
| G05 | 24.431 | 1.036 | 22 | 22.281 | 26.580 |
| G06 | 25.799 | 1.036 | 22 | 23.650 | 27.948 |
| G07 | 26.504 | 1.036 | 22 | 24.355 | 28.654 |
| G08 | 26.862 | 1.036 | 22 | 24.713 | 29.011 |
| G09 | 28.346 | 1.036 | 22 | 26.197 | 30.495 |
| G10 | 28.677 | 1.036 | 22 | 26.528 | 30.826 |

First 10 rows shown. Download the CSV for every row.

Results are averaged over the levels of: Rep

Confidence level used: 0.95

### ANOVA

[Full-precision CSV](../data/heterosis-table-3.csv)

| Source / term | df | SS | MS | F | p-value |
| --- | --- | --- | --- | --- | --- |
| Rep | 2 | 4.870 | 2.435 | 0.756 | 0.481 |
| Genotype | 11 | 277.705 | 25.246 | 7.836 | <0.001 |
| Residuals | 22 | 70.877 | 3.222 | NA | NA |

### Exclusions

[Full-precision CSV](../data/heterosis-table-4.csv)

No rows to report.

### Reviewed data

[Full-precision CSV](../data/heterosis-table-5.csv)

| Genotype | Rep | Value |
| --- | --- | --- |
| G01 | R1 | 22.691 |
| G02 | R1 | 20.013 |
| G03 | R1 | 23.957 |
| G04 | R1 | 24.046 |
| G05 | R1 | 22.649 |
| G06 | R1 | 27.087 |
| G07 | R1 | 25.236 |
| G08 | R1 | 25.931 |
| G09 | R1 | 29.522 |
| G10 | R1 | 26.708 |

First 10 rows shown. Download the CSV for every row.

### Software versions

[Full-precision CSV](../data/heterosis-table-6.csv)

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

[Full-precision CSV](../data/heterosis-table-7.csv)

| Setting | Value |
| --- | --- |
| Parent1 | G01 |
| Parent2 | G02 |
| Lower_is_better | FALSE |
| Alpha | 0.05 |

### Diagnostics and model notes

- Percentage intervals use the delta method and are unreliable near a zero reference mean. Zero-reference percentages are undefined. Better-parent intervals are conditional on the observed selected parent. Holm p-values adjust the family of displayed difference tests.

## Reporting conventions
Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.

[Validation and limitations](../VALIDATION.md)
