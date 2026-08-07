#' Fit a Negative Binomial GLMM for overdispersed wait-time analysis
#'
#' Runs a multilevel negative binomial regression (`glmmTMB::glmmTMB`) for
#' mystery caller studies where the Poisson model shows overdispersion
#' (`mysterycall_poisson_model()` reports phi > 2). The physician identifier
#' is modelled as a random intercept. Fixed-effect results are returned as
#' incidence rate ratios (IRR) with Wald confidence intervals.
#'
#' Use this function when `mysterycall_poisson_model()` returns
#' `overdispersion` substantially greater than 2: the negative binomial adds
#' a per-observation variance term (theta) that absorbs the excess variance
#' and yields correctly-sized standard errors.
#'
#' @name mysterycall_nb_model
NULL

#' Fit a Negative Binomial GLMM and return IRR table
#'
#' @param data A data frame containing all model columns. Rows with `NA` in
#'   any model column are dropped before fitting.
#' @param outcome Character scalar naming the count-outcome column (e.g.
#'   `"business_days_until_appointment"`). Must be non-negative integer-valued.
#' @param predictors Character vector of fixed-effect predictor column names.
#'   Factor and character columns are used as-is; the reference level is the
#'   first level alphabetically (or the first `levels()` for factors).
#' @param random_intercept Character scalar naming the grouping column for
#'   the random intercept (e.g. `"npi"` for physician). A `(1 | column)`
#'   term is added to the formula automatically.
#' @param conf_level Confidence level for Wald CIs. Default `0.95`.
#' @param offset_col Optional character scalar naming a numeric column to use
#'   as a log-offset. When supplied, `offset(log(offset_col))` is appended to
#'   the fixed-effects formula.
#' @param ... Additional arguments forwarded to [glmmTMB::glmmTMB()].
#'
#' @return A list of class `mysterycall_nb_model` containing:
#' \describe{
#'   \item{`model`}{`glmmTMB`. The fitted model object.}
#'   \item{`irr_table`}{`tibble`. One row per fixed-effect term: `term`,
#'     `estimate` (log scale), `se`, `z_value`, `p_value`, `p_value_fmt`,
#'     `irr`, `ci_lower`, `ci_upper`.}
#'   \item{`theta`}{`numeric`. Negative binomial dispersion parameter
#'     (shape, `theta > 0`). Higher values indicate less overdispersion.
#'     Variance = mean + mean^2 / theta.}
#'   \item{`random_effects`}{`data.frame` from [lme4::VarCorr()].}
#'   \item{`factor_refs`}{`list`. Reference levels for character/factor
#'     predictors.}
#'   \item{`formula`}{`formula`. The formula passed to glmmTMB.}
#'   \item{`n`}{`integer`. Complete-case rows used.}
#'   \item{`n_dropped`}{`integer`. Rows excluded for missing values.}
#'   \item{`n_clusters`}{`integer`. Unique values of `random_intercept`.}
#'   \item{`overdispersion`}{`numeric`. Pearson chi-square / residual df after
#'     NB fit. Values near 1 indicate adequate fit. Values > 2 suggest the NB
#'     model still underfits; consider zero-inflated NB.}
#'   \item{`convergence`}{`list`. `converged` (logical), `messages` (character
#'     vector).}
#'   \item{`aic`}{`numeric`. AIC.}
#'   \item{`bic`}{`numeric`. BIC.}
#' }
#'
#' @section When to use negative binomial vs Poisson:
#' Run `mysterycall_poisson_model()` first. If `result$overdispersion > 2`,
#' switch to `mysterycall_nb_model()`. The negative binomial model will give
#' wider (more honest) confidence intervals and correct p-values; Poisson
#' standard errors are deflated under overdispersion, producing spuriously
#' small p-values.
#'
#' @section Interpreting theta:
#' `theta` (the shape parameter) controls how quickly variance grows with
#' the mean. As theta -> Inf, the NB distribution approaches Poisson. Values
#' of theta < 5 indicate substantial overdispersion.
#'
#' @importFrom stats as.formula complete.cases qnorm AIC BIC
#' @importFrom tibble tibble
#' @family outcomes
#' @seealso [mysterycall_poisson_model()] for the Poisson equivalent;
#'   [mysterycall_wait_time_summary()] for descriptive summaries.
#' @export
#'
#' @examplesIf requireNamespace("glmmTMB", quietly = TRUE)
#' set.seed(1978)
#' df <- data.frame(
#'   wait_days = rnbinom(40, mu = 18, size = 2),
#'   insurance = rep(c("Medicaid", "BCBS"), each = 20),
#'   gender    = sample(c("Male", "Female"), 40, replace = TRUE),
#'   physician = rep(paste0("Dr_", 1:8), each = 5),
#'   stringsAsFactors = FALSE
#' )
#' result <- mysterycall_nb_model(
#'   df,
#'   outcome          = "wait_days",
#'   predictors       = c("insurance", "gender"),
#'   random_intercept = "physician"
#' )
#' result$irr_table
mysterycall_nb_model <- function(data,
                                 outcome,
                                 predictors,
                                 random_intercept,
                                 conf_level = 0.95,
                                 offset_col = NULL,
                                 ...) {

  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    stop(
      "Package 'glmmTMB' is required. Install with: install.packages('glmmTMB')",
      call. = FALSE
    )
  }

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
    stop(sprintf("`%s` contains negative values; negative binomial requires counts >= 0.", outcome),
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

  # Decompose any interaction/formula terms to actual column names for complete-case filtering
  decomposed_predictors <- unique(unlist(lapply(predictors, function(term) {
    if (grepl("[:\\*\\+\\|\\(\\)]", term)) {
      tryCatch(all.vars(stats::as.formula(paste("~", term))), error = function(e) term)
    } else {
      term
    }
  })))
  model_cols <- unique(c(outcome, decomposed_predictors, random_intercept, offset_col))
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

  factor_refs <- Filter(Negate(is.null), lapply(
    setNames(predictors, predictors),
    function(pred) {
      x <- data_cc[[pred]]
      if (is.factor(x))    return(levels(x)[[1L]])
      if (is.character(x)) return(sort(unique(x[!is.na(x)]), method = "radix")[[1L]])
      NULL
    }
  ))

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

  message(sprintf("Fitting Negative Binomial GLMM: %s", deparse(model_formula)))

  warnings_captured <- character(0L)

  model <- tryCatch(
    withCallingHandlers(
      glmmTMB::glmmTMB(
        formula = model_formula,
        data    = data_cc,
        family  = glmmTMB::nbinom2(link = "log"),
        ...
      ),
      warning = function(w) {
        warnings_captured <<- c(warnings_captured, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      stop(sprintf("glmmTMB() failed to fit: %s", e$message), call. = FALSE)
    }
  )

  conv_code <- model$fit$convergence
  pd_hess   <- isTRUE(model$sdr$pdHess)
  converged <- (conv_code == 0L) && pd_hess && !length(warnings_captured)

  if (!converged) {
    msg_parts <- character(0L)
    if (conv_code != 0L)  msg_parts <- c(msg_parts, sprintf("optimizer code %d", conv_code))
    if (!pd_hess)         msg_parts <- c(msg_parts, "non-positive-definite Hessian")
    if (length(warnings_captured)) msg_parts <- c(msg_parts, warnings_captured)
    warning(sprintf(
      "Convergence issues detected: %s\nConsider simplifying predictors or increasing iterations.",
      paste(msg_parts, collapse = "; ")
    ), call. = FALSE)
  }

  fe <- coef(summary(model))$cond

  z_crit    <- stats::qnorm(1 - (1 - conf_level) / 2)
  estimates <- fe[, "Estimate"]
  ses       <- fe[, "Std. Error"]

  irr_table <- tibble::tibble(
    term        = rownames(fe),
    estimate    = estimates,
    se          = ses,
    z_value     = fe[, "z value"],
    p_value     = fe[, "Pr(>|z|)"],
    p_value_fmt = .fmt_nb_pval(fe[, "Pr(>|z|)"]),
    irr         = exp(estimates),
    ci_lower    = exp(estimates - z_crit * ses),
    ci_upper    = exp(estimates + z_crit * ses)
  )

  theta <- tryCatch(sigma(model), error = function(e) NA_real_)

  # -- Overdispersion check for NB ---------------------------------------------
  y_obs       <- data_cc[[outcome]]
  y_hat       <- tryCatch(fitted(model), error = function(e) rep(NA_real_, length(y_obs)))
  df_resid_nb <- max(nrow(data_cc) - nrow(irr_table), 1L)
  pearson_nb  <- (y_obs - y_hat) / sqrt(y_hat + y_hat^2 / max(theta, 0.001))
  overdispersion <- sum(pearson_nb^2, na.rm = TRUE) / df_resid_nb

  if (!is.na(theta) && theta < 1) {
    warning(sprintf(
      "Extreme overdispersion: theta = %.2f (< 1). NB may still underfit. Consider a zero-inflated negative binomial model.",
      theta
    ), call. = FALSE)
  } else if (overdispersion > 2) {
    warning(sprintf(
      "Residual overdispersion phi = %.2f after NB fit. The negative binomial may not fully account for the excess variance. Check for zero-inflation or outliers.",
      overdispersion
    ), call. = FALSE)
  } else if (!is.na(theta) && theta > 100) {
    message(sprintf(
      "theta = %.1f suggests minimal overdispersion; a Poisson model may be adequate (compare AIC).",
      theta
    ))
  }

  re_df <- tryCatch(
    as.data.frame(lme4::VarCorr(model)),
    error = function(e) data.frame()
  )

  n_clusters <- tryCatch(
    length(unique(data_cc[[random_intercept]])),
    error = function(e) NA_integer_
  )

  message(sprintf(
    "Model fitted: n=%d, physicians=%d, AIC=%.1f, theta=%.2f",
    nrow(data_cc), n_clusters, AIC(model), theta
  ))

  structure(
    list(
      model          = model,
      irr_table      = irr_table,
      theta          = theta,
      overdispersion = overdispersion,
      random_effects = re_df,
      factor_refs    = factor_refs,
      formula        = model_formula,
      n              = nrow(data_cc),
      n_dropped      = n_dropped,
      n_clusters     = n_clusters,
      convergence    = list(
        converged = converged,
        messages  = c(
          if (conv_code != 0L) sprintf("optimizer code %d", conv_code),
          if (!pd_hess) "non-positive-definite Hessian",
          warnings_captured
        )
      ),
      aic = AIC(model),
      bic = BIC(model)
    ),
    class = "mysterycall_nb_model"
  )
}

.fmt_nb_pval <- function(p) {
  .mc_format_p(p)
}

#' Print method for mysterycall_nb_model objects
#'
#' @param x A `mysterycall_nb_model` object.
#' @param digits Integer. Decimal places for IRR display. Default `3`.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_nb_model <- function(x, digits = 3, ...) {
  cat(sprintf(
    "Negative Binomial GLMM  n = %d  physicians = %d  AIC = %.1f  BIC = %.1f\n",
    x$n, x$n_clusters, x$aic, x$bic
  ))
  cat(sprintf("  Dispersion (theta) = %.3f  [higher = less overdispersion]\n", x$theta))
  if (!is.null(x$overdispersion) && x$overdispersion > 2) {
    cat(sprintf("  Residual overdispersion phi = %.2f (NB may underfit)\n", x$overdispersion))
  }

  if (x$n_dropped > 0L) {
    cat(sprintf("  (%d row(s) excluded for missing values)\n", x$n_dropped))
  }

  flags <- character(0L)
  if (!x$convergence$converged) flags <- c(flags, "convergence issues")
  if (!is.null(x$overdispersion) && x$overdispersion > 2) flags <- c(flags, sprintf("residual phi=%.2f", x$overdispersion))
  if (length(flags)) cat(sprintf("  Warning: %s\n", paste(flags, collapse = "; ")))

  if (!x$convergence$converged) {
    msgs <- x$convergence$messages
    cat(sprintf("  Convergence detail - %s\n",
                paste(msgs[nzchar(msgs)], collapse = "; ")))
  }

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

  re <- x$random_effects[
    !is.na(x$random_effects$grp) & x$random_effects$grp != "Residual", ,
    drop = FALSE
  ]
  if (nrow(re)) {
    cat(sprintf("\nRandom intercept (%s):  variance = %.4f  SD = %.4f\n",
                re$grp[[1L]], re$vcov[[1L]], re$sdcor[[1L]]))
  }

  invisible(x)
}
