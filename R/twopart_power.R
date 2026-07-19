#' Monte Carlo power for a two-part (offer + conditional wait) design
#'
#' Mystery-caller access studies almost always have a two-part outcome: a binary
#' "was any appointment offered?" measured on every call, and a wait time (count
#' of business days) defined **only** for the calls that received an offer.
#' Powering such a study means powering both parts jointly -- a single-outcome
#' calculator understates the sample needed because the wait model runs on the
#' offered subset, not the full sample.
#'
#' This simulates a two-group single-contact design: each call is drawn from a
#' reference or treatment group, an offer is generated from a group-specific
#' probability (Bernoulli), and -- for offered calls only -- a wait time is drawn
#' from a group-specific negative-binomial. It fits a logistic model for the
#' offer on the full sample and a negative-binomial model
#' ([MASS::glm.nb()]) for the wait on the offered subset, and reports the power
#' for the group effect in each part.
#'
#' @param n_total Total calls. May be a vector to trace a power curve (one row
#'   per value).
#' @param offer_ref,offer_trt Probability of an offer in the reference /
#'   treatment group.
#' @param wait_ref,wait_trt Mean wait days (given an offer) in the reference /
#'   treatment group.
#' @param phi Negative-binomial dispersion (the `size`; variance is
#'   `mu + mu^2 / phi`).
#' @param group_frac Fraction of calls in the treatment group. Default `0.5`.
#' @param alpha Two-sided significance level. Default `0.05`.
#' @param n_sim Monte Carlo replicates per sample size. Default `500`.
#' @param seed Optional integer seed for reproducibility.
#'
#' @return An object of class `"mysterycall_twopart_power"`: a list with `table`
#'   (a tibble: `n_total`, `n_ref`, `n_trt`, `pow_offer`, `pow_wait`,
#'   `mean_offered`, `convergence_rate`, `n_sim`) and the call inputs.
#'   [as.data.frame()] returns the table.
#'
#' @examples
#' \donttest{
#' mysterycall_twopart_power(
#'   n_total = c(200, 400), offer_ref = 0.70, offer_trt = 0.55,
#'   wait_ref = 14, wait_trt = 21, phi = 1.7, n_sim = 50, seed = 1
#' )
#' }
#' @export
mysterycall_twopart_power <- function(n_total, offer_ref, offer_trt,
                                      wait_ref, wait_trt, phi,
                                      group_frac = 0.5, alpha = 0.05,
                                      n_sim = 500, seed = NULL) {
  checkmate::assert_integerish(n_total, lower = 4, any.missing = FALSE,
                               min.len = 1L)
  checkmate::assert_number(offer_ref, lower = 0, upper = 1)
  checkmate::assert_number(offer_trt, lower = 0, upper = 1)
  checkmate::assert_number(wait_ref, lower = 0)
  checkmate::assert_number(wait_trt, lower = 0)
  checkmate::assert_number(phi, lower = 1e-6)
  checkmate::assert_number(group_frac, lower = 1e-6, upper = 1 - 1e-6)
  checkmate::assert_number(alpha, lower = 1e-6, upper = 0.5)
  checkmate::assert_count(n_sim, positive = TRUE)
  if (!requireNamespace("MASS", quietly = TRUE)) {
    stop("mysterycall_twopart_power() needs the MASS package (in Suggests).",
         call. = FALSE)
  }
  if (!is.null(seed)) set.seed(seed)

  rows <- lapply(n_total, function(nt) {
    .mc_twopart_at_n(nt, offer_ref, offer_trt, wait_ref, wait_trt, phi,
                     group_frac, alpha, n_sim)
  })
  tab <- tibble::as_tibble(do.call(rbind, rows))

  structure(
    list(table = tab, alpha = alpha, n_sim = n_sim,
         inputs = list(offer_ref = offer_ref, offer_trt = offer_trt,
                       wait_ref = wait_ref, wait_trt = wait_trt, phi = phi,
                       group_frac = group_frac)),
    class = "mysterycall_twopart_power"
  )
}

.mc_twopart_at_n <- function(n_total, offer_ref, offer_trt, wait_ref, wait_trt,
                             phi, group_frac, alpha, n_sim) {
  n_trt <- round(n_total * group_frac)
  # deterministic group vector (fixed across replicates: power reflects outcome
  # variability, not group-assignment variability)
  group <- c(rep(0L, n_total - n_trt), rep(1L, n_trt))
  p_off <- ifelse(group == 1L, offer_trt, offer_ref)
  mu_w  <- ifelse(group == 1L, wait_trt, wait_ref)

  one_rep <- function() {
    offered <- stats::rbinom(n_total, 1, p_off)
    wait <- rep(NA_real_, n_total)
    has <- offered == 1L
    if (any(has)) {
      wait[has] <- stats::rnbinom(sum(has), mu = mu_w[has], size = phi)
    }
    dat <- data.frame(offered = offered, wait = wait, group = group)

    # offer part: logistic on the full sample
    op <- tryCatch({
      f <- suppressWarnings(stats::glm(offered ~ group,
                                       family = stats::binomial(), data = dat))
      cf <- summary(f)$coefficients
      if ("group" %in% rownames(cf)) cf["group", "Pr(>|z|)"] else NA_real_
    }, error = function(e) NA_real_)

    # wait part: NB on the offered subset
    sub <- dat[has & !is.na(dat$wait), , drop = FALSE]
    wp_ok <- length(unique(sub$group)) == 2L && nrow(sub) >= 6L
    wp <- if (wp_ok) tryCatch({
      f <- suppressWarnings(MASS::glm.nb(wait ~ group, data = sub))
      cf <- summary(f)$coefficients
      if ("group" %in% rownames(cf)) cf["group", "Pr(>|z|)"] else NA_real_
    }, error = function(e) NA_real_) else NA_real_

    c(op = op, wp = wp, n_off = sum(offered), conv = as.numeric(!is.na(op) && !is.na(wp)))
  }

  flat <- do.call(rbind, lapply(seq_len(n_sim), function(i) one_rep()))
  pow <- function(p) mean(p < alpha, na.rm = TRUE)
  data.frame(
    n_total = n_total,
    n_ref = n_total - n_trt,
    n_trt = n_trt,
    pow_offer = pow(flat[, "op"]),
    pow_wait = pow(flat[, "wp"]),
    mean_offered = mean(flat[, "n_off"]),
    convergence_rate = mean(flat[, "conv"]),
    n_sim = n_sim,
    stringsAsFactors = FALSE
  )
}

#' @export
print.mysterycall_twopart_power <- function(x, ...) {
  cat(sprintf("<mysterycall two-part power: %d sample size(s), %d sims, alpha %.3f>\n",
              nrow(x$table), x$n_sim, x$alpha))
  print(x$table, ...)
  invisible(x)
}

#' @export
as.data.frame.mysterycall_twopart_power <- function(x, ...) {
  as.data.frame(x$table, ...)
}

#' Type I error calibration check for a simulation-based test
#'
#' A companion to the simulation power functions: given the number of null
#' rejections observed when a test is run with the effect set to zero, report
#' the observed type I error rate, an exact binomial confidence interval, and a
#' verdict on whether the nominal `alpha` is plausibly attained. Use it to
#' confirm a Monte Carlo power simulator is well-calibrated before trusting its
#' power numbers.
#'
#' @param rejections Either the count of null replicates that rejected, or the
#'   observed rejection *rate* in `[0, 1]` (auto-detected: a value `<= 1` with a
#'   non-integer or `n_sim > 1` is treated as a rate).
#' @param n_sim Number of null replicates.
#' @param alpha Nominal significance level. Default `0.05`.
#'
#' @return A one-row tibble: `rejection_rate`, `ci_low`, `ci_high`, `n_sim`,
#'   `alpha_in_ci`, `verdict`.
#'
#' @examples
#' # 7 of 100 null replicates rejected at alpha = 0.05
#' mysterycall_type_i_check(7, n_sim = 100)
#' @export
mysterycall_type_i_check <- function(rejections, n_sim, alpha = 0.05) {
  checkmate::assert_count(n_sim, positive = TRUE)
  checkmate::assert_number(alpha, lower = 1e-6, upper = 0.5)
  checkmate::assert_number(rejections, lower = 0)
  # interpret input as a rate if it is <= 1 and not obviously a raw count
  if (rejections <= 1 && rejections != round(rejections)) {
    k <- round(rejections * n_sim)
  } else if (rejections <= 1 && n_sim > 1 && rejections < 1) {
    k <- round(rejections * n_sim)
  } else {
    k <- as.integer(round(rejections))
  }
  if (k > n_sim) {
    stop("`rejections` implies more rejections than `n_sim`.", call. = FALSE)
  }
  ci <- stats::binom.test(k, n_sim)$conf.int
  verdict <- if (alpha < ci[1]) "anti-conservative (rejects too often)"
             else if (alpha > ci[2]) "conservative (rejects too rarely)"
             else "consistent with nominal alpha"
  tibble::tibble(
    rejection_rate = k / n_sim,
    ci_low = ci[1], ci_high = ci[2],
    n_sim = n_sim,
    alpha_in_ci = alpha >= ci[1] && alpha <= ci[2],
    verdict = verdict
  )
}

#' Minimum detectable effect by binary search over a power function
#'
#' Finds the smallest effect size at which a (monotone) power function reaches a
#' target power, by bisection. Generic: `power_fn` can wrap any of the package's
#' simulation power calculators (or your own), so the same solver serves wait
#' times, offer rates, or rate ratios.
#'
#' @param power_fn A function of one numeric argument (the effect size) returning
#'   estimated power in `[0, 1]`. Assumed non-decreasing in the effect over
#'   `[lower, upper]`.
#' @param lower,upper Effect-size bracket to search. `power_fn(upper)` should
#'   meet or exceed `target_power`; if it does not, the search returns `NA` with
#'   a warning.
#' @param target_power Target power. Default `0.90`.
#' @param tol Stop when the bracket is narrower than `tol`. Default `0.01`.
#' @param max_iter Maximum bisection steps. Default `20`.
#'
#' @return A list with `mde` (the smallest effect meeting the target, or `NA`),
#'   `power_at_mde`, `iterations`, and `history` (a tibble of evaluated
#'   effect/power pairs).
#'
#' @examples
#' \donttest{
#' # smallest wait-time gap (treatment mean) detectable at 90% power
#' pf <- function(wait_trt) {
#'   mysterycall_twopart_power(
#'     n_total = 400, offer_ref = 0.7, offer_trt = 0.7,
#'     wait_ref = 14, wait_trt = wait_trt, phi = 1.7,
#'     n_sim = 40, seed = 1
#'   )$table$pow_wait
#' }
#' mysterycall_find_mde(pf, lower = 14, upper = 28, target_power = 0.90)
#' }
#' @export
mysterycall_find_mde <- function(power_fn, lower, upper, target_power = 0.90,
                                 tol = 0.01, max_iter = 20) {
  checkmate::assert_function(power_fn)
  checkmate::assert_number(lower)
  checkmate::assert_number(upper, lower = lower + 1e-9)
  checkmate::assert_number(target_power, lower = 0.01, upper = 0.999)
  checkmate::assert_number(tol, lower = 1e-9)
  checkmate::assert_count(max_iter, positive = TRUE)

  hist_eff <- numeric(0); hist_pow <- numeric(0)
  eval_pow <- function(e) {
    p <- power_fn(e)
    hist_eff[[length(hist_eff) + 1L]] <<- e
    hist_pow[[length(hist_pow) + 1L]] <<- p
    p
  }

  p_hi <- eval_pow(upper)
  if (is.na(p_hi) || p_hi < target_power) {
    warning(sprintf(paste0("power at upper = %g is %s, below target %g; ",
                          "widen the bracket."),
                    upper, format(p_hi), target_power), call. = FALSE)
    return(list(mde = NA_real_, power_at_mde = p_hi, iterations = 1L,
                history = tibble::tibble(effect = hist_eff, power = hist_pow)))
  }

  lo <- lower; hi <- upper; it <- 1L
  while ((hi - lo) > tol && it < max_iter) {
    mid <- (lo + hi) / 2
    p <- eval_pow(mid)
    if (!is.na(p) && p >= target_power) hi <- mid else lo <- mid
    it <- it + 1L
  }
  list(mde = hi, power_at_mde = eval_pow(hi), iterations = it,
       history = tibble::tibble(effect = hist_eff, power = hist_pow))
}
