#' Calculate the Maximum Value(s) and Corresponding Level(s) of a Factor Variable
#'
#' This function returns the level(s) corresponding to the maximum value(s) of a factor variable.
#'
#' @param InVec Input vector, expected to be a factor variable or convertible to a factor.
#' @param mult Logical value indicating whether to return multiple maximum values or just the first one. Default is FALSE.
#' @return Character scalar (`mult = FALSE`) or character vector (`mult = TRUE`)
#'   containing the factor level(s) with the maximum frequency. Returns
#'   `character(0)` for a zero-length input.
#' @examples
#' vec <- factor(c("A", "B", "A", "C", "B", "B"))
#' mysterycall_max_table(vec)           # "B"
#' mysterycall_max_table(vec, mult = TRUE)  # "B"
#' @family table helpers
#' @seealso [mysterycall_min_table()]
#' @export
mysterycall_max_table <- function(InVec, mult = FALSE) {
  checkmate::assert_flag(mult)
  if (length(InVec) == 0) {
    return(character(0))
  }
  if (!is.factor(InVec)) {
    InVec <- factor(InVec)
  }
  A <- tabulate(InVec)
  if (isTRUE(mult)) {
    levels(InVec)[A == max(A)]
  } else {
    levels(InVec)[which.max(A)]
  }
}
