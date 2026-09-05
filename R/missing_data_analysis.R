#' Missing data analysis for mystery-caller appointment outcomes
#'
#' @name missing_data_analysis
NULL

#' Test whether missing appointment dates are MAR or MNAR
#'
#' Creates a binary missingness indicator for the appointment-date outcome
#' column and tests whether missingness is associated with key predictors
#' (insurance group, physician characteristics, caller identity). Rejection
#' of the null indicates that data are not Missing Completely At Random
#' (MCAR); the pattern is then interpreted as MAR or MNAR depending on
#' whether the predictors are themselves observed.
#'
#' For categorical predictors, a Pearson chi-square test is used (with
#' Fisher's exact test as a fallback when any expected cell count < 5).
#' For numeric predictors, a Wilcoxon rank-sum test is used.
#'
#' @param data A data frame.
#' @param outcome_col Character scalar. Name of the appointment-date (or
#'   numeric outcome) column to test for missingness. Rows where this column
#'   is `NA` are treated as missing.
#' @param group_col Character scalar or `NULL`. Primary grouping variable
#'   (e.g. `"insurance"`). Tested first and included in the summary table.
#' @param covariate_cols Character vector or `NULL`. Additional columns to
#'   test for association with missingness (e.g. physician characteristics,
#'   caller identity).
#' @param alpha Numeric. Significance threshold for interpretation.
#'   Default `0.05`.
#'
#' @return A list of class `mysterycall_missing_data` with elements:
#' \describe{
#'   \item{`summary`}{Data frame: one row per variable tested, columns
#'     `variable`, `n_observed`, `n_missing`, `pct_missing`, `test`,
#'     `statistic`, `df`, `p_value`, `significant`.}
#'   \item{`overall`}{List: `n_total`, `n_missing`, `pct_missing`.}
#'   \item{`interpretation`}{Character scalar. Plain-language MAR/MNAR
#'     interpretation based on significant tests.}
#'   \item{`group_table`}{Data frame: missingness counts broken out by
#'     `group_col` levels, or `NULL` when `group_col` is `NULL`.}
#'   \item{`outcome_col`}{Character. Name of the outcome column tested.}
#' }
#'
#' @family outcomes
#' @seealso [mysterycall_materials_methods()] for the M&M section generator
#'   that calls this function.
#' @export
#'
#' @examples
#' set.seed(9)
#' df <- data.frame(
#'   appt_date = c(rep(as.Date("2024-03-01"), 60), rep(NA, 20)),
#'   insurance = sample(c("BCBS", "Medicaid"), 80, replace = TRUE),
#'   physician = rep(paste0("Dr", 1:20), each = 4),
#'   stringsAsFactors = FALSE
#' )
#' mda <- mysterycall_missing_data_analysis(
#'   df,
#'   outcome_col   = "appt_date",
#'   group_col     = "insurance",
#'   covariate_cols = "physician"
#' )
#' print(mda)
mysterycall_missing_data_analysis <- function(
    data,
    outcome_col,
    group_col      = NULL,
    covariate_cols = NULL,
    alpha          = 0.05
) {

  if (!is.data.frame(data))
    stop(sprintf("`data` must be a data frame, not %s.", class(data)[1L]), call. = FALSE)
  if (!is.character(outcome_col) || length(outcome_col) != 1L)
    stop("`outcome_col` must be a single character string naming a column in `data`.", call. = FALSE)
  if (!outcome_col %in% names(data))
    stop(sprintf(
      "`outcome_col` '%s' not found in `data`.\nAvailable columns: %s",
      outcome_col, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  if (!is.null(group_col)) {
    if (!is.character(group_col) || length(group_col) != 1L)
      stop("`group_col` must be a single character string or NULL.", call. = FALSE)
    if (!group_col %in% names(data))
      stop(sprintf(
        "`group_col` '%s' not found in `data`.\nAvailable columns: %s",
        group_col, paste(names(data), collapse = ", ")
      ), call. = FALSE)
  }
  if (!is.null(covariate_cols)) {
    bad <- setdiff(covariate_cols, names(data))
    if (length(bad))
      stop(sprintf(
        "covariate_cols not found in `data`: %s\nAvailable columns: %s",
        paste(bad, collapse = ", "), paste(names(data), collapse = ", ")
      ), call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || alpha <= 0 || alpha >= 1)
    stop(sprintf("`alpha` must be a single number in (0, 1), not %s.", deparse(alpha)), call. = FALSE)

  missing_flag <- as.integer(is.na(data[[outcome_col]]))
  n_total   <- nrow(data)
  n_missing <- sum(missing_flag)
  pct_miss  <- round(n_missing / n_total * 100, 1)

  all_cols <- c(group_col, covariate_cols)

  rows <- lapply(all_cols, function(col) {
    x <- data[[col]]
    .test_one(col, x, missing_flag, alpha)
  })
  summary_df <- do.call(rbind, rows)
  if (is.null(summary_df)) {
    summary_df <- data.frame(
      variable    = character(0),
      n_observed  = integer(0),
      n_missing   = integer(0),
      pct_missing = numeric(0),
      test        = character(0),
      statistic   = numeric(0),
      df          = integer(0),
      p_value     = numeric(0),
      significant = logical(0),
      stringsAsFactors = FALSE
    )
  }

  group_table <- NULL
  if (!is.null(group_col)) {
    group_table <- .group_breakdown(data, group_col, missing_flag)
  }

  sig_vars <- if (nrow(summary_df)) {
    summary_df$variable[summary_df$significant]
  } else {
    character(0)
  }

  interpretation <- .interpret_mcar(n_missing, n_total, sig_vars)

  structure(
    list(
      summary        = summary_df,
      overall        = list(n_total = n_total, n_missing = n_missing, pct_missing = pct_miss),
      interpretation = interpretation,
      group_table    = group_table,
      outcome_col    = outcome_col
    ),
    class = "mysterycall_missing_data"
  )
}


# ----- internal helpers -------------------------------------------------------

.test_one <- function(varname, x, missing_flag, alpha) {
  is_numeric <- is.numeric(x) && length(unique(stats::na.omit(x))) > 5L
  n_obs  <- sum(!is.na(x))
  n_miss <- sum(is.na(x))
  pct    <- round(sum(missing_flag) / length(missing_flag) * 100, 1)

  if (is_numeric) {
    # Wilcoxon rank-sum: compare x between missing and observed groups
    grp0 <- x[missing_flag == 0L & !is.na(x)]
    grp1 <- x[missing_flag == 1L & !is.na(x)]
    if (length(grp0) < 2L || length(grp1) < 2L) {
      return(.na_row(varname, n_obs, n_miss, pct))
    }
    res <- tryCatch(
      stats::wilcox.test(grp0, grp1),
      error   = function(e) NULL,
      warning = function(w) suppressWarnings(stats::wilcox.test(grp0, grp1))
    )
    if (is.null(res)) return(.na_row(varname, n_obs, n_miss, pct))
    data.frame(
      variable    = varname,
      n_observed  = n_obs,
      n_missing   = n_miss,
      pct_missing = pct,
      test        = "Wilcoxon",
      statistic   = as.numeric(res$statistic),
      df          = NA_integer_,
      p_value     = as.numeric(res$p.value),
      significant = !is.na(res$p.value) && res$p.value < alpha,
      stringsAsFactors = FALSE
    )
  } else {
    # Chi-square or Fisher
    x_f <- factor(x)
    tbl <- table(x_f, factor(missing_flag, levels = c(0L, 1L),
                              labels = c("Observed", "Missing")))
    if (nrow(tbl) < 2L || ncol(tbl) < 2L) {
      return(.na_row(varname, n_obs, n_miss, pct))
    }
    use_fisher <- any(stats::chisq.test(tbl, correct = FALSE)$expected < 5)
    if (use_fisher) {
      res <- tryCatch(
        stats::fisher.test(tbl, simulate.p.value = TRUE, B = 2000L),
        error = function(e) NULL
      )
      if (is.null(res)) return(.na_row(varname, n_obs, n_miss, pct))
      data.frame(
        variable    = varname,
        n_observed  = n_obs,
        n_missing   = n_miss,
        pct_missing = pct,
        test        = "Fisher",
        statistic   = NA_real_,
        df          = NA_integer_,
        p_value     = as.numeric(res$p.value),
        significant = !is.na(res$p.value) && res$p.value < alpha,
        stringsAsFactors = FALSE
      )
    } else {
      res <- tryCatch(
        stats::chisq.test(tbl, correct = FALSE),
        error = function(e) NULL
      )
      if (is.null(res)) return(.na_row(varname, n_obs, n_miss, pct))
      data.frame(
        variable    = varname,
        n_observed  = n_obs,
        n_missing   = n_miss,
        pct_missing = pct,
        test        = "Chi-square",
        statistic   = as.numeric(res$statistic),
        df          = as.integer(res$parameter),
        p_value     = as.numeric(res$p.value),
        significant = !is.na(res$p.value) && res$p.value < alpha,
        stringsAsFactors = FALSE
      )
    }
  }
}

.na_row <- function(varname, n_obs, n_miss, pct) {
  data.frame(
    variable    = varname,
    n_observed  = n_obs,
    n_missing   = n_miss,
    pct_missing = pct,
    test        = "insufficient data",
    statistic   = NA_real_,
    df          = NA_integer_,
    p_value     = NA_real_,
    significant = FALSE,
    stringsAsFactors = FALSE
  )
}

.group_breakdown <- function(data, group_col, missing_flag) {
  x    <- data[[group_col]]
  lvls <- sort(unique(stats::na.omit(x)))
  rows <- lapply(lvls, function(lvl) {
    idx      <- x == lvl & !is.na(x)
    n_total  <- sum(idx)
    n_miss   <- sum(missing_flag[idx])
    n_obs    <- n_total - n_miss
    data.frame(
      group       = as.character(lvl),
      n_total     = n_total,
      n_observed  = n_obs,
      n_missing   = n_miss,
      pct_missing = round(n_miss / n_total * 100, 1),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

.interpret_mcar <- function(n_missing, n_total, sig_vars) {
  pct <- round(n_missing / n_total * 100, 1)
  if (n_missing == 0L) {
    return(sprintf("No missing data in the outcome column (%d/%d complete).",
                   n_total, n_total))
  }
  if (length(sig_vars) == 0L) {
    return(sprintf(
      paste0(
        "%d of %d calls (%g%%) have a missing appointment date. ",
        "No significant associations were detected between missingness ",
        "and the tested variables, consistent with data missing completely ",
        "at random (MCAR). Analyses using complete cases are unlikely to ",
        "introduce systematic bias."
      ),
      n_missing, n_total, pct
    ))
  }
  vars_str <- paste(sig_vars, collapse = ", ")
  sprintf(
    paste0(
      "%d of %d calls (%g%%) have a missing appointment date. ",
      "Missingness was significantly associated with: %s. ",
      "This pattern is consistent with data missing at random (MAR) ",
      "conditional on observed covariates. Complete-case analyses may ",
      "underestimate the magnitude of insurance-related disparities; ",
      "consider multiple imputation or sensitivity analyses for robustness."
    ),
    n_missing, n_total, pct, vars_str
  )
}


#' Print method for mysterycall_missing_data
#'
#' @param x A `mysterycall_missing_data` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_missing_data <- function(x, ...) {
  cat("=== Missing Data Analysis ===\n\n")
  cat(sprintf("Overall: %d missing / %d total (%.1f%%)\n\n",
              x$overall$n_missing, x$overall$n_total, x$overall$pct_missing))

  if (!is.null(x$group_table)) {
    cat("-- Missingness by Group --\n")
    print(x$group_table, row.names = FALSE)
    cat("\n")
  }

  if (nrow(x$summary) > 0L) {
    cat("-- Statistical Tests (predictor vs. missingness) --\n")
    disp <- x$summary
    disp$statistic <- round(disp$statistic, 3)
    p_disp         <- mysterycall_format_p(disp$p_value)
    p_disp[is.na(disp$p_value)] <- "NA"
    disp$p_value   <- p_disp
    print(disp, row.names = FALSE)
    cat("\n")
  }

  cat("-- Interpretation --\n")
  cat(strwrap(x$interpretation, width = 80), sep = "\n")
  cat("\n")
  invisible(x)
}
