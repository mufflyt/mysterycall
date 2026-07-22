#' Test for overdispersion and generate an interpretive sentence
#'
#' @name mysterycall_overdispersion_sentence
NULL

#' Pearson-based overdispersion test with manuscript-ready sentence
#'
#' Computes Pearson chi-square–based dispersion statistics for a fitted
#' model (GLM or GLMER), categorises the result, and returns a
#' manuscript-ready sentence. Suitable for Poisson and quasi-Poisson models
#' as well as linear models (\code{lm}) which also expose
#' \code{df.residual()}.
#'
#' @param model A fitted model with \code{df.residual()},
#'   \code{residuals(type = "pearson")}, and \code{df.residual > 0}.
#' @param digits_ratio Integer scalar. Decimal places for the dispersion ratio
#'   in the sentence. Default \code{2}.
#' @param digits_p Integer scalar. Decimal places for the p-value in the
#'   sentence. Default \code{3}.
#'
#' @return A named list with:
#'   \describe{
#'     \item{\code{chisq}}{Numeric. Pearson chi-square statistic.}
#'     \item{\code{ratio}}{Numeric. Dispersion ratio (\eqn{\chi^2 / df}).}
#'     \item{\code{df}}{Numeric. Residual degrees of freedom.}
#'     \item{\code{p_value}}{Numeric. Upper-tail chi-square p-value.}
#'     \item{\code{p_formatted}}{Character. Formatted p-value string.}
#'     \item{\code{interpretation}}{Character. Tiered interpretation message.}
#'     \item{\code{sentence}}{Character. Full manuscript sentence.}
#'     \item{\code{overdispersed}}{Logical. \code{TRUE} when
#'       \code{p_value < 0.05} AND \code{ratio > 1.2}.}
#'   }
#'
#' @seealso [mysterycall_random_effect_variance()] for random-effect ICC;
#'   [mysterycall_r2_sentence()] for R² interpretation.
#' @family modeling helpers
#' @export
#' @importFrom stats df.residual residuals pchisq
#' @importFrom checkmate assert_integerish
#'
#' @examples
#' m <- glm(breaks ~ wool + tension, data = warpbreaks, family = poisson)
#' res <- mysterycall_overdispersion_sentence(m)
#' cat(res$sentence)
mysterycall_overdispersion_sentence <- function(model,
                                                digits_ratio = 2,
                                                digits_p = 3) {
  checkmate::assert_integerish(digits_ratio, lower = 0, len = 1)
  checkmate::assert_integerish(digits_p,     lower = 0, len = 1)

  rdf <- tryCatch(
    stats::df.residual(model),
    error = function(e) {
      stop("`model` does not expose `df.residual()`.", call. = FALSE)
    }
  )

  if (is.null(rdf) || is.na(rdf)) {
    stop("`df.residual(model)` returned NULL or NA.", call. = FALSE)
  }
  if (rdf <= 0) {
    stop(
      "Residual degrees of freedom is 0 or negative; overdispersion cannot be computed.",
      call. = FALSE
    )
  }

  rp <- tryCatch(
    stats::residuals(model, type = "pearson"),
    error = function(e) {
      stop(
        paste0("Could not extract Pearson residuals: ", conditionMessage(e)),
        call. = FALSE
      )
    }
  )

  Pearson_chisq <- sum(rp^2)
  ratio         <- Pearson_chisq / rdf
  p_value       <- stats::pchisq(Pearson_chisq, df = rdf, lower.tail = FALSE)

  p_formatted <- if (p_value < 0.001) {
    "< 0.001"
  } else {
    format(round(p_value, digits_p), nsmall = digits_p)
  }

  interpretation <- if (p_value < 0.05) {
    if (ratio > mysterycall_overdispersion_threshold()) {
      paste0(
        "Significant overdispersion detected (ratio = ", round(ratio, digits_ratio),
        "). Consider using a Negative Binomial model to account for overdispersion."
      )
    } else if (ratio > 1.2) {
      paste0(
        "Mild overdispersion detected (ratio = ", round(ratio, digits_ratio),
        "), below the negative-binomial switch threshold; the Poisson model may still be adequate."
      )
    } else {
      paste0(
        "Slight overdispersion detected (ratio = ", round(ratio, digits_ratio),
        "). The Poisson model may still be adequate; monitor model diagnostics."
      )
    }
  } else {
    paste0(
      "No significant overdispersion detected (ratio = ", round(ratio, digits_ratio),
      "). The Poisson model appears adequate."
    )
  }

  sentence <- paste0(
    "The Pearson dispersion ratio is ", round(ratio, digits_ratio),
    " (chi-square = ", round(Pearson_chisq, digits_ratio),
    ", df = ", round(rdf, 0),
    ", p = ", p_formatted, "). ",
    interpretation
  )

  overdispersed <- (p_value < 0.05) && (ratio > mysterycall_overdispersion_threshold())

  list(
    chisq          = Pearson_chisq,
    ratio          = ratio,
    df             = rdf,
    p_value        = p_value,
    p_formatted    = p_formatted,
    interpretation = interpretation,
    sentence       = sentence,
    overdispersed  = overdispersed
  )
}
