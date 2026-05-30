############################################################
# MET stability analysis backend
# AMMI, GGE, WAASB/WAASBY, BLUP stability, and batch summaries
############################################################

met_required_packages <- function() {
  pkgs <- c("metan", "lme4", "lmerTest")
  missing_pkgs <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_pkgs) > 0) {
    stop(paste0(
      "Missing packages required for MET analysis: ",
      paste(missing_pkgs, collapse = ", "),
      ". Install with: install.packages(c(",
      paste(sprintf('"%s"', missing_pkgs), collapse = ", "),
      "))"
    ))
  }
  invisible(TRUE)
}

met_direction_label <- function(direction) {
  if (identical(direction, "l")) "lower_is_better" else "higher_is_better"
}

met_rank <- function(x, direction = "h") {
  if (identical(direction, "l")) {
    rank(x, ties.method = "first", na.last = "keep")
  } else {
    rank(-x, ties.method = "first", na.last = "keep")
  }
}

met_clean_numeric <- function(x) {
  suppressWarnings(as.numeric(x))
}

met_as_table <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.data.frame(x)) return(as.data.frame(x, stringsAsFactors = FALSE))
  if (is.list(x) && length(x) > 0 && is.data.frame(x[[1]])) {
    return(as.data.frame(x[[1]], stringsAsFactors = FALSE))
  }
  tryCatch(as.data.frame(x, stringsAsFactors = FALSE), error = function(e) NULL)
}

met_model_data <- function(model, what) {
  out <- metan::get_model_data(model, what = what, verbose = FALSE)
  tbl <- met_as_table(out)
  if (is.null(tbl)) {
    stop("No table returned for get_model_data(..., what = '", what, "').", call. = FALSE)
  }
  rownames(tbl) <- NULL
  tbl
}

met_metric_vector <- function(model, what, metric = "Y") {
  x <- met_model_data(model, what)
  if (!metric %in% names(x)) {
    stop("Expected column '", metric, "' not found in get_model_data(..., what = '", what, "').", call. = FALSE)
  }
  x[[metric]]
}

met_metric_by_gen <- function(model, what, value_name, metric = "Y") {
  x <- met_model_data(model, what)
  gen_col <- intersect(c("GEN", "Genotype", "gen", "GENOTYPE"), names(x))[1]
  if (is.na(gen_col) || !metric %in% names(x)) {
    stop("Expected genotype and ", metric, " columns for get_model_data(..., what = '", what, "').", call. = FALSE)
  }
  out <- data.frame(
    GEN = as.character(x[[gen_col]]),
    value = x[[metric]],
    stringsAsFactors = FALSE
  )
  stats::setNames(out, c("GEN", value_name))
}

met_merge_by_gen <- function(tables) {
  tables <- Filter(Negate(is.null), tables)
  if (length(tables) == 0) return(NULL)
  Reduce(function(x, y) merge(x, y, by = "GEN", all = TRUE), tables)
}

met_safe_metric_by_gen <- function(model, what, value_name, metric = "Y") {
  tryCatch(met_metric_by_gen(model, what, value_name, metric), error = function(e) NULL)
}

validate_met_data <- function(dat) {
  if (nrow(dat) == 0) {
    stop("No observations remain after removing missing values.")
  }
  if (nlevels(dat$GEN) < 2) {
    stop("At least 2 genotypes are required for MET analysis.")
  }
  if (nlevels(dat$ENV) < 2) {
    stop("At least 2 environments are required for MET analysis.")
  }
}

sig_stars <- function(p) {
  ifelse(is.na(p), "",
    ifelse(p < 0.001, "***",
      ifelse(p < 0.01, "**",
        ifelse(p < 0.05, "*",
          ifelse(p < 0.1, ".", "ns")))))
}

format_anova_table <- function(av) {
  av <- as.data.frame(av, stringsAsFactors = FALSE)
  av$Source <- rownames(av)
  rownames(av) <- NULL

  col_or_na <- function(names_to_try) {
    hit <- intersect(names_to_try, names(av))[1]
    if (is.na(hit)) rep(NA_real_, nrow(av)) else av[[hit]]
  }

  data.frame(
    Source = av$Source,
    df = col_or_na(c("Df", "NumDF", "DF")),
    Den_df = col_or_na(c("DenDF", "Den Df")),
    SS = round(col_or_na(c("Sum Sq", "Sum.Sq", "SS")), 4),
    MS = round(col_or_na(c("Mean Sq", "Mean.Sq", "MS")), 4),
    F_value = round(col_or_na(c("F value", "F.value", "F")), 3),
    Pr_F = round(col_or_na(c("Pr(>F)", "Pr..F.", "P value", "P.value")), 4),
    Sig = sig_stars(col_or_na(c("Pr(>F)", "Pr..F.", "P value", "P.value"))),
    stringsAsFactors = FALSE
  )
}

compute_gen_means <- function(dat, direction = "h") {
  result <- do.call(rbind, lapply(levels(dat$GEN), function(g) {
    y <- dat$Y[dat$GEN == g]
    m <- mean(y, na.rm = TRUE)
    s <- stats::sd(y, na.rm = TRUE)
    data.frame(
      GEN = g,
      Genotype = g,
      N = sum(!is.na(y)),
      Mean = round(m, 4),
      SD = round(s, 4),
      CV_pct = if (is.finite(m) && abs(m) > 0) round(100 * s / abs(m), 2) else NA_real_,
      stringsAsFactors = FALSE
    )
  }))
  result$Rank_Mean <- met_rank(result$Mean, direction)
  result[order(result$Rank_Mean), , drop = FALSE]
}

compute_individual_anovas <- function(dat, alpha = 0.05) {
  envs <- levels(dat$ENV)
  lapply(setNames(envs, envs), function(env) {
    sub <- dat[dat$ENV == env, , drop = FALSE]
    sub$GEN <- droplevels(sub$GEN)
    sub$REP <- droplevels(sub$REP)
    tryCatch({
      n_rep <- nlevels(sub$REP)
      mod <- if (n_rep > 1) stats::lm(Y ~ GEN + REP, data = sub) else stats::lm(Y ~ GEN, data = sub)
      out <- format_anova_table(stats::anova(mod))
      error_ms <- out$MS[out$Source == "Residuals"]
      grand_mean <- mean(sub$Y, na.rm = TRUE)
      cv_pct <- if (length(error_ms) == 1 && !is.na(error_ms) && abs(grand_mean) > 0) {
        round(100 * sqrt(error_ms) / abs(grand_mean), 2)
      } else {
        NA_real_
      }
      attr(out, "cv_pct") <- cv_pct
      attr(out, "grand_mean") <- round(grand_mean, 4)
      out
    }, error = function(e) {
      data.frame(Source = "Error", df = NA, Den_df = NA, SS = NA, MS = NA,
                 F_value = NA, Pr_F = NA, Sig = conditionMessage(e),
                 stringsAsFactors = FALSE)
    })
  })
}

compute_combined_anova <- function(dat, alpha = 0.05) {
  tryCatch({
    mod <- lmerTest::lmer(
      Y ~ GEN + ENV + GEN:ENV + (1 | ENV:REP),
      data = dat,
      control = lme4::lmerControl(optimizer = "bobyqa")
    )
    out <- format_anova_table(stats::anova(mod))
    vc <- as.data.frame(lme4::VarCorr(mod))
    error_var <- vc$vcov[vc$grp == "Residual"]
    grand_mean <- mean(dat$Y, na.rm = TRUE)
    cv_pct <- if (length(error_var) == 1 && !is.na(error_var) && abs(grand_mean) > 0) {
      round(100 * sqrt(error_var) / abs(grand_mean), 2)
    } else {
      NA_real_
    }
    out <- rbind(out, data.frame(
      Source = "Residual (Error)", df = NA, Den_df = NA, SS = NA,
      MS = round(if (length(error_var) == 1) error_var else NA_real_, 4),
      F_value = NA, Pr_F = NA, Sig = "", stringsAsFactors = FALSE
    ))
    attr(out, "cv_pct") <- cv_pct
    attr(out, "grand_mean") <- round(grand_mean, 4)
    out
  }, error = function(e) {
    data.frame(Source = "Error", df = NA, Den_df = NA, SS = NA, MS = NA,
               F_value = NA, Pr_F = NA, Sig = conditionMessage(e),
               stringsAsFactors = FALSE)
  })
}

compute_year_anova <- function(dat, alpha = 0.05) {
  if (!all(c("SEASON", "LOC") %in% names(dat))) return(NULL)
  tryCatch({
    dat$SEASON <- as.factor(dat$SEASON)
    dat$LOC <- as.factor(dat$LOC)
    mod <- lmerTest::lmer(
      Y ~ GEN * SEASON * LOC + (1 | SEASON:LOC:REP),
      data = dat,
      control = lme4::lmerControl(optimizer = "bobyqa")
    )
    format_anova_table(stats::anova(mod))
  }, error = function(e) {
    data.frame(Source = "Error", df = NA, Den_df = NA, SS = NA, MS = NA,
               F_value = NA, Pr_F = NA, Sig = conditionMessage(e),
               stringsAsFactors = FALSE)
  })
}

fallback_ammi_stability <- function(ammi_pc_scores, ammi_ipca_summary) {
  if (is.null(ammi_pc_scores) || is.null(ammi_ipca_summary)) {
    return(NULL)
  }
  pc_cols <- grep("^PC[0-9]+$", names(ammi_pc_scores), value = TRUE)
  if (length(pc_cols) == 0) {
    return(NULL)
  }

  scores <- as.matrix(ammi_pc_scores[pc_cols])
  explained <- ammi_ipca_summary$Explained_percent[seq_along(pc_cols)]
  explained <- ifelse(is.na(explained), 0, explained)
  weights <- explained / sum(explained)
  if (any(!is.finite(weights))) {
    weights <- rep(1 / length(pc_cols), length(pc_cols))
  }

  pc1 <- scores[, 1]
  pc2 <- if (ncol(scores) >= 2) scores[, 2] else rep(0, length(pc1))
  ss1 <- ammi_ipca_summary$SS[1]
  ss2 <- if (nrow(ammi_ipca_summary) >= 2) ammi_ipca_summary$SS[2] else NA_real_
  asv_weight <- if (is.finite(ss1) && is.finite(ss2) && ss2 != 0) ss1 / ss2 else 1
  za_total <- sum(abs(scores), na.rm = TRUE)

  data.frame(
    GEN = ammi_pc_scores$GEN,
    ASV = sqrt((asv_weight * pc1)^2 + pc2^2),
    EV = rowMeans(scores^2, na.rm = TRUE),
    SIPC = rowSums(abs(scores), na.rm = TRUE),
    WAAS = as.numeric(abs(scores) %*% weights),
    ZA = if (za_total > 0) 100 * rowSums(abs(scores), na.rm = TRUE) / za_total else NA_real_,
    stringsAsFactors = FALSE
  )
}

compute_ammi <- function(dat) {
  warnings <- character(0)
  add_warning <- function(msg) warnings <<- c(warnings, msg)

  tryCatch({
    ammi_mod <- metan::performs_ammi(
      .data = dat, env = ENV, gen = GEN, rep = REP, resp = Y,
      verbose = FALSE
    )

    ammi_anova <- tryCatch(met_model_data(ammi_mod, "anova"), error = function(e) {
      add_warning(paste("AMMI ANOVA extraction failed:", conditionMessage(e)))
      NULL
    })

    ipca_summary <- tryCatch({
      ipca_ss <- met_model_data(ammi_mod, "ipca_ss")
      data.frame(
        IPCA = ipca_ss$PC,
        DF = ipca_ss$DF,
        SS = ipca_ss$Y,
        MS = met_metric_vector(ammi_mod, "ipca_ms"),
        F_value = met_metric_vector(ammi_mod, "ipca_fval"),
        P_value = met_metric_vector(ammi_mod, "ipca_pval"),
        Explained_percent = met_metric_vector(ammi_mod, "ipca_expl"),
        Accumulated_percent = met_metric_vector(ammi_mod, "ipca_accum"),
        stringsAsFactors = FALSE
      )
    }, error = function(e) {
      add_warning(paste("AMMI IPCA extraction failed:", conditionMessage(e)))
      NULL
    })

    pc_scores <- NULL
    if (!is.null(ipca_summary) && nrow(ipca_summary) > 0) {
      pc_scores <- met_merge_by_gen(lapply(seq_len(nrow(ipca_summary)), function(i) {
        met_safe_metric_by_gen(ammi_mod, paste0("PC", i), paste0("PC", i))
      }))
    }

    stability <- tryCatch({
      ammi_ind_mod <- metan::ammi_indexes(ammi_mod)
      met_merge_by_gen(list(
        met_safe_metric_by_gen(ammi_ind_mod, "ASV", "ASV"),
        met_safe_metric_by_gen(ammi_ind_mod, "EV", "EV"),
        met_safe_metric_by_gen(ammi_ind_mod, "SIPC", "SIPC"),
        met_safe_metric_by_gen(ammi_ind_mod, "WAAS", "WAAS"),
        met_safe_metric_by_gen(ammi_ind_mod, "ZA", "ZA")
      ))
    }, error = function(e) {
      add_warning(paste("metan::ammi_indexes() failed; fallback stability was used:", conditionMessage(e)))
      fallback_ammi_stability(pc_scores, ipca_summary)
    })

    if (is.null(stability)) {
      stability <- fallback_ammi_stability(pc_scores, ipca_summary)
    }

    list(
      mod = ammi_mod,
      anova = ammi_anova,
      ipca_summary = ipca_summary,
      scores = pc_scores,
      pc_scores = pc_scores,
      stability = stability,
      warnings = warnings
    )
  }, error = function(e) {
    list(
      mod = NULL, anova = NULL, ipca_summary = NULL, scores = NULL,
      pc_scores = NULL, stability = NULL,
      warnings = c(warnings, paste("AMMI model failed:", conditionMessage(e))),
      error = conditionMessage(e)
    )
  })
}

compute_gge <- function(dat) {
  tryCatch({
    list(mod = metan::gge(.data = dat, env = ENV, gen = GEN, resp = Y, verbose = FALSE))
  }, error = function(e) {
    list(mod = NULL, error = conditionMessage(e), warnings = paste("GGE model failed:", conditionMessage(e)))
  })
}

compute_waasb <- function(dat, direction = "h") {
  warnings <- character(0)
  add_warning <- function(msg) warnings <<- c(warnings, msg)

  tryCatch({
    waasb_mod <- metan::waasb(
      .data = dat, env = ENV, gen = GEN, rep = REP, resp = Y,
      mresp = direction, wresp = 70, random = "gen", verbose = FALSE
    )

    blup_ind_mod <- tryCatch(metan::blup_indexes(waasb_mod), error = function(e) {
      add_warning(paste("metan::blup_indexes() failed:", conditionMessage(e)))
      NULL
    })

    scores <- met_merge_by_gen(c(
      if (!is.null(blup_ind_mod)) list(
        met_safe_metric_by_gen(blup_ind_mod, "HMGV", "HMGV"),
        met_safe_metric_by_gen(blup_ind_mod, "HMGV_R", "HMGV_R"),
        met_safe_metric_by_gen(blup_ind_mod, "RPGV", "RPGV"),
        met_safe_metric_by_gen(blup_ind_mod, "RPGV_Y", "RPGV_Y"),
        met_safe_metric_by_gen(blup_ind_mod, "HMRPGV", "HMRPGV"),
        met_safe_metric_by_gen(blup_ind_mod, "HMRPGV_R", "HMRPGV_R"),
        met_safe_metric_by_gen(blup_ind_mod, "WAASB", "WAASB"),
        met_safe_metric_by_gen(blup_ind_mod, "WAASB_R", "WAASB_R")
      ) else list(),
      list(
        met_safe_metric_by_gen(waasb_mod, "PctResp", "PctResp"),
        met_safe_metric_by_gen(waasb_mod, "PctWAASB", "PctWAASB"),
        met_safe_metric_by_gen(waasb_mod, "WAASBY", "WAASBY"),
        met_safe_metric_by_gen(waasb_mod, "OrWAASBY", "Rank_WAASBY")
      )
    ))

    list(mod = waasb_mod, blup_indexes_model = blup_ind_mod, scores = scores, warnings = warnings)
  }, error = function(e) {
    list(
      mod = NULL, blup_indexes_model = NULL, scores = NULL,
      warnings = c(warnings, paste("WAASB model failed:", conditionMessage(e))),
      error = conditionMessage(e)
    )
  })
}

safe_harmonic <- function(x) {
  x <- x[is.finite(x) & x > 0]
  if (length(x) == 0) return(NA_real_)
  length(x) / sum(1 / x)
}

compute_blup_indices <- function(dat, gen_means, direction = "h") {
  tryCatch({
    blup_mod <- lme4::lmer(
      Y ~ ENV + (1 | GEN) + (1 | GEN:ENV) + (1 | ENV:REP),
      data = dat,
      control = lme4::lmerControl(optimizer = "bobyqa")
    )
    pred_grid <- expand.grid(GEN = levels(dat$GEN), ENV = levels(dat$ENV), stringsAsFactors = FALSE)
    pred_grid$GEN <- factor(pred_grid$GEN, levels = levels(dat$GEN))
    pred_grid$ENV <- factor(pred_grid$ENV, levels = levels(dat$ENV))
    pred_grid$GV <- stats::predict(
      blup_mod, newdata = pred_grid,
      re.form = ~(1 | GEN) + (1 | GEN:ENV),
      allow.new.levels = TRUE
    )

    env_means <- stats::aggregate(Y ~ ENV, data = dat, FUN = mean, na.rm = TRUE)
    names(env_means)[2] <- "ENV_MEAN"
    pred_grid <- merge(pred_grid, env_means, by = "ENV", all.x = TRUE)
    pred_grid$RPGVij <- pred_grid$GV / pred_grid$ENV_MEAN

    indices <- do.call(rbind, lapply(levels(dat$GEN), function(g) {
      sub <- pred_grid[pred_grid$GEN == g, , drop = FALSE]
      data.frame(
        GEN = g,
        HMGV = safe_harmonic(sub$GV),
        RPGV = mean(sub$RPGVij, na.rm = TRUE),
        HMRPGV = safe_harmonic(sub$RPGVij),
        stringsAsFactors = FALSE
      )
    }))

    means <- gen_means[, intersect(c("GEN", "Genotype", "Mean", "Rank_Mean"), names(gen_means)), drop = FALSE]
    indices <- merge(indices, means, by = "GEN", all.x = TRUE)
    indices$Rank_HMGV <- met_rank(indices$HMGV, direction)
    indices$Rank_RPGV <- met_rank(indices$RPGV, direction)
    indices$Rank_HMRPGV <- met_rank(indices$HMRPGV, direction)
    indices <- indices[order(indices$Rank_HMRPGV), , drop = FALSE]
    rownames(indices) <- NULL
    indices
  }, error = function(e) {
    data.frame(Error = conditionMessage(e), stringsAsFactors = FALSE)
  })
}

compute_ssi <- function(waasb_scores, gen_means, direction = "h") {
  tryCatch({
    if (is.null(waasb_scores) || !"GEN" %in% names(waasb_scores)) {
      return(list(full = NULL, culled = NULL))
    }

    means <- gen_means[, intersect(c("GEN", "Genotype", "Mean", "Rank_Mean"), names(gen_means)), drop = FALSE]
    ssi <- merge(waasb_scores, means, by = "GEN", all.x = TRUE)

    if (!"WAASB" %in% names(ssi)) ssi$WAASB <- NA_real_
    if (!"WAASBY" %in% names(ssi)) ssi$WAASBY <- NA_real_
    ssi$Rank_Yield <- ssi$Rank_Mean
    ssi$Rank_Stability <- rank(ssi$WAASB, ties.method = "first", na.last = "keep")
    ssi$NP_SSI <- ssi$Rank_Yield + ssi$Rank_Stability
    ssi$Rank_NP_SSI <- rank(ssi$NP_SSI, ties.method = "first", na.last = "keep")

    if (!"Rank_WAASBY" %in% names(ssi) || all(is.na(ssi$Rank_WAASBY))) {
      ssi$Rank_WAASBY <- rank(-ssi$WAASBY, ties.method = "first", na.last = "keep")
    }
    ssi$P_SSI <- ssi$WAASBY
    ssi$Rank_P_SSI <- ssi$Rank_WAASBY
    ssi$Stable_by_culling <- ssi$WAASB < mean(ssi$WAASB, na.rm = TRUE)
    ssi <- ssi[order(ssi$Rank_P_SSI), , drop = FALSE]

    cssi <- ssi[isTRUE(ssi$Stable_by_culling) | (!is.na(ssi$Stable_by_culling) & ssi$Stable_by_culling), , drop = FALSE]
    cssi <- cssi[order(cssi$Rank_Yield), , drop = FALSE]
    cssi$Rank_C_SSI <- seq_len(nrow(cssi))

    list(full = ssi, culled = cssi)
  }, error = function(e) {
    list(full = NULL, culled = NULL, error = conditionMessage(e))
  })
}

prepare_met_data <- function(data, gen_col, env_col, rep_col, trait_col,
                             season_col = NULL, loc_col = NULL) {
  dat <- as.data.frame(data, stringsAsFactors = FALSE)
  required_cols <- c(gen_col, env_col, rep_col, trait_col)
  missing_cols <- setdiff(required_cols, names(dat))
  if (length(missing_cols) > 0) {
    stop("Missing columns: ", paste(missing_cols, collapse = ", "))
  }

  names(dat)[names(dat) == gen_col] <- "GEN"
  names(dat)[names(dat) == env_col] <- "ENV"
  names(dat)[names(dat) == rep_col] <- "REP"
  names(dat)[names(dat) == trait_col] <- "Y"

  if (!is.null(season_col) && season_col %in% names(dat)) {
    names(dat)[names(dat) == season_col] <- "SEASON"
  }
  if (!is.null(loc_col) && loc_col %in% names(dat)) {
    names(dat)[names(dat) == loc_col] <- "LOC"
  }

  dat$GEN <- as.factor(trimws(as.character(dat$GEN)))
  dat$ENV <- as.factor(trimws(as.character(dat$ENV)))
  dat$REP <- as.factor(trimws(as.character(dat$REP)))
  if ("SEASON" %in% names(dat)) dat$SEASON <- as.factor(trimws(as.character(dat$SEASON)))
  if ("LOC" %in% names(dat)) dat$LOC <- as.factor(trimws(as.character(dat$LOC)))
  dat$Y <- met_clean_numeric(dat$Y)
  dat <- dat[!is.na(dat$Y), , drop = FALSE]
  validate_met_data(dat)
  dat
}

run_met_analysis <- function(data, gen_col, env_col, rep_col, trait_col,
                             season_col = NULL, loc_col = NULL, alpha = 0.05,
                             direction = "h") {
  met_required_packages()
  direction <- if (identical(direction, "l")) "l" else "h"
  dat <- prepare_met_data(data, gen_col, env_col, rep_col, trait_col, season_col, loc_col)

  gen_means <- compute_gen_means(dat, direction)
  ammi <- compute_ammi(dat)
  gge <- compute_gge(dat)
  waasb <- compute_waasb(dat, direction)
  ssi <- compute_ssi(waasb$scores, gen_means, direction)

  res <- list(
    dataset = dat,
    gen_means = gen_means,
    ind_anova = compute_individual_anovas(dat, alpha),
    comb_anova = compute_combined_anova(dat, alpha),
    year_anova = if (all(c("SEASON", "LOC") %in% names(dat))) compute_year_anova(dat, alpha) else NULL,
    ammi = ammi,
    gge = gge,
    waasb = waasb,
    blup = compute_blup_indices(dat, gen_means, direction),
    ssi = ssi,
    trait = trait_col,
    direction = direction,
    direction_label = met_direction_label(direction),
    n_gen = nlevels(dat$GEN),
    n_env = nlevels(dat$ENV),
    warnings = unique(c(ammi$warnings, gge$warnings, waasb$warnings))
  )
  res$report_note <- sprintf(
    "Trait: %s | Direction: %s | Genotypes: %d | Environments: %d | Observations: %d",
    trait_col, res$direction_label, res$n_gen, res$n_env, nrow(dat)
  )
  res
}

run_met_batch_analysis <- function(data, gen_col, env_col, rep_col, trait_cols,
                                   direction_map, season_col = NULL, loc_col = NULL,
                                   alpha = 0.05) {
  trait_cols <- unique(trait_cols[nzchar(trait_cols)])
  if (length(trait_cols) == 0) {
    stop("Select at least one numeric trait for batch MET analysis.")
  }

  results <- list()
  errors <- data.frame(Trait = character(0), Error = character(0), stringsAsFactors = FALSE)

  for (trait in trait_cols) {
    direction <- direction_map[[trait]]
    if (is.null(direction) || !direction %in% c("h", "l")) direction <- "h"
    result <- tryCatch(
      run_met_analysis(data, gen_col, env_col, rep_col, trait, season_col, loc_col, alpha, direction),
      error = function(e) e
    )
    if (inherits(result, "error")) {
      errors <- rbind(errors, data.frame(Trait = trait, Error = conditionMessage(result), stringsAsFactors = FALSE))
    } else {
      results[[trait]] <- result
    }
  }

  top_summary <- do.call(rbind, lapply(results, function(res) {
    ssi <- res$ssi$full
    if (is.null(ssi) || nrow(ssi) == 0) return(NULL)
    ssi <- ssi[order(ssi$Rank_P_SSI), , drop = FALSE]
    ssi <- utils::head(ssi, 10)
    keep <- intersect(c("GEN", "Mean", "WAASB", "WAASBY", "Rank_P_SSI", "Rank_NP_SSI"), names(ssi))
    out <- ssi[, keep, drop = FALSE]
    out$Trait <- res$trait
    out$Direction <- res$direction_label
    out[, c("Trait", "Direction", keep), drop = FALSE]
  }))
  if (is.null(top_summary)) {
    top_summary <- data.frame(Trait = character(0), Direction = character(0), GEN = character(0), stringsAsFactors = FALSE)
  }
  rownames(top_summary) <- NULL

  multi_trait_index <- if (nrow(top_summary) > 0) {
    split_top <- split(top_summary, top_summary$GEN)
    out <- do.call(rbind, lapply(names(split_top), function(gen) {
      sub <- split_top[[gen]]
      data.frame(
        GEN = gen,
        Traits_in_top10 = length(unique(sub$Trait)),
        Mean_rank = mean(sub$Rank_P_SSI, na.rm = TRUE),
        Traits = paste(sort(unique(sub$Trait)), collapse = ", "),
        stringsAsFactors = FALSE
      )
    }))
    out[order(-out$Traits_in_top10, out$Mean_rank), , drop = FALSE]
  } else {
    data.frame(GEN = character(0), Traits_in_top10 = integer(0), Mean_rank = numeric(0), Traits = character(0), stringsAsFactors = FALSE)
  }
  rownames(multi_trait_index) <- NULL

  list(results = results, errors = errors, top_summary = top_summary, multi_trait_index = multi_trait_index)
}

met_result_tables <- function(res) {
  tables <- list(
    Dataset = res$dataset,
    Genotype_Means = res$gen_means,
    Combined_ANOVA = res$comb_anova,
    Over_Year_ANOVA = res$year_anova,
    AMMI_ANOVA = res$ammi$anova,
    AMMI_IPCA = res$ammi$ipca_summary,
    AMMI_PC_Scores = res$ammi$pc_scores,
    AMMI_Stability = res$ammi$stability,
    WAASB_WAASBY = res$waasb$scores,
    BLUP_HMGV_RPGV_HMRPGV = res$blup,
    SSI = res$ssi$full,
    C_SSI = res$ssi$culled
  )
  Filter(function(x) is.data.frame(x) && nrow(x) >= 0, tables)
}

met_batch_result_tables <- function(batch, current_result = NULL) {
  tables <- list(
    Top_10_All_Traits = batch$top_summary,
    Multi_Trait_Index = batch$multi_trait_index,
    Batch_Errors = batch$errors
  )
  if (!is.null(current_result)) {
    current <- met_result_tables(current_result)
    names(current) <- paste0(substr(current_result$trait, 1, 10), "_", names(current))
    tables <- c(tables, current)
  }
  Filter(function(x) is.data.frame(x) && nrow(x) >= 0, tables)
}

met_run_signature <- function(mode, data_source, gen_col, env_col, rep_col,
                              trait_col = NULL, trait_cols = NULL,
                              lower_traits = NULL, alpha = 0.05,
                              use_sep_env = FALSE, season_col = NULL,
                              loc_col = NULL) {
  list(
    mode = mode,
    data_source = data_source,
    gen_col = gen_col,
    env_col = env_col,
    rep_col = rep_col,
    trait_col = trait_col,
    trait_cols = sort(unique(as.character(trait_cols))),
    lower_traits = sort(unique(as.character(lower_traits))),
    alpha = alpha,
    use_sep_env = isTRUE(use_sep_env),
    season_col = season_col,
    loc_col = loc_col
  )
}

met_signature_changed <- function(previous, current) {
  if (is.null(previous) || is.null(current)) return(FALSE)
  !identical(previous, current)
}

met_payload_traits <- function(payload) {
  if (is.null(payload)) return(character(0))
  if (identical(payload$mode, "batch")) return(names(payload$batch$results))
  payload$result$trait
}

met_select_cached_result <- function(payload, selected_trait = NULL) {
  if (is.null(payload)) return(NULL)
  if (!identical(payload$mode, "batch")) return(payload$result)

  traits <- names(payload$batch$results)
  if (length(traits) == 0) return(NULL)
  if (is.null(selected_trait) || !selected_trait %in% traits) {
    selected_trait <- traits[1]
  }
  payload$batch$results[[selected_trait]]
}

met_payload_status_text <- function(payload, selected_trait = NULL) {
  if (is.null(payload)) return(NULL)
  run_time <- payload$run_time
  if (is.null(run_time)) run_time <- ""
  if (identical(payload$mode, "batch")) {
    traits <- met_payload_traits(payload)
    selected <- selected_trait
    if (is.null(selected)) selected <- traits[1]
    sprintf(
      "Batch run completed for %d traits at %s. Viewing %s from cached results; switching traits does not rerun analysis.",
      length(traits), run_time, selected
    )
  } else {
    sprintf("Single-trait run completed for %s at %s.", payload$result$trait, run_time)
  }
}

met_all_batch_result_tables <- function(batch, current_result = NULL, include_all_traits = TRUE) {
  tables <- met_batch_result_tables(batch, current_result)
  if (isTRUE(include_all_traits) && length(batch$results) > 0) {
    for (trait in names(batch$results)) {
      trait_tables <- met_result_tables(batch$results[[trait]])
      names(trait_tables) <- paste0(substr(trait, 1, 12), "_", names(trait_tables))
      tables <- c(tables, trait_tables)
    }
  }
  Filter(function(x) is.data.frame(x) && nrow(x) >= 0, tables)
}

met_safe_sheet_names <- function(names_in) {
  cleaned <- gsub("[^A-Za-z0-9_]", "_", names_in)
  cleaned[!nzchar(cleaned)] <- "Sheet"
  counts <- list()

  vapply(cleaned, function(name) {
    base <- substr(name, 1, 25)
    count <- counts[[base]]
    if (is.null(count)) count <- 0
    count <- count + 1
    counts[[base]] <<- count

    suffix <- if (count == 1) "" else paste0("_", count)
    substr(paste0(substr(base, 1, 31 - nchar(suffix)), suffix), 1, 31)
  }, character(1), USE.NAMES = FALSE)
}
