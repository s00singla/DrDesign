# Generation-Mean Analysis

Fit generation means with a declared parameterization

## Question and data
Provide one mean and positive sampling SE for P1, P2, F1, F2, BC1 and BC2. The analysis assumes these six means are independent.

## Read and report the results
The fitted equation is m + a·d + b·h + a²·i + ab·j + b²·l. The exported coefficient matrix is authoritative: BC1/BC2 use ±1/4 for the j coefficient. Report three-parameter joint lack of fit and A–D scaling tests before interpreting the saturated six-parameter estimates.

## Scope and assumptions
Some publications define the additive × dominance coefficient as 2ab; their j estimate is half the ab-convention estimate here. Do not compare coefficients across conventions without transformation. The full six-parameter fit has zero lack-of-fit df; supplied SEs are treated as known sampling uncertainty.

## Setup
```r
source("tools/example-cases.R")
load_drdesign()
```

## generation-means

[Example CSV](../data/generation-means.csv) · [R script](../code/generation-means.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- research_example("generation-means")
result <- run_generation_means(data)
```

### Three-parameter estimates

[Full-precision CSV](../data/generation-means-table-1.csv)

| Parameter | Estimate | SE | z | p-value | CI lower | CI upper |
| --- | --- | --- | --- | --- | --- | --- |
| m | 19.858 | 0.396 | 50.198 | <0.001 | 19.083 | 20.634 |
| d | 4.078 | 0.390 | 10.456 | <0.001 | 3.313 | 4.842 |
| h | 4.756 | 0.775 | 6.139 | <0.001 | 3.238 | 6.275 |

### Six-parameter estimates

[Full-precision CSV](../data/generation-means-table-2.csv)

| Parameter | Estimate | SE | z | p-value | CI lower | CI upper |
| --- | --- | --- | --- | --- | --- | --- |
| m | 23.000 | 3.787 | 6.074 | <0.001 | 15.578 | 30.422 |
| d | 4.000 | 0.424 | 9.428 | <0.001 | 3.168 | 4.832 |
| h | -4.000 | 8.852 | -0.452 | 0.651 | -21.349 | 13.349 |
| i | -3.000 | 3.763 | -0.797 | 0.425 | -10.375 | 4.375 |
| j | 1.000 | 2.154 | 0.464 | 0.642 | -3.222 | 5.222 |
| l | 6.000 | 5.348 | 1.122 | 0.262 | -4.482 | 16.482 |

### Scaling tests

[Full-precision CSV](../data/generation-means-table-3.csv)

| Scale | Estimate | SE | z | p-value |
| --- | --- | --- | --- | --- |
| A | -1.000 | 1.676 | -0.597 | 0.551 |
| B | -2.000 | 1.676 | -1.193 | 0.233 |
| C | 0.000 | 3.594 | 0.000 | 1.000 |
| D | 1.500 | 1.881 | 0.797 | 0.425 |

### Three-parameter lack of fit

[Full-precision CSV](../data/generation-means-table-4.csv)

| Chi Square | df | p-value |
| --- | --- | --- |
| 1.705 | 3 | 0.636 |

### Coefficient matrix

[Full-precision CSV](../data/generation-means-table-5.csv)

| Generation | m | d | h | i | j | l |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | 1.000 | 1.000 | 0.000 | 1.000 | 0.000 | 0.000 |
| P2 | 1.000 | -1.000 | 0.000 | 1.000 | 0.000 | 0.000 |
| F1 | 1.000 | 0.000 | 1.000 | 0.000 | 0.000 | 1.000 |
| F2 | 1.000 | 0.000 | 0.500 | 0.000 | 0.000 | 0.250 |
| BC1 | 1.000 | 0.500 | 0.500 | 0.250 | 0.250 | 0.250 |
| BC2 | 1.000 | -0.500 | 0.500 | 0.250 | -0.250 | 0.250 |

### Exclusions

[Full-precision CSV](../data/generation-means-table-6.csv)

No rows to report.

### Reviewed data

[Full-precision CSV](../data/generation-means-table-7.csv)

| Generation | Mean | SE |
| --- | --- | --- |
| P1 | 24.000 | 0.600 |
| P2 | 16.000 | 0.600 |
| F1 | 25.000 | 0.700 |
| F2 | 22.500 | 0.800 |
| BC1 | 24.000 | 0.700 |
| BC2 | 19.500 | 0.700 |

### Software versions

[Full-precision CSV](../data/generation-means-table-8.csv)

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

[Full-precision CSV](../data/generation-means-table-9.csv)

| Setting | Value |
| --- | --- |
| Alpha | 0.05 |
| Weight | Inverse variance of generation means |

### Diagnostics and model notes

- Assumes independent generation means and supplied sampling variances. Normal approximations use supplied SEs. The six-parameter model is saturated and has no lack-of-fit test. Parameterization uses coefficients 1, a, b, a^2, ab, b^2; inspect the exported coefficient matrix.

## Reporting conventions
Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.

[Validation and limitations](../VALIDATION.md)
