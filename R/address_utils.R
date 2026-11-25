#' Address cleaning utilities
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name address_utils
NULL

#' Extract a clean 5-digit ZIP code from a dirty string
#'
#' Strips all non-digit characters, validates minimum length, takes the first
#' five digits, and left-pads with zeros if fewer than five digits remain.
#' Returns `NA_character_` for inputs that cannot be parsed into a plausible
#' ZIP code.
#'
#' @param x Character vector of raw ZIP/postal-code strings (e.g. `"80203"`,
#'   `"80203-1234"`, `"  80203 "`, `"8020"` -> `"08020"`).
#'
#' @return Character vector the same length as `x`. Each element is a
#'   5-character string of digits or `NA_character_`.
#'
#' @family data management
#' @seealso [mysterycall_clean_zip()] for the exported ZIP cleaner (also splits
#'   multi-ZIP cells); [mysterycall_normalize_zip5()] for the address-pipeline
#'   variant.
#' @keywords internal
#'
#' @examples
#' mysterycall:::mysterycall_extract_zip5(c("80203-1234", " 80203 ", "8020", "abc", NA))
mysterycall_extract_zip5 <- function(x) {
  # Thin contract wrapper over the shared core (see .zip5_core in clean_zip.R):
  # this variant alone treats a digit run shorter than 3 as not-a-ZIP, because
  # a two-digit fragment in a free-text address is never a dropped-leading-zero
  # ZIP, whereas padding it would fabricate one.
  .zip5_core(x, min_digits = 3L)
}
