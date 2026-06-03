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
  n     <- ceiling(n_raw)

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
    n_total_calls <- n_total * 2L
  }

  message(sprintf(
    "Poisson power: IRR=%.2f, lambda_ref=%.1f, lambda_trt=%.1f | n_per_arm=%d, n_total=%d, calls=%d",
    irr, lambda_ref, lambda_trt, n_per_arm, n_total, n_total_calls
  ))

  list(
    n_per_arm      = n_per_arm,
    n_total        = n_total,
    n_total_calls  = n_total_calls,
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
    stop("ggplot2 is required.", call. = FALSE)
  }
  if (!is.numeric(irr_seq) || length(irr_seq) < 1L) {
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
