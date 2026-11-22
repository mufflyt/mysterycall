# Standard statistical accessors for the package's fitted-model classes.
#
# Before these existed, coef(), fitted() and residuals() on a
# mysterycall_poisson_model dispatched to the *.default methods, which look
# for list elements that these objects do not have, and so returned NULL
# without any error. A silent NULL in place of a coefficient vector is worse
# than a missing method, because it propagates into downstream arithmetic.
#
# Every method resolves the engine fit through .mc_engine_fit(), which errors
# when $model is absent, and then delegates to the engine's own method. The
# package never recomputes an estimate that the engine can report.
#
# These methods are deliberately NOT defined for the table and report
# classes: those are formatted results, not fitted models.


#' Fitted-Model Classes Carrying an Engine Fit
#'
#' @return Character vector of class names.
#' @family model-accessors
#' @keywords internal
.mc_fitted_model_classes <- function() {
  c(
    "mysterycall_poisson_model",
    "mysterycall_nb_model",
    "mysterycall_lmm",
    "mysterycall_logistic_model"
  )
}


#' Resolve the Engine Fit Stored on a mysterycall Model Object
#'
#' @param object A mysterycall fitted-model object.
#' @param call_name Character scalar naming the accessor, for the error.
#'
#' @return The stored engine fit (`glmerMod`, `glmmTMB`, `lmerMod`, `glm`).
#' @family model-accessors
#' @keywords internal
.mc_engine_fit <- function(object, call_name) {
  fit <- object[["model"]]
  if (is.null(fit)) {
    stop(sprintf(
      paste0("%s() requires the fitted engine model, but this `%s` object ",
             "has no `$model` element. The object was not produced by a ",
             "completed fit, or `$model` was removed after fitting."),
      call_name, class(object)[[1L]]
    ), call. = FALSE)
  }
  fit
}


#' Fixed-Effect Coefficients From an Engine Fit
#'
#' `stats::coef()` on a `merMod` returns the per-group coefficient matrix,
#' not the fixed effects, so the mixed-model engines are handled explicitly.
#'
#' @param fit An engine fit.
#'
#' @return Named numeric vector of fixed-effect estimates on the link scale.
#' @family model-accessors
#' @keywords internal
.mc_fixed_effects <- function(fit) {
  if (inherits(fit, "glmmTMB")) {
    return(glmmTMB::fixef(fit)$cond)
  }
  if (inherits(fit, "merMod")) {
    return(lme4::fixef(fit))
  }
  stats::coef(fit)
}


#' Fixed-Effect Variance-Covariance Matrix From an Engine Fit
#'
#' Returned as a base matrix: `lme4` supplies a `dpoMatrix`, which fails
#' `is.matrix()` and cannot be indexed the way callers expect.
#'
#' @param fit An engine fit.
#'
#' @return Numeric matrix for the fixed effects (conditional model only).
#' @family model-accessors
#' @keywords internal
.mc_fixed_vcov <- function(fit) {
  v <- if (inherits(fit, "glmmTMB")) {
    stats::vcov(fit)$cond
  } else {
    stats::vcov(fit)
  }
  as.matrix(v)
}


# -- coef() -------------------------------------------------------------------

#' Fixed-Effect Coefficients of a mysterycall Model
#'
#' Returns the fixed-effect estimates on the link scale, exactly as the
#' underlying engine reports them (`lme4::fixef()` for `glmerMod`/`lmerMod`,
#' the conditional component of `glmmTMB::fixef()` for `glmmTMB`). Random
#' effects are not included; use [lme4::ranef()] on `$model` for those.
#'
#' For a count model with a log link, `exp(coef(object))` gives the incidence
#' rate ratios reported in `object$irr_table$irr`.
#'
#' @param object A mysterycall fitted-model object.
#' @param ... Ignored, present for generic compatibility.
#'
#' @return Named numeric vector of fixed-effect estimates on the link scale.
#' @rdname coef.mysterycall
#' @family model-accessors
#' @export
coef.mysterycall_poisson_model <- function(object, ...) {
  .mc_fixed_effects(.mc_engine_fit(object, "coef"))
}

#' @rdname coef.mysterycall
#' @export
coef.mysterycall_nb_model <- function(object, ...) {
  .mc_fixed_effects(.mc_engine_fit(object, "coef"))
}

#' @rdname coef.mysterycall
#' @export
coef.mysterycall_lmm <- function(object, ...) {
  .mc_fixed_effects(.mc_engine_fit(object, "coef"))
}

#' @rdname coef.mysterycall
#' @export
coef.mysterycall_logistic_model <- function(object, ...) {
  .mc_fixed_effects(.mc_engine_fit(object, "coef"))
}


# -- vcov() -------------------------------------------------------------------

#' Variance-Covariance Matrix of a mysterycall Model
#'
#' Returns the fixed-effect variance-covariance matrix of the conditional
#' model as a base matrix. Random-effect variance components are not part of
#' this matrix; see `object$random_effects`.
#'
#' @param object A mysterycall fitted-model object.
#' @param ... Ignored, present for generic compatibility.
#'
#' @return Numeric matrix with one row and column per fixed effect.
#' @rdname vcov.mysterycall
#' @family model-accessors
#' @export
vcov.mysterycall_poisson_model <- function(object, ...) {
  .mc_fixed_vcov(.mc_engine_fit(object, "vcov"))
}

#' @rdname vcov.mysterycall
#' @export
vcov.mysterycall_nb_model <- function(object, ...) {
  .mc_fixed_vcov(.mc_engine_fit(object, "vcov"))
}

#' @rdname vcov.mysterycall
#' @export
vcov.mysterycall_lmm <- function(object, ...) {
  .mc_fixed_vcov(.mc_engine_fit(object, "vcov"))
}

#' @rdname vcov.mysterycall
#' @export
vcov.mysterycall_logistic_model <- function(object, ...) {
  .mc_fixed_vcov(.mc_engine_fit(object, "vcov"))
}


# -- confint() ----------------------------------------------------------------

#' Wald Confidence Intervals for a mysterycall Model
#'
#' Intervals are **Wald** intervals on the link scale,
#' \eqn{\hat\beta \pm z_{1-\alpha/2} \cdot \mathrm{SE}(\hat\beta)}, computed
#' from [vcov()]. They are the same intervals the package reports in
#' `object$irr_table` (which exponentiates them), so the two never disagree.
#'
#' These are not profile-likelihood or bootstrap intervals. For a
#' profile-likelihood interval on a mixed model, call
#' `stats::confint(object$model, method = "profile")` directly and expect it
#' to be considerably slower.
#'
#' @param object A mysterycall fitted-model object.
#' @param parm Optional character or numeric selection of parameters.
#' @param level Numeric scalar. Confidence level, default `0.95`.
#' @param ... Ignored, present for generic compatibility.
#'
#' @return Numeric matrix with two columns of link-scale interval bounds.
#' @rdname confint.mysterycall
#' @family model-accessors
#' @export
confint.mysterycall_poisson_model <- function(object, parm, level = 0.95,
                                              ...) {
  .mc_wald_confint(object, parm, level, "confint")
}

#' @rdname confint.mysterycall
#' @export
confint.mysterycall_nb_model <- function(object, parm, level = 0.95, ...) {
  .mc_wald_confint(object, parm, level, "confint")
}

#' @rdname confint.mysterycall
#' @export
confint.mysterycall_lmm <- function(object, parm, level = 0.95, ...) {
  .mc_wald_confint(object, parm, level, "confint")
}

#' @rdname confint.mysterycall
#' @export
confint.mysterycall_logistic_model <- function(object, parm, level = 0.95,
                                               ...) {
  .mc_wald_confint(object, parm, level, "confint")
}


#' Build a Wald Confidence Interval Matrix
#'
#' @param object A mysterycall fitted-model object.
#' @param parm Optional parameter selection.
#' @param level Numeric scalar confidence level.
#' @param call_name Character scalar naming the accessor, for errors.
#'
#' @return Numeric matrix of link-scale bounds.
#' @family model-accessors
#' @keywords internal
.mc_wald_confint <- function(object, parm, level, call_name) {
  if (!is.numeric(level) || length(level) != 1L ||
      level <= 0 || level >= 1) {
    stop("`level` must be a single number strictly between 0 and 1.",
         call. = FALSE)
  }

  fit <- .mc_engine_fit(object, call_name)
  est <- .mc_fixed_effects(fit)
  se  <- sqrt(diag(.mc_fixed_vcov(fit)))
  z   <- stats::qnorm(1 - (1 - level) / 2)

  out <- cbind(est - z * se, est + z * se)
  dimnames(out) <- list(
    names(est),
    sprintf("%g %%", c((1 - level) / 2, 1 - (1 - level) / 2) * 100)
  )

  if (!missing(parm) && !is.null(parm)) {
    out <- out[parm, , drop = FALSE]
  }
  out
}


# -- nobs() -------------------------------------------------------------------

#' Number of Observations Used by a mysterycall Model
#'
#' Reports the rows the engine actually fitted, which the fitters assert is
#' equal to `object$n`. A disagreement between the two means the engine
#' dropped rows on its own and is treated as an error at fit time.
#'
#' @param object A mysterycall fitted-model object.
#' @param ... Ignored, present for generic compatibility.
#'
#' @return Integer scalar count of fitted observations.
#' @rdname nobs.mysterycall
#' @family model-accessors
#' @export
nobs.mysterycall_poisson_model <- function(object, ...) {
  stats::nobs(.mc_engine_fit(object, "nobs"))
}

#' @rdname nobs.mysterycall
#' @export
nobs.mysterycall_nb_model <- function(object, ...) {
  stats::nobs(.mc_engine_fit(object, "nobs"))
}

#' @rdname nobs.mysterycall
#' @export
nobs.mysterycall_lmm <- function(object, ...) {
  stats::nobs(.mc_engine_fit(object, "nobs"))
}

#' @rdname nobs.mysterycall
#' @export
nobs.mysterycall_logistic_model <- function(object, ...) {
  stats::nobs(.mc_engine_fit(object, "nobs"))
}


# -- formula() ----------------------------------------------------------------

#' Model Formula of a mysterycall Model
#'
#' Returns the formula that was passed to the fitting engine, including the
#' random-effect term and any `offset()` term the fitter constructed.
#'
#' @param x A mysterycall fitted-model object.
#' @param ... Ignored, present for generic compatibility.
#'
#' @return A `formula`.
#' @rdname formula.mysterycall
#' @family model-accessors
#' @export
formula.mysterycall_poisson_model <- function(x, ...) {
  .mc_model_formula(x, "formula")
}

#' @rdname formula.mysterycall
#' @export
formula.mysterycall_nb_model <- function(x, ...) {
  .mc_model_formula(x, "formula")
}

#' @rdname formula.mysterycall
#' @export
formula.mysterycall_lmm <- function(x, ...) {
  .mc_model_formula(x, "formula")
}

#' @rdname formula.mysterycall
#' @export
formula.mysterycall_logistic_model <- function(x, ...) {
  .mc_model_formula(x, "formula")
}


#' Resolve the Formula of a mysterycall Model Object
#'
#' @param x A mysterycall fitted-model object.
#' @param call_name Character scalar naming the accessor, for errors.
#'
#' @return A `formula`.
#' @family model-accessors
#' @keywords internal
.mc_model_formula <- function(x, call_name) {
  # Resolve the engine first: a stored $formula must not be reported for an
  # object that carries no fit, since the two could disagree.
  fit <- .mc_engine_fit(x, call_name)
  stored <- x[["formula"]]
  if (inherits(stored, "formula")) {
    return(stored)
  }
  stats::formula(fit)
}


# -- fitted() -----------------------------------------------------------------

#' Fitted Values of a mysterycall Model
#'
#' Returns the engine's fitted values. For the mixed models these are
#' **conditional** on the estimated random effects and on the response scale
#' (expected wait-time counts for the count models, probabilities for the
#' logistic model) -- not marginal, population-average predictions. For
#' marginal predictions over a covariate profile use
#' [mysterycall_predicted_means()] or [mysterycall_marginal_effects()].
#'
#' @param object A mysterycall fitted-model object.
#' @param ... Passed to the engine's `fitted()` method.
#'
#' @return Numeric vector of fitted values, one per fitted observation.
#' @rdname fitted.mysterycall
#' @family model-accessors
#' @export
fitted.mysterycall_poisson_model <- function(object, ...) {
  stats::fitted(.mc_engine_fit(object, "fitted"), ...)
}

#' @rdname fitted.mysterycall
#' @export
fitted.mysterycall_nb_model <- function(object, ...) {
  stats::fitted(.mc_engine_fit(object, "fitted"), ...)
}

#' @rdname fitted.mysterycall
#' @export
fitted.mysterycall_lmm <- function(object, ...) {
  stats::fitted(.mc_engine_fit(object, "fitted"), ...)
}

#' @rdname fitted.mysterycall
#' @export
fitted.mysterycall_logistic_model <- function(object, ...) {
  stats::fitted(.mc_engine_fit(object, "fitted"), ...)
}


# -- residuals() --------------------------------------------------------------

#' Residuals of a mysterycall Model
#'
#' Delegates to the engine, so `type` follows the engine's own convention
#' (`"deviance"` by default for `glmerMod`, `"pearson"` available for the
#' dispersion diagnostic). Residuals are conditional on the estimated random
#' effects, matching [fitted()].
#'
#' @param object A mysterycall fitted-model object.
#' @param ... Passed to the engine's `residuals()` method, notably `type`.
#'
#' @return Numeric vector of residuals, one per fitted observation.
#' @rdname residuals.mysterycall
#' @family model-accessors
#' @export
residuals.mysterycall_poisson_model <- function(object, ...) {
  stats::residuals(.mc_engine_fit(object, "residuals"), ...)
}

#' @rdname residuals.mysterycall
#' @export
residuals.mysterycall_nb_model <- function(object, ...) {
  stats::residuals(.mc_engine_fit(object, "residuals"), ...)
}

#' @rdname residuals.mysterycall
#' @export
residuals.mysterycall_lmm <- function(object, ...) {
  stats::residuals(.mc_engine_fit(object, "residuals"), ...)
}

#' @rdname residuals.mysterycall
#' @export
residuals.mysterycall_logistic_model <- function(object, ...) {
  stats::residuals(.mc_engine_fit(object, "residuals"), ...)
}


# -- summary() ----------------------------------------------------------------

#' Summarise a mysterycall Model
#'
#' Collects the cohort size, formula, coefficient table, dispersion
#' diagnostic and convergence status into one object of class
#' `mysterycall_model_summary`. The engine's own summary remains available as
#' `summary(object$model)`.
#'
#' @param object A mysterycall fitted-model object.
#' @param ... Ignored, present for generic compatibility.
#'
#' @return An object of class `mysterycall_model_summary`.
#' @rdname summary.mysterycall
#' @family model-accessors
#' @export
summary.mysterycall_poisson_model <- function(object, ...) {
  .mc_model_summary(object, "Poisson GLMM")
}

#' @rdname summary.mysterycall
#' @export
summary.mysterycall_nb_model <- function(object, ...) {
  .mc_model_summary(object, "Negative binomial GLMM")
}

#' @rdname summary.mysterycall
#' @export
summary.mysterycall_lmm <- function(object, ...) {
  .mc_model_summary(object, "Linear mixed model")
}

#' @rdname summary.mysterycall
#' @export
summary.mysterycall_logistic_model <- function(object, ...) {
  .mc_model_summary(object, "Logistic model")
}


#' Build a mysterycall Model Summary
#'
#' @param object A mysterycall fitted-model object.
#' @param label Character scalar describing the model family.
#'
#' @return An object of class `mysterycall_model_summary`.
#' @family model-accessors
#' @keywords internal
.mc_model_summary <- function(object, label) {
  fit <- .mc_engine_fit(object, "summary")

  structure(
    list(
      label          = label,
      class_name     = class(object)[[1L]],
      formula        = .mc_model_formula(object, "summary"),
      n              = object[["n"]],
      n_dropped      = object[["n_dropped"]],
      n_clusters     = object[["n_clusters"]],
      nobs_engine    = stats::nobs(fit),
      coefficients   = object[["irr_table"]],
      overdispersion = object[["overdispersion"]],
      dispersion     = object[["dispersion_details"]],
      convergence    = object[["convergence"]],
      fit_warnings   = object[["fit_warnings"]],
      aic            = object[["aic"]],
      bic            = object[["bic"]]
    ),
    class = "mysterycall_model_summary"
  )
}


#' Print a mysterycall Model Summary
#'
#' @param x A `mysterycall_model_summary` object.
#' @param ... Ignored, present for generic compatibility.
#'
#' @return `x`, invisibly.
#' @family model-accessors
#' @export
print.mysterycall_model_summary <- function(x, ...) {
  cat(sprintf("%s (%s)\n", x$label, x$class_name))
  cat(sprintf("Formula: %s\n", paste(deparse(x$formula), collapse = " ")))

  if (!is.null(x$n)) {
    cat(sprintf(
      "Observations: %s fitted", format(x$nobs_engine, big.mark = ",")
    ))
    if (!is.null(x$n_dropped) && x$n_dropped > 0L) {
      cat(sprintf(
        " (%s excluded for missing values)", format(x$n_dropped, big.mark = ",")
      ))
    }
    cat("\n")
  }
  if (!is.null(x$n_clusters) && !is.na(x$n_clusters)) {
    cat(sprintf("Clusters: %s\n", format(x$n_clusters, big.mark = ",")))
  }

  if (!is.null(x$overdispersion) && is.finite(x$overdispersion)) {
    method <- if (is.null(x$dispersion$method)) "" else {
      sprintf(" [%s]", x$dispersion$method)
    }
    cat(sprintf("Dispersion: %.3f%s\n", x$overdispersion, method))
  }
  if (!is.null(x$aic)) {
    cat(sprintf("AIC: %.1f   BIC: %.1f\n", x$aic, x$bic))
  }

  conv <- x$convergence
  if (!is.null(conv)) {
    cat(sprintf(
      "Optimizer converged: %s   Singular: %s   Fit warnings: %d\n",
      isTRUE(conv$converged), isTRUE(conv$singular),
      length(x$fit_warnings)
    ))
  }

  if (!is.null(x$coefficients)) {
    cat("\nFixed effects:\n")
    print(x$coefficients)
  }

  invisible(x)
}


#' Record an Auditable Dispersion Diagnostic
#'
#' Bundles the dispersion statistic with the exact formula, denominator and
#' assumptions behind it, so a reader can reproduce the number rather than
#' having to infer which convention was used. The returned `df` is the
#' denominator actually divided by, so
#' `pearson_chisq / df == overdispersion` holds exactly.
#'
#' @section Choice of denominator:
#' The count fitters divide the Pearson chi-square by `n - p_fixed`, counting
#' only the fixed-effect parameters. `stats::df.residual()` on a `merMod`
#' instead returns `n - (p_fixed + n_varpar)`, which also debits the
#' random-effect variance components, and so is smaller by the number of
#' variance parameters -- one, for a single random intercept. The two
#' denominators therefore differ by one, and the resulting statistic by a
#' factor of roughly `1 + 1/df`.
#'
#' Both conventions appear in practice, and the Pearson statistic is in any
#' case only an approximate dispersion diagnostic for a GLMM: its reference
#' chi-square distribution is asymptotic and does not strictly hold once
#' random effects are estimated. `df_engine` is recorded alongside `df` so
#' the difference is visible and auditable; the statistic reported in
#' `$overdispersion` is unchanged from previous releases, and changing the
#' convention is a separate decision that would move published numbers.
#'
#' @param method Character scalar naming the convention.
#' @param formula Character scalar giving the computation verbatim.
#' @param pearson_chisq Numeric scalar. The Pearson chi-square statistic.
#' @param df Numeric scalar. The denominator actually used.
#' @param n Integer scalar. Observations in the fitted cohort.
#' @param n_parameters Integer scalar. Parameters debited by `df`.
#' @param df_engine Numeric scalar. The engine's own residual df, for
#'   comparison. `NA_real_` when the engine does not report one.
#'
#' @return A named list describing the diagnostic.
#' @family model-accessors
#' @keywords internal
.mc_dispersion_details <- function(method,
                                   formula,
                                   pearson_chisq,
                                   df,
                                   n,
                                   n_parameters,
                                   df_engine = NA_real_) {
  list(
    method        = method,
    formula       = formula,
    pearson_chisq = pearson_chisq,
    df            = df,
    n             = as.integer(n),
    n_parameters  = as.integer(n_parameters),
    df_engine     = as.numeric(df_engine),
    assumptions   = paste0(
      "Approximate diagnostic. The Pearson chi-square reference ",
      "distribution is asymptotic and does not hold exactly once random ",
      "effects are estimated; the denominator debits fixed-effect ",
      "parameters only, not random-effect variance components (compare ",
      "`df_engine`). Values near 1 indicate no evidence of over- or ",
      "under-dispersion; values below 1 indicate underdispersion."
    )
  )
}
