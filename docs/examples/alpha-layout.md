# Alpha-Lattice Fieldbook

Allocate resolvable incomplete blocks

## Question and data
Specify the genotype count, entries per block, number of complete replicates and seed. Block size must divide the genotype count; the agricolae alpha-design restrictions also apply.

## Read and report the results
Each genotype should occur once in every replicate. Keep the replicate and incomplete-block identifiers with every response measurement.

## Scope and assumptions
This is a layout generator. It does not establish that the chosen field geometry removes spatial variation or guarantee a particular efficiency gain.

## Setup
```r
source("tools/example-cases.R")
load_drdesign()
```

## alpha-layout

[Example CSV](../data/alpha-layout.csv) · [R script](../code/alpha-layout.R)

Synthetic teaching data; not observations from a field experiment.

```r
data <- data.frame(Genotypes=12,BlockSize=3,Replications=3,Seed=7)
result <- list(fieldbook=run_alpha_layout(12,3,3,7))
```

### fieldbook

[Full-precision CSV](../data/alpha-layout-table-1.csv)

| plots | cols | block | paste0("G", seq len(treatments)) | replication | Plot ID | Row | Column | Seed | Response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 101.000 | 1 | 1 | G4 | 1 | P0001 | 1 | 1 | 7 | NA |
| 102.000 | 2 | 1 | G5 | 1 | P0002 | 1 | 2 | 7 | NA |
| 103.000 | 3 | 1 | G11 | 1 | P0003 | 1 | 3 | 7 | NA |
| 104.000 | 1 | 2 | G3 | 1 | P0004 | 1 | 4 | 7 | NA |
| 105.000 | 2 | 2 | G12 | 1 | P0005 | 1 | 5 | 7 | NA |
| 106.000 | 3 | 2 | G7 | 1 | P0006 | 1 | 6 | 7 | NA |
| 107.000 | 1 | 3 | G1 | 1 | P0007 | 1 | 7 | 7 | NA |
| 108.000 | 2 | 3 | G2 | 1 | P0008 | 1 | 8 | 7 | NA |
| 109.000 | 3 | 3 | G9 | 1 | P0009 | 1 | 9 | 7 | NA |
| 110.000 | 1 | 4 | G8 | 1 | P0010 | 1 | 10 | 7 | NA |

First 10 rows shown. Download the CSV for every row.

## Reporting conventions
Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.

[Validation and limitations](../VALIDATION.md)
