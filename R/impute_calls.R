#' Multiple imputation for missing mystery-caller outcomes
#'
#' @name impute_calls
NULL

#' Format a p-value for imputed results display
#' @keywords internal
.fmt_impute_pval <- function(p) {
  ifelse(is.na(p), NA_character_,
         ifelse(p < 0.001, "< 0.001", sprintf("%.3f", p)))
}

#' Multiple imputation by chained equations for missing call outcomes
#'
#' Performs multiple imputation using [mice::mice()] to handle missing values
#' in the binary outcome column, fits a multilevel logistic GLMM
#' ([mysterycall_logistic_model()]) to each imputed dataset, and pools
#' fixed-effect estimates across imputations using Rubin's rules. Because
#' `mice::pool()` does not support `glmerMod` objects, pooling is implemented
#' manually.
#'
#' **Rubin's rules (1987)**
#' \enumerate{
#'   \item \eqn{\bar{Q} = \frac{1}{m} \sum_{i=1}^{m} \hat{\beta}_i} (pooled estimate)
#'   \item \eqn{\bar{U} = \frac{1}{m} \sum_{i=1}^{m} \hat{\text{SE}}_i^2} (within-imputation variance)
#'   \item \eqn{B = \frac{1}{m-1} \sum_{i=1}^{m} (\hat{\beta}_i - \bar{Q})^2} (between-imputation variance)
#'   \item \eqn{T = \bar{U} + \left(1 + \frac{1}{m}\right) B} (total variance)
#'   \item Degrees of freedom: \eqn{\nu = (m-1) \left(1 + \frac{\bar{U}}{(1+1/m) B}\right)^2}
#'   \item Fraction of missing information: \eqn{\text{FMI} = \frac{B + B/m}{T}}
#' }
#'
#' @param data A data frame containing at least `outcome_col`, all columns
#'   named in `predictors`, and `random_intercept`. Rows may have missing
#'   values in any column; MICE will impute them.
#' @param outcome_col Character scalar. Name of the binary 0/1 outcome column.
#'   Values must be in \{0, 1\} (integer or numeric) or logical.
#' @param predictors Character vector. Fixed-effect predictor column names
#'   passed to [mysterycall_logistic_model()].
#' @param random_intercept Character scalar. Grouping column for the physician
#'   random intercept (e.g. `"physician"`). Passed directly to
#'   [mysterycall_logistic_model()].
#' @param m Integer. Number of imputed datasets to generate. Default `20L`.
#'   Values below `5` are not recommended; values above `50` rarely add
#'   precision.
#' @param maxit Integer. Number of MICE iterations per imputation. Default `5L`.
#' @param seed Integer. Random seed for [mice::mice()] reproducibility.
#'   Default `42L`.
#' @param conf_level Numeric strictly between 0 and 1. Confidence level for
#'   pooled Wald intervals on the odds-ratio scale. Default `0.95`.
#' @param verbose Logical. If `TRUE`, MICE progress is printed to the console
#'   (`printFlag = TRUE`). Default `FALSE`.
#'
#' @return A list of class `mysterycall_impute_calls` containing:
#' \describe{
#'   \item{`pooled_table`}{[tibble::tibble()] with one row per fixed-effect
#'     term and columns: `term`, `estimate_logodds` (pooled log-OR),
#'     `pooled_se`, `or` (pooled odds ratio), `ci_lower`, `ci_upper`,
#'     `p_value`, `p_fmt`, `fmi` (fraction of missing information).}
#'   \item{`m`}{Integer. Number of imputations used.}
#'   \item{`n_missing`}{Integer. Count of `NA` values in `outcome_col`.}
#'   \item{`pct_missing`}{Numeric. Percentage of rows with missing outcome.}
#'   \item{`individual_fits`}{List of `m` `mysterycall_logistic_model`
#'     objects, one per imputed dataset.}
#'   \item{`sentence`}{Character. Publication-ready summary sentence, e.g.
#'     `"Results were robust to multiple imputation (m=20): OR 0.61, 95% CI
#'     0.40-0.93, p=0.021, FMI=0.08."` Uses the first non-intercept term.}
#' }
#'
#' @section Missingness warning:
#' If fewer than 1% of `outcome_col` values are missing, a [base::warning()]
#' is emitted noting that imputation may be unnecessary. The function still
#' proceeds so you can confirm robustness.
#'
#' @section mice in Suggests:
#' `mice` is listed under `Suggests`, not `Imports`. If it is not installed,
#' the function stops with an informative message. Install with
#' `install.packages("mice")`.
#'
#' @importFrom stats pt qt complete.cases
#' @importFrom tibble tibble
#' @family outcomes
#' @seealso [mysterycall_logistic_model()] which is called on each imputed
#'   dataset; `mice::mice()` for imputation engine documentation.
#' @export
#'
#' @examples
#' \dontrun{
#' library(mice)
#' set.seed(1)
#' n_phys <- 20L
#' n_calls <- 4L
#' n <- n_phys * n_calls
#'
#' df <- data.frame(
#'   offered   = rbinom(n, 1L, 0.70),
#'   insurance = rep(c("Medicaid", "BCBS"), n / 2L),
#'   physician = rep(paste0("Dr", seq_len(n_phys)), each = n_calls),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Introduce ~15% missingness in the outcome
#' miss_idx <- sample(seq_len(n), size = round(n * 0.15))
#' df$offered[miss_idx] <- NA_integer_
#'
#' result <- mysterycall_impute_calls(
#'   data             = df,
#'   outcome_col      = "offered",
#'   predictors       = "insurance",
#'   random_intercept = "physician",
#'   m                = 10L,
#'   seed             = 2024L
#' )
#'
#' print(result)
#' result$pooled_table
#' result$sentence
#' }
mysterycall_impute_calls <- function(data,
                                     outcome_col,
                                     predictors,
                                     random_intercept,
                                     m          = 20L,
                                     maxit      = 5L,
                                     seed       = 42L,
                                     conf_level = 0.95,
                                     verbose    = FALSE) {

  # -- Dependency checks -------------------------------------------------------
  if (!requireNamespace("mice", quietly = TRUE)) {
    stop(
      "Package 'mice' is required for multiple imputation. ",
      "Install with: install.packages('mice')",
      call. = FALSE
    )
  }
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop(
      "Package 'lme4' is required. Install with: install.packages('lme4')",
      call. = FALSE
    )
  }

  # -- Input validation --------------------------------------------------------
  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)

  if (!is.character(outcome_col) || length(outcome_col) != 1L)
    stop("`outcome_col` must be a single character column name.", call. = FALSE)
  if (!outcome_col %in% names(data))
    stop(sprintf("`outcome_col` '%s' not found in `data`.", outcome_col),
         call. = FALSE)

  if (!is.character(predictors) || !length(predictors))
    stop("`predictors` must be a non-empty character vector.", call. = FALSE)
  validate_required_columns(data, predictors, name = "data")

  if (!is.character(random_intercept) || length(random_intercept) != 1L)
    stop("`random_intercept` must be a single character column name.",
         call. = FALSE)
  validate_required_columns(data, random_intercept, name = "data")

  m <- as.integer(m)
  if (is.na(m) || m < 2L)
    stop("`m` must be an integer >= 2.", call. = FALSE)

  maxit <- as.integer(maxit)
  if (is.na(maxit) || maxit < 1L)
    stop("`maxit` must be a positive integer.", call. = FALSE)

  seed <- as.integer(seed)
  if (is.na(seed))
    stop("`seed` must be a finite integer.", call. = FALSE)

  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1)
    stop("`conf_level` must be a single number strictly between 0 and 1.",
         call. = FALSE)

  if (!is.logical(verbose) || length(verbose) != 1L || is.na(verbose))
    stop("`verbose` must be TRUE or FALSE.", call. = FALSE)

  # -- Validate binary outcome -------------------------------------------------
  y_obs <- data[[outcome_col]]
  y_vals <- unique(stats::na.omit(as.numeric(y_obs)))
  if (!is.logical(y_obs) && !all(y_vals %in% c(0, 1))) {
    stop(
      sprintf("`%s` must be a binary column (values 0/1 or logical).",
              outcome_col),
      call. = FALSE
    )
  }

  # -- Missingness summary -----------------------------------------------------
  n_total   <- nrow(data)
  n_missing <- sum(is.na(y_obs))
  pct_missing <- n_missing / n_total * 100

  if (n_missing == 0L) {
    warning(
      sprintf(
        "No missing values found in '%s'. Multiple imputation has nothing to impute.",
        outcome_col
      ),
      call. = FALSE
    )
  } else if (pct_missing < 1) {
    warning(
      sprintf(
        "Only %.2f%% of '%s' values are missing (%d/%d rows). ",
        pct_missing, outcome_col, n_missing, n_total,
        "Imputation may be unnecessary; results should be nearly identical to complete-case analysis."
      ),
      call. = FALSE
    )
  }

  message(sprintf(
    "Multiple imputation: m=%d, maxit=%d, seed=%d | missing outcome: %d/%d (%.1f%%)",
    m, maxit, seed, n_missing, n_total, pct_missing
  ))

  # -- Restrict to model columns for imputation --------------------------------
  model_cols <- unique(c(outcome_col, predictors, random_intercept))
  data_mice  <- data[, model_cols, drop = FALSE]

  # Ensure outcome column is numeric for MICE (binary PMM / logreg)
  data_mice[[outcome_col]] <- as.numeric(data_mice[[outcome_col]])

  # -- Run MICE ----------------------------------------------------------------
  imp <- tryCatch(
    mice::mice(
      data      = data_mice,
      m         = m,
      maxit     = maxit,
      seed      = seed,
      printFlag = verbose
    ),
    error = function(e) {
      stop(sprintf("mice::mice() failed: %s", e$message), call. = FALSE)
    }
  )

  # -- Fit logistic GLMM on each imputed dataset ------------------------------
  individual_fits <- vector("list", m)

  for (i in seq_len(m)) {
    if (verbose) message(sprintf("  Fitting model on imputed dataset %d / %d ...", i, m))

    data_i <- mice::complete(imp, i)

    individual_fits[[i]] <- tryCatch(
      mysterycall_logistic_model(
        data             = data_i,
        outcome          = outcome_col,
        predictors       = predictors,
        random_intercept = random_intercept,
        conf_level       = conf_level
      ),
      error = function(e) {
        stop(sprintf("Model failed on imputed dataset %d: %s", i, e$message),
             call. = FALSE)
      }
    )
  }

  # -- Extract terms (use first fit as template) --------------------------------
  terms_vec <- individual_fits[[1L]]$or_table$term

  # -- Pool via Rubin's rules --------------------------------------------------
  pooled_rows <- lapply(terms_vec, function(trm) {

    # Collect estimates (log-OR) and SEs across imputations
    estimates <- vapply(individual_fits, function(fit) {
      idx <- match(trm, fit$or_table$term)
      if (is.na(idx)) NA_real_ else fit$or_table$estimate[[idx]]
    }, numeric(1L))

    ses <- vapply(individual_fits, function(fit) {
      idx <- match(trm, fit$or_table$term)
      if (is.na(idx)) NA_real_ else fit$or_table$se[[idx]]
    }, numeric(1L))

    # Drop any imputations where the term was missing / failed
    ok      <- !is.na(estimates) & !is.na(ses)
    m_used  <- sum(ok)

    if (m_used < 2L) {
      warning(sprintf("Term '%s': fewer than 2 valid estimates; pooling skipped.", trm),
              call. = FALSE)
      return(tibble::tibble(
        term            = trm,
        estimate_logodds = NA_real_,
        pooled_se       = NA_real_,
        or              = NA_real_,
        ci_lower        = NA_real_,
        ci_upper        = NA_real_,
        p_value         = NA_real_,
        p_fmt           = NA_character_,
        fmi             = NA_real_
      ))
    }

    Q  <- estimates[ok]
    SE <- ses[ok]

    Q_bar <- mean(Q)
    U_bar <- mean(SE^2)
    B     <- stats::var(Q)                        # = sum((Q - Q_bar)^2)/(m_used - 1)
    T_var <- U_bar + (1 + 1 / m_used) * B

    pooled_se <- sqrt(T_var)

    # Degrees of freedom (Barnard & Rubin 1999 approximation)
    # Guard against B = 0 (no between-imputation variance)
    if (B < .Machine$double.eps) {
      df_rubin <- Inf
    } else {
      df_rubin <- (m_used - 1L) * (1 + U_bar / ((1 + 1 / m_used) * B))^2
    }

    t_stat  <- Q_bar / pooled_se
    p_val   <- 2 * stats::pt(-abs(t_stat), df = df_rubin)

    z_crit  <- stats::qt(1 - (1 - conf_level) / 2, df = df_rubin)
    ci_lo   <- exp(Q_bar - z_crit * pooled_se)
    ci_hi   <- exp(Q_bar + z_crit * pooled_se)

    # Fraction of missing information
    fmi     <- if (T_var < .Machine$double.eps) NA_real_
               else (B + B / m_used) / T_var

    tibble::tibble(
      term             = trm,
      estimate_logodds = Q_bar,
      pooled_se        = pooled_se,
      or               = exp(Q_bar),
      ci_lower         = ci_lo,
      ci_upper         = ci_hi,
      p_value          = p_val,
      p_fmt            = .fmt_impute_pval(p_val),
      fmi              = fmi
    )
  })

  pooled_table <- do.call(rbind, pooled_rows)

  # -- Build sentence ----------------------------------------------------------
  # Use first non-intercept term for the summary sentence
  non_int <- pooled_table[pooled_table$term != "(Intercept)", , drop = FALSE]
  if (!nrow(non_int)) {
    non_int <- pooled_table[1L, , drop = FALSE]
  }
  ref_row  <- non_int[1L, , drop = FALSE]

  sentence <- sprintf(
    "Results were robust to multiple imputation (m=%d): OR %.2f, 95%% CI %.2f-%.2f, p=%s, FMI=%.2f.",
    m,
    ref_row$or,
    ref_row$ci_lower,
    ref_row$ci_upper,
    if (!is.na(ref_row$p_value) && ref_row$p_value < 0.001) "< 0.001"
    else sprintf("%.3f", ref_row$p_value),
    ref_row$fmi
  )

  message(sentence)

  # -- Return ------------------------------------------------------------------
  structure(
    list(
      pooled_table     = pooled_table,
      m                = m,
      n_missing        = n_missing,
      pct_missing      = pct_missing,
      individual_fits  = individual_fits,
      sentence         = sentence
    ),
    class = "mysterycall_impute_calls"
  )
}


#' Print method for mysterycall_impute_calls objects
#'
#' Displays imputation summary, missingness statistics, and the pooled
#' fixed-effects table with odds ratios (OR), 95% CI, p-values, and
#' fraction of missing information (FMI).
#'
#' @param x A `mysterycall_impute_calls` object.
#' @param digits Integer. Decimal places for OR display. Default `3`.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_impute_calls <- function(x, digits = 3, ...) {
  cat(sprintf(
    "Multiple Imputation (MICE)  m = %d  |  missing outcome: %d (%.1f%%)\n",
    x$m, x$n_missing, x$pct_missing
  ))
  cat("\nPooled fixed effects (Rubin's rules, OR scale):\n")

  tbl <- as.data.frame(x$pooled_table[,
    c("term", "or", "ci_lower", "ci_upper", "p_fmt", "fmi"),
    drop = FALSE
  ])
  tbl$or       <- round(tbl$or,       digits)
  tbl$ci_lower <- round(tbl$ci_lower, digits)
  tbl$ci_upper <- round(tbl$ci_upper, digits)
  tbl$fmi      <- round(tbl$fmi,      3L)
  names(tbl)[names(tbl) == "p_fmt"] <- "p-value"

  print(tbl, row.names = FALSE)

  cat(sprintf("\n%s\n", x$sentence))
  invisible(x)
}
