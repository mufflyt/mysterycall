#' Compute random-effect variance components and ICC for mixed models
#'
#' @name mysterycall_random_effect_variance
NULL

#' Compute ICC and random-effect variance components
#'
#' Extracts variance components from a fitted mixed model via [lme4::VarCorr()],
#' computes the intraclass correlation coefficient (ICC), and generates a
#' manuscript-ready interpretive sentence. Handles Poisson GLMER models where
#' the residual scale parameter (\code{sc}) is unavailable by returning
#' \code{icc = NA} with an informative message.
#'
#' @param model A fitted mixed model (\code{glmerMod}, \code{lmerMod}, etc.)
#'   from lme4.
#' @param variance_threshold Numeric scalar \eqn{\ge 0}. Variance components
#'   with \code{vcov > variance_threshold} are flagged as \code{"Yes"} in the
#'   \code{$var_table} column \code{Significant}. Default \code{0.01}.
#' @param digits Integer scalar. Number of decimal places for the ICC in the
#'   sentence. Default \code{3}.
#'
#' @return A named list with:
#'   \describe{
#'     \item{\code{icc}}{Numeric or \code{NA}. Intraclass correlation
#'       coefficient.}
#'     \item{\code{random_variance}}{Numeric. Variance of the first random-effect
#'       group.}
#'     \item{\code{residual_variance}}{Numeric or \code{NA}. Residual variance
#'       (\code{sc^2}). \code{NA} for Poisson GLMER.}
#'     \item{\code{random_effect_group}}{Character. Name of the first random-effect
#'       grouping factor.}
#'     \item{\code{var_table}}{Data frame. Output of
#'       \code{as.data.frame(VarCorr(model))} with an additional logical column
#'       \code{Significant}.}
#'     \item{\code{interpretation}}{Character scalar. One of \code{"high"},
#'       \code{"moderate"}, \code{"low to moderate"}, or \code{"low"}.}
#'     \item{\code{sentence}}{Character scalar. Full ICC sentence and
#'       interpretation paragraph.}
#'   }
#'
#' @seealso [mysterycall_r2_sentence()] for marginal and conditional R²;
#'   [lme4::VarCorr()] for the underlying computation.
#' @family modeling helpers
#' @export
#' @importFrom lme4 VarCorr
#'
#' @examples
#' \dontrun{
#' library(lme4)
#' m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
#' res <- mysterycall_random_effect_variance(m)
#' cat(res$sentence)
#' }
mysterycall_random_effect_variance <- function(model,
                                               variance_threshold = 0.01,
                                               digits = 3) {
  if (!inherits(model, c("merMod", "glmerMod", "lmerMod", "MixMod", "lme", "glmmTMB"))) {
    stop(
      "`model` must be a fitted mixed model (e.g., glmerMod, lmerMod from lme4).",
      call. = FALSE
    )
  }

  if (!is.numeric(variance_threshold) || length(variance_threshold) != 1L ||
      variance_threshold < 0) {
    stop("`variance_threshold` must be a non-negative numeric scalar.", call. = FALSE)
  }

  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("Package 'lme4' is required. Install with: install.packages('lme4')",
         call. = FALSE)
  }

  withCallingHandlers(
    {
      vc    <- lme4::VarCorr(model)
      vc_df <- as.data.frame(vc)
    },
    warning = function(w) {
      if (grepl("singular", conditionMessage(w), ignore.case = TRUE))
        invokeRestart("muffleWarning")
    }
  )

  random_variance      <- vc_df$vcov[1L]
  random_effect_group  <- as.character(vc_df$grp[1L])

  # sc may be NA for Poisson family (no residual scale)
  sc               <- attr(vc, "sc")
  residual_variance <- if (!is.null(sc) && !is.na(sc) && sc != 0) sc^2 else NA_real_

  # ICC
  icc <- if (!is.na(residual_variance) && (random_variance + residual_variance) > 0) {
    random_variance / (random_variance + residual_variance)
  } else {
    NA_real_
  }

  # Add Significant flag
  vc_df$Significant <- ifelse(vc_df$vcov > variance_threshold, "Yes", "No")

  # Tiered interpretation
  interpretation <- if (is.na(icc)) {
    NA_character_
  } else if (icc >= 0.75) {
    "high"
  } else if (icc >= 0.5) {
    "moderate"
  } else if (icc >= 0.25) {
    "low to moderate"
  } else {
    "low"
  }

  # Build sentence
  if (is.na(icc)) {
    sentence <- "ICC cannot be computed for this model family."
  } else {
    interp_text <- switch(
      interpretation,
      "high"           = paste0(
        "An ICC of ", round(icc, digits), " is considered high, indicating that ",
        "a substantial proportion of the total variance is attributable to ",
        "differences between groups of '", random_effect_group, "'."),
      "moderate"       = paste0(
        "An ICC of ", round(icc, digits), " is considered moderate, indicating ",
        "meaningful clustering within groups of '", random_effect_group, "'."),
      "low to moderate" = paste0(
        "An ICC of ", round(icc, digits), " is considered low to moderate, ",
        "suggesting some clustering within groups of '", random_effect_group, "'."),
      "low"            = paste0(
        "An ICC of ", round(icc, digits), " is considered low, suggesting that ",
        "most variance is at the individual level rather than between groups of '",
        random_effect_group, "'.")
    )

    sentence <- paste0(
      "The intraclass correlation (ICC) of the model for the random effect group '",
      random_effect_group, "' is ", round(icc, digits), ". ",
      interp_text
    )
  }

  list(
    icc                  = icc,
    random_variance      = random_variance,
    residual_variance    = residual_variance,
    random_effect_group  = random_effect_group,
    var_table            = vc_df,
    interpretation       = interpretation,
    sentence             = sentence
  )
}
