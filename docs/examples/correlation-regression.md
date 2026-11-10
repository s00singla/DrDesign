# Correlation & Regression

Separate association from prediction

## Question and data
Choose a numeric response and one or more numeric predictors. The examples show simple and multiple regression, using one reviewed common observation set for the model and correlation matrix.

## Read and report the results
Report coefficients with SE, t and p-value, R², adjusted R², residual SD and the fitted model. Inspect residuals, linearity and the relevance of predictors. Correlation-matrix tests are unadjusted pairwise Pearson tests.

## Scope and assumptions
Correlation does not establish causation. Perfectly dependent or constant predictors are rejected. The small teaching dataset illustrates the mechanics; it is not enough to establish a reliable predictive model.

## Setup
```r
source("tools/example-cases.R")
load_drdesign()
```

## simple-regression

[Example CSV](../data/simple-regression.csv) · [R script](../code/simple-regression.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- read_pasted_table(correlation_example)
result <- run_correlation_regression(data,"Yield","Rainfall")
```

### dataset

[Full-precision CSV](../data/simple-regression-table-1.csv)

| Yield | Rainfall | Nitrogen | Plant Height |
| --- | --- | --- | --- |
| 42.100 | 740.000 | 90.000 | 112.000 |
| 45.000 | 780.000 | 100.000 | 116.000 |
| 39.800 | 690.000 | 85.000 | 109.000 |
| 50.300 | 820.000 | 110.000 | 122.000 |
| 47.400 | 800.000 | 105.000 | 118.000 |

### correlation

[Full-precision CSV](../data/simple-regression-table-2.csv)

| Source / term | Yield | Rainfall |
| --- | --- | --- |
| Yield | 1.000 | 0.973 |
| Rainfall | 0.973 | 1.000 |

### correlation_source

[Full-precision CSV](../data/simple-regression-table-3.csv)

| Yield | Rainfall |
| --- | --- |
| 42.100 | 740.000 |
| 45.000 | 780.000 |
| 39.800 | 690.000 |
| 50.300 | 820.000 |
| 47.400 | 800.000 |

### correlation_p

[Full-precision CSV](../data/simple-regression-table-4.csv)

| Source / term | Yield | Rainfall |
| --- | --- | --- |
| Yield | <0.001 | 0.005 |
| Rainfall | 0.005 | <0.001 |

### coefficients

[Full-precision CSV](../data/simple-regression-table-5.csv)

| Source / term | Estimate | SE | t | p-value |
| --- | --- | --- | --- | --- |
| (Intercept) | -14.988 | 8.229 | -1.821 | 0.166 |
| Rainfall | 0.078 | 0.011 | 7.294 | 0.005 |

### fit

[Full-precision CSV](../data/simple-regression-table-6.csv)

| Metric | Value |
| --- | --- |
| R-squared | 0.947 |
| Adjusted R-squared | 0.929 |
| Residual SE | 1.110 |
| F-statistic p-value | 0.005 |

### diagnostics

[Full-precision CSV](../data/simple-regression-table-7.csv)

| Observation | Fitted | Residual |
| --- | --- | --- |
| 1 | 42.887 | -0.787 |
| 2 | 46.015 | -1.015 |
| 3 | 38.976 | 0.824 |
| 4 | 49.143 | 1.157 |
| 5 | 47.579 | -0.179 |

### exclusions

[Full-precision CSV](../data/simple-regression-table-8.csv)

No rows to report.

### Diagnostics and model notes

- Regression model: Yield ~ Rainfall. Observations used: 5; excluded after review: 0.

## multiple-regression

[Example CSV](../data/multiple-regression.csv) · [R script](../code/multiple-regression.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- read_pasted_table(correlation_example)
result <- run_correlation_regression(data,"Yield",c("Rainfall","Nitrogen"))
```

### dataset

[Full-precision CSV](../data/multiple-regression-table-1.csv)

| Yield | Rainfall | Nitrogen | Plant Height |
| --- | --- | --- | --- |
| 42.100 | 740.000 | 90.000 | 112.000 |
| 45.000 | 780.000 | 100.000 | 116.000 |
| 39.800 | 690.000 | 85.000 | 109.000 |
| 50.300 | 820.000 | 110.000 | 122.000 |
| 47.400 | 800.000 | 105.000 | 118.000 |

### correlation

[Full-precision CSV](../data/multiple-regression-table-2.csv)

| Source / term | Yield | Rainfall | Nitrogen |
| --- | --- | --- | --- |
| Yield | 1.000 | 0.973 | 0.992 |
| Rainfall | 0.973 | 1.000 | 0.983 |
| Nitrogen | 0.992 | 0.983 | 1.000 |

### correlation_source

[Full-precision CSV](../data/multiple-regression-table-3.csv)

| Yield | Rainfall | Nitrogen |
| --- | --- | --- |
| 42.100 | 740.000 | 90.000 |
| 45.000 | 780.000 | 100.000 |
| 39.800 | 690.000 | 85.000 |
| 50.300 | 820.000 | 110.000 |
| 47.400 | 800.000 | 105.000 |

### correlation_p

[Full-precision CSV](../data/multiple-regression-table-4.csv)

| Source / term | Yield | Rainfall | Nitrogen |
| --- | --- | --- | --- |
| Yield | <0.001 | 0.005 | <0.001 |
| Rainfall | 0.005 | <0.001 | 0.003 |
| Nitrogen | <0.001 | 0.003 | <0.001 |

### coefficients

[Full-precision CSV](../data/multiple-regression-table-5.csv)

| Source / term | Estimate | SE | t | p-value |
| --- | --- | --- | --- | --- |
| (Intercept) | 7.206 | 11.590 | 0.622 | 0.598 |
| Rainfall | -0.005 | 0.039 | -0.118 | 0.917 |
| Nitrogen | 0.421 | 0.193 | 2.175 | 0.162 |

### fit

[Full-precision CSV](../data/multiple-regression-table-6.csv)

| Metric | Value |
| --- | --- |
| R-squared | 0.984 |
| Adjusted R-squared | 0.968 |
| Residual SE | 0.741 |
| F-statistic p-value | 0.016 |

### diagnostics

[Full-precision CSV](../data/multiple-regression-table-7.csv)

| Observation | Fitted | Residual |
| --- | --- | --- |
| 1 | 41.674 | 0.426 |
| 2 | 45.697 | -0.697 |
| 3 | 39.800 | -9.16e-16 |
| 4 | 49.720 | 0.580 |
| 5 | 47.709 | -0.309 |

### exclusions

[Full-precision CSV](../data/multiple-regression-table-8.csv)

No rows to report.

### Diagnostics and model notes

- Regression model: Yield ~ Rainfall + Nitrogen. Observations used: 5; excluded after review: 0.

## Reporting conventions
Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.

[Validation and limitations](../VALIDATION.md)
