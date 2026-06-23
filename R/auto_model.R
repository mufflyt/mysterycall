#' Automatically select Poisson or negative binomial model based on overdispersion
#'
#' Fits a [mysterycall_poisson_model()] first. If the Pearson overdispersion ratio
#' (phi = Pearson chi-square / residual df) exceeds `phi_threshold`, re-fits the
#' same specification as a [mysterycall_nb_model()] and returns that instead.
#' Either way, a message explains the decision.
#'
#' This is a convenience wrapper for the two-step workflow recommended in
#' `vignette("adding-covariates")`. It does not change any modelling decisions
#' that require domain knowledge (covariate selection, random effects structure).
#'
#' @param data A data frame.
#' @param outcome Character scalar naming the count outcome column.
#' @param predictors Character vector of fixed-effect predictor column names.
#' @param random_intercept Character scalar naming the random-intercept grouping
#'   column.
#' @param phi_threshold Numeric. Pearson phi above which the NB model is
#'   substituted. Default `2.0` (the conventional threshold).
#' @param conf_level Numeric. Confidence level for Wald CIs. Default `0.95`.
#' @param ... Additional arguments forwarded to both model-fitting functions.
#'
#' @return Either a `mysterycall_poisson_model` or `mysterycall_nb_model` object,
#'   depending on the overdispersion check. The returned object has an extra
#'   element `$selection` — a list with:
#'   \describe{
#'     \item{`poisson_phi`}{Numeric. Overdispersion from the initial Poisson fit.}
#'     \item{`model_chosen`}{Character. `"poisson"` or `"negative_binomial"`.}
#'     \item{`reason`}{Character. One-sentence explanation of the choice.}
#'   }
#'
#' @family outcomes
#' @seealso [mysterycall_poisson_model()], [mysterycall_nb_model()],
#'   [mysterycall_select_best_model()]
#' @export
#'
#' @examplesIf requireNamespace("lme4", quietly = TRUE)
#' set.seed(1978)
#' df <- data.frame(
#'   wait = rpois(60, 18),
#'   ins  = rep(c("Medicaid", "BCBS"), 30),
#'   phys = rep(paste0("Dr_", 1:10), each = 6),
#'   stringsAsFactors = FALSE
#' )
#' result <- mysterycall_auto_model(df, "wait", "ins", "phys")
#' print(result)
mysterycall_auto_model <- function(data,
                                    outcome,
                                    predictors,
                                    random_intercept,
                                    phi_threshold = 2.0,
                                    conf_level    = 0.95,
                                    ...) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("Package 'lme4' is required. Install with: install.packages('lme4')", call. = FALSE)
  }

  message("Step 1/2: Fitting Poisson model to assess overdispersion...")
  poi <- mysterycall_poisson_model(
    data             = data,
    outcome          = outcome,
    predictors       = predictors,
    random_intercept = random_intercept,
    conf_level       = conf_level,
    ...
  )

  phi <- poi$overdispersion

  if (phi <= phi_threshold) {
    reason <- sprintf(
      "Poisson model selected: phi = %.2f <= %.1f (no overdispersion detected).",
      phi, phi_threshold
    )
    message(reason)
    poi$selection <- list(
      poisson_phi  = phi,
      model_chosen = "poisson",
      reason       = reason
    )
    return(poi)
  }

  message(sprintf(
    "Step 2/2: Overdispersion phi = %.2f > %.1f. Fitting negative binomial model...",
    phi, phi_threshold
  ))

  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    warning(
      "glmmTMB not installed; cannot fit NB model. Returning Poisson result. ",
      "Install with: install.packages('glmmTMB')",
      call. = FALSE
    )
    poi$selection <- list(
      poisson_phi  = phi,
      model_chosen = "poisson",
      reason       = "NB requested but glmmTMB not available; returned Poisson."
    )
    return(poi)
  }

  nb <- mysterycall_nb_model(
    data             = data,
    outcome          = outcome,
    predictors       = predictors,
    random_intercept = random_intercept,
    conf_level       = conf_level,
    ...
  )

  reason <- sprintf(
    "Negative binomial model selected: phi = %.2f > %.1f (overdispersion detected).",
    phi, phi_threshold
  )
  message(reason)
  nb$selection <- list(
    poisson_phi  = phi,
    model_chosen = "negative_binomial",
    reason       = reason
  )
  nb
}
