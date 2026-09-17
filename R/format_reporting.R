#' Format a confidence interval for reporting
#'
#' Joins the endpoints of an interval into the string a manuscript prints.
#' SAMPL asks that the endpoints be separated with `"to"` rather than a hyphen
#' or a dash, so that a negative lower bound cannot be misread as a minus sign:
#' `-0.45--0.12` is ambiguous, `-0.45 to -0.12` is not.
#'
#' The separator is an argument rather than a constant because house styles
#' differ. `gtsummary`'s JAMA and Lancet journal themes make the same choice
#' this default does, exposing it as a `ci.sep` theme setting; a journal that
#' insists on a dash can be served by passing `sep` or by setting
#' `options(mysterycall.ci_sep = )` once, rather than by editing every
#' formatter in the package.
#'
#' @param lower,upper Numeric vectors of interval endpoints, recycled against
#'   each other. `NA` in either endpoint yields `NA` for that element.
#' @param digits Integer. Decimal places for both endpoints. Default `2`.
#' @param sep Character scalar placed between the endpoints. Defaults to
#'   `getOption("mysterycall.ci_sep", " to ")`, so a whole document can be
#'   switched with one option.
#'
#' @return A character vector the length of the recycled inputs.
#'
#' @references
#' Lang TA, Altman DG. Basic statistical reporting for articles published in
#' biomedical journals: the "Statistical Analyses and Methods in the Published
#' Literature" or the SAMPL Guidelines. *International Journal of Nursing
#' Studies*. 2015;52(1):5-9. \doi{10.1016/j.ijnurstu.2014.09.006}
#'
#' The `sep` argument follows the pattern set by `gtsummary`'s journal themes
#' (`gtsummary::theme_gtsummary_journal("jama")`, MIT licensed), which likewise
#' separate interval endpoints with "to" and expose the separator as a setting.
#'
#' @family table helpers
#' @seealso [mysterycall_format_p()] for the matching p-value formatter, and
#'   [mysterycall_sampl_checklist()] for the reporting items these serve.
#' @examples
#' mysterycall_format_ci(1.05, 1.57)
#' mysterycall_format_ci(-0.45, -0.12)
#' mysterycall_format_ci(c(1.05, NA), c(1.57, 2.0))
#' mysterycall_format_ci(0.4, 0.9, digits = 3, sep = " - ")
#' @export
mysterycall_format_ci <- function(lower,
                                  upper,
                                  digits = 2L,
                                  sep    = getOption("mysterycall.ci_sep", " to ")) {
  checkmate::assert_numeric(lower)
  checkmate::assert_numeric(upper)
  checkmate::assert_count(digits)
  checkmate::assert_string(sep)

  n <- max(length(lower), length(upper))
  if (n == 0L) return(character(0))
  lower <- rep_len(lower, n)
  upper <- rep_len(upper, n)

  fmt <- paste0("%.", as.integer(digits), "f")
  out <- paste0(sprintf(fmt, lower), sep, sprintf(fmt, upper))
  out[is.na(lower) | is.na(upper)] <- NA_character_
  out
}


#' Format a p-value for reporting
#'
#' The package's single source of truth for printing p-values. SAMPL asks for
#' exact values rather than inequalities against alpha, so a p-value is printed
#' to `digits` decimal places and only collapses to `"< 0.001"` below the
#' threshold at which the extra digits stop being meaningful. `"NS"` is never
#' produced.
#'
#' @param p Numeric vector of p-values. `NA` stays `NA`.
#' @param digits Integer. Decimal places for values at or above `threshold`.
#'   Default `3`.
#' @param name Character scalar or `NULL`. When `NULL` (default) the bare value
#'   is returned (`"0.043"`, `"< 0.001"`). When given, the result is prefixed
#'   for prose: `name = "p"` yields `"p = 0.043"` and `"p < 0.001"`.
#' @param threshold Numeric. Values below this print as `"< threshold"`.
#'   Default `0.001`.
#'
#' @return A character vector the length of `p`.
#'
#' @references
#' Lang TA, Altman DG. Basic statistical reporting for articles published in
#' biomedical journals: the SAMPL Guidelines. *International Journal of Nursing
#' Studies*. 2015;52(1):5-9. \doi{10.1016/j.ijnurstu.2014.09.006}
#'
#' @family table helpers
#' @seealso [mysterycall_format_ci()] for the matching interval formatter.
#' @examples
#' mysterycall_format_p(c(0.0431, 0.0004, NA))
#' mysterycall_format_p(0.0431, name = "p")
#' mysterycall_format_p(0.0004, name = "p")
#' @export
mysterycall_format_p <- function(p,
                                 digits    = 3L,
                                 name      = NULL,
                                 threshold = 0.001) {
  checkmate::assert_numeric(p)
  checkmate::assert_count(digits)
  checkmate::assert_number(threshold, lower = 0, upper = 1)
  if (!is.null(name)) checkmate::assert_string(name)

  digits <- as.integer(digits)
  small  <- !is.na(p) & p < threshold
  thr    <- sub("0+$", "", sprintf("%.10f", threshold))

  out <- ifelse(small, paste0("< ", thr), sprintf("%.*f", digits, p))
  if (!is.null(name)) {
    out <- ifelse(small, paste0(name, " ", out), paste0(name, " = ", out))
  }
  out[is.na(p)] <- NA_character_
  out
}
