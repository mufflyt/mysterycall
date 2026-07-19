#' Two-part hurdle model for a mystery-caller wait time
#'
#' Mystery-caller wait times have a two-part structure: an appointment is either
#' obtained or not (the "hurdle"), and *conditional on* obtaining one, the wait is
#' a right-skewed count of days. This fits both parts and returns them together:
#' a binary hurdle model for whether an appointment was obtained, and a
#' (zero-truncated) negative-binomial model for the wait among obtained
#' appointments. Both parts accept a practice random intercept, so the paired /
#' clustered structure of an audit is respected -- an advantage over
#' `pscl::hurdle()`, which cannot cluster.
#'
#' A hurdle model is the natural default when the wait is right-skewed: the
#' negative-binomial count part absorbs the skew and overdispersion that a
#' normal-outcome selection (Heckman) model cannot. It assumes the two parts are
#' separable given the covariates (selection on observables); address any
#' residual selection-on-unobservables concern with a sensitivity analysis --
#' [mysterycall_outcome_bounds()] (Manski bounds on the obtainment rate) or
#' [mysterycall_leave_one_out()] -- rather than forcing a Heckman correction.
#'
#' @param data A data frame, one row per call.
#' @param obtained_col Name of the binary "appointment obtained" column (the
#'   hurdle outcome). Coerced with `%in% TRUE`/`1`/`"TRUE"`/`"Yes"`.
#' @param wait_col Name of the wait-time count column (defined among obtained
#'   appointments; `NA`/missing otherwise).
#' @param predictors Character vector of predictor columns, used in both parts.
#' @param random_intercept Optional name of a clustering column (e.g. practice)
#'   for a random intercept in both parts. `NULL` fits fixed-effects-only.
#' @param count_family Working family for the count part: `"nbinom2"` (default)
#'   or `"poisson"`.
#' @param truncate_zero If `TRUE` (default) model the wait with a **zero-
#'   truncated** count distribution fit on waits `> 0` (the hurdle already
#'   carries the not-obtained cases); if `FALSE` keep same-day (0-day) waits and
#'   fit an untruncated count model.
#' @param conf_level Confidence level for the reported intervals. Default `0.95`.
#'
#' @return An object of class `"mysterycall_hurdle_wait"`: a list with `hurdle`
#'   (a tibble of odds ratios for the obtainment part) and `count` (a tibble of
#'   incidence-rate ratios for the wait part), each with `term`, `estimate`,
#'   `conf_low`, `conf_high`, `p_value`, plus `n_hurdle`, `n_count`, and the
#'   fitted `hurdle_model` / `count_model`. [as.data.frame()] returns the two
#'   tables stacked with a `part` column. Requires the \pkg{glmmTMB} package.
#'
#' @examples
#' \donttest{
#' set.seed(1)
#' d <- data.frame(
#'   practice  = rep(sprintf("p%03d", 1:150), each = 2),
#'   insurance = rep(c("Commercial", "Medicaid"), 150),
#'   obtained  = rbinom(300, 1, 0.65))
#' d$wait_days <- ifelse(d$obtained == 1, rnbinom(300, mu = 16, size = 2), NA)
#' mysterycall_hurdle_wait(d, "obtained", "wait_days", "insurance",
#'                         random_intercept = "practice")
#' }
#' @export
mysterycall_hurdle_wait <- function(data, obtained_col, wait_col, predictors,
                                    random_intercept = NULL,
                                    count_family = c("nbinom2", "poisson"),
                                    truncate_zero = TRUE, conf_level = 0.95) {
  count_family <- match.arg(count_family)
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_choice(obtained_col, names(data))
  checkmate::assert_choice(wait_col, names(data))
  checkmate::assert_character(predictors, min.len = 1L, any.missing = FALSE)
  checkmate::assert_subset(predictors, names(data))
  if (!is.null(random_intercept)) {
    checkmate::assert_choice(random_intercept, names(data))
  }
  checkmate::assert_flag(truncate_zero)
  checkmate::assert_number(conf_level, lower = 0.5, upper = 0.999)
  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    stop("mysterycall_hurdle_wait() needs the glmmTMB package (in Suggests).",
         call. = FALSE)
  }

  re <- if (is.null(random_intercept)) "" else
    sprintf(" + (1 | %s)", random_intercept)
  rhs <- paste0(paste(predictors, collapse = " + "), re)

  # ---- part 1: the hurdle (appointment obtained yes/no) ----------------------
  hd <- data
  hd[[obtained_col]] <- as.integer(hd[[obtained_col]] %in%
                                     c(TRUE, 1, "1", "TRUE", "Yes", "yes"))
  hurdle_fit <- suppressWarnings(glmmTMB::glmmTMB(
    stats::as.formula(sprintf("%s ~ %s", obtained_col, rhs)),
    family = stats::binomial(), data = hd))

  # ---- part 2: the wait among obtained appointments --------------------------
  sub <- hd[hd[[obtained_col]] == 1L & !is.na(hd[[wait_col]]), , drop = FALSE]
  if (truncate_zero) sub <- sub[sub[[wait_col]] > 0, , drop = FALSE]
  fam <- switch(paste(count_family, truncate_zero),
    "nbinom2 TRUE"  = glmmTMB::truncated_nbinom2(),
    "nbinom2 FALSE" = glmmTMB::nbinom2(),
    "poisson TRUE"  = glmmTMB::truncated_poisson(),
    "poisson FALSE" = glmmTMB::poisson())
  count_fit <- suppressWarnings(glmmTMB::glmmTMB(
    stats::as.formula(sprintf("%s ~ %s", wait_col, rhs)),
    family = fam, data = sub))

  structure(
    list(
      hurdle = .mc_hurdle_tidy(hurdle_fit, conf_level),
      count = .mc_hurdle_tidy(count_fit, conf_level),
      n_hurdle = nrow(hd), n_count = nrow(sub),
      count_family = count_family, truncated = truncate_zero,
      hurdle_model = hurdle_fit, count_model = count_fit),
    class = "mysterycall_hurdle_wait"
  )
}

# tidy the conditional fixed effects of a glmmTMB fit into an exp(estimate) table
.mc_hurdle_tidy <- function(fit, conf_level) {
  co <- summary(fit)$coefficients$cond
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  est <- co[, "Estimate"]; se <- co[, "Std. Error"]
  tibble::tibble(
    term = rownames(co),
    estimate = exp(est),
    conf_low = exp(est - z * se),
    conf_high = exp(est + z * se),
    p_value = co[, "Pr(>|z|)"]
  )
}

#' @export
print.mysterycall_hurdle_wait <- function(x, ...) {
  cat(sprintf("<mysterycall hurdle wait model: hurdle n=%d, count n=%d (%s%s)>\n",
              x$n_hurdle, x$n_count, if (x$truncated) "zero-truncated " else "",
              x$count_family))
  cat("\nHurdle part -- appointment obtained (odds ratios):\n")
  print(x$hurdle, ...)
  cat("\nCount part -- wait days | obtained (incidence rate ratios):\n")
  print(x$count, ...)
  invisible(x)
}

#' @export
as.data.frame.mysterycall_hurdle_wait <- function(x, ...) {
  as.data.frame(rbind(
    cbind(part = "hurdle", x$hurdle),
    cbind(part = "count", x$count)), ...)
}
