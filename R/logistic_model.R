#' Fit a Logistic GLMER for mystery caller appointment-offered outcome
#'
#' @name mysterycall_logistic_model
NULL

#' Format logistic model p-value for display
#' @keywords internal
.fmt_logistic_pval <- function(p) {
  ifelse(is.na(p), NA_character_,
         ifelse(p < 0.001, "< 0.001", sprintf("%.3f", p)))
}

#' Fit a Logistic GLMER and return odds ratio table
#'
#' Runs a multilevel logistic regression (`lme4::glmer`) appropriate for
#' mystery caller studies where the binary outcome is whether an appointment
#' was offered at all. The physician identifier is modelled as a random
#' intercept. Fixed-effect results are returned as odds ratios (OR) with
#' Wald confidence intervals.
#'
#' Use this alongside [mysterycall_poisson_model()] or
#' [mysterycall_nb_model()]: the logistic model answers "was an appointment
#' offered?" while the count model answers "how many days was the wait?"
#' Together they address both stages of the access disparity question.
#'
#' @param data A data frame containing all model columns. Rows with `NA` in
#'   any model column are dropped before fitting; the count is reported.
#' @param outcome Character scalar naming the binary outcome column. Must
#'   contain only values in \{0, 1\} (integer or numeric) or be logical
#'   (`TRUE`/`FALSE`). A value of 1 / `TRUE` indicates an appointment was
#'   offered.
#' @param predictors Character vector of fixed-effect predictor column names.
#'   Factor and character columns are used as-is; the reference level is the
#'   first level alphabetically (or the first `levels()` for factors).
#' @param random_intercept Character scalar naming the grouping column for
#'   the random intercept (e.g. `"physician"`). A `(1 | column)` term is
#'   added to the formula automatically.
#' @param conf_level Confidence level for Wald CIs. Default `0.95`.
#' @param nAGQ Integer passed to [lme4::glmer()]. `0` (default) uses the
#'   fastest approximation; `1` uses the Laplace approximation.
#' @param ... Additional arguments forwarded to [lme4::glmer()].
#'
#' @return A list of class `mysterycall_logistic_model` containing:
#' \describe{
#'   \item{`model`}{`glmerMod`. The fitted multilevel logistic model.}
#'   \item{`or_table`}{`tibble`. One row per fixed-effect term with columns:
#'     `term`, `estimate` (log-odds), `se`, `z_value`, `p_value`,
#'     `p_value_fmt`, `or` (odds ratio), `ci_lower`, `ci_upper`.}
#'   \item{`random_effects`}{`data.frame` from [lme4::VarCorr()].}
#'   \item{`factor_refs`}{`list`. Reference levels for character/factor
#'     predictors.}
#'   \item{`formula`}{`formula`. The formula passed to [lme4::glmer()].}
#'   \item{`n`}{`integer`. Complete-case rows used.}
#'   \item{`n_dropped`}{`integer`. Rows excluded for missing values.}
#'   \item{`n_clusters`}{`integer`. Unique values of `random_intercept`.}
#'   \item{`convergence`}{`list`. `converged` (logical), `singular`
#'     (logical), `messages` (character vector).}
#'   \item{`aic`}{`numeric`. AIC.}
#'   \item{`bic`}{`numeric`. BIC.}
#' }
#'
#' @section Interpreting ORs:
#' An OR of 0.62 for `insuranceMedicaid` means the odds of an appointment
#' being offered were 38% lower for Medicaid calls than for the reference
#' insurance group, after accounting for physician-level clustering.
#'
#' @importFrom stats binomial as.formula complete.cases qnorm AIC BIC
#' @importFrom tibble tibble
#' @family outcomes
#' @seealso [mysterycall_poisson_model()], [mysterycall_nb_model()],
#'   [mysterycall_acceptance_rate()] for descriptive acceptance rates.
#' @export
#'
#' @examplesIf requireNamespace("lme4", quietly = TRUE)
#' set.seed(42)
#' df <- data.frame(
#'   offered   = rbinom(80, 1L, 0.7),
#'   insurance = rep(c("Medicaid", "BCBS"), 40),
#'   physician = rep(paste0("Dr", 1:20), each = 4L),
#'   stringsAsFactors = FALSE
#' )
#' fit <- mysterycall_logistic_model(df, "offered", "insurance", "physician")
#' print(fit)
mysterycall_logistic_model <- function(data,
                                        outcome,
                                        predictors,
                                        random_intercept,
                                        conf_level = 0.95,
                                        nAGQ       = 0L,
                                        ...) {

  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("Package 'lme4' is required. Install with: install.packages('lme4')",
         call. = FALSE)
  }

  # -- Input validation ---------------------------------------------------------
  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
  validate_required_columns(data, outcome,          name = "data")
  validate_required_columns(data, predictors,       name = "data")
  validate_required_columns(data, random_intercept, name = "data")

  if (!is.character(outcome) || length(outcome) != 1L)
    stop("`outcome` must be a single column name.", call. = FALSE)

  y      <- data[[outcome]]
  y_vals <- unique(stats::na.omit(as.numeric(y)))
  if (!is.logical(y) && !all(y_vals %in% c(0, 1))) {
    stop(sprintf("`%s` must be binary (values 0/1 or logical).", outcome),
         call. = FALSE)
  }

  if (!is.character(random_intercept) || length(random_intercept) != 1L)
    stop("`random_intercept` must be a single column name.", call. = FALSE)
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1)
    stop("`conf_level` must be a single number strictly between 0 and 1.",
         call. = FALSE)

  # -- Complete-case filtering --------------------------------------------------
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
    stop("No complete cases remain after removing rows with missing values.",
         call. = FALSE)

  # -- Quasi-complete separation check ------------------------------------------
  y_cc   <- as.numeric(data_cc[[outcome]])
  n_zero <- sum(y_cc == 0L, na.rm = TRUE)
  n_one  <- sum(y_cc == 1L, na.rm = TRUE)
  if (min(n_zero, n_one) < 5L) {
    warning(sprintf(
      "Outcome has very few %s events (%d). Estimates may be unreliable (quasi-complete separation).",
      if (n_zero < n_one) "zero" else "one",
      min(n_zero, n_one)
    ), call. = FALSE)
  }

  # -- Events-per-variable check ------------------------------------------------
  est_df <- 1L
  for (.pred in predictors) {
    x <- data_cc[[.pred]]
    est_df <- est_df + if (is.factor(x) || is.character(x)) {
      length(unique(x[!is.na(x)])) - 1L
    } else {
      1L
    }
  }
  n_events <- min(n_zero, n_one)
  epv      <- n_events / est_df
  if (epv < 5) {
    warning(sprintf(
      "Very low events-per-variable: %d events / %d parameters = %.1f. Estimates will be unreliable.",
      n_events, est_df, epv
    ), call. = FALSE)
  } else if (epv < 10) {
    warning(sprintf(
      "Low events-per-variable: %d events / %d parameters = %.1f. Convention recommends >= 10.",
      n_events, est_df, epv
    ), call. = FALSE)
  }

  # -- Reference levels ---------------------------------------------------------
  factor_refs <- Filter(Negate(is.null), lapply(
    setNames(predictors, predictors),
    function(pred) {
      x <- data_cc[[pred]]
      if (is.factor(x))    return(levels(x)[[1L]])
      if (is.character(x)) return(sort(unique(x[!is.na(x)]))[[1L]])
      NULL
    }
  ))

  # -- Build formula ------------------------------------------------------------
  fixed_part    <- paste(predictors, collapse = " + ")
  random_part   <- sprintf("(1 | %s)", random_intercept)
  formula_str   <- sprintf("%s ~ %s + %s", outcome, fixed_part, random_part)
  model_formula <- stats::as.formula(formula_str)

  message(sprintf("Fitting Logistic GLMER: %s", deparse(model_formula)))

  # -- Fit ----------------------------------------------------------------------
  warnings_captured <- character(0L)

  model <- tryCatch(
    withCallingHandlers(
      lme4::glmer(
        formula = model_formula,
        data    = data_cc,
        family  = stats::binomial(link = "logit"),
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

  # -- Convergence / singularity ------------------------------------------------
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

  # -- OR table -----------------------------------------------------------------
  z_crit <- stats::qnorm(1 - (1 - conf_level) / 2)
  fe     <- as.data.frame(coef(summary(model)))

  or_table <- tibble::tibble(
    term        = rownames(fe),
    estimate    = fe$Estimate,
    se          = fe[["Std. Error"]],
    z_value     = fe[["z value"]],
    p_value     = fe[["Pr(>|z|)"]],
    p_value_fmt = .fmt_logistic_pval(fe[["Pr(>|z|)"]]),
    or          = exp(fe$Estimate),
    ci_lower    = exp(fe$Estimate - z_crit * fe[["Std. Error"]]),
    ci_upper    = exp(fe$Estimate + z_crit * fe[["Std. Error"]])
  )

  # -- Random effects -----------------------------------------------------------
  re_df      <- as.data.frame(lme4::VarCorr(model))
  n_clusters <- lme4::ngrps(model)[[random_intercept]]

  message(sprintf(
    "Model fitted: n=%d, physicians=%d, AIC=%.1f, events=%d/%d (%.1f%%)",
    nrow(data_cc), n_clusters, AIC(model),
    n_one, nrow(data_cc), n_one / nrow(data_cc) * 100
  ))

  structure(
    list(
      model          = model,
      or_table       = or_table,
      random_effects = re_df,
      factor_refs    = factor_refs,
      formula        = model_formula,
      n              = nrow(data_cc),
      n_dropped      = n_dropped,
      n_clusters     = n_clusters,
      convergence    = list(
        converged = converged,
        singular  = is_singular,
        messages  = c(conv_msgs, warnings_captured)
      ),
      aic = AIC(model),
      bic = BIC(model)
    ),
    class = "mysterycall_logistic_model"
  )
}


#' Print method for mysterycall_logistic_model objects
#'
#' Displays a formatted console summary: sample size, physician count,
#' AIC/BIC, convergence flags, reference levels, and a fixed-effects table
#' with odds ratios (OR) and Wald 95% CIs.
#'
#' @param x A `mysterycall_logistic_model` object.
#' @param digits Integer. Decimal places for OR display. Default `3`.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_logistic_model <- function(x, digits = 3, ...) {
  cat(sprintf(
    "Logistic GLMER  n = %d  physicians = %d  AIC = %.1f  BIC = %.1f\n",
    x$n, x$n_clusters, x$aic, x$bic
  ))
  if (x$n_dropped > 0L)
    cat(sprintf("  (%d row(s) excluded for missing values)\n", x$n_dropped))

  flags <- character(0L)
  if (!x$convergence$converged) flags <- c(flags, "convergence warnings")
  if (x$convergence$singular)   flags <- c(flags, "singular fit")
  if (length(flags))
    cat(sprintf("  Warning: %s\n", paste(flags, collapse = "; ")))

  if (length(x$factor_refs)) {
    refs <- paste(sprintf("%s='%s'", names(x$factor_refs), unlist(x$factor_refs)),
                  collapse = ", ")
    cat(sprintf("  Reference levels: %s\n", refs))
  }

  cat("\nFixed effects (OR with Wald CI):\n")
  tbl <- as.data.frame(
    x$or_table[, c("term", "or", "ci_lower", "ci_upper", "p_value_fmt")]
  )
  tbl$or       <- round(tbl$or,       digits)
  tbl$ci_lower <- round(tbl$ci_lower, digits)
  tbl$ci_upper <- round(tbl$ci_upper, digits)
  names(tbl)[names(tbl) == "p_value_fmt"] <- "p-value"
  print(tbl, row.names = FALSE)

  re <- x$random_effects[x$random_effects$grp != "Residual", , drop = FALSE]
  if (nrow(re)) {
    cat(sprintf("\nRandom intercept (%s):  variance = %.4f  SD = %.4f\n",
                re$grp[[1L]], re$vcov[[1L]], re$sdcor[[1L]]))
  }

  invisible(x)
}


#' Tidy method for mysterycall_logistic_model objects
#'
#' Returns a broom-compatible tibble of fixed-effect odds ratios (OR) with
#' Wald 95% CIs and p-values. Column names follow broom conventions so the
#' result integrates with tidy workflows and `broom::bind_rows()`.
#'
#' @param x A `mysterycall_logistic_model` object returned by
#'   [mysterycall_logistic_model()].
#' @param ... Ignored; present for S3 consistency.
#'
#' @return A [tibble::tibble()] with one row per fixed-effect term and columns:
#' \describe{
#'   \item{`term`}{Coefficient name.}
#'   \item{`estimate`}{OR (odds ratio) on the exponentiated scale.}
#'   \item{`std.error`}{Standard error of the *log*-OR.}
#'   \item{`statistic`}{z-statistic.}
#'   \item{`p.value`}{Two-tailed Wald p-value.}
#'   \item{`conf.low`}{Lower bound of 95% Wald CI for OR.}
#'   \item{`conf.high`}{Upper bound of 95% Wald CI for OR.}
#' }
#'
#' @family outcomes
#' @method tidy mysterycall_logistic_model
#' @export
#' @examples
#' \donttest{
#' fake_fit <- structure(
#'   list(or_table = data.frame(
#'     term = "scenarioB", or = 2.5, se = 0.3,
#'     z_value = 3.1, p_value = 0.002,
#'     ci_lower = 1.8, ci_upper = 3.5,
#'     stringsAsFactors = FALSE
#'   )),
#'   class = "mysterycall_logistic_model"
#' )
#' tidy(fake_fit)
#' }
tidy.mysterycall_logistic_model <- function(x, ...) {
  tbl <- x$or_table
  tibble::tibble(
    term      = tbl$term,
    estimate  = tbl$or,
    std.error = tbl$se,
    statistic = tbl$z_value,
    p.value   = tbl$p_value,
    conf.low  = tbl$ci_lower,
    conf.high = tbl$ci_upper
  )
}
