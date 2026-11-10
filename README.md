# DrDesign Research Station Suite

DrDesign is a Shiny suite for agricultural experiments, plant breeding and research reporting. It provides 23 workflows, from fieldbook preparation to model diagnostics and downloadable results.

Start with the **[worked-example guide](docs/README.md)**, or open **[the styled guide](docs/index.html)** locally. The guide includes 52 runnable examples, input data, complete output tables, figures and interpretation notes. It is ready for GitHub Pages using the repository's `/docs` folder; it has not been published by this change.

## Workflows

The portal and navigation organize the modules under five headings:

| Heading | Analyses and tools |
| --- | --- |
| Prepare & design | Data review, design randomizer, alpha-lattice fieldbooks, power planning |
| Trial analysis | CRD/RBD, factorial, split plot, strip plot, augmented, incomplete block, spatial |
| Across environments | Pooled ANOVA, pooled split plot, MET stability |
| Breeding & selection | Genetic variability, multi-trait selection, PCA/diversity, combining ability, heterosis, generation means |
| Explore & compare | Descriptive statistics, t-tests, correlation/regression |

## Shared features

- paste-table and CSV/XLSX upload support
- validation messages in plain language
- CSV table downloads
- HTML report downloads
- consistent table labels, uncertainty and p-value formatting across the app and reports
- full-precision CSV results, with formatting applied only for presentation
- reviewed exclusions and protection against exporting results after changing inputs

## Local run

```powershell
Rscript -e "shiny::runApp('R:/Studies/DrDesign')"
```

## Smoke tests

```powershell
Rscript tests/analysis-smoke-tests.R
```

Use `./tools/test-project.ps1 -Reports` for the full analysis and report suites. The scientific audit checks 52 example cases and inventories 457 tables and figures. It combines independent formula checks, package integration checks and rendering checks; these have different strengths. Read the **[validation record and limitations](docs/VALIDATION.md)** before using results in a publication.

The reusable R Markdown articles are in `vignettes/articles/`. Run `Rscript tools/check-vignettes.R` to execute all 23. They currently use source-checkout functions; conversion to an installed R package and exported app launcher is future work.

After generating reports, `Rscript tests/export-content-audit.R` checks every expected formatted value and inference note in the research Word reports. `python tests/pdf-layout-audit.py` checks PDF page boundaries (requires `pdfplumber`), and `python tests/guide-integrity.py` checks local guide links and mathematical text encoding.

`Rscript tests/report-download-tests.R` also invokes the PDF and Word download handlers with helpers isolated in an application environment, as in a running Shiny app. This guards against downloads failing despite standalone report generation succeeding.

## Deployment

Deployment assets live in the `deploy/` folder.

## Authorship and licence

DrDesign is authored and copyright 2026 by Saurav Singla. It is distributed
under GNU GPL version 3. Runtime R packages remain the property of their
respective copyright holders and are not included in the DrDesign copyright
claim. The `grapesAgri1-1.1.0` reference tree is excluded from DrDesign release
and copyright-filing artifacts.

## Research expansion

The portal now includes data validation, augmented and strip-plot analysis,
genetic variability, multi-trait selection, PCA/diversity, power planning,
alpha-lattice fieldbooks, incomplete-block and spatial trials, combining ability,
heterosis, and generation-mean analysis. See [RESEARCH_MODULES.md](RESEARCH_MODULES.md)
for supported designs, assumptions, verification, and package integration details.

Canonical navigation uses the root app with `?app=<module-key>`. On Windows,
use `./tools/run-local.ps1` to select R 4.5.3 explicitly, and run
`./tools/test-project.ps1 -Reports` for analysis and export checks.
