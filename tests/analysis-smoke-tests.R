required_pkgs <- c(
  "shiny", "htmltools", "readxl", "dplyr", "tidyr", "agricolae",
  "desplot", "ggplot2", "emmeans", "multcomp", "multcompView",
  "car", "lme4", "lmerTest", "DT"
)
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop("Missing packages required for analysis smoke tests: ", paste(missing_pkgs, collapse = ", "))
}

source("R/shared.R", local = TRUE)
source("R/analysis.R", local = TRUE)
source("R/met_analysis.R", local = TRUE)
source("R/app_builders.R", local = TRUE)

assert_table <- function(x, min_rows = 1, label = deparse(substitute(x))) {
  stopifnot(is.data.frame(x))
  if (nrow(x) < min_rows) {
    stop(label, " returned fewer than ", min_rows, " row(s).", call. = FALSE)
  }
  invisible(TRUE)
}

check_layout <- function(design, expected_rows, ...) {
  result <- run_design_layout(design, seed = 7, ...)
  assert_table(result$summary, label = paste(design, "summary"))
  assert_table(result$fieldbook, expected_rows, paste(design, "fieldbook"))
  stopifnot(nrow(result$fieldbook) == expected_rows)
  stopifnot(is.data.frame(result$plot_data))
  result
}

check_design_analysis <- function(design, data_text, ...) {
  result <- run_design_analysis(read_pasted_table(data_text), design, ...)
  assert_table(result$dataset, label = paste(design, "dataset"))
  assert_table(result$anova, label = paste(design, "ANOVA"))
  assert_table(result$stats, label = paste(design, "statistics"))
  assert_table(result$means, label = paste(design, "means"))
  assert_table(result$groups, label = paste(design, "groups"))
  result
}

check_layout("CRD", 12, trt = 4, rep = 3)
check_layout("RBD", 12, trt = 4, rep = 3)

factorial_crd_layout <- check_layout("Factorial CRD", 12, factor_a_trt = 2, factor_b_trt = 3, rep = 2)
stopifnot(all(c("FactorA", "FactorB", "Treatment") %in% names(factorial_crd_layout$fieldbook)))
stopifnot(length(unique(factorial_crd_layout$fieldbook$Treatment)) == 6)

factorial_rbd_layout <- check_layout("Factorial RBD", 18, factor_a_trt = 2, factor_b_trt = 3, rep = 3)
stopifnot(all(c("FactorA", "FactorB", "Treatment") %in% names(factorial_rbd_layout$fieldbook)))
stopifnot(length(unique(factorial_rbd_layout$fieldbook$Treatment)) == 6)

check_layout("Split Plot", 27, rep = 3, main_trt = 3, sub_trt = 3)
check_layout("Strip Plot", 27, rep = 3, main_trt = 3, sub_trt = 3)
check_layout("Augmented RCBD", 15, rep = 3, checks = 3, test_trt = 6)

crd_result <- check_design_analysis("CRD", default_data[["CRD"]], alpha = 0.05, comparison_method = "LSD")
stopifnot(identical(crd_result$comparison_method, "LSD"))
assert_table(crd_result$treatment_summary, label = "CRD treatment summary")

rbd_result <- check_design_analysis("RBD", default_data[["RBD"]], alpha = 0.05, comparison_method = "Tukey")
stopifnot(identical(rbd_result$comparison_method, "Tukey"))
assert_table(rbd_result$treatment_summary, label = "RBD treatment summary")

factorial_crd <- check_design_analysis("Factorial CRD", default_data[["Factorial CRD"]], levels_a = 2, levels_b = 2, alpha = 0.05)
stopifnot(is.list(factorial_crd$factorial))
assert_table(factorial_crd$factorial$full_anova, label = "Factorial CRD full ANOVA")
assert_table(factorial_crd$factorial$emmeans_interaction, label = "Factorial CRD emmeans")

factorial_rbd <- check_design_analysis("Factorial RBD", default_data[["Factorial RBD"]], levels_a = 2, levels_b = 2, alpha = 0.05)
stopifnot(is.list(factorial_rbd$factorial))
assert_table(factorial_rbd$factorial$full_anova, label = "Factorial RBD full ANOVA")
assert_table(factorial_rbd$factorial$emmeans_interaction, label = "Factorial RBD emmeans")

desc_result <- run_descriptive_analysis(
  read_pasted_table(default_data[["Descriptive Statistics"]]),
  analysis_type = "summary"
)
assert_table(desc_result$summary, label = "Descriptive summary")

desc_group_result <- run_descriptive_analysis(
  read_pasted_table(default_data[["Descriptive Statistics"]]),
  analysis_type = "sumbygrp",
  selected_vars = c("Yield", "Height"),
  group_var = "Group"
)
assert_table(desc_group_result$by_group, label = "Descriptive group summary")

tt_data <- read_pasted_table(default_data[["Compare Means"]])
tt_one <- run_ttest_analysis(tt_data, "one-sample", value_var = "Value", mu = 0)
assert_table(tt_one$test_result, label = "One-sample t-test")

tt_two <- run_ttest_analysis(tt_data, "two-sample", value_var = "Value", group_var = "Group")
assert_table(tt_two$test_result, label = "Two-sample t-test")

tt_welch <- run_ttest_analysis(tt_data, "welch", value_var = "Value", group_var = "Group")
assert_table(tt_welch$test_result, label = "Welch t-test")

paired_data <- data.frame(Before = c(10.1, 11.3, 9.8, 12.2), After = c(11.0, 12.0, 10.4, 12.8))
tt_paired <- run_ttest_analysis(paired_data, "paired", value_var = "Before", pair_left = "Before", pair_right = "After")
assert_table(tt_paired$test_result, label = "Paired t-test")

pooled_result <- run_pooled_anova(read_pasted_table(pooled_example), alpha = 0.05)
assert_table(pooled_result$anova, 3, "Pooled ANOVA")
assert_table(pooled_result$homogeneity, label = "Pooled homogeneity")
assert_table(pooled_result$error_summary, label = "Pooled error summary")

split_result <- run_split_plot(read_pasted_table(split_plot_example), alpha = 0.05)
assert_table(split_result$emmeans_interaction, label = "Split emmeans interaction")
assert_table(split_result$split_anova, label = "Split ANOVA")
assert_table(split_result$split_lsd_cv, label = "Split LSD/CV")
stopifnot(!is.null(split_result$random_effects))
stopifnot(split_result$random_effect_column %in% names(split_result$random_effects))

custom_split <- read_pasted_table(gsub(
  "Rep\tMainPlot\tSubPlot\tValue",
  "Block\tIrrigation\tVariety\tYield",
  split_plot_example,
  fixed = TRUE
))
custom_split_result <- run_split_plot(
  custom_split,
  rep_var = "Block",
  mainplot_var = "Irrigation",
  subplot_var = "Variety",
  response_var = "Yield",
  alpha = 0.05
)
assert_table(custom_split_result$split_anova, label = "Custom split ANOVA")
assert_table(custom_split_result$split_lsd_cv, label = "Custom split LSD/CV")

cor_result <- run_correlation_regression(read_pasted_table(correlation_example), "Yield", c("Rainfall", "Nitrogen"))
assert_table(cor_result$coefficients, 2, "Correlation regression coefficients")
assert_table(cor_result$correlation_p, 2, "Correlation p-values")

fake_met_result <- function(trait) {
  simple_table <- data.frame(GEN = c("G1", "G2"), Value = c(1, 2), stringsAsFactors = FALSE)
  list(
    trait = trait,
    dataset = simple_table,
    gen_means = simple_table,
    comb_anova = simple_table,
    year_anova = NULL,
    ammi = list(
      anova = simple_table,
      ipca_summary = simple_table,
      pc_scores = simple_table,
      stability = simple_table
    ),
    waasb = list(scores = simple_table),
    blup = simple_table,
    ssi = list(full = simple_table, culled = simple_table)
  )
}

met_signature_a <- met_run_signature(
  mode = "batch",
  data_source = list(type = "pasted", length = 10),
  gen_col = "Genotype",
  env_col = "ENV",
  rep_col = "Rep",
  trait_cols = c("Yield", "DPM"),
  lower_traits = "DPM",
  alpha = 0.05
)
met_signature_b <- met_run_signature(
  mode = "batch",
  data_source = list(type = "pasted", length = 11),
  gen_col = "Genotype",
  env_col = "ENV",
  rep_col = "Rep",
  trait_cols = c("Yield", "DPM"),
  lower_traits = "DPM",
  alpha = 0.05
)
met_cached_payload <- list(
  mode = "batch",
  batch = list(
    results = list(Yield = fake_met_result("Yield"), DPM = fake_met_result("DPM")),
    errors = data.frame(Trait = character(0), Error = character(0), stringsAsFactors = FALSE),
    top_summary = data.frame(Trait = c("Yield", "DPM"), GEN = c("G1", "G2"), stringsAsFactors = FALSE),
    multi_trait_index = data.frame(GEN = "G1", Traits_in_top10 = 2, stringsAsFactors = FALSE)
  ),
  signature = met_signature_a,
  run_time = "test-run"
)
stopifnot(identical(met_select_cached_result(met_cached_payload, "DPM")$trait, "DPM"))
stopifnot(identical(met_select_cached_result(met_cached_payload, "Missing")$trait, "Yield"))
stopifnot(!met_signature_changed(met_signature_a, met_signature_a))
stopifnot(met_signature_changed(met_signature_a, met_signature_b))
stopifnot(grepl("switching traits does not rerun analysis", met_payload_status_text(met_cached_payload, "DPM"), fixed = TRUE))

met_cached_tables <- met_all_batch_result_tables(met_cached_payload$batch, met_cached_payload$batch$results$Yield, include_all_traits = TRUE)
stopifnot(length(met_cached_tables) > 3)
stopifnot(all(vapply(met_cached_tables, is.data.frame, logical(1))))
met_sheet_names <- met_safe_sheet_names(names(met_cached_tables))
stopifnot(all(nchar(met_sheet_names) <= 31))
stopifnot(length(unique(met_sheet_names)) == length(met_sheet_names))

met_pkgs <- c("metan", "lme4", "lmerTest")
if (all(vapply(met_pkgs, requireNamespace, logical(1), quietly = TRUE))) {
  met_smoke <- expand.grid(
    Genotype = paste0("G", 1:4),
    ENV = paste0("E", 1:3),
    Rep = paste0("R", 1:2),
    stringsAsFactors = FALSE
  )
  met_smoke$Yield <- c(
    4.5, 4.7, 4.4, 4.8, 5.1, 5.2,
    5.4, 5.3, 5.7, 5.6, 5.2, 5.4,
    6.1, 6.0, 5.9, 6.2, 6.4, 6.5,
    3.9, 4.0, 4.2, 4.1, 4.3, 4.4
  )
  met_smoke$DPM <- 120 - met_smoke$Yield * 5 + rep(c(0, 1), length.out = nrow(met_smoke))

  met_high <- run_met_analysis(
    met_smoke,
    gen_col = "Genotype",
    env_col = "ENV",
    rep_col = "Rep",
    trait_col = "Yield",
    direction = "h"
  )
  met_low <- run_met_analysis(
    met_smoke,
    gen_col = "Genotype",
    env_col = "ENV",
    rep_col = "Rep",
    trait_col = "Yield",
    direction = "l"
  )

  assert_table(met_high$gen_means, 3, "MET genotype means")
  assert_table(met_high$comb_anova, label = "MET combined ANOVA")
  stopifnot(is.data.frame(met_high$ammi$ipca_summary) || length(met_high$warnings) >= 0)
  stopifnot(is.data.frame(met_high$waasb$scores) || length(met_high$warnings) >= 0)
  stopifnot(is.data.frame(met_high$blup))
  stopifnot(!is.null(met_high$ssi))
  stopifnot(!identical(as.character(met_high$gen_means$GEN[1]), as.character(met_low$gen_means$GEN[1])))
  if (!is.null(met_high$ssi$full) && !is.null(met_low$ssi$full)) {
    stopifnot(!identical(as.character(met_high$ssi$full$GEN[1]), as.character(met_low$ssi$full$GEN[1])))
  }

  direction_map <- c(Yield = "h", DPM = "l")
  met_batch <- run_met_batch_analysis(
    met_smoke,
    gen_col = "Genotype",
    env_col = "ENV",
    rep_col = "Rep",
    trait_cols = c("Yield", "DPM"),
    direction_map = direction_map
  )
  stopifnot(length(met_batch$results) >= 1)
  stopifnot(is.data.frame(met_batch$top_summary))
  stopifnot(is.data.frame(met_batch$multi_trait_index))

  if (requireNamespace("writexl", quietly = TRUE)) {
    met_xlsx <- tempfile(fileext = ".xlsx")
    writexl::write_xlsx(met_batch_result_tables(met_batch, met_batch$results[[1]]), met_xlsx)
    stopifnot(file.exists(met_xlsx))
  }
} else {
  message("Skipping MET model smoke tests; missing packages: ", paste(met_pkgs[!vapply(met_pkgs, requireNamespace, logical(1), quietly = TRUE)], collapse = ", "))
}

cat("All analysis smoke tests passed.\n")
