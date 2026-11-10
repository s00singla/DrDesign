# DrDesign research guide

Start with the [data preparation tutorial](examples/data-preparation.md).

## Prepare & design

- [Data Preparation & Trial Validation](examples/data-preparation.md)
- [Design Randomizer](examples/design-analyzer.md)
- [Alpha-Lattice Fieldbook](examples/alpha-layout.md)
- [Power & Replication Planning](examples/power-planning.md)

## Trial analysis

- [CRD / RBD](examples/crd-rbd.md)
- [Factorial Design](examples/factorial-design.md)
- [Split Plot](examples/split-plot.md)
- [Strip-Plot Analysis](examples/strip-plot.md)
- [Augmented Trial Analysis](examples/augmented-trial.md)
- [Incomplete-Block Trials](examples/incomplete-block.md)
- [Spatial Field Analysis](examples/spatial-field.md)

## Across environments

- [Pooled ANOVA](examples/pooled-anova.md)
- [Pooled Split Plot](examples/pooled-split-plot.md)
- [MET Stability](examples/met-stability.md)

## Breeding & selection

- [Genetic Variability & Heritability](examples/genetic-variability.md)
- [Multi-Trait Selection](examples/multi-trait-selection.md)
- [PCA & Diversity Exploration](examples/pca-diversity.md)
- [Combining Ability](examples/combining-ability.md)
- [Heterosis](examples/heterosis.md)
- [Generation-Mean Analysis](examples/generation-means.md)

## Explore & compare

- [Descriptive Statistics](examples/descriptive-statistics.md)
- [Compare Means](examples/compare-means.md)
- [Correlation & Regression](examples/correlation-regression.md)

## Rebuild

```r
source("tests/scientific-audit.R")
source("tools/prepare-guide.R")
```

```sh
python tools/build-guide.py
```

Open docs/index.html for the styled site. To publish with GitHub Pages, select the reviewed branch and /docs folder in repository Pages settings. This build does not publish the repository or claim a live URL.

Vignette sources are in vignettes/articles/. They currently load source-checkout functions; replace the setup with exported package functions when packaging is completed.

[Validation and limitations](VALIDATION.md)
