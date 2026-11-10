# Validation record

27 October 2026.

74 checks across 52 executable cases passed.

[Check results](data/checks.csv) · [Output inventory](data/inventory.csv) · [Package versions](data/session-info.txt)

Independent formula checks, integration checks and rendering checks have different evidential strength. These examples do not certify every possible dataset. Inspect experimental assumptions and model diagnostics before publication.

## Corrections

- Corrected two-sample and paired t-test differences and aligned one-sample confidence intervals with the difference from the null mean.
- Separated display rounding from calculation. Small p-values are displayed as <0.001 and raw values retain numerical precision.
- Used the fitted error and t limits for CRD/RCBD mean intervals.
- Retained full interactions rather than selecting an additive model from a preliminary interaction test.
- Corrected split-plot SE(d) labels, column mapping, balanced-design validation and cross-stratum approximate degrees of freedom.
- Disabled silent AMMI/GGE imputation and automatic substitute stability formulas.
- Stopped discarding nonpositive values in harmonic stability calculations.
- Replaced generic genetic BLUP limits with clearly labelled conditional genotypic-effect intervals.
- Corrected report section titles, removed duplicate tables, repeated PDF headers and preserved literal formula labels in Word.

## Reporting conventions
Tables: estimates and standard errors to 3 decimals; p-values below 0.001 shown as <0.001. Very small or large values use scientific notation. NA means unavailable or not applicable. CSV files retain numerical precision. Confidence levels and multiplicity corrections follow the stated analysis settings; shared letters indicate non-rejection, not equivalence.

## References

- [R t-test definitions](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/t.test.html)
- [emmeans comparisons and contrasts](https://rvlenth.github.io/emmeans/articles/comparisons.html)
- [metan models and examples](https://tiagoolivoto.github.io/metan/)
- [agricolae experimental designs](https://cran.r-project.org/package=agricolae)
- [SpATS spatial analysis](https://cran.r-project.org/package=SpATS)
- [DiallelAnalysisR](https://cran.r-project.org/package=DiallelAnalysisR)
- [Generation-mean parameterization in a published analysis](https://academicjournals.org/journal/JPBCS/article-full-text/A8E7C2D53630)

## Additional verification

- [Research and interface checks](data/research-checks.csv): 59 passed
- [Legacy module checks](data/module-checks.csv): 27 passed
- [Runnable vignette articles](data/vignette-checks.csv): 23 passed
- [Word table value checks](data/word-content-checks.csv): 17 passed
- [PDF page boundary checks](data/pdf-layout-checks.csv): 27 passed
