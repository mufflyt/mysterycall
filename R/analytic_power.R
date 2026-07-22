#' Analytic power for a two-group continuous outcome under unequal allocation
#'
#' The package's analytic power tools are all count/binary; a mystery-caller
#' study with a continuous outcome (wait days) and a *fixed natural allocation*
#' -- e.g. only 15% of practices are rural -- needs a Cohen's-d two-sample
#' calculation that a naive equal-N formula gets wrong. This reports both the
#' equal-allocation sample size and the total N required under the study's real
#' group split, found by a binary search over [pwr::pwr.t2n.test()].
#'
#' Requires the \pkg{pwr} package.
#'
#' @param mde Minimum detectable effect (difference in group means, same units
#'   as `sd`). May be a vector; one result row per value.
#' @param sd Common within-group standard deviation.
#' @param group_frac Fraction of the sample in the smaller (exposure) group,
#'   in `(0, 1)`. Default `0.5` (equal allocation).
#' @param alpha Two-sided significance level. Default `0.05`.
#' @param power Target power. Default `0.80`.
#'
#' @return A [tibble::tibble()], one row per `mde`: `mde`, `cohens_d`,
#'   `n_per_group_equal`, `equal_total_n`, `natural_n_small`, `natural_n_large`,
#'   `natural_total_n`.
#'
#' @family power
#' @seealso [mysterycall_lm_interaction_power()], [mysterycall_power_curve()]
#' @examples
#' if (requireNamespace("pwr", quietly = TRUE)) {
#'   mysterycall_ttest_power(mde = c(3, 5, 7), sd = 12, group_frac = 0.15)
#' }
#' @export
mysterycall_ttest_power <- function(mde, sd, group_frac = 0.5,
                                   alpha = 0.05, power = 0.80) {
  checkmate::assert_numeric(mde, lower = 1e-9, any.missing = FALSE,
                            min.len = 1L)
  checkmate::assert_number(sd, lower = 1e-9)
  checkmate::assert_number(group_frac, lower = 1e-6, upper = 1 - 1e-6)
  checkmate::assert_number(alpha, lower = 1e-6, upper = 0.5)
  checkmate::assert_number(power, lower = 0.5, upper = 1 - 1e-9)
  if (!requireNamespace("pwr", quietly = TRUE)) {
    stop("mysterycall_ttest_power() requires the pwr package.\n",
         "Install it with: install.packages(\"pwr\")", call. = FALSE)
  }

  solve_unequal_n <- function(d) {
    lo <- 20L; hi <- 500000L
    while (hi - lo > 1L) {
      mid <- (lo + hi) %/% 2L
      n_small <- max(2L, round(mid * group_frac))
      n_large <- mid - n_small
      if (n_large < 2L) { lo <- mid; next }
      pw <- tryCatch(
        pwr::pwr.t2n.test(n1 = n_small, n2 = n_large, d = d,
                          sig.level = alpha, alternative = "two.sided")$power,
        error = function(e) NA_real_)
      if (is.na(pw)) { lo <- mid; next }
      if (pw < power) lo <- mid else hi <- mid
    }
    n_small <- max(2L, round(hi * group_frac))
    list(total = hi, small = n_small, large = hi - n_small)
  }

  rows <- lapply(mde, function(m) {
    d  <- m / sd
    eq <- pwr::pwr.t.test(d = d, sig.level = alpha, power = power,
                          type = "two.sample", alternative = "two.sided")
    n_eq <- ceiling(eq$n)
    un   <- solve_unequal_n(d)
    tibble::tibble(
      mde               = m,
      cohens_d          = round(d, 3),
      n_per_group_equal = n_eq,
      equal_total_n     = 2L * n_eq,
      natural_n_small   = un$small,
      natural_n_large   = un$large,
      natural_total_n   = un$total
    )
  })
  do.call(rbind, rows)
}

#' Analytic power for factorial linear-model terms via Cohen's f-squared
#'
#' A saturated factorial audit model (e.g. `rural * subspecialty * insurance`)
#' has a main effect and interaction for every term, each an F-test with its own
#' numerator degrees of freedom. This reports the total sample size each term
#' needs at a target power, using [pwr::pwr.f2.test()] with the correct
#' numerator df and adding back the full model's parameter count so the returned
#' figure is a usable N rather than a residual df.
#'
#' Requires the \pkg{pwr} package.
#'
#' @param terms Either a named integer vector mapping term label to numerator df
#'   (e.g. `c("rural" = 1, "rural x subspec" = 6)`), or a data frame with
#'   columns `term` and `df_num`.
#' @param n_params Number of parameters (cell means) in the full saturated
#'   model, e.g. `2 * n_subspec * n_insurance`. Added, with an intercept, to the
#'   solved residual df to give a total N.
#' @param f2 Named numeric vector of Cohen's f-squared effect sizes to report.
#'   Default `c(small = 0.02, medium = 0.15)`.
#' @param alpha Significance level. Default `0.05`.
#' @param power Target power. Default `0.90`.
#'
#' @return A [tibble::tibble()], one row per term: `term`, `df_num`, and one
#'   `n_<name>` column per `f2` entry giving the required total N.
#'
#' @family power
#' @seealso [mysterycall_ttest_power()], [mysterycall_joint_test()]
#' @examples
#' if (requireNamespace("pwr", quietly = TRUE)) {
#'   mysterycall_lm_interaction_power(
#'     terms = c("rural" = 1, "subspecialty" = 6, "rural x insurance" = 1),
#'     n_params = 2 * 7 * 2
#'   )
#' }
#' @export
mysterycall_lm_interaction_power <- function(terms, n_params,
                                            f2 = c(small = 0.02,
                                                   medium = 0.15),
                                            alpha = 0.05, power = 0.90) {
  if (is.data.frame(terms)) {
    checkmate::assert_subset(c("term", "df_num"), names(terms))
    term_lab <- as.character(terms$term)
    df_num   <- as.integer(terms$df_num)
  } else {
    checkmate::assert_integerish(terms, lower = 1L, any.missing = FALSE,
                                 names = "named", min.len = 1L)
    term_lab <- names(terms)
    df_num   <- as.integer(terms)
  }
  checkmate::assert_count(n_params, positive = TRUE)
  checkmate::assert_numeric(f2, lower = 1e-9, any.missing = FALSE,
                            min.len = 1L, names = "named")
  checkmate::assert_number(alpha, lower = 1e-6, upper = 0.5)
  checkmate::assert_number(power, lower = 0.5, upper = 1 - 1e-9)
  if (!requireNamespace("pwr", quietly = TRUE)) {
    stop("mysterycall_lm_interaction_power() requires the pwr package.\n",
         "Install it with: install.packages(\"pwr\")", call. = FALSE)
  }

  out <- tibble::tibble(term = term_lab, df_num = df_num)
  for (nm in names(f2)) {
    out[[paste0("n_", nm)]] <- vapply(df_num, function(u) {
      v <- pwr::pwr.f2.test(u = u, f2 = f2[[nm]], sig.level = alpha,
                            power = power)$v
      as.integer(ceiling(v) + n_params + 1L)
    }, integer(1))
  }
  out
}
