library(dplyr)
library(tidyr)
library(agricolae)
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
  `Factorial RBD` = "trt\tRep1\tRep2\tRep3\nA1B1\t25.4\t26.1\t24.8\nA1B2\t28.2\t27.5\t29.1\nA2B1\t21.0\t22.4\t20.8\nA2B2\t30.5\t31.2\t30.9"
)

pooled_example <- "Season\tRep\tTreatment\tValue\nKharif-2024\tR1\tT1\t25.4\nKharif-2024\tR2\tT1\t26.1\nKharif-2024\tR1\tT2\t28.2\nKharif-2024\tR2\tT2\t27.8\nRabi-2025\tR1\tT1\t24.9\nRabi-2025\tR2\tT1\t25.5\nRabi-2025\tR1\tT2\t29.0\nRabi-2025\tR2\tT2\t28.6"
split_plot_example <- "Rep\tMainPlot\tSubPlot\tValue\nR1\tI1\tV1\t28.1\nR1\tI1\tV2\t31.5\nR1\tI2\tV1\t30.2\nR1\tI2\tV2\t34.6\nR2\tI1\tV1\t27.4\nR2\tI1\tV2\t30.8\nR2\tI2\tV1\t29.9\nR2\tI2\tV2\t33.8"
correlation_example <- "Yield\tRainfall\tNitrogen\tPlantHeight\n42.1\t740\t90\t112\n45.0\t780\t100\t116\n39.8\t690\t85\t109\n50.3\t820\t110\t122\n47.4\t800\t105\t118"

format_anova_table <- function(model) {
  out <- as.data.frame(anova(model))
  out$Term <- rownames(out)
  rownames(out) <- NULL
  out
}

run_design_analysis <- function(df, design, levels_a = 2, levels_b = 2, alpha = 0.05) {
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

  lsd <- if (design %in% c("CRD", "RBD")) {
    LSD.test(model, "Trt", alpha = alpha, console = FALSE)
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

  means <- lsd$means
  groups <- lsd$groups

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
    lsd_stats = metrics_table(lsd$statistics),
    report_note = sprintf("Model: %s at alpha %.2f", design, alpha),
    factorial = factorial_details
  )
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

run_split_plot <- function(df, alpha = 0.05) {
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

  full_model <- lmerTest::lmer(Value ~ MainPlot * SubPlot + (1 | Rep), data = df)
  additive_model <- lmerTest::lmer(Value ~ MainPlot + SubPlot + (1 | Rep), data = df)

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

  corr <- round(cor(df[, unique(c(response, predictors)), drop = FALSE], use = "complete.obs"), 4)
  formula_text <- sprintf("%s ~ %s", response, paste(predictors, collapse = " + "))
  model <- lm(as.formula(formula_text), data = df)
  coeffs <- as.data.frame(summary(model)$coefficients)
  coeffs$Term <- rownames(coeffs)
  coeffs <- coeffs[, c("Term", setdiff(names(coeffs), "Term"))]

  list(
    dataset = df,
    correlation = as.data.frame(corr),
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
