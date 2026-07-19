# Extract the underlying model fit from a mysterycall model wrapper (or return
# the object unchanged if it is already a fitted model).
.mc_extract_fit <- function(model) {
  if (inherits(model, c("mysterycall_logistic_model", "mysterycall_nb_model",
                        "mysterycall_lmm", "mysterycall_poisson_model")) &&
      !is.null(model$model)) {
    return(model$model)
  }
  model
}

# Fixed-effect term labels of a fitted model that involve `predictor` (main
# effect and any interaction), robust across glm / glmer / glmmTMB.
.mc_terms_involving <- function(fit, predictor) {
  tl <- attr(stats::terms(stats::formula(fit)), "term.labels")
  # a term involves the predictor if the predictor is one of its ":"-parts
  involves <- vapply(strsplit(tl, ":", fixed = TRUE),
                     function(parts) predictor %in% trimws(parts), logical(1))
  tl[involves]
}

#' Joint likelihood-ratio test for a multi-level predictor
#'
#' Tests whether a categorical predictor matters *as a whole* -- e.g. "does
#' subspecialty (7 levels) jointly predict access?" -- by refitting the model
#' without every term that involves the predictor (its main effect and any
#' interaction) and comparing the two fits with a likelihood-ratio test.
#'
#' The test statistic is computed directly from the log-likelihoods
#' (`chi^2 = 2(logLik_full - logLik_reduced)`, `df =` the difference in the
#' number of estimated parameters). This deliberately avoids reading the degrees
#' of freedom off an `anova()` table, which is a known footgun: `lme4::glmer`
#' labels that column `"Df"` (already the difference) while `glmmTMB` labels it
#' `"Chi Df"`, and grabbing the wrong one yields the total parameter count
#' instead of the factor's df and a badly wrong p-value.
#'
#' @param model A fitted model (`glm`, `lme4::glmer`/`lmer`, `glmmTMB`, ...) or a
#'   mysterycall model wrapper (`mysterycall_logistic_model`,
#'   `mysterycall_nb_model`, `mysterycall_lmm`, ...); the underlying fit is
#'   extracted automatically.
#' @param predictor Name of the predictor to test jointly. Must appear as a
#'   fixed-effect term in the model.
#'
#' @return An object of class `"mysterycall_joint_test"`: a list with
#'   `predictor`, `chisq`, `df`, `p_value`, `dropped_terms` (the terms removed),
#'   `logLik_full`, `logLik_reduced`. [as.data.frame()] returns a one-row tibble.
#'
#' @examples
#' d <- data.frame(
#'   y = rbinom(200, 1, 0.4),
#'   grp = factor(sample(letters[1:4], 200, TRUE)),
#'   x = rnorm(200)
#' )
#' fit <- glm(y ~ grp + x, family = binomial, data = d)
#' mysterycall_joint_test(fit, "grp")
#' @export
mysterycall_joint_test <- function(model, predictor) {
  checkmate::assert_string(predictor)
  fit <- .mc_extract_fit(model)

  dropped <- .mc_terms_involving(fit, predictor)
  if (!length(dropped)) {
    stop(sprintf("'%s' is not a fixed-effect term in the model.", predictor),
         call. = FALSE)
  }
  drop_expr <- paste(dropped, collapse = " - ")
  # Refit on the fit's own stored model frame rather than re-evaluating the
  # original `data =` argument, which may be out of scope by the time this runs
  # (e.g. the model was built inside a function). glm/glmer/glmmTMB all retain
  # their frame, so model.frame() reconstructs the fitting data.
  dat <- tryCatch(stats::model.frame(fit), error = function(e) NULL)
  reduced <- if (is.null(dat)) {
    stats::update(fit, stats::as.formula(paste(". ~ . -", drop_expr)))
  } else {
    stats::update(fit, stats::as.formula(paste(". ~ . -", drop_expr)), data = dat)
  }

  ll_full <- stats::logLik(fit)
  ll_red  <- stats::logLik(reduced)
  df <- attr(ll_full, "df") - attr(ll_red, "df")
  chisq <- as.numeric(2 * (as.numeric(ll_full) - as.numeric(ll_red)))
  if (df <= 0) {
    stop("Reduced model does not have fewer parameters than the full model; ",
         "cannot form a joint test.", call. = FALSE)
  }
  p <- stats::pchisq(chisq, df, lower.tail = FALSE)

  structure(
    list(predictor = predictor, chisq = chisq, df = as.integer(df),
         p_value = p, dropped_terms = dropped,
         logLik_full = as.numeric(ll_full),
         logLik_reduced = as.numeric(ll_red)),
    class = "mysterycall_joint_test"
  )
}

#' @export
print.mysterycall_joint_test <- function(x, ...) {
  cat(sprintf("<mysterycall joint LRT: %s>\n", x$predictor))
  cat(sprintf("  chi-square(%d) = %.2f, p = %s\n", x$df, x$chisq,
              format.pval(x$p_value, digits = 3, eps = 1e-4)))
  cat(sprintf("  dropped: %s\n", paste(x$dropped_terms, collapse = ", ")))
  invisible(x)
}

#' @export
as.data.frame.mysterycall_joint_test <- function(x, ...) {
  as.data.frame(tibble::tibble(
    predictor = x$predictor, chisq = x$chisq, df = x$df, p_value = x$p_value,
    dropped_terms = paste(x$dropped_terms, collapse = ", ")), ...)
}
