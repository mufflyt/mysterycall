#' Simulate power for a negative binomial mixed model
#'
#' Estimates statistical power to detect a target incidence rate ratio (IRR)
#' in a two-group mystery-caller study using a multilevel negative binomial
#' model with physician random intercepts. Uses Monte Carlo simulation because
#' closed-form power formulas for NB GLMMs require unrealistic approximations.
#'
#' @param n_physicians Integer. Number of physicians (clusters) per group.
#' @param calls_per_physician Integer. Number of mystery calls per physician.
#'   Default `2L` (one Medicaid, one reference insurance).
#' @param irr Numeric. The IRR to detect (e.g. `0.75` means 25% fewer days for
#'   the intervention group). Must be positive.
#' @param theta Numeric. Negative binomial dispersion parameter. Higher values
#'   mean less overdispersion (Poisson is the limit as theta -> Inf). Use the
#'   `$theta` from a pilot `mysterycall_nb_model()` fit, or a literature-based
#'   estimate. Default `2.0` (moderate overdispersion typical of wait-time data).
#' @param baseline_mean Numeric. Expected mean wait days in the reference group.
#'   Default `21` (three weeks).
#' @param sigma_u Numeric. Standard deviation of the physician-level random
#'   intercept (on the log scale). Default `0.3` (typical for specialty scheduling).
#' @param alpha Numeric. Type I error rate. Default `0.05`.
#' @param n_sim Integer. Number of Monte Carlo simulations. Default `1000L`.
#'   Use at least `500` for stable estimates; `2000` for publication.
#' @param seed Integer or `NULL`. Random seed for reproducibility. Default `42L`.
#'
#' @return A list of class `mysterycall_nb_power` with elements:
#' \describe{
#'   \item{`power`}{Numeric. Estimated power (proportion of simulations with p < alpha).}
#'   \item{`n_physicians`}{Integer. Physicians per group.}
#'   \item{`total_n`}{Integer. Total observations (2 x n_physicians x calls_per_physician).}
#'   \item{`irr`}{Numeric. Target IRR.}
#'   \item{`theta`}{Numeric. Dispersion parameter used.}
#'   \item{`alpha`}{Numeric. Type I error rate used.}
#'   \item{`n_sim`}{Integer. Number of simulations run.}
#'   \item{`ci`}{Numeric vector length 2. 95% Wilson CI around the power estimate.}
#' }
#'
#' @section Choosing theta:
#' If you have pilot data, fit `mysterycall_nb_model()` and use `result$theta`.
#' Without pilot data, use `theta = 1` (high overdispersion, conservative) to
#' `theta = 5` (mild overdispersion). Smaller theta -> lower power -> larger required N.
#'
#' @family outcomes
#' @seealso [mysterycall_nb_model()] for fitting the NB model;
#'   [mysterycall_poisson_power()] for the Poisson power calculation.
#' @export
#'
#' @examples
#' # Detect a 25% reduction (IRR = 0.75) with 36 physicians per group
#' result <- mysterycall_nb_power(
#'   n_physicians = 36L,
#'   irr          = 0.75,
#'   theta        = 2.0,
#'   n_sim        = 200L   # use >= 1000 for real analyses
#' )
#' print(result)
mysterycall_nb_power <- function(n_physicians,
                                  calls_per_physician = 2L,
                                  irr                 = 0.75,
                                  theta               = 2.0,
                                  baseline_mean       = 21,
                                  sigma_u             = 0.3,
                                  alpha               = 0.05,
                                  n_sim               = 1000L,
                                  seed                = 42L) {

  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    stop("Package 'glmmTMB' is required. Install with: install.packages('glmmTMB')", call. = FALSE)
  }

  stopifnot(
    is.numeric(n_physicians), n_physicians >= 2,
    is.numeric(irr), irr > 0,
    is.numeric(theta), theta > 0,
    is.numeric(baseline_mean), baseline_mean > 0,
    is.numeric(sigma_u), sigma_u >= 0,
    is.numeric(alpha), alpha > 0, alpha < 1,
    is.numeric(n_sim), n_sim >= 10
  )

  n_physicians        <- as.integer(n_physicians)
  calls_per_physician <- as.integer(calls_per_physician)
  n_sim               <- as.integer(n_sim)

  if (!is.null(seed)) set.seed(seed)

  log_baseline <- log(baseline_mean)
  log_irr      <- log(irr)
  sig_count    <- 0L
  n_per_group  <- n_physicians * calls_per_physician

  for (i in seq_len(n_sim)) {
    u_ref <- stats::rnorm(n_physicians, 0, sigma_u)
    u_trt <- stats::rnorm(n_physicians, 0, sigma_u)

    mu_ref <- exp(log_baseline + rep(u_ref, each = calls_per_physician))
    y_ref  <- stats::rnbinom(n_per_group, mu = mu_ref, size = theta)

    mu_trt <- exp(log_baseline + log_irr + rep(u_trt, each = calls_per_physician))
    y_trt  <- stats::rnbinom(n_per_group, mu = mu_trt, size = theta)

    sim_data <- data.frame(
      y    = c(y_ref, y_trt),
      ins  = rep(c("ref", "trt"), each = n_per_group),
      phys = c(
        rep(paste0("R", seq_len(n_physicians)), each = calls_per_physician),
        rep(paste0("T", seq_len(n_physicians)), each = calls_per_physician)
      ),
      stringsAsFactors = FALSE
    )

    fit <- tryCatch(
      suppressWarnings(suppressMessages(
        glmmTMB::glmmTMB(y ~ ins + (1 | phys),
                         data   = sim_data,
                         family = glmmTMB::nbinom2(link = "log"),
                         REML   = FALSE)
      )),
      error = function(e) NULL
    )

    if (!is.null(fit)) {
      p_val <- tryCatch({
        coefs <- coef(summary(fit))$cond
        coefs["instrt", "Pr(>|z|)"]
      }, error = function(e) NA_real_)

      if (!is.na(p_val) && p_val < alpha) {
        sig_count <- sig_count + 1L
      }
    }
  }

  power_est <- sig_count / n_sim

  z95    <- stats::qnorm(0.975)
  denom  <- n_sim + z95^2
  centre <- (sig_count + z95^2 / 2) / denom
  half   <- z95 * sqrt(sig_count * (n_sim - sig_count) / n_sim + z95^2 / 4) / denom
  ci     <- pmax(0, pmin(1, c(centre - half, centre + half)))

  structure(
    list(
      power        = power_est,
      n_physicians = n_physicians,
      total_n      = 2L * n_per_group,
      irr          = irr,
      theta        = theta,
      alpha        = alpha,
      n_sim        = n_sim,
      ci           = ci
    ),
    class = "mysterycall_nb_power"
  )
}

#' Print method for mysterycall_nb_power
#'
#' @param x A `mysterycall_nb_power` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_nb_power <- function(x, ...) {
  cat(sprintf(
    "NB Power Analysis\n  Physicians/group: %d  Total N: %d  Target IRR: %.2f  theta: %.2f\n",
    x$n_physicians, x$total_n, x$irr, x$theta
  ))
  cat(sprintf(
    "  Estimated power: %.1f%%  (95%% CI: %.1f%%-%.1f%%)  [%d simulations, alpha=%.3f]\n",
    x$power * 100, x$ci[1] * 100, x$ci[2] * 100, x$n_sim, x$alpha
  ))
  invisible(x)
}
