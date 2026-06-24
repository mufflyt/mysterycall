#' Residual diagnostic plots for a fitted model
#'
#' @name mysterycall_plot_residuals
NULL

#' Residual diagnostic plots for a fitted count model
#'
#' When DHARMa is installed (recommended), uses randomized quantile residuals
#' via [DHARMa::simulateResiduals()] - the current gold standard for diagnosing
#' GLMMs. Falls back to Pearson residual ggplot2 panels when DHARMa is
#' unavailable or `use_dharma = FALSE`.
#'
#' @param model A `mysterycall_poisson_model` or `mysterycall_nb_model` result,
#'   or a bare `glm`, `glmerMod`, `glmmTMB`, or `lm` object.
#' @param use_dharma Logical. When `TRUE` (default) and DHARMa is installed,
#'   uses [DHARMa::simulateResiduals()] for residual diagnostics. Set to
#'   `FALSE` to force the Pearson residual ggplot2 panels.
#' @param n_sim Integer. Number of simulations passed to
#'   [DHARMa::simulateResiduals()]. Higher values give smoother distributions
#'   at the cost of time. Default `250L`.
#' @param plot Logical. When `TRUE` (default), draws the DHARMa diagnostic
#'   plot to the active graphics device. Ignored on the Pearson path (those
#'   plots are always returned, never auto-drawn).
#' @param ... Additional arguments forwarded to [DHARMa::simulateResiduals()]
#'   (DHARMa path only).
#'
#' @return **DHARMa path** (`use_dharma = TRUE` and DHARMa installed):
#'   Returns the `DHARMaResiduals` simulation object invisibly. Pass it to
#'   [DHARMa::testZeroInflation()], [DHARMa::testDispersion()], or
#'   [DHARMa::testTemporalAutocorrelation()] for targeted diagnostics.
#'
#'   **Pearson path** (`use_dharma = FALSE` or DHARMa not installed):
#'   Returns a named list of three `ggplot` objects:
#'   \describe{
#'     \item{`residuals_vs_fitted`}{Pearson residuals vs. fitted values.}
#'     \item{`qq`}{Normal Q-Q plot of Pearson residuals.}
#'     \item{`scale_location`}{Scale-location (spread-location) plot.}
#'   }
#'
#' @seealso [DHARMa::simulateResiduals()] for the simulation engine;
#'   [mysterycall_check_zero_inflation()] for a targeted zero-inflation test;
#'   [mysterycall_poisson_model()] / [mysterycall_nb_model()] to fit the model;
#'   [mysterycall_save_plot()] to write Pearson-path plots to disk.
#' @family outcomes
#' @importFrom graphics plot
#' @export
#'
#' @examples
#' # Pearson path (no DHARMa needed)
#' m <- glm(mpg ~ wt, data = mtcars, family = gaussian())
#' plots <- mysterycall_plot_residuals(m, use_dharma = FALSE)
#' plots$qq
mysterycall_plot_residuals <- function(model,
                                       use_dharma = TRUE,
                                       n_sim      = 250L,
                                       plot       = TRUE,
                                       ...) {
  # -- Unwrap package wrapper objects ------------------------------------------
  if (inherits(model, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    fit <- model$model
  } else if (inherits(model, c("glmerMod", "glmmTMB", "glm", "lm"))) {
    fit <- model
  } else {
    stop(
      "`model` must be a `mysterycall_poisson_model`, `mysterycall_nb_model`, glm, glmerMod, glmmTMB, or lm object.",
      call. = FALSE
    )
  }

  # -- Decide which path to take -----------------------------------------------
  use_dharma_actual <- isTRUE(use_dharma) && requireNamespace("DHARMa", quietly = TRUE)

  if (isTRUE(use_dharma) && !use_dharma_actual) {
    message(
      "DHARMa not installed; falling back to Pearson residual plots. ",
      "Install with: install.packages('DHARMa')"
    )
  }

  # -- DHARMa path -------------------------------------------------------------
  if (use_dharma_actual) {
    sim <- DHARMa::simulateResiduals(fittedModel = fit, n = as.integer(n_sim), ...)
    if (isTRUE(plot)) {
      graphics::plot(sim)
    }
    return(invisible(sim))
  }

  # -- Pearson / ggplot2 path --------------------------------------------------
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required for the Pearson residual plots.", call. = FALSE)
  }

  fitted_vals    <- as.numeric(fitted(fit))
  resid_vals     <- as.numeric(residuals(fit, type = "pearson"))
  sqrt_abs_resid <- sqrt(abs(resid_vals))

  df_plot <- data.frame(
    fitted         = fitted_vals,
    residuals      = resid_vals,
    sqrt_abs_resid = sqrt_abs_resid
  )

  p1 <- ggplot2::ggplot(df_plot, ggplot2::aes(x = fitted, y = residuals)) +
    ggplot2::geom_point(alpha = 0.5) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    ggplot2::labs(
      title = "Residuals vs Fitted",
      x     = "Fitted values",
      y     = "Pearson residuals"
    ) +
    ggplot2::theme_minimal()

  p2 <- ggplot2::ggplot(df_plot, ggplot2::aes(sample = residuals)) +
    ggplot2::stat_qq() +
    ggplot2::stat_qq_line(color = "red") +
    ggplot2::labs(
      title = "Normal Q-Q",
      x     = "Theoretical quantiles",
      y     = "Sample quantiles"
    ) +
    ggplot2::theme_minimal()

  p3 <- ggplot2::ggplot(df_plot, ggplot2::aes(x = fitted, y = sqrt_abs_resid)) +
    ggplot2::geom_point(alpha = 0.5) +
    ggplot2::geom_smooth(method = "loess", se = FALSE, color = "red",
                         formula = y ~ x) +
    ggplot2::labs(
      title = "Scale-Location",
      x     = "Fitted values",
      y     = "sqrt(|Pearson residuals|)"
    ) +
    ggplot2::theme_minimal()

  list(residuals_vs_fitted = p1, qq = p2, scale_location = p3)
}
