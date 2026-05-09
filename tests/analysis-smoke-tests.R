source("R/shared.R", local = TRUE)
source("R/analysis.R", local = TRUE)

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

cat("All smoke tests passed.\n")
