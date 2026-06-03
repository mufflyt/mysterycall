#' NPI validation utilities
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @name npi_utils
NULL

#' Validate NPI numbers using the official CMS Luhn checksum
#'
#' Implements the CMS-specified Luhn algorithm for 10-digit National Provider
#' Identifiers (NPI). The CMS prepends the constant "80840" to the NPI before
#' computing the checksum, so this is not a generic Luhn check.
#'
#' @param npi Character or numeric vector of NPI values. Non-10-digit values
#'   (after coercing to character) are immediately invalid.
#'
#' @return Logical vector the same length as `npi`. `TRUE` means the NPI
#'   passes the CMS Luhn checksum; `FALSE` means it does not or is malformed.
#'   `NA` inputs return `FALSE`.
#'
#' @seealso [mysterycall_validate_npi()] for row-level NPI validation with
#'   filtering; [mysterycall_get_clinician_data()] to retrieve clinician detail
#'   records for validated NPIs.
#' @family data management
#' @export
#'
#' @examples
#' mysterycall_luhn_check(c("1234567893", "9999999999", NA))
#' # Filter a data frame to valid NPIs:
#' # df[mysterycall_luhn_check(df$npi), ]
mysterycall_luhn_check <- function(npi) {
  .check_one <- function(n) {
    s <- as.character(n)
    if (is.na(s) || !grepl("^[0-9]{10}$", s)) return(FALSE)
    full   <- paste0("80840", s)
    digits <- as.integer(strsplit(full, "")[[1L]])
    len    <- length(digits)
    for (i in seq_along(digits)) {
      pos_from_right <- len - i + 1L
      if (pos_from_right %% 2L == 0L) {
        digits[i] <- digits[i] * 2L
      }
    }
    total <- sum(digits %/% 10L + digits %% 10L)
    total %% 10L == 0L
  }
  vapply(npi, .check_one, logical(1L), USE.NAMES = FALSE)
}
