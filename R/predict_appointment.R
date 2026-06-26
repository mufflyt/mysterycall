#' Predict appointment probability for new patient profiles
#'
#' Generates predicted probabilities of appointment acceptance (and optional
#' confidence intervals) from a fitted [mysterycall_logistic_model()] object.
#' Predictions are **population-level** by default (`re.form = NA`), which is
#' appropriate for new practices not seen during model training.
#'
#' @param fit A `mysterycall_logistic_model` object returned by
#'   [mysterycall_logistic_model()].
#' @param newdata A data frame of new patient/practice profiles to predict.
#'   Must contain all fixed-effect predictors used when fitting `fit`.
#' @param re.form Formula or `NA`. Passed to [lme4::predict.merMod()].
#'   `NA` (default) gives **population-level** predictions (ignores random
#'   effects -- appropriate for new practices). `NULL` includes the estimated
#'   random effects for practices already in the training data.
#' @param conf_level Numeric in (0, 1). Confidence level for the intervals.
#'   Default `0.95`.
#' @param allow_new_levels Logical. Whether to allow new random-effect levels
#'   (new practice names) in `newdata`. Default `TRUE`.
#' @param ci Logical. Whether to compute confidence intervals via the delta
#'   method on the logit scale. Default `TRUE`. Set to `FALSE` for faster
#'   predictions when CIs are not needed.
#'
#' @return The input `newdata` data frame with three columns appended:
#' \describe{
#'   \item{`prob`}{Predicted probability of appointment acceptance (0-1).}
#'   \item{`ci_lower`}{Lower confidence bound on the probability scale.
#'     `NA` when `ci = FALSE`.}
#'   \item{`ci_upper`}{Upper confidence bound on the probability scale.
#'     `NA` when `ci = FALSE`.}
#' }
#'
#' @details
#' **Delta method CIs:** Standard errors are computed by propagating the
#' fixed-effects variance-covariance matrix through the model matrix for
#' `newdata`, then transforming the Wald interval from the logit scale back
#' to the probability scale via `plogis()`. This approach ignores random-effect
#' uncertainty and is therefore anti-conservative when the number of clusters
#' is small.
#'
#' **Population-level vs. cluster-level:** With `re.form = NA` (default),
#' predictions represent the average practice. With `re.form = NULL`, the
#' function uses estimated random intercepts for practices seen during
#' training; new practice names require `allow_new_levels = TRUE` (which
#' sets the random intercept to zero, equivalent to an average practice).
#'
#' @examples
#' \donttest{
#' set.seed(1)
#' df <- data.frame(
#'   practice  = rep(paste0("P", 1:10), each = 6),
#'   insurance = rep(c("Medicaid", "BCBS"), 30),
#'   scenario  = rep(c("A", "B", "C"), 20),
#'   accepted  = rbinom(60, 1, prob = ifelse(
#'     rep(c("Medicaid", "BCBS"), 30) == "Medicaid", 0.35, 0.65
#'   ))
#' )
#' fit <- mysterycall_logistic_model(df, "accepted",
#'                                   c("insurance", "scenario"),
#'                                   "practice")
#' new_profiles <- data.frame(
#'   insurance = c("Medicaid", "BCBS", "Medicaid"),
#'   scenario  = c("A",        "A",    "B"),
#'   practice  = c("new1",     "new1", "new2")
#' )
#' mysterycall_predict_appointment(fit, new_profiles)
#' }
#'
#' @seealso [mysterycall_logistic_model()], [mysterycall_forest_plot()]
#' @family logistic model helpers
#' @importFrom stats predict plogis qnorm delete.response terms model.matrix vcov formula
#' @export
mysterycall_predict_appointment <- function(
    fit,
    newdata,
    re.form          = NA,
    conf_level       = 0.95,
    allow_new_levels = TRUE,
    ci               = TRUE
) {
  if (!inherits(fit, "mysterycall_logistic_model"))
    stop("`fit` must be a mysterycall_logistic_model object.", call. = FALSE)
  if (!requireNamespace("lme4", quietly = TRUE))
    stop("Package 'lme4' is required. Install it with install.packages('lme4').",
         call. = FALSE)
  if (!is.data.frame(newdata) || nrow(newdata) == 0L)
    stop("`newdata` must be a non-empty data frame.", call. = FALSE)
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1)
    stop("`conf_level` must be a single number in (0, 1).", call. = FALSE)

  model <- fit$model
  z     <- stats::qnorm(1 - (1 - conf_level) / 2)

  # Linear predictor on logit scale
  eta <- stats::predict(model, newdata = newdata, type = "link",
                        re.form = re.form,
                        allow.new.levels = allow_new_levels)

  # Delta-method SE on logit scale using fixed-effects vcov
  if (isTRUE(ci)) {
    se_eta <- tryCatch({
      nbf <- if (requireNamespace("reformulas", quietly = TRUE)) {
        reformulas::nobars(stats::formula(model))
      } else {
        suppressWarnings(lme4::nobars(stats::formula(model)))
      }
      fixed_terms <- stats::delete.response(stats::terms(nbf))

      # Align character/factor columns in newdata to training-data levels so
      # model.matrix builds the correct dummy columns even when newdata only
      # contains a subset of levels.
      mf_train    <- model@frame
      nd_aligned  <- newdata
      for (col in names(nd_aligned)) {
        if (col %in% names(mf_train)) {
          tr <- mf_train[[col]]
          if (is.factor(tr) || is.character(tr)) {
            lvls <- levels(as.factor(tr))
            nd_aligned[[col]] <- factor(nd_aligned[[col]], levels = lvls)
          }
        }
      }

      X <- stats::model.matrix(fixed_terms, nd_aligned)
      V <- as.matrix(stats::vcov(model))
      # Align columns (model.matrix may drop aliased columns)
      keep <- intersect(colnames(X), colnames(V))
      X    <- X[, keep, drop = FALSE]
      V    <- V[keep, keep, drop = FALSE]
      se   <- sqrt(pmax(0, diag(X %*% V %*% t(X))))
      if (length(se) == 1L && nrow(newdata) > 1L) se <- rep(se, nrow(newdata))
      se
    }, error = function(e) rep(NA_real_, nrow(newdata)))
  } else {
    se_eta <- rep(NA_real_, nrow(newdata))
  }

  # Back-transform to probability scale
  prob     <- stats::plogis(eta)
  ci_lower <- if (isTRUE(ci)) stats::plogis(eta - z * se_eta) else rep(NA_real_, nrow(newdata))
  ci_upper <- if (isTRUE(ci)) stats::plogis(eta + z * se_eta) else rep(NA_real_, nrow(newdata))

  out          <- newdata
  out$prob     <- round(prob,     4L)
  out$ci_lower <- round(ci_lower, 4L)
  out$ci_upper <- round(ci_upper, 4L)
  out
}
