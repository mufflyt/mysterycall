#' Model-based predicted mean wait times per group
#'
#' @name predicted_means
NULL

#' Extract predicted mean wait times from a fitted mystery-caller model
#'
#' Computes model-based (marginal) predicted mean wait times on the response
#' (count) scale for each level of a grouping variable, with confidence
#' intervals. This translates incidence rate ratios into absolute day estimates
#' that are easier to interpret clinically.
#'
#' Uses [emmeans::emmeans()] when available (preferred), or
#' [marginaleffects::predictions()] as a fallback.
#'
#' @param model_result A `mysterycall_poisson_model` or `mysterycall_nb_model`
#'   object.
#' @param group_col Character scalar. Name of the grouping variable (e.g.
#'   `"insurance"`). Must match a fixed-effect term in the model.
#' @param data Optional data frame. Required when using the
#'   `marginaleffects` fallback path. When using `emmeans`, `data` is not
#'   needed (the model frame is used internally).
#' @param conf_level Numeric. Confidence level for intervals. Default `0.95`.
#' @param ... Additional arguments forwarded to `emmeans::emmeans()` or
#'   `marginaleffects::predictions()`.
#'
#' @return A data frame of class `mysterycall_predicted_means` with columns:
#' \describe{
#'   \item{`group`}{Character. Group level label.}
#'   \item{`predicted_mean`}{Numeric. Back-transformed (response-scale) predicted
#'     mean wait days.}
#'   \item{`se`}{Numeric. Standard error on the response scale.}
#'   \item{`ci_lower`}{Numeric. Lower confidence interval bound.}
#'   \item{`ci_upper`}{Numeric. Upper confidence interval bound.}
#' }
#' The attribute `"group_col"` stores the name of the grouping variable.
#'
#' @family outcomes
#' @seealso [mysterycall_irr_to_days()] for converting IRRs to day differences;
#'   [mysterycall_marginal_effects()] for average marginal effects.
#' @export
#'
#' @examplesIf requireNamespace("lme4", quietly = TRUE) && requireNamespace("emmeans", quietly = TRUE)
#' set.seed(7)
#' df <- data.frame(
#'   wait = rpois(60, 21),
#'   ins  = rep(c("Medicaid", "BCBS"), 30),
#'   phys = rep(paste0("Dr", 1:10), each = 6),
#'   stringsAsFactors = FALSE
#' )
#' fit   <- mysterycall_poisson_model(df, "wait", "ins", "phys")
#' pmean <- mysterycall_predicted_means(fit, "ins")
#' print(pmean)
mysterycall_predicted_means <- function(model_result,
                                         group_col,
                                         data       = NULL,
                                         conf_level = 0.95,
                                         ...) {

  if (!inherits(model_result, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    stop(
      "`model_result` must be a `mysterycall_poisson_model` or `mysterycall_nb_model`.",
      call. = FALSE
    )
  }
  if (is.null(model_result$model)) {
    stop(
      "`model_result$model` is NULL. Refit the model with a real dataset before extracting predicted means.",
      call. = FALSE
    )
  }
  if (!is.character(group_col) || length(group_col) != 1L) {
    stop("`group_col` must be a single character string.", call. = FALSE)
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    stop("`conf_level` must be a single number in (0, 1).", call. = FALSE)
  }

  if (requireNamespace("emmeans", quietly = TRUE)) {
    out <- .predicted_via_emmeans(model_result, group_col, conf_level, ...)
  } else if (requireNamespace("marginaleffects", quietly = TRUE)) {
    if (is.null(data)) {
      stop(
        "`data` is required when using the marginaleffects fallback. ",
        "Alternatively install emmeans: install.packages('emmeans')",
        call. = FALSE
      )
    }
    out <- .predicted_via_marginaleffects(model_result, group_col, data, conf_level, ...)
  } else {
    stop(
      "Either 'emmeans' or 'marginaleffects' is required. ",
      "Install with: install.packages('emmeans')",
      call. = FALSE
    )
  }

  attr(out, "group_col") <- group_col
  structure(out, class = c("mysterycall_predicted_means", "data.frame"))
}

.predicted_via_emmeans <- function(model_result, group_col, conf_level, ...) {
  specs <- stats::as.formula(paste0("~", group_col))
  em <- tryCatch(
    suppressMessages(
      emmeans::emmeans(model_result$model,
                       specs      = specs,
                       type       = "response",
                       level      = conf_level,
                       ...)
    ),
    error = function(e) {
      stop("emmeans::emmeans() failed: ", conditionMessage(e), call. = FALSE)
    }
  )
  s <- as.data.frame(summary(em))

  rate_col <- intersect(c("rate", "response", "emmean"), names(s))[1L]
  se_col   <- intersect(c("SE"), names(s))[1L]
  lo_col   <- intersect(c("asymp.LCL", "lower.CL", "lower.HPD"), names(s))[1L]
  hi_col   <- intersect(c("asymp.UCL", "upper.CL", "upper.HPD"), names(s))[1L]

  data.frame(
    group          = as.character(s[[group_col]]),
    predicted_mean = as.numeric(s[[rate_col]]),
    se             = as.numeric(s[[se_col]]),
    ci_lower       = as.numeric(s[[lo_col]]),
    ci_upper       = as.numeric(s[[hi_col]]),
    stringsAsFactors = FALSE
  )
}

.predicted_via_marginaleffects <- function(model_result, group_col, data,
                                            conf_level, ...) {
  alpha  <- 1 - conf_level
  preds  <- tryCatch(
    suppressMessages(
      marginaleffects::predictions(
        model_result$model,
        newdata  = data,
        by       = group_col,
        conf_level = conf_level,
        ...)
    ),
    error = function(e) {
      stop("marginaleffects::predictions() failed: ", conditionMessage(e),
           call. = FALSE)
    }
  )
  s <- as.data.frame(preds)

  est_col <- intersect(c("estimate", "predicted", "Estimate"), names(s))[1L]
  se_col  <- intersect(c("std.error", "SE", "std_error"), names(s))[1L]
  lo_col  <- intersect(c("conf.low", "lower", "2.5 %"), names(s))[1L]
  hi_col  <- intersect(c("conf.high", "upper", "97.5 %"), names(s))[1L]

  data.frame(
    group          = as.character(s[[group_col]]),
    predicted_mean = as.numeric(s[[est_col]]),
    se             = as.numeric(s[[se_col]]),
    ci_lower       = as.numeric(s[[lo_col]]),
    ci_upper       = as.numeric(s[[hi_col]]),
    stringsAsFactors = FALSE
  )
}


#' Print method for mysterycall_predicted_means
#'
#' @param x A `mysterycall_predicted_means` object.
#' @param digits Integer. Decimal places for predicted means and CIs.
#'   Default `1`.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_predicted_means <- function(x, digits = 1, ...) {
  cat("Model-predicted wait times (days):\n")
  disp <- x
  class(disp) <- "data.frame"
  disp$predicted_mean <- round(disp$predicted_mean, digits)
  disp$se             <- round(disp$se,             digits)
  disp$ci_lower       <- round(disp$ci_lower,       digits)
  disp$ci_upper       <- round(disp$ci_upper,       digits)
  print(disp, row.names = FALSE)

  if (nrow(x) >= 2L) {
    ord  <- order(x$predicted_mean)
    lo_r <- x[ord[1L], ]
    hi_r <- x[ord[nrow(x)], ]
    cat(sprintf(
      "\nPredicted wait times ranged from %.1f days (%s) to %.1f days (%s, 95%% CI %.1f-%.1f).\n",
      lo_r$predicted_mean, lo_r$group,
      hi_r$predicted_mean, hi_r$group,
      hi_r$ci_lower, hi_r$ci_upper
    ))
  }
  invisible(x)
}
