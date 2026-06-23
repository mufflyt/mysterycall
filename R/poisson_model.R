#' Fit a Poisson GLMER for mystery caller wait-time analysis
#'
#' Runs a multilevel Poisson regression (`lme4::glmer`) appropriate for
#' mystery caller studies where the same physician may be called multiple
#' times (e.g. with different insurance types). The physician identifier is
#' modelled as a random intercept, which accounts for correlation within
#' physicians. Fixed-effect results are returned as incidence rate ratios
#' (IRR) with Wald confidence intervals.
#'
#' @name mysterycall_poisson_model
NULL

#' Format Model P-Value for Display
#'
#' @param p Numeric p-value.
#'
#' @return Formatted character string (e.g., "<0.001").
#' @family outcomes
#' @keywords internal
.fmt_model_pval <- function(p) {
  ifelse(is.na(p), NA_character_,
         ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
}


#' Fit a Poisson GLMER and return IRR table
#'
#' @param data A data frame containing all model columns. Rows with `NA` in
#'   any model column are dropped before fitting; the count is reported.
#' @param outcome Character scalar naming the count-outcome column (e.g.
#'   `"business_days_until_appointment"`). Must be non-negative numeric.
#' @param predictors Character vector of fixed-effect predictor column names.
#'   Factor and character columns are used as-is; their reference level is
#'   the first level alphabetically (or the first `levels()` for factors).
#' @param random_intercept Character scalar naming the grouping column for
#'   the random intercept (e.g. `"name"` for physician). A `(1 | column)`
#'   term is added to the formula automatically.
#' @param conf_level Confidence level for Wald CIs. Default `0.95`.
#' @param nAGQ Integer passed to [lme4::glmer()]. `0` (default) uses the
#'   fastest approximation; `1` uses the Laplace approximation; values `> 1`
#'   use adaptive Gauss-Hermite quadrature (slower, more accurate for small
#'   cluster sizes).
#' @param offset_col Optional character scalar naming a numeric column to use
#'   as a log-offset (e.g. log(exposure time)). When supplied, the term
#'   `offset(log(offset_col))` is appended to the fixed-effects formula.
#' @param ... Additional arguments forwarded to [lme4::glmer()].
#'
#' @return A list of class `mysterycall_poisson_model` containing:
#' \describe{
#'   \item{`model`}{`glmerMod`. The fitted multilevel Poisson model.}
#'   \item{`irr_table`}{`tibble`. One row per fixed-effect term with
#'     columns: `term` (character), `estimate` (numeric, log scale),
#'     `se` (numeric), `z_value` (numeric), `p_value` (numeric),
#'     `p_value_fmt` (character, formatted), `irr` (numeric, incidence
#'     rate ratio), `ci_lower` (numeric), `ci_upper` (numeric).}
#'   \item{`random_effects`}{`data.frame` from [lme4::VarCorr()].
#'     Describes random-intercept variance and standard deviation.}
#'   \item{`factor_refs`}{`list` (named). Reference levels for each
#'     character/factor predictor.}
#'   \item{`formula`}{`formula`. The formula passed to [lme4::glmer()].}
#'   \item{`n`}{`integer`. Number of complete-case rows used for fitting.}
#'   \item{`n_dropped`}{`integer`. Rows excluded due to missing values.}
#'   \item{`n_clusters`}{`integer`. Number of unique values of
#'     `random_intercept`.}
#'   \item{`overdispersion`}{`numeric`. Pearson chi-square / residual df.
#'     Values substantially above 1 (common threshold: 2) suggest
#'     overdispersion; consider a negative binomial model.}
#'   \item{`convergence`}{`list`. Elements: `converged` (logical),
#'     `singular` (logical), `messages` (character vector).}
#'   \item{`aic`}{`numeric`. Akaike Information Criterion.}
#'   \item{`bic`}{`numeric`. Bayesian Information Criterion.}
#' }
#'
#' @section Interpreting IRRs:
#' An IRR of 1.40 for `insurance_typeMedicaid` means physicians contacted
#' with Medicaid insurance had, on average, 40% longer wait times than the
#' reference insurance group. Compute as `exp(estimate)` with Wald CI
#' `exp(estimate +/- z * se)`.
#'
#' @section Overdispersion:
#' Poisson assumes mean = variance. If `overdispersion` is substantially
#' greater than 1 (a common threshold is 2), the standard errors will be
#' underestimated. Consider fitting a negative binomial model or using
#' quasi-Poisson standard errors for inference.
#'
#' @importFrom stats poisson as.formula complete.cases qnorm AIC BIC residuals
#' @importFrom tibble tibble
#' @family outcomes
#' @seealso [mysterycall_wait_time_summary()], [mysterycall_table1()],
#'   [mysterycall_create_formula()]
#' @export
#'
#' @examplesIf requireNamespace("lme4", quietly = TRUE)
#' set.seed(1978)
#' df <- data.frame(
#'   wait_days = rpois(40, lambda = 18),
#'   insurance = rep(c("Medicaid", "BCBS"), each = 20),
#'   gender    = sample(c("Male", "Female"), 40, replace = TRUE),
#'   physician = rep(paste0("Dr_", 1:8), each = 5),
#'   stringsAsFactors = FALSE
#' )
#' result <- mysterycall_poisson_model(
#'   df,
#'   outcome          = "wait_days",
#'   predictors       = c("insurance", "gender"),
#'   random_intercept = "physician"
#' )
#' result$irr_table
mysterycall_poisson_model <- function(data,
                                      outcome,
                                      predictors,
                                      random_intercept,
                                      conf_level = 0.95,
                                      nAGQ       = 0L,
                                      offset_col = NULL,
                                      ...) {

  # -- Require lme4 -------------------------------------------------------------
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop(
      "Package 'lme4' is required",
      call. = FALSE
    )
  }

  # -- Validate inputs -----------------------------------------------------------
  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
  validate_required_columns(data, outcome,          name = "data")
  validate_required_columns(data, predictors,       name = "data")
  validate_required_columns(data, random_intercept, name = "data")

  if (!is.character(outcome) || length(outcome) != 1L) {
    stop("`outcome` must be a single column name.", call. = FALSE)
  }
  if (!is.numeric(data[[outcome]])) {
    stop(sprintf("`%s` must be numeric (count of days).", outcome), call. = FALSE)
  }
  if (any(data[[outcome]] < 0, na.rm = TRUE)) {
    stop(sprintf("`%s` contains negative values; Poisson requires counts >= 0.", outcome),
         call. = FALSE)
  }
  if (!is.character(random_intercept) || length(random_intercept) != 1L) {
    stop("`random_intercept` must be a single column name.", call. = FALSE)
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    stop("`conf_level` must be a single number strictly between 0 and 1.", call. = FALSE)
  }
  if (!is.null(offset_col)) {
    validate_required_columns(data, offset_col, name = "data")
    if (!is.numeric(data[[offset_col]])) {
      stop(sprintf("`%s` (offset_col) must be numeric.", offset_col), call. = FALSE)
    }
  }

  # -- Complete-case filtering ---------------------------------------------------
  model_cols <- unique(c(outcome, predictors, random_intercept, offset_col))
  n_before   <- nrow(data)
  cc_mask    <- stats::complete.cases(data[, model_cols, drop = FALSE])
  data_cc    <- data[cc_mask, , drop = FALSE]
  n_dropped  <- n_before - nrow(data_cc)

  if (n_dropped > 0L) {
    message(sprintf(
      "%d row(s) with missing values excluded (%.1f%% of data).",
      n_dropped, n_dropped / n_before * 100
    ))
  }
  if (!nrow(data_cc)) {
    stop("No complete cases remain after removing rows with missing values.", call. = FALSE)
  }

  n_zeros <- sum(data_cc[[outcome]] == 0L, na.rm = TRUE)
  if (n_zeros > 0L) {
    message(sprintf(
      "%d row(s) have %s = 0 (same-day appointments). Poisson handles zeros; verify these are intentional.",
      n_zeros, outcome
    ))
  }

  # -- Degrees-of-freedom check ------------------------------------------------
  est_df <- 1L  # intercept
  for (.pred in predictors) {
    .x <- data_cc[[.pred]]
    if (is.factor(.x) || is.character(.x)) {
      est_df <- est_df + length(unique(.x[!is.na(.x)])) - 1L
    } else {
      est_df <- est_df + 1L
    }
  }
  epv <- nrow(data_cc) / est_df
  if (epv < 5) {
    warning(sprintf(
      "Very low events-per-variable ratio: %d observations / %d model parameters = %.1f obs/param. Model estimates will be unreliable. Remove predictors or collect more data.",
      nrow(data_cc), est_df, epv
    ), call. = FALSE)
  } else if (epv < 10) {
    warning(sprintf(
      "Low events-per-variable ratio: %d observations / %d model parameters = %.1f obs/param. Convention recommends >=10 per parameter. Consider removing low-priority predictors.",
      nrow(data_cc), est_df, epv
    ), call. = FALSE)
  }

  # -- Reference levels for factor/character predictors -------------------------
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
  fixed_part  <- paste(predictors, collapse = " + ")
  random_part <- sprintf("(1 | %s)", random_intercept)
  offset_part <- if (!is.null(offset_col)) {
    sprintf(" + offset(log(%s))", offset_col)
  } else {
    ""
  }

  formula_str   <- sprintf("%s ~ %s + %s%s",
                           outcome, fixed_part, random_part, offset_part)
  model_formula <- stats::as.formula(formula_str)

  message(sprintf("Fitting Poisson GLMER: %s", deparse(model_formula)))

  # -- Fit -----------------------------------------------------------------------
  warnings_captured <- character(0L)

  model <- tryCatch(
    withCallingHandlers(
      lme4::glmer(
        formula = model_formula,
        data    = data_cc,
        family  = stats::poisson(link = "log"),
        nAGQ    = nAGQ,
        ...
      ),
      warning = function(w) {
        warnings_captured <<- c(warnings_captured, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      stop(sprintf("glmer() failed to fit: %s", e$message), call. = FALSE)
    }
  )

  # -- Convergence / singularity -------------------------------------------------
  conv_msgs   <- model@optinfo$conv$lme4$messages
  is_singular <- lme4::isSingular(model)
  converged   <- is.null(conv_msgs) && !length(warnings_captured)

  if (!converged) {
    all_msgs <- c(conv_msgs, warnings_captured)
    warning(sprintf(
      "Convergence issues detected:\n  %s\nConsider simplifying predictors or using nAGQ = 1.",
      paste(all_msgs, collapse = "\n  ")
    ), call. = FALSE)
  }
  if (is_singular) {
    warning(
      "Singular fit: random-intercept variance is ~0. The physician-level random effect explains little variation.",
      call. = FALSE
    )
  }

  # -- IRR table -----------------------------------------------------------------
  z_crit <- stats::qnorm(1 - (1 - conf_level) / 2)
  fe     <- as.data.frame(coef(summary(model)))

  irr_table <- tibble::tibble(
    term        = rownames(fe),
    estimate    = fe$Estimate,
    se          = fe[["Std. Error"]],
    z_value     = fe[["z value"]],
    p_value     = fe[["Pr(>|z|)"]],
    p_value_fmt = .fmt_model_pval(fe[["Pr(>|z|)"]]),
    irr         = exp(fe$Estimate),
    ci_lower    = exp(fe$Estimate - z_crit * fe[["Std. Error"]]),
    ci_upper    = exp(fe$Estimate + z_crit * fe[["Std. Error"]])
  )

  # -- Random effects and overdispersion -----------------------------------------
  re_df <- as.data.frame(lme4::VarCorr(model))

  pearson_resid  <- residuals(model, type = "pearson")
  df_resid       <- nrow(data_cc) - length(lme4::fixef(model))
  overdispersion <- sum(pearson_resid^2, na.rm = TRUE) / max(df_resid, 1L)

  if (overdispersion > 2) {
    warning(sprintf(
      "Overdispersion detected (phi = %.2f). Standard errors may be underestimated. Consider a negative binomial model.",
      overdispersion
    ), call. = FALSE)
  }

  n_clusters <- lme4::ngrps(model)[[random_intercept]]

  message(sprintf(
    "Model fitted: n=%d, physicians=%d, AIC=%.1f, overdispersion=%.2f",
    nrow(data_cc), n_clusters, AIC(model), overdispersion
  ))

  structure(
    list(
      model          = model,
      irr_table      = irr_table,
      random_effects = re_df,
      factor_refs    = factor_refs,
      formula        = model_formula,
      n              = nrow(data_cc),
      n_dropped      = n_dropped,
      n_clusters     = n_clusters,
      overdispersion = overdispersion,
      convergence    = list(
        converged = converged,
        singular  = is_singular,
        messages  = c(conv_msgs, warnings_captured)
      ),
      aic = AIC(model),
      bic = BIC(model)
    ),
    class = "mysterycall_poisson_model"
  )
}

#' Print method for mysterycall_poisson_model objects
#'
#' Displays a formatted console summary of the fitted model: sample size,
#' number of physicians, AIC/BIC, any convergence warnings, reference levels
#' for each factor, and a fixed-effects table with incidence rate ratios (IRR),
#' Wald 95% CIs, and p-values.
#'
#' @param x A `mysterycall_poisson_model` object.
#' @param digits Integer. Decimal places for coefficient display. Default `3`.
#' @param ... Ignored.
#' @return `invisible(x)` (the original model list, returned silently so
#'   the print method can be used in pipes without printing twice).
#' @seealso [mysterycall_poisson_model()] which produces this object;
#'   [mysterycall_irr_plot()] to visualize the same IRR estimates.
#' @family outcomes
#' @export
#' @examples
#' \dontrun{
#' model <- mysterycall_poisson_model(data, outcome_col = "wait_days",
#'                                     predictor_col = "insurance",
#'                                     random_intercept = "physician_id")
#' print(model)
#' }
print.mysterycall_poisson_model <- function(x, digits = 3, ...) {
  cat(sprintf(
    "Poisson GLMER  n = %d  physicians = %d  AIC = %.1f  BIC = %.1f\n",
    x$n, x$n_clusters, x$aic, x$bic
  ))
  if (x$n_dropped > 0L) {
    cat(sprintf("  (%d row(s) excluded for missing values)\n", x$n_dropped))
  }

  flags <- character(0L)
  if (!x$convergence$converged) flags <- c(flags, "convergence warnings")
  if (x$convergence$singular)   flags <- c(flags, "singular fit")
  if (x$overdispersion > 2)     flags <- c(flags, sprintf("overdispersion phi=%.2f", x$overdispersion))
  if (length(flags)) cat(sprintf("  Warning: %s\n", paste(flags, collapse = "; ")))

  if (length(x$factor_refs)) {
    refs <- paste(sprintf("%s='%s'", names(x$factor_refs), unlist(x$factor_refs)),
                  collapse = ", ")
    cat(sprintf("  Reference levels: %s\n", refs))
  }

  cat("\nFixed effects (IRR with Wald CI):\n")
  tbl <- x$irr_table[, c("term", "irr", "ci_lower", "ci_upper", "p_value_fmt")]
  tbl$irr      <- round(tbl$irr,      digits)
  tbl$ci_lower <- round(tbl$ci_lower, digits)
  tbl$ci_upper <- round(tbl$ci_upper, digits)
  print(tbl, n = Inf)

  re <- x$random_effects[x$random_effects$grp != "Residual", , drop = FALSE]
  if (nrow(re)) {
    cat(sprintf("\nRandom intercept (%s):  variance = %.4f  SD = %.4f\n",
                re$grp[[1L]], re$vcov[[1L]], re$sdcor[[1L]]))
  }

  invisible(x)
}
