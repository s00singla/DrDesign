library(dplyr)
library(tidyr)
library(agricolae)
library(desplot)
library(ggplot2)
library(emmeans)
library(multcomp)
library(multcompView)
library(car)
library(lme4)
library(lmerTest)

default_data <- list(
  CRD = "trt\tRep1\tRep2\tRep3\nT1\t25.4\t26.1\t24.8\nT2\t28.2\t27.5\t29.1\nT3\t21.0\t22.4\t20.8\nT4\t30.5\t31.2\t30.9",
  RBD = "trt\tRep1\tRep2\tRep3\nT1\t25.4\t26.1\t24.8\nT2\t28.2\t27.5\t29.1\nT3\t21.0\t22.4\t20.8\nT4\t30.5\t31.2\t30.9",
  `Factorial CRD` = "trt\tRep1\tRep2\tRep3\nA1B1\t25.4\t26.1\t24.8\nA1B2\t28.2\t27.5\t29.1\nA2B1\t21.0\t22.4\t20.8\nA2B2\t30.5\t31.2\t30.9",
  `Factorial RBD` = "trt\tRep1\tRep2\tRep3\nA1B1\t25.4\t26.1\t24.8\nA1B2\t28.2\t27.5\t29.1\nA2B1\t21.0\t22.4\t20.8\nA2B2\t30.5\t31.2\t30.9",
  `Descriptive Statistics` = "Group\tYield\tHeight\nA\t42.1\t120\nB\t45.3\t125\nA\t40.2\t118\nB\t46.7\t128",
  `Compare Means` = "Group\tValue\nControl\t25.4\nControl\t26.1\nTreatment\t28.2\nTreatment\t27.5\nControl\t24.9\nTreatment\t29.0"
)

pooled_example <- "Season\tRep\tTreatment\tValue\nKharif-2024\tR1\tT1\t25.4\nKharif-2024\tR2\tT1\t26.1\nKharif-2024\tR1\tT2\t28.2\nKharif-2024\tR2\tT2\t27.8\nRabi-2025\tR1\tT1\t24.9\nRabi-2025\tR2\tT1\t25.5\nRabi-2025\tR1\tT2\t29.0\nRabi-2025\tR2\tT2\t28.6"
split_plot_example <- "Rep\tMainPlot\tSubPlot\tValue\nR1\tI1\tV1\t28.1\nR1\tI1\tV2\t31.5\nR1\tI2\tV1\t30.2\nR1\tI2\tV2\t34.6\nR2\tI1\tV1\t27.4\nR2\tI1\tV2\t30.8\nR2\tI2\tV1\t29.9\nR2\tI2\tV2\t33.8"
correlation_example <- "Yield\tRainfall\tNitrogen\tPlantHeight\n42.1\t740\t90\t112\n45.0\t780\t100\t116\n39.8\t690\t85\t109\n50.3\t820\t110\t122\n47.4\t800\t105\t118"

correlation_p_matrix <- function(df, conf.level = 0.95) {
  mat <- as.matrix(df)
  n <- ncol(mat)
  p_mat <- matrix(0, n, n)
  colnames(p_mat) <- colnames(mat)
  rownames(p_mat) <- colnames(mat)

  if (n < 2) {
    return(p_mat)
  }

  for (i in seq_len(n - 1)) {
    for (j in seq.int(i + 1, n)) {
      test_result <- suppressWarnings(stats::cor.test(mat[, i], mat[, j], conf.level = conf.level))
      p_mat[i, j] <- test_result$p.value
      p_mat[j, i] <- test_result$p.value
    }
  }

  p_mat
}

summarize_numeric_columns <- function(df, vars = names(df)) {
  numeric_vars <- vars[vapply(df[vars], is.numeric, logical(1))]
  if (length(numeric_vars) == 0) {
    stop("No numeric variables found for descriptive analysis.")
  }
  out <- lapply(numeric_vars, function(name) {
    col <- df[[name]]
    data.frame(
      Variable = name,
      N = sum(!is.na(col)),
      Mean = mean(col, na.rm = TRUE),
      SD = stats::sd(col, na.rm = TRUE),
      Min = min(col, na.rm = TRUE),
      Max = max(col, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

run_descriptive_analysis <- function(df, analysis_type, selected_vars = NULL, group_var = NULL) {
  df <- normalize_columns(df)
  numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]
  if (length(numeric_cols) == 0) {
    stop("Upload a dataset with numeric columns to continue.")
  }

  if (is.null(selected_vars) || length(selected_vars) == 0) {
    selected_vars <- numeric_cols
  }
  selected_vars <- intersect(selected_vars, numeric_cols)
  if (length(selected_vars) == 0) {
    stop("Select at least one numeric variable.")
  }

  summary_table <- summarize_numeric_columns(df, selected_vars)
  by_group <- data.frame()
  plot_obj <- NULL
  normality <- "Select a normality check or plot in the tabs above."

  if (analysis_type == "sumbygrp") {
    if (is.null(group_var) || !nzchar(group_var) || !(group_var %in% names(df))) {
      stop("Select a valid group variable for grouped summary.")
    }
    by_group <- df %>%
      select(all_of(c(group_var, selected_vars))) %>%
      pivot_longer(-all_of(group_var), names_to = "Variable", values_to = "Value") %>%
      group_by(across(all_of(group_var)), Variable) %>%
      summarise(
        N = sum(!is.na(Value)),
        Mean = mean(Value, na.rm = TRUE),
        SD = stats::sd(Value, na.rm = TRUE),
        Min = min(Value, na.rm = TRUE),
        Max = max(Value, na.rm = TRUE),
        .groups = "drop"
      )
  }

  analysis_var <- selected_vars[[1]]
  if (analysis_type == "boxplot") {
    if (!is.null(group_var) && nzchar(group_var) && group_var %in% names(df)) {
      plot_obj <- ggplot(df, aes_string(x = group_var, y = analysis_var, fill = group_var)) +
        geom_boxplot(alpha = 0.85) +
        theme_minimal() +
        labs(title = sprintf("Boxplot of %s by %s", analysis_var, group_var), x = group_var, y = analysis_var) +
        theme(legend.position = "none")
    } else {
      plot_obj <- ggplot(df, aes_string(x = "", y = analysis_var)) +
        geom_boxplot(fill = "#66c2a5", alpha = 0.8) +
        theme_minimal() +
        labs(title = sprintf("Boxplot of %s", analysis_var), x = "", y = analysis_var)
    }
  } else if (analysis_type == "histogram") {
    plot_obj <- ggplot(df, aes_string(x = analysis_var)) +
      geom_histogram(fill = "#1f78b4", color = "#ffffff", bins = 15, alpha = 0.85) +
      theme_minimal() +
      labs(title = sprintf("Histogram of %s", analysis_var), x = analysis_var, y = "Count")
  } else if (analysis_type == "qqplot") {
    plot_obj <- ggplot(df, aes_string(sample = analysis_var)) +
      stat_qq(color = "#1f78b4") +
      stat_qq_line(color = "#d62728") +
      theme_minimal() +
      labs(title = sprintf("Q-Q plot for %s", analysis_var), x = "Theoretical quantiles", y = "Sample quantiles")
  } else if (analysis_type == "nt") {
    values <- df[[analysis_var]]
    if (sum(!is.na(values)) < 3) {
      stop("Normality test requires at least 3 non-missing values.")
    }
    normality_res <- shapiro.test(values)
    normality <- c(
      sprintf("Variable: %s", analysis_var),
      sprintf("W = %.4f", unname(normality_res$statistic)),
      sprintf("p-value = %.4f", normality_res$p.value),
      if (normality_res$p.value >= 0.05) "The distribution is not significantly different from normal." else "The distribution deviates from normality."
    )
    plot_obj <- ggplot(df, aes_string(sample = analysis_var)) +
      stat_qq(color = "#1f78b4") +
      stat_qq_line(color = "#d62728") +
      theme_minimal() +
      labs(title = sprintf("Q-Q plot for %s", analysis_var), x = "Theoretical quantiles", y = "Sample quantiles")
  }

  list(
    dataset = df,
    summary = summary_table,
    by_group = by_group,
    plot_obj = plot_obj,
    normality = normality
  )
}

run_ttest_analysis <- function(df, test_type, value_var = NULL, group_var = NULL, pair_left = NULL, pair_right = NULL, mu = 0, var_equal = TRUE) {
  df <- normalize_columns(df)
  numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]
  if (length(numeric_cols) == 0) {
    stop("Upload a dataset with numeric columns for t-test analysis.")
  }

  if (is.null(value_var) || !value_var %in% names(df)) {
    stop("Select an outcome variable for the t-test.")
  }

  result_summary <- data.frame()
  variance_info <- data.frame()
  test_result <- data.frame()
  plot_obj <- NULL
  dataset <- df

  if (test_type == "one-sample") {
    x <- df[[value_var]]
    x <- na.omit(x)
    if (length(x) < 3) stop("One-sample t-test requires at least 3 non-missing values.")
    res <- t.test(x, mu = mu)
    result_summary <- data.frame(Variable = value_var, N = length(x), Mean = mean(x), SD = sd(x), stringsAsFactors = FALSE)
    variance_info <- data.frame(Statistic = c("Hypothesized mean", "Alternative"), Value = c(mu, res$alternative), stringsAsFactors = FALSE)
    test_result <- data.frame(
      Statistic = c("t statistic", "df", "p value", "Mean difference", "95% lower", "95% upper", "Method"),
      Value = c(round(res$statistic, 4), round(res$parameter, 2), round(res$p.value, 4), round(res$estimate - mu, 4), round(res$conf.int[1], 4), round(res$conf.int[2], 4), res$method),
      stringsAsFactors = FALSE
    )
    plot_obj <- ggplot(data.frame(Value = x), aes(x = Value)) +
      geom_histogram(fill = "#1f78b4", color = "white", bins = 12, alpha = 0.8) +
      theme_minimal() +
      labs(title = sprintf("One-sample distribution for %s", value_var), x = value_var, y = "Count")
  } else if (test_type %in% c("two-sample", "welch")) {
    if (is.null(group_var) || !group_var %in% names(df)) {
      stop("Select a grouping variable for two-sample t-test.")
    }
    df <- df %>% filter(!is.na(.data[[value_var]]), !is.na(.data[[group_var]]))
    groups <- unique(df[[group_var]])
    if (length(groups) != 2) stop("Grouping variable must have exactly two levels for two-sample tests.")
    x <- df[[value_var]]
    g <- factor(df[[group_var]])
    res <- t.test(x ~ g, var.equal = test_type == "two-sample")
    result_summary <- df %>% group_by(.data[[group_var]]) %>% summarise(N = sum(!is.na(.data[[value_var]])), Mean = mean(.data[[value_var]], na.rm = TRUE), SD = sd(.data[[value_var]], na.rm = TRUE), .groups = "drop")
    variance <- var.test(x ~ g)
    variance_info <- data.frame(Statistic = c("F statistic", "df1", "df2", "p value"), Value = c(round(variance$statistic, 4), variance$parameter[1], variance$parameter[2], round(variance$p.value, 4)), stringsAsFactors = FALSE)
    test_result <- data.frame(
      Statistic = c("t statistic", "df", "p value", "Mean difference", "95% lower", "95% upper", "Method"),
      Value = c(round(res$statistic, 4), round(res$parameter, 2), round(res$p.value, 4), round(diff(res$estimate), 4), round(res$conf.int[1], 4), round(res$conf.int[2], 4), res$method),
      stringsAsFactors = FALSE
    )
    plot_obj <- ggplot(df, aes_string(x = group_var, y = value_var, fill = group_var)) +
      geom_boxplot(alpha = 0.85) +
      theme_minimal() +
      theme(legend.position = "none") +
      labs(title = sprintf("%s distribution by %s", ifelse(test_type == "welch", "Welch t-test", "Two-sample t-test"), group_var), x = group_var, y = value_var)
  } else if (test_type == "paired") {
    if (is.null(pair_left) || is.null(pair_right) || !pair_left %in% names(df) || !pair_right %in% names(df)) {
      stop("Select two numeric columns for paired t-test.")
    }
    x <- df[[pair_left]]
    y <- df[[pair_right]]
    if (length(na.omit(x)) < 3 || length(na.omit(y)) < 3) stop("Paired t-test requires at least 3 non-missing values in both columns.")
    paired_df <- data.frame(Left = x, Right = y)
    res <- t.test(paired_df$Left, paired_df$Right, paired = TRUE)
    result_summary <- data.frame(Variable = c(pair_left, pair_right), Mean = c(mean(x, na.rm = TRUE), mean(y, na.rm = TRUE)), SD = c(sd(x, na.rm = TRUE), sd(y, na.rm = TRUE)), N = c(sum(!is.na(x)), sum(!is.na(y))), stringsAsFactors = FALSE)
    variance_info <- data.frame(Statistic = c("Paired t-test"), Value = c(res$method), stringsAsFactors = FALSE)
    test_result <- data.frame(
      Statistic = c("t statistic", "df", "p value", "Mean difference", "95% lower", "95% upper", "Method"),
      Value = c(round(res$statistic, 4), round(res$parameter, 2), round(res$p.value, 4), round(res$estimate[1] - res$estimate[2], 4), round(res$conf.int[1], 4), round(res$conf.int[2], 4), res$method),
      stringsAsFactors = FALSE
    )
    plot_obj <- ggplot(paired_df, aes(x = Left, y = Right)) +
      geom_point(color = "#1f78b4", size = 2) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "#d62728") +
      theme_minimal() +
      labs(title = sprintf("Paired plot for %s and %s", pair_left, pair_right), x = pair_left, y = pair_right)
  } else {
    stop("Unsupported t-test type.")
  }

  list(
    dataset = dataset,
    summary = result_summary,
    variance = variance_info,
    test_result = test_result,
    plot_obj = plot_obj
  )
}

format_anova_table <- function(model) {
  out <- as.data.frame(anova(model))
  out$Term <- rownames(out)
  rownames(out) <- NULL
  out
}

run_multiple_comparison <- function(model, treatment_term, method = "LSD", alpha = 0.05) {
  method_key <- toupper(method)

  result <- switch(
    method_key,
    LSD = agricolae::LSD.test(model, treatment_term, alpha = alpha, console = FALSE),
    DMRT = agricolae::duncan.test(model, treatment_term, alpha = alpha, group = TRUE, console = FALSE),
    TUKEY = agricolae::HSD.test(model, treatment_term, alpha = alpha, group = TRUE, console = FALSE),
    stop(sprintf("Unsupported comparison method: %s", method))
  )

  result$method_label <- switch(method_key, LSD = "LSD", DMRT = "DMRT", TUKEY = "Tukey", method_key)
  result
}

build_treatment_summary <- function(df_long, treatment_col = "Trt", alpha = 0.05) {
  z_value <- qnorm(1 - alpha / 2)
  split_values <- split(df_long$Value, df_long[[treatment_col]])

  out <- do.call(rbind, lapply(names(split_values), function(name) {
    values <- as.numeric(split_values[[name]])
    mean_value <- mean(values, na.rm = TRUE)
    sd_value <- stats::sd(values, na.rm = TRUE)
    n_value <- sum(!is.na(values))
    se_value <- sd_value / sqrt(n_value)
    data.frame(
      Treatment = name,
      Mean = mean_value,
      SD = sd_value,
      N = n_value,
      SE = se_value,
      LowerCI = mean_value - z_value * se_value,
      UpperCI = mean_value + z_value * se_value,
      stringsAsFactors = FALSE
    )
  }))

  rownames(out) <- NULL
  out
}

run_design_analysis <- function(df, design, levels_a = 2, levels_b = 2, alpha = 0.05, comparison_method = "LSD") {
  validate(need(ncol(df) >= 3, "Data must include a treatment column and at least two replication columns."))
  colnames(df)[1] <- "Trt"
  trt_order <- df$Trt

  if (design %in% c("Factorial CRD", "Factorial RBD")) {
    expected_rows <- levels_a * levels_b
    validate(need(nrow(df) == expected_rows, sprintf("Expected %s rows from %s x %s factorial levels, found %s.", expected_rows, levels_a, levels_b, nrow(df))))
  }

  df_long <- pivot_longer(df, cols = -1, names_to = "Rep", values_to = "Value")
  df_long$Rep <- factor(df_long$Rep)
  df_long$Value <- as.numeric(df_long$Value)
  validate(need(!any(is.na(df_long$Value)), "All replication columns must be numeric."))

  if (design %in% c("Factorial CRD", "Factorial RBD")) {
    mapping <- data.frame(
      Trt = trt_order,
      FactA = factor(rep(paste0("A", seq_len(levels_a)), each = levels_b)),
      FactB = factor(rep(paste0("B", seq_len(levels_b)), times = levels_a)),
      stringsAsFactors = FALSE
    )
    df_long <- merge(df_long, mapping, by = "Trt", sort = FALSE)
  } else {
    df_long$Trt <- factor(df_long$Trt, levels = trt_order)
  }

  model <- switch(
    design,
    "CRD" = aov(Value ~ Trt, data = df_long),
    "RBD" = aov(Value ~ Rep + Trt, data = df_long),
    "Factorial CRD" = aov(Value ~ FactA * FactB, data = df_long),
    "Factorial RBD" = aov(Value ~ Rep + FactA * FactB, data = df_long)
  )

  comparison <- if (design %in% c("CRD", "RBD")) {
    run_multiple_comparison(model, "Trt", method = comparison_method, alpha = alpha)
  } else {
    LSD.test(model, c("FactA", "FactB"), alpha = alpha, console = FALSE)
  }

  aov_sum <- anova(model)
  mse <- aov_sum["Residuals", "Mean Sq"]
  reps <- length(unique(df_long$Rep))
  grand_mean <- mean(df_long$Value)
  stats <- data.frame(
    Statistic = c("Replications detected", "Grand Mean", "Mean Square Error (MSE)", "Standard Error of Mean - SE(m)", "Standard Error of Difference - SE(d)", "Coefficient of Variation - CV (%)"),
    Value = round(c(reps, grand_mean, mse, sqrt(mse / reps), sqrt(2 * mse / reps), (sqrt(mse) / grand_mean) * 100), 4),
    stringsAsFactors = FALSE
  )

  means <- comparison$means
  groups <- comparison$groups
  treatment_summary <- if (design %in% c("CRD", "RBD")) build_treatment_summary(df_long, "Trt", alpha = alpha) else NULL

  inference <- ""
  if (design %in% c("CRD", "RBD")) {
    p_val <- aov_sum["Trt", "Pr(>F)"]
    if (!is.na(p_val)) {
      if (p_val <= alpha) {
        inference <- sprintf("Since the P-value in ANOVA table is <= %s, there is a significant difference between at least a pair of treatments, so multiple comparison is required to identify best treatment(s). Treatments with same letters are not significantly different.", alpha)
      } else {
        inference <- "Treatment means are not significantly different. Multiple comparison test is not performed."
      }
    }
  }

  factorial_details <- NULL
  if (design %in% c("Factorial CRD", "Factorial RBD")) {
    needed_packages <- c("ggplot2", "emmeans", "multcomp", "multcompView", "car")
    missing_packages <- needed_packages[!vapply(needed_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
    validate(need(
      length(missing_packages) == 0,
      paste(
        "Missing package(s):",
        paste(missing_packages, collapse = ", "),
        ". Install them in this R environment with install.packages(c(",
        paste(sprintf("'%s'", missing_packages), collapse = ", "),
        "), repos = 'https://cloud.r-project.org')"
      )
    ))

    full_model <- model
    additive_model <- switch(
      design,
      "Factorial CRD" = aov(Value ~ FactA + FactB, data = df_long),
      "Factorial RBD" = aov(Value ~ Rep + FactA + FactB, data = df_long)
    )

    full_anova <- format_anova_table(full_model)
    additive_anova <- format_anova_table(additive_model)
    interaction_p <- full_anova$`Pr(>F)`[full_anova$Term == "FactA:FactB"]
    interaction_p_value <- if (length(interaction_p) == 1) interaction_p[[1]] else NA_real_
    use_additive_model <- !is.na(interaction_p_value) && interaction_p_value >= alpha
    final_model <- if (use_additive_model) additive_model else full_model
    final_model_name <- if (use_additive_model) "Additive model" else "Interaction model"

    emm_interaction <- emmeans::emmeans(full_model, ~ FactA * FactB)
    emm_a <- emmeans::emmeans(additive_model, ~ FactA)
    emm_b <- emmeans::emmeans(additive_model, ~ FactB)

    tukey_interaction <- as.data.frame(pairs(emm_interaction, adjust = "tukey"))
    tukey_a <- as.data.frame(pairs(emm_a, adjust = "tukey"))
    tukey_b <- as.data.frame(pairs(emm_b, adjust = "tukey"))

    cld_interaction <- as.data.frame(multcomp::cld(emm_interaction, Letters = letters, adjust = "tukey"))
    cld_a <- as.data.frame(multcomp::cld(emm_a, Letters = letters, adjust = "tukey"))
    cld_b <- as.data.frame(multcomp::cld(emm_b, Letters = letters, adjust = "tukey"))

    boxplot_obj <- ggplot2::ggplot(df_long, ggplot2::aes(x = FactA, y = Value, fill = FactB)) +
      ggplot2::geom_boxplot() +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Boxplot of Response by Factors A and B", x = "Factor A", y = "Response")

    observed_interaction_plot <- ggplot2::ggplot(df_long, ggplot2::aes(x = FactA, y = Value, color = FactB, group = FactB)) +
      ggplot2::stat_summary(fun = mean, geom = "line", linewidth = 1) +
      ggplot2::stat_summary(fun = mean, geom = "point", size = 3) +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Interaction Plot (Observed Means)", x = "Factor A", y = "Response", color = "Factor B")

    emm_interaction_df <- as.data.frame(emm_interaction)
    emm_a_df <- as.data.frame(emm_a)
    emm_b_df <- as.data.frame(emm_b)

    emm_interaction_plot <- ggplot2::ggplot(emm_interaction_df, ggplot2::aes(x = FactA, y = emmean, color = FactB, group = FactB)) +
      ggplot2::geom_line(linewidth = 1) +
      ggplot2::geom_point(size = 3) +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Interaction Plot (Estimated Marginal Means)", x = "Factor A", y = "Estimated mean", color = "Factor B")

    emm_a_plot <- ggplot2::ggplot(emm_a_df, ggplot2::aes(x = FactA, y = emmean, ymin = lower.CL, ymax = upper.CL)) +
      ggplot2::geom_pointrange(color = "#1f4d3b", size = 0.5) +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Factor A Effects", x = "Factor A", y = "Estimated mean")

    emm_b_plot <- ggplot2::ggplot(emm_b_df, ggplot2::aes(x = FactB, y = emmean, ymin = lower.CL, ymax = upper.CL)) +
      ggplot2::geom_pointrange(color = "#7a5c1e", size = 0.5) +
      ggplot2::theme_minimal() +
      ggplot2::labs(title = "Factor B Effects", x = "Factor B", y = "Estimated mean")

    residuals_full <- residuals(full_model)
    fitted_full <- fitted(full_model)
    shapiro_out <- shapiro.test(residuals_full)
    levene_out <- car::leveneTest(Value ~ interaction(FactA, FactB), data = df_long)
    levene_df <- data.frame(Term = rownames(levene_out), levene_out, row.names = NULL, check.names = FALSE)

    factorial_details <- list(
      data_summary = capture.output(summary(df_long)),
      full_anova = full_anova,
      additive_anova = additive_anova,
      final_summary = capture.output(summary(final_model)),
      assumptions = data.frame(
        Metric = c("Alpha", "Interaction p-value", "Selected final model"),
        Value = c(alpha, ifelse(is.na(interaction_p_value), "NA", round(interaction_p_value, 4)), final_model_name),
        stringsAsFactors = FALSE
      ),
      shapiro = data.frame(
        Metric = c("W statistic", "p-value"),
        Value = c(round(unname(shapiro_out$statistic), 4), round(shapiro_out$p.value, 4)),
        stringsAsFactors = FALSE
      ),
      levene = levene_df,
      diagnostics = data.frame(
        Observation = seq_along(residuals_full),
        Fitted = fitted_full,
        Residual = residuals_full,
        stringsAsFactors = FALSE
      ),
      emmeans_interaction = emm_interaction_df,
      emmeans_a = emm_a_df,
      emmeans_b = emm_b_df,
      tukey_interaction = tukey_interaction,
      tukey_a = tukey_a,
      tukey_b = tukey_b,
      cld_interaction = cld_interaction,
      cld_a = cld_a,
      cld_b = cld_b,
      boxplot_obj = boxplot_obj,
      observed_interaction_plot = observed_interaction_plot,
      emm_interaction_plot = emm_interaction_plot,
      emm_a_plot = emm_a_plot,
      emm_b_plot = emm_b_plot,
      residuals = residuals_full,
      fitted = fitted_full
    )
  }

  list(
    dataset = df_long,
    anova = format_anova_table(model),
    stats = stats,
    means = data.frame(Treatment = rownames(means), means, row.names = NULL, stringsAsFactors = FALSE),
    groups = data.frame(Treatment = rownames(groups), groups, row.names = NULL, stringsAsFactors = FALSE),
    lsd_stats = metrics_table(comparison$statistics),
    comparison_method = comparison$method_label %||% comparison_method,
    treatment_summary = treatment_summary,
    inference = inference,
    report_note = sprintf("Model: %s at alpha %.2f using %s comparisons", design, alpha, comparison$method_label %||% comparison_method),
    factorial = factorial_details
  )
}

run_design_layout <- function(
    design,
    seed = 1,
    trt = NULL,
    rep = NULL,
    main_trt = NULL,
    sub_trt = NULL,
    checks = NULL,
    test_trt = NULL) {
  kind <- "Super-Duper"

  if (identical(design, "CRD")) {
    validate(need(!is.null(trt) && trt >= 2, "CRD needs at least two treatments."))
    validate(need(!is.null(rep) && rep >= 2, "CRD needs at least two replications."))
    trt_labels <- sprintf("T%s", seq_len(trt))
    fieldbook <- agricolae::design.crd(trt_labels, r = rep, seed = seed, serie = 0, kinds = kind, randomization = TRUE)$book
    fieldbook <- fieldbook[order(fieldbook$r), , drop = FALSE]
    fieldbook$ExperimentalUnit <- seq_len(nrow(fieldbook))
    plot_data <- transform(fieldbook, row = 1, col = ExperimentalUnit, label = as.character(trtname))
    list(
      design = design,
      summary = data.frame(Treatments = trt, Replications = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(ExperimentalUnit = fieldbook$ExperimentalUnit, Treatment = as.character(fieldbook$trtname), stringsAsFactors = FALSE),
      plot_data = plot_data
    )
  } else if (identical(design, "RBD")) {
    validate(need(!is.null(trt) && trt >= 2, "RBD needs at least two treatments."))
    validate(need(!is.null(rep) && rep >= 2, "RBD needs at least two blocks."))
    trt_labels <- sprintf("T%s", seq_len(trt))
    fieldbook <- agricolae::design.rcbd(trt = trt_labels, r = rep, seed = seed, serie = 0, kinds = kind, randomization = TRUE)$book
    fieldbook <- fieldbook[order(fieldbook$block), , drop = FALSE]
    fieldbook$Plot <- ave(seq_len(nrow(fieldbook)), fieldbook$block, FUN = seq_along)
    plot_data <- transform(fieldbook, block_num = as.numeric(block), plot_num = Plot, label = as.character(trtname))
    list(
      design = design,
      summary = data.frame(Treatments = trt, Blocks = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(Block = as.character(fieldbook$block), Plot = fieldbook$Plot, Treatment = as.character(fieldbook$trtname), stringsAsFactors = FALSE),
      plot_data = plot_data
    )
  } else if (identical(design, "Augmented RCBD")) {
    validate(need(!is.null(checks) && checks >= 2, "Augmented RCBD needs at least two checks."))
    validate(need(!is.null(test_trt) && test_trt >= 2, "Augmented RCBD needs at least two test treatments."))
    validate(need(!is.null(rep) && rep >= 2, "Augmented RCBD needs at least two blocks."))
    check_labels <- sprintf("C%s", seq_len(checks))
    test_labels <- sprintf("T%s", seq_len(test_trt))
    fieldbook <- agricolae::design.dau(check_labels, test_labels, r = rep, seed = seed, serie = 0, randomization = TRUE)$book
    fieldbook <- fieldbook[order(fieldbook$block), , drop = FALSE]
    fieldbook$Plot <- ave(seq_len(nrow(fieldbook)), fieldbook$block, FUN = seq_along)
    plot_data <- transform(fieldbook, block_num = as.numeric(block), plot_num = Plot, label = as.character(trt))
    list(
      design = design,
      summary = data.frame(Checks = checks, TestTreatments = test_trt, Blocks = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(Block = as.character(fieldbook$block), Plot = fieldbook$Plot, Treatment = as.character(fieldbook$trt), stringsAsFactors = FALSE),
      plot_data = plot_data
    )
  } else if (identical(design, "Split Plot")) {
    validate(need(!is.null(main_trt) && main_trt >= 2, "Split plot needs at least two main-plot treatments."))
    validate(need(!is.null(sub_trt) && sub_trt >= 2, "Split plot needs at least two subplot treatments."))
    validate(need(!is.null(rep) && rep >= 2, "Split plot needs at least two replications."))
    main_labels <- sprintf("A%s", seq_len(main_trt))
    sub_labels <- sprintf("B%s", seq_len(sub_trt))
    fieldbook <- agricolae::design.split(main_labels, sub_labels, r = rep, serie = 0, seed = seed, kinds = kind, randomization = TRUE)$book
    fieldbook <- fieldbook[order(fieldbook$block, fieldbook$plots, fieldbook$splots), , drop = FALSE]
    plot_data <- transform(fieldbook, rep_num = as.numeric(block), main_num = as.numeric(plots), sub_num = as.numeric(splots), label = sprintf("%s/%s", as.character(main), as.character(sub)))
    list(
      design = design,
      summary = data.frame(MainPlotTreatments = main_trt, SubPlotTreatments = sub_trt, Replications = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(Replication = as.character(fieldbook$block), MainPlot = fieldbook$plots, SubPlot = fieldbook$splots, MainTreatment = as.character(fieldbook$main), SubTreatment = as.character(fieldbook$sub), stringsAsFactors = FALSE),
      plot_data = plot_data
    )
  } else if (identical(design, "Strip Plot")) {
    validate(need(!is.null(main_trt) && main_trt >= 2, "Strip plot needs at least two horizontal treatments."))
    validate(need(!is.null(sub_trt) && sub_trt >= 2, "Strip plot needs at least two vertical treatments."))
    validate(need(!is.null(rep) && rep >= 2, "Strip plot needs at least two replications."))
    main_labels <- sprintf("A%s", seq_len(main_trt))
    sub_labels <- sprintf("B%s", seq_len(sub_trt))
    fieldbook <- agricolae::design.strip(main_labels, sub_labels, r = rep, serie = 0, seed = seed, kinds = kind, randomization = TRUE)$book
    fieldbook$row_key <- do.call(paste, as.data.frame(t(apply(fieldbook[4:5], 1, sort))))
    fieldbook$col_key <- do.call(paste, as.data.frame(t(apply(fieldbook[2:3], 1, sort))))
    fieldbook$Row <- match(fieldbook$row_key, unique(fieldbook$row_key))
    fieldbook$Column <- match(fieldbook$col_key, unique(fieldbook$col_key))
    plot_data <- transform(fieldbook, rep_num = as.numeric(block), row_num = Row, col_num = Column, label = sprintf("%s/%s", as.character(main1), as.character(main2)))
    list(
      design = design,
      summary = data.frame(HorizontalTreatments = main_trt, VerticalTreatments = sub_trt, Replications = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(Replication = as.character(fieldbook$block), Row = fieldbook$Row, Column = fieldbook$Column, HorizontalTreatment = as.character(fieldbook$main1), VerticalTreatment = as.character(fieldbook$main2), stringsAsFactors = FALSE),
      plot_data = plot_data
    )
  } else {
    stop(sprintf("Unsupported layout design: %s", design))
  }
}

run_pooled_anova <- function(df, alpha = 0.05) {
  required <- c("Season", "Treatment", "Value")
  validate(need(all(required %in% names(df)), "Columns Season, Treatment, and Value are required."))

  if (!("Rep" %in% names(df))) {
    df$Rep <- "R1"
  }

  df <- df %>%
    mutate(Season = factor(Season), Rep = factor(Rep), Treatment = factor(Treatment), Value = as.numeric(Value))
  validate(need(!any(is.na(df$Value)), "Value must be numeric."))

  season_models <- lapply(split(df, df$Season), function(part) {
    if (nlevels(part$Rep) > 1) aov(Value ~ Rep + Treatment, data = part) else aov(Value ~ Treatment, data = part)
  })

  error_summary <- data.frame(
    Season = names(season_models),
    ErrorMS = vapply(season_models, function(m) anova(m)["Residuals", "Mean Sq"], numeric(1)),
    stringsAsFactors = FALSE
  )

  homogeneity <- bartlett.test(Value ~ Season, data = df)
  pooled_model <- aov(Value ~ Season + Season:Rep + Treatment + Season:Treatment, data = df)

  list(
    dataset = df,
    anova = format_anova_table(pooled_model),
    error_summary = error_summary,
    homogeneity = data.frame(
      Metric = c("Bartlett K-squared", "df", "p-value", "Pool errors"),
      Value = c(round(unname(homogeneity$statistic), 4), homogeneity$parameter, round(homogeneity$p.value, 4), ifelse(homogeneity$p.value >= alpha, "Yes", "Investigate before pooling")),
      stringsAsFactors = FALSE
    ),
    treatment_means = df %>% group_by(Treatment) %>% summarise(Mean = mean(Value), .groups = "drop"),
    season_treatment_means = df %>% group_by(Season, Treatment) %>% summarise(Mean = mean(Value), .groups = "drop"),
    report_note = sprintf("Pooled across %s seasons at alpha %.2f", nlevels(df$Season), alpha)
  )
}

split_plot_analysis <- function(data, alpha = 0.05) {
  required <- c("Rep", "MainPlot", "SubPlot", "Value")
  validate(need(all(required %in% names(data)), "Columns Rep/MainPlot/SubPlot/Value are required."))

  data <- data %>%
    mutate(
      Rep = factor(Rep),
      MainPlot = factor(MainPlot),
      SubPlot = factor(SubPlot),
      Value = as.numeric(Value)
    )
  validate(need(!any(is.na(data$Value)), "Value must be numeric."))

  model <- aov(Value ~ MainPlot * SubPlot + Error(Rep/MainPlot), data = data)
  sp <- summary(model)

  strata_names <- names(sp)
  rep_stratum <- strata_names[grepl("Error:.*Rep", strata_names)][1]
  main_stratum <- strata_names[grepl("MainPlot", strata_names)][1]
  within_stratum <- strata_names[grepl("Within", strata_names)][1]

  rep_tab <- sp[[rep_stratum]][[1]]
  main_tab <- sp[[main_stratum]][[1]]
  sub_tab <- sp[[within_stratum]][[1]]

  main_effect <- gsub(" ", "", rownames(main_tab)[1])
  subplot_effect <- gsub(" ", "", rownames(sub_tab)[1])
  interaction_effect <- gsub(" ", "", rownames(sub_tab)[2])

  anova_table <- data.frame(
    Source = c(
      "Replication",
      main_effect,
      "Error(a)",
      subplot_effect,
      interaction_effect,
      "Error(b)"
    ),
    df = c(
      rep_tab$Df[1],
      main_tab$Df[1],
      main_tab$Df[2],
      sub_tab$Df[1],
      sub_tab$Df[2],
      sub_tab$Df[3]
    ),
    `Sum Sq` = c(
      rep_tab$`Sum Sq`[1],
      main_tab$`Sum Sq`[1],
      main_tab$`Sum Sq`[2],
      sub_tab$`Sum Sq`[1],
      sub_tab$`Sum Sq`[2],
      sub_tab$`Sum Sq`[3]
    ),
    `Mean Sq` = c(
      rep_tab$`Mean Sq`[1],
      main_tab$`Mean Sq`[1],
      main_tab$`Mean Sq`[2],
      sub_tab$`Mean Sq`[1],
      sub_tab$`Mean Sq`[2],
      sub_tab$`Mean Sq`[3]
    ),
    `F value` = c(
      NA,
      main_tab$`F value`[1],
      NA,
      sub_tab$`F value`[1],
      sub_tab$`F value`[2],
      NA
    ),
    `Pr(>F)` = c(
      NA,
      ifelse(main_tab$`Pr(>F)`[1] < 0.001, "<0.001", round(main_tab$`Pr(>F)`[1], 4)),
      NA,
      ifelse(sub_tab$`Pr(>F)`[1] < 0.001, "<0.001", round(sub_tab$`Pr(>F)`[1], 4)),
      ifelse(sub_tab$`Pr(>F)`[2] < 0.001, "<0.001", round(sub_tab$`Pr(>F)`[2], 4)),
      NA
    ),
    stringsAsFactors = FALSE
  )
  anova_table[, 2:5] <- round(anova_table[, 2:5], 3)

  Ea <- main_tab$`Mean Sq`[2]
  dfa <- main_tab$Df[2]
  Eb <- sub_tab$`Mean Sq`[3]
  dfb <- sub_tab$Df[3]

  r <- nlevels(as.factor(data$Rep))
  a <- nlevels(as.factor(data$MainPlot))
  b <- nlevels(as.factor(data$SubPlot))
  grand_mean <- mean(data$Value, na.rm = TRUE)

  t_a <- qt(1 - alpha / 2, dfa)
  SEm_main <- sqrt((2 * Ea) / (r * b))
  LSD_main <- t_a * SEm_main

  t_b <- qt(1 - alpha / 2, dfb)
  SEm_sub <- sqrt((2 * Eb) / (r * a))
  LSD_sub <- t_b * SEm_sub

  SEm_interaction <- sqrt((2 * Eb) / r)
  LSD_interaction <- t_b * SEm_interaction

  tw <- (((b - 1) * Eb * t_b) + (Ea * t_a)) / (((b - 1) * Eb) + Ea)
  SEm_type4 <- sqrt((2 * (((b - 1) * Eb) + Ea)) / (r * b))
  LSD_type4 <- tw * SEm_type4

  CV_main <- sqrt(Ea) / grand_mean * 100
  CV_sub <- sqrt(Eb) / grand_mean * 100

  main_means <- aggregate(data$Value, list(data$MainPlot), mean)
  names(main_means) <- c("MainPlot", "Mean")

  subplot_means <- aggregate(data$Value, list(data$SubPlot), mean)
  names(subplot_means) <- c("SubPlot", "Mean")

  interaction_means <- aggregate(data$Value, list(data$MainPlot, data$SubPlot), mean)
  names(interaction_means) <- c("MainPlot", "SubPlot", "Mean")

  list(
    ANOVA = anova_table,
    MainPlotMeans = main_means,
    SubPlotMeans = subplot_means,
    InteractionMeans = interaction_means,
    LSD = list(
      MainPlot = list(
        Factor = "MainPlot",
        ErrorMS = Ea,
        DF = dfa,
        SED = SEm_main,
        LSD = LSD_main
      ),
      SubPlot = list(
        Factor = "SubPlot",
        ErrorMS = Eb,
        DF = dfb,
        SED = SEm_sub,
        LSD = LSD_sub
      ),
      Interaction = list(
        Comparison = "Subplot within MainPlot",
        ErrorMS = Eb,
        DF = dfb,
        SED = SEm_interaction,
        LSD = LSD_interaction
      ),
      Interaction2 = list(
        Comparison = "Two main-plot means at same/different subplot levels",
        ErrorA = Ea,
        ErrorB = Eb,
        DFa = dfa,
        DFb = dfb,
        Weighted_t_value = tw,
        SED = SEm_type4,
        LSD = LSD_type4
      )
    ),
    CV = list(
      MainPlotCV = CV_main,
      SubPlotCV = CV_sub
    )
  )
}

run_split_plot <- function(df, rep_var = "Rep", mainplot_var = "MainPlot", subplot_var = "SubPlot", response_var = "Value", alpha = 0.05) {
  needed_packages <- c("lme4", "lmerTest", "emmeans", "ggplot2", "multcomp", "multcompView")
  missing_packages <- needed_packages[!vapply(needed_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
  validate(need(
    length(missing_packages) == 0,
    paste(
      "Missing package(s):",
      paste(missing_packages, collapse = ", "),
      ". Install them in this R environment with install.packages(c(",
      paste(sprintf("'%s'", missing_packages), collapse = ", "),
      "), repos = 'https://cloud.r-project.org')"
    )
  ))

  rename_map <- c(W = "Rep", A = "MainPlot", B = "SubPlot", Y = "Value")
  for (old_name in names(rename_map)) {
    new_name <- rename_map[[old_name]]
    if (old_name %in% names(df) && !(new_name %in% names(df))) {
      names(df)[names(df) == old_name] <- new_name
    }
  }

  if (!identical(rep_var, "Rep") && !is.null(rep_var) && rep_var %in% names(df)) {
    if (!("Rep" %in% names(df))) names(df)[names(df) == rep_var] <- "Rep"
  }
  if (!identical(mainplot_var, "MainPlot") && !is.null(mainplot_var) && mainplot_var %in% names(df)) {
    if (!("MainPlot" %in% names(df))) names(df)[names(df) == mainplot_var] <- "MainPlot"
  }
  if (!identical(subplot_var, "SubPlot") && !is.null(subplot_var) && subplot_var %in% names(df)) {
    if (!("SubPlot" %in% names(df))) names(df)[names(df) == subplot_var] <- "SubPlot"
  }
  if (!identical(response_var, "Value") && !is.null(response_var) && response_var %in% names(df)) {
    if (!("Value" %in% names(df))) names(df)[names(df) == response_var] <- "Value"
  }

  if (is.null(df) || ncol(df) == 0) {
    validate(need(FALSE, "Input dataset is empty or invalid."))
  }

  required <- c("Rep", "MainPlot", "SubPlot", "Value")
  validate(need(all(required %in% names(df)), "Columns Rep/MainPlot/SubPlot/Value or W/A/B/Y are required."))

  df <- df %>%
    mutate(
      Rep = factor(Rep),
      MainPlot = factor(MainPlot),
      SubPlot = factor(SubPlot),
      Value = as.numeric(Value)
    )
  validate(need(!any(is.na(df$Value)), "Value must be numeric."))

  full_model <- lmerTest::lmer(Value ~ MainPlot * SubPlot + (1 | Rep/MainPlot), data = df)
  additive_model <- lmerTest::lmer(Value ~ MainPlot + SubPlot + (1 | Rep/MainPlot), data = df)

  split_results <- split_plot_analysis(df, alpha = alpha)

  full_anova <- as.data.frame(anova(full_model))
  full_anova$Effect <- rownames(full_anova)
  rownames(full_anova) <- NULL

  additive_anova <- as.data.frame(anova(additive_model))
  additive_anova$Effect <- rownames(additive_anova)
  rownames(additive_anova) <- NULL

  interaction_p <- full_anova$`Pr(>F)`[full_anova$Effect == "MainPlot:SubPlot"]
  interaction_p_value <- if (length(interaction_p) == 1) interaction_p[[1]] else NA_real_
  use_additive_model <- !is.na(interaction_p_value) && interaction_p_value >= alpha
  final_model <- if (use_additive_model) additive_model else full_model
  final_model_name <- if (use_additive_model) "Additive model" else "Interaction model"

  emm_main <- emmeans::emmeans(final_model, ~ MainPlot)
  emm_sub <- emmeans::emmeans(final_model, ~ SubPlot)
  emm_interaction <- emmeans::emmeans(full_model, ~ MainPlot * SubPlot)

  tukey_main <- as.data.frame(pairs(emm_main, adjust = "tukey"))
  tukey_sub <- as.data.frame(pairs(emm_sub, adjust = "tukey"))

  cld_main <- as.data.frame(multcomp::cld(emm_main, Letters = letters, adjust = "tukey"))
  cld_sub <- as.data.frame(multcomp::cld(emm_sub, Letters = letters, adjust = "tukey"))

  boxplot_obj <- ggplot2::ggplot(df, ggplot2::aes(x = MainPlot, y = Value, fill = SubPlot)) +
    ggplot2::geom_boxplot() +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Boxplot of Response by Main Plot and Subplot", x = "Main Plot", y = "Response")

  emm_main_df <- as.data.frame(emm_main)
  emm_sub_df <- as.data.frame(emm_sub)
  emm_interaction_df <- as.data.frame(emm_interaction)

  lsmean_main_plot <- ggplot2::ggplot(emm_main_df, ggplot2::aes(x = MainPlot, y = emmean, ymin = lower.CL, ymax = upper.CL)) +
    ggplot2::geom_pointrange(color = "#1f4d3b", size = 0.5) +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Estimated Means for Main Plot", x = "Main Plot", y = "Estimated mean")

  lsmean_sub_plot <- ggplot2::ggplot(emm_sub_df, ggplot2::aes(x = SubPlot, y = emmean, ymin = lower.CL, ymax = upper.CL)) +
    ggplot2::geom_pointrange(color = "#7a5c1e", size = 0.5) +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Estimated Means for Subplot", x = "Subplot", y = "Estimated mean")

  interaction_plot <- ggplot2::ggplot(emm_interaction_df, ggplot2::aes(x = MainPlot, y = emmean, color = SubPlot, group = SubPlot)) +
    ggplot2::geom_line(size = 0.8) +
    ggplot2::geom_point(size = 2) +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Interaction Plot of Estimated Means", x = "Main Plot", y = "Estimated mean", color = "Subplot")

  lsd_main_plot <- ggplot2::ggplot(split_results$MainPlotMeans, ggplot2::aes(x = MainPlot, y = Mean)) +
    ggplot2::geom_col(fill = "#8bb174") +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = Mean - split_results$LSD$MainPlot$LSD / 2, ymax = Mean + split_results$LSD$MainPlot$LSD / 2), width = 0.2, color = "#335633") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Main Plot Means with LSD", x = "Main Plot", y = "Mean")

  lsd_sub_plot <- ggplot2::ggplot(split_results$SubPlotMeans, ggplot2::aes(x = SubPlot, y = Mean)) +
    ggplot2::geom_col(fill = "#c1974f") +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = Mean - split_results$LSD$SubPlot$LSD / 2, ymax = Mean + split_results$LSD$SubPlot$LSD / 2), width = 0.2, color = "#5f4623") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Subplot Means with LSD", x = "Subplot", y = "Mean")

  split_interaction_mean_plot <- ggplot2::ggplot(split_results$InteractionMeans, ggplot2::aes(x = MainPlot, y = Mean, color = SubPlot, group = SubPlot)) +
    ggplot2::geom_line(size = 0.8) +
    ggplot2::geom_point(size = 2) +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Interaction Plot of Observed Means", x = "Main Plot", y = "Mean", color = "Subplot")

  split_lsd_cv_table <- metrics_table(list(
    "Main plot LSD" = split_results$LSD$MainPlot$LSD,
    "Main plot SED" = split_results$LSD$MainPlot$SED,
    "Main plot Error MS" = split_results$LSD$MainPlot$ErrorMS,
    "Main plot DF" = split_results$LSD$MainPlot$DF,
    "Subplot LSD" = split_results$LSD$SubPlot$LSD,
    "Subplot SED" = split_results$LSD$SubPlot$SED,
    "Subplot Error MS" = split_results$LSD$SubPlot$ErrorMS,
    "Subplot DF" = split_results$LSD$SubPlot$DF,
    "Interaction LSD" = split_results$LSD$Interaction$LSD,
    "Interaction SED" = split_results$LSD$Interaction$SED,
    "Main plot CV (%)" = split_results$CV$MainPlotCV,
    "Subplot CV (%)" = split_results$CV$SubPlotCV
  ))

  residuals_final <- residuals(final_model)
  fitted_final <- fitted(final_model)
  random_effects <- as.data.frame(lme4::ranef(final_model)$Rep)
  random_effect_column <- names(random_effects)[1]

  diagnostics <- data.frame(
    Observation = seq_along(residuals_final),
    Fitted = fitted_final,
    Residual = residuals_final,
    stringsAsFactors = FALSE
  )

  assumptions <- data.frame(
    Metric = c("Alpha", "Interaction p-value", "Selected final model", "Random effect"),
    Value = c(alpha, ifelse(is.na(interaction_p_value), "NA", round(interaction_p_value, 4)), final_model_name, "Replication/block as random intercept"),
    stringsAsFactors = FALSE
  )

  list(
    dataset = df,
    data_summary = capture.output(summary(df)),
    full_anova = full_anova,
    additive_anova = additive_anova,
    final_summary = capture.output(summary(final_model)),
    assumptions = assumptions,
    emmeans_main = emm_main_df,
    emmeans_sub = emm_sub_df,
    emmeans_interaction = emm_interaction_df,
    tukey_main = tukey_main,
    tukey_sub = tukey_sub,
    cld_main = cld_main,
    cld_sub = cld_sub,
    diagnostics = diagnostics,
    boxplot_obj = boxplot_obj,
    lsmean_main_plot = lsmean_main_plot,
    lsmean_sub_plot = lsmean_sub_plot,
    interaction_plot = interaction_plot,
    split_anova = split_results$ANOVA,
    split_main_means = split_results$MainPlotMeans,
    split_sub_means = split_results$SubPlotMeans,
    split_interaction_means = split_results$InteractionMeans,
    split_lsd_cv = split_lsd_cv_table,
    lsd_main_plot = lsd_main_plot,
    lsd_sub_plot = lsd_sub_plot,
    split_interaction_mean_plot = split_interaction_mean_plot,
    residuals_final = residuals_final,
    fitted_final = fitted_final,
    random_effects = random_effects,
    random_effect_column = random_effect_column,
    report_note = sprintf("Split-plot mixed model fitted with %s replications; final model: %s", nlevels(df$Rep), final_model_name)
  )
}

run_correlation_regression <- function(df, response, predictors) {
  numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]
  validate(need(length(numeric_cols) >= 2, "At least two numeric columns are required."))
  validate(need(response %in% numeric_cols, "Choose a numeric response variable."))
  validate(need(length(predictors) >= 1, "Choose at least one numeric predictor."))
  selected_predictors <- unique(setdiff(predictors, response))
  validate(need(length(selected_predictors) >= 1, "Choose at least one predictor different from the response variable."))

  numeric_df <- df[, unique(c(response, selected_predictors)), drop = FALSE]
  corr <- round(cor(numeric_df, use = "complete.obs"), 4)
  formula_text <- sprintf("%s ~ %s", response, paste(selected_predictors, collapse = " + "))
  model <- lm(as.formula(formula_text), data = df)
  coeffs <- as.data.frame(summary(model)$coefficients)
  coeffs$Term <- rownames(coeffs)
  coeffs <- coeffs[, c("Term", setdiff(names(coeffs), "Term"))]

  list(
    dataset = df,
    correlation = as.data.frame(corr),
    correlation_source = numeric_df,
    correlation_p = as.data.frame(correlation_p_matrix(numeric_df)),
    coefficients = coeffs,
    fit = data.frame(
      Metric = c("R-squared", "Adjusted R-squared", "Residual SE", "F-statistic p-value"),
      Value = c(summary(model)$r.squared, summary(model)$adj.r.squared, sigma(model), pf(summary(model)$fstatistic[1], summary(model)$fstatistic[2], summary(model)$fstatistic[3], lower.tail = FALSE)),
      stringsAsFactors = FALSE
    ),
    diagnostics = data.frame(Observation = seq_len(nrow(df)), Fitted = fitted(model), Residual = resid(model), stringsAsFactors = FALSE),
    formula = formula_text,
    report_note = sprintf("Regression model: %s", formula_text)
  )
}
