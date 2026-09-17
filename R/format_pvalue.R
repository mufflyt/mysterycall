#' Format p-values consistently across the package
#'
#' @name format_pvalue
#' @keywords internal
NULL

# Canonical p-value formatter: a spaced "< 0.001" below the display threshold,
# otherwise a fixed-decimal string; NA stays NA. Vectorised. This is the single
# source of truth so every manuscript table and sentence prints p-values the
# same way (previously some formatters emitted the unspaced "<0.001").
#
# Retained as the internal spelling used across the package; the behaviour now
# lives in the exported mysterycall_format_p(), so there is genuinely one
# implementation rather than a comment claiming there is.
.mc_format_p <- function(p, digits = 3L) {
  mysterycall_format_p(p, digits = digits)
}
