source("R/shared.R", local = TRUE)
source("R/analysis.R", local = TRUE)
source("R/met_analysis.R", local = TRUE)

design_result <- run_design_analysis(read_pasted_table(default_data[["CRD"]]), "CRD", alpha = 0.05)
stopifnot(nrow(design_result$anova) >= 2)
stopifnot(identical(design_result$comparison_method, "LSD"))
stopifnot(nrow(design_result$treatment_summary) >= 1)

pooled_result <- run_pooled_anova(read_pasted_table(pooled_example), alpha = 0.05)
stopifnot(nrow(pooled_result$anova) >= 3)

split_result <- run_split_plot(read_pasted_table(split_plot_example), alpha = 0.05)
stopifnot(nrow(split_result$emmeans_interaction) >= 1)
stopifnot(nrow(split_result$split_anova) >= 1)
stopifnot(nrow(split_result$split_lsd_cv) >= 1)
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
stopifnot(nrow(custom_split_result$split_anova) >= 1)
stopifnot(nrow(custom_split_result$split_lsd_cv) >= 1)

cor_result <- run_correlation_regression(read_pasted_table(correlation_example), "Yield", c("Rainfall", "Nitrogen"))
stopifnot(nrow(cor_result$coefficients) >= 2)
stopifnot(nrow(cor_result$correlation_p) >= 2)

layout_result <- run_design_layout("RBD", seed = 7, trt = 4, rep = 3)
stopifnot(nrow(layout_result$fieldbook) == 12)

factorial_crd_layout <- run_design_layout("Factorial CRD", seed = 7, factor_a_trt = 2, factor_b_trt = 3, rep = 2)
stopifnot(nrow(factorial_crd_layout$fieldbook) == 12)
stopifnot(all(c("FactorA", "FactorB", "Treatment") %in% names(factorial_crd_layout$fieldbook)))
stopifnot(length(unique(factorial_crd_layout$fieldbook$Treatment)) == 6)

factorial_rbd_layout <- run_design_layout("Factorial RBD", seed = 7, factor_a_trt = 2, factor_b_trt = 3, rep = 3)
stopifnot(nrow(factorial_rbd_layout$fieldbook) == 18)
stopifnot(all(c("FactorA", "FactorB", "Treatment") %in% names(factorial_rbd_layout$fieldbook)))
stopifnot(length(unique(factorial_rbd_layout$fieldbook$Treatment)) == 6)

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

  stopifnot(nrow(met_high$gen_means) >= 3)
  stopifnot(nrow(met_high$comb_anova) >= 1)
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
  message("Skipping MET smoke tests; missing packages: ", paste(met_pkgs[!vapply(met_pkgs, requireNamespace, logical(1), quietly = TRUE)], collapse = ", "))
}

cat("All smoke tests passed.\n")
