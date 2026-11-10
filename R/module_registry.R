module_registry <- list(
  portal = list(label = "Portal", prefix = "portal", description = "Choose a research workflow."),
  `design-analyzer` = list(label = "Design Randomizer", prefix = "design_analyzer", description = "Randomize common experimental designs and export fieldbooks."),
  `crd-rbd` = list(label = "CRD / RBD", prefix = "crd_rbd", description = "Analyze single-factor experiments."),
  `factorial-design` = list(label = "Factorial Design", prefix = "factorial_design", description = "Analyze two-factor experiments and interactions."),
  `pooled-anova` = list(label = "Pooled ANOVA", prefix = "pooled_anova", description = "Analyze trials across seasons with residual diagnostics."),
  `pooled-split-plot` = list(label = "Pooled Split Plot", prefix = "pooled_split_plot", description = "Analyze split-plot experiments across years."),
  `split-plot` = list(label = "Split Plot", prefix = "split_plot", description = "Analyze split-plot experiments with separate error strata."),
  `correlation-regression` = list(label = "Correlation & Regression", prefix = "correlation_regression", description = "Explore associations and linear prediction."),
  `descriptive-statistics` = list(label = "Descriptive Statistics", prefix = "descriptive_statistics", description = "Summarize traits and distributions."),
  `compare-means` = list(label = "Compare Means", prefix = "compare_means", description = "One-sample, independent, Welch and paired t-tests."),
  `met-stability` = list(label = "MET Stability", prefix = "met_stability", description = "AMMI, GGE, WAASB and multi-environment stability."),
  `data-preparation` = list(label = "Data Preparation & Trial Validation", roles = character(), traits = TRUE, description = "Review data quality, identifiers and missing observations; reshape wide field data."),
  `augmented-trial` = list(label = "Augmented Trial Analysis", roles = c("Block", "Genotype", "Value"), description = "Adjusted means and comparisons for checks and unreplicated entries."),
  `strip-plot` = list(label = "Strip-Plot Analysis", roles = c("Rep", "FactorA", "FactorB", "Value"), description = "Balanced strip plots with separate error strata."),
  `genetic-variability` = list(label = "Genetic Variability & Heritability", roles = c("Genotype", "Rep"), traits = TRUE, description = "Variance components, heritability, genetic advance and genotype predictions."),
  `multi-trait-selection` = list(label = "Multi-Trait Selection", roles = "Genotype", traits = TRUE, description = "MGIDI and weighted trait scores with explicit selection directions."),
  `pca-diversity` = list(label = "PCA & Diversity Exploration", roles = "Genotype", traits = TRUE, description = "Standardized PCA, biplots and Ward clustering."),
  `power-planning` = list(label = "Power & Replication Planning", roles = character(), description = "Plan balanced CRD and independent two-group comparisons."),
  `alpha-layout` = list(label = "Alpha-Lattice Fieldbook", roles = character(), description = "Generate reproducible incomplete-block layouts and recording sheets."),
  `incomplete-block` = list(label = "Incomplete-Block Trials", roles = c("Genotype", "Rep", "Block"), traits = TRUE, description = "Analyze resolvable incomplete blocks using adjusted means or BLUPs."),
  `spatial-field` = list(label = "Spatial Field Analysis", roles = c("Genotype", "Rep", "Row", "Column", "Value"), description = "Spatial field trends, genotype estimates and residual maps."),
  `combining-ability` = list(label = "Combining Ability", roles = c("Rep", "Parent1", "Parent2", "Value"), description = "Line x tester and fixed-effects Griffing Method II diallel analysis."),
  heterosis = list(label = "Heterosis", roles = c("Rep", "Genotype", "Value"), description = "Mid-parent, better-parent and commercial-check comparisons."),
  `generation-means` = list(label = "Generation-Mean Analysis", roles = c("Generation", "Mean", "SE"), description = "Weighted three- and six-parameter models and scaling tests.")
)

module_groups <- list(
  "Prepare & design" = c("data-preparation","design-analyzer","alpha-layout","power-planning"),
  "Trial analysis" = c("crd-rbd","factorial-design","split-plot","strip-plot","augmented-trial","incomplete-block","spatial-field"),
  "Across environments" = c("pooled-anova","pooled-split-plot","met-stability"),
  "Breeding & selection" = c("genetic-variability","multi-trait-selection","pca-diversity","combining-ability","heterosis","generation-means"),
  "Explore & compare" = c("descriptive-statistics","compare-means","correlation-regression")
)

module_catalog <- function() lapply(names(module_registry), function(key) {
  list(key = key, label = module_registry[[key]]$label, path = if (key == "portal") "?app=portal" else paste0("?app=", key))
})

resolve_module <- function(key) {
  if (is.null(key) || length(key) != 1 || !key %in% names(module_registry)) "portal" else key
}

module_ui <- function(key, catalog = module_catalog()) {
  spec <- module_registry[[resolve_module(key)]]
  if (!is.null(spec$prefix)) get(paste0(spec$prefix, "_ui"))(catalog) else research_ui(key, catalog)
}

module_server <- function(key, input, output, session) {
  spec <- module_registry[[resolve_module(key)]]
  if (!is.null(spec$prefix)) get(paste0(spec$prefix, "_server"))(input, output, session) else research_server(key, input, output, session)
}
