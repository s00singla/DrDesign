############################################################
# MET Stability Analysis — backend functions
# Packages: metan, lme4, lmerTest
############################################################

met_required_packages <- function() {
  pkgs <- c("metan", "lme4", "lmerTest")
  missing_pkgs <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_pkgs) > 0) {
    stop(paste0(
      "Missing packages required for MET analysis: ",
      paste(missing_pkgs, collapse = ", "),
      ".\nInstall with: install.packages(c(",
      paste(sprintf('"%s"', missing_pkgs), collapse = ", "),
      "))"
    ))
  }
  invisible(TRUE)
}

validate_met_data <- function(dat) {
  if (nrow(dat) == 0)
    stop("No observations remain after removing missing values.")
  if (nlevels(dat$GEN) < 2)
    stop("At least 2 genotypes are required for MET analysis.")
  if (nlevels(dat$ENV) < 2)
    stop("At least 2 environments are required for MET analysis.")
}

# ---- significance stars ----------------------------------------
sig_stars <- function(p) {
  ifelse(is.na(p), "",
    ifelse(p < 0.001, "***",
      ifelse(p < 0.01, "**",
        ifelse(p < 0.05, "*",
          ifelse(p < 0.1, ".", "ns")))))
}

# ---- 1. Genotype means ----------------------------------------
compute_gen_means <- function(dat) {
  result <- do.call(rbind, lapply(levels(dat$GEN), function(g) {
    y <- dat$Y[dat$GEN == g]
    m <- mean(y, na.rm = TRUE)
    s <- sd(y, na.rm = TRUE)
    data.frame(
      Genotype = g,
      N        = sum(!is.na(y)),
      Mean     = round(m, 4),
      SD       = round(s, 4),
      CV_pct   = round(100 * s / abs(m), 2),
      stringsAsFactors = FALSE
    )
  }))
  result <- result[order(-result$Mean), ]
  result$Rank <- seq_len(nrow(result))
  result
}

# ---- 2. Individual ANOVA per environment ---------------------
compute_individual_anovas <- function(dat, alpha = 0.05) {
  envs <- levels(dat$ENV)
  lapply(setNames(envs, envs), function(env) {
    sub      <- dat[dat$ENV == env, ]
    sub$GEN  <- droplevels(sub$GEN)
    sub$REP  <- droplevels(sub$REP)
    tryCatch({
      n_rep <- nlevels(sub$REP)
      mod   <- if (n_rep > 1) lm(Y ~ GEN + REP, data = sub) else lm(Y ~ GEN, data = sub)
      av    <- as.data.frame(anova(mod))
      av$Source <- rownames(av)
      rownames(av) <- NULL
      out <- data.frame(
        Source  = av$Source,
        df      = av$Df,
        SS      = round(av$`Sum Sq`, 4),
        MS      = round(av$`Mean Sq`, 4),
        F_value = round(av$`F value`, 3),
        Pr_F    = round(av$`Pr(>F)`, 4),
        Sig     = sig_stars(av$`Pr(>F)`),
        stringsAsFactors = FALSE
      )
      error_ms   <- out$MS[out$Source == "Residuals"]
      grand_mean <- mean(sub$Y, na.rm = TRUE)
      cv_pct     <- if (length(error_ms) == 1 && !is.na(error_ms) && abs(grand_mean) > 0)
                      round(100 * sqrt(error_ms) / abs(grand_mean), 2) else NA
      attr(out, "cv_pct")     <- cv_pct
      attr(out, "grand_mean") <- round(grand_mean, 4)
      out
    }, error = function(e) {
      data.frame(Source = "Error", df = NA, SS = NA, MS = NA,
                 F_value = NA, Pr_F = NA, Sig = conditionMessage(e),
                 stringsAsFactors = FALSE)
    })
  })
}

# ---- 3. Combined ANOVA over environments ---------------------
compute_combined_anova <- function(dat, alpha = 0.05) {
  tryCatch({
    # Fit combined model: GEN + ENV + GEN:ENV with REP nested in ENV as random
    mod <- lmerTest::lmer(Y ~ GEN + ENV + GEN:ENV + (1 | ENV:REP), data = dat,
                          control = lme4::lmerControl(optimizer = "bobyqa"))
    av  <- as.data.frame(anova(mod))
    av$Source <- rownames(av)
    rownames(av) <- NULL
    out <- data.frame(
      Source  = av$Source,
      df      = av$Df,
      SS      = round(av$`Sum Sq`, 4),
      MS      = round(av$`Mean Sq`, 4),
      F_value = round(av$`F value`, 3),
      Pr_F    = round(av$`Pr(>F)`, 4),
      Sig     = sig_stars(av$`Pr(>F)`),
      stringsAsFactors = FALSE
    )
    vc         <- as.data.frame(lme4::VarCorr(mod))
    error_var  <- vc$vcov[vc$grp == "Residual"]
    grand_mean <- mean(dat$Y, na.rm = TRUE)
    cv_pct     <- if (length(error_var) == 1 && !is.na(error_var) && abs(grand_mean) > 0)
                    round(100 * sqrt(error_var) / abs(grand_mean), 2) else NA
    # append residual row
    out <- rbind(out, data.frame(
      Source = "Residual (Error)", df = NA, SS = NA,
      MS = round(if (length(error_var) == 1) error_var else NA_real_, 4),
      F_value = NA, Pr_F = NA, Sig = "", stringsAsFactors = FALSE
    ))
    attr(out, "cv_pct")     <- cv_pct
    attr(out, "grand_mean") <- round(grand_mean, 4)
    out
  }, error = function(e) {
    data.frame(Source = "Error", df = NA, SS = NA, MS = NA,
               F_value = NA, Pr_F = NA, Sig = conditionMessage(e),
               stringsAsFactors = FALSE)
  })
}

# ---- 4. Over-Year ANOVA (Season × Location) ------------------
compute_year_anova <- function(dat, alpha = 0.05) {
  if (!all(c("SEASON", "LOC") %in% names(dat))) return(NULL)
  tryCatch({
    dat$SEASON <- as.factor(dat$SEASON)
    dat$LOC    <- as.factor(dat$LOC)
    mod <- lmerTest::lmer(
      Y ~ GEN * SEASON * LOC + (1 | SEASON:LOC:REP), data = dat,
      control = lme4::lmerControl(optimizer = "bobyqa")
    )
    av  <- as.data.frame(anova(mod))
    av$Source <- rownames(av)
    rownames(av) <- NULL
    data.frame(
      Source  = av$Source,
      df      = av$Df,
      SS      = round(av$`Sum Sq`, 4),
      MS      = round(av$`Mean Sq`, 4),
      F_value = round(av$`F value`, 3),
      Pr_F    = round(av$`Pr(>F)`, 4),
      Sig     = sig_stars(av$`Pr(>F)`),
      stringsAsFactors = FALSE
    )
  }, error = function(e) {
    data.frame(Source = "Error", df = NA, SS = NA, MS = NA,
               F_value = NA, Pr_F = NA, Sig = conditionMessage(e),
               stringsAsFactors = FALSE)
  })
}

# ---- 5. AMMI analysis ----------------------------------------
compute_ammi <- function(dat) {
  tryCatch({
    ammi_mod <- metan::performs_ammi(
      .data = dat, env = ENV, gen = GEN, rep = REP, resp = Y,
      verbose = FALSE
    )
    ammi_anova <- tryCatch({
      av <- as.data.frame(metan::get_model_data(ammi_mod, "anova"))
      av$Source <- rownames(av); rownames(av) <- NULL; av
    }, error = function(e) NULL)

    ammi_scores <- tryCatch(
      as.data.frame(metan::get_model_data(ammi_mod, "scores")),
      error = function(e) NULL
    )
    ammi_stab <- tryCatch({
      s <- metan::ammi_indexes(ammi_mod)
      # metan returns a named list; grab the first (only) trait element
      if (is.list(s) && !is.data.frame(s)) as.data.frame(s[[1]]) else as.data.frame(s)
    }, error = function(e) NULL)

    list(mod = ammi_mod, anova = ammi_anova, scores = ammi_scores, stability = ammi_stab)
  }, error = function(e) {
    list(mod = NULL, anova = NULL, scores = NULL, stability = NULL, error = conditionMessage(e))
  })
}

# ---- 6. GGE analysis -----------------------------------------
compute_gge <- function(dat) {
  tryCatch({
    gge_mod <- metan::gge(
      .data = dat, env = ENV, gen = GEN, resp = Y,
      verbose = FALSE
    )
    list(mod = gge_mod)
  }, error = function(e) {
    list(mod = NULL, error = conditionMessage(e))
  })
}

# ---- 7. WAASB / WAASBY --------------------------------------
compute_waasb <- function(dat) {
  tryCatch({
    waasb_mod <- metan::waasb(
      .data = dat, env = ENV, gen = GEN, rep = REP, resp = Y,
      random = "gen", verbose = FALSE
    )
    scores <- tryCatch({
      sc <- metan::get_model_data(waasb_mod, "WAASB")
      if (is.list(sc) && !is.data.frame(sc)) as.data.frame(sc[[1]]) else as.data.frame(sc)
    }, error = function(e) NULL)

    blups <- tryCatch({
      b <- metan::get_model_data(waasb_mod, "blupg")
      if (is.list(b) && !is.data.frame(b)) as.data.frame(b[[1]]) else as.data.frame(b)
    }, error = function(e) NULL)

    list(mod = waasb_mod, scores = scores, blups = blups)
  }, error = function(e) {
    list(mod = NULL, scores = NULL, blups = NULL, error = conditionMessage(e))
  })
}

# ---- 8. BLUP-based stability indices -------------------------
compute_blup_indices <- function(dat, gen_means) {
  tryCatch({
    blup_mod <- lme4::lmer(
      Y ~ ENV + (1 | GEN) + (1 | GEN:ENV) + (1 | ENV:REP), data = dat,
      control = lme4::lmerControl(optimizer = "bobyqa")
    )
    pred_grid     <- expand.grid(GEN = levels(dat$GEN), ENV = levels(dat$ENV),
                                  stringsAsFactors = FALSE)
    pred_grid$GEN <- factor(pred_grid$GEN, levels = levels(dat$GEN))
    pred_grid$ENV <- factor(pred_grid$ENV, levels = levels(dat$ENV))
    pred_grid$GV  <- predict(blup_mod, newdata = pred_grid,
                              re.form = ~(1 | GEN) + (1 | GEN:ENV),
                              allow.new.levels = TRUE)

    env_means <- aggregate(Y ~ ENV, data = dat, FUN = mean, na.rm = TRUE)
    names(env_means)[2] <- "ENV_MEAN"
    pred_grid <- merge(pred_grid, env_means, by = "ENV", all.x = TRUE)
    pred_grid$RPGVij <- pred_grid$GV / pred_grid$ENV_MEAN

    indices <- do.call(rbind, lapply(levels(dat$GEN), function(g) {
      sub <- pred_grid[pred_grid$GEN == g & !is.na(pred_grid$GV) &
                         pred_grid$GV > 0 & pred_grid$RPGVij > 0, ]
      n   <- nrow(sub)
      if (n == 0) return(data.frame(GEN = g, HMGV = NA, RPGV = NA,
                                     HMRPGV = NA, stringsAsFactors = FALSE))
      data.frame(
        GEN    = g,
        HMGV   = round(n / sum(1 / sub$GV,     na.rm = TRUE), 4),
        RPGV   = round(mean(sub$RPGVij,          na.rm = TRUE), 4),
        HMRPGV = round(n / sum(1 / sub$RPGVij,  na.rm = TRUE), 4),
        stringsAsFactors = FALSE
      )
    }))

    indices <- merge(indices, gen_means[, c("Genotype", "Mean")],
                     by.x = "GEN", by.y = "Genotype", all.x = TRUE)
    indices$Rank_Mean   <- rank(-indices$Mean,   ties.method = "first")
    indices$Rank_HMGV   <- rank(-indices$HMGV,   ties.method = "first")
    indices$Rank_RPGV   <- rank(-indices$RPGV,   ties.method = "first")
    indices$Rank_HMRPGV <- rank(-indices$HMRPGV, ties.method = "first")
    indices[order(indices$Rank_HMRPGV), ]
  }, error = function(e) {
    data.frame(Error = conditionMessage(e), stringsAsFactors = FALSE)
  })
}

# ---- 9. Simultaneous Selection Index (SSI) ------------------
compute_ssi <- function(waasb_scores, gen_means) {
  tryCatch({
    if (is.null(waasb_scores) ||
        !all(c("GEN", "WAASB", "WAASBY") %in% names(waasb_scores)))
      return(list(full = NULL, culled = NULL))

    ssi <- merge(
      waasb_scores[, c("GEN", "WAASB", "WAASBY")],
      gen_means[, c("Genotype", "Mean")],
      by.x = "GEN", by.y = "Genotype", all.x = TRUE
    )
    ssi$Rank_Yield     <- rank(-ssi$Mean,  ties.method = "first")
    ssi$Rank_Stability <- rank(ssi$WAASB,  ties.method = "first")
    ssi$NP_SSI         <- ssi$Rank_Yield + ssi$Rank_Stability
    ssi$Rank_NP_SSI    <- rank(ssi$NP_SSI, ties.method = "first")

    mean_waasb          <- mean(ssi$WAASB, na.rm = TRUE)
    ssi$Yield_score     <- ssi$Mean / mean(ssi$Mean, na.rm = TRUE)
    ssi$Stability_score <- (1 / ssi$WAASB) / mean(1 / ssi$WAASB, na.rm = TRUE)
    ssi$P_SSI           <- 0.70 * ssi$Yield_score + 0.30 * ssi$Stability_score
    ssi$Rank_P_SSI      <- rank(-ssi$P_SSI, ties.method = "first")
    ssi$Stable_by_culling <- ssi$WAASB < mean_waasb
    ssi <- ssi[order(ssi$Rank_P_SSI), ]

    cssi <- ssi[ssi$Stable_by_culling, ]
    cssi <- cssi[order(-cssi$Mean), ]
    cssi$Rank_C_SSI <- seq_len(nrow(cssi))

    list(full = ssi, culled = cssi)
  }, error = function(e) {
    list(full = NULL, culled = NULL, error = conditionMessage(e))
  })
}

# ============================================================
# MASTER FUNCTION
# ============================================================
run_met_analysis <- function(data, gen_col, env_col, rep_col, trait_col,
                              season_col = NULL, loc_col = NULL, alpha = 0.05) {
  met_required_packages()

  dat <- as.data.frame(data, stringsAsFactors = FALSE)

  # Validate required columns
  required_cols <- c(gen_col, env_col, rep_col, trait_col)
  missing_cols  <- setdiff(required_cols, names(dat))
  if (length(missing_cols) > 0)
    stop(paste("Missing columns:", paste(missing_cols, collapse = ", ")))

  # Rename to standard internal names
  names(dat)[names(dat) == gen_col]   <- "GEN"
  names(dat)[names(dat) == env_col]   <- "ENV"
  names(dat)[names(dat) == rep_col]   <- "REP"
  names(dat)[names(dat) == trait_col] <- "Y"

  if (!is.null(season_col) && season_col %in% names(dat))
    names(dat)[names(dat) == season_col] <- "SEASON"
  if (!is.null(loc_col) && loc_col %in% names(dat))
    names(dat)[names(dat) == loc_col] <- "LOC"

  dat$GEN <- as.factor(trimws(as.character(dat$GEN)))
  dat$ENV <- as.factor(trimws(as.character(dat$ENV)))
  dat$REP <- as.factor(trimws(as.character(dat$REP)))
  dat$Y   <- suppressWarnings(as.numeric(dat$Y))
  dat     <- dat[!is.na(dat$Y), ]

  validate_met_data(dat)

  res <- list()
  res$dataset    <- dat
  res$gen_means  <- compute_gen_means(dat)
  res$ind_anova  <- compute_individual_anovas(dat, alpha)
  res$comb_anova <- compute_combined_anova(dat, alpha)

  if (all(c("SEASON", "LOC") %in% names(dat)))
    res$year_anova <- compute_year_anova(dat, alpha)
  else
    res$year_anova <- NULL

  res$ammi  <- compute_ammi(dat)
  res$gge   <- compute_gge(dat)
  res$waasb <- compute_waasb(dat)
  res$blup  <- compute_blup_indices(dat, res$gen_means)
  res$ssi   <- compute_ssi(res$waasb$scores, res$gen_means)

  res$trait       <- trait_col
  res$n_gen       <- nlevels(dat$GEN)
  res$n_env       <- nlevels(dat$ENV)
  res$report_note <- sprintf(
    "Trait: %s | Genotypes: %d | Environments: %d | Observations: %d",
    trait_col, res$n_gen, res$n_env, nrow(dat)
  )
  res
}
