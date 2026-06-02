#' Calculate the Minimum Value(s) and Corresponding Level(s) of a Factor Variable
#'
#' This function returns the level(s) corresponding to the minimum value(s) of a factor variable.
#'
#' @param InVec A vector or factor. Non-factor inputs are coerced to factor
#'   via `factor()`. The function counts occurrences of each resulting level.
#' @param mult Logical scalar. If `TRUE`, all levels tied for the minimum
#'   count are returned. If `FALSE` (default), only the first such level is
#'   returned (via `which.min()`).
#' @return Character scalar (`mult = FALSE`) or character vector (`mult = TRUE`)
#'   of the factor level(s) with the minimum frequency. Returns `character(0)`
#'   for a zero-length input.
#' @examples
#' vec <- factor(c("A", "B", "A", "C", "B", "B"))
#' mysterycall_min_table(vec)           # "C"
#' mysterycall_min_table(vec, mult = TRUE)  # "C"
#' @family table helpers
#' @seealso [mysterycall_max_table()]
#' @export
mysterycall_min_table <- function(InVec, mult = FALSE) {
  if (length(InVec) == 0) {
    return(character(0))
  }
  if (!is.factor(InVec)) {
    InVec <- factor(InVec)
  }
  A <- tabulate(InVec)
  if (isTRUE(mult)) {
    levels(InVec)[A == min(A)]
  } else {
    levels(InVec)[which.min(A)]
  }
}

