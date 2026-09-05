#' Stratum-specific ORs and omnibus LRT for a fitted interaction term
#'
#' @name mysterycall_interaction_table
NULL

# ---------------------------------------------------------------------------
# Internal helper: format a p-value for interaction table display
# ---------------------------------------------------------------------------
.fmt_interaction_pval <- function(p, digits = 3L) {
  mysterycall_format_p(p, digits = digits)
}

#' Stratum-specific ORs and omnibus LRT for a fitted interaction term
#'
#' Given a [mysterycall_logistic_model()] object whose `$model` already
#' contains an interaction term (e.g. `insurance:specialty`), this function
#' extracts the interaction rows from `$or_table`, performs an omnibus
#' likelihood-ratio test (LRT) by refitting the model without the interaction,
#' and returns a tidy list suitable for manuscript reporting.
#'
#' The LRT refits the model with `update()` dropping only the
#' `var1:var2` term, then calls [stats::anova()] on the two models.  If the
#' refit fails for any reason (e.g. convergence, missing `lme4`, or a `NULL`
#' `$model` in a fake object) the LRT p-value is set to `NA` with a warning
#' rather than stopping.
#'
#' @param fit A `mysterycall_logistic_model` object returned by
#'   [mysterycall_logistic_model()].  The `$model` element must have been
#'   fitted with the interaction term `var1:var2` (or `var1*var2`) in the
#'   fixed-effects formula; otherwise no rows will be found and the function
#'   stops with an informative message.
#' @param var1 Character scalar.  First variable in the interaction
#'   (e.g. `"insurance"`).
#' @param var2 Character scalar.  Second variable in the interaction
#'   (e.g. `"specialty"`).
#' @param conf_level Numeric scalar strictly between 0 and 1.  Confidence
#'   level used to label CIs in the printed output.  Default `0.95`.
#' @param digits Non-negative integer scalar.  Decimal places for ORs and the
#'   LRT p-value in formatted output.  Default `2L`.
#'
#' @return A list of class `mysterycall_interaction_table` containing:
#' \describe{
#'   \item{`interaction_ors`}{[tibble::tibble()] with one row per interaction
#'     contrast and columns `term`, `or`, `ci_lower`, `ci_upper`,
#'     `p_value_fmt`.  ORs and CIs are rounded to `digits` places.}
#'   \item{`lrt_p`}{Numeric.  Omnibus LRT p-value (`NA` if the refit failed).}
#'   \item{`lrt_p_fmt`}{Character.  Formatted LRT p-value (e.g. `"0.003"` or
#'     `"< 0.001"`).}
#'   \item{`sentence`}{Character.  Ready-to-paste manuscript footnote, e.g.
#'     `"The interaction between insurance and specialty was statistically
#'     significant (LRT p=0.003)."`}
#'   \item{`var1`}{Character.  Echo of the `var1` argument.}
#'   \item{`var2`}{Character.  Echo of the `var2` argument.}
#'   \item{`digits`}{Integer.  Echo of the `digits` argument.}
#'   \item{`conf_level`}{Numeric.  Echo of the `conf_level` argument.}
#' }
#'
#' @section Manuscript use:
#' Paste `result$sentence` directly into a Table footnote.  Use
#' `result$interaction_ors` as a supplemental panel or within-table stratum
#' block.
#'
#' @importFrom tibble tibble
#' @importFrom stats anova as.formula
#' @family outcomes
#' @seealso [mysterycall_logistic_model()], [mysterycall_forest_plot()]
#' @export
#'
#' @examples
#' # Fake a mysterycall_logistic_model object -- no lme4 required.
#' # The LRT refit will be caught by tryCatch (model = NULL) and lrt_p = NA.
#' fake_or_table <- data.frame(
#'   term        = c("(Intercept)",
#'                   "insuranceMedicaid",
#'                   "specialtyGYN",
#'                   "insuranceMedicaid:specialtyGYN",
#'                   "insuranceMedicaid:specialtyOB"),
#'   estimate    = c( 0.80, -0.20,  0.15, -0.45,  0.31),
#'   se          = c( 0.18,  0.14,  0.12,  0.21,  0.19),
#'   z_value     = c( 4.44, -1.43,  1.25, -2.14,  1.63),
#'   p_value     = c( 0.001,  0.153,  0.211,  0.032,  0.103),
#'   p_value_fmt = c("< 0.001", "0.153", "0.211", "0.032", "0.103"),
#'   or          = c( 2.23,  0.82,  1.16,  0.64,  1.36),
#'   ci_lower    = c( 1.56,  0.62,  0.92,  0.42,  0.94),
#'   ci_upper    = c( 3.19,  1.08,  1.46,  0.97,  1.97),
#'   stringsAsFactors = FALSE
#' )
#' fake_fit <- structure(
#'   list(
#'     model      = NULL,
#'     or_table   = fake_or_table,
#'     n          = 200L,
#'     n_clusters = 40L,
#'     formula    = stats::as.formula(
#'                    "offered ~ insurance * specialty + (1 | physician)"
#'                  )
#'   ),
#'   class = "mysterycall_logistic_model"
#' )
#'
#' result <- mysterycall_interaction_table(fake_fit, "insurance", "specialty")
#' print(result)
mysterycall_interaction_table <- function(fit,
                                          var1,
                                          var2,
                                          conf_level = 0.95,
                                          digits     = 2L) {

  # -- Input validation ---------------------------------------------------------
  if (!inherits(fit, "mysterycall_logistic_model")) {
    stop(
      "`fit` must be a mysterycall_logistic_model object produced by ",
      "mysterycall_logistic_model().",
      call. = FALSE
    )
  }

  if (!is.character(var1) || length(var1) != 1L || !nzchar(trimws(var1))) {
    stop("`var1` must be a non-empty character scalar.", call. = FALSE)
  }
  if (!is.character(var2) || length(var2) != 1L || !nzchar(trimws(var2))) {
    stop("`var2` must be a non-empty character scalar.", call. = FALSE)
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    stop(
      "`conf_level` must be a single number strictly between 0 and 1.",
      call. = FALSE
    )
  }

  digits <- suppressWarnings(as.integer(digits))
  if (length(digits) != 1L || is.na(digits) || digits < 0L) {
    stop("`digits` must be a non-negative integer scalar.", call. = FALSE)
  }

  or_table <- fit$or_table
  if (is.null(or_table) || !is.data.frame(or_table)) {
    stop(
      "fit$or_table is missing or not a data.frame. ",
      "Re-run mysterycall_logistic_model() to produce a valid fit object.",
      call. = FALSE
    )
  }
  if (!"term" %in% names(or_table)) {
    stop("fit$or_table has no 'term' column.", call. = FALSE)
  }

  # -- Extract interaction rows -------------------------------------------------
  pattern  <- paste0(var1, ".*", var2, "|", var2, ".*", var1)
  int_mask <- grepl(pattern, or_table$term, perl = TRUE)
  int_rows <- or_table[int_mask, , drop = FALSE]

  if (nrow(int_rows) == 0L) {
    stop(sprintf(
      paste0(
        "No interaction rows found in fit$or_table for variables '%s' and '%s'.\n",
        "  Ensure the model was fitted with an interaction term such as\n",
        "  '%s:%s' or '%s*%s' among the predictors."
      ),
      var1, var2, var1, var2, var1, var2
    ), call. = FALSE)
  }

  # Resolve p_value_fmt column (may or may not be present in a fake object)
  p_val_col <- if ("p_value_fmt" %in% names(int_rows)) {
    int_rows$p_value_fmt
  } else if ("p_value" %in% names(int_rows)) {
    .fmt_interaction_pval(int_rows$p_value, digits = 3L)
  } else {
    rep(NA_character_, nrow(int_rows))
  }

  required_numeric <- c("or", "ci_lower", "ci_upper")
  missing_cols <- setdiff(required_numeric, names(int_rows))
  if (length(missing_cols)) {
    stop(sprintf(
      "fit$or_table is missing required column(s): %s.",
      paste(missing_cols, collapse = ", ")
    ), call. = FALSE)
  }

  interaction_ors <- tibble::tibble(
    term        = int_rows$term,
    or          = round(int_rows$or,       digits),
    ci_lower    = round(int_rows$ci_lower, digits),
    ci_upper    = round(int_rows$ci_upper, digits),
    p_value_fmt = p_val_col
  )

  # -- Omnibus LRT: refit without the interaction term -------------------------
  lrt_p <- tryCatch(
    {
      if (!requireNamespace("lme4", quietly = TRUE)) {
        warning(
          "Package 'lme4' is not available; LRT p-value set to NA.",
          call. = FALSE
        )
        NA_real_
      } else if (is.null(fit$model)) {
        warning(
          "fit$model is NULL (likely a fake/stub object); LRT p-value set to NA.",
          call. = FALSE
        )
        NA_real_
      } else {
        drop_str      <- paste0(". ~ . - ", var1, ":", var2)
        model_reduced <- update(fit$model, stats::as.formula(drop_str))
        lrt_result    <- stats::anova(model_reduced, fit$model)
        lrt_result[["Pr(>Chisq)"]][[2L]]
      }
    },
    error = function(e) {
      warning(
        sprintf(
          "LRT refitting failed: %s\n  lrt_p set to NA.",
          conditionMessage(e)
        ),
        call. = FALSE
      )
      NA_real_
    }
  )

  # -- Format LRT p-value -------------------------------------------------------
  lrt_p_fmt <- if (is.na(lrt_p)) {
    "NA"
  } else if (lrt_p < 0.001) {
    "< 0.001"
  } else {
    sprintf("%.*f", digits, lrt_p)
  }

  # -- Build manuscript sentence ------------------------------------------------
  sig_phrase <- if (is.na(lrt_p)) {
    "undetermined (LRT could not be computed)"
  } else if (lrt_p < 0.05) {
    "statistically significant"
  } else {
    "not statistically significant"
  }

  sentence <- sprintf(
    "The interaction between %s and %s was %s (LRT p=%s).",
    var1, var2, sig_phrase, lrt_p_fmt
  )

  # -- Return -------------------------------------------------------------------
  structure(
    list(
      interaction_ors = interaction_ors,
      lrt_p           = lrt_p,
      lrt_p_fmt       = lrt_p_fmt,
      sentence        = sentence,
      var1            = var1,
      var2            = var2,
      digits          = digits,
      conf_level      = conf_level
    ),
    class = "mysterycall_interaction_table"
  )
}


#' Print method for mysterycall_interaction_table objects
#'
#' Displays the stratum-specific OR table followed by the omnibus
#' likelihood-ratio test sentence.
#'
#' @param x A `mysterycall_interaction_table` object.
#' @param ... Ignored; present for S3 consistency.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_interaction_table <- function(x, ...) {
  cat(sprintf(
    "Interaction table: %s x %s  (conf_level = %.2f)\n\n",
    x$var1, x$var2, x$conf_level
  ))

  cat("Stratum-specific odds ratios (OR with CI):\n")
  tbl <- as.data.frame(x$interaction_ors)
  names(tbl)[names(tbl) == "p_value_fmt"] <- "p-value"
  print(tbl, row.names = FALSE)

  cat(sprintf(
    "\nOmnibus LRT p-value: %s\n",
    x$lrt_p_fmt
  ))
  cat(sprintf("\n%s\n", x$sentence))

  invisible(x)
}
