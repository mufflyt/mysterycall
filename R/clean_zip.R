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
#' @seealso [mysterycall_add_hhi()]
#' @examples
#' mysterycall_clean_zip(c("03110, 03756", 3110, "12345-6789", "", NA))
#' # -> c("03110", "03110", "12345", NA, NA)
#' @export
mysterycall_clean_zip <- function(x) {
  x <- as.character(x)
  vapply(x, function(s) {
    if (is.na(s)) return(NA_character_)
    s <- trimws(s)
    if (!nzchar(s)) return(NA_character_)
    # First ZIP when several are separated by comma / semicolon / slash.
    s <- trimws(strsplit(s, "[,;/]")[[1]][1])
    m <- regmatches(s, regexpr("[0-9]+", s))
    if (length(m) == 0L) return(NA_character_)
    d <- m[1]
    if (nchar(d) > 5L) d <- substr(d, 1L, 5L)   # ZIP+4 written without a dash
    if (nchar(d) < 5L) d <- paste0(strrep("0", 5L - nchar(d)), d)
    d
  }, character(1), USE.NAMES = FALSE)
}
