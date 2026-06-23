#' Power curve for negative binomial GLMM mystery-caller studies
#'
#' @name power_curve
NULL

#' Plot power vs. physicians across IRR scenarios (NB GLMM)
#'
#' Runs [mysterycall_nb_power()] for every combination of `n_range` and
#' `irr_values`, collects the results, and returns a publication-ready
#' ggplot2 figure showing how power grows with sample size under each
#' IRR scenario.
#'
#' @param n_range Integer vector. Physician counts per group to evaluate.
#'   Default `seq(20, 100, by = 10)`.
#' @param irr_values Numeric vector. IRR scenarios to plot (e.g. `c(0.60,
#'   0.75, 0.80)`). Must all be positive. Default `c(0.60, 0.70, 0.75,
#'   0.80)`.
#' @param calls_per_physician Integer. Calls per physician. Default `2L`.
#' @param theta Numeric. NB dispersion parameter. Default `2.0`.
#' @param baseline_mean Numeric. Reference-group mean wait days. Default `21`.
#' @param sigma_u Numeric. SD of physician random intercept (log scale).
#'   Default `0.3`.
#' @param alpha Numeric. Type I error rate. Default `0.05`.
#' @param n_sim Integer. Monte Carlo simulations per cell. Default `500L`.
#'   Use `>= 1000` for publication.
#' @param seed Integer. Random seed passed to each [mysterycall_nb_power()]
#'   call. Default `42L`.
#' @param target_power Numeric in (0, 1). Dashed reference line position and
#'   threshold used to compute `$min_n`. Default `0.80`.
#' @param plot Logical. Whether to print the plot. Default `TRUE`.
#'
#' @return A list of class `mysterycall_power_curve` (returned invisibly):
#' \describe{
#'   \item{`plot`}{ggplot2 object.}
#'   \item{`data`}{Data frame with columns `n_physicians`, `irr_label`,
#'     `irr`, `power`, `ci_lower`, `ci_upper`.}
#'   \item{`min_n`}{Named numeric. Minimum N achieving `target_power` for
#'     each IRR scenario; `NA` when never achieved across `n_range`.}
#'   \item{`params`}{List of input parameters.}
#' }
#'
#' @family outcomes
#' @seealso [mysterycall_nb_power()] for the underlying simulation;
#'   [mysterycall_poisson_power()] for the Poisson variant.
#' @export
#'
#' @examplesIf requireNamespace("glmmTMB", quietly = TRUE) && requireNamespace("ggplot2", quietly = TRUE)
#' pc <- mysterycall_power_curve(
#'   n_range   = seq(20, 60, by = 20),
#'   irr_values = c(0.70, 0.80),
#'   n_sim     = 100L
#' )
mysterycall_power_curve <- function(n_range             = seq(20, 100, by = 10),
                                     irr_values          = c(0.60, 0.70, 0.75, 0.80),
                                     calls_per_physician = 2L,
                                     theta               = 2.0,
                                     baseline_mean       = 21,
                                     sigma_u             = 0.3,
                                     alpha               = 0.05,
                                     n_sim               = 500L,
                                     seed                = 42L,
                                     target_power        = 0.80,
                                     plot                = TRUE) {

  if (!requireNamespace("glmmTMB", quietly = TRUE))
    stop("Package 'glmmTMB' is required. Install with: install.packages('glmmTMB')",
         call. = FALSE)
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Package 'ggplot2' is required. Install with: install.packages('ggplot2')",
         call. = FALSE)

  if (!is.numeric(n_range) || length(n_range) == 0L || any(n_range < 2))
    stop("`n_range` must be a numeric vector of physician counts >= 2.", call. = FALSE)
  if (!is.numeric(irr_values) || length(irr_values) == 0L || any(irr_values <= 0))
    stop("`irr_values` must be a positive numeric vector.", call. = FALSE)
  if (!is.numeric(target_power) || length(target_power) != 1L ||
      target_power <= 0 || target_power >= 1)
    stop("`target_power` must be a single number in (0, 1).", call. = FALSE)

  rows <- vector("list", length(n_range) * length(irr_values))
  idx  <- 0L

  for (irr in irr_values) {
    irr_label <- paste0("IRR = ", irr)
    for (n in n_range) {
      idx <- idx + 1L
      message(sprintf("Simulating N = %d, IRR = %.2f ...", as.integer(n), irr))
      res <- mysterycall_nb_power(
        n_physicians        = as.integer(n),
        calls_per_physician = as.integer(calls_per_physician),
        irr                 = irr,
        theta               = theta,
        baseline_mean       = baseline_mean,
        sigma_u             = sigma_u,
        alpha               = alpha,
        n_sim               = as.integer(n_sim),
        seed                = seed
      )
      rows[[idx]] <- data.frame(
        n_physicians = as.integer(n),
        irr_label    = irr_label,
        irr          = irr,
        power        = res$power,
        ci_lower     = res$ci[1L],
        ci_upper     = res$ci[2L],
        stringsAsFactors = FALSE
      )
    }
  }

  dat <- do.call(rbind, rows)

  min_n <- vapply(irr_values, function(irr) {
    sub <- dat[dat$irr == irr & !is.na(dat$power), ]
    hits <- sub$n_physicians[sub$power >= target_power]
    if (length(hits)) min(hits) else NA_real_
  }, numeric(1L))
  names(min_n) <- paste0("IRR = ", irr_values)

  p <- ggplot2::ggplot(
    dat,
    ggplot2::aes(
      x      = n_physicians,
      y      = power,
      colour = irr_label,
      fill   = irr_label,
      group  = irr_label
    )
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = ci_lower, ymax = ci_upper),
      alpha  = 0.15,
      colour = NA
    ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 2) +
    ggplot2::geom_hline(
      yintercept = target_power,
      linetype   = "dashed",
      colour     = "grey40"
    ) +
    ggplot2::annotate(
      "text",
      x      = max(n_range),
      y      = target_power + 0.03,
      label  = paste0("Target (", round(target_power * 100), "%)"),
      hjust  = 1,
      size   = 3,
      colour = "grey40"
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 1),
      labels = scales::percent_format(accuracy = 1)
    ) +
    ggplot2::scale_x_continuous(breaks = n_range) +
    ggplot2::labs(
      title   = "Power Curve: Negative Binomial GLMM",
      x       = "Physicians per group (N)",
      y       = "Power (1 − β)",
      colour  = NULL,
      fill    = NULL,
      caption = sprintf(
        "theta = %.1f, baseline mean = %.0f days, sigma_u = %.2f, alpha = %.2f, %d simulations per cell",
        theta, baseline_mean, sigma_u, alpha, as.integer(n_sim)
      )
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "bottom")

  if (isTRUE(plot)) print(p)

  out <- structure(
    list(
      plot   = p,
      data   = dat,
      min_n  = min_n,
      params = list(
        n_range             = n_range,
        irr_values          = irr_values,
        calls_per_physician = calls_per_physician,
        theta               = theta,
        baseline_mean       = baseline_mean,
        sigma_u             = sigma_u,
        alpha               = alpha,
        n_sim               = n_sim,
        seed                = seed,
        target_power        = target_power
      )
    ),
    class = "mysterycall_power_curve"
  )

  invisible(out)
}


#' Print method for mysterycall_power_curve
#'
#' @param x A `mysterycall_power_curve` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_power_curve <- function(x, ...) {
  cat("Power Curve — Minimum N to reach target power\n")
  cat(sprintf("Target power: %.0f%%\n\n", x$params$target_power * 100))
  mn <- x$min_n
  for (nm in names(mn)) {
    val <- mn[[nm]]
    cat(sprintf("  %-14s  %s\n", nm,
                if (is.na(val)) "never achieved in n_range" else paste0("N = ", val)))
  }
  cat("\n")
  print(x$plot)
  invisible(x)
}
