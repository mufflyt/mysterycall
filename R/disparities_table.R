#' Compute Disparity Metrics Across Groups
#'
#' For each level of a grouping column (e.g., insurance type), compute
#' acceptance rates, confidence intervals, and disparity metrics relative
#' to a reference group.
#'
#' @param data A data.frame containing the study data.
#' @param outcome_col Character scalar. Name of the binary outcome column
#'   (values must be 0/1; NAs are dropped before calculations).
#' @param group_col Character scalar. Name of the grouping column.
#' @param ref_group Character scalar or NULL. Reference group label.
#'   If NULL, uses the first factor level when `group_col` is a factor,
#'   otherwise the alphabetically first level.
#' @param ci_method One of `"wilson"` (default), `"exact"`, or `"wald"`.
#' @param alpha Numeric in (0, 1). Significance level. Default 0.05 yields
#'   95% CIs.
#'
#' @return A data.frame with class
#'   `c("mysterycall_disparities_table", "data.frame")` sorted with the
#'   reference group first, then remaining groups by descending acceptance
#'   rate. Attributes `ref_group`, `ci_method`, and `alpha` are attached.
#'   Columns:
#'   \describe{
#'     \item{group}{Group label.}
#'     \item{n}{Total observations in group.}
#'     \item{n_accepted}{Sum of `outcome_col` (excluding NAs).}
#'     \item{rate}{Acceptance rate (n_accepted / n).}
#'     \item{lower_ci}{Lower bound of rate CI.}
#'     \item{upper_ci}{Upper bound of rate CI.}
#'     \item{abs_diff}{Difference in percentage points from ref group
#'       (0 for reference).}
#'     \item{rel_risk}{Rate relative to ref group rate (1 for reference).}
#'     \item{rr_lower}{Lower bound of RR CI via log method (NA for reference).}
#'     \item{rr_upper}{Upper bound of RR CI via log method (NA for reference).}
#'     \item{p_value}{Two-proportion z-test p-value vs. reference
#'       (NA for reference).}
#'     \item{p_value_fmt}{Formatted p-value string.}
#'   }
#'
#' @details
#' Relative-risk CIs use the log method with a 0.5 continuity correction when
#' `n_accepted` is 0:
#' \eqn{SE(\log RR) = \sqrt{1/n_+ - 1/n + 1/n_{ref,+} - 1/n_{ref}}}.
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   insurance = sample(c("Medicaid", "Private", "Medicare"), 120, replace = TRUE),
#'   accepted  = rbinom(120, 1, 0.5)
#' )
#' mysterycall_disparities_table(df, "accepted", "insurance")
#'
#' @importFrom stats prop.test binom.test qnorm
#' @family table helpers
#' @seealso [mysterycall_table1_gtsummary()], [mysterycall_bootstrap_ci()]
#' @export
mysterycall_disparities_table <- function(
    data,
    outcome_col,
    group_col,
    ref_group = NULL,
    ci_method = c("wilson", "exact", "wald"),
    alpha     = 0.05
) {
  # ---- input validation --------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }
  if (!is.character(outcome_col) || length(outcome_col) != 1L) {
    stop("`outcome_col` must be a single character string.", call. = FALSE)
  }
  if (!is.character(group_col) || length(group_col) != 1L) {
    stop("`group_col` must be a single character string.", call. = FALSE)
  }
  if (!outcome_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", outcome_col), call. = FALSE)
  }
  if (!group_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", group_col), call. = FALSE)
  }
  ov      <- data[[outcome_col]]
  ov_nona <- ov[!is.na(ov)]
  if (length(ov_nona) == 0L) {
    stop(sprintf("Column '%s' contains only NAs.", outcome_col), call. = FALSE)
  }
  if (!all(ov_nona == 0 | ov_nona == 1)) {
    stop(
      sprintf("Column '%s' must be binary (0/1 only; found: %s).",
              outcome_col,
              paste(sort(unique(ov_nona[ov_nona != 0 & ov_nona != 1])),
                    collapse = ", ")),
      call. = FALSE
    )
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be a single numeric value in (0, 1).", call. = FALSE)
  }
  ci_method <- match.arg(ci_method)

  # ---- determine reference group ----------------------------------------
  gv <- data[[group_col]]
  groups_ordered <- if (is.factor(gv)) {
    levels(gv)
  } else {
    sort(unique(as.character(gv)))
  }

  if (is.null(ref_group)) {
    ref_group <- groups_ordered[1L]
  } else {
    if (!ref_group %in% unique(as.character(gv))) {
      stop(
        sprintf("ref_group '%s' not found in column '%s'. Available: %s.",
                ref_group, group_col,
                paste(sort(unique(as.character(gv))), collapse = ", ")),
        call. = FALSE
      )
    }
  }

  # ---- per-group summaries -----------------------------------------------
  conf_level <- 1 - alpha
  gv_chr     <- as.character(gv)

  rows <- lapply(groups_ordered, function(g) {
    idx   <- !is.na(gv_chr) & gv_chr == g
    y     <- ov[idx]
    y     <- y[!is.na(y)]
    n     <- length(y)
    n_acc <- sum(y)
    rate  <- if (n > 0L) n_acc / n else NA_real_
    ci    <- .disp_rate_ci(n_acc, n, ci_method, conf_level, rate, alpha)
    data.frame(
      group      = g,
      n          = n,
      n_accepted = n_acc,
      rate       = rate,
      lower_ci   = ci[[1L]],
      upper_ci   = ci[[2L]],
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, rows)

  # ---- reference row values ----------------------------------------------
  ref_row   <- result[result$group == ref_group, , drop = FALSE]
  ref_rate  <- ref_row$rate
  ref_n     <- ref_row$n
  ref_n_acc <- ref_row$n_accepted

  # ---- disparity columns -------------------------------------------------
  n_groups    <- nrow(result)
  abs_diff    <- numeric(n_groups)
  rel_risk    <- numeric(n_groups)
  rr_lower    <- rep(NA_real_, n_groups)
  rr_upper    <- rep(NA_real_, n_groups)
  p_value     <- rep(NA_real_, n_groups)
  p_value_fmt <- rep(NA_character_, n_groups)

  z_crit <- stats::qnorm(1 - alpha / 2)

  for (i in seq_len(n_groups)) {
    if (result$group[[i]] == ref_group) {
      abs_diff[[i]] <- 0
      rel_risk[[i]] <- 1
      next
    }

    ni     <- result$n[[i]]
    ni_acc <- result$n_accepted[[i]]
    ratei  <- result$rate[[i]]

    abs_diff[[i]] <- (ratei - ref_rate) * 100

    # relative risk
    rr <- if (!is.na(ref_rate) && ref_rate > 0) ratei / ref_rate else NA_real_
    rel_risk[[i]] <- rr

    # RR CI via log method (0.5 continuity correction for zero cells)
    if (!is.na(rr) && rr > 0) {
      ni_acc_cc  <- if (ni_acc == 0) 0.5 else ni_acc
      ref_acc_cc <- if (ref_n_acc == 0) 0.5 else ref_n_acc
      se_log_rr  <- sqrt(
        1 / ni_acc_cc - 1 / ni + 1 / ref_acc_cc - 1 / ref_n
      )
      log_rr       <- log(rr)
      rr_lower[[i]] <- exp(log_rr - z_crit * se_log_rr)
      rr_upper[[i]] <- exp(log_rr + z_crit * se_log_rr)
    }

    # two-proportion z-test
    pv <- tryCatch(
      suppressWarnings(
        stats::prop.test(
          c(ni_acc, ref_n_acc), c(ni, ref_n), correct = FALSE
        )$p.value
      ),
      error = function(e) NA_real_
    )
    p_value[[i]] <- pv
    p_value_fmt[[i]] <- .fmt_pvalue(pv)
  }

  result$abs_diff    <- abs_diff
  result$rel_risk    <- rel_risk
  result$rr_lower    <- rr_lower
  result$rr_upper    <- rr_upper
  result$p_value     <- p_value
  result$p_value_fmt <- p_value_fmt

  # ---- sort: ref first, then by rate descending --------------------------
  is_ref  <- result$group == ref_group
  non_ref <- result[!is_ref, , drop = FALSE]
  non_ref <- non_ref[order(-non_ref$rate, na.last = TRUE), , drop = FALSE]
  result  <- rbind(result[is_ref, , drop = FALSE], non_ref)
  rownames(result) <- NULL

  class(result) <- c("mysterycall_disparities_table", "data.frame")
  attr(result, "ref_group") <- ref_group
  attr(result, "ci_method") <- ci_method
  attr(result, "alpha")     <- alpha
  result
}

# ---- internal helpers -------------------------------------------------------

#' Calculate Confidence Interval for Proportion
#'
#' @param n_acc Number of successes.
#' @param n Total number of trials.
#' @param method CI method: "wilson", "exact", or "wald".
#' @param conf_level Confidence level (e.g., 0.95).
#' @param rate Observed proportion (n_acc / n).
#' @param alpha Significance level (1 - conf_level).
#'
#' @return Numeric vector of length 2 (lower, upper).
#' @family outcomes
#' @keywords internal
.disp_rate_ci <- function(n_acc, n, method, conf_level, rate, alpha) {
  if (n == 0L) return(c(NA_real_, NA_real_))
  switch(method,
    wilson = {
      ci <- suppressWarnings(
        stats::prop.test(n_acc, n, conf.level = conf_level, correct = FALSE)$conf.int
      )
      as.numeric(ci)
    },
    exact = {
      as.numeric(stats::binom.test(n_acc, n, conf.level = conf_level)$conf.int)
    },
    wald = {
      z  <- stats::qnorm(1 - alpha / 2)
      se <- sqrt(rate * (1 - rate) / n)
      c(rate - z * se, rate + z * se)
    }
  )
}

#' Format P-Value for Display
#'
#' @param p Numeric p-value.
#'
#' @return Formatted character string (e.g., "<0.001").
#' @family outcomes
#' @keywords internal
.fmt_pvalue <- function(p) {
  if (is.na(p))      return(NA_character_)
  if (p < 0.001)     return("<0.001")
  if (p < 0.01)      return(sprintf("%.3f", p))
  sprintf("%.3f", p)
}

# ---- S3 print ---------------------------------------------------------------

#' Print a mysterycall_disparities_table
#'
#' Prints a formatted table of disparity metrics with group sizes, acceptance
#' rates, Wilson confidence intervals, absolute risk differences, relative risks,
#' and p-values versus the reference group.  Column headers are labelled using
#' the `ci_method` and `alpha` attributes stored on the object.
#'
#' @param x A `mysterycall_disparities_table` object returned by
#'   [mysterycall_disparities_table()].
#' @param ... Ignored.
#' @return Invisibly returns `x`.
#' @seealso [mysterycall_disparities_table()]
#' @family table helpers
#' @export
#' @examples
#' \donttest{
#' df <- data.frame(
#'   group   = c("Medicaid", "Private", "Uninsured"),
#'   success = c(40L, 80L, 30L),
#'   total   = c(100L, 100L, 100L)
#' )
#' disp_table <- mysterycall_disparities_table(df, "group", "success", "total",
#'                                              ref_group = "Private")
#' print(disp_table)
#' }
print.mysterycall_disparities_table <- function(x, ...) {
  ref    <- attr(x, "ref_group") %||% x$group[[1L]]
  method <- attr(x, "ci_method") %||% "wilson"
  alpha  <- attr(x, "alpha")     %||% 0.05
  ci_pct <- round((1 - alpha) * 100)

  cat(sprintf("Disparity table -- %d groups | ref: '%s' | %s %d%% CI\n",
              nrow(x), ref, method, ci_pct))
  cat(sprintf("%-22s %6s %6s %8s  %-16s %9s  %-22s  %s\n",
              "Group", "n", "n_acc", "Rate",
              sprintf("%d%% CI", ci_pct),
              "Abs.Diff", "RR (95% CI)", "p-value"))
  cat(strrep("-", 100), "\n")

  for (i in seq_len(nrow(x))) {
    row      <- x[i, ]
    is_ref_i <- !is.na(row$group) && row$group == ref

    rate_fmt <- if (is.na(row$rate)) "NA" else sprintf("%.1f%%", row$rate * 100)
    lo       <- row$lower_ci
    hi       <- row$upper_ci
    ci_fmt   <- if (is.na(lo) || is.na(hi)) {
      "NA"
    } else {
      sprintf("%.1f%%-%.1f%%", lo * 100, hi * 100)
    }
    ad_fmt <- if (is_ref_i) "(ref)" else sprintf("%+.1f pp", row$abs_diff)
    rr_fmt <- if (is_ref_i || is.na(row$rr_lower)) {
      sprintf("%.2f (ref)", row$rel_risk)
    } else {
      sprintf("%.2f (%.2f-%.2f)", row$rel_risk, row$rr_lower, row$rr_upper)
    }
    pv_fmt <- if (is_ref_i || is.na(row$p_value_fmt)) "(ref)" else row$p_value_fmt

    cat(sprintf("%-22s %6d %6d %8s  %-16s %9s  %-22s  %s\n",
                row$group, row$n, row$n_accepted,
                rate_fmt, ci_fmt, ad_fmt, rr_fmt, pv_fmt))
  }
  invisible(x)
}
