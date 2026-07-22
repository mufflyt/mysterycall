#' Simulation power for a covariate-adjusted NB GLMM with a cluster ICC
#'
#' The existing power tools cluster on the *physician* (paired calls). A
#' geographic access study instead adjusts for confounders and clusters callers
#' within a higher-level unit -- states, markets -- whose correlation is
#' expressed as an intraclass correlation coefficient (ICC), not a random-slope
#' design. Analysts usually paper over this with a "+20% for clustering" rule of
#' thumb. This instead simulates power for the *actual adjusted analysis*: a
#' negative-binomial GLMM for the wait outcome with a rural (exposure) fixed
#' effect, a subspecialty fixed effect, a configurable number of nuisance
#' adjustment covariates, and a **state-level random intercept whose SD is
#' derived from a target ICC** via
#' `sigma = sqrt(ICC/(1 - ICC) * (trigamma(1/phi) + pi^2/3))` -- the same
#' latent-scale decomposition [mysterycall_icc()] uses. It
#' reports the power to detect the rural effect along with the mean estimated
#' effect, its standard error, and the model convergence rate.
#'
#' Requires the \pkg{glmmTMB} package.
#'
#' @param n_total Integer total sample size (calls).
#' @param rural_frac Fraction of calls in the rural (exposure) group, in
#'   `(0, 1)`.
#' @param wait_urban,wait_rural Mean wait (days) in the urban and rural groups;
#'   their ratio is the true effect on the log scale.
#' @param phi Negative-binomial dispersion (`size`); smaller is more
#'   overdispersed.
#' @param state_icc Target intraclass correlation for the cluster random
#'   intercept, in `[0, 0.9)`. Default `0.05`.
#' @param n_states Number of clusters (random-intercept levels). Default `51`.
#' @param n_subspecs Number of subspecialty fixed-effect levels (`1` drops the
#'   term). Default `7`.
#' @param n_extra_covars Number of nuisance adjustment covariates. Default `6`.
#' @param alpha Two-sided significance level. Default `0.05`.
#' @param n_sim Number of Monte Carlo replicates. Default `100`.
#' @param seed Optional integer seed for reproducibility. Default `NULL`.
#'
#' @return A one-row [tibble::tibble()]: `n_total`, `n_rural`, `n_urban`,
#'   `power` (rural-effect rejection rate), `mean_log_effect`, `mean_se`,
#'   `median_se`, `convergence_rate`, `state_icc`, `sigma_state`, `n_states`,
#'   `n_subspecs`, `n_extra_covars`, `n_sim`. Pair with [mysterycall_find_mde()]
#'   to solve for a detectable effect, or call across an `n_total` grid for a
#'   power curve.
#'
#' @family power
#' @seealso [mysterycall_marginal_power()], [mysterycall_twopart_power()],
#'   [mysterycall_find_mde()]
#' @examples
#' \donttest{
#' if (requireNamespace("glmmTMB", quietly = TRUE)) {
#'   mysterycall_adjusted_power(
#'     n_total = 400, rural_frac = 0.15,
#'     wait_urban = 20, wait_rural = 28, phi = 1.7,
#'     state_icc = 0.05, n_sim = 20, seed = 1
#'   )
#' }
#' }
#' @export
mysterycall_adjusted_power <- function(n_total, rural_frac,
                                      wait_urban, wait_rural, phi,
                                      state_icc = 0.05, n_states = 51,
                                      n_subspecs = 7, n_extra_covars = 6,
                                      alpha = 0.05, n_sim = 100, seed = NULL) {
  checkmate::assert_count(n_total, positive = TRUE)
  checkmate::assert_number(rural_frac, lower = 1e-6, upper = 1 - 1e-6)
  checkmate::assert_number(wait_urban, lower = 1e-6)
  checkmate::assert_number(wait_rural, lower = 1e-6)
  checkmate::assert_number(phi, lower = 1e-6)
  checkmate::assert_number(state_icc, lower = 0, upper = 0.9 - 1e-9)
  checkmate::assert_count(n_states); checkmate::assert_true(n_states >= 2L)
  checkmate::assert_count(n_subspecs, positive = TRUE)
  checkmate::assert_count(n_extra_covars)
  checkmate::assert_number(alpha, lower = 1e-6, upper = 0.5)
  checkmate::assert_count(n_sim, positive = TRUE)

  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    stop("mysterycall_adjusted_power() requires the glmmTMB package.\n",
         "Install it with: install.packages(\"glmmTMB\")", call. = FALSE)
  }
  if (!is.null(seed)) set.seed(seed)

  # ICC -> state random-intercept SD on the log scale. Invert the *same*
  # latent-scale decomposition mysterycall_icc() uses, so a run requested at
  # state_icc simulates data whose measured ICC matches: for the NB model the
  # level-1 (residual) variance is trigamma(1 / phi) + pi^2 / 3, not 1 / phi.
  resid_var   <- .mysterycall_latent_dist_var(is_nb = TRUE, theta = phi)
  sigma_state <- sqrt(state_icc / (1 - state_icc) * resid_var)

  # Fixed design across replicates: power reflects outcome variability, not
  # design variability.
  rural   <- stats::rbinom(n_total, 1, rural_frac)
  state   <- sample.int(n_states, n_total, replace = TRUE)
  subspec <- if (n_subspecs >= 2L)
    sample.int(n_subspecs, n_total, replace = TRUE) else rep(1L, n_total)
  extra   <- if (n_extra_covars > 0L)
    matrix(stats::rbinom(n_total * n_extra_covars, 1, 0.5), nrow = n_total)
  else NULL

  subspec_eff <- if (n_subspecs >= 2L)
    c(0, stats::rnorm(n_subspecs - 1L, 0, 0.25)) else 0
  extra_eff <- if (n_extra_covars > 0L)
    stats::rnorm(n_extra_covars, 0, 0.08) else numeric(0)

  rhs <- "rural + (1 | state)"
  if (n_subspecs >= 2L) rhs <- "rural + subspec + (1 | state)"
  if (n_extra_covars > 0L) {
    ex <- paste(paste0("x", seq_len(n_extra_covars)), collapse = " + ")
    rhs <- if (n_subspecs >= 2L)
      sprintf("rural + subspec + %s + (1 | state)", ex)
    else sprintf("rural + %s + (1 | state)", ex)
  }
  form <- stats::as.formula(paste("y ~", rhs))

  one_rep <- function() {
    u_state <- stats::rnorm(n_states, 0, sigma_state)
    eta <- log(wait_urban) +
      ifelse(rural == 1, log(wait_rural / wait_urban), 0) +
      subspec_eff[subspec] + u_state[state]
    if (!is.null(extra)) eta <- eta + as.numeric(extra %*% extra_eff)
    y <- stats::rnbinom(n_total, mu = exp(eta), size = phi)

    dat <- data.frame(y = y, rural = rural,
                      state = factor(state), subspec = factor(subspec))
    if (!is.null(extra))
      for (k in seq_len(n_extra_covars)) dat[[paste0("x", k)]] <- extra[, k]

    fit <- suppressWarnings(tryCatch(
      glmmTMB::glmmTMB(form, family = glmmTMB::nbinom2, data = dat),
      error = function(e) NULL))
    if (is.null(fit)) return(c(est = NA_real_, se = NA_real_, p = NA_real_,
                               ok = 0))
    cf <- summary(fit)$coefficients$cond
    if (!"rural" %in% rownames(cf))
      return(c(est = NA_real_, se = NA_real_, p = NA_real_, ok = 1))
    c(est = cf["rural", "Estimate"], se = cf["rural", "Std. Error"],
      p = cf["rural", "Pr(>|z|)"], ok = 1)
  }

  flat <- do.call(rbind, lapply(seq_len(n_sim), function(i) one_rep()))

  tibble::tibble(
    n_total          = n_total,
    n_rural          = round(n_total * rural_frac),
    n_urban          = n_total - round(n_total * rural_frac),
    power            = mean(flat[, "p"] < alpha, na.rm = TRUE),
    mean_log_effect  = mean(flat[, "est"], na.rm = TRUE),
    mean_se          = mean(flat[, "se"], na.rm = TRUE),
    median_se        = stats::median(flat[, "se"], na.rm = TRUE),
    convergence_rate = mean(flat[, "ok"] == 1),
    state_icc        = state_icc,
    sigma_state      = sigma_state,
    n_states         = n_states,
    n_subspecs       = n_subspecs,
    n_extra_covars   = n_extra_covars,
    n_sim            = n_sim
  )
}
