#' Worst-case / best-case bounds on a proportion under non-response
#'
#' When some calls are incomplete, the true outcome rate over the full sampling
#' frame is not point-identified: the missing calls could all have been
#' successes or all failures. This computes the Manski-style bounds -- the
#' complete-case rate, plus the assumption-free interval you get by assigning
#' every unobserved call first to failure (worst case) then to success (best
#' case) -- over the full universe. Reviewers of audit studies routinely ask for
#' these bounds so a headline offer/acceptance rate is not quietly conditioned
#' on the calls that happened to complete.
#'
#' @param data A data frame spanning the full sampling universe (observed *and*
#'   unobserved calls).
#' @param outcome_col Name of the binary outcome column.
#' @param positive_values Value(s) of `outcome_col` counted as a success.
#'   Default `TRUE` (also matched against `"TRUE"`/`1` via `%in%`).
#' @param observed Optional: which rows have a trustworthy observed outcome.
#'   Either a column name (interpreted so that non-missing / truthy = observed)
#'   or a logical vector the length of `nrow(data)`. If `NULL` (default), a row
#'   is observed when `outcome_col` is not `NA`.
#' @param conf_level Confidence level for the Wilson interval on the
#'   complete-case rate. Default `0.95`.
#'
#' @return An object of class `"mysterycall_outcome_bounds"`: a list with
#'   `n_universe`, `n_observed`, `n_missing`, `n_positive`, `complete_case_rate`
#'   (+ Wilson `cc_ci_lower`/`cc_ci_upper`), `lower_bound` (all missing are
#'   failures), `upper_bound` (all missing are successes), and `bound_width`
#'   (= `n_missing / n_universe`, the ignorance interval). All rates are
#'   proportions in `[0, 1]`. [as.data.frame()] returns a one-row tibble.
#'
#' @examples
#' d <- data.frame(
#'   offered  = c(TRUE, FALSE, TRUE, NA, NA, TRUE, FALSE, NA),
#'   complete = c("Y", "Y", "Y", "N", "N", "Y", "Y", "N")
#' )
#' mysterycall_outcome_bounds(d, "offered")
#' @export
mysterycall_outcome_bounds <- function(data, outcome_col, positive_values = TRUE,
                                       observed = NULL, conf_level = 0.95) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_choice(outcome_col, names(data))
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)

  n_universe <- nrow(data)
  out <- data[[outcome_col]]

  if (is.null(observed)) {
    obs <- !is.na(out)
  } else if (is.character(observed) && length(observed) == 1L) {
    checkmate::assert_choice(observed, names(data))
    ov <- data[[observed]]
    obs <- if (is.logical(ov)) ov & !is.na(ov) else !is.na(ov) & .mc_truthy(ov)
  } else {
    checkmate::assert_logical(observed, len = n_universe, any.missing = FALSE)
    obs <- observed
  }

  pos <- obs & (out %in% positive_values)
  n_observed <- sum(obs)
  n_missing <- n_universe - n_observed
  n_positive <- sum(pos)

  cc_rate <- if (n_observed > 0) n_positive / n_observed else NA_real_
  cc_ci <- .mc_wilson_ci(n_positive, n_observed, conf_level)

  structure(
    list(
      n_universe = n_universe,
      n_observed = n_observed,
      n_missing = n_missing,
      n_positive = n_positive,
      complete_case_rate = cc_rate,
      cc_ci_lower = cc_ci[1], cc_ci_upper = cc_ci[2],
      lower_bound = n_positive / n_universe,
      upper_bound = (n_positive + n_missing) / n_universe,
      bound_width = n_missing / n_universe,
      conf_level = conf_level
    ),
    class = "mysterycall_outcome_bounds"
  )
}

.mc_truthy <- function(x) {
  if (is.logical(x)) return(x & !is.na(x))
  if (is.numeric(x)) return(!is.na(x) & x != 0)
  trimws(tolower(as.character(x))) %in% c("true", "1", "yes", "y", "complete",
                                          "observed", "offered")
}

#' @export
print.mysterycall_outcome_bounds <- function(x, ...) {
  pc <- function(p) if (is.na(p)) "NA" else sprintf("%.1f%%", 100 * p)
  cat("<mysterycall outcome bounds under non-response>\n")
  cat(sprintf("  universe %d = observed %d + missing %d; positives %d\n",
              x$n_universe, x$n_observed, x$n_missing, x$n_positive))
  cat(sprintf("  complete-case rate: %s  (%.0f%% CI %s-%s)\n",
              pc(x$complete_case_rate), 100 * x$conf_level,
              pc(x$cc_ci_lower), pc(x$cc_ci_upper)))
  cat(sprintf("  bounds over universe: [%s (all missing fail), %s (all succeed)]  width %s\n",
              pc(x$lower_bound), pc(x$upper_bound), pc(x$bound_width)))
  invisible(x)
}

#' @export
as.data.frame.mysterycall_outcome_bounds <- function(x, ...) {
  as.data.frame(tibble::tibble(
    n_universe = x$n_universe, n_observed = x$n_observed,
    n_missing = x$n_missing, n_positive = x$n_positive,
    complete_case_rate = x$complete_case_rate,
    cc_ci_lower = x$cc_ci_lower, cc_ci_upper = x$cc_ci_upper,
    lower_bound = x$lower_bound, upper_bound = x$upper_bound,
    bound_width = x$bound_width), ...)
}
