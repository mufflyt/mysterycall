#' Clean and standardize ZIP codes to five digits
#'
#' Two ZIP hygiene steps recur in every audit that joins practices to
#' ZIP-indexed data (income, rurality, HRR): a cell sometimes holds more than
#' one ZIP (`"03110, 03756"`), and New England / Puerto Rico ZIPs lose their
#' leading zero the moment the column is read as a number (`3110` for `03110`).
#' This takes the first ZIP when several are present, strips a ZIP+4 suffix, and
#' left-pads to five digits so the key joins correctly.
#'
#' @param x Character or numeric vector of ZIP codes.
#'
#' @return A character vector the length of `x`: a five-character ZIP, or `NA`
#'   for entries with no digits.
#'
#' @family data integrity
#' @seealso [mysterycall_add_hhi()]. Related ZIP helpers:
#'   [mysterycall_extract_zip5()] (strip ZIP+4 / pad, single-ZIP cells) and
#'   [mysterycall_normalize_zip5()] (address-pipeline variant). `clean_zip()`
#'   additionally splits multi-ZIP cells (`"03110, 03756"` -> first).
#' @examples
#' mysterycall_clean_zip(c("03110, 03756", 3110, "12345-6789", "", NA))
#' # -> c("03110", "03110", "12345", NA, NA)
#' @export
mysterycall_clean_zip <- function(x) {
  x <- as.character(x)
  # First ZIP when several are separated by comma / semicolon / slash --
  # the one behavior this exported wrapper adds over the shared core.
  first <- vapply(x, function(s) {
    if (is.na(s)) return(NA_character_)
    trimws(strsplit(trimws(s), "[,;/]")[[1L]][1L])
  }, character(1L), USE.NAMES = FALSE)
  .zip5_core(first, min_digits = 1L)
}

#' Canonical ZIP-5 extraction core
#'
#' The single implementation behind [mysterycall_clean_zip()],
#' `mysterycall_extract_zip5()` and `mysterycall_normalize_zip5()`. All three
#' used to re-implement extract-first-digit-run / truncate / left-pad
#' independently, and the copies diverged in exactly the edge cases each was
#' written to fix (a dropped leading zero survived in one copy and not
#' another). The only contract difference that survives consolidation is
#' `min_digits`: `extract_zip5` treats runs shorter than 3 digits as
#' not-a-ZIP (`NA`), while the other two left-pad even a single digit.
#'
#' The first digit RUN -- not the first five digits of the concatenated digit
#' string -- is what gets padded, because the hyphen in `"7001-1234"` is the
#' only thing marking where the 5-digit part ends when its leading zero was
#' dropped; concatenating first yields `"70011"` there. Digit runs that are
#' not a ZIP shape are `NA` rather than truncated: 6 or 10+ digits cannot be
#' a ZIP or a lost-zero ZIP+4 (a phone number in the ZIP column used to
#' become a ZIP), 7-8 digits are a ZIP+4 that lost its leading zero(s), and
#' scientific notation is unrecoverable corruption, not digits.
#'
#' @param x Character or numeric vector.
#' @param min_digits Minimum digit-run length accepted as a ZIP candidate.
#' @return Character vector of 5-digit ZIPs or `NA`.
#' @keywords internal
.zip5_core <- function(x, min_digits = 1L) {
  if (is.numeric(x)) {
    # Numeric ZIPs are integer-valued identifiers, not measurements: format
    # without scientific notation or decimal noise before digit extraction.
    x <- ifelse(is.na(x), NA_character_, sprintf("%.0f", x))
  } else {
    x <- as.character(x)
  }
  vapply(x, function(s) {
    if (is.na(s)) return(NA_character_)
    s <- trimws(s)
    if (!nzchar(s)) return(NA_character_)
    # Scientific notation is a corrupted number, not a ZIP: there is no way
    # to know which digits were dropped, so it is invalid rather than
    # reassembled into a different valid-looking ZIP ("1.2e5" -> "00001").
    if (grepl("[0-9][eE][+-]?[0-9]", s)) return(NA_character_)
    m <- regmatches(s, regexpr("[0-9]+", s))
    if (length(m) == 0L) return(NA_character_)
    d <- m[1L]
    len <- nchar(d)
    if (len < min_digits) return(NA_character_)
    d <- if (len <= 5L) {
      # 1-2 digit runs are still padded per each wrapper's own min_digits
      # contract; 3-4 digit runs are a ZIP that lost its leading zero(s)
      paste0(strrep("0", 5L - len), d)
    } else if (len == 6L) {
      # Not a ZIP shape: no lost-zero chain lands here, and truncating used
      # to fabricate a different valid-looking ZIP
      return(NA_character_)
    } else if (len <= 8L) {
      # Unseparated ZIP+4 that ALSO lost its leading zero(s): pad back to 9
      # digits, then keep the 5-digit part ("21011234" -> "02101", not
      # "21011")
      substr(paste0(strrep("0", 9L - len), d), 1L, 5L)
    } else if (len == 9L) {
      substr(d, 1L, 5L)   # ZIP+4 written without a dash
    } else {
      # 10+ digits: a phone number or other identifier typed into the ZIP
      # column, never a ZIP -- invalid rather than truncated
      return(NA_character_)
    }
    d
  }, character(1L), USE.NAMES = FALSE)
}
