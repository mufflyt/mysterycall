#' Collapse rare factor/character levels into an "Other" category
#'
#' @name mysterycall_collapse_rare
NULL

#' Collapse rare levels into "Other"
#'
#' Replaces any level (or unique value) that appears fewer than `threshold`
#' times with `other_label`. Factors are returned as factors with updated
#' levels; character vectors are returned as character.
#'
#' @param x A character or factor vector.
#' @param threshold Minimum count to retain a level. Levels with fewer
#'   observations are collapsed. Default `50L`.
#' @param other_label Character scalar used as the replacement label.
#'   Default `"Other"`.
#'
#' @return A vector the same length and type as `x`. Character input returns
#'   character; factor input returns a factor with updated levels (rare levels
#'   removed, `other_label` appended at the end if any collapsing occurred).
#'   Relative order of retained levels is preserved.
#'
#' @seealso [mysterycall_reorder_by_freq()] to reorder factor levels by
#'   frequency; [mysterycall_recode_credentials()] for credential grouping.
#' @family provider characteristics
#' @keywords internal
#'
#' @examples
#' x <- c(rep("Otolaryngology", 80), rep("Urology", 30), rep("Dermatology", 5))
#' mysterycall_collapse_rare(x, threshold = 10)
mysterycall_collapse_rare <- function(x, threshold = 50L, other_label = "Other") {
  if (!is.character(x) && !is.factor(x)) {
    stop("`x` must be a character or factor vector.", call. = FALSE)
  }
  if (!is.numeric(threshold) || length(threshold) != 1L || is.na(threshold) || threshold < 1) {
    stop("`threshold` must be a single positive number.", call. = FALSE)
  }
  if (!is.character(other_label) || length(other_label) != 1L) {
    stop("`other_label` must be a single character string.", call. = FALSE)
  }

  was_factor  <- is.factor(x)
  orig_levels <- if (was_factor) levels(x) else NULL
  x_chr       <- as.character(x)

  tab  <- table(x_chr)
  rare <- names(tab[tab < threshold])
  x_chr[x_chr %in% rare] <- other_label

  if (was_factor) {
    keep <- c(setdiff(orig_levels, rare), other_label)
    factor(x_chr, levels = unique(keep))
  } else {
    x_chr
  }
}
