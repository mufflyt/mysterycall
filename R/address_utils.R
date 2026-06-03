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
#' @export
#'
#' @examples
#' mysterycall_extract_zip5(c("80203-1234", " 80203 ", "8020", "abc", NA))
mysterycall_extract_zip5 <- function(x) {
  if (!is.character(x)) x <- as.character(x)

  .extract_one <- function(s) {
    if (is.na(s)) return(NA_character_)
    digits <- gsub("[^0-9]", "", s)
    if (nchar(digits) < 3L) return(NA_character_)
    zip5 <- substr(digits, 1L, 5L)
    # Left-pad to 5 digits (e.g. NJ zip "07001" stored as "7001")
    formatC(as.integer(zip5), width = 5L, flag = "0")
  }

  vapply(x, .extract_one, character(1L), USE.NAMES = FALSE)
}
