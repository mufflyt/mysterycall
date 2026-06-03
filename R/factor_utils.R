#' Factor and categorical-variable utilities
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name factor_utils
NULL

#' Recode raw physician credential strings to MD, DO, or Other
#'
#' Normalizes the messy free-text values found in NPPES
#' `Provider.Credential.Text` (and similar fields) to one of three canonical
#' labels. Matching is case-insensitive; MD is checked before DO so that
#' `"MD/PhD"` maps to `"MD"` rather than falling through.
#'
#' Recognised patterns:
#' \describe{
#'   \item{`"MD"`}{`M.D.`, `MD`, `MD/PhD`, `MD-PhD`, `MD, PhD`,
#'     `doctor of medicine`, `allopathic`}
#'   \item{`"DO"`}{`D.O.`, `DO`, `D.O.M.`, `osteopathic`}
#'   \item{`"Other"`}{everything else (PA, NP, RN, DDS, DMD, MBBS, ...)}
#' }
#'
#' @param x Character vector of raw credential strings.
#' @param other_label Character scalar returned when neither MD nor DO pattern
#'   matches. Default `"Other"`. This label covers all non-physician
#'   credentials such as PA, NP, RN, DDS, DMD, MBBS, and any unrecognised
#'   free-text strings.
#'
#' @return Character vector the same length as `x`. `NA` inputs return `NA`.
#'
#' @family provider characteristics
#' @keywords internal
#'
#' @examples
#' creds <- c("M.D.", "DO", "MD/PhD", "D.O.", "PA-C", "MBBS", NA)
#' mysterycall_recode_credentials(creds)
mysterycall_recode_credentials <- function(x, other_label = "Other") {
  if (!is.character(x)) x <- as.character(x)
  if (!is.character(other_label) || length(other_label) != 1L)
    stop("`other_label` must be a single character string.", call. = FALSE)

  .md_re <- paste0(
    "\\bm\\.?d\\.?\\b|",              # M.D. / MD
    "\\bmd[/\\-]phd\\b|",             # MD/PhD MD-PhD
    "doctor of medicine|",
    "allopathic"
  )
  .do_re <- paste0(
    "\\bd\\.?o\\.?\\b|",              # D.O. / DO
    "osteopathic"
  )

  .recode_one <- function(s) {
    if (is.na(s)) return(NA_character_)
    sl <- tolower(trimws(s))
    if (grepl(.md_re, sl, perl = TRUE)) return("MD")
    if (grepl(.do_re, sl, perl = TRUE)) return("DO")
    other_label
  }

  vapply(x, .recode_one, character(1L), USE.NAMES = FALSE)
}


#' Reorder a factor (or character vector) by descending frequency
#'
#' Returns a factor whose levels are ordered from most to least common. This
#' is the standard preparation step before passing a categorical variable to
#' ggplot2 bar charts or `gtsummary::tbl_summary()`.
#'
#' Equivalent to `forcats::fct_infreq()` but implemented in pure base R with
#' no additional dependencies.
#'
#' @param x A factor or character vector.
#' @param decreasing Logical. `TRUE` (default) sorts most-frequent first;
#'   `FALSE` sorts least-frequent first.
#' @param na_level Character scalar or `NULL`. When non-`NULL`, `NA` values
#'   are replaced with this string and included as the last level. Default
#'   `NULL` (NAs kept as `NA`).
#'
#' @return A factor with levels sorted by frequency.
#'
#' @family provider characteristics
#' @export
#'
#' @examples
#' x <- c("B", "A", "A", "C", "B", "B", "C", NA)
#' mysterycall_reorder_by_freq(x)
#' # levels: B (3), A (2), C (2), then by appearance for ties
#'
#' # Useful in ggplot2:
#' # ggplot(df, aes(x = mysterycall_reorder_by_freq(specialty))) + geom_bar()
mysterycall_reorder_by_freq <- function(x, decreasing = TRUE, na_level = NULL) {
  if (!is.character(x) && !is.factor(x))
    stop("`x` must be a character or factor vector.", call. = FALSE)

  x_chr <- as.character(x)

  if (!is.null(na_level)) {
    x_chr[is.na(x_chr)] <- na_level
  }

  tab <- sort(table(x_chr), decreasing = decreasing)
  lvls <- names(tab)

  if (!is.null(na_level)) {
    lvls <- c(setdiff(lvls, na_level), na_level)
  }

  factor(x_chr, levels = lvls)
}
