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
pooled_split_plot_example <- local({
  example_data <- expand.grid(
    Year = c("2023", "2024", "2025"),
    Rep = c("R1", "R2", "R3"),
    MainPlot = c("M1", "M2"),
    SubPlot = c("S1", "S2"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  example_data$Value <- with(
    example_data,
    32 + as.numeric(factor(Year)) * 0.8 + as.numeric(factor(MainPlot)) * 2.2 +
      as.numeric(factor(SubPlot)) * 1.1 + as.numeric(factor(Rep)) * 0.25
  )
  # Deterministic teaching variation keeps residual uncertainty estimable.
  example_data$Value <- example_data$Value + sin(seq_len(nrow(example_data)) * 1.7)
  paste(
    c(
      paste(names(example_data), collapse = "\t"),
      apply(example_data, 1, paste, collapse = "\t")
    ),
    collapse = "\n"
  )
})
correlation_example <- "Yield\tRainfall\tNitrogen\tPlantHeight\n42.1\t740\t90\t112\n45.0\t780\t100\t116\n39.8\t690\t85\t109\n50.3\t820\t110\t122\n47.4\t800\t105\t118"

met_example <- paste(
  "GEN\tENV\tREP\tYield",
  "G01\tE1_Loc1\tR1\t5.20", "G01\tE1_Loc1\tR2\t5.40", "G01\tE1_Loc1\tR3\t5.10",
  "G01\tE1_Loc2\tR1\t4.80", "G01\tE1_Loc2\tR2\t4.60", "G01\tE1_Loc2\tR3\t5.00",
  "G01\tE2_Loc1\tR1\t5.50", "G01\tE2_Loc1\tR2\t5.30", "G01\tE2_Loc1\tR3\t5.60",
  "G02\tE1_Loc1\tR1\t4.80", "G02\tE1_Loc1\tR2\t5.00", "G02\tE1_Loc1\tR3\t4.90",
  "G02\tE1_Loc2\tR1\t3.20", "G02\tE1_Loc2\tR2\t3.40", "G02\tE1_Loc2\tR3\t3.10",
  "G02\tE2_Loc1\tR1\t6.20", "G02\tE2_Loc1\tR2\t6.50", "G02\tE2_Loc1\tR3\t6.10",
  "G03\tE1_Loc1\tR1\t4.50", "G03\tE1_Loc1\tR2\t4.30", "G03\tE1_Loc1\tR3\t4.60",
  "G03\tE1_Loc2\tR1\t4.40", "G03\tE1_Loc2\tR2\t4.20", "G03\tE1_Loc2\tR3\t4.50",
  "G03\tE2_Loc1\tR1\t4.30", "G03\tE2_Loc1\tR2\t4.50", "G03\tE2_Loc1\tR3\t4.10",
  "G04\tE1_Loc1\tR1\t3.80", "G04\tE1_Loc1\tR2\t4.00", "G04\tE1_Loc1\tR3\t3.90",
  "G04\tE1_Loc2\tR1\t3.70", "G04\tE1_Loc2\tR2\t3.90", "G04\tE1_Loc2\tR3\t3.80",
  "G04\tE2_Loc1\tR1\t3.90", "G04\tE2_Loc1\tR2\t4.10", "G04\tE2_Loc1\tR3\t3.80",
  "G05\tE1_Loc1\tR1\t6.20", "G05\tE1_Loc1\tR2\t6.00", "G05\tE1_Loc1\tR3\t6.40",
  "G05\tE1_Loc2\tR1\t3.10", "G05\tE1_Loc2\tR2\t3.30", "G05\tE1_Loc2\tR3\t2.90",
  "G05\tE2_Loc1\tR1\t5.80", "G05\tE2_Loc1\tR2\t6.00", "G05\tE2_Loc1\tR3\t5.60",
  sep = "\n"
)

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

  # Missingness must be reviewed in Data Preparation before descriptive models.
  review_observations(df, selected_vars, if (identical(analysis_type, "sumbygrp") && !is.null(group_var)) group_var else character())

  summary_table <- summarize_numeric_columns(df, selected_vars)
  by_group <- data.frame()
  plot_obj <- NULL
  normality <- "Select a normality check or plot in the tabs above."

  if (analysis_type == "sumbygrp") {
    if (is.null(group_var) || !nzchar(group_var) || !(group_var %in% names(df))) {
      stop("Select a valid group variable for grouped summary.")
    }
    by_group <- df %>%
      dplyr::select(dplyr::all_of(c(group_var, selected_vars))) %>%
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
      sprintf("W = %.3f", unname(normality_res$statistic)),
      sprintf("p-value = %.3f", normality_res$p.value),
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
  review_vars <- if (identical(test_type, "paired")) c(pair_left, pair_right) else value_var
  review_observations(df, review_vars, if (test_type %in% c("two-sample", "welch")) group_var else character())

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
      Value = c(res$statistic, res$parameter, res$p.value, res$estimate - mu, res$conf.int[1] - mu, res$conf.int[2] - mu, res$method),
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
    variance_info <- data.frame(Statistic = c("F statistic", "df1", "df2", "p value"), Value = unname(c(variance$statistic, variance$parameter[1], variance$parameter[2], variance$p.value)), row.names = NULL, stringsAsFactors = FALSE)
    test_result <- data.frame(
      Statistic = c("t statistic", "df", "p value", "Mean difference", "95% lower", "95% upper", "Method"),
      Value = c(res$statistic, res$parameter, res$p.value, res$estimate[1] - res$estimate[2], res$conf.int[1], res$conf.int[2], res$method),
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
    result_summary <- data.frame(Variable = c(pair_left, pair_right), N = c(sum(!is.na(x)), sum(!is.na(y))), Mean = c(mean(x, na.rm = TRUE), mean(y, na.rm = TRUE)), SD = c(sd(x, na.rm = TRUE), sd(y, na.rm = TRUE)), stringsAsFactors = FALSE)
    variance_info <- data.frame(Statistic = c("Paired t-test"), Value = c(res$method), stringsAsFactors = FALSE)
    test_result <- data.frame(
      Statistic = c("t statistic", "df", "p value", "Mean difference", "95% lower", "95% upper", "Method"),
      Value = c(res$statistic, res$parameter, res$p.value, res$estimate, res$conf.int[1], res$conf.int[2], res$method),
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

  # Preserve inferential values as numeric columns; format only for presentation.
  difference <- if(test_type == "one-sample") unname(res$estimate-mu) else if(test_type == "paired") unname(res$estimate) else unname(res$estimate[1]-res$estimate[2])
  ci <- as.numeric(res$conf.int) - if(test_type == "one-sample") mu else 0
  test_result <- data.frame(Contrast = if(test_type=="one-sample") paste(value_var,"minus",mu) else if(test_type=="paired") paste(pair_left,"minus",pair_right) else paste(levels(g),collapse=" minus "),
    Estimate=difference, SE=unname(res$stderr), df=unname(res$parameter), LowerCI=ci[1], UpperCI=ci[2], t=unname(res$statistic), P= res$p.value,
    Method=res$method, row.names = NULL, stringsAsFactors = FALSE)
  list(
    dataset = dataset,
    summary = result_summary,
    variance = variance_info,
    test_result = test_result,
    plot_obj = plot_obj
  )
}

format_anova_table <- function(model, term_col = "Term") {
  out <- as.data.frame(anova(model))
  out[[term_col]] <- rownames(out)
  rownames(out) <- NULL
  preferred <- c(term_col, "Df", "DF", "NumDF", "DenDF", "Sum Sq", "Mean Sq", "F value", "Pr(>F)")
  cols <- c(intersect(preferred, names(out)), setdiff(names(out), preferred))
  out[, cols, drop = FALSE]
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
  split_values <- split(df_long$Value, df_long[[treatment_col]])

  out <- do.call(rbind, lapply(names(split_values), function(name) {
    values <- as.numeric(split_values[[name]])
    mean_value <- mean(values, na.rm = TRUE)
    sd_value <- stats::sd(values, na.rm = TRUE)
    n_value <- sum(!is.na(values))
    se_value <- sd_value / sqrt(n_value)
    data.frame(
      Treatment = name,
      N = n_value,
      Mean = mean_value,
      SD = sd_value,
      SE = se_value,
      LowerCI = mean_value - qt(1-alpha/2,n_value-1) * se_value,
      UpperCI = mean_value + qt(1-alpha/2,n_value-1) * se_value,
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
  validate(need(!anyNA(trt_order) && all(nzchar(trimws(as.character(trt_order)))) && !anyDuplicated(trt_order), "Treatment identifiers must be nonempty and unique."))
  validate(need(is.finite(alpha) && alpha>0 && alpha<1,"Alpha must be between 0 and 1."))

  if (design %in% c("Factorial CRD", "Factorial RBD")) {
    expected_rows <- levels_a * levels_b
    validate(need(nrow(df) == expected_rows, sprintf("Expected %s rows from %s x %s factorial levels, found %s.", expected_rows, levels_a, levels_b, nrow(df))))
  }

  df_long <- pivot_longer(df, cols = -1, names_to = "Rep", values_to = "Value")
  df_long$Rep <- factor(df_long$Rep)
  df_long$Value <- as.numeric(df_long$Value)
  validate(need(!any(is.na(df_long$Value)), "All replication columns must be numeric."))
  validate(need(all(is.finite(df_long$Value)), "Replication values must be finite."))

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
    Value = c(reps, grand_mean, mse, sqrt(mse / reps), sqrt(2 * mse / reps), if(grand_mean>0) (sqrt(mse) / grand_mean) * 100 else NA_real_),
    stringsAsFactors = FALSE
  )

  means <- comparison$means
  groups <- comparison$groups
  treatment_summary <- if (design %in% c("CRD", "RBD")) build_treatment_summary(df_long, "Trt", alpha = alpha) else NULL
  if (!is.null(treatment_summary)) {
    estimated <- as.data.frame(emmeans::emmeans(model,~Trt,level=1-alpha))
    idx <- match(treatment_summary$Treatment,estimated$Trt)
    treatment_summary$SE <- estimated$SE[idx]
    treatment_summary$LowerCI <- estimated$lower.CL[idx]
    treatment_summary$UpperCI <- estimated$upper.CL[idx]
    treatment_summary$df <- estimated$df[idx]
    treatment_summary <- treatment_summary[, c("Treatment", "N", "Mean", "SD", "SE", "df", "LowerCI", "UpperCI"), drop = FALSE]
  }

  inference <- ""
  if (design %in% c("CRD", "RBD")) {
    p_val <- aov_sum["Trt", "Pr(>F)"]
    if (!is.na(p_val)) {
      if (p_val <= alpha) {
        inference <- sprintf("Since the P-value in ANOVA table is <= %s, there is a significant difference between at least a pair of treatments, so multiple comparison is required to identify best treatment(s). Treatments with same letters are not significantly different.", alpha)
      } else {
        inference <- "The omnibus treatment test did not reject equal means. Pairwise comparisons are shown as exploratory results; shared letters indicate non-rejection, not equivalence."
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
    use_additive_model <- FALSE
    final_model <- if (use_additive_model) additive_model else full_model
    final_model_name <- if (use_additive_model) "Additive model" else "Interaction model"

    emm_interaction <- emmeans::emmeans(full_model, ~ FactA * FactB, level=1-alpha)
    emm_a <- emmeans::emmeans(full_model, ~ FactA, level=1-alpha)
    emm_b <- emmeans::emmeans(full_model, ~ FactB, level=1-alpha)

    tukey_interaction <- as.data.frame(pairs(emm_interaction, adjust = "tukey"))
    tukey_a <- as.data.frame(pairs(emm_a, adjust = "tukey"))
    tukey_b <- as.data.frame(pairs(emm_b, adjust = "tukey"))

    cld_interaction <- as.data.frame(multcomp::cld(emm_interaction, Letters = letters, adjust = "tukey", alpha=alpha, level=1-alpha))
    cld_a <- as.data.frame(multcomp::cld(emm_a, Letters = letters, adjust = "tukey", alpha=alpha, level=1-alpha))
    cld_b <- as.data.frame(multcomp::cld(emm_b, Letters = letters, adjust = "tukey", alpha=alpha, level=1-alpha))
    rownames(cld_interaction) <- NULL
    rownames(cld_a) <- NULL
    rownames(cld_b) <- NULL

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
        Value = c(alpha, ifelse(is.na(interaction_p_value), "NA", interaction_p_value), final_model_name),
        stringsAsFactors = FALSE
      ),
      shapiro = data.frame(
        Metric = c("W statistic", "p-value"),
        Value = c(unname(shapiro_out$statistic), shapiro_out$p.value),
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
    factor_a_trt = NULL,
    factor_b_trt = NULL,
    checks = NULL,
    test_trt = NULL) {
  kind <- "Super-Duper"

  parse_factorial_treatment <- function(treatment) {
    parts <- strcapture(
      "^A([0-9]+)B([0-9]+)$",
      as.character(treatment),
      proto = list(A = integer(), B = integer())
    )
    data.frame(
      FactorA = sprintf("A%s", parts$A),
      FactorB = sprintf("B%s", parts$B),
      stringsAsFactors = FALSE
    )
  }

  if (identical(design, "CRD")) {
    validate(need(!is.null(trt) && trt >= 2, "CRD needs at least two treatments."))
    validate(need(!is.null(rep) && rep >= 2, "CRD needs at least two replications."))
    trt_labels <- sprintf("T%s", seq_len(trt))
    fieldbook <- agricolae::design.crd(trt_labels, r = rep, seed = seed, serie = 0, kinds = kind, randomization = TRUE)$book
    fieldbook$Treatment <- as.character(fieldbook[[ncol(fieldbook)]])
    fieldbook <- fieldbook[order(fieldbook$r), , drop = FALSE]
    fieldbook$ExperimentalUnit <- seq_len(nrow(fieldbook))
    plot_data <- transform(fieldbook, row = 1, col = ExperimentalUnit, label = Treatment)
    list(
      design = design,
      summary = data.frame(Treatments = trt, Replications = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(ExperimentalUnit = fieldbook$ExperimentalUnit, Treatment = fieldbook$Treatment, stringsAsFactors = FALSE),
      plot_data = plot_data
    )
  } else if (identical(design, "RBD")) {
    validate(need(!is.null(trt) && trt >= 2, "RBD needs at least two treatments."))
    validate(need(!is.null(rep) && rep >= 2, "RBD needs at least two blocks."))
    trt_labels <- sprintf("T%s", seq_len(trt))
    fieldbook <- agricolae::design.rcbd(trt = trt_labels, r = rep, seed = seed, serie = 0, kinds = kind, randomization = TRUE)$book
    fieldbook$Treatment <- as.character(fieldbook[[ncol(fieldbook)]])
    fieldbook <- fieldbook[order(fieldbook$block), , drop = FALSE]
    fieldbook$Plot <- ave(seq_len(nrow(fieldbook)), fieldbook$block, FUN = seq_along)
    plot_data <- transform(fieldbook, block_num = as.numeric(block), plot_num = Plot, label = Treatment)
    list(
      design = design,
      summary = data.frame(Treatments = trt, Blocks = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(Block = as.character(fieldbook$block), Plot = fieldbook$Plot, Treatment = fieldbook$Treatment, stringsAsFactors = FALSE),
      plot_data = plot_data
    )
  } else if (identical(design, "Factorial CRD")) {
    validate(need(!is.null(factor_a_trt) && factor_a_trt >= 2, "Factorial CRD needs at least two Factor A levels."))
    validate(need(!is.null(factor_b_trt) && factor_b_trt >= 2, "Factorial CRD needs at least two Factor B levels."))
    validate(need(!is.null(rep) && rep >= 2, "Factorial CRD needs at least two replications."))
    factor_a_labels <- sprintf("A%s", seq_len(factor_a_trt))
    factor_b_labels <- sprintf("B%s", seq_len(factor_b_trt))
    trt_labels <- as.vector(outer(factor_a_labels, factor_b_labels, paste0))
    fieldbook <- agricolae::design.crd(trt_labels, r = rep, seed = seed, serie = 0, kinds = kind, randomization = TRUE)$book
    fieldbook$Treatment <- as.character(fieldbook[[ncol(fieldbook)]])
    fieldbook <- fieldbook[order(fieldbook$r), , drop = FALSE]
    fieldbook$ExperimentalUnit <- seq_len(nrow(fieldbook))
    factors <- parse_factorial_treatment(fieldbook$Treatment)
    plot_data <- transform(fieldbook, row = 1, col = ExperimentalUnit, label = Treatment)
    list(
      design = design,
      summary = data.frame(FactorALevels = factor_a_trt, FactorBLevels = factor_b_trt, Treatments = length(trt_labels), Replications = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(ExperimentalUnit = fieldbook$ExperimentalUnit, FactorA = factors$FactorA, FactorB = factors$FactorB, Treatment = fieldbook$Treatment, stringsAsFactors = FALSE),
      plot_data = plot_data
    )
  } else if (identical(design, "Factorial RBD")) {
    validate(need(!is.null(factor_a_trt) && factor_a_trt >= 2, "Factorial RBD needs at least two Factor A levels."))
    validate(need(!is.null(factor_b_trt) && factor_b_trt >= 2, "Factorial RBD needs at least two Factor B levels."))
    validate(need(!is.null(rep) && rep >= 2, "Factorial RBD needs at least two blocks."))
    factor_a_labels <- sprintf("A%s", seq_len(factor_a_trt))
    factor_b_labels <- sprintf("B%s", seq_len(factor_b_trt))
    trt_labels <- as.vector(outer(factor_a_labels, factor_b_labels, paste0))
    fieldbook <- agricolae::design.rcbd(trt = trt_labels, r = rep, seed = seed, serie = 0, kinds = kind, randomization = TRUE)$book
    fieldbook$Treatment <- as.character(fieldbook[[ncol(fieldbook)]])
    fieldbook <- fieldbook[order(fieldbook$block), , drop = FALSE]
    fieldbook$Plot <- ave(seq_len(nrow(fieldbook)), fieldbook$block, FUN = seq_along)
    factors <- parse_factorial_treatment(fieldbook$Treatment)
    plot_data <- transform(fieldbook, block_num = as.numeric(block), plot_num = Plot, label = Treatment)
    list(
      design = design,
      summary = data.frame(FactorALevels = factor_a_trt, FactorBLevels = factor_b_trt, Treatments = length(trt_labels), Blocks = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(Block = as.character(fieldbook$block), Plot = fieldbook$Plot, FactorA = factors$FactorA, FactorB = factors$FactorB, Treatment = fieldbook$Treatment, stringsAsFactors = FALSE),
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
    treatment_columns <- tail(names(fieldbook), 2L)
    fieldbook$MainTreatment <- as.character(fieldbook[[treatment_columns[[1L]]]])
    fieldbook$SubTreatment <- as.character(fieldbook[[treatment_columns[[2L]]]])
    fieldbook <- fieldbook[order(fieldbook$block, fieldbook$plots, fieldbook$splots), , drop = FALSE]
    plot_data <- transform(
      fieldbook,
      rep_num = as.numeric(block),
      main_num = as.numeric(plots),
      sub_num = as.numeric(splots),
      main_treatment = MainTreatment,
      sub_treatment = SubTreatment,
      label = sprintf("%s/%s", MainTreatment, SubTreatment)
    )
    list(
      design = design,
      summary = data.frame(MainPlotTreatments = main_trt, SubPlotTreatments = sub_trt, Replications = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(Replication = as.character(fieldbook$block), MainPlot = fieldbook$plots, SubPlot = fieldbook$splots, MainTreatment = fieldbook$MainTreatment, SubTreatment = fieldbook$SubTreatment, stringsAsFactors = FALSE),
      plot_data = plot_data
    )
  } else if (identical(design, "Strip Plot")) {
    validate(need(!is.null(main_trt) && main_trt >= 2, "Strip plot needs at least two horizontal treatments."))
    validate(need(!is.null(sub_trt) && sub_trt >= 2, "Strip plot needs at least two vertical treatments."))
    validate(need(!is.null(rep) && rep >= 2, "Strip plot needs at least two replications."))
    main_labels <- sprintf("A%s", seq_len(main_trt))
    sub_labels <- sprintf("B%s", seq_len(sub_trt))
    fieldbook <- agricolae::design.strip(main_labels, sub_labels, r = rep, serie = 0, seed = seed, kinds = kind, randomization = TRUE)$book
    treatment_columns <- tail(names(fieldbook), 2L)
    fieldbook$HorizontalTreatment <- as.character(fieldbook[[treatment_columns[[1L]]]])
    fieldbook$VerticalTreatment <- as.character(fieldbook[[treatment_columns[[2L]]]])
    fieldbook$Row <- match(fieldbook$HorizontalTreatment, unique(fieldbook$HorizontalTreatment))
    fieldbook$Column <- match(fieldbook$VerticalTreatment, unique(fieldbook$VerticalTreatment))
    plot_data <- transform(fieldbook, rep_num = as.numeric(block), row_num = Row, col_num = Column, label = sprintf("%s/%s", HorizontalTreatment, VerticalTreatment))
    list(
      design = design,
      summary = data.frame(HorizontalTreatments = main_trt, VerticalTreatments = sub_trt, Replications = rep, ExperimentalUnits = nrow(fieldbook), stringsAsFactors = FALSE),
      fieldbook = data.frame(Replication = as.character(fieldbook$block), Row = fieldbook$Row, Column = fieldbook$Column, HorizontalTreatment = fieldbook$HorizontalTreatment, VerticalTreatment = fieldbook$VerticalTreatment, stringsAsFactors = FALSE),
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

  df <- review_observations(df,"Value",c("Season","Rep","Treatment"))$data
  validate(need(nlevels(df$Season)>=2 && nlevels(df$Treatment)>=2,"At least two seasons and treatments are required."))
  validate(need(!anyDuplicated(df[c("Season","Rep","Treatment")]),"Duplicate Season/Rep/Treatment units are not independent replications."))
  validate(need(all(table(df$Season,df$Treatment)>0),"Every treatment must occur in every season."))

  season_models <- lapply(split(df, df$Season), function(part) {
    part <- droplevels(part)
    if (nlevels(part$Rep) > 1) aov(Value ~ Rep + Treatment, data = part) else aov(Value ~ Treatment, data = part)
  })

  error_summary <- data.frame(
    Season = names(season_models),
    ErrorMS = vapply(season_models, function(m) anova(m)["Residuals", "Mean Sq"], numeric(1)),
    stringsAsFactors = FALSE
  )

  error_summary$ErrorDF <- vapply(season_models, df.residual, numeric(1))
  validate(need(all(error_summary$ErrorDF > 0), "Each season needs residual degrees of freedom to assess error variance."))
  residual_data <- do.call(rbind, lapply(names(season_models), function(s) data.frame(Season = s, Residual = residuals(season_models[[s]]))))
  residual_data$Season <- factor(residual_data$Season)
  homogeneity <- car::leveneTest(Residual ~ Season, data = residual_data, center = median)
  pooled_model <- if (nlevels(df$Rep) > 1) aov(Value ~ Season + Season:Rep + Treatment + Season:Treatment, data = df) else aov(Value ~ Season * Treatment, data = df)

  list(
    dataset = df,
    anova = format_anova_table(pooled_model),
    error_summary = error_summary,
    homogeneity = data.frame(
      Metric = c("Residual median-centred Levene F", "df", "p-value", "Interpretation"),
      Value = c(homogeneity[1, "F value"], homogeneity[1, "Df"], homogeneity[1, "Pr(>F)"], "Diagnostic only: inspect residuals and experimental design before pooling."),
      stringsAsFactors = FALSE
    ),
    treatment_means = df %>% group_by(Treatment) %>% summarise(Mean = mean(Value), .groups = "drop"),
    season_treatment_means = df %>% group_by(Season, Treatment) %>% summarise(Mean = mean(Value), .groups = "drop"),
    report_note = sprintf("Pooled across %s seasons at alpha %.2f. Fixed season, treatment and nested block model with sequential sums of squares; inference is conditional on the observed seasons. Residual Levene test is diagnostic only.", nlevels(df$Season), alpha)
  )
}

run_pooled_split_plot <- function(
  df,
  year_var = "Year",
  rep_var = "Rep",
  mainplot_var = "MainPlot",
  subplot_var = "SubPlot",
  response_var = "Value",
  alpha = 0.05,
  include_pwpp = FALSE
) {
  required_packages <- c("lme4", "lmerTest", "emmeans", "ggplot2")
  missing_packages <- required_packages[!vapply(required_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
  if (length(missing_packages) > 0) {
    stop(sprintf("Missing package(s): %s.", paste(missing_packages, collapse = ", ")), call. = FALSE)
  }

  selected_columns <- c(year_var, rep_var, mainplot_var, subplot_var, response_var)
  if (any(is.na(selected_columns)) || any(!nzchar(selected_columns)) || length(unique(selected_columns)) != 5) {
    stop("Year, Rep, MainPlot, SubPlot, and response variables must be five different columns.", call. = FALSE)
  }
  if (!all(selected_columns %in% names(df))) {
    stop("Selected Year, Rep, MainPlot, SubPlot, or response column was not found in the dataset.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1 || is.na(alpha) || alpha <= 0 || alpha >= 1) {
    stop("Alpha must be a single value between 0 and 1.", call. = FALSE)
  }

  data <- df[, selected_columns, drop = FALSE]
  names(data) <- c("Year", "Rep", "MainPlot", "SubPlot", "Value")
  if (nrow(data) == 0) {
    stop("Input dataset is empty.", call. = FALSE)
  }
  if (any(vapply(data[c("Year", "Rep", "MainPlot", "SubPlot")], function(x) any(is.na(x) | trimws(as.character(x)) == ""), logical(1)))) {
    stop("Year, Rep, MainPlot, and SubPlot cannot contain missing or blank values.", call. = FALSE)
  }

  data$Value <- suppressWarnings(as.numeric(data$Value))
  if (any(!is.finite(data$Value))) {
    stop("Response values must be finite numeric values.", call. = FALSE)
  }
  data[c("Year", "Rep", "MainPlot", "SubPlot")] <- lapply(
    data[c("Year", "Rep", "MainPlot", "SubPlot")],
    function(x) factor(trimws(as.character(x)))
  )

  if (anyDuplicated(data[c("Year", "Rep", "MainPlot", "SubPlot")])) {
    stop("Each Year/Rep/MainPlot/SubPlot combination must occur exactly once.", call. = FALSE)
  }

  n_year <- nlevels(data$Year)
  n_main <- nlevels(data$MainPlot)
  n_sub <- nlevels(data$SubPlot)
  if (n_year < 2 || n_main < 2 || n_sub < 2) {
    stop("Pooled Split-RCBD requires at least two years and two levels of each treatment factor.", call. = FALSE)
  }

  rep_counts <- vapply(split(data$Rep, data$Year), function(x) nlevels(droplevels(x)), integer(1))
  if (any(rep_counts < 2) || length(unique(rep_counts)) != 1) {
    stop("Each year must have the same number of replications, with at least two replications per year.", call. = FALSE)
  }

  main_levels_by_year <- lapply(split(data$MainPlot, data$Year), function(x) levels(droplevels(x)))
  sub_levels_by_year <- lapply(split(data$SubPlot, data$Year), function(x) levels(droplevels(x)))
  if (!all(vapply(main_levels_by_year, identical, logical(1), main_levels_by_year[[1]])) ||
      !all(vapply(sub_levels_by_year, identical, logical(1), sub_levels_by_year[[1]]))) {
    stop("Every year must contain the same MainPlot and SubPlot treatment levels.", call. = FALSE)
  }

  expected_rows <- n_year * rep_counts[[1]] * n_main * n_sub
  if (nrow(data) != expected_rows) {
    stop("Data must be balanced: every Year/Rep/MainPlot/SubPlot cell needs one observation.", call. = FALSE)
  }

  full_model <- lmerTest::lmer(
    Value ~ Year + (1 | Year:Rep) + MainPlot * SubPlot + Year:(MainPlot * SubPlot) + (1 | Year:Rep:MainPlot),
    data = data
  )

  anova_table <- as.data.frame(stats::anova(full_model, type = 3, ddf = "Satterthwaite"))
  anova_table$Effect <- rownames(anova_table)
  rownames(anova_table) <- NULL
  preferred_anova <- c("Effect", "NumDF", "DenDF", "Sum Sq", "Mean Sq", "F value", "Pr(>F)")
  anova_table <- anova_table[, c(intersect(preferred_anova, names(anova_table)), setdiff(names(anova_table), preferred_anova)), drop = FALSE]

  make_lsd_table <- function(emm_grid) {
    contrasts <- emmeans::contrast(emm_grid, method = "pairwise", adjust = "none")
    result <- as.data.frame(summary(contrasts, infer = c(TRUE, TRUE), level = 1 - alpha))
    result$Critical_t <- stats::qt(1 - alpha / 2, df = result$df)
    result$CD <- result$SE * result$Critical_t
    rownames(result) <- NULL
    stat_cols <- c("estimate", "SE", "df", "Critical_t", "CD", "lower.CL", "upper.CL", "t.ratio", "p.value")
    id_cols <- setdiff(names(result), stat_cols)
    id_cols <- c(setdiff(id_cols, "contrast"), intersect("contrast", id_cols))
    result[, c(id_cols, intersect(stat_cols, names(result))), drop = FALSE]
  }
  summarize_cd_family <- function(label, pairwise_table) {
    data.frame(
      Comparison = label,
      Comparisons = nrow(pairwise_table),
      `Minimum CD` = min(pairwise_table$CD),
      `Maximum CD` = max(pairwise_table$CD),
      `Mean CD` = mean(pairwise_table$CD),
      `Minimum df` = min(pairwise_table$df),
      `Maximum df` = max(pairwise_table$df),
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
  }

  emm_main <- emmeans::emmeans(full_model, ~ MainPlot, lmer.df = "satterthwaite")
  emm_sub <- emmeans::emmeans(full_model, ~ SubPlot, lmer.df = "satterthwaite")
  emm_interaction <- emmeans::emmeans(full_model, ~ MainPlot * SubPlot, lmer.df = "satterthwaite")
  emm_sub_within_main <- emmeans::emmeans(full_model, ~ SubPlot | MainPlot, lmer.df = "satterthwaite")
  emm_main_within_sub <- emmeans::emmeans(full_model, ~ MainPlot | SubPlot, lmer.df = "satterthwaite")

  lsd_main <- make_lsd_table(emm_main)
  lsd_sub <- make_lsd_table(emm_sub)
  lsd_interaction <- make_lsd_table(emm_interaction)
  lsd_sub_within_main <- make_lsd_table(emm_sub_within_main)
  lsd_main_within_sub <- make_lsd_table(emm_main_within_sub)
  cd_summary <- do.call(
    rbind,
    list(
      summarize_cd_family("Main plot means", lsd_main),
      summarize_cd_family("Subplot means", lsd_sub),
      summarize_cd_family("Subplot means within main plot", lsd_sub_within_main),
      summarize_cd_family("Main-plot means within subplot", lsd_main_within_sub)
    )
  )
  cd_summary[, 3:7] <- cd_summary[, 3:7]

  main_means <- as.data.frame(summary(emm_main, infer = c(TRUE, TRUE), level = 1 - alpha))
  sub_means <- as.data.frame(summary(emm_sub, infer = c(TRUE, TRUE), level = 1 - alpha))
  interaction_means <- as.data.frame(summary(emm_interaction, infer = c(TRUE, TRUE), level = 1 - alpha))

  residuals_final <- residuals(full_model)
  fitted_final <- fitted(full_model)
  diagnostics <- data.frame(
    Observation = seq_along(residuals_final),
    Fitted = fitted_final,
    Residual = residuals_final,
    stringsAsFactors = FALSE
  )
  normality <- if (length(residuals_final) >= 3 && length(residuals_final) <= 5000) stats::shapiro.test(residuals_final) else NULL
  random_effect_variance <- as.data.frame(lme4::VarCorr(full_model))
  fixed_effects <- as.data.frame(summary(full_model)$coefficients)
  fixed_effects$Effect <- rownames(fixed_effects)
  rownames(fixed_effects) <- NULL
  fixed_effects <- fixed_effects[, c("Effect", setdiff(names(fixed_effects), "Effect")), drop = FALSE]

  interaction_plot <- ggplot2::ggplot(interaction_means, ggplot2::aes(x = MainPlot, y = emmean, color = SubPlot, group = SubPlot)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 2) +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Pooled Split-RCBD Interaction Means", x = "Main plot", y = "Estimated mean", color = "Subplot")
  main_plot <- ggplot2::ggplot(main_means, ggplot2::aes(x = MainPlot, y = emmean, ymin = lower.CL, ymax = upper.CL)) +
    ggplot2::geom_pointrange(color = "#1f4d3b") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Pooled Main-Plot Means", x = "Main plot", y = "Estimated mean")
  sub_plot <- ggplot2::ggplot(sub_means, ggplot2::aes(x = SubPlot, y = emmean, ymin = lower.CL, ymax = upper.CL)) +
    ggplot2::geom_pointrange(color = "#7a5c1e") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Pooled Subplot Means", x = "Subplot", y = "Estimated mean")
  residual_plot <- ggplot2::ggplot(diagnostics, ggplot2::aes(x = Fitted, y = Residual)) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "#7a5c1e") +
    ggplot2::geom_point(color = "#1f4d3b") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Residuals vs Fitted", x = "Fitted values", y = "Residuals")
  residual_qq_plot <- ggplot2::ggplot(diagnostics, ggplot2::aes(sample = Residual)) +
    ggplot2::stat_qq(color = "#1f4d3b") +
    ggplot2::stat_qq_line(color = "#7a1e1e") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Residual Q-Q Plot")
  pwpp_plot <- if (isTRUE(include_pwpp)) emmeans::pwpp(emm_interaction, adjust = "none") else NULL

  model_info <- data.frame(
    Metric = c("Formula", "Degrees of freedom", "Comparison method", "CD formula", "Years", "Replications per year", "Main-plot levels", "Subplot levels", "Residual normality p-value"),
    Value = c(
      paste(deparse(stats::formula(full_model)), collapse = " "),
      "Satterthwaite",
      "Fisher LSD (unadjusted pairwise contrasts)",
      "qt(1 - alpha / 2, df) * SE",
      n_year,
      rep_counts[[1]],
      n_main,
      n_sub,
      if (is.null(normality)) "Not computed" else report_number(normality$p.value, p = TRUE)
    ),
    stringsAsFactors = FALSE
  )

  list(
    dataset = data,
    model = full_model,
    formula = stats::formula(full_model),
    anova = anova_table,
    model_info = model_info,
    fixed_effects = fixed_effects,
    random_effect_variance = random_effect_variance,
    main_means = main_means,
    sub_means = sub_means,
    interaction_means = interaction_means,
    cd_summary = cd_summary,
    lsd_main = lsd_main,
    lsd_sub = lsd_sub,
    lsd_interaction = lsd_interaction,
    lsd_sub_within_main = lsd_sub_within_main,
    lsd_main_within_sub = lsd_main_within_sub,
    diagnostics = diagnostics,
    model_summary = capture.output(summary(full_model)),
    interaction_plot = interaction_plot,
    main_plot = main_plot,
    sub_plot = sub_plot,
    residual_plot = residual_plot,
    residual_qq_plot = residual_qq_plot,
    pwpp_plot = pwpp_plot,
    report_note = sprintf(
      "Pooled Split-RCBD mixed model across %s years with %s replications per year; Fisher LSD contrasts use Satterthwaite degrees of freedom.",
      n_year,
      rep_counts[[1]]
    )
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
      main_tab$`Pr(>F)`[1],
      NA,
      sub_tab$`Pr(>F)`[1],
      sub_tab$`Pr(>F)`[2],
      NA
    ),
    stringsAsFactors = FALSE
  )


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

  mixed_df <- (Ea+(b-1)*Eb)^2 / (Ea^2/dfa + ((b-1)*Eb)^2/dfb)
  tw <- qt(1-alpha/2,mixed_df)
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
        SatterthwaiteDF = mixed_df,
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

  selected <- c(rep_var,mainplot_var,subplot_var,response_var)
  aliases <- c(Rep="W",MainPlot="A",SubPlot="B",Value="Y")
  selected <- vapply(selected,function(nm) if(nm %in% names(df)) nm else if(nm %in% names(aliases)) aliases[[nm]] else nm,character(1))
  validate(need(length(unique(selected))==4 && all(selected %in% names(df)),"Choose four distinct columns for Rep/MainPlot/SubPlot/Value (or W/A/B/Y)."))
  df <- df[,selected,drop=FALSE];names(df)<-c("Rep","MainPlot","SubPlot","Value")
  df <- review_observations(df,"Value",c("Rep","MainPlot","SubPlot"))$data
  validate(need(!anyDuplicated(df[c("Rep","MainPlot","SubPlot")]) && all(table(df$Rep,df$MainPlot,df$SubPlot)==1),"A complete balanced split-plot layout with one observation per experimental unit is required."))
  validate(need(all(vapply(df[c("Rep","MainPlot","SubPlot")],nlevels,integer(1))>=2),"Split plots require at least two replications and two levels of each factor."))

  full_model <- lmerTest::lmer(Value ~ MainPlot * SubPlot + (1 | Rep/MainPlot), data = df)
  additive_model <- lmerTest::lmer(Value ~ MainPlot + SubPlot + (1 | Rep/MainPlot), data = df)

  split_results <- split_plot_analysis(df, alpha = alpha)

  full_anova <- format_anova_table(full_model, term_col = "Effect")
  additive_anova <- format_anova_table(additive_model, term_col = "Effect")

  interaction_p <- full_anova$`Pr(>F)`[full_anova$Effect == "MainPlot:SubPlot"]
  interaction_p_value <- if (length(interaction_p) == 1) interaction_p[[1]] else NA_real_
  use_additive_model <- FALSE
  final_model <- if (use_additive_model) additive_model else full_model
  final_model_name <- if (use_additive_model) "Additive model" else "Interaction model"

  emm_main <- emmeans::emmeans(final_model, ~ MainPlot, level=1-alpha)
  emm_sub <- emmeans::emmeans(final_model, ~ SubPlot, level=1-alpha)
  emm_interaction <- emmeans::emmeans(full_model, ~ MainPlot * SubPlot, level=1-alpha)

  tukey_main <- as.data.frame(pairs(emm_main, adjust = "tukey"))
  tukey_sub <- as.data.frame(pairs(emm_sub, adjust = "tukey"))

  cld_main <- as.data.frame(multcomp::cld(emm_main, Letters = letters, adjust = "tukey", alpha=alpha, level=1-alpha))
  cld_sub <- as.data.frame(multcomp::cld(emm_sub, Letters = letters, adjust = "tukey", alpha=alpha, level=1-alpha))
  rownames(cld_main) <- NULL
  rownames(cld_sub) <- NULL

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
    ggplot2::labs(title = "Main plot means: half-LSD bars (not confidence intervals)", x = "Main Plot", y = "Mean")

  lsd_sub_plot <- ggplot2::ggplot(split_results$SubPlotMeans, ggplot2::aes(x = SubPlot, y = Mean)) +
    ggplot2::geom_col(fill = "#c1974f") +
    ggplot2::geom_errorbar(ggplot2::aes(ymin = Mean - split_results$LSD$SubPlot$LSD / 2, ymax = Mean + split_results$LSD$SubPlot$LSD / 2), width = 0.2, color = "#5f4623") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Subplot means: half-LSD bars (not confidence intervals)", x = "Subplot", y = "Mean")

  split_interaction_mean_plot <- ggplot2::ggplot(split_results$InteractionMeans, ggplot2::aes(x = MainPlot, y = Mean, color = SubPlot, group = SubPlot)) +
    ggplot2::geom_line(size = 0.8) +
    ggplot2::geom_point(size = 2) +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Interaction Plot of Observed Means", x = "Main Plot", y = "Mean", color = "Subplot")

  split_lsd_cv_table <- data.frame(
    Comparison = c(
      "Main plot",
      "Subplot",
      "Subplot within main plot",
      "Main-plot means at same/different subplot levels"
    ),
    `Error MS` = c(
      report_number(split_results$LSD$MainPlot$ErrorMS),
      report_number(split_results$LSD$SubPlot$ErrorMS),
      report_number(split_results$LSD$Interaction$ErrorMS),
      sprintf(
        "Ea: %s; Eb: %s",
        report_number(split_results$LSD$Interaction2$ErrorA),
        report_number(split_results$LSD$Interaction2$ErrorB)
      )
    ),
    DF = c(
      report_number(split_results$LSD$MainPlot$DF, count = TRUE),
      report_number(split_results$LSD$SubPlot$DF, count = TRUE),
      report_number(split_results$LSD$Interaction$DF, count = TRUE),
      sprintf(
        "DFa: %s; DFb: %s",
        report_number(split_results$LSD$Interaction2$DFa, count = TRUE),
        report_number(split_results$LSD$Interaction2$DFb, count = TRUE)
      )
    ),
    `SE(d)` = c(
      split_results$LSD$MainPlot$SED,
      split_results$LSD$SubPlot$SED,
      split_results$LSD$Interaction$SED,
      split_results$LSD$Interaction2$SED
    ),
    CD = c(
      split_results$LSD$MainPlot$LSD,
      split_results$LSD$SubPlot$LSD,
      split_results$LSD$Interaction$LSD,
      split_results$LSD$Interaction2$LSD
    ),
    `CV (%)` = c(
      split_results$CV$MainPlotCV,
      split_results$CV$SubPlotCV,
      NA,
      NA
    ),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

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
    Value = c(alpha, ifelse(is.na(interaction_p_value), "NA", interaction_p_value), final_model_name, "Replication/block as random intercept"),
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

run_correlation_regression <- function(df, response, predictors, exclude_missing = FALSE) {
  numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]
  validate(need(length(numeric_cols) >= 2, "At least two numeric columns are required."))
  validate(need(response %in% numeric_cols, "Choose a numeric response variable."))
  validate(need(length(predictors) >= 1, "Choose at least one numeric predictor."))
  selected_predictors <- unique(setdiff(predictors, response))
  validate(need(length(selected_predictors) >= 1, "Choose at least one predictor different from the response variable."))
  validate(need(all(selected_predictors %in% numeric_cols), "Choose numeric predictor columns."))

  numeric_df <- df[, unique(c(response, selected_predictors)), drop = FALSE]
  review <- review_observations(numeric_df, names(numeric_df), exclude_missing = exclude_missing)
  numeric_df <- review$data
  validate(need(nrow(numeric_df) > ncol(numeric_df), "More complete observations than fitted coefficients are required."))
  validate(need(all(vapply(numeric_df, function(x) length(unique(x)) > 1L, logical(1))), "Remove constant variables before regression."))
  df <- df[review$rows, , drop = FALSE]
  corr <- cor(numeric_df, use = "complete.obs")
  model_formula <- safe_model_formula(response, selected_predictors)
  formula_text <- paste(deparse(model_formula), collapse = " ")
  model <- lm(model_formula, data = df, na.action = na.fail)
  validate(need(model$rank == length(coef(model)), "Predictors are linearly dependent. Remove redundant predictors."))
  coeffs <- as.data.frame(summary(model)$coefficients)
  coeffs$Term <- rownames(coeffs)
  rownames(coeffs) <- NULL
  coeffs <- coeffs[, c("Term", setdiff(names(coeffs), "Term"))]

  list(
    dataset = df,
    correlation = as.data.frame(corr),
    correlation_source = numeric_df,
    correlation_p = structure(as.data.frame(correlation_p_matrix(numeric_df)), p_value_matrix = TRUE),
    coefficients = coeffs,
    fit = data.frame(
      Metric = c("R-squared", "Adjusted R-squared", "Residual SE", "F-statistic p-value"),
      Value = c(summary(model)$r.squared, summary(model)$adj.r.squared, sigma(model), pf(summary(model)$fstatistic[1], summary(model)$fstatistic[2], summary(model)$fstatistic[3], lower.tail = FALSE)),
      stringsAsFactors = FALSE
    ),
    diagnostics = data.frame(Observation = review$rows, Fitted = fitted(model), Residual = resid(model), stringsAsFactors = FALSE),
    exclusions = review$exclusions,
    formula = formula_text,
    report_note = sprintf("Regression model: %s. Observations used: %s; excluded after review: %s.", formula_text, nrow(df), nrow(review$exclusions))
  )
}

# Preserve existing return fields while surfacing model health in reports.
run_design_analysis <- capture_analysis_health(run_design_analysis)
run_pooled_anova <- capture_analysis_health(run_pooled_anova)
run_pooled_split_plot <- capture_analysis_health(run_pooled_split_plot)
run_split_plot <- capture_analysis_health(run_split_plot)
run_correlation_regression <- capture_analysis_health(run_correlation_regression)

run_design_layout <- local({
  engine <- run_design_layout
  function(design, seed = 1, ...) {
    out <- engine(design, seed = seed, ...)
    book <- out$fieldbook
    book$PlotID <- sprintf("P%05d",seq_len(nrow(book)))
    block <- if("Block" %in% names(book)) book$Block else if("Replication" %in% names(book)) book$Replication else rep(1,nrow(book))
    if(!"Row" %in% names(book)) book$Row <- as.integer(factor(block))
    if(!"Column" %in% names(book)) book$Column <- as.integer(ave(seq_len(nrow(book)),block,FUN=seq_along))
    book$Seed <- seed
    book$Response <- NA_real_
    out$fieldbook <- book
    out
  }
})
