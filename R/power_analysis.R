#' Power and sample-size tools for mystery caller studies
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name mysterycall_power
NULL


#' Cochran finite-population sample size
#'
#' Calculates the number of providers to sample from a known directory of `N`
#' providers so that the estimated proportion (e.g. acceptance rate) is within
#' `margin_of_error` with 95% confidence. This is the standard Cochran (1977)
#' formula used in mystery caller audit studies to determine how many physicians
#' to call from a specialty directory.
#'
#' The formula is: `n = N / (1 + N * e^2)` where `e` is the margin of error.
#'
#' @param N Integer or numeric. Total number of providers in the sampling frame
#'   (e.g. size of the specialty directory).
#' @param margin_of_error Numeric scalar in (0, 1). Desired margin of error for
#'   proportions. Default `0.05` (+/-5 percentage points).
#'
#' @return A named list with elements:
#' \describe{
#'   \item{`n`}{Required sample size (rounded up to the nearest integer).}
#'   \item{`N`}{Input population size.}
#'   \item{`margin_of_error`}{Input margin of error.}
#'   \item{`effective_margin`}{Achieved margin of error at the returned `n`.}
#' }
#'
#' @references Cochran, W. G. (1977). *Sampling Techniques* (3rd ed.). Wiley.
#'
#' @family power analysis
#' @seealso [mysterycall_poisson_power()]
#' @export
#'
#' @examples
#' # 369 pediatric otolaryngologists in the directory
#' mysterycall_cochran_n(N = 369)   # ~= 192
#'
#' # 215 neurotologists in the directory
#' mysterycall_cochran_n(N = 215)   # ~= 140
mysterycall_cochran_n <- function(N, margin_of_error = 0.05) {

  if (!is.numeric(N) || length(N) != 1L || N < 1L) {
    stop("`N` must be a single positive number.", call. = FALSE)
  }
  if (!is.numeric(margin_of_error) || length(margin_of_error) != 1L ||
      margin_of_error <= 0 || margin_of_error >= 1) {
    stop("`margin_of_error` must be a single number strictly between 0 and 1.", call. = FALSE)
  }

  n_raw <- N / (1 + N * margin_of_error^2)
  n     <- as.integer(ceiling(n_raw))

  list(
    n                = n,
    N                = N,
    margin_of_error  = margin_of_error,
    effective_margin = sqrt(N / n - 1) / sqrt(N)
  )
}


#' Sample-size calculation for a Poisson mystery caller study
#'
#' Computes the number of providers per insurance arm needed to detect a
#' specified Incidence Rate Ratio (IRR) in a mystery caller study with a
#' Poisson count outcome (e.g. business days until appointment). Each provider
#' is called once per insurance arm.
#'
#' The sample-size formula is derived from the score test for comparing two
#' independent Poisson rates \eqn{\lambda_0} (reference arm, e.g. BCBS) and
#' \eqn{\lambda_1 = \text{IRR} \times \lambda_0} (treatment arm, e.g. Medicaid):
#'
#' \deqn{n = \frac{(z_{\alpha/2} + z_\beta)^2 \left(\frac{1}{\lambda_0} + \frac{1}{\lambda_1}\right)}{(\log \text{IRR})^2}}
#'
#' This gives providers per arm. Total providers = `n * 2`. When each provider
#' is called with both insurance types (`both_arms = TRUE`), only `n` providers
#' are needed in total.
#'
#' @param irr Numeric. The minimum detectable incidence rate ratio. Must be
#'   positive and not equal to 1.
#' @param lambda_ref Numeric. Expected mean wait time (days) for the reference
#'   insurance group (e.g. BCBS). Must be positive.
#' @param alpha Numeric. Two-sided type I error rate. Default `0.05`.
#' @param power Numeric. Desired statistical power (1 - beta). Default `0.80`.
#' @param both_arms Logical. When `TRUE`, each provider is called with **both**
#'   insurance types (paired design), halving the total providers needed.
#'   Default `TRUE`.
#' @param icc Numeric in [0, 1). Intra-cluster correlation if providers are
#'   clustered (e.g. same practice). Applied as a design-effect inflation:
#'   `n * (1 + (m - 1) * icc)` where `m` is `calls_per_cluster`. Default `0`
#'   (no clustering adjustment).
#' @param calls_per_cluster Integer. Average calls per cluster, used only when
#'   `icc > 0`. Default `2L`.
#'
#' @return A named list with elements:
#' \describe{
#'   \item{`n_per_arm`}{Providers needed per insurance arm.}
#'   \item{`n_total`}{Total providers needed.}
#'   \item{`n_total_calls`}{Total calls placed (= `n_per_arm * 2` or
#'     `n_total * 2` for paired design).}
#'   \item{`irr`, `lambda_ref`, `lambda_trt`}{Input parameters plus derived
#'     treatment-arm mean.}
#'   \item{`alpha`, `power`}{Input parameters.}
#'   \item{`design_effect`}{Inflation factor when `icc > 0`.}
#' }
#'
#' @family power analysis
#' @seealso [mysterycall_cochran_n()], [mysterycall_poisson_model()]
#' @export
#'
#' @examples
#' # Detect IRR = 1.40 (Medicaid 40% longer waits) vs BCBS mean of 14 days
#' mysterycall_poisson_power(irr = 1.40, lambda_ref = 14)
#'
#' # Higher power
#' mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, power = 0.90)
#'
#' # Smaller effect (IRR = 1.20)
#' mysterycall_poisson_power(irr = 1.20, lambda_ref = 14)
mysterycall_poisson_power <- function(irr,
                                       lambda_ref,
                                       alpha             = 0.05,
                                       power             = 0.80,
                                       both_arms         = TRUE,
                                       icc               = 0,
                                       calls_per_cluster = 2L) {

  if (!is.numeric(irr) || length(irr) != 1L || irr <= 0 || irr == 1) {
    stop("`irr` must be a single positive number not equal to 1.", call. = FALSE)
  }
  if (!is.numeric(lambda_ref) || length(lambda_ref) != 1L || lambda_ref <= 0) {
    stop("`lambda_ref` must be a single positive number.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be a single number in (0, 1).", call. = FALSE)
  }
  if (!is.numeric(power) || length(power) != 1L || power <= 0 || power >= 1) {
    stop("`power` must be a single number in (0, 1).", call. = FALSE)
  }
  if (!is.numeric(icc) || length(icc) != 1L || icc < 0 || icc >= 1) {
    stop("`icc` must be a single number in [0, 1).", call. = FALSE)
  }

  lambda_trt <- irr * lambda_ref

  z_alpha <- stats::qnorm(1 - alpha / 2)
  z_beta  <- stats::qnorm(power)

  # Score-test formula for two Poisson rates
  n_per_arm_raw <- ((z_alpha + z_beta)^2 * (1 / lambda_ref + 1 / lambda_trt)) /
                    (log(irr))^2

  # Design effect for clustering
  design_effect <- 1
  if (icc > 0) {
    design_effect <- 1 + (calls_per_cluster - 1) * icc
    n_per_arm_raw <- n_per_arm_raw * design_effect
  }

  n_per_arm <- ceiling(n_per_arm_raw)

  if (both_arms) {
    n_total       <- n_per_arm
    n_total_calls <- n_total * 2L
  } else {
    n_total       <- n_per_arm * 2L
    # Unpaired design = one call per provider, so calls == providers. (The
    # paired both_arms branch is what makes two calls per provider.)
    n_total_calls <- n_total
  }

  message(sprintf(
    "Poisson power: IRR=%.2f, lambda_ref=%.1f, lambda_trt=%.1f | n_per_arm=%d, n_total=%d, calls=%d",
    irr, lambda_ref, lambda_trt, n_per_arm, n_total, n_total_calls
  ))

  list(
    n_per_arm      = as.integer(n_per_arm),
    n_total        = as.integer(n_total),
    n_total_calls  = as.integer(n_total_calls),
    irr            = irr,
    lambda_ref     = lambda_ref,
    lambda_trt     = lambda_trt,
    alpha          = alpha,
    power          = power,
    design_effect  = design_effect
  )
}


#' Poisson power curve: required sample size across a range of IRRs
#'
#' Calls [mysterycall_poisson_power()] across a range of incidence rate
#' ratios and returns a ggplot2 line chart showing how the required sample
#' size per arm changes with effect size. Useful as Figure 1 in a
#' mystery-caller manuscript.
#'
#' @param lambda0 Numeric. Baseline expected count in the reference arm
#'   (e.g. mean business days for the reference insurance). Default `14`.
#' @param irr_seq Numeric vector of IRR values to evaluate. Default
#'   `seq(1.10, 2.0, by = 0.05)`.
#' @param alpha Numeric. Two-sided type I error rate. Default `0.05`.
#' @param power Numeric. Desired statistical power. Default `0.80`.
#' @param both_arms Logical. If `TRUE` (default), each arm receives `n`
#'   patients; the total study size is `2n`.
#'
#' @return A `ggplot` object. The x-axis is IRR, the y-axis is
#'   required sample size per arm, and a vertical dashed line marks
#'   IRR = 1 (no effect).
#'
#' @family power analysis
#' @export
#'
#' @examples
#' mysterycall_equation_figure(lambda0 = 14, irr_seq = seq(1.1, 1.8, 0.1))
mysterycall_equation_figure <- function(lambda0   = 14,
                                         irr_seq   = seq(1.10, 2.0, by = 0.05),
                                         alpha     = 0.05,
                                         power     = 0.80,
                                         both_arms = TRUE) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop(
      "This function requires the ggplot2 package.\n",
      "Install it with: install.packages(\"ggplot2\")",
      call. = FALSE
    )
  }
  if (!is.numeric(irr_seq) || length(irr_seq) < 2L) {
    stop("`irr_seq` must be a numeric vector with at least 2 values.", call. = FALSE)
  }
  irr_seq <- irr_seq[irr_seq > 0 & irr_seq != 1]

  ns <- vapply(irr_seq, function(irr) {
    tryCatch(
      mysterycall_poisson_power(irr, lambda0, alpha = alpha,
                                power = power, both_arms = both_arms)$n_per_arm,
      error = function(e) NA_real_
    )
  }, numeric(1L))

  df <- data.frame(irr = irr_seq, n_per_arm = ns)
  df <- df[!is.na(df$n_per_arm), ]

  ggplot2::ggplot(df, ggplot2::aes(x = irr, y = n_per_arm)) +
    ggplot2::geom_line(linewidth = 1, color = "#2C3E50") +
    ggplot2::geom_point(size = 2, color = "#2C3E50") +
    ggplot2::labs(
      title = sprintf(
        "Required sample size (lambda0 = %g, alpha = %.2f, power = %.0f%%)",
        lambda0, alpha, power * 100
      ),
      x = "Incidence Rate Ratio (IRR)",
      y = "Required sample size per arm"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(plot.title = ggplot2::element_text(size = 11))
}


#' Clustered binary power and sample-size calculator (GLMM / VIF approach)
#'
#' Computes the required sample size or achieved power for a two-group binary
#' outcome in a clustered mystery-caller study using the variance inflation
#' factor (VIF) approach for clustered binary data (Donner & Klar 2000). This
#' is the appropriate correction when multiple calls are placed to the same
#' physician (cluster), inducing within-cluster correlation that inflates
#' effective sample-size requirements relative to an independence assumption.
#'
#' The unadjusted sample size per group (\eqn{n_{\text{simple}}}) comes from
#' the standard unpooled two-proportion \eqn{z}-test:
#'
#' \deqn{n_{\text{simple}} = \frac{(z_{\alpha/2} + z_{\beta})^2
#'   [p_1(1-p_1) + p_2(1-p_2)]}{(p_1 - p_2)^2}}
#'
#' The clustering adjustment uses the variance inflation factor:
#'
#' \deqn{\text{VIF} = 1 + (m - 1)\,\rho}
#'
#' where \eqn{m} is the average cluster size (calls per physician) and
#' \eqn{\rho} is the intraclass correlation (ICC). The adjusted sample size is:
#'
#' \deqn{n_{\text{adjusted}} = \lceil n_{\text{simple}} \times \text{VIF} \rceil}
#'
#' When \code{n} is supplied instead of leaving it \code{NULL}, the function
#' back-calculates the achieved power at that \code{n} (treated as
#' \eqn{n_{\text{simple}}, before clustering).
#'
#' @param p1 Numeric. Baseline acceptance probability for the reference group
#'   (e.g. commercial insurance). Must be in (0, 1). Default \code{0.70}.
#' @param p2 Numeric or \code{NULL}. Expected acceptance probability for the
#'   comparison group (e.g. Medicaid). Must be in (0, 1) and differ from
#'   \code{p1}. If \code{NULL}, power is back-calculated from \code{n};
#'   \code{n} must then be provided. Either \code{p2} or \code{n} must be
#'   non-\code{NULL}.
#' @param n Integer or \code{NULL}. Known simple (unclustered) sample size per
#'   group. If \code{NULL}, \eqn{n} is solved from \code{p1}, \code{p2},
#'   \code{alpha}, and \code{power}. Either \code{p2} or \code{n} must be
#'   non-\code{NULL}.
#' @param icc Numeric. Intraclass correlation coefficient capturing
#'   within-physician clustering. Must be in \eqn{[0, 1)}. Default \code{0.05}.
#' @param m Numeric. Average number of mystery calls placed per physician
#'   (cluster size). Must be \eqn{\geq 1}. Default \code{4}.
#' @param alpha Numeric. Two-sided significance level. Must be in (0, 1).
#'   Default \code{0.05}.
#' @param power Numeric. Desired statistical power (1 - beta) when solving for
#'   \code{n}. Must be in (0, 1). Default \code{0.80}. Ignored when \code{n}
#'   is supplied; achieved power is returned in that case.
#'
#' @return A named list with elements:
#' \describe{
#'   \item{\code{n_simple}}{Unadjusted sample size per group from the
#'     two-proportion \eqn{z}-test (integer).}
#'   \item{\code{n_adjusted}}{Clustering-adjusted sample size per group,
#'     \eqn{\lceil n_{\text{simple}} \times \text{VIF} \rceil} (integer).}
#'   \item{\code{vif}}{Variance inflation factor \eqn{1 + (m - 1)\,\rho}.}
#'   \item{\code{p1}}{Input baseline acceptance probability.}
#'   \item{\code{p2}}{Input comparison acceptance probability (or \code{NULL}).}
#'   \item{\code{alpha}}{Input significance level.}
#'   \item{\code{power}}{Achieved power at the returned \code{n_simple}. When
#'     solving for \code{n}, this reflects the power at the ceiling-rounded
#'     \code{n_simple} and will be \eqn{\geq} the requested power. When
#'     \code{n} is supplied directly, this is the back-calculated power.}
#'   \item{\code{icc}}{Input intraclass correlation.}
#'   \item{\code{m}}{Input average cluster size.}
#'   \item{\code{message}}{A character string suitable for a manuscript methods
#'     section summarising the key design parameters and result.}
#' }
#'
#' @references Donner A, Klar N (2000). \emph{Design and Analysis of Cluster
#'   Randomization Trials in Health Research}. Arnold: London.
#'
#' @family power analysis
#' @seealso [mysterycall_cochran_n()], [mysterycall_poisson_power()]
#' @export
#'
#' @examples
#' # Solve for n: Medicaid acceptance (p2 = 0.50) vs commercial (p1 = 0.70)
#' mysterycall_power_calc(p1 = 0.70, p2 = 0.50)
#'
#' # Larger ICC and more calls per physician inflate the adjusted n
#' mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0.15, m = 6)
#'
#' # 90% power and a smaller effect require a larger sample
#' mysterycall_power_calc(p1 = 0.70, p2 = 0.55, power = 0.90)
#'
#' # Back-calculate power for a fixed simple n of 100 per group
#' mysterycall_power_calc(p1 = 0.70, p2 = 0.50, n = 100)
mysterycall_power_calc <- function(p1    = 0.70,
                                   p2    = NULL,
                                   n     = NULL,
                                   icc   = 0.05,
                                   m     = 4,
                                   alpha = 0.05,
                                   power = 0.80) {

  # ---- input validation -------------------------------------------------------
  if (!is.numeric(p1) || length(p1) != 1L || p1 <= 0 || p1 >= 1) {
    stop("`p1` must be a single number in (0, 1).", call. = FALSE)
  }
  if (!is.null(p2)) {
    if (!is.numeric(p2) || length(p2) != 1L || p2 <= 0 || p2 >= 1) {
      stop("`p2` must be a single number in (0, 1) or NULL.", call. = FALSE)
    }
    if (isTRUE(all.equal(p1, p2))) {
      stop("`p1` and `p2` must differ.", call. = FALSE)
    }
  }
  if (!is.null(n)) {
    if (!is.numeric(n) || length(n) != 1L || n < 1) {
      stop("`n` must be a single positive number or NULL.", call. = FALSE)
    }
  }
  if (is.null(p2) && is.null(n)) {
    stop("Either `p2` or `n` must be non-NULL.", call. = FALSE)
  }
  if (is.null(p2) && !is.null(n)) {
    stop(
      "`p2` must be provided to compute power; only `n` was supplied.",
      call. = FALSE
    )
  }
  if (!is.numeric(icc) || length(icc) != 1L || icc < 0 || icc >= 1) {
    stop("`icc` must be a single number in [0, 1).", call. = FALSE)
  }
  if (!is.numeric(m) || length(m) != 1L || m < 1) {
    stop("`m` must be a single number >= 1.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be a single number in (0, 1).", call. = FALSE)
  }
  if (!is.numeric(power) || length(power) != 1L || power <= 0 || power >= 1) {
    stop("`power` must be a single number in (0, 1).", call. = FALSE)
  }

  # ---- core computation -------------------------------------------------------
  vif        <- 1 + (m - 1) * icc
  z_a2       <- stats::qnorm(1 - alpha / 2)
  pooled_var <- p1 * (1 - p1) + p2 * (1 - p2)
  delta_sq   <- (p1 - p2)^2

  if (is.null(n)) {
    # Mode 1: solve for n given p1, p2, alpha, power -------------------------
    z_b      <- stats::qnorm(power)
    n_simple <- ceiling((z_a2 + z_b)^2 * pooled_var / delta_sq)
    n_adj    <- ceiling(n_simple * vif)
    # Back-calculate achieved power at the ceiling-rounded n_simple
    achieved_power <- stats::pnorm(
      sqrt(n_simple * delta_sq / pooled_var) - z_a2
    )
  } else {
    # Mode 2: back-calculate power for the provided n (treated as n_simple) --
    n_simple <- as.integer(ceiling(n))
    n_adj    <- ceiling(n_simple * vif)
    achieved_power <- stats::pnorm(
      sqrt(n_simple * delta_sq / pooled_var) - z_a2
    )
  }

  # ---- methods-section sentence -----------------------------------------------
  msg <- sprintf(
    paste0(
      "Assuming an acceptance probability of %.0f%% in the reference group and ",
      "%.0f%% in the comparison group, with an intraclass correlation of %.3f ",
      "and an average of %.1f calls per physician (VIF = %.3f), ",
      "%d participants per group are required before clustering adjustment and ",
      "%d per group after adjustment, yielding %.1f%% power at a ",
      "two-sided alpha of %.3f (Donner & Klar 2000)."
    ),
    p1 * 100, p2 * 100, icc, m, vif,
    as.integer(n_simple), as.integer(n_adj),
    achieved_power * 100, alpha
  )

  message(sprintf(
    "mysterycall_power_calc: n_simple=%d, n_adjusted=%d, VIF=%.3f, power=%.1f%%",
    as.integer(n_simple), as.integer(n_adj), vif, achieved_power * 100
  ))

  list(
    n_simple   = as.integer(n_simple),
    n_adjusted = as.integer(n_adj),
    vif        = vif,
    p1         = p1,
    p2         = p2,
    alpha      = alpha,
    power      = achieved_power,
    icc        = icc,
    m          = m,
    message    = msg
  )
}
