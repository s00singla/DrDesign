# Research workflows share explicit review, diagnostics and report metadata.
research_assert <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

research_table <- function(x, row_label = "Term") {
  out <- as.data.frame(x)
  has_named_rows <- !is.null(rownames(out)) &&
    !identical(rownames(out), as.character(seq_len(nrow(out)))) &&
    !all(grepl("^[0-9]+$", rownames(out))) &&
    all(nzchar(trimws(rownames(out))))
  if (has_named_rows) {
    out <- cbind(setNames(data.frame(rownames(out), stringsAsFactors = FALSE), row_label), out)
  }
  if (all(c("Sum Sq", "Mean Sq") %in% names(out))) {
    anova_cols <- c(row_label, "Df", "DF", "NumDF", "DenDF", "Sum Sq", "Mean Sq", "F value", "Pr(>F)")
    out <- out[, c(intersect(anova_cols, names(out)), setdiff(names(out), anova_cols)), drop = FALSE]
  }
  rownames(out) <- NULL
  out
}

research_capture <- function(expr) {
  notes <- character()
  value <- withCallingHandlers(force(expr), warning = function(w) {
    notes <<- c(notes, conditionMessage(w)); invokeRestart("muffleWarning")
  }, message = function(m) {
    msg <- conditionMessage(m)
    if (grepl("singular|converg|misleading|estimab", msg, ignore.case = TRUE)) notes <<- c(notes, msg)
    invokeRestart("muffleMessage")
  })
  list(value = value, warnings = unique(notes))
}

research_result <- function(title, review, tables, plots = list(), notes = character(), settings = list(), references = character()) {
  packages <- c("shiny", "agricolae", "metan", "lme4", "emmeans", "SpATS", "DiallelAnalysisR")
  versions <- data.frame(Package = c("R", packages), Version = c(as.character(getRversion()), vapply(packages, function(p) if (requireNamespace(p, quietly = TRUE)) as.character(packageVersion(p)) else "Not installed", character(1))), row.names = NULL)
  tables <- c(tables, list("Exclusions" = review$exclusions, "Reviewed data" = review$data, "Software versions" = versions))
  if (length(settings)) tables[["Analysis settings"]] <- data.frame(Setting = names(settings), Value = vapply(settings, function(x) paste(x, collapse = ", "), character(1)), row.names = NULL)
  list(title = title, dataset = review$data, exclusions = review$exclusions, tables = tables, plots = plots,
       settings = settings, warnings = unique(notes), status = if (length(notes)) "Review diagnostics" else "Completed",
       references = references, generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))
}

research_unique <- function(data, keys) {
  research_assert(!anyDuplicated(data[keys]), paste("Duplicate experimental units for", paste(keys, collapse = ", ")))
}

research_balanced <- function(data, keys) {
  research_unique(data, keys)
  research_assert(all(do.call(table, data[keys]) == 1), paste("A complete balanced layout is required for", paste(keys, collapse = " x ")))
  research_assert(all(vapply(data[keys], function(x) length(unique(x)) >= 2, logical(1))), "Each design factor needs at least two levels.")
}

research_means_plot <- function(table, label, value, title) {
  ggplot2::ggplot(table, ggplot2::aes(x = .data[[label]], y = .data[[value]])) +
    ggplot2::geom_point(color = "#245f49", size = 2) + ggplot2::coord_flip() +
    ggplot2::theme_minimal() + ggplot2::labs(title = title, x = label, y = value)
}

run_data_preparation <- function(data, traits, ids, exclude_missing = FALSE, wide = FALSE) {
  if (wide) {
    research_assert(length(ids) == 1 && length(traits) >= 2, "Wide conversion requires one treatment identifier and at least two replication columns.")
    data <- tidyr::pivot_longer(data, cols = tidyselect::all_of(traits), names_to = "Replication", values_to = "Response")
    traits <- "Response"; ids <- c(ids, "Replication")
  }
  review <- review_observations(data, traits, ids, exclude_missing)
  duplicate_rows <- if (length(ids)) which(duplicated(review$data[ids]) | duplicated(review$data[ids], fromLast = TRUE)) else integer()
  summary <- data.frame(Check = c("Input observations", "Retained observations", "Excluded observations", "Rows sharing identifiers"), Count = c(nrow(data), nrow(review$data), nrow(review$exclusions), length(duplicate_rows)))
  notes <- if (length(duplicate_rows)) "Repeated identifiers found. Confirm whether these are subsamples or duplicate experimental units before analysis." else character()
  tables <- list("Validation summary" = summary, "Repeated identifiers" = review$data[duplicate_rows, , drop = FALSE])
  if (length(ids)) tables[["Design counts"]] <- as.data.frame(do.call(table, review$data[ids]))
  research_result("Data Preparation & Trial Validation", review, tables, notes = notes,
                  settings = list(Traits = traits, Identifiers = ids, Wide_conversion = wide))
}

run_augmented_trial <- function(data, checks, alpha = 0.05, exclude_missing = FALSE) {
  review <- review_observations(data, "Value", c("Block", "Genotype"), exclude_missing)
  d <- review$data; research_unique(d, c("Block", "Genotype"))
  checks <- unique(checks)
  research_assert(length(checks) >= 2 && all(checks %in% d$Genotype), "Select at least two check genotypes present in the data.")
  b <- nlevels(d$Block)
  research_assert(b >= 2, "At least two blocks are required.")
  counts <- table(d$Genotype)
  research_assert(all(counts[checks] == b) && all(counts[setdiff(names(counts), checks)] == 1) && length(counts) > length(checks), "Checks must occur once in every block; test entries must each occur exactly once.")
  # DAU.test evaluates the response expression inside a formula; pass a local symbol.
  block <- d$Block; trt <- d$Genotype; y <- d$Value
  fit <- agricolae::DAU.test(block, trt, y, method = "lsd", alpha = alpha, group = FALSE)
  model <- lm(Value ~ Block + Genotype, d)
  research_assert(df.residual(model) > 0, "The check design has no residual degrees of freedom.")
  means <- research_table(fit$means, "Genotype")
  means$IsCheck <- means$Genotype %in% checks
  check_mean <- mean(means$mean.adj[means$IsCheck])
  means$DifferenceFromCheckMean <- means$mean.adj - check_mean
  aug_cols <- c("Genotype", "IsCheck", "r", "y", "mean.adj", "SE", "DifferenceFromCheckMean", "std", "block", "LCL", "UCL", "Min", "Max", "Q25", "Q50", "Q75")
  means <- means[, c(intersect(aug_cols, names(means)), setdiff(names(means), aug_cols)), drop = FALSE]
  rownames(means) <- NULL
  research_result("Augmented Trial Analysis", review,
    list("Adjusted means" = means, "ANOVA: blocks then adjusted genotypes" = research_table(anova(model)),
         "LSD comparisons" = research_table(fit$comparison, "Comparison"), "Comparison standard errors" = research_table(fit$SE.difference)),
    plots = list("Adjusted means" = research_means_plot(means, "Genotype", "mean.adj", "Adjusted genotype means")),
    notes = "Fisher LSD comparisons are unadjusted for multiplicity. Interpret planned comparisons in their experimental context.",
    settings = list(Checks = checks, Alpha = alpha, Method = "Augmented RCBD; Fisher LSD"), references = "agricolae::DAU.test")
}

run_strip_trial <- function(data, alpha = 0.05, exclude_missing = FALSE) {
  review <- review_observations(data, "Value", c("Rep", "FactorA", "FactorB"), exclude_missing)
  d <- review$data; research_balanced(d, c("Rep", "FactorA", "FactorB"))
  invisible(capture.output(fit <- agricolae::strip.plot(d$Rep, d$FactorA, d$FactorB, d$Value)))
  model <- aov(Value ~ FactorA * FactorB + Error(Rep + Rep:FactorA + Rep:FactorB), data = d,
               contrasts = list(Rep = "contr.sum", FactorA = "contr.sum", FactorB = "contr.sum"))
  emm <- emmeans::emmeans(model, ~ FactorA * FactorB, level = 1-alpha)
  means <- as.data.frame(emm)
  a_in_b <- as.data.frame(pairs(emmeans::emmeans(model, ~ FactorA | FactorB), adjust = "tukey"))
  if (all(c("FactorB", "contrast") %in% names(a_in_b))) {
    a_in_b <- a_in_b[, c("FactorB", "contrast", setdiff(names(a_in_b), c("FactorB", "contrast"))), drop = FALSE]
  }
  b_in_a <- as.data.frame(pairs(emmeans::emmeans(model, ~ FactorB | FactorA), adjust = "tukey"))
  if (all(c("FactorA", "contrast") %in% names(b_in_a))) {
    b_in_a <- b_in_a[, c("FactorA", "contrast", setdiff(names(b_in_a), c("FactorA", "contrast"))), drop = FALSE]
  }
  tables <- list("ANOVA" = research_table(fit$ANOVA), "Interaction means" = means,
    "Factor A comparisons" = as.data.frame(pairs(emmeans::emmeans(model, ~ FactorA), adjust = "tukey")),
    "Factor B comparisons" = as.data.frame(pairs(emmeans::emmeans(model, ~ FactorB), adjust = "tukey")),
    "A within B comparisons" = a_in_b,
    "B within A comparisons" = b_in_a)
  plot <- ggplot2::ggplot(means, ggplot2::aes(FactorA, emmean, color = FactorB, group = FactorB)) + ggplot2::geom_point() + ggplot2::geom_line() + ggplot2::theme_minimal()
  research_result("Strip-Plot Analysis", review, tables, list("Interaction" = plot),
    settings = list(Alpha = alpha, Errors = "Rep:A, Rep:B, residual interaction", Comparisons = "Tukey within each displayed family"), references = "agricolae::strip.plot; emmeans")
}

run_genetic_variability <- function(data, traits, alpha = 0.05, selection_percent = 15, exclude_missing = FALSE, incomplete = FALSE, genotype_random = TRUE) {
  ids <- c("Genotype", "Rep", if (incomplete) "Block")
  review <- review_observations(data, traits, ids, exclude_missing)
  d <- review$data; research_unique(d, c("Genotype", "Rep"))
  research_assert(nlevels(d$Genotype) >= 3 && nlevels(d$Rep) >= 2, "At least three genotypes and two replications are required.")
  research_assert(selection_percent > 0 && selection_percent < 100, "Selection percentage must be between 0 and 100.")
  if (incomplete) {
    research_balanced(d, c("Genotype", "Rep"))
    block_sizes <- table(interaction(d$Rep, d$Block, drop = TRUE))
    research_assert(length(unique(block_sizes)) == 1 && min(block_sizes) >= 2 && min(block_sizes) < nlevels(d$Genotype), "Incomplete blocks must have equal size, at least two entries, and fewer entries than a complete replicate.")
  }
  tables <- list(); notes <- character(); matrix <- data.frame(Genotype = levels(d$Genotype))
  for (trait in traits) {
    z <- data.frame(GEN = d$Genotype, REP = d$Rep, Y = d[[trait]])
    if (incomplete) z$BLOCK <- d$Block
    if (!genotype_random) {
      fit <- lmerTest::lmer(Y ~ GEN + REP + (1 | REP:BLOCK), z)
      means <- as.data.frame(emmeans::emmeans(fit, ~ GEN, level = 1 - alpha))
      tables[[paste(trait, "adjusted means")]] <- means
      tables[[paste(trait, "ANOVA")]] <- research_table(anova(fit))
      matrix[[trait]] <- means$emmean[match(matrix$Genotype, means$GEN)]
      if (lme4::isSingular(fit)) notes <- c(notes, paste(trait, "has a singular block variance fit."))
      next
    }
    fit <- if (incomplete) metan::gamem(z, GEN, REP, Y, block = BLOCK, prob = alpha, verbose = FALSE) else metan::gamem(z, GEN, REP, Y, prob = alpha, verbose = FALSE)
    model <- fit[[1]]$modellme
    vc <- as.data.frame(lme4::VarCorr(model)); vg <- vc$vcov[vc$grp == "GEN"]; ve <- sigma(model)^2
    balanced <- all(table(d$Genotype, d$Rep) == 1)
    r <- nlevels(d$Rep); avg <- mean(z$Y)
    hplot <- vg / (vg + ve); hmean <- if (balanced && !incomplete) vg / (vg + ve/r) else NA_real_
    intensity <- dnorm(qnorm(1 - selection_percent/100)) / (selection_percent/100)
    pars <- data.frame(Trait = trait, GeneticVariance = vg, ResidualVariance = ve,
      H2_plot_conditional_on_blocks = hplot, H2_entry_mean_balanced_RCBD = hmean,
      GCV_percent = if (avg > 0) 100 * sqrt(vg)/avg else NA_real_, PCV_plot_percent = if (avg > 0) 100 * sqrt(vg+ve)/avg else NA_real_,
      SelectionAccuracy_balanced_RCBD = sqrt(hmean), GeneticAdvance_entry_mean = intensity * sqrt(vg+ve/r) * hmean)
    tables[[paste(trait, "genetic parameters")]] <- pars
    tables[[paste(trait, "variance components")]] <- research_table(vc)
    pred <- research_table(fit[[1]]$BLUPgen)
    pred <- pred[,setdiff(names(pred),c("LL","UL")),drop=FALSE]
    conditional <- lme4::ranef(model,condVar=TRUE)$GEN
    conditional_se <- sqrt(as.numeric(attr(conditional,"postVar")))
    pred$ConditionalSE <- conditional_se[match(pred$GEN,rownames(conditional))]
    pred$EffectLower <- pred$BLUPg-qnorm(1-alpha/2)*pred$ConditionalSE
    pred$EffectUpper <- pred$BLUPg+qnorm(1-alpha/2)*pred$ConditionalSE
    population_mean <- mean(tapply(predict(model,re.form=NA),z$REP,mean))
    pred$Predicted <- population_mean+pred$BLUPg
    blup_cols <- c("GEN", "Predicted", "BLUPg", "ConditionalSE", "EffectLower", "EffectUpper")
    pred <- pred[, c(intersect(blup_cols, names(pred)), setdiff(names(pred), blup_cols)), drop = FALSE]
    rownames(pred) <- NULL
    tables[[paste(trait, "BLUPs")]] <- pred
    # Population mean includes the average fixed replication effect.
    re <- lme4::ranef(model)$GEN[, 1]
    matrix[[trait]] <- population_mean + re[match(matrix$Genotype, rownames(lme4::ranef(model)$GEN))]
    if (lme4::isSingular(model)) notes <- c(notes, paste(trait, "has a boundary/singular variance fit; interpret genetic parameters cautiously."))
    if (!balanced || incomplete) notes <- c(notes, paste(trait, "simple balanced-RCBD entry-mean heritability and advance are not reported for this design."))
    notes <- c(notes,"BLUP effect intervals use conditional random-effect uncertainty with fitted variance components held fixed. They are not confidence intervals for the absolute predicted genotype mean.")
  }
  tables[["Genotype trait matrix"]] <- matrix
  research_result(if (incomplete) "Incomplete-Block Trials" else "Genetic Variability & Heritability", review, tables,
    plots = list("Genotype estimates" = research_means_plot(matrix, "Genotype", traits[1], paste("Genotype estimates:", traits[1]))),
    notes = notes, settings = list(Traits = traits, Replication = "Fixed", Genotype = if (genotype_random) "Random" else "Fixed", Selection_percent = selection_percent, Alpha = alpha), references = "metan::gamem; lme4; emmeans")
}

run_multi_trait_selection <- function(data, traits, lower_traits = character(), weights = rep(1, length(traits)), selection_percent = 15, method = "weighted", exclude_missing = FALSE) {
  review <- review_observations(data, traits, "Genotype", exclude_missing)
  d <- review$data; research_unique(d, "Genotype")
  research_assert(length(traits) >= 2 && nrow(d) >= 3, "Provide at least two traits and three genotypes.")
  research_assert(length(weights) == length(traits) && all(is.finite(weights)) && all(weights >= 0) && sum(weights) > 0, "Supply one nonnegative weight per trait, with at least one positive weight.")
  research_assert(selection_percent > 0 && selection_percent < 100, "Selection percentage must be between 0 and 100.")
  x <- as.matrix(d[traits]); rownames(x) <- as.character(d$Genotype)
  research_assert(all(apply(x, 2, sd) > 0), "Remove constant traits.")
  direction <- ifelse(traits %in% lower_traits, -1, 1)
  tables <- list(); notes <- character()
  if (method == "mgidi") {
    research_assert(nrow(x) > ncol(x) && qr(cor(x))$rank == ncol(x), "MGIDI needs more genotypes than traits and a full-rank trait correlation matrix.")
    fit <- metan::mgidi(data.frame(Genotype = rownames(x), x, check.names = FALSE), SI = selection_percent, ideotype = ifelse(direction > 0, "h", "l"), weights = weights / max(weights), verbose = FALSE)
    ranking <- as.data.frame(fit$MGIDI); names(ranking)[1:2] <- c("Genotype", "Score")
    ranking <- ranking[order(ranking$Score, ranking$Genotype), , drop = FALSE]
    tables[["Factor loadings"]] <- research_table(fit$finish_loadings)
  } else {
    score <- as.numeric(scale(x) %*% (weights/sum(weights) * direction))
    ranking <- data.frame(Genotype = d$Genotype, Score = score)
    ranking <- ranking[order(-ranking$Score, ranking$Genotype), , drop = FALSE]
  }
  nselect <- max(1L, ceiling(nrow(d) * selection_percent/100))
  cutoff <- ranking$Score[nselect]
  ranking$Selected <- if (method == "mgidi") ranking$Score <= cutoff else ranking$Score >= cutoff
  ranking$Rank <- rank(if (method == "mgidi") ranking$Score else -ranking$Score, ties.method = "min")
  rank_cols <- c("Genotype", "Rank", "Score", "Selected")
  ranking <- ranking[, c(intersect(rank_cols, names(ranking)), setdiff(names(ranking), rank_cols)), drop = FALSE]
  rownames(ranking) <- NULL
  selected <- as.character(ranking$Genotype[ranking$Selected])
  differential <- data.frame(Trait = traits, Desired = ifelse(direction > 0, "Higher", "Lower"), PopulationMean = colMeans(x), SelectedMean = colMeans(x[rownames(x) %in% selected, , drop = FALSE]), row.names = NULL)
  differential$Differential <- differential$SelectedMean - differential$PopulationMean
  notes <- "Selection differentials describe this input matrix, not predicted genetic gain. Ties at the selection boundary are retained. Confirm whether inputs are means, adjusted means, or BLUPs."
  research_result("Multi-Trait Selection", review, c(list("Rankings" = ranking, "Selection differentials" = differential), tables),
    list("Selection scores" = research_means_plot(ranking, "Genotype", "Score", method)), notes,
    list(Method = method, Lower_traits = lower_traits, Weights = weights, Selection_percent = selection_percent), "metan::mgidi; weighted direction-adjusted standardized scores")
}

run_diversity <- function(data, traits, clusters = 2, exclude_missing = FALSE) {
  review <- review_observations(data, traits, "Genotype", exclude_missing)
  d <- review$data; research_unique(d, "Genotype")
  research_assert(length(traits) >= 2 && nrow(d) >= 3, "Provide at least two traits and three genotypes.")
  research_assert(all(vapply(d[traits], sd, numeric(1)) > 0), "Remove constant traits before PCA.")
  research_assert(clusters >= 2 && clusters < nrow(d) && clusters == as.integer(clusters), "Clusters must be an integer from 2 to one less than the genotype count.")
  x <- as.matrix(d[traits]); rownames(x) <- as.character(d$Genotype)
  fit <- prcomp(x, center = TRUE, scale. = TRUE)
  tree <- hclust(dist(scale(x)), method = "ward.D2")
  scores <- data.frame(Genotype = rownames(x), fit$x, Cluster = cutree(tree, clusters), row.names = NULL)
  variance <- data.frame(Component = colnames(fit$x), VariancePercent = 100 * fit$sdev^2/sum(fit$sdev^2), row.names = NULL)
  variance$CumulativePercent <- cumsum(variance$VariancePercent)
  p <- ggplot2::ggplot(scores, ggplot2::aes(PC1, PC2, label = Genotype, color = factor(Cluster))) + ggplot2::geom_point() + ggplot2::geom_text(vjust = -0.5, check_overlap = TRUE) + ggplot2::theme_minimal() + ggplot2::labs(color = "Cluster", title = "Standardized PCA scores")
  loading <- data.frame(Trait = rownames(fit$rotation), fit$rotation, row.names = NULL)
  biplot <- p + ggplot2::geom_segment(data = loading, ggplot2::aes(x = 0, y = 0, xend = PC1, yend = PC2), inherit.aes = FALSE, color = "grey30") + ggplot2::geom_text(data = loading, ggplot2::aes(PC1, PC2, label = Trait), inherit.aes = FALSE, color = "grey30")
  dendro <- function() plot(tree, main = "Ward.D2 clustering of standardized traits", xlab = "", sub = "")
  merges_df <- data.frame(Step1 = tree$merge[, 1], Step2 = tree$merge[, 2], Height = tree$height, row.names = NULL)
  research_result("PCA & Diversity Exploration", review,
    list("Explained variance" = variance, "Scores and clusters" = scores, "Loadings" = loading, "Clustering merges" = merges_df),
    list("PCA biplot" = biplot, "Dendrogram" = dendro),
    settings = list(Scaling = "Centre and unit standard deviation", Distance = "Euclidean", Linkage = "Ward.D2", Clusters = clusters), references = "stats::prcomp; stats::hclust")
}

run_power_planning <- function(means, residual_sd, target_power = 0.8, alpha = 0.05, method = "anova") {
  research_assert(length(means) >= 2 && all(is.finite(means)) && var(means) > 0, "Provide at least two finite anticipated means with a nonzero difference.")
  research_assert(is.finite(residual_sd) && residual_sd > 0 && target_power > 0 && target_power < 1 && alpha > 0 && alpha < 1, "SD must be positive; power and alpha must be between 0 and 1.")
  if (method == "two-sample") research_assert(length(means) == 2, "Two-group planning requires exactly two means.")
  power_at <- function(n = NULL, power = NULL) {
    if (method == "two-sample") power.t.test(n = n, delta = abs(diff(means)), sd = residual_sd, sig.level = alpha, power = power, type = "two.sample", alternative = "two.sided") else power.anova.test(groups = length(means), n = n, between.var = var(means), within.var = residual_sd^2, sig.level = alpha, power = power)
  }
  n <- max(2L, ceiling(power_at(power = target_power)$n))
  grid <- unique(pmax(2L, round(seq(max(2, n/2), n*1.5, length.out = 30))))
  curve <- data.frame(ReplicationsPerGroup = grid, Power = vapply(grid, function(k) power_at(n = k)$power, numeric(1)))
  summary <- data.frame(ReplicationsPerGroup = n, Groups = length(means), TotalUnits = n*length(means), TargetPower = target_power, AchievedPower = power_at(n = n)$power)
  review <- list(data = data.frame(Group = seq_along(means), AnticipatedMean = means), exclusions = data.frame(Observation = integer(), Reason = character()))
  plot <- ggplot2::ggplot(curve, ggplot2::aes(ReplicationsPerGroup, Power)) + ggplot2::geom_line() + ggplot2::geom_hline(yintercept = target_power, linetype = 2) + ggplot2::theme_minimal()
  research_result("Power & Replication Planning", review, list("Recommended design" = summary, "Sensitivity" = curve), list("Power curve" = plot),
    notes = "Assumes independent normal observations and common residual variance. This calculation does not account for blocking, split plots, or attrition.",
    settings = list(Method = method, ResidualSD = residual_sd, Alpha = alpha, TargetPower = target_power), references = "stats::power.anova.test; stats::power.t.test")
}

run_alpha_layout <- function(treatments = 12, block_size = 3, replications = 3, seed = 7) {
  research_assert(all(c(treatments, block_size, replications, seed) == as.integer(c(treatments, block_size, replications, seed))) && treatments >= 4 && block_size >= 2 && treatments %% block_size == 0 && block_size < treatments && replications >= 2, "Use integer counts, with block size dividing the treatment count and at least two replications.")
  trt <- paste0("G", seq_len(treatments))
  fit <- agricolae::design.alpha(trt, k = block_size, r = replications, seed = seed)
  book <- fit$book
  names(book)[names(book) == "trt"] <- "Genotype"
  book$PlotID <- sprintf("P%04d", seq_len(nrow(book)))
  book$Row <- rep(seq_len(replications), each = treatments)
  book$Column <- rep(seq_len(treatments), replications)
  book$Seed <- seed; book$Response <- NA_real_
  book_cols <- c("PlotID", "replication", "block", "plots", "cols", "Row", "Column", "Genotype", "Seed", "Response")
  book <- book[, c(intersect(book_cols, names(book)), setdiff(names(book), book_cols)), drop = FALSE]
  rownames(book) <- NULL
  research_assert(nrow(book) == treatments*replications, "Layout generation failed to allocate all units.")
  book
}

run_spatial_trial <- function(data, genotype_random = FALSE, alpha = 0.05, exclude_missing = FALSE) {
  research_assert(requireNamespace("SpATS", quietly = TRUE), "The SpATS dependency is required for spatial analysis.")
  review <- review_observations(data, c("Value", "Row", "Column"), c("Genotype", "Rep"), exclude_missing)
  d <- review$data; research_unique(d, c("Row", "Column"))
  research_assert(length(unique(d$Row)) >= 4 && length(unique(d$Column)) >= 4, "Spatial smoothing requires at least four distinct row and column coordinates.")
  research_assert(nlevels(d$Genotype) >= 3 && nlevels(d$Rep) >= 2, "Provide at least three genotypes and two replications.")
  fit <- SpATS::SpATS(response = "Value", genotype = "Genotype", genotype.as.random = genotype_random,
    spatial = ~ SpATS::PSANOVA(Column, Row, nseg = c(3, 3)), fixed = ~ Rep, data = d,
    control = list(tolerance = 1e-05, monitoring = 0, maxit = 200))
  predictions <- as.data.frame(predict(fit, which = "Genotype", predFixed = "marginal"))
  pred_cols <- c("Genotype", "predicted.values", "standard.errors", "weights")
  predictions <- predictions[, c(intersect(pred_cols, names(predictions)), setdiff(names(predictions), pred_cols)), drop = FALSE]
  rownames(predictions) <- NULL
  base <- if (genotype_random) lme4::lmer(Value ~ Rep + (1 | Genotype), d) else lm(Value ~ Rep + Genotype, d)
  diagnostic <- data.frame(Observation = review$rows, Row = d$Row, Column = d$Column, Fitted = fit$fitted, Residual = fit$residuals, NonspatialResidual = residuals(base), row.names = NULL)
  surfaces <- function() SpATS::plot.SpATS(fit)
  residual_map <- ggplot2::ggplot(diagnostic, ggplot2::aes(Column, Row, fill = Residual)) + ggplot2::geom_tile() + ggplot2::scale_fill_gradient2() + ggplot2::coord_equal() + ggplot2::theme_minimal()
  comparison <- data.frame(Model = c("Spatial", "Nonspatial"), ResidualRMSE = c(sqrt(mean(fit$residuals^2)), sqrt(mean(residuals(base)^2))), row.names = NULL)
  notes <- "RMSE is descriptive in-sample fit, not evidence of predictive superiority. Spatial genotype standard errors are supplied by SpATS."
  if (fit$niterations >= 200) notes <- c(notes, "Spatial model reached its iteration limit. Treat estimates as unverified.")
  research_result("Spatial Field Analysis", review, list("Genotype predictions" = predictions, "Residual diagnostics" = diagnostic, "Model comparison" = comparison,
    "Variance components" = data.frame(Component = names(fit$var.comp), Variance = unlist(fit$var.comp), row.names = NULL)),
    list("Residual field map" = residual_map, "Spatial surfaces" = surfaces), notes,
    list(Genotype = if (genotype_random) "Random" else "Fixed", Replication = "Fixed", Spatial = "PSANOVA(Column, Row), 3 x 3 segments", Alpha = alpha), "SpATS::SpATS; Rodriguez-Alvarez et al. (2018), Spatial Statistics 23:52-71")
}

research_flat_tables <- function(x, prefix = "Results") {
  if (is.data.frame(x) || is.matrix(x)) return(setNames(list(research_table(x)), prefix))
  if (!is.list(x)) return(list())
  out <- list()
  for (nm in names(x)) out <- c(out, research_flat_tables(x[[nm]], paste(prefix, nm)))
  out
}

run_combining_ability <- function(data, method = "line-tester", alpha = 0.05, exclude_missing = FALSE) {
  review <- review_observations(data, "Value", c("Rep", "Parent1", "Parent2"), exclude_missing)
  d <- review$data
  if (method == "line-tester") {
    research_balanced(d, c("Rep", "Parent1", "Parent2"))
    # agricolae::lineXtester requires additional parent rows and cannot fit a
    # crosses-only trial. Use the fixed balanced factorial model explicitly.
    model <- lm(Value ~ Rep + Parent1 * Parent2, d)
    emm <- emmeans::emmeans(model, ~ Parent1 * Parent2,level=1-alpha)
    cells <- as.data.frame(emm); N <- nrow(cells)
    grand <- rep(1/N, N); contrasts <- list()
    for (p in levels(d$Parent1)) contrasts[[paste("Line GCA",p)]] <- as.numeric(cells$Parent1==p)/nlevels(d$Parent2)-grand
    for (p in levels(d$Parent2)) contrasts[[paste("Tester GCA",p)]] <- as.numeric(cells$Parent2==p)/nlevels(d$Parent1)-grand
    for (i in seq_len(N)) contrasts[[paste("SCA",cells$Parent1[i],cells$Parent2[i])]] <- as.numeric(seq_len(N)==i)-as.numeric(cells$Parent1==cells$Parent1[i])/nlevels(d$Parent2)-as.numeric(cells$Parent2==cells$Parent2[i])/nlevels(d$Parent1)+grand
    effects <- as.data.frame(summary(emmeans::contrast(emm,contrasts),infer=c(TRUE,TRUE),level=1-alpha,adjust="none"))
    effects$HolmP <- p.adjust(effects$p.value,"holm")
    fit <- list(ANOVA=anova(model),AdjustedMeans=cells,Effects=effects)
  } else {
    research_assert(requireNamespace("DiallelAnalysisR", quietly = TRUE), "DiallelAnalysisR is required for diallel analysis.")
    parents <- sort(unique(c(as.character(d$Parent1), as.character(d$Parent2))))
    research_assert(length(parents) >= 3 && nlevels(d$Rep) >= 2, "Diallel analysis requires at least three parents and two replications.")
    a <- match(d$Parent1, parents); b <- match(d$Parent2, parents)
    d$Cross <- paste(pmin(a, b), pmax(a, b), sep = ":")
    research_unique(d, c("Rep", "Cross"))
    research_assert(all(table(d$Rep, d$Cross) == 1) && length(unique(d$Cross)) == length(parents)*(length(parents)+1)/2, "Method II requires every parent and one copy of every F1 cross per replicate, without reciprocals.")
    d$Parent1 <- factor(parents[pmin(a,b)], levels = parents); d$Parent2 <- factor(parents[pmax(a,b)], levels = parents)
    invisible(capture.output(fit <- DiallelAnalysisR::Griffing(y = Value, Rep = Rep, Cross1 = Parent1, Cross2 = Parent2, data = d, Method = 2, Model = 1)))
    # Derive uncertainty from residual error. The installed package's Method II
    # StdErr uses the replication mean square, so do not expose that field.
    model <- lm(Value ~ Rep + Cross, d)
    emm <- emmeans::emmeans(model, ~ Cross,level=1-alpha)
    cells <- as.data.frame(emm)
    indices <- do.call(rbind,strsplit(as.character(cells$Cross),":",fixed=TRUE))
    indices <- matrix(as.integer(indices),ncol=2)
    n <- length(parents); N <- nrow(cells); grand <- rep(1/N,N)
    gca <- lapply(seq_len(n),function(p) ((indices[,1]==p)+(indices[,2]==p)-2/n)/(n+2))
    contrasts <- setNames(gca,paste("GCA",parents))
    for (i in seq_len(N)) contrasts[[paste("SCA",parents[indices[i,1]],parents[indices[i,2]])]] <- as.numeric(seq_len(N)==i)-gca[[indices[i,1]]]-gca[[indices[i,2]]]-grand
    effects <- as.data.frame(summary(emmeans::contrast(emm,contrasts),infer=c(TRUE,TRUE),level=1-alpha,adjust="none"))
    effects$HolmP <- p.adjust(effects$p.value,"holm")
    fit <- list(ANOVA=fit$ANOVA,AdjustedMeans=cells,Effects=effects,TrialANOVA=anova(model))
  }
  tables <- research_flat_tables(fit)
  research_assert(length(tables) > 0, "No combining-ability tables were returned.")
  research_result("Combining Ability", review, tables,
    notes = "Fixed parental set: inference concerns the tested parents. GCA/SCA effects do not by themselves establish additive/dominance variance in a wider population.",
    settings = list(Method = method, Model = "Fixed parental effects; balanced single environment", Alpha = alpha), references = if (method == "line-tester") "Fixed Rep + Line * Tester linear model; marginal and interaction contrasts via emmeans" else "DiallelAnalysisR::Griffing, Method II, Model I")
}

run_heterosis <- function(data, parent1, parent2, hybrids, check = NULL, lower_better = FALSE, alpha = 0.05, exclude_missing = FALSE) {
  review <- review_observations(data, "Value", c("Rep", "Genotype"), exclude_missing)
  d <- review$data; research_balanced(d, c("Rep", "Genotype"))
  levels <- levels(d$Genotype)
  research_assert(parent1 != parent2 && all(c(parent1, parent2, hybrids, check) %in% levels) && length(hybrids) > 0 && !any(hybrids %in% c(parent1, parent2, check)), "Select two distinct parents, at least one separate hybrid, and an optional separate check.")
  model <- lm(Value ~ Rep + Genotype, d)
  emm <- emmeans::emmeans(model, ~ Genotype,level=1-alpha)
  tab <- as.data.frame(emm)
  best <- c(parent1, parent2)[if (lower_better) which.min(tab$emmean[match(c(parent1,parent2),tab$Genotype)]) else which.max(tab$emmean[match(c(parent1,parent2),tab$Genotype)])]
  rows <- list()
  # Delta-method ratio SE uses the fitted covariance of numerator and denominator.
  covm <- vcov(emm); mu <- tab$emmean; lev <- as.character(tab$Genotype)
  for (hybrid in hybrids) for (kind in c("Mid-parent", "Better-parent", if (!is.null(check) && nzchar(check)) "Standard")) {
    num <- as.numeric(lev == hybrid)
    den <- switch(kind, "Mid-parent" = as.numeric(lev %in% c(parent1,parent2))/2, "Better-parent" = as.numeric(lev == best), "Standard" = as.numeric(lev == check))
    h <- sum(num*mu); ref <- sum(den*mu); diff <- num-den
    contrast <- as.data.frame(summary(emmeans::contrast(emm, list(Difference = diff)), infer = c(TRUE, TRUE), level = 1-alpha))
    percent <- if (abs(ref) > sqrt(.Machine$double.eps)) 100*(h/ref-1) else NA_real_
    gradient <- if (is.finite(percent)) 100*(num/ref - h*den/ref^2) else rep(NA_real_, length(mu))
    se <- sqrt(as.numeric(t(gradient) %*% covm %*% gradient))
    crit <- qt(1-alpha/2, df.residual(model))
    rows[[length(rows)+1]] <- data.frame(Hybrid = hybrid, Comparison = kind, ReferenceMean = ref, Difference = contrast$estimate, DifferenceSE = contrast$SE,
      HeterosisPercent = percent, ApproxSEPercent = se, ApproxLower = percent-crit*se, ApproxUpper = percent+crit*se, DifferenceP = contrast$p.value, row.names = NULL)
  }
  out <- do.call(rbind, rows); out$HolmP <- p.adjust(out$DifferenceP, "holm")
  rownames(out) <- NULL
  research_result("Heterosis", review, list("Heterosis estimates" = out, "Adjusted means" = tab, "ANOVA" = research_table(anova(model))),
    notes = "Percentage intervals use the delta method and are unreliable near a zero reference mean. Zero-reference percentages are undefined. Better-parent intervals are conditional on the observed selected parent. Holm p-values adjust the family of displayed difference tests.",
    settings = list(Parent1 = parent1, Parent2 = parent2, Lower_is_better = lower_better, Alpha = alpha), references = "RCBD linear contrasts; delta-method ratio uncertainty")
}

run_generation_means <- function(data, alpha = 0.05) {
  review <- review_observations(data, c("Mean", "SE"), "Generation")
  d <- review$data; generations <- c("P1", "P2", "F1", "F2", "BC1", "BC2")
  research_assert(nrow(d) == 6 && setequal(as.character(d$Generation), generations), "Supply exactly one row for P1, P2, F1, F2, BC1 and BC2.")
  research_assert(all(d$SE > 0), "All generation-mean standard errors must be positive.")
  d <- d[match(generations, d$Generation), ]; y <- d$Mean; v <- d$SE^2
  a <- c(1,-1,0,0,0.5,-0.5); dominance <- c(0,0,1,0.5,0.5,0.5)
  X <- cbind(m = 1, d = a, h = dominance, i = a^2, j = a*dominance, l = dominance^2)
  fit <- function(k) {
    x <- X[,seq_len(k),drop=FALSE]; V <- solve(crossprod(x, x/v)); beta <- V %*% crossprod(x,y/v); se <- sqrt(diag(V))
    data.frame(Parameter = colnames(x), Estimate = as.numeric(beta), SE = se, Lower = as.numeric(beta)-qnorm(1-alpha/2)*se, Upper = as.numeric(beta)+qnorm(1-alpha/2)*se, Z = as.numeric(beta)/se, P = 2*pnorm(-abs(as.numeric(beta)/se)), row.names = NULL)
  }
  reduced <- fit(3); full <- fit(6); expected <- as.numeric(X[,1:3] %*% reduced$Estimate)
  lackfit <- sum((y-expected)^2/v)
  L <- rbind(A = c(-1,0,-1,0,2,0), B = c(0,-1,-1,0,0,2), C = c(-1,-1,-2,4,0,0), D = c(0,0,0,2,-1,-1))
  estimates <- as.numeric(L %*% y); errors <- sqrt(diag(L %*% diag(v) %*% t(L)))
  scales <- data.frame(Scale = rownames(L), Estimate = estimates, SE = errors, Z = estimates/errors, P = 2*pnorm(-abs(estimates/errors)), row.names = NULL)
  research_result("Generation-Mean Analysis", review,
    list("Three-parameter estimates" = reduced, "Six-parameter estimates" = full, "Scaling tests" = scales,
         "Three-parameter lack of fit" = data.frame(ChiSquare = lackfit, DF = 3, P = pchisq(lackfit,3,lower.tail=FALSE), row.names = NULL),
         "Coefficient matrix" = data.frame(Generation = generations, X, row.names = NULL)),
    notes = "Assumes independent generation means and supplied sampling variances. Normal approximations use supplied SEs. The six-parameter model is saturated and has no lack-of-fit test. Parameterization uses coefficients 1, a, b, a^2, ab, b^2; inspect the exported coefficient matrix.",
    settings = list(Alpha = alpha, Weight = "Inverse variance of generation means"), references = "Weighted generation-mean linear model; Mather-Jinks scaling contrasts")
}
