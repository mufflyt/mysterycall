#' Parse messy free-text call durations to a numeric unit
#'
#' Mystery-caller logs capture hold time and call length as free text a caller
#' typed in a hurry -- `"1.5min"`, `"1min 45 sec"`, `"30sec"`,
#' `"2min 30 sec"`, a bare `"90"`, an `"O"` meant as zero. Studies routinely
#' hand-build a lookup table of every variant they happen to see, which is
#' brittle and does not transfer to the next audit. This parses the common forms
#' directly: it sums any minute tokens (`N min`, `N m`) and second tokens
#' (`N sec`, `N s`) it finds, and falls back to treating a bare number as
#' `default_unit`.
#'
#' @param x Character (or numeric) vector of durations.
#' @param output_unit One of `"seconds"` (default) or `"minutes"`; the unit of
#'   the returned numbers.
#' @param default_unit One of `"minutes"` (default) or `"seconds"`; how to
#'   interpret an entry that is a bare number with no `min`/`sec` token (e.g.
#'   `"3"`). Set this to match the column's convention.
#'
#' @return A numeric vector the length of `x`, in `output_unit`. Entries that are
#'   missing, empty, or contain no recoverable number return `NA`.
#'
#' @details Matching is case-insensitive. `"o"`/`"O"` alone (a common stand-in
#'   for zero) parses to `0`. Decimals are supported in either token
#'   (`"2.75min"` -> 165 s). When both minute and second tokens are present they
#'   are added (`"1min 45 sec"` -> 105 s).
#'
#' @family data integrity
#' @seealso [mysterycall_categorize_wait()]
#' @examples
#' mysterycall_parse_duration(
#'   c("1.5min", "1min 45 sec", "30sec", "O", "2.75min, 30sec", "3"),
#'   output_unit = "seconds"
#' )
#' # bare "3" as minutes -> 180 s; "O" -> 0
#' @export
mysterycall_parse_duration <- function(x, output_unit = c("seconds", "minutes"),
                                      default_unit = c("minutes", "seconds")) {
  output_unit  <- match.arg(output_unit)
  default_unit <- match.arg(default_unit)
  x <- as.character(x)

  parse_one <- function(s) {
    if (is.na(s)) return(NA_real_)
    s <- tolower(trimws(s))
    if (!nzchar(s)) return(NA_real_)
    if (s %in% c("o", "0", "none", "no", "n/a", "na")) {
      return(if (s == "o" || s == "0") 0 else NA_real_)
    }

    num <- "[0-9]*\\.?[0-9]+"
    min_hits <- regmatches(s, gregexpr(paste0(num, "\\s*m(?:in)?\\b"), s))[[1]]
    sec_hits <- regmatches(s, gregexpr(paste0(num, "\\s*s(?:ec)?\\b"), s))[[1]]

    if (length(min_hits) || length(sec_hits)) {
      mins <- sum(as.numeric(sub(paste0("(", num, ").*"), "\\1", min_hits)))
      secs <- sum(as.numeric(sub(paste0("(", num, ").*"), "\\1", sec_hits)))
      return(mins * 60 + secs)
    }

    # No unit token: a bare number in `default_unit`.
    if (grepl(paste0("^", num, "$"), s)) {
      v <- as.numeric(s)
      return(if (default_unit == "minutes") v * 60 else v)
    }
    NA_real_
  }

  secs <- vapply(x, parse_one, numeric(1), USE.NAMES = FALSE)
  if (output_unit == "minutes") secs / 60 else secs
}
