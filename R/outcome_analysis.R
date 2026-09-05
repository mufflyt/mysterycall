#' Primary outcome analysis for mystery caller studies
#'
#' Two complementary functions cover the headline results every mystery caller
#' paper reports: appointment wait times and appointment acceptance rates.
#' Both accept an optional grouping column (typically `"insurance"`) and
#' return a named list containing a tidy summary tibble, the raw test object,
#' a p-value, and a plain-language interpretation sentence.
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name mysterycall_outcomes
NULL

#' Coerce Acceptance Column to Logical
#'
#' Accepts logical, numeric, or character ("yes"/"y"/"true"/"1").
#'
#' @param x Vector to coerce.
#'
#' @return Logical vector.
#' @family outcomes
#' @keywords internal
.as_positive_logical <- function(x) {
  if (is.logical(x)) return(!is.na(x) & x)
  if (is.numeric(x)) return(!is.na(x) & x != 0)
  normalized <- tolower(trimws(as.character(x)))
  !is.na(normalized) & normalized %in% c("yes", "y", "true", "1")
}

#' Calculate Descriptive Statistics for Wait Times
#'
#' @param x Numeric vector of wait times.
#'
#' @return A tibble with descriptive statistics (n, mean, sd, median, etc.).
#' @family outcomes
#' @keywords internal
.wait_stats <- function(x) {
  x <- x[!is.na(x)]
  n <- length(x)
  if (n == 0L) {
    return(tibble::tibble(
      n = 0L, mean = NA_real_, sd = NA_real_,
      median = NA_real_, q1 = NA_real_, q3 = NA_real_,
      min = NA_real_, max = NA_real_
    ))
  }
  qs <- stats::quantile(x, probs = c(0.25, 0.75), na.rm = FALSE)
  tibble::tibble(
    n      = n,
    mean   = mean(x),
    sd     = stats::sd(x),
    median = stats::median(x),
    q1     = qs[[1L]],
    q3     = qs[[2L]],
    min    = min(x),
    max    = max(x)
  )
}

#' Wilson score confidence interval for a proportion
#'
#' @param k Number of successes.
#' @param n Total number of trials.
#' @param conf_level Confidence level.
#'
#' @return A numeric vector of length 2 (lower, upper).
#' @family outcomes
#' @keywords internal
.wilson_ci <- function(k, n, conf_level) {
  if (n == 0L) return(c(NA_real_, NA_real_))
  as.numeric(suppressWarnings(
    stats::prop.test(k, n, conf.level = conf_level, correct = FALSE)$conf.int
  ))
}


#' Summarize appointment wait times
#'
#' Computes descriptive statistics (n, mean, SD, median, IQR, range) for a
#' numeric wait-time column and runs an appropriate non-parametric test when
#' groups are specified: Wilcoxon rank-sum for two groups, Kruskal-Wallis for
#' three or more.
#'
#' Wait times must already be numeric (days to appointment). If your Phase 2
#' data records an appointment date rather than a count, compute
#' `data$wait_days <- as.numeric(data$appt_date - data$call_date)` before
#' calling this function.
#'
#' @param data A data frame containing at least the column named by `wait_col`.
#' @param wait_col Name of the numeric column holding days to appointment.
#'   Defaults to `"wait_days"`.
#' @param group_by Optional character scalar naming a grouping column (e.g.
#'   `"insurance"`). When `NULL` (default) statistics are computed over the
#'   full dataset and no test is run.
#' @param conf_level Confidence level used by the Wilcoxon test. Default
#'   `0.95`.
#'
#' @return A named list with:
#' \describe{
#'   \item{`summary`}{Tibble with one row per group (or one row overall).
#'     When `group_by` is non-`NULL`, the first column is named after the
#'     grouping variable (character). Remaining columns: `n` (integer),
#'     `n_missing` (integer), `mean` (numeric), `sd` (numeric), `median`
#'     (numeric), `q1` (numeric), `q3` (numeric), `min` (numeric), `max`
#'     (numeric).}
#'   \item{`test`}{`htest` object from [stats::wilcox.test()] (two groups)
#'     or [stats::kruskal.test()] (three or more groups), or `NULL` when no
#'     test was run (i.e., `group_by = NULL`).}
#'   \item{`p_value`}{Numeric p-value extracted from `test`, or `NA_real_`
#'     when no test was run.}
#'   \item{`test_name`}{Character. One of `"Wilcoxon rank-sum"`,
#'     `"Kruskal-Wallis"`, or `"none"`.}
#'   \item{`interpretation`}{Character. One-sentence plain-language summary
#'     suitable for pasting into a Results section.}
#' }
#'
#' @importFrom stats wilcox.test kruskal.test sd median quantile
#' @importFrom tibble tibble as_tibble
#' @family outcomes
#' @seealso [mysterycall_acceptance_rate()], [mysterycall_clean_phase2()], and
#'   [mysterycall_wait_time_by_group()] for the lean quantile-table-only variant
#'   (median/Q1/Q3/n with CSV export, no hypothesis test).
#' @export
#'
#' @examples
#' df <- data.frame(
#'   wait_days = c(3, 7, 14, 21, 5, 10, 30, 2),
#'   insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid",
#'                 "BCBS", "BCBS", "BCBS", "BCBS")
#' )
#' mysterycall_wait_time_summary(df, group_by = "insurance")
mysterycall_wait_time_summary <- function(data,
                                          wait_col   = "wait_days",
                                          group_by   = NULL,
                                          conf_level = 0.95) {
  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
  validate_required_columns(data, wait_col, name = "data")
  if (!is.null(group_by)) {
    validate_required_columns(data, group_by, name = "data")
    if (!is.character(group_by) || length(group_by) != 1L) {
      stop("`group_by` must be a single column name.", call. = FALSE)
    }
  }
  if (!is.numeric(data[[wait_col]])) {
    stop(sprintf(
      "`%s` must be a numeric column (days to appointment). If it is a Date, convert first: as.numeric(appt_date - call_date).",
      wait_col
    ), call. = FALSE)
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    stop("`conf_level` must be a single number strictly between 0 and 1.", call. = FALSE)
  }

  wait_vec  <- data[[wait_col]]
  n_missing <- sum(is.na(wait_vec))

  # -- No grouping ------------------------------------------------------------
  if (is.null(group_by)) {
    s <- .wait_stats(wait_vec)
    s$n_missing <- n_missing
    s <- s[, c("n", "n_missing", "mean", "sd", "median", "q1", "q3", "min", "max")]
    interp <- sprintf(
      "Median wait time: %g days (IQR %g to %g); mean %g days (SD %g); n = %d, %d missing.",
      s$median, s$q1, s$q3, round(s$mean, 1), round(s$sd, 1), s$n, n_missing
    )
    return(list(
      summary        = s,
      test           = NULL,
      p_value        = NA_real_,
      test_name      = "none",
      interpretation = interp
    ))
  }

  # -- Grouped ----------------------------------------------------------------
  group_vec <- data[[group_by]]
  groups    <- sort(unique(group_vec[!is.na(group_vec)]))
  n_groups  <- length(groups)

  group_rows <- lapply(groups, function(g) {
    mask <- !is.na(group_vec) & group_vec == g
    x    <- wait_vec[mask]
    s    <- .wait_stats(x)
    s$n_missing <- sum(is.na(x))
    s[[group_by]] <- as.character(g)
    s[, c(group_by, "n", "n_missing", "mean", "sd", "median", "q1", "q3", "min", "max")]
  })
  summary_tbl <- tibble::as_tibble(do.call(rbind, group_rows))

  # -- Non-parametric test ----------------------------------------------------
  test_obj  <- NULL
  p_value   <- NA_real_
  test_name <- "none"

  if (n_groups == 2L) {
    gdata <- lapply(groups, function(g) {
      x <- wait_vec[!is.na(group_vec) & group_vec == g]
      x[!is.na(x)]
    })
    if (all(lengths(gdata) >= 1L)) {
      test_obj <- tryCatch(
        suppressWarnings(
          stats::wilcox.test(gdata[[1L]], gdata[[2L]],
                             conf.level = conf_level, exact = FALSE)
        ),
        error = function(e) NULL
      )
      if (!is.null(test_obj)) {
        p_value   <- test_obj$p.value
        test_name <- "Wilcoxon rank-sum (Mann-Whitney U)"
      }
    }
  } else if (n_groups > 2L) {
    kw_df <- data.frame(
      x = wait_vec[!is.na(group_vec)],
      g = group_vec[!is.na(group_vec)]
    )
    kw_df <- kw_df[!is.na(kw_df$x), ]
    if (nrow(kw_df) > 0L) {
      test_obj <- tryCatch(
        stats::kruskal.test(x ~ g, data = kw_df),
        error = function(e) NULL
      )
      if (!is.null(test_obj)) {
        p_value   <- test_obj$p.value
        test_name <- "Kruskal-Wallis"
      }
    }
  }

  # -- Interpretation sentence ------------------------------------------------
  parts <- vapply(groups, function(g) {
    row <- summary_tbl[summary_tbl[[group_by]] == g, , drop = FALSE]
    sprintf("%s: median %g days (IQR %g to %g, n=%d)",
            g, row$median, row$q1, row$q3, row$n)
  }, character(1L))

  p_str <- if (!is.na(p_value)) {
    if (p_value < 0.001) "p < 0.001" else sprintf("p = %.3f", p_value)
  } else ""

  interpretation <- paste0(
    paste(parts, collapse = "; "),
    if (nzchar(p_str)) sprintf(". %s: %s", test_name, p_str) else "."
  )

  list(
    summary        = summary_tbl,
    test           = test_obj,
    p_value        = p_value,
    test_name      = test_name,
    interpretation = interpretation
  )
}


#' Compute appointment acceptance rates
#'
#' Calculates the proportion of physicians who offered an appointment (or were
#' successfully contacted, depending on how `accepted_col` is defined), with
#' Wilson confidence intervals. When groups are specified, runs a chi-square
#' test or Fisher's exact test (when any cell falls below `min_cell`).
#'
#' The acceptance column is interpreted generously: logical `TRUE`, non-zero
#' numerics, and character strings `"yes"`, `"y"`, `"true"`, and `"1"`
#' (case-insensitive) all count as accepted. Any other non-`NA` value counts
#' as not accepted, while `NA` values are treated as missing and excluded from
#' the denominator (they count as neither accepted nor rejected).
#'
#' @param data A data frame containing at least the column named by
#'   `accepted_col`.
#' @param accepted_col Name of the column recording whether the physician
#'   offered an appointment. Defaults to `"contact_office"`, the standard
#'   Phase 2 column name after [mysterycall_clean_phase2()].
#' @param group_by Optional character scalar naming a grouping column (e.g.
#'   `"insurance"`). When `NULL` (default), rates are computed over the full
#'   dataset and no test is run.
#' @param conf_level Confidence level for Wilson confidence intervals.
#'   Default `0.95`.
#' @param min_cell Minimum expected cell count; cells below this threshold
#'   trigger Fisher's exact test instead of chi-square. Default `5`.
#'
#' @return A named list with:
#' \describe{
#'   \item{`summary`}{Tibble with one row per group (or one row overall).
#'     When `group_by` is non-`NULL`, the first column is named after the
#'     grouping variable (character). Remaining columns: `n_total`
#'     (integer), `n_missing` (integer), `n_accepted` (integer),
#'     `n_rejected` (integer), `rate` (numeric, 0-1), `ci_lower` (numeric,
#'     0-1), `ci_upper` (numeric, 0-1).}
#'   \item{`test`}{`htest` object from [stats::chisq.test()] or
#'     [stats::fisher.test()], or `NULL` when no test was run.}
#'   \item{`p_value`}{Numeric p-value extracted from `test`, or `NA_real_`
#'     when no test was run.}
#'   \item{`test_name`}{Character. One of `"Fisher's exact"`,
#'     `"chi-square"`, `"chi-square (small cells)"`, or `"none"`.}
#'   \item{`interpretation`}{Character. One-sentence plain-language summary
#'     suitable for pasting into a Results section.}
#' }
#'
#' @importFrom stats prop.test chisq.test fisher.test
#' @importFrom tibble tibble as_tibble
#' @family outcomes
#' @seealso [mysterycall_wait_time_summary()], [mysterycall_clean_phase2()]
#' @export
#'
#' @examples
#' df <- data.frame(
#'   contact_office = c("Yes", "No", "Yes", "Yes", "No", "Yes", "No", "No"),
#'   insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid",
#'                 "BCBS", "BCBS", "BCBS", "BCBS")
#' )
#' mysterycall_acceptance_rate(df, group_by = "insurance")
mysterycall_acceptance_rate <- function(data,
                                        accepted_col = "contact_office",
                                        group_by     = NULL,
                                        conf_level   = 0.95,
                                        min_cell     = 5L) {
  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
  validate_required_columns(data, accepted_col, name = "data")
  if (!is.null(group_by)) {
    validate_required_columns(data, group_by, name = "data")
    if (!is.character(group_by) || length(group_by) != 1L) {
      stop("`group_by` must be a single column name.", call. = FALSE)
    }
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    stop("`conf_level` must be a single number strictly between 0 and 1.", call. = FALSE)
  }
  if (!is.numeric(min_cell) || length(min_cell) != 1L || min_cell < 0) {
    stop("`min_cell` must be a single non-negative number.", call. = FALSE)
  }

  raw_col   <- data[[accepted_col]]
  n_missing <- sum(is.na(raw_col))
  # Coerce only non-NA entries; NAs are missing, not rejected.
  non_na_mask  <- !is.na(raw_col)
  accepted_lgl <- .as_positive_logical(raw_col[non_na_mask])

  # -- No grouping ------------------------------------------------------------
  if (is.null(group_by)) {
    k    <- sum(accepted_lgl)
    n    <- length(accepted_lgl)   # excludes NAs
    ci   <- .wilson_ci(k, n, conf_level)
    rate <- if (n > 0L) k / n else NA_real_
    s <- tibble::tibble(
      n_total    = n,
      n_missing  = n_missing,
      n_accepted = k,
      n_rejected = n - k,
      rate       = rate,
      ci_lower   = ci[[1L]],
      ci_upper   = ci[[2L]]
    )
    interp <- sprintf(
      "Acceptance rate: %d/%d (%.1f%%, %d%% CI %.1f%% to %.1f%%).",
      k, n, rate * 100, round(conf_level * 100),
      ci[[1L]] * 100, ci[[2L]] * 100
    )
    return(list(
      summary        = s,
      test           = NULL,
      p_value        = NA_real_,
      test_name      = "none",
      interpretation = interp
    ))
  }

  # -- Grouped ----------------------------------------------------------------
  group_vec <- data[[group_by]]
  groups    <- sort(unique(group_vec[!is.na(group_vec)]))
  n_groups  <- length(groups)

  group_rows <- lapply(groups, function(g) {
    mask    <- !is.na(group_vec) & group_vec == g
    raw_grp <- raw_col[mask]
    nm      <- sum(is.na(raw_grp))
    acc     <- .as_positive_logical(raw_grp[!is.na(raw_grp)])
    k       <- sum(acc)
    n       <- length(acc)   # excludes NAs
    ci   <- .wilson_ci(k, n, conf_level)
    s    <- tibble::tibble(
      n_total    = n,
      n_missing  = nm,
      n_accepted = k,
      n_rejected = n - k,
      rate       = if (n > 0L) k / n else NA_real_,
      ci_lower   = ci[[1L]],
      ci_upper   = ci[[2L]]
    )
    s[[group_by]] <- as.character(g)
    s[, c(group_by, "n_total", "n_missing", "n_accepted", "n_rejected",
          "rate", "ci_lower", "ci_upper")]
  })
  summary_tbl <- tibble::as_tibble(do.call(rbind, group_rows))

  # -- Contingency table ------------------------------------------------------
  ct <- matrix(
    0L, nrow = 2L, ncol = n_groups,
    dimnames = list(c("accepted", "rejected"), as.character(groups))
  )
  for (i in seq_along(groups)) {
    mask    <- !is.na(group_vec) & group_vec == groups[[i]]
    raw_grp <- raw_col[mask]
    acc     <- .as_positive_logical(raw_grp[!is.na(raw_grp)])
    ct["accepted", i] <- sum(acc)
    ct["rejected", i] <- sum(!acc)
  }

  # -- Statistical test -------------------------------------------------------
  test_obj  <- NULL
  p_value   <- NA_real_
  test_name <- "none"

  if (n_groups >= 2L) {
    use_fisher <- any(ct < min_cell) && n_groups == 2L
    if (use_fisher) {
      test_obj  <- tryCatch(
        stats::fisher.test(ct, conf.level = conf_level),
        error = function(e) NULL
      )
      test_name <- "Fisher's exact"
    } else {
      test_obj  <- tryCatch(
        suppressWarnings(stats::chisq.test(ct, correct = FALSE)),
        error = function(e) NULL
      )
      test_name <- if (any(ct < min_cell)) {
        "chi-square (small cells -- interpret cautiously)"
      } else {
        "chi-square"
      }
    }
    if (!is.null(test_obj)) p_value <- test_obj$p.value
  }

  # -- Interpretation sentence ------------------------------------------------
  parts <- vapply(groups, function(g) {
    row <- summary_tbl[summary_tbl[[group_by]] == g, , drop = FALSE]
    sprintf("%s: %d/%d (%.1f%%, 95%% CI %.1f%% to %.1f%%)",
            g, row$n_accepted, row$n_total,
            row$rate * 100, row$ci_lower * 100, row$ci_upper * 100)
  }, character(1L))

  p_str <- if (!is.na(p_value)) {
    if (p_value < 0.001) "p < 0.001" else sprintf("p = %.3f", p_value)
  } else ""

  interpretation <- paste0(
    paste(parts, collapse = "; "),
    if (nzchar(p_str)) sprintf(". %s: %s", test_name, p_str) else "."
  )

  list(
    summary        = summary_tbl,
    test           = test_obj,
    p_value        = p_value,
    test_name      = test_name,
    interpretation = interpretation
  )
}
