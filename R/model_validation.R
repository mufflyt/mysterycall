#' Test for Interaction Effect in Wait-Time GLMM
#'
#' Fits a full glmmTMB Negative Binomial model with an interaction term and
#' compares it to a reduced model without the interaction term using a
#' Likelihood Ratio Test (ANOVA).
#'
#' @param data A data frame containing the call outcomes.
#' @param formula_full Formula. Formula for the model with the interaction term.
#' @param formula_reduced Formula. Formula for the model without the interaction term.
#' @param family Character or function. Family function for glmmTMB (default is "nbinom2").
#' @return An anova table object containing the Likelihood Ratio Test results.
#' @export
mysterycall_test_interaction_effect <- function(data, formula_full, formula_reduced, family = "nbinom2") {
  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    stop("Package 'glmmTMB' is required. Install with: install.packages('glmmTMB')", call. = FALSE)
  }
  
  # Fit full model
  m_full <- glmmTMB::glmmTMB(formula_full, data = data, family = family)
  
  # Fit reduced model
  m_red <- glmmTMB::glmmTMB(formula_reduced, data = data, family = family)
  
  # Likelihood Ratio Test via ANOVA
  lrt <- stats::anova(m_red, m_full)
  return(lrt)
}

#' Run DHARMa Residual Diagnostics for GLMM Validation
#'
#' Simulates randomized quantile residuals using DHARMa and performs non-parametric
#' dispersion and outlier tests to validate the model's distributional assumptions.
#'
#' @param model A fitted model object (e.g. from glmmTMB, lmer, or glm).
#' @param plot_path Character. If provided, saves the DHARMa residual plot as a PNG at this path.
#' @param n_sim Integer. Number of residual simulations. Default is 250.
#' @return A list containing the DHARMa residuals object and the dispersion/outlier test results.
#' @export
mysterycall_validate_residuals_dharma <- function(model, plot_path = NULL, n_sim = 250) {
  if (!requireNamespace("DHARMa", quietly = TRUE)) {
    stop("Package 'DHARMa' is required. Install with: install.packages('DHARMa')", call. = FALSE)
  }
  
  # Simulate residuals
  sim_res <- DHARMa::simulateResiduals(fittedModel = model, n = n_sim, plot = FALSE)
  
  # Save plot to disk if a file path is specified
  if (!is.null(plot_path)) {
    grDevices::png(plot_path, width = 800, height = 600)
    plot(sim_res)
    grDevices::dev.off()
  }
  
  # Perform diagnostic tests
  disp_test <- DHARMa::testDispersion(sim_res, plot = FALSE)
  out_test <- DHARMa::testOutliers(sim_res, plot = FALSE)
  
  return(list(
    residuals = sim_res,
    dispersion_test = disp_test,
    outlier_test = out_test
  ))
}
