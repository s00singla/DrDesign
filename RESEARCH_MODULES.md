# Research modules and validation

The application uses one registry for navigation and query routing. Launch the
root application and select a module. Canonical links use `?app=<module-key>`.
Sessions are temporary; export tables and reports before leaving a module.

## New workflows

| Module key | Accepted workflow |
|---|---|
| data-preparation | Check traits and identifiers, review exclusions, convert replication-wide tables |
| augmented-trial | Augmented RCBD: at least two checks in every block, test entries once each |
| strip-plot | Complete balanced Rep x FactorA x FactorB, with distinct error strata |
| genetic-variability | Replicated single-environment RCBD; genotype random, replication fixed |
| multi-trait-selection | One row per genotype; weighted standardized score or MGIDI |
| pca-diversity | Standardized PCA and Euclidean Ward.D2 clustering |
| power-planning | Balanced independent CRD ANOVA or two independent groups |
| alpha-layout | Seeded alpha-lattice allocation and recording fieldbook |
| incomplete-block | Complete resolvable equal-size incomplete blocks; fixed means or random BLUPs |
| spatial-field | Gaussian SpATS with plot row/column, replication, genotype and response |
| combining-ability | Balanced crosses-only line x tester, or fixed Griffing II diallel including parents |
| heterosis | Balanced replicated parents, hybrids and optional commercial check |
| generation-means | Six independent generation means (P1/P2/F1/F2/BC1/BC2) with positive SEs |

Each data-based module contains an example, upload/paste controls, column mapping,
and explicit observation review. Exclusions require confirmation and are recorded
in reports. Missing-value decisions reset after data/mapping changes. Unsupported
layouts are rejected. Data Preparation can create a reviewed CSV for older modules
that reject missing data directly. Batch MET exclusions are recorded per trait.

New analysis reports include settings, data used, exclusions, software versions,
diagnostics and references. Changed analysis inputs invalidate displayed results
and downloads. Table pagination and selection of an export table do not invalidate
the analysis. There is no automatic model fallback or imputation.

## Statistical implementation decisions

- Augmented comparisons use agricolae DAU Fisher LSD with design-specific standard
  errors. These are unadjusted comparisons, explicitly labelled in the report.
- Strip plots use agricolae ANOVA and an aov error-stratum model for emmeans
  comparisons. Tukey adjustment is applied within each displayed comparison family.
- Genetic variance uses metan/lme4. The simple entry-mean heritability, accuracy and
  genetic advance formulas are reported only for balanced RCBD. Plot heritability
  is conditional on the fitted block structure. CVs require a positive trait mean.
- Selection includes all ties at the requested cutoff. Selection differentials
  are descriptive, not promised genetic gain. MGIDI is kept distinct from the
  weighted score and MET stability indices.
- Spatial smoothing uses PSANOVA with 3 x 3 segments and fixed replication. Row and
  column coordinates must identify unique plots. Nonspatial RMSE comparison is
  descriptive in-sample fit, not a model selection criterion.
- The installed agricolae lineXtester routine requires parent rows; it cannot fit
  the planned crosses-only workflow. The module instead fits Rep + Line * Tester
  and derives fixed GCA/SCA and standard errors through explicit linear contrasts.
- The installed DiallelAnalysisR 0.6.0 Method II routine computes its StdErr from
  the replication mean square. That field is deliberately not used. The module
  retains its ANOVA but derives GCA/SCA uncertainty from residual covariance of the
  fitted cross means. Random-population genetic components are not presented for
  this fixed-parent model.
- Heterosis percentage intervals use a delta approximation. Near-zero reference
  means make them unstable; a zero reference produces NA. Better-parent intervals
  are conditional on the observed parent selected. Difference tests include Holm
  correction across the displayed family.
- Generation-mean coefficients are exported explicitly. SEs are treated as
  supplied sampling uncertainty, with independent generation means. The full
  six-parameter fit is saturated and has no lack-of-fit test.

## Running and checking

On this Windows workspace:

```powershell
./tools/run-local.ps1
./tools/test-project.ps1 -Reports
```

The scripts select R 4.5.3 explicitly because the system's default Rscript points
to R 2.15.1. For another host, use R 4.5.3, restore renv.lock, then run the same R
test scripts. Report checks need Pandoc and a LaTeX engine for PDF output.

The research suite includes independent checks for augmented adjustments,
strip-plot error terms, balanced variance components, combining-ability effects,
heterosis, power, PCA and generation-mean coefficients. It also tests invalid
designs, exclusions, genotype IDs, stale results, UI construction and exports.
Report test output is retained under output/research-reports for inspection.

Validation on 27 October 2026: 59 research/interface checks, 27 legacy audit
checks and 74 scientific checks passed, along with the legacy analysis smoke
suite. The scientific audit executes 52 cases and inventories 457 tables and
figures across all 23 workflows. See [the validation record](docs/VALIDATION.md)
for individual checks, corrected calculations, assumptions and evidence.
HTML, Word and PDF reports were generated for 17 research example/variant cases;
the 10 legacy report cases also export to Word and PDF. Word table contents and
PDF page boundaries are checked, with representative pages visually reviewed.
Browser checks covered data preparation, augmented trials, PCA, multi-trait
selection and the existing regression module, including stale-result protection
and CSV/Word/PDF downloads. These
checks cover supplied examples and selected edge cases, not every possible dataset.
An input-update loop that rebuilt interactive tables and interrupted downloads
is covered by a regression check.

The navigation now has five workflow headings. Publication tables share labels,
precision rules and explicit uncertainty fields across the app and exports;
CSV files retain full precision. PDF tables repeat headers across page breaks.
The example guide contains 23 articles and 52 scripts, with matching R Markdown
sources for future package vignettes. It is prepared for GitHub Pages but not
published. The source-checkout app remains runnable with shiny::runApp().

Conditional BLUP effect intervals describe random-effect uncertainty with fitted
variance parameters held fixed. They are not confidence intervals for absolute
genotype means. Generation-mean interaction coefficients use the exported ab
convention; a 2ab convention has a differently scaled interaction parameter.

The container configuration uses the root app; nginx redirects the original
path-style module URLs. The Docker daemon must be running to validate a container
build. The Docker daemon was unavailable during this validation, so container
startup and nginx redirects remain unverified. No production deployment was made.

These workflows do not cover GWAS/QTL/genomic prediction, arbitrary diallel
methods, multienvironment combining ability, correlated generation-mean SEs,
or power for blocked/split-plot designs.
