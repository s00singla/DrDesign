# Design Randomizer

Randomize before planting

## Question and data
Choose the design, treatment counts, replication counts and a reproducible seed. The examples cover CRD, RCBD, factorial CRD/RCBD, split plot, strip plot and augmented RCBD.

## Read and report the results
The fieldbook records treatment allocation, plot identifiers and the seed. Record the actual field orientation and retain the original allocation before entering responses.

## Scope and assumptions
Recording row and column positions are planning coordinates. Confirm the physical field orientation and randomization restrictions before using them for a spatial analysis.

## Setup
```r
source("tools/example-cases.R")
load_drdesign()
```

## layout-CRD

[Example CSV](../data/layout-CRD.csv) · [R script](../code/layout-CRD.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- data.frame(Seed=7)
result <- run_design_layout("CRD",seed=7,trt=4,rep=3)
```

### summary

[Full-precision CSV](../data/layout-CRD-table-1.csv)

| Treatments | Replications | Experimental Units |
| --- | --- | --- |
| 4.000 | 3 | 12.000 |

### fieldbook

[Full-precision CSV](../data/layout-CRD-table-2.csv)

| Experimental Unit | Treatment | Plot ID | Row | Column | Seed | Response |
| --- | --- | --- | --- | --- | --- | --- |
| 1.000 | T4 | P00001 | 1 | 1 | 7 | NA |
| 2.000 | T2 | P00002 | 1 | 2 | 7 | NA |
| 3.000 | T1 | P00003 | 1 | 3 | 7 | NA |
| 4.000 | T3 | P00004 | 1 | 4 | 7 | NA |
| 5.000 | T4 | P00005 | 1 | 5 | 7 | NA |
| 6.000 | T1 | P00006 | 1 | 6 | 7 | NA |
| 7.000 | T2 | P00007 | 1 | 7 | 7 | NA |
| 8.000 | T3 | P00008 | 1 | 8 | 7 | NA |
| 9.000 | T4 | P00009 | 1 | 9 | 7 | NA |
| 10.000 | T1 | P00010 | 1 | 10 | 7 | NA |

First 10 rows shown. Download the CSV for every row.

### plot_data

[Full-precision CSV](../data/layout-CRD-table-3.csv)

| plots | r | trt labels | Treatment | Experimental Unit | row | col | label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1.000 | 1.000 | T4 | T4 | 1.000 | 1.000 | 1.000 | T4 |
| 2.000 | 1.000 | T2 | T2 | 2.000 | 1.000 | 2.000 | T2 |
| 3.000 | 1.000 | T1 | T1 | 3.000 | 1.000 | 3.000 | T1 |
| 8.000 | 1.000 | T3 | T3 | 4.000 | 1.000 | 4.000 | T3 |
| 4.000 | 2.000 | T4 | T4 | 5.000 | 1.000 | 5.000 | T4 |
| 5.000 | 2.000 | T1 | T1 | 6.000 | 1.000 | 6.000 | T1 |
| 6.000 | 2.000 | T2 | T2 | 7.000 | 1.000 | 7.000 | T2 |
| 9.000 | 2.000 | T3 | T3 | 8.000 | 1.000 | 8.000 | T3 |
| 7.000 | 3.000 | T4 | T4 | 9.000 | 1.000 | 9.000 | T4 |
| 10.000 | 3.000 | T1 | T1 | 10.000 | 1.000 | 10.000 | T1 |

First 10 rows shown. Download the CSV for every row.

## layout-RBD

[Example CSV](../data/layout-RBD.csv) · [R script](../code/layout-RBD.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- data.frame(Seed=7)
result <- run_design_layout("RBD",seed=7,trt=4,rep=3)
```

### summary

[Full-precision CSV](../data/layout-RBD-table-1.csv)

| Treatments | Blocks | Experimental Units |
| --- | --- | --- |
| 4.000 | 3.000 | 12.000 |

### fieldbook

[Full-precision CSV](../data/layout-RBD-table-2.csv)

| Block | Plot | Treatment | Plot ID | Row | Column | Seed | Response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1.000 | T2 | P00001 | 1 | 1 | 7 | NA |
| 1 | 2.000 | T1 | P00002 | 1 | 2 | 7 | NA |
| 1 | 3.000 | T3 | P00003 | 1 | 3 | 7 | NA |
| 1 | 4.000 | T4 | P00004 | 1 | 4 | 7 | NA |
| 2 | 1.000 | T2 | P00005 | 2 | 1 | 7 | NA |
| 2 | 2.000 | T4 | P00006 | 2 | 2 | 7 | NA |
| 2 | 3.000 | T1 | P00007 | 2 | 3 | 7 | NA |
| 2 | 4.000 | T3 | P00008 | 2 | 4 | 7 | NA |
| 3 | 1.000 | T1 | P00009 | 3 | 1 | 7 | NA |
| 3 | 2.000 | T3 | P00010 | 3 | 2 | 7 | NA |

First 10 rows shown. Download the CSV for every row.

### plot_data

[Full-precision CSV](../data/layout-RBD-table-3.csv)

| plots | block | trt labels | Treatment | Plot | block num | plot num | label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 11.000 | 1 | T2 | T2 | 1.000 | 1.000 | 1.000 | T2 |
| 12.000 | 1 | T1 | T1 | 2.000 | 1.000 | 2.000 | T1 |
| 13.000 | 1 | T3 | T3 | 3.000 | 1.000 | 3.000 | T3 |
| 14.000 | 1 | T4 | T4 | 4.000 | 1.000 | 4.000 | T4 |
| 21.000 | 2 | T2 | T2 | 1.000 | 2.000 | 1.000 | T2 |
| 22.000 | 2 | T4 | T4 | 2.000 | 2.000 | 2.000 | T4 |
| 23.000 | 2 | T1 | T1 | 3.000 | 2.000 | 3.000 | T1 |
| 24.000 | 2 | T3 | T3 | 4.000 | 2.000 | 4.000 | T3 |
| 31.000 | 3 | T1 | T1 | 1.000 | 3.000 | 1.000 | T1 |
| 32.000 | 3 | T3 | T3 | 2.000 | 3.000 | 2.000 | T3 |

First 10 rows shown. Download the CSV for every row.

## layout-Factorial-CRD

[Example CSV](../data/layout-Factorial-CRD.csv) · [R script](../code/layout-Factorial-CRD.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- data.frame(Seed=7)
result <- run_design_layout("Factorial CRD",seed=7,factor_a_trt=2,factor_b_trt=3,rep=3)
```

### summary

[Full-precision CSV](../data/layout-Factorial-CRD-table-1.csv)

| Factor ALevels | Factor BLevels | Treatments | Replications | Experimental Units |
| --- | --- | --- | --- | --- |
| 2.000 | 3.000 | 6.000 | 3 | 18.000 |

### fieldbook

[Full-precision CSV](../data/layout-Factorial-CRD-table-2.csv)

| Experimental Unit | Factor A | Factor B | Treatment | Plot ID | Row | Column | Seed | Response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1.000 | A2 | B1 | A2B1 | P00001 | 1 | 1 | 7 | NA |
| 2.000 | A1 | B2 | A1B2 | P00002 | 1 | 2 | 7 | NA |
| 3.000 | A1 | B1 | A1B1 | P00003 | 1 | 3 | 7 | NA |
| 4.000 | A2 | B3 | A2B3 | P00004 | 1 | 4 | 7 | NA |
| 5.000 | A2 | B2 | A2B2 | P00005 | 1 | 5 | 7 | NA |
| 6.000 | A1 | B3 | A1B3 | P00006 | 1 | 6 | 7 | NA |
| 7.000 | A1 | B1 | A1B1 | P00007 | 1 | 7 | 7 | NA |
| 8.000 | A1 | B2 | A1B2 | P00008 | 1 | 8 | 7 | NA |
| 9.000 | A2 | B3 | A2B3 | P00009 | 1 | 9 | 7 | NA |
| 10.000 | A1 | B3 | A1B3 | P00010 | 1 | 10 | 7 | NA |

First 10 rows shown. Download the CSV for every row.

### plot_data

[Full-precision CSV](../data/layout-Factorial-CRD-table-3.csv)

| plots | r | trt labels | Treatment | Experimental Unit | row | col | label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1.000 | 1.000 | A2B1 | A2B1 | 1.000 | 1.000 | 1.000 | A2B1 |
| 2.000 | 1.000 | A1B2 | A1B2 | 2.000 | 1.000 | 2.000 | A1B2 |
| 3.000 | 1.000 | A1B1 | A1B1 | 3.000 | 1.000 | 3.000 | A1B1 |
| 4.000 | 1.000 | A2B3 | A2B3 | 4.000 | 1.000 | 4.000 | A2B3 |
| 8.000 | 1.000 | A2B2 | A2B2 | 5.000 | 1.000 | 5.000 | A2B2 |
| 10.000 | 1.000 | A1B3 | A1B3 | 6.000 | 1.000 | 6.000 | A1B3 |
| 5.000 | 2.000 | A1B1 | A1B1 | 7.000 | 1.000 | 7.000 | A1B1 |
| 6.000 | 2.000 | A1B2 | A1B2 | 8.000 | 1.000 | 8.000 | A1B2 |
| 7.000 | 2.000 | A2B3 | A2B3 | 9.000 | 1.000 | 9.000 | A2B3 |
| 12.000 | 2.000 | A1B3 | A1B3 | 10.000 | 1.000 | 10.000 | A1B3 |

First 10 rows shown. Download the CSV for every row.

## layout-Factorial-RBD

[Example CSV](../data/layout-Factorial-RBD.csv) · [R script](../code/layout-Factorial-RBD.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- data.frame(Seed=7)
result <- run_design_layout("Factorial RBD",seed=7,factor_a_trt=2,factor_b_trt=3,rep=3)
```

### summary

[Full-precision CSV](../data/layout-Factorial-RBD-table-1.csv)

| Factor ALevels | Factor BLevels | Treatments | Blocks | Experimental Units |
| --- | --- | --- | --- | --- |
| 2.000 | 3.000 | 6.000 | 3.000 | 18.000 |

### fieldbook

[Full-precision CSV](../data/layout-Factorial-RBD-table-2.csv)

| Block | Plot | Factor A | Factor B | Treatment | Plot ID | Row | Column | Seed | Response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1.000 | A2 | B1 | A2B1 | P00001 | 1 | 1 | 7 | NA |
| 1 | 2.000 | A1 | B3 | A1B3 | P00002 | 1 | 2 | 7 | NA |
| 1 | 3.000 | A1 | B1 | A1B1 | P00003 | 1 | 3 | 7 | NA |
| 1 | 4.000 | A2 | B2 | A2B2 | P00004 | 1 | 4 | 7 | NA |
| 1 | 5.000 | A2 | B3 | A2B3 | P00005 | 1 | 5 | 7 | NA |
| 1 | 6.000 | A1 | B2 | A1B2 | P00006 | 1 | 6 | 7 | NA |
| 2 | 1.000 | A1 | B1 | A1B1 | P00007 | 2 | 1 | 7 | NA |
| 2 | 2.000 | A1 | B3 | A1B3 | P00008 | 2 | 2 | 7 | NA |
| 2 | 3.000 | A2 | B3 | A2B3 | P00009 | 2 | 3 | 7 | NA |
| 2 | 4.000 | A1 | B2 | A1B2 | P00010 | 2 | 4 | 7 | NA |

First 10 rows shown. Download the CSV for every row.

### plot_data

[Full-precision CSV](../data/layout-Factorial-RBD-table-3.csv)

| plots | block | trt labels | Treatment | Plot | block num | plot num | label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 11.000 | 1 | A2B1 | A2B1 | 1.000 | 1.000 | 1.000 | A2B1 |
| 12.000 | 1 | A1B3 | A1B3 | 2.000 | 1.000 | 2.000 | A1B3 |
| 13.000 | 1 | A1B1 | A1B1 | 3.000 | 1.000 | 3.000 | A1B1 |
| 14.000 | 1 | A2B2 | A2B2 | 4.000 | 1.000 | 4.000 | A2B2 |
| 15.000 | 1 | A2B3 | A2B3 | 5.000 | 1.000 | 5.000 | A2B3 |
| 16.000 | 1 | A1B2 | A1B2 | 6.000 | 1.000 | 6.000 | A1B2 |
| 21.000 | 2 | A1B1 | A1B1 | 1.000 | 2.000 | 1.000 | A1B1 |
| 22.000 | 2 | A1B3 | A1B3 | 2.000 | 2.000 | 2.000 | A1B3 |
| 23.000 | 2 | A2B3 | A2B3 | 3.000 | 2.000 | 3.000 | A2B3 |
| 24.000 | 2 | A1B2 | A1B2 | 4.000 | 2.000 | 4.000 | A1B2 |

First 10 rows shown. Download the CSV for every row.

## layout-Split-Plot

[Example CSV](../data/layout-Split-Plot.csv) · [R script](../code/layout-Split-Plot.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- data.frame(Seed=7)
result <- run_design_layout("Split Plot",seed=7,main_trt=3,sub_trt=3,rep=3)
```

### summary

[Full-precision CSV](../data/layout-Split-Plot-table-1.csv)

| Main Plot Treatments | Sub Plot Treatments | Replications | Experimental Units |
| --- | --- | --- | --- |
| 3.000 | 3.000 | 3 | 27.000 |

### fieldbook

[Full-precision CSV](../data/layout-Split-Plot-table-2.csv)

| Replication | Main-plot factor | Subplot factor | Main Treatment | Sub Treatment | Plot ID | Row | Column | Seed | Response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1.000 | 1 | A2 | B3 | P00001 | 1 | 1 | 7 | NA |
| 1 | 1.000 | 2 | A2 | B1 | P00002 | 1 | 2 | 7 | NA |
| 1 | 1.000 | 3 | A2 | B2 | P00003 | 1 | 3 | 7 | NA |
| 1 | 2.000 | 1 | A1 | B3 | P00004 | 1 | 4 | 7 | NA |
| 1 | 2.000 | 2 | A1 | B1 | P00005 | 1 | 5 | 7 | NA |
| 1 | 2.000 | 3 | A1 | B2 | P00006 | 1 | 6 | 7 | NA |
| 1 | 3.000 | 1 | A3 | B2 | P00007 | 1 | 7 | 7 | NA |
| 1 | 3.000 | 2 | A3 | B1 | P00008 | 1 | 8 | 7 | NA |
| 1 | 3.000 | 3 | A3 | B3 | P00009 | 1 | 9 | 7 | NA |
| 2 | 4.000 | 1 | A1 | B3 | P00010 | 2 | 1 | 7 | NA |

First 10 rows shown. Download the CSV for every row.

### plot_data

[Full-precision CSV](../data/layout-Split-Plot-table-3.csv)

| plots | splots | block | main labels | sub labels | Main Treatment | Sub Treatment | rep num | main num | sub num | main treatment | sub treatment | label |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1.000 | 1 | 1 | A2 | B3 | A2 | B3 | 1.000 | 1.000 | 1.000 | A2 | B3 | A2/B3 |
| 1.000 | 2 | 1 | A2 | B1 | A2 | B1 | 1.000 | 1.000 | 2.000 | A2 | B1 | A2/B1 |
| 1.000 | 3 | 1 | A2 | B2 | A2 | B2 | 1.000 | 1.000 | 3.000 | A2 | B2 | A2/B2 |
| 2.000 | 1 | 1 | A1 | B3 | A1 | B3 | 1.000 | 2.000 | 1.000 | A1 | B3 | A1/B3 |
| 2.000 | 2 | 1 | A1 | B1 | A1 | B1 | 1.000 | 2.000 | 2.000 | A1 | B1 | A1/B1 |
| 2.000 | 3 | 1 | A1 | B2 | A1 | B2 | 1.000 | 2.000 | 3.000 | A1 | B2 | A1/B2 |
| 3.000 | 1 | 1 | A3 | B2 | A3 | B2 | 1.000 | 3.000 | 1.000 | A3 | B2 | A3/B2 |
| 3.000 | 2 | 1 | A3 | B1 | A3 | B1 | 1.000 | 3.000 | 2.000 | A3 | B1 | A3/B1 |
| 3.000 | 3 | 1 | A3 | B3 | A3 | B3 | 1.000 | 3.000 | 3.000 | A3 | B3 | A3/B3 |
| 4.000 | 1 | 2 | A1 | B3 | A1 | B3 | 2.000 | 4.000 | 1.000 | A1 | B3 | A1/B3 |

First 10 rows shown. Download the CSV for every row.

## layout-Strip-Plot

[Example CSV](../data/layout-Strip-Plot.csv) · [R script](../code/layout-Strip-Plot.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- data.frame(Seed=7)
result <- run_design_layout("Strip Plot",seed=7,main_trt=3,sub_trt=3,rep=3)
```

### summary

[Full-precision CSV](../data/layout-Strip-Plot-table-1.csv)

| Horizontal Treatments | Vertical Treatments | Replications | Experimental Units |
| --- | --- | --- | --- |
| 3.000 | 3.000 | 3 | 27.000 |

### fieldbook

[Full-precision CSV](../data/layout-Strip-Plot-table-2.csv)

| Replication | Row | Column | Horizontal Treatment | Vertical Treatment | Plot ID | Seed | Response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1 | A2 | B1 | P00001 | 7 | NA |
| 1 | 1 | 2 | A2 | B2 | P00002 | 7 | NA |
| 1 | 1 | 3 | A2 | B3 | P00003 | 7 | NA |
| 1 | 2 | 1 | A1 | B1 | P00004 | 7 | NA |
| 1 | 2 | 2 | A1 | B2 | P00005 | 7 | NA |
| 1 | 2 | 3 | A1 | B3 | P00006 | 7 | NA |
| 1 | 3 | 1 | A3 | B1 | P00007 | 7 | NA |
| 1 | 3 | 2 | A3 | B2 | P00008 | 7 | NA |
| 1 | 3 | 3 | A3 | B3 | P00009 | 7 | NA |
| 2 | 2 | 3 | A1 | B3 | P00010 | 7 | NA |

First 10 rows shown. Download the CSV for every row.

### plot_data

[Full-precision CSV](../data/layout-Strip-Plot-table-3.csv)

| plots | block | main labels | sub labels | Horizontal Treatment | Vertical Treatment | Row | Column | rep num | row num | col num | label |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 11.000 | 1 | A2 | B1 | A2 | B1 | 1 | 1 | 1.000 | 1.000 | 1.000 | A2/B1 |
| 12.000 | 1 | A2 | B2 | A2 | B2 | 1 | 2 | 1.000 | 1.000 | 2.000 | A2/B2 |
| 13.000 | 1 | A2 | B3 | A2 | B3 | 1 | 3 | 1.000 | 1.000 | 3.000 | A2/B3 |
| 14.000 | 1 | A1 | B1 | A1 | B1 | 2 | 1 | 1.000 | 2.000 | 1.000 | A1/B1 |
| 15.000 | 1 | A1 | B2 | A1 | B2 | 2 | 2 | 1.000 | 2.000 | 2.000 | A1/B2 |
| 16.000 | 1 | A1 | B3 | A1 | B3 | 2 | 3 | 1.000 | 2.000 | 3.000 | A1/B3 |
| 17.000 | 1 | A3 | B1 | A3 | B1 | 3 | 1 | 1.000 | 3.000 | 1.000 | A3/B1 |
| 18.000 | 1 | A3 | B2 | A3 | B2 | 3 | 2 | 1.000 | 3.000 | 2.000 | A3/B2 |
| 19.000 | 1 | A3 | B3 | A3 | B3 | 3 | 3 | 1.000 | 3.000 | 3.000 | A3/B3 |
| 21.000 | 2 | A1 | B3 | A1 | B3 | 2 | 3 | 2.000 | 2.000 | 3.000 | A1/B3 |

First 10 rows shown. Download the CSV for every row.

## layout-Augmented-RCBD

[Example CSV](../data/layout-Augmented-RCBD.csv) · [R script](../code/layout-Augmented-RCBD.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- data.frame(Seed=7)
result <- run_design_layout("Augmented RCBD",seed=7,checks=3,test_trt=6,rep=3)
```

### summary

[Full-precision CSV](../data/layout-Augmented-RCBD-table-1.csv)

| Checks | Test Treatments | Blocks | Experimental Units |
| --- | --- | --- | --- |
| 3.000 | 6.000 | 3.000 | 15.000 |

### fieldbook

[Full-precision CSV](../data/layout-Augmented-RCBD-table-2.csv)

| Block | Plot | Treatment | Plot ID | Row | Column | Seed | Response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1.000 | C3 | P00001 | 1 | 1 | 7 | NA |
| 1 | 2.000 | T3 | P00002 | 1 | 2 | 7 | NA |
| 1 | 3.000 | T6 | P00003 | 1 | 3 | 7 | NA |
| 1 | 4.000 | C2 | P00004 | 1 | 4 | 7 | NA |
| 1 | 5.000 | C1 | P00005 | 1 | 5 | 7 | NA |
| 2 | 1.000 | T1 | P00006 | 2 | 1 | 7 | NA |
| 2 | 2.000 | T5 | P00007 | 2 | 2 | 7 | NA |
| 2 | 3.000 | C2 | P00008 | 2 | 3 | 7 | NA |
| 2 | 4.000 | C1 | P00009 | 2 | 4 | 7 | NA |
| 2 | 5.000 | C3 | P00010 | 2 | 5 | 7 | NA |

First 10 rows shown. Download the CSV for every row.

### plot_data

[Full-precision CSV](../data/layout-Augmented-RCBD-table-3.csv)

| plots | block | trt | Plot | block num | plot num | label |
| --- | --- | --- | --- | --- | --- | --- |
| 11.000 | 1 | C3 | 1.000 | 1.000 | 1.000 | C3 |
| 12.000 | 1 | T3 | 2.000 | 1.000 | 2.000 | T3 |
| 13.000 | 1 | T6 | 3.000 | 1.000 | 3.000 | T6 |
| 14.000 | 1 | C2 | 4.000 | 1.000 | 4.000 | C2 |
| 15.000 | 1 | C1 | 5.000 | 1.000 | 5.000 | C1 |
| 21.000 | 2 | T1 | 1.000 | 2.000 | 1.000 | T1 |
| 22.000 | 2 | T5 | 2.000 | 2.000 | 2.000 | T5 |
| 23.000 | 2 | C2 | 3.000 | 2.000 | 3.000 | C2 |
| 24.000 | 2 | C1 | 4.000 | 2.000 | 4.000 | C1 |
| 25.000 | 2 | C3 | 5.000 | 2.000 | 5.000 | C3 |

First 10 rows shown. Download the CSV for every row.

## Reporting conventions
Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.

[Validation and limitations](../VALIDATION.md)
