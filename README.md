# DrDesign Research Station Suite

This repository now contains a cloud-ready multi-app Shiny suite for research station analysis workflows.

## Apps

- `/` portal for navigation, support text, and module launch
- `/design-analyzer/` Design Randomizer for CRD, RBD, factorial CRD/RBD, split-plot, strip-plot, and augmented RCBD
- `/crd-rbd/` single-factor CRD and RBD
- `/factorial-design/` factorial CRD and factorial RBD
- `/pooled-anova/` pooled analysis across years or seasons
- `/split-plot/` split-plot design analysis
- `/correlation-regression/` correlation and regression workflows

## Shared features

- paste-table and CSV/XLSX upload support
- validation messages in plain language
- CSV table downloads
- HTML report downloads
- shared styling and navigation

## Local run

```powershell
Rscript -e "shiny::runApp('R:/Studies/DrDesign')"
```

## Smoke tests

```powershell
Rscript tests/analysis-smoke-tests.R
```

## Deployment

Deployment assets live in the `deploy/` folder.
