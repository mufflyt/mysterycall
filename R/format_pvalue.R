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
# The threshold is fixed at 0.001 (matching every historical call site); only
# the number of decimals for larger p-values is configurable via `digits`.
.mc_format_p <- function(p, digits = 3L) {
  digits <- as.integer(digits)
  out <- ifelse(p < 0.001, "< 0.001", sprintf("%.*f", digits, p))
  out[is.na(p)] <- NA_character_
  out
}
