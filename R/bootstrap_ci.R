#' Bootstrap Confidence Intervals for a Summary Statistic
#'
#' For each level of an optional grouping column (or for the whole dataset),
#' draws `n_boot` bootstrap samples with replacement, computes a
#' summary statistic, and returns percentile confidence intervals.
#'
#' @param data A data.frame.
#' @param outcome_col Character scalar. Name of the outcome column.
#'   When `stat = "proportion"`, values must be 0/1.
#' @param group_col Character scalar or NULL. Name of a grouping column.
#'   If NULL, a single "Overall" row is returned.
#' @param n_boot Positive integer (>= 100). Number of bootstrap replicates.
#'   Default 2000L.
#' @param seed Integer or NULL. If not NULL, passed to `set.seed()`
#'   before bootstrapping to make results reproducible.
#' @param alpha Numeric in (0, 1). CI uses the `alpha/2` and
#'   `1 - alpha/2` percentiles. Default 0.05.
#' @param stat Character. Statistic to bootstrap. One of
#'   `"proportion"` (mean of a 0/1 variable), `"mean"`, or `"median"`.
#'
#' @return A data frame with one row per group (or `"Overall"` when
#'   `group_col` is `NULL`) and columns:
#'   \describe{
#'     \item{`group`}{Character. Group label, or `"Overall"` when
#'       `group_col` is `NULL`.}
#'     \item{`n`}{Integer. Number of non-NA observations used.}
#'     \item{`estimate`}{Numeric. Observed statistic value (proportion,
#'       mean, or median depending on `stat`).}
#'     \item{`lower_ci`}{Numeric. Lower percentile CI bound at `alpha/2`.}
#'     \item{`upper_ci`}{Numeric. Upper percentile CI bound at
#'       `1 - alpha/2`.}
#'     \item{`n_boot`}{Integer. Number of bootstrap replicates used.}
#'   }
#'
#' @examples
#' set.seed(42)
#' df <- data.frame(
#'   insurance = sample(c("Medicaid", "Private"), 200, replace = TRUE),
#'   accepted  = rbinom(200, 1, 0.6)
#' )
#' mysterycall_bootstrap_ci(df, "accepted", group_col = "insurance", seed = 1)
#'
#' @seealso [mysterycall_acceptance_rate()], [mysterycall_wait_time_summary()]
#'   for model-based outcome summaries; [mysterycall_compare_waves()] for
#'   cross-wave significance testing.
#' @family outcomes
#' @family inference
#' @export
mysterycall_bootstrap_ci <- function(
    data,
    outcome_col,
    group_col = NULL,
    n_boot    = 2000L,
    seed      = NULL,
    alpha     = 0.05,
    stat      = c("proportion", "mean", "median")
) {
  stat <- match.arg(stat)

  # ---- input validation ------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }
  if (!is.character(outcome_col) || length(outcome_col) != 1L) {
    stop("`outcome_col` must be a single character string.", call. = FALSE)
  }
  if (!outcome_col %in% names(data)) {
    stop(sprintf(
      "outcome_col '%s' not found in `data`.\nAvailable columns: %s",
      outcome_col, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  }
  if (!is.null(group_col)) {
    if (!is.character(group_col) || length(group_col) != 1L) {
      stop("`group_col` must be a single character string or NULL.", call. = FALSE)
    }
    if (!group_col %in% names(data)) {
      stop(sprintf(
        "group_col '%s' not found in `data`.\nAvailable columns: %s",
        group_col, paste(names(data), collapse = ", ")
      ), call. = FALSE)
    }
  }
  if (is.null(n_boot)) {
    stop("`n_boot` must not be NULL.", call. = FALSE)
  }
  n_boot <- as.integer(n_boot)
  if (length(n_boot) != 1L || is.na(n_boot) || n_boot < 100L) {
    stop("`n_boot` must be an integer >= 100.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be a single numeric value in (0, 1).", call. = FALSE)
  }

  # ---- set seed --------------------------------------------------------
  if (!is.null(seed)) {
    set.seed(seed)
  }

  # ---- choose statistic function --------------------------------------
  stat_fn <- switch(stat,
    proportion = mean,
    mean       = mean,
    median     = stats::median
  )

  # ---- helper: bootstrap one group ------------------------------------
  .boot_group <- function(y, label) {
    y <- y[!is.na(y)]
    n <- length(y)
    if (n == 0L) {
      return(data.frame(
        group    = label,
        n        = 0L,
        estimate = NA_real_,
        lower_ci = NA_real_,
        upper_ci = NA_real_,
        n_boot   = n_boot,
        stringsAsFactors = FALSE
      ))
    }
    obs_stat <- stat_fn(y)
    boot_stats <- replicate(n_boot, stat_fn(sample(y, size = n, replace = TRUE)))
    probs <- c(alpha / 2, 1 - alpha / 2)
    ci    <- stats::quantile(boot_stats, probs = probs, names = FALSE)
    data.frame(
      group    = label,
      n        = n,
      estimate = obs_stat,
      lower_ci = ci[1L],
      upper_ci = ci[2L],
      n_boot   = n_boot,
      stringsAsFactors = FALSE
    )
  }

  # ---- run by group or overall ----------------------------------------
  if (is.null(group_col)) {
    result <- .boot_group(data[[outcome_col]], "Overall")
  } else {
    gv     <- data[[group_col]]
    groups <- if (is.factor(gv)) levels(gv) else sort(unique(as.character(gv)))
    gv_chr <- as.character(gv)
    rows <- lapply(groups, function(g) {
      idx <- gv_chr == g & !is.na(gv_chr)
      .boot_group(data[[outcome_col]][idx], g)
    })
    result <- do.call(rbind, rows)
    rownames(result) <- NULL
  }

  result
}
