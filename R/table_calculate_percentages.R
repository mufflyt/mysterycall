#' Most frequent level(s) of a categorical variable with percentage
#'
#' Counts each level of a categorical variable, computes its share of the
#' **non-missing** rows, and returns **only the level(s) with the highest
#' count**. When multiple levels tie for the top count, all tied levels are
#' returned. `NA` values are excluded from both the counts and the denominator,
#' matching [mysterycall_table_proportion()], [mysterycall_distribution_summary()],
#' and [mysterycall_most_common_gender()].
#'
#' @param data_frame A data frame containing the categorical variable.
#' @param variable A character string giving the column name of the categorical
#'   variable within `data_frame`.
#'
#' @return A data frame with one row per level tied for the highest count.
#'   Columns: the variable itself, `n` (count), and `percent` (exact percentage
#'   of non-missing rows, not rounded).
#'
#' @examples
#' # "A" is most frequent: returns 1 row
#' data_frame <- data.frame(category = c("A", "B", "A", "C", "A", "B", "B", "A"))
#' mysterycall_table_percentages(data_frame, "category")
#'
#' # Three-way tie: all three returned
#' df_tie <- data.frame(category = c("A", "B", "A", "B", "C", "C", "C", "A", "B"))
#' mysterycall_table_percentages(df_tie, "category")
#'
#' # NAs are excluded; "A" is 3 of 6 non-missing rows = 50%
#' df_na <- data.frame(category = c("A", NA, "A", "C", "A", "B", "B", NA))
#' mysterycall_table_percentages(df_na, "category")
#'
#' @importFrom rlang sym
#' @family table helpers
#' @seealso [mysterycall_table_proportion()], [mysterycall_most_common_gender()],
#'   [mysterycall_min_table()], [mysterycall_max_table()]
#' @export
mysterycall_table_percentages <- function(data_frame, variable) {
  checkmate::assert_data_frame(data_frame, min.rows = 1L)
  variable <- as.character(variable)  # Ensure the variable name is a string
  checkmate::assert_string(variable, min.chars = 1L)
  checkmate::assert_choice(variable, names(data_frame))

  # Denominator = non-missing rows (NA excluded from both count and total).
  non_missing <- dplyr::filter(data_frame, !is.na(!!rlang::sym(variable)))
  counts <- dplyr::count(non_missing, !!rlang::sym(variable), name = "n")

  if (nrow(counts) == 0L) {
    # All values missing: no modal non-missing level.
    counts$percent <- numeric(0)
    return(counts)
  }

  counts <- dplyr::mutate(counts, percent = 100 * n / sum(n))
  counts <- dplyr::arrange(counts, dplyr::desc(n))
  dplyr::filter(counts, n == max(n))
}
