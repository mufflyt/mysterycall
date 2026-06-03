#' Remove Near-Zero Variance Variables from a Data Frame
#'
#' This function takes a data frame and returns a new data frame with near-zero variance variables removed.
#'
#' @param data_frame A data frame from which near-zero variance variables should be removed.
#' @param freqCut The ratio of the most common value to the second most common value. Defaults to 19.
#' @param uniqueCut The percentage of distinct values out of the number of total samples. Defaults to 10.
#'
#' @return A data frame with the same row count as `data_frame`, but with
#'   near-zero variance columns removed. Returns `data_frame` unchanged
#'   when it is empty or no near-zero variance columns are found.
#'
#' @seealso [mysterycall_remove_constants()] to drop columns where every
#'   value is identical; [mysterycall_preflight_check()] for pre-processing
#'   data quality checks.
#' @examplesIf interactive()
#' df <- data.frame(a = 1:20, b = c(rep(1, 19), 2))
#' mysterycall_remove_near_zero(df)
#'
#' @importFrom dplyr select
#'
#' @family data quality
#' @keywords internal
mysterycall_remove_near_zero <- function(data_frame, freqCut = 19, uniqueCut = 10) {
  if (!requireNamespace("caret", quietly = TRUE)) {
    stop("Package 'caret' is required for mysterycall_remove_near_zero()", call. = FALSE)
  }

  if (nrow(data_frame) == 0 || ncol(data_frame) == 0) {
    message("The data frame is empty. Exiting function.")
    return(data_frame)
  }

  message("Identifying near-zero variance variables...")
  remove_cols <- caret::nearZeroVar(data_frame, names = TRUE, freqCut = freqCut, uniqueCut = uniqueCut)
  remove_cols <- sort(remove_cols)

  message(sprintf("Found %d near-zero variance variable(s).", length(remove_cols)))

  if (length(remove_cols) > 0) {
    message("Removing near-zero variance variable(s)...")
    data_frame <- data_frame %>% dplyr::select(-dplyr::all_of(remove_cols))
  } else {
    message("No near-zero variance variables to remove.")
  }

  return(data_frame)
}
