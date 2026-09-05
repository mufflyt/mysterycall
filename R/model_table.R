#' Word-ready IRR table from a fitted Poisson model
#'
#' @name mysterycall_model_table
NULL


#' Format a Poisson GLMER IRR table for Word / flextable output
#'
#' Extracts and formats the fixed-effects table from a
#' `mysterycall_poisson_model` result into a print-ready data frame. Column
#' names and values follow standard epidemiological reporting conventions
#' (IRR with 95% CI in a single "IRR (95% CI)" column, formatted p-values).
#' The returned data frame can be passed directly to `flextable::flextable()`
#' or `knitr::kable()` for Word/HTML output.
#'
#' @param x A `mysterycall_poisson_model` object from [mysterycall_poisson_model()]
#'   or a `mysterycall_nb_model` object from [mysterycall_nb_model()].
#' @param include_intercept Logical. When `FALSE` (default) the `(Intercept)`
#'   row is dropped.
#' @param digits Integer. Decimal places for IRR and CI values. Default `2`.
#' @param irr_col Character. Name of the combined "IRR (95% CI)" column.
#'   Default `"IRR (95% CI)"`.
#' @param p_col Character. Name of the p-value column. Default `"p-value"`.
#' @param term_col Character. Name of the term column. Default `"Term"`.
#'
#' @return A data frame (tibble) with columns `term_col`, `irr_col`, and
#'   `p_col`. One row per fixed-effect term.
#'
#' @family table helpers
#' @seealso [mysterycall_poisson_model()], [mysterycall_irr_plot()]
#' @export
#'
#' @examples
#' if (requireNamespace("lme4", quietly = TRUE)) {
#'   set.seed(1978)
#'   df <- data.frame(
#'     wait_days = rpois(40, lambda = 18),
#'     insurance = rep(c("Medicaid", "BCBS"), each = 20),
#'     physician = rep(paste0("Dr_", 1:8), each = 5),
#'     stringsAsFactors = FALSE
#'   )
#'   result <- suppressWarnings(mysterycall_poisson_model(
#'     df, "wait_days", "insurance", "physician"
#'   ))
#'   mysterycall_model_table(result)
#' }
mysterycall_model_table <- function(x,
                                     include_intercept = FALSE,
                                     digits            = 2L,
                                     irr_col           = "IRR (95% CI)",
                                     p_col             = "p-value",
                                     term_col          = "Term") {

  if (!inherits(x, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    stop("`x` must be a `mysterycall_poisson_model` or `mysterycall_nb_model` object.", call. = FALSE)
  }
  if (!is.numeric(digits) || length(digits) != 1L || digits < 0L) {
    stop("`digits` must be a non-negative integer scalar.", call. = FALSE)
  }

  tbl <- x$irr_table

  if (!include_intercept) {
    tbl <- tbl[tbl$term != "(Intercept)", , drop = FALSE]
  }

  fmt <- function(v) formatC(round(v, digits), format = "f", digits = digits)

  irr_ci <- sprintf("%s (%s to %s)",
                    fmt(tbl$irr),
                    fmt(tbl$ci_lower),
                    fmt(tbl$ci_upper))

  out <- data.frame(
    term_col = tbl$term,
    irr_ci   = irr_ci,
    p_val    = tbl$p_value_fmt,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  names(out) <- c(term_col, irr_col, p_col)

  out
}
