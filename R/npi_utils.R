#' NPI validation utilities
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name npi_utils
NULL

#' Validate NPI numbers using the official CMS Luhn checksum
#'
#' Implements the CMS-specified Luhn algorithm for 10-digit National Provider
#' Identifiers (NPI). The CMS prepends the constant "80840" to the NPI before
#' computing the checksum, so this is not a generic Luhn check.
#'
#' THE LEADING DIGIT IS PART OF THE FORMAT. CMS has only ever issued NPIs
#' beginning with 1 (and reserves 2); roughly one in ten arbitrary 10-digit
#' strings passes the Luhn checksum by chance, so the checksum alone is a
#' weak gate -- "0103000788" satisfies the checksum yet cannot be an NPI.
#' This mirrors `mysterynpi::npi_luhn_ok()`, the ecosystem's canonical
#' implementation; the two must never diverge, because state provider numbers
#' that happen to satisfy the checksum otherwise join as phantom NPIs.
#'
#' @param npi Character or numeric vector of NPI values. Non-10-digit values
#'   (after stripping punctuation/whitespace) are immediately invalid.
#'
#' @return Logical vector the same length as `npi`. `TRUE` means the NPI
#'   passes the CMS Luhn checksum and leading-digit format; `FALSE` means it
#'   does not or is malformed. `NA` inputs return `FALSE` (unlike
#'   `mysterynpi::npi_luhn_ok()`, whose `NA`-in-`NA`-out contract serves a
#'   different caller -- here absence must not propagate into `filter()`).
#'
#' @seealso [mysterycall_validate_npi()] for row-level NPI validation with
#'   filtering; [mysterycall_get_clinician_data()] to retrieve clinician detail
#'   records for validated NPIs.
#' @family data management
#' @keywords internal
#'
#' @examples
#' mysterycall:::mysterycall_luhn_check(c("1234567893", "9999999999", NA))
#' # Filter a data frame to valid NPIs:
#' # df[mysterycall_luhn_check(df$npi), ]
mysterycall_luhn_check <- function(npi) {
  # Strip punctuation/whitespace before validating, matching
  # mysterycall_validate_npi() -- otherwise "123-456-7893" or a trailing space
  # would be dropped here but kept there (same NPI, opposite verdicts).
  s <- gsub("[^0-9]", "", as.character(npi))
  ok <- !is.na(s) & grepl("^[12][0-9]{9}$", s)
  out <- rep(FALSE, length(s))
  if (any(ok)) {
    v <- s[ok]
    # "80840" + the first 9 digits is a FIXED 14-character string, so the
    # Luhn positions to double are the fixed even columns -- the whole
    # computation runs as one digit matrix instead of a per-element strsplit
    # loop. Algorithm copied from mysterynpi::npi_luhn_ok(); do not re-derive
    # it here, a scalar copy already diverged once.
    base <- paste0("80840", substr(v, 1, 9))
    digs <- vapply(1:14, function(j) as.integer(substr(base, j, j)),
                   integer(length(v)))
    dim(digs) <- c(length(v), 14L)
    even <- seq(2L, 14L, by = 2L)
    digs[, even] <- digs[, even] * 2L
    digs[digs > 9L] <- digs[digs > 9L] - 9L
    check <- (10L - (as.integer(rowSums(digs)) %% 10L)) %% 10L
    out[ok] <- check == as.integer(substr(v, 10, 10))
  }
  out
}
