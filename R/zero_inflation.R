#' Test for zero-inflation in a fitted count model
#'
#' Uses [DHARMa::testZeroInflation()] to assess whether the observed count of
#' zeros in the outcome is higher than expected under the fitted distribution.
#' Applicable to both [mysterycall_poisson_model()] and [mysterycall_nb_model()]
#' objects.
#'
#' A significant result (p < 0.05) means the model predicts fewer zeros than
#' observed --- consider a zero-inflated Poisson or zero-inflated negative
#' binomial model (e.g. [glmmTMB::glmmTMB()] with `ziformula = ~1`).
#'
#' @param model A `mysterycall_poisson_model`, `mysterycall_nb_model`, or bare
#'   `glmerMod` / `glmmTMB` object.
#' @param n_sim Integer. Number of simulations for DHARMa. Default `500L`.
#' @param plot Logical. When `TRUE` (default), print the DHARMa zero-inflation
#'   plot to the active graphics device.
#'
#' @return Invisibly returns the DHARMa `testZeroInflation` result list (class
#'   `"DHARMaTest"`), which contains `$statistic`, `$p.value`, and the
#'   simulated distribution. Prints a one-line summary to the console.
#'
#' @section Interpretation:
#'   \describe{
#'     \item{`p > 0.05`}{No evidence of zero-inflation under the fitted model.}
#'     \item{`p < 0.05`}{Significant zero-inflation detected. The model may
#'       underestimate the probability of zero-wait appointments.}
#'   }
#'
#' @family outcomes
#' @seealso [mysterycall_plot_residuals()] for full DHARMa residual diagnostics;
#'   [mysterycall_nb_model()] for the negative binomial model that handles
#'   overdispersion (but not zero-inflation).
#' @export
#'
#' @examplesIf requireNamespace("DHARMa", quietly = TRUE) && requireNamespace("lme4", quietly = TRUE)
#' set.seed(42)
#' df <- data.frame(
#'   wait = rpois(60, lambda = 15),
#'   ins  = rep(c("Medicaid", "BCBS"), 30),
#'   phys = rep(paste0("Dr", 1:10), each = 6),
#'   stringsAsFactors = FALSE
#' )
#' fit <- mysterycall_poisson_model(df, "wait", "ins", "phys")
#' mysterycall_check_zero_inflation(fit, plot = FALSE)
mysterycall_check_zero_inflation <- function(model, n_sim = 500L, plot = TRUE) {
  if (!requireNamespace("DHARMa", quietly = TRUE)) {
    stop(
      "Package 'DHARMa' is required. Install with: install.packages('DHARMa')",
      call. = FALSE
    )
  }

  fit <- if (inherits(model, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    model$model
  } else if (inherits(model, c("glmerMod", "glmmTMB", "glm", "lm"))) {
    model
  } else {
    stop(
      "`model` must be a mysterycall_poisson_model, mysterycall_nb_model, glmerMod, glmmTMB, glm, or lm object.",
      call. = FALSE
    )
  }

  sim    <- DHARMa::simulateResiduals(fittedModel = fit, n = as.integer(n_sim))
  result <- DHARMa::testZeroInflation(sim, plot = plot)

  p <- result$p.value
  verdict <- if (is.na(p)) {
    "p-value unavailable"
  } else if (p < 0.05) {
    sprintf("Zero-inflation detected (p = %.3f). Consider a zero-inflated model.", p)
  } else {
    sprintf("No zero-inflation detected (p = %.3f).", p)
  }
  message(verdict)

  invisible(result)
}
