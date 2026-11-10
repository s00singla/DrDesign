required_pkgs <- c(
  "shiny", "htmltools", "readxl", "dplyr", "tidyr", "agricolae",
  "desplot", "ggplot2", "emmeans", "multcomp", "multcompView",
  "car", "lme4", "lmerTest", "rmarkdown", "knitr", "DT"
)
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop("Missing packages required for report smoke tests: ", paste(missing_pkgs, collapse = ", "))
}
if (!rmarkdown::pandoc_available()) {
  stop("Pandoc is required for report smoke tests.")
}

source("R/shared.R", local = TRUE)
source("R/analysis.R", local = TRUE)
source("R/met_analysis.R", local = TRUE)
source("R/app_builders.R", local = TRUE)

has_pdf_engine <- function() {
  engines <- c("pdflatex", "xelatex", "lualatex")
  any(nzchar(Sys.which(engines)))
}

assert_rendered <- function(path, label) {
  if (!file.exists(path)) {
    stop(label, " did not create an output file: ", path, call. = FALSE)
  }
  info <- file.info(path)
  if (is.na(info$size) || info$size < 1000) {
    stop(label, " output is unexpectedly small: ", info$size, " bytes.", call. = FALSE)
  }
  invisible(TRUE)
}

render_report_pair <- function(label, params) {
  dir.create("output/legacy-reports", recursive = TRUE, showWarnings = FALSE)
  stem <- file.path("output/legacy-reports", gsub("[^A-Za-z0-9]+", "-", label))
  word_file <- paste0(stem, ".docx")
  render_parameterized_report(word_file, "word_document", params)
  assert_rendered(word_file, paste(label, "Word report"))
  document <- xml2::read_xml(unz(word_file, "word/document.xml"))
  tables <- xml2::xml_find_all(document, ".//w:tbl", xml2::xml_ns(document))
  stopifnot(length(tables) > 0, !grepl("\\begin{longtable}", xml2::xml_text(document), fixed = TRUE))

  if (has_pdf_engine()) {
    pdf_file <- paste0(stem, ".pdf")
    render_parameterized_report(pdf_file, "pdf_document", params)
    assert_rendered(pdf_file, paste(label, "PDF report"))
  } else {
    message("Skipping ", label, " PDF report smoke test; no LaTeX engine found.")
  }
  cat("PASS reports:", label, "\n")
}

design_layout_params <- function() {
  plan <- run_design_layout("RBD", seed = 7, trt = 4, rep = 3)
  list(
    report_title = "Design Layout Report",
    design_name = plan$design,
    comparison_method = "Randomized layout",
    summary_stats = plan$summary,
    anova_table = plan$fieldbook,
    dataset_preview = head(plan$fieldbook, 20),
    inference_text = sprintf("Randomized %s layout generated with seed %s.", plan$design, 7),
    report_note = sprintf("Design: %s | Seed: %s | Experimental units: %s", plan$design, 7, nrow(plan$fieldbook)),
    extra_tables = list("Design Summary" = plan$summary, "Allocation Table" = plan$fieldbook),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
}

crd_rbd_params <- function() {
  result <- run_design_analysis(read_pasted_table(default_data[["CRD"]]), "CRD", alpha = 0.05, comparison_method = "LSD")
  treatment_plot <- ggplot2::ggplot(result$treatment_summary, ggplot2::aes(x = Treatment, y = Mean, fill = Treatment)) +
    ggplot2::geom_col(alpha = 0.9) +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = LowerCI, ymax = UpperCI), width = 0.2) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "none") +
    ggplot2::labs(title = "CRD treatment means with 95% CI", x = "Treatment", y = "Mean response")
  list(
    report_title = "CRD Analysis Report",
    design_name = "CRD",
    alpha = 0.05,
    comparison_method = result$comparison_method,
    summary_stats = result$treatment_summary,
    anova_table = result$anova,
    key_statistics = result$stats,
    mean_table = result$means,
    posthoc_summary = result$lsd_stats,
    posthoc_table = result$groups,
    dataset_preview = head(result$dataset, 20),
    inference_text = result$inference,
    report_note = result$report_note,
    plot_errorbar = treatment_plot,
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
}

descriptive_params <- function() {
  result <- run_descriptive_analysis(read_pasted_table(default_data[["Descriptive Statistics"]]), "summary")
  list(
    report_title = "Descriptive Statistics Report",
    design_name = "Descriptive Statistics",
    comparison_method = "summary",
    summary_stats = result$summary,
    anova_table = result$by_group,
    dataset_preview = head(result$dataset, 20),
    inference_text = paste(result$normality, collapse = "\n"),
    report_note = "Analysis type: summary",
    extra_tables = list("Summary Statistics" = result$summary, "Group Summary" = result$by_group),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
}

compare_means_params <- function() {
  result <- run_ttest_analysis(read_pasted_table(default_data[["Compare Means"]]), "two-sample", value_var = "Value", group_var = "Group")
  list(
    report_title = "Compare Means Report",
    design_name = "Compare Means",
    comparison_method = "two-sample",
    summary_stats = result$summary,
    anova_table = result$test_result,
    key_statistics = result$variance,
    dataset_preview = head(result$dataset, 20),
    inference_text = "Test type: two-sample",
    report_note = "Compare means workflow: two-sample",
    plot_errorbar = result$plot_obj,
    extra_tables = list(
      "Descriptive Summary" = result$summary,
      "Variance Comparison" = result$variance,
      "Test Result" = result$test_result
    ),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
}

factorial_params <- function() {
  result <- run_design_analysis(read_pasted_table(default_data[["Factorial CRD"]]), "Factorial CRD", levels_a = 2, levels_b = 2, alpha = 0.05)
  fact <- result$factorial
  list(
    report_title = "Factorial CRD Analysis Report",
    design_name = "Factorial CRD",
    alpha = 0.05,
    comparison_method = result$comparison_method,
    summary_stats = result$means,
    anova_table = result$anova,
    key_statistics = result$stats,
    mean_table = fact$emmeans_interaction,
    posthoc_summary = fact$tukey_interaction,
    posthoc_table = fact$cld_interaction,
    dataset_preview = head(result$dataset, 20),
    inference_text = "Factorial design smoke report.",
    report_note = result$report_note,
    plot_errorbar = fact$observed_interaction_plot,
    extra_tables = list(
      "Factorial Full ANOVA" = fact$full_anova,
      "Factorial Additive ANOVA" = fact$additive_anova,
      "Factorial Assumptions" = fact$assumptions,
      "Estimated Means - Interaction" = fact$emmeans_interaction,
      "Tukey Comparisons - Interaction" = fact$tukey_interaction,
      "Diagnostics" = fact$diagnostics
    ),
    extra_text_sections = list("Data Summary" = fact$data_summary, "Final Model Summary" = fact$final_summary),
    extra_plots = list("Boxplot" = fact$boxplot_obj, "Observed Interaction Plot" = fact$observed_interaction_plot),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
}

pooled_params <- function() {
  result <- run_pooled_anova(read_pasted_table(pooled_example), alpha = 0.05)
  list(
    report_title = "Pooled ANOVA Report",
    design_name = "Pooled ANOVA",
    alpha = 0.05,
    comparison_method = "Bartlett homogeneity check",
    summary_stats = result$treatment_means,
    anova_table = result$anova,
    key_statistics = result$homogeneity,
    mean_table = result$season_treatment_means,
    dataset_preview = head(result$dataset, 20),
    inference_text = result$report_note,
    report_note = result$report_note,
    extra_tables = list(
      "Homogeneity Check" = result$homogeneity,
      "Season-wise Error Mean Square" = result$error_summary,
      "Pooled ANOVA Table" = result$anova,
      "Treatment Means" = result$treatment_means,
      "Season x Treatment Means" = result$season_treatment_means
    ),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
}

split_plot_params <- function() {
  result <- run_split_plot(read_pasted_table(split_plot_example), alpha = 0.05)
  list(
    report_title = "Split Plot Analysis Report",
    design_name = "Split Plot",
    alpha = 0.05,
    comparison_method = "Tukey",
    summary_stats = result$split_lsd_cv,
    anova_table = result$split_anova,
    key_statistics = result$assumptions,
    mean_table = result$split_interaction_means,
    posthoc_summary = result$tukey_main,
    posthoc_table = result$cld_main,
    dataset_preview = head(result$dataset, 20),
    inference_text = "Split-plot mixed model smoke report.",
    report_note = result$report_note,
    plot_errorbar = result$interaction_plot,
    extra_tables = list(
      "Full Mixed-Model ANOVA" = result$full_anova,
      "Additive Mixed-Model ANOVA" = result$additive_anova,
      "Clean Split-Plot ANOVA" = result$split_anova,
      "LSD and CV Summary" = result$split_lsd_cv,
      "Estimated Means - Interaction" = result$emmeans_interaction,
      "Diagnostics" = result$diagnostics
    ),
    extra_text_sections = list("Data Summary" = result$data_summary, "Final Model Summary" = result$final_summary),
    extra_plots = list(
      "Boxplot" = result$boxplot_obj,
      "Estimated Means Interaction Plot" = result$interaction_plot,
      "Main Plot Means with LSD" = result$lsd_main_plot,
      "Subplot Means with LSD" = result$lsd_sub_plot
    ),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
}

pooled_split_plot_params <- function() {
  result <- run_pooled_split_plot(read_pasted_table(pooled_split_plot_example), alpha = 0.05, include_pwpp = TRUE)
  list(
    report_title = "Pooled Split-RCBD Analysis Report",
    design_name = "Pooled Split-RCBD",
    alpha = 0.05,
    comparison_method = "Fisher LSD, unadjusted pairwise contrasts",
    summary_stats = result$cd_summary,
    anova_table = result$anova,
    key_statistics = result$model_info,
    mean_table = result$interaction_means,
    posthoc_summary = result$lsd_main,
    posthoc_table = result$lsd_interaction,
    dataset_preview = head(result$dataset, 20),
    inference_text = "Comparison-specific CD = qt(1 - alpha / 2, df) * SE.",
    report_note = result$report_note,
    plot_errorbar = result$interaction_plot,
    extra_tables = list(
      "Critical Difference Summary" = result$cd_summary,
      "Fisher LSD - Interaction Cells" = result$lsd_interaction,
      "Fisher LSD - Subplot Within Main Plot" = result$lsd_sub_within_main,
      "Fisher LSD - Main Plot Within Subplot" = result$lsd_main_within_sub
    ),
    extra_text_sections = list("Mixed-Model Summary" = result$model_summary),
    extra_plots = list("Interaction Pairwise P-Value Plot (PWPP)" = result$pwpp_plot),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
}

correlation_params <- function() {
  result <- run_correlation_regression(read_pasted_table(correlation_example), "Yield", c("Rainfall", "Nitrogen"))
  list(
    report_title = "Correlation and Regression Report",
    design_name = "Correlation & Regression",
    alpha = 0.05,
    comparison_method = "Correlation plot: color, lower, original",
    summary_stats = result$fit,
    anova_table = result$correlation,
    key_statistics = result$coefficients,
    mean_table = result$diagnostics,
    dataset_preview = head(result$dataset, 20),
    inference_text = result$report_note,
    report_note = result$report_note,
    extra_tables = list(
      "Correlation Matrix" = result$correlation,
      "Correlation P-values" = result$correlation_p,
      "Regression Coefficients" = result$coefficients,
      "Fit Statistics" = result$fit,
      "Diagnostics" = result$diagnostics
    ),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
}

met_params <- function() {
  met_pkgs <- c("metan", "lme4", "lmerTest")
  if (!all(vapply(met_pkgs, requireNamespace, logical(1), quietly = TRUE))) {
    message("Skipping MET report smoke test; missing packages: ", paste(met_pkgs[!vapply(met_pkgs, requireNamespace, logical(1), quietly = TRUE)], collapse = ", "))
    return(NULL)
  }
  result <- run_met_analysis(
    read_pasted_table(met_example),
    gen_col = "GEN",
    env_col = "ENV",
    rep_col = "REP",
    trait_col = "Yield",
    alpha = 0.05,
    direction = "h"
  )
  genotype_plot <- ggplot2::ggplot(result$gen_means, ggplot2::aes(x = stats::reorder(Genotype, Mean), y = Mean, fill = Mean)) +
    ggplot2::geom_col(alpha = 0.9) +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_gradient(low = "#a8d5a2", high = "#1f4d3b") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "none") +
    ggplot2::labs(title = "Genotype means for Yield", x = "Genotype", y = "Mean")
  list(
    report_title = "MET Stability Report - Yield",
    design_name = "MET Stability",
    alpha = 0.05,
    comparison_method = result$direction_label,
    summary_stats = result$gen_means,
    anova_table = result$comb_anova,
    key_statistics = result$waasb$scores,
    mean_table = result$blup,
    posthoc_summary = result$ssi$full,
    posthoc_table = result$ssi$culled,
    dataset_preview = head(result$dataset, 20),
    inference_text = result$report_note,
    report_note = result$report_note,
    plot_errorbar = genotype_plot,
    extra_tables = met_result_tables(result),
    extra_text_sections = list("Model Notes" = result$warnings),
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  )
}

reports <- list(
  "Design Randomizer" = design_layout_params(),
  "CRD RBD" = crd_rbd_params(),
  "Descriptive Statistics" = descriptive_params(),
  "Compare Means" = compare_means_params(),
  "Factorial Design" = factorial_params(),
  "Pooled ANOVA" = pooled_params(),
  "Pooled Split Plot" = pooled_split_plot_params(),
  "Split Plot" = split_plot_params(),
  "Correlation Regression" = correlation_params()
)

met_report <- met_params()
if (!is.null(met_report)) {
  reports[["MET Stability"]] <- met_report
}

for (label in names(reports)) {
  render_report_pair(label, reports[[label]])
}

pooled_split_html <- tempfile(pattern = "pooled-split-plot-", fileext = ".html")
pooled_split_html_params <- pooled_split_plot_params()
save_html_report(
  pooled_split_html_params$report_title,
  list(
    list(title = "Pooled Split-RCBD ANOVA", table = pooled_split_html_params$anova_table),
    list(title = "Interaction Pairwise P-Value Plot (PWPP)", plot = pooled_split_html_params$extra_plots[[1]])
  ),
  pooled_split_html
)
assert_rendered(pooled_split_html, "Pooled Split Plot HTML report")

cat("All report smoke tests passed.\n")
