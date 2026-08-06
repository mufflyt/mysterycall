#' Test overdispersion in a fitted count model
#'
#' Computes the Pearson chi-square dispersion statistic (phi = chi-sq /
#' residual df) for any fitted count model and returns a plain-language
#' interpretation.  The calculation mirrors the `overdisp_fun()` approach
#' used in the mystery-caller Rmd analyses: Pearson residuals are squared
#' and summed, divided by the residual degrees of freedom, and tested against
#' a chi-square distribution.
#'
#' This is the standalone export of the overdispersion check that
#' [mysterycall_poisson_model()] performs internally.  Use it to diagnose
#' any fitted count model *after* fitting --- including negative binomial
#' models, where phi near 1.0 confirms that the dispersion was adequately
#' absorbed.
#'
#' @param model A fitted model object.  Supported classes:
#'   \describe{
#'     \item{`glmerMod`}{From [lme4::glmer()].}
#'     \item{`glm`}{From [stats::glm()].}
#'     \item{`negbin`}{From [MASS::glm.nb()].}
#'   }
#'   Any object that responds to [residuals()] with `type = "pearson"` and
#'   to [df.residual()] is also accepted.
#' @param phi_thresholds Named numeric vector.  Boundaries used to assign the
#'   verbal interpretation category.  Must have names `"mild"`, `"moderate"`,
#'   and `"severe"` and must satisfy
#'   `mild < moderate < severe`.  Default:
#'   `c(mild = 1.2, moderate = 1.5, severe = 2.0)`.
#' @param digits Integer.  Number of decimal places for phi and the p-value
#'   in formatted output.  Default `3L`.
#'
#' @return A list of class `"mysterycall_overdispersion_test"` with elements:
#' \describe{
#'   \item{`phi`}{Numeric. Pearson dispersion ratio (chi-sq / df).}
#'   \item{`pearson_chisq`}{Numeric. Raw Pearson chi-square statistic.}
#'   \item{`df`}{Integer. Residual degrees of freedom.}
#'   \item{`p_value`}{Numeric. P-value from
#'     `pchisq(pearson_chisq, df, lower.tail = FALSE)`.}
#'   \item{`p_fmt`}{Character. Formatted p-value (e.g. `"< 0.001"`).}
#'   \item{`interpretation`}{Character. One-sentence verbal category.}
#'   \item{`recommendation`}{Character. One-sentence action sentence.}
#'   \item{`sentence`}{Character. Combined summary sentence suitable for
#'     inline reporting.}
#' }
#'
#' @section Interpretation thresholds:
#' \describe{
#'   \item{phi < 1.0}{Underdispersion --- the model may overfit.}
#'   \item{1.0 <= phi < 1.2}{No significant overdispersion.}
#'   \item{1.2 <= phi < 1.5}{Mild overdispersion.}
#'   \item{1.5 <= phi < 2.0}{Moderate overdispersion.}
#'   \item{phi >= 2.0}{Severe overdispersion.}
#' }
#'
#' @section Mixed-effects caveat:
#' For mixed-effects models (`glmmTMB`, `merMod`), [df.residual()] counts only
#' the fixed-effect parameters and ignores the effective degrees of freedom
#' consumed by the random effects, so phi is an **approximation** rather than an
#' exact dispersion ratio. The verbal interpretation accounts for this by
#' treating low residual phi as expected for negative-binomial and mixed models
#' (dispersion absorbed by the NB variance or random intercepts) rather than as
#' overfitting. For a formal simulation-based check on a GLMM, prefer
#' `DHARMa::testDispersion()`.
#'
#' @family outcomes
#' @seealso [mysterycall_poisson_model()], [mysterycall_nb_model()],
#'   [mysterycall_check_zero_inflation()]
#' @importFrom stats residuals df.residual pchisq
#' @export
#'
#' @examples
#' ## Poisson GLM on count data ------------------------------------------------
#' set.seed(42)
#' n   <- 200
#' dat <- data.frame(
#'   y   = rpois(n, lambda = exp(0.5 + 0.3 * rnorm(n))),
#'   x1  = rnorm(n),
#'   grp = sample(c("A", "B"), n, replace = TRUE)
#' )
#' fit <- glm(y ~ x1 + grp, data = dat, family = poisson())
#' result <- mysterycall_overdispersion_test(fit)
#' print(result)
#'
#' ## Gaussian GLM (non-count, shows underdispersion path) ---------------------
#' fit2 <- glm(mpg ~ wt + cyl, data = mtcars, family = gaussian())
#' mysterycall_overdispersion_test(fit2)
mysterycall_overdispersion_test <- function(
    model,
    phi_thresholds = c(mild = 1.2, moderate = 1.5, severe = 2.0),
    digits = 3L
) {

  # ---- validate phi_thresholds -----------------------------------------------
  if (!is.numeric(phi_thresholds) ||
      !all(c("mild", "moderate", "severe") %in% names(phi_thresholds))) {
    stop(
      "`phi_thresholds` must be a named numeric vector with names ",
      "'mild', 'moderate', and 'severe'.",
      call. = FALSE
    )
  }
  mild_t     <- phi_thresholds[["mild"]]
  moderate_t <- phi_thresholds[["moderate"]]
  severe_t   <- phi_thresholds[["severe"]]
  if (!(mild_t < moderate_t && moderate_t < severe_t)) {
    stop(
      "`phi_thresholds` values must satisfy mild < moderate < severe.",
      call. = FALSE
    )
  }

  digits <- as.integer(digits)
  if (is.na(digits) || digits < 0L) {
    stop("`digits` must be a non-negative integer.", call. = FALSE)
  }

  # ---- extract Pearson residuals and residual df -----------------------------
  rp <- tryCatch(
    residuals(model, type = "pearson"),
    error = function(e) {
      stop(
        "Could not extract Pearson residuals from `model`. ",
        "The object must support residuals(model, type = 'pearson'). ",
        "Original error: ", conditionMessage(e),
        call. = FALSE
      )
    }
  )

  rdf <- tryCatch(
    df.residual(model),
    error = function(e) {
      stop(
        "Could not extract residual df from `model`. ",
        "The object must support df.residual(). ",
        "Original error: ", conditionMessage(e),
        call. = FALSE
      )
    }
  )

  if (is.null(rdf) || is.na(rdf) || rdf <= 0) {
    stop(
      "Residual degrees of freedom are zero or missing. ",
      "Cannot compute a dispersion statistic.",
      call. = FALSE
    )
  }

  # ---- core statistics -------------------------------------------------------
  pearson_chisq <- sum(rp^2, na.rm = TRUE)
  phi           <- pearson_chisq / rdf
  p_value       <- pchisq(pearson_chisq, df = rdf, lower.tail = FALSE)

  # ---- formatted p-value -----------------------------------------------------
  p_fmt <- .mc_format_p(p_value, digits = digits)

  phi_fmt <- sprintf(paste0("%.", digits, "f"), phi)

  # ---- verbal interpretation -------------------------------------------------
  if (phi < 1.0) {
    # Detect if the model is Negative Binomial or mixed-effects (GLMM)
    is_nb <- inherits(model, "mysterycall_nb_model") ||
             (inherits(model, "glmmTMB") && grepl("nbinom", tryCatch(stats::family(model)$family, error = function(e) ""))) ||
             inherits(model, "negbin")
    is_mixed <- inherits(model, c("glmmTMB", "merMod", "lmerMod", "glmerMod"))

    if (is_nb) {
      interpretation <- sprintf(
        "Low residual dispersion detected (phi=%s). This is normal for Negative Binomial models where overdispersion has been successfully absorbed.",
        phi_fmt
      )
      recommendation <- "No action required; the Negative Binomial model successfully resolved dispersion."
    } else if (is_mixed) {
      interpretation <- sprintf(
        "Low residual dispersion detected (phi=%s). This is a common artifact in mixed-effects models as random intercepts absorb variance.",
        phi_fmt
      )
      recommendation <- "No action required; verify model fit using AIC comparisons, but residual underdispersion is expected in GLMMs."
    } else {
      interpretation <- sprintf(
        "Underdispersion detected (phi=%s). Model may overfit.",
        phi_fmt
      )
      recommendation <- paste(
        "Inspect the model for unnecessary predictors or",
        "consider a quasi-Poisson specification."
      )
    }
    category <- "underdispersion"

  } else if (phi < mild_t) {
    interpretation <- sprintf(
      "No significant overdispersion (phi=%s, p=%s).",
      phi_fmt, p_fmt
    )
    recommendation <- "No action required; the Poisson model appears adequate."
    category <- "none"

  } else if (phi < moderate_t) {
    interpretation <- sprintf(
      "Mild overdispersion (phi=%s), below the negative-binomial switch threshold.",
      phi_fmt
    )
    recommendation <- paste(
      "The Poisson model is likely adequate; monitor diagnostics.",
      "Switch to mysterycall_nb_model() only if phi reaches the moderate band."
    )
    category <- "mild"

  } else if (phi < severe_t) {
    interpretation <- sprintf(
      "Moderate overdispersion (phi=%s). Consider negative binomial or zero-inflated model.",
      phi_fmt
    )
    recommendation <- paste(
      "Fit a negative binomial model (mysterycall_nb_model()) or a",
      "zero-inflated model; check for excess zeros with",
      "mysterycall_check_zero_inflation()."
    )
    category <- "moderate"

  } else {
    interpretation <- sprintf(
      "Severe overdispersion (phi=%s). Negative binomial or zero-inflated model strongly recommended.",
      phi_fmt
    )
    recommendation <- paste(
      "Switch to a negative binomial or zero-inflated negative binomial",
      "model immediately; Poisson standard errors are severely underestimated."
    )
    category <- "severe"
  }

  # ---- combined sentence -----------------------------------------------------
  # sentence = header statistics + interpretation; recommendation follows
  # separately in the print method so it is not duplicated.
  sentence <- sprintf(
    "Pearson dispersion phi=%s (chi-sq=%s, df=%d, p=%s): %s",
    phi_fmt,
    sprintf("%.0f", round(pearson_chisq)),
    as.integer(round(rdf)),
    p_fmt,
    interpretation
  )

  # ---- return ----------------------------------------------------------------
  structure(
    list(
      phi           = phi,
      pearson_chisq = pearson_chisq,
      df            = as.integer(round(rdf)),
      p_value       = p_value,
      p_fmt         = p_fmt,
      interpretation = interpretation,
      recommendation = recommendation,
      sentence      = sentence,
      category      = category
    ),
    class = "mysterycall_overdispersion_test"
  )
}


#' Print method for mysterycall_overdispersion_test
#'
#' @param x A `mysterycall_overdispersion_test` object.
#' @param ... Ignored.
#'
#' @return Invisibly returns `x`.
#' @export
print.mysterycall_overdispersion_test <- function(x, ...) {
  cat(x$sentence, "\n")
  cat(x$recommendation, "\n")
  invisible(x)
}
