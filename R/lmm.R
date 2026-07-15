#' Fit a Linear Mixed Model for approximately normal wait-time outcomes
#'
#' @name lmm
NULL

#' Fit a Linear Mixed Model (LMM) for wait-time analysis
#'
#' Fits a multilevel linear mixed model (`lme4::lmer`) treating appointment
#' wait days as a continuous, approximately normal outcome. The physician
#' identifier is modelled as a random intercept. Fixed-effect coefficients are
#' returned directly in **days** (not as incidence rate ratios), making results
#' straightforward to explain to clinical audiences.
#'
#' **When to use LMM vs. Poisson/NB GLMM:**
#' Prefer LMM when the wait-day distribution is approximately symmetric with no
#' strong floor effect at zero (check with a Q-Q plot via
#' [plot.mysterycall_lmm()]). A Shapiro-Wilk normality test on the residuals
#' is run automatically; a warning is issued when p < 0.05 (residuals depart
#' from normality). If the outcome is right-skewed or contains many zeroes,
#' use [mysterycall_poisson_model()] or [mysterycall_nb_model()] instead.
#'
#' P-values use the Satterthwaite denominator-df approximation when the
#' `lmerTest` package is available (recommended), and fall back to a
#' conservative t-approximation with residual df otherwise.
#'
#' @param data A data frame. Rows with `NA` in any model column are dropped;
#'   the count is reported.
#' @param outcome Character scalar. Name of the continuous wait-day column
#'   (e.g. `"calendar_days"`). Must be numeric.
#' @param predictors Character vector of fixed-effect column names.
#'   Character and factor columns are dummy-coded; the reference level is the
#'   first level alphabetically (or `levels()[[1]]` for ordered factors).
#' @param random_intercept Character scalar. Grouping column for the physician
#'   random intercept (e.g. `"physician"`). A `(1 | column)` term is added
#'   automatically.
#' @param conf_level Numeric. Confidence level for Wald CIs. Default `0.95`.
#' @param REML Logical. Use Restricted Maximum Likelihood? Default `TRUE`
#'   (recommended for variance estimation). Set `FALSE` for AIC-based model
#'   comparison.
#' @param auto_log Logical. When `TRUE` (default), the function checks whether
#'   the outcome is right-skewed (sample skewness > 1 on non-negative values)
#'   and automatically applies a `log1p()` transform before fitting. Coefficients
#'   are returned on both the log scale (`coef_table`) and back-transformed as
#'   geometric mean ratios (`gmr_table`). Set to `FALSE` to suppress this
#'   behaviour and model the raw outcome.
#' @param sensitivity_poisson One of `"auto"` (default), `TRUE`, or `FALSE`.
#'   Controls whether a Poisson GLMM sensitivity analysis is run on the
#'   **original untransformed** outcome alongside the LMM:
#'   \describe{
#'     \item{`"auto"`}{Runs the Poisson model only when the Shapiro-Wilk test
#'       on LMM residuals returns p < 0.05, indicating non-normal residuals.}
#'     \item{`TRUE`}{Always runs the Poisson sensitivity model.}
#'     \item{`FALSE`}{Never runs it.}
#'   }
#'   Results are stored in `$sensitivity` (a `mysterycall_poisson_model`
#'   object) and printed as a compact IRR table. Requires `lme4`.
#' @param ... Additional arguments forwarded to [lme4::lmer()].
#'
#' @return A list of class `mysterycall_lmm` with elements:
#' \describe{
#'   \item{`model`}{`lmerMod` (or `lmerModLmerTest`). The fitted model.}
#'   \item{`coef_table`}{`tibble`. One row per fixed-effect term: `term`,
#'     `estimate`, `se`, `t_value`, `df`, `p_value`, `p_value_fmt`,
#'     `ci_lower`, `ci_upper`. Units are days (raw outcome) or log1p(days)
#'     when `log_transformed` is `TRUE`.}
#'   \item{`gmr_table`}{`tibble` or `NULL`. Present only when
#'     `log_transformed = TRUE`. Columns: `term`, `GMR` (geometric mean ratio
#'     of (days + 1) vs. reference level), `GMR_lo`, `GMR_hi`, `p_value_fmt`.
#'     A GMR < 1 means shorter wait relative to the reference.}
#'   \item{`log_transformed`}{`logical`. `TRUE` when `auto_log` triggered a
#'     `log1p()` transform.}
#'   \item{`outcome_original`}{`character`. The column name as supplied by
#'     the caller.}
#'   \item{`outcome_used`}{`character`. The column actually modelled
#'     (`log1p_<outcome>` when transformed, same as `outcome_original`
#'     otherwise).}
#'   \item{`random_effects`}{`data.frame` from [lme4::VarCorr()].}
#'   \item{`factor_refs`}{`list`. Reference levels for character/factor
#'     predictors.}
#'   \item{`formula`}{`formula`. The formula passed to lmer.}
#'   \item{`n`}{`integer`. Complete-case rows used.}
#'   \item{`n_dropped`}{`integer`. Rows excluded for missing values.}
#'   \item{`n_clusters`}{`integer`. Unique values of `random_intercept`.}
#'   \item{`sigma`}{`numeric`. Residual standard deviation.}
#'   \item{`r_squared`}{`list`. `marginal` and `conditional` R^2 (Nakagawa
#'     & Schielzeth 2013).}
#'   \item{`normality`}{`list`. Shapiro-Wilk test on model residuals:
#'     `statistic`, `p_value`, `interpretation`, `method`. Skipped when
#'     n > 5000.}
#'   \item{`convergence`}{`list`. `converged` (logical), `singular` (logical),
#'     `messages` (character vector).}
#'   \item{`aic`}{`numeric`. AIC (valid only when `REML = FALSE`).}
#'   \item{`bic`}{`numeric`. BIC (valid only when `REML = FALSE`).}
#'   \item{`sensitivity`}{`mysterycall_poisson_model` or `NULL`. A Poisson
#'     GLMM fit on the original (untransformed) outcome using the same
#'     predictors and random intercept. Present when `sensitivity_poisson`
#'     triggers; `NULL` otherwise. Use `$sensitivity$irr_table` for IRR
#'     estimates. IRR < 1 = shorter wait than reference.}
#'   \item{`sensitivity_note`}{`character` or `NULL`. One-sentence explanation
#'     of why the sensitivity analysis was (or was not) run.}
#' }
#'
#' @section Interpreting coefficients:
#' **Raw scale (`auto_log = FALSE` or skewness <= 1):** An estimate of `+5.2`
#' for `insuranceMedicaid` means physicians called with Medicaid had, on
#' average, **5.2 more wait days** than the reference group.
#'
#' **Log scale (`auto_log = TRUE`, skewness > 1):** Coefficients are on the
#' `log1p(days)` scale. Use `gmr_table` for interpretation: a GMR of `0.87`
#' means the group waits ~13% fewer days (* (days + 1)) than the reference.
#' Report as: "GMR = 0.87 (95% CI 0.49-1.54), p = 0.631."
#'
#' @section R-squared:
#' Marginal R^2 reflects variance explained by fixed effects alone;
#' conditional R^2 includes the physician random intercept. Both are computed
#' from the variance-component decomposition (Nakagawa & Schielzeth 2013) and
#' do not require any additional packages.
#'
#' @references
#' Nakagawa S, Schielzeth H (2013). A general and simple method for obtaining
#' R^2 from generalized linear mixed-effects models. *Methods in Ecology and
#' Evolution* 4(2):133-142. \doi{10.1111/j.2041-210x.2012.00261.x}
#'
#' @importFrom stats complete.cases qnorm as.formula shapiro.test AIC BIC sigma
#' @importFrom tibble tibble
#' @family outcomes
#' @seealso [plot.mysterycall_lmm()] for Q-Q and residual plots;
#'   [mysterycall_poisson_model()] for count outcomes;
#'   [mysterycall_nb_model()] for overdispersed counts;
#'   [mysterycall_model_comparison_table()] to compare models by AIC/BIC.
#' @export
#'
#' @examplesIf requireNamespace("lme4", quietly = TRUE)
#' set.seed(42)
#' df <- data.frame(
#'   wait_days = round(rnorm(80, mean = 21, sd = 8)),
#'   insurance = rep(c("Medicaid", "BCBS"), 40),
#'   physician = rep(paste0("Dr", 1:20), each = 4),
#'   stringsAsFactors = FALSE
#' )
#' fit <- mysterycall_lmm(df, "wait_days", "insurance", "physician")
#' print(fit)
mysterycall_lmm <- function(data,
                             outcome,
                             predictors,
                             random_intercept,
                             conf_level           = 0.95,
                             REML                 = TRUE,
                             auto_log             = TRUE,
                             sensitivity_poisson  = "auto",
                             ...) {

  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("Package 'lme4' is required. Install with: install.packages('lme4')",
         call. = FALSE)
  }

  # -- Input validation ----------------------------------------------------------
  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
  validate_required_columns(data, outcome,          name = "data")
  validate_required_columns(data, predictors,       name = "data")
  validate_required_columns(data, random_intercept, name = "data")

  if (!is.character(outcome) || length(outcome) != 1L)
    stop("`outcome` must be a single column name.", call. = FALSE)
  if (!is.numeric(data[[outcome]]))
    stop(sprintf("`%s` must be numeric.", outcome), call. = FALSE)
  if (!is.character(random_intercept) || length(random_intercept) != 1L)
    stop("`random_intercept` must be a single column name.", call. = FALSE)
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1)
    stop("`conf_level` must be a single number in (0, 1).", call. = FALSE)

  # -- Complete-case filtering ---------------------------------------------------
  model_cols <- unique(c(outcome, predictors, random_intercept))
  n_before   <- nrow(data)
  cc_mask    <- stats::complete.cases(data[, model_cols, drop = FALSE])
  data_cc    <- data[cc_mask, , drop = FALSE]
  n_dropped  <- n_before - nrow(data_cc)

  if (n_dropped > 0L) {
    message(sprintf("%d row(s) with missing values excluded (%.1f%% of data).",
                    n_dropped, n_dropped / n_before * 100))
  }
  if (!nrow(data_cc))
    stop("No complete cases remain after removing rows with missing values.", call. = FALSE)

  # -- Auto log1p transform for right-skewed non-negative outcomes ---------------
  log_transformed  <- FALSE
  outcome_original <- outcome

  if (isTRUE(auto_log)) {
    y_raw <- data_cc[[outcome]]
    if (min(y_raw, na.rm = TRUE) >= 0) {
      y_mean <- mean(y_raw, na.rm = TRUE)
      y_sd   <- stats::sd(y_raw, na.rm = TRUE)
      skew   <- if (y_sd > 0) {
        mean(((y_raw - y_mean) / y_sd)^3, na.rm = TRUE)
      } else 0
      if (skew > 1) {
        log_col <- paste0("log1p_", outcome)
        data_cc[[log_col]] <- log1p(y_raw)
        message(sprintf(
          paste0(
            "auto_log: right-skewed outcome detected (skewness = %.2f > 1). ",
            "Applying log1p(%s) -> '%s'. ",
            "Coefficients are on the log scale; GMR back-transforms are in $gmr_table. ",
            "To model the raw outcome, set auto_log = FALSE."
          ),
          skew, outcome, log_col
        ))
        outcome         <- log_col
        log_transformed <- TRUE
      }
    }
  }

  # -- Normality pre-check on raw outcome ----------------------------------------
  y_range <- diff(range(data_cc[[outcome_original]], na.rm = TRUE))
  if (y_range < 30) {
    warning(sprintf(
      paste0("Outcome range is only %.0f days (< 30). LMM assumes approximate normality; ",
             "with a narrow range the distribution may be non-normal or floor-censored. ",
             "Consider Poisson/NB GLMM instead and check the Q-Q plot."),
      y_range
    ), call. = FALSE)
  }

  # -- Observations-per-parameter check ------------------------------------------
  est_df <- 1L
  for (.pred in predictors) {
    x <- data_cc[[.pred]]
    est_df <- est_df + if (is.factor(x) || is.character(x)) {
      length(unique(x[!is.na(x)])) - 1L
    } else {
      1L
    }
  }
  opv <- nrow(data_cc) / est_df
  if (opv < 5) {
    warning(sprintf(
      "Very low obs-per-parameter: %d obs / %d params = %.1f. Estimates will be unreliable.",
      nrow(data_cc), est_df, opv
    ), call. = FALSE)
  } else if (opv < 10) {
    warning(sprintf(
      "Low obs-per-parameter: %d obs / %d params = %.1f. Convention recommends >= 10.",
      nrow(data_cc), est_df, opv
    ), call. = FALSE)
  }

  # -- Reference levels ----------------------------------------------------------
  factor_refs <- Filter(Negate(is.null), lapply(
    setNames(predictors, predictors),
    function(pred) {
      x <- data_cc[[pred]]
      if (is.factor(x))    return(levels(x)[[1L]])
      if (is.character(x)) return(sort(unique(x[!is.na(x)]))[[1L]])
      NULL
    }
  ))

  # -- Build formula -------------------------------------------------------------
  fixed_part    <- paste(predictors, collapse = " + ")
  random_part   <- sprintf("(1 | %s)", random_intercept)
  formula_str   <- sprintf("%s ~ %s + %s", outcome, fixed_part, random_part)
  model_formula <- stats::as.formula(formula_str)

  message(sprintf("Fitting LMM: %s", deparse(model_formula)))

  # -- Fit (prefer lmerTest for Satterthwaite p-values) -------------------------
  warnings_captured <- character(0L)
  use_lmertest      <- requireNamespace("lmerTest", quietly = TRUE)

  fit_fn <- if (use_lmertest) lmerTest::lmer else lme4::lmer

  model <- tryCatch(
    withCallingHandlers(
      fit_fn(formula = model_formula, data = data_cc, REML = REML, ...),
      warning = function(w) {
        warnings_captured <<- c(warnings_captured, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      stop(sprintf("lmer() failed to fit: %s", e$message), call. = FALSE)
    }
  )

  # -- Convergence / singularity -------------------------------------------------
  conv_msgs   <- model@optinfo$conv$lme4$messages
  is_singular <- lme4::isSingular(model)
  converged   <- is.null(conv_msgs) && !length(warnings_captured)

  if (!converged) {
    all_msgs <- c(conv_msgs, warnings_captured)
    warning(sprintf(
      "Convergence issues detected:\n  %s",
      paste(all_msgs, collapse = "\n  ")
    ), call. = FALSE)
  }
  if (is_singular) {
    warning(
      "Singular fit: physician random-intercept variance is ~0. Consider a fixed-effects-only model.",
      call. = FALSE
    )
  }

  # -- Coefficient table ---------------------------------------------------------
  fe <- as.data.frame(coef(summary(model)))

  # Column names differ between lmer and lmerTest::lmer
  est_col  <- "Estimate"
  se_col   <- "Std. Error"
  t_col    <- if ("t value" %in% names(fe)) "t value" else "t value"
  df_col   <- if ("df" %in% names(fe)) "df" else NULL
  pval_col <- if ("Pr(>|t|)" %in% names(fe)) "Pr(>|t|)" else NULL

  p_values <- if (!is.null(pval_col)) {
    fe[[pval_col]]
  } else {
    # Conservative fallback: t with residual df (est_df already counts intercept)
    df_resid <- nrow(data_cc) - est_df
    2 * stats::pt(abs(fe[[t_col]]), df = df_resid, lower.tail = FALSE)
  }

  df_values <- if (!is.null(df_col)) fe[[df_col]] else {
    rep(nrow(data_cc) - est_df, nrow(fe))
  }

  # Per-term t critical value so the CI matches the Satterthwaite t-based
  # p-value (a normal z quantile would disagree at small residual df).
  t_crit <- stats::qt(1 - (1 - conf_level) / 2, df = df_values)

  coef_table <- tibble::tibble(
    term        = rownames(fe),
    estimate    = fe[[est_col]],
    se          = fe[[se_col]],
    t_value     = fe[[t_col]],
    df          = df_values,
    p_value     = p_values,
    p_value_fmt = .fmt_lmm_pval(p_values),
    ci_lower    = fe[[est_col]] - t_crit * fe[[se_col]],
    ci_upper    = fe[[est_col]] + t_crit * fe[[se_col]]
  )

  # -- Back-transform to geometric mean ratios when log-transformed -------------
  gmr_table <- if (log_transformed) {
    tibble::tibble(
      term        = coef_table$term,
      GMR         = exp(coef_table$estimate),
      GMR_lo      = exp(coef_table$ci_lower),
      GMR_hi      = exp(coef_table$ci_upper),
      p_value_fmt = coef_table$p_value_fmt
    )
  } else {
    NULL
  }

  # -- Random effects ------------------------------------------------------------
  re_df      <- as.data.frame(lme4::VarCorr(model))
  n_clusters <- lme4::ngrps(model)[[random_intercept]]
  res_sigma  <- stats::sigma(model)

  # -- Normality test on residuals -----------------------------------------------
  resids    <- stats::residuals(model)
  normality <- .lmm_normality(resids)

  if (!is.na(normality$p_value) && normality$p_value < 0.05) {
    warning(sprintf(
      paste0("Shapiro-Wilk test on residuals: W = %.4f, p = %.4f. ",
             "Residuals depart from normality. Consider Poisson/NB GLMM, ",
             "a log-transform of the outcome, or check the Q-Q plot."),
      normality$statistic, normality$p_value
    ), call. = FALSE)
  }

  # -- Poisson sensitivity analysis ---------------------------------------------
  run_sensitivity <- isTRUE(sensitivity_poisson) ||
    (identical(sensitivity_poisson, "auto") &&
       !is.na(normality$p_value) && normality$p_value < 0.05)

  sensitivity      <- NULL
  sensitivity_note <- NULL

  if (run_sensitivity) {
    sensitivity_note <- sprintf(
      paste0("Poisson GLMM sensitivity analysis on %s ",
             "(original scale, log link). ",
             "IRR < 1 = shorter wait than reference. ",
             "Triggered by: %s"),
      outcome_original,
      if (identical(sensitivity_poisson, TRUE)) {
        "sensitivity_poisson = TRUE"
      } else {
        sprintf("Shapiro-Wilk p = %.4f < 0.05 on LMM residuals", normality$p_value)
      }
    )
    sensitivity <- tryCatch(
      suppressMessages(
        mysterycall_poisson_model(
          data             = data_cc,
          outcome          = outcome_original,
          predictors       = predictors,
          random_intercept = random_intercept,
          conf_level       = conf_level
        )
      ),
      error = function(e) {
        sensitivity_note <<- sprintf(
          "Poisson sensitivity failed: %s", e$message
        )
        NULL
      }
    )
  }

  # -- R-squared (Nakagawa & Schielzeth 2013) ------------------------------------
  r2 <- .lmm_r_squared(model, re_df, res_sigma)

  message(sprintf(
    "Model fitted: n=%d, physicians=%d, AIC=%.1f, sigma=%.2f, R2m=%.3f, R2c=%.3f",
    nrow(data_cc), n_clusters, AIC(model), res_sigma, r2$marginal, r2$conditional
  ))

  structure(
    list(
      model            = model,
      coef_table       = coef_table,
      gmr_table        = gmr_table,
      log_transformed  = log_transformed,
      outcome_original = outcome_original,
      outcome_used     = outcome,
      random_effects   = re_df,
      factor_refs      = factor_refs,
      formula          = model_formula,
      n                = nrow(data_cc),
      n_dropped        = n_dropped,
      n_clusters       = n_clusters,
      sigma            = res_sigma,
      r_squared        = r2,
      normality        = normality,
      convergence      = list(
        converged = converged,
        singular  = is_singular,
        messages  = c(conv_msgs, warnings_captured)
      ),
      aic              = AIC(model),
      bic              = BIC(model),
      REML             = REML,
      sensitivity      = sensitivity,
      sensitivity_note = sensitivity_note
    ),
    class = "mysterycall_lmm"
  )
}


# ----- internal helpers -------------------------------------------------------

.fmt_lmm_pval <- function(p) {
  ifelse(is.na(p), NA_character_,
         ifelse(p < 0.001, "< 0.001", sprintf("%.3f", p)))
}

.lmm_normality <- function(resids) {
  n <- length(resids)
  if (n > 5000L) {
    return(list(
      statistic      = NA_real_,
      p_value        = NA_real_,
      interpretation = "Shapiro-Wilk skipped (n > 5000); inspect Q-Q plot.",
      method         = "none"
    ))
  }
  res <- tryCatch(stats::shapiro.test(resids), error = function(e) NULL)
  if (is.null(res)) {
    return(list(statistic = NA_real_, p_value = NA_real_,
                interpretation = "Shapiro-Wilk could not be computed.", method = "none"))
  }
  interp <- if (res$p.value >= 0.05) {
    "Residuals consistent with normality (p >= 0.05)."
  } else if (res$p.value >= 0.01) {
    "Mild departure from normality (0.01 <= p < 0.05); inspect Q-Q plot."
  } else {
    "Significant departure from normality (p < 0.01); consider Poisson/NB GLMM."
  }
  list(statistic = as.numeric(res$statistic), p_value = as.numeric(res$p.value),
       interpretation = interp, method = "Shapiro-Wilk")
}

.lmm_r_squared <- function(model, re_df, sigma_resid) {
  tryCatch({
    fe_var <- stats::var(as.numeric(lme4::getME(model, "X") %*% lme4::fixef(model)))
    re_row <- re_df[!is.na(re_df$grp) & re_df$grp != "Residual", , drop = FALSE]
    re_var <- if (nrow(re_row)) sum(re_row$vcov, na.rm = TRUE) else 0
    res_var <- sigma_resid^2
    total   <- fe_var + re_var + res_var
    list(
      marginal    = fe_var / total,
      conditional = (fe_var + re_var) / total
    )
  }, error = function(e) {
    list(marginal = NA_real_, conditional = NA_real_)
  })
}


#' Print method for mysterycall_lmm objects
#'
#' Displays a formatted console summary: sample size, physician count,
#' AIC/BIC, residual SD, normality test, R^2, reference levels, and the
#' fixed-effects table with coefficients in **days**.
#'
#' @param x A `mysterycall_lmm` object.
#' @param digits Integer. Decimal places for coefficient display. Default `2`.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_lmm <- function(x, digits = 2, ...) {
  reml_label <- if (x$REML) "REML" else "ML"
  log_label  <- if (isTRUE(x$log_transformed)) "log1p(days)" else "days"
  cat(sprintf(
    "Linear Mixed Model (%s)  n = %d  physicians = %d\n",
    reml_label, x$n, x$n_clusters
  ))
  cat(sprintf("  AIC = %.1f   BIC = %.1f   Residual SD = %.2f %s\n",
              x$aic, x$bic, x$sigma, log_label))

  if (!is.na(x$r_squared$marginal)) {
    cat(sprintf("  R^2 marginal = %.3f   conditional = %.3f\n",
                x$r_squared$marginal, x$r_squared$conditional))
  }

  if (x$n_dropped > 0L)
    cat(sprintf("  (%d row(s) excluded for missing values)\n", x$n_dropped))

  flags <- character(0L)
  if (!x$convergence$converged) flags <- c(flags, "convergence warnings")
  if (x$convergence$singular)   flags <- c(flags, "singular fit")
  if (!is.na(x$normality$p_value) && x$normality$p_value < 0.05)
    flags <- c(flags, sprintf("non-normal residuals (Shapiro-Wilk p=%.3f)", x$normality$p_value))
  if (length(flags))
    cat(sprintf("  Warning: %s\n", paste(flags, collapse = "; ")))

  if (!is.na(x$normality$p_value)) {
    cat(sprintf("  Normality: %s\n", x$normality$interpretation))
  }

  if (length(x$factor_refs)) {
    refs <- paste(sprintf("%s='%s'", names(x$factor_refs), unlist(x$factor_refs)),
                  collapse = ", ")
    cat(sprintf("  Reference levels: %s\n", refs))
  }

  if (isTRUE(x$log_transformed)) {
    cat(sprintf(
      "  Outcome: log1p(%s) [auto_log]. Coefs are on log scale; see GMR table below.\n",
      x$outcome_original
    ))
  }

  cat(sprintf("\nFixed effects (%s):\n", log_label))
  tbl <- as.data.frame(x$coef_table[, c("term", "estimate", "se", "ci_lower", "ci_upper", "p_value_fmt")])
  tbl$estimate <- round(tbl$estimate, digits)
  tbl$se       <- round(tbl$se,       digits)
  tbl$ci_lower <- round(tbl$ci_lower, digits)
  tbl$ci_upper <- round(tbl$ci_upper, digits)
  names(tbl)[names(tbl) == "p_value_fmt"] <- "p-value"
  print(tbl, row.names = FALSE)

  if (!is.null(x$gmr_table)) {
    cat("\nGeometric mean ratios [exp(estimate)] -- GMR < 1 = shorter wait:\n")
    gmr <- as.data.frame(x$gmr_table)
    gmr$GMR    <- round(gmr$GMR,    3)
    gmr$GMR_lo <- round(gmr$GMR_lo, 3)
    gmr$GMR_hi <- round(gmr$GMR_hi, 3)
    names(gmr)[names(gmr) == "p_value_fmt"] <- "p-value"
    print(gmr, row.names = FALSE)
  }

  re <- x$random_effects[
    !is.na(x$random_effects$grp) & x$random_effects$grp != "Residual", ,
    drop = FALSE
  ]
  if (nrow(re)) {
    cat(sprintf("\nRandom intercept (%s):  variance = %.4f  SD = %.4f %s\n",
                re$grp[[1L]], re$vcov[[1L]], re$sdcor[[1L]], log_label))
  }

  if (!is.null(x$sensitivity)) {
    cat("\n-- Sensitivity Analysis: Poisson GLMM (same outcome, log link) --\n")
    if (!is.null(x$sensitivity_note)) cat(strwrap(x$sensitivity_note, width = 72,
                                                    prefix = "  "), sep = "\n")
    cat("\n")
    irr <- as.data.frame(
      x$sensitivity$irr_table[, c("term", "irr", "ci_lower", "ci_upper", "p_value_fmt")]
    )
    irr$irr      <- round(irr$irr,      digits)
    irr$ci_lower <- round(irr$ci_lower, digits)
    irr$ci_upper <- round(irr$ci_upper, digits)
    names(irr)[names(irr) == "p_value_fmt"] <- "p-value"
    print(irr, row.names = FALSE)
    cat("  IRR < 1 = shorter wait than reference. Check $sensitivity for full output.\n")
  } else if (!is.null(x$sensitivity_note)) {
    cat(sprintf("\nSensitivity: %s\n", x$sensitivity_note))
  }

  invisible(x)
}


#' Q-Q and residual diagnostic plots for a fitted LMM
#'
#' Produces two side-by-side diagnostic panels: a Normal Q-Q plot of the
#' model residuals and a residuals-vs-fitted plot. Use these **before** relying
#' on the LMM - if the Q-Q plot shows a systematic S-shape or heavy tails,
#' switch to a Poisson or negative-binomial GLMM.
#'
#' @param x A `mysterycall_lmm` object returned by [mysterycall_lmm()].
#' @param ... Ignored.
#'
#' @return A `ggplot` object (invisibly). The plot is also printed to the
#'   active graphics device.
#'
#' @family outcomes
#' @seealso [mysterycall_lmm()] which produces this object.
#' @export
#'
#' @examplesIf requireNamespace("lme4", quietly = TRUE) && requireNamespace("ggplot2", quietly = TRUE)
#' set.seed(42)
#' df <- data.frame(
#'   wait_days = round(rnorm(80, 21, 8)),
#'   insurance = rep(c("Medicaid", "BCBS"), 40),
#'   physician = rep(paste0("Dr", 1:20), each = 4),
#'   stringsAsFactors = FALSE
#' )
#' fit <- mysterycall_lmm(df, "wait_days", "insurance", "physician")
#' plot(fit)
plot.mysterycall_lmm <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for diagnostic plots. Install with: install.packages('ggplot2')",
         call. = FALSE)
  }

  resids  <- stats::residuals(x$model)
  fitted  <- stats::fitted(x$model)

  df_qq <- data.frame(
    theoretical = stats::qqnorm(resids, plot.it = FALSE)$x,
    sample      = stats::qqnorm(resids, plot.it = FALSE)$y
  )
  df_rf <- data.frame(fitted = fitted, residuals = resids)

  # Q-Q plot
  qq <- ggplot2::ggplot(df_qq, ggplot2::aes(x = .data$theoretical, y = .data$sample)) +
    ggplot2::geom_point(size = 1.5, alpha = 0.6) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "steelblue", linewidth = 0.8) +
    ggplot2::labs(
      title    = "Normal Q-Q Plot",
      subtitle = sprintf("Shapiro-Wilk: %s",
                         if (!is.na(x$normality$p_value))
                           sprintf("W = %.4f, p = %.4f", x$normality$statistic, x$normality$p_value)
                         else x$normality$interpretation),
      x = "Theoretical quantiles",
      y = "Sample quantiles"
    ) +
    ggplot2::theme_bw()

  # Residuals vs fitted
  rv <- ggplot2::ggplot(df_rf, ggplot2::aes(x = .data$fitted, y = .data$residuals)) +
    ggplot2::geom_point(size = 1.5, alpha = 0.6) +
    ggplot2::geom_hline(yintercept = 0, colour = "steelblue", linewidth = 0.8, linetype = "dashed") +
    ggplot2::geom_smooth(method = "loess", formula = y ~ x, se = FALSE,
                         colour = "firebrick", linewidth = 0.7) +
    ggplot2::labs(
      title    = "Residuals vs Fitted",
      subtitle = sprintf("Residual SD = %.2f days", x$sigma),
      x = "Fitted values (days)",
      y = "Residuals (days)"
    ) +
    ggplot2::theme_bw()

  if (requireNamespace("patchwork", quietly = TRUE)) {
    p <- patchwork::wrap_plots(qq, rv, ncol = 2L)
  } else {
    p <- qq
    message("Install 'patchwork' to show both panels side-by-side. Printing Q-Q plot only.")
  }

  print(p)
  invisible(p)
}


#' Tidy method for mysterycall_lmm objects
#'
#' Returns a broom-compatible tibble of fixed-effect coefficients with Wald
#' 95% CIs and Satterthwaite p-values. When the model was fit on a
#' log-transformed outcome, `estimate` is on the **log** scale; use
#' `$gmr_table` for back-transformed geometric mean ratios.
#'
#' @param x A `mysterycall_lmm` object returned by [mysterycall_lmm()].
#' @param ... Ignored; present for S3 consistency.
#'
#' @return A [tibble::tibble()] with one row per fixed-effect term and columns:
#' \describe{
#'   \item{`term`}{Coefficient name.}
#'   \item{`estimate`}{Point estimate (days, or log-days if log-transformed).}
#'   \item{`std.error`}{Standard error.}
#'   \item{`statistic`}{t-statistic.}
#'   \item{`df`}{Satterthwaite denominator degrees of freedom.}
#'   \item{`p.value`}{Two-tailed Satterthwaite p-value.}
#'   \item{`conf.low`}{Lower bound of Wald CI.}
#'   \item{`conf.high`}{Upper bound of Wald CI.}
#' }
#'
#' @family outcomes
#' @importFrom generics tidy
#' @method tidy mysterycall_lmm
#' @export
#' @examples
#' \donttest{
#' fake_fit <- structure(
#'   list(coef_table = data.frame(
#'     term = "scenarioB", estimate = 2.1, se = 0.5,
#'     t_value = 4.2, df = 80, p_value = 0.001,
#'     ci_lower = 1.1, ci_upper = 3.1,
#'     stringsAsFactors = FALSE
#'   )),
#'   class = "mysterycall_lmm"
#' )
#' generics::tidy(fake_fit)
#' }
tidy.mysterycall_lmm <- function(x, ...) {
  tbl <- x$coef_table
  tibble::tibble(
    term      = tbl$term,
    estimate  = tbl$estimate,
    std.error = tbl$se,
    statistic = tbl$t_value,
    df        = tbl$df,
    p.value   = tbl$p_value,
    conf.low  = tbl$ci_lower,
    conf.high = tbl$ci_upper
  )
}

