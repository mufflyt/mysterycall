#' Compute R-squared values and generate an interpretive sentence for mixed models
#'
#' @name mysterycall_r2_sentence
NULL

#' Compute marginal and conditional R^2 and generate an interpretive sentence
#'
#' Extracts marginal (fixed-effects only) and conditional (fixed + random
#' effects) R^2 values from a fitted mixed model using
#' [performance::r2()], then formats them into a manuscript-ready
#' interpretive paragraph.
#'
#' @param model A fitted mixed model (\code{glmerMod}, \code{lmerMod}, etc.)
#'   compatible with [performance::r2()]. Pure fixed-effects models (e.g.,
#'   \code{lm}, \code{glm}) are not supported and will trigger an error.
#' @param digits Integer scalar. Number of decimal places for R^2 values in
#'   the sentence. Default \code{3}.
#' @param digits_pct Integer scalar. Number of decimal places for percentage
#'   values in the sentence. Default \code{1}.
#'
#' @return A named list with:
#'   \describe{
#'     \item{\code{marginal_r2}}{Numeric. Marginal R^2 (fixed effects only).}
#'     \item{\code{conditional_r2}}{Numeric. Conditional R^2 (fixed + random effects).}
#'     \item{\code{fixed_effects}}{Character vector of fixed-effect term names.}
#'     \item{\code{random_effects}}{Character vector of random-effect group names.}
#'     \item{\code{sentence}}{Character scalar. Full interpretive paragraph.}
#'   }
#'
#' @seealso [mysterycall_random_effect_variance()] for ICC-based random-effect
#'   interpretation; [performance::r2()] for the underlying computation.
#' @family modeling helpers
#' @export
#' @importFrom lme4 fixef ranef
#' @importFrom performance r2
#'
#' @examples
#' \dontrun{
#' library(lme4)
#' m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
#' res <- mysterycall_r2_sentence(m)
#' cat(res$sentence)
#' }
mysterycall_r2_sentence <- function(model, digits = 3, digits_pct = 1) {
  if (!inherits(model, c("merMod", "glmerMod", "lmerMod", "MixMod",
                          "lme", "glmmTMB"))) {
    stop(
      "`model` must be a fitted mixed model (e.g., glmerMod, lmerMod from lme4).",
      call. = FALSE
    )
  }

  if (!requireNamespace("performance", quietly = TRUE)) {
    stop("Package 'performance' is required. Install with: install.packages('performance')",
         call. = FALSE)
  }
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("Package 'lme4' is required. Install with: install.packages('lme4')",
         call. = FALSE)
  }

  r2_values <- tryCatch(
    withCallingHandlers(
      performance::r2(model),
      warning = function(w) {
        if (grepl("singular", conditionMessage(w), ignore.case = TRUE))
          invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      stop(
        paste0("Could not compute R\u00b2 for this model: ", conditionMessage(e)),
        call. = FALSE
      )
    }
  )

  marginal_r2   <- as.numeric(r2_values$R2_marginal)
  conditional_r2 <- as.numeric(r2_values$R2_conditional)

  fixed_effects  <- tryCatch(names(lme4::fixef(model)), error = function(e) character(0))
  random_effects <- tryCatch(names(lme4::ranef(model)), error = function(e) character(0))

  fe_str <- paste(fixed_effects,  collapse = ", ")
  re_str <- paste(random_effects, collapse = ", ")

  sentence <- paste0(
    "The marginal R\u00b2 value of the model is ", round(marginal_r2, digits),
    " and the conditional R\u00b2 value is ", round(conditional_r2, digits), ". ",
    "The marginal R\u00b2 represents the proportion of variance explained by the ",
    "fixed effects (", fe_str, ") alone (",
    round(marginal_r2 * 100, digits_pct), "%). ",
    "The conditional R\u00b2 represents the proportion of variance explained by both ",
    "the fixed effects and the random effects (", re_str, ") combined (",
    round(conditional_r2 * 100, digits_pct), "%)."
  )

  list(
    marginal_r2    = marginal_r2,
    conditional_r2 = conditional_r2,
    fixed_effects  = fixed_effects,
    random_effects = random_effects,
    sentence       = sentence
  )
}
