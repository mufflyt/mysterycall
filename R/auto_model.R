#' Automatically select and compare wait-time models
#'
#' Fits a Poisson GLMM first, checks overdispersion, and upgrades to a
#' negative binomial GLMM when warranted. Optionally fits a Linear Mixed
#' Model (LMM) in parallel and evaluates whether it is defensible as a
#' communication/sensitivity tool. Returns the statistically preferred
#' count model with a structured recommendation attached.
#'
#' **Decision tree**
#' \enumerate{
#'   \item Fit Poisson GLMM and compute Pearson overdispersion (phi).
#'   \item If phi <= `phi_threshold`: primary model = Poisson.
#'         Otherwise: re-fit as negative binomial (NB) GLMM.
#'   \item If `include_lmm = TRUE`: fit LMM and run a Shapiro-Wilk normality
#'         test on the residuals. If residuals are approximately normal
#'         (p >= `lmm_normality_threshold`) **and** the outcome range exceeds
#'         30 days, the LMM is flagged as defensible for reporting
#'         day-scale coefficients alongside the primary count model.
#'         Otherwise the LMM is flagged as not recommended.
#' }
#'
#' The **primary return value** is the selected count model (Poisson or NB)
#' - the same class as [mysterycall_poisson_model()] /
#' [mysterycall_nb_model()], so all downstream functions work unchanged.
#' The LMM and routing metadata live in `result$selection`.
#'
#' @param data A data frame.
#' @param outcome Character scalar. Name of the count (wait-day) outcome
#'   column.
#' @param predictors Character vector of fixed-effect column names.
#' @param random_intercept Character scalar. Grouping column for the
#'   physician random intercept.
#' @param phi_threshold Numeric. Pearson phi above which the NB model
#'   replaces Poisson. Default `2.0`.
#' @param conf_level Numeric. Confidence level for Wald CIs. Default `0.95`.
#' @param include_lmm Logical. Fit an LMM and evaluate its suitability?
#'   Default `TRUE`. The LMM is *never* the primary model; it is always
#'   a secondary communication/sensitivity check.
#' @param lmm_normality_threshold Numeric. Shapiro-Wilk p-value threshold
#'   above which LMM residuals are considered approximately normal.
#'   Default `0.05`.
#' @param ... Additional arguments forwarded to all model-fitting functions.
#'
#' @return The selected count model - either a `mysterycall_poisson_model`
#'   or `mysterycall_nb_model` - with an extra element `$selection`:
#' \describe{
#'   \item{`poisson_phi`}{Numeric. Overdispersion from the initial Poisson
#'     fit.}
#'   \item{`model_chosen`}{Character. `"poisson"` or `"negative_binomial"`.}
#'   \item{`reason`}{Character. Explanation of count-model selection.}
#'   \item{`lmm`}{A `mysterycall_lmm` object, or `NULL` when
#'     `include_lmm = FALSE` or fitting failed.}
#'   \item{`lmm_shapiro_p`}{Numeric. Shapiro-Wilk p-value on LMM residuals,
#'     or `NA`.}
#'   \item{`lmm_defensible`}{Logical. `TRUE` when LMM residuals pass
#'     normality **and** outcome range exceeds 30 days.}
#'   \item{`lmm_recommendation`}{Character. Plain-language guidance on
#'     whether and how to use the LMM.}
#'   \item{`recommendation`}{Character. Overall one-paragraph guidance
#'     covering both the primary model and the LMM.}
#' }
#'
#' @family outcomes
#' @seealso [mysterycall_poisson_model()], [mysterycall_nb_model()],
#'   [mysterycall_lmm()], [mysterycall_model_comparison_table()]
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
                                    phi_threshold           = 2.0,
                                    conf_level              = 0.95,
                                    include_lmm             = TRUE,
                                    lmm_normality_threshold = 0.05,
                                    ...) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("Package 'lme4' is required. Install with: install.packages('lme4')",
         call. = FALSE)
  }

  # ---- Pre-flight: reject impossible outcome values ---------------------------
  y_check <- data[[outcome]]
  if (!is.numeric(y_check))
    stop(sprintf("Outcome '%s' must be numeric (count of wait days).", outcome), call. = FALSE)
  if (any(y_check < 0, na.rm = TRUE)) {
    n_neg <- sum(y_check < 0, na.rm = TRUE)
    stop(sprintf(
      "Outcome '%s' contains %d negative value%s (min = %g).\nNegative wait days are impossible — check for data entry errors or date calculation bugs.",
      outcome, n_neg, if (n_neg == 1L) "" else "s", min(y_check, na.rm = TRUE)
    ), call. = FALSE)
  }
  if (any(y_check > 365, na.rm = TRUE)) {
    n_long <- sum(y_check > 365, na.rm = TRUE)
    warning(sprintf(
      "Outcome '%s' contains %d value%s exceeding 365 days (max = %g).\nWait times over one year are likely a year-typo error (e.g. 2027 instead of 2026) — verify appointment dates before modelling.",
      outcome, n_long, if (n_long == 1L) "" else "s", max(y_check, na.rm = TRUE)
    ), call. = FALSE)
  }

  # ---- Step 1: Poisson GLMM ---------------------------------------------------
  message("Step 1/", if (include_lmm) "3" else "2",
          ": Fitting Poisson GLMM to assess overdispersion...")
  poi <- mysterycall_poisson_model(
    data             = data,
    outcome          = outcome,
    predictors       = predictors,
    random_intercept = random_intercept,
    conf_level       = conf_level,
    ...
  )
  phi <- poi$overdispersion

  # ---- Step 2: Select primary count model -------------------------------------
  if (phi <= phi_threshold) {
    reason <- sprintf(
      "Poisson GLMM selected: phi = %.2f <= %.1f (no overdispersion detected). ",
      phi, phi_threshold
    )
    message(reason)
    primary        <- poi
    model_chosen   <- "poisson"
  } else {
    message(sprintf(
      "Step 2/%s: Overdispersion phi = %.2f > %.1f. Fitting negative binomial GLMM...",
      if (include_lmm) "3" else "2", phi, phi_threshold
    ))

    if (!requireNamespace("glmmTMB", quietly = TRUE)) {
      warning(
        "glmmTMB not installed; cannot fit NB model. Returning Poisson result. ",
        "Install with: install.packages('glmmTMB')",
        call. = FALSE
      )
      reason       <- "NB model requested but glmmTMB not available; returned Poisson."
      primary      <- poi
      model_chosen <- "poisson"
    } else {
      nb <- mysterycall_nb_model(
        data             = data,
        outcome          = outcome,
        predictors       = predictors,
        random_intercept = random_intercept,
        conf_level       = conf_level,
        ...
      )
      reason       <- sprintf(
        "Negative binomial GLMM selected: Poisson phi = %.2f > %.1f (overdispersion detected). ",
        phi, phi_threshold
      )
      message(reason)
      primary      <- nb
      model_chosen <- "negative_binomial"
    }
  }

  # ---- Step 3: LMM as optional sensitivity / communication check --------------
  lmm_result         <- NULL
  lmm_shapiro_p      <- NA_real_
  lmm_defensible     <- NA
  lmm_recommendation <- "LMM not attempted (include_lmm = FALSE)."

  if (include_lmm) {
    message("Step 3/3: Fitting LMM to evaluate day-scale coefficients...")
    y_vals    <- data[[outcome]][!is.na(data[[outcome]])]
    y_range   <- diff(range(y_vals))
    range_ok  <- y_range >= 30

    lmm_result <- tryCatch(
      suppressWarnings(
        mysterycall_lmm(
          data             = data,
          outcome          = outcome,
          predictors       = predictors,
          random_intercept = random_intercept,
          conf_level       = conf_level,
          REML             = FALSE,   # ML so AIC is comparable
          ...
        )
      ),
      error = function(e) {
        message("LMM failed to fit: ", conditionMessage(e))
        NULL
      }
    )

    if (!is.null(lmm_result)) {
      lmm_shapiro_p  <- lmm_result$normality$p_value
      normal_ok      <- !is.na(lmm_shapiro_p) && lmm_shapiro_p >= lmm_normality_threshold
      lmm_defensible <- range_ok && normal_ok

      lmm_recommendation <- if (lmm_defensible) {
        sprintf(
          paste0(
            "LMM is defensible as a secondary communication tool: ",
            "Shapiro-Wilk p = %.3f (>= %.2f) and outcome range = %.0f days (>= 30). ",
            "Report the primary %s model for inference; use the LMM's day-scale ",
            "coefficients in-text for clinical interpretation."
          ),
          lmm_shapiro_p, lmm_normality_threshold, y_range,
          if (model_chosen == "negative_binomial") "NB" else "Poisson"
        )
      } else if (!range_ok) {
        sprintf(
          paste0(
            "LMM is not recommended: outcome range = %.0f days (< 30). ",
            "A floor effect near zero violates the normality assumption. ",
            "Stick with the %s GLMM."
          ),
          y_range,
          if (model_chosen == "negative_binomial") "negative binomial" else "Poisson"
        )
      } else {
        sprintf(
          paste0(
            "LMM is not recommended: Shapiro-Wilk p = %.3f (< %.2f), ",
            "indicating non-normal residuals. Stick with the %s GLMM; ",
            "consider log-transforming the outcome if day-scale coefficients ",
            "are required."
          ),
          lmm_shapiro_p, lmm_normality_threshold,
          if (model_chosen == "negative_binomial") "negative binomial" else "Poisson"
        )
      }
    } else {
      lmm_recommendation <- "LMM could not be fitted; see message above."
    }
  }

  # ---- Overall recommendation -------------------------------------------------
  nb_unavailable <- (phi > phi_threshold && model_chosen == "poisson")
  recommendation <- .auto_model_recommendation(
    model_chosen, phi, phi_threshold,
    lmm_defensible, lmm_recommendation, include_lmm,
    nb_unavailable = nb_unavailable
  )

  # ---- Attach selection metadata and return primary model ---------------------
  primary$selection <- list(
    poisson_phi        = phi,
    model_chosen       = model_chosen,
    reason             = reason,
    lmm                = lmm_result,
    lmm_shapiro_p      = lmm_shapiro_p,
    lmm_defensible     = lmm_defensible,
    lmm_recommendation = lmm_recommendation,
    recommendation     = recommendation
  )

  # Prepend so print.mysterycall_auto_model fires first; inherits() still
  # finds the underlying model class for all downstream functions.
  class(primary) <- c("mysterycall_auto_model", class(primary))
  primary
}


# ----- internal helper --------------------------------------------------------

.auto_model_recommendation <- function(model_chosen, phi, phi_threshold,
                                        lmm_defensible, lmm_rec, include_lmm,
                                        nb_unavailable = FALSE) {
  count_sentence <- if (model_chosen == "negative_binomial") {
    sprintf(
      paste0(
        "PRIMARY MODEL: Negative binomial GLMM (phi = %.2f > %.1f). ",
        "Report incidence rate ratios (IRRs) with 95%% Wald CIs. ",
        "The NB model accounts for overdispersion and yields correctly-sized standard errors."
      ),
      phi, phi_threshold
    )
  } else if (nb_unavailable) {
    sprintf(
      paste0(
        "PRIMARY MODEL: Poisson GLMM returned as fallback (phi = %.2f > %.1f, ",
        "but glmmTMB is not installed so NB could not be fitted). ",
        "Install glmmTMB and re-run: install.packages('glmmTMB')."
      ),
      phi, phi_threshold
    )
  } else {
    sprintf(
      paste0(
        "PRIMARY MODEL: Poisson GLMM (phi = %.2f <= %.1f; no overdispersion). ",
        "Report incidence rate ratios (IRRs) with 95%% Wald CIs."
      ),
      phi, phi_threshold
    )
  }

  lmm_sentence <- if (!include_lmm) {
    ""
  } else if (isTRUE(lmm_defensible)) {
    paste0(
      "\nSENSITIVITY / COMMUNICATION: LMM residuals are approximately normal. ",
      "The LMM's day-scale coefficients may be reported alongside the primary ",
      "model to aid clinical interpretation (e.g., 'Medicaid patients waited ",
      "X more days'). State in the paper that the primary analysis used the ",
      sprintf("%s GLMM.",
              if (model_chosen == "negative_binomial") "negative binomial" else "Poisson")
    )
  } else {
    paste0(
      "\nSENSITIVITY / COMMUNICATION: ", lmm_rec,
      " Do not report LMM coefficients as primary results."
    )
  }

  paste0(count_sentence, lmm_sentence)
}


#' Print method for auto-selected mystery-caller models
#'
#' Extends the primary model's print output with the routing decision,
#' LMM defensibility verdict, and the overall recommendation.
#'
#' @param x A `mysterycall_poisson_model` or `mysterycall_nb_model` returned
#'   by [mysterycall_auto_model()], carrying a `$selection` element.
#' @param digits Integer. Decimal places for coefficients. Default `3`.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_auto_model <- function(x, digits = 3, ...) {
  if (inherits(x, "mysterycall_nb_model")) {
    NextMethod()
  } else {
    NextMethod()
  }
  sel <- x$selection
  if (is.null(sel)) return(invisible(x))

  cat("\n=== Auto-Model Selection ===\n")
  cat(sprintf("Count model: %s (Poisson phi = %.2f)\n",
              gsub("_", " ", sel$model_chosen), sel$poisson_phi))

  if (!is.null(sel$lmm)) {
    cat(sprintf(
      "LMM: Shapiro-Wilk p = %s  |  Defensible: %s\n",
      if (is.na(sel$lmm_shapiro_p)) "n/a" else sprintf("%.3f", sel$lmm_shapiro_p),
      if (is.na(sel$lmm_defensible)) "unknown" else if (sel$lmm_defensible) "YES" else "NO"
    ))
  }

  cat("\n--- Recommendation ---\n")
  cat(strwrap(sel$recommendation, width = 76, exdent = 2), sep = "\n")
  cat("\n")
  invisible(x)
}
