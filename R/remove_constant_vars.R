#' Remove Constant Variables from a Data Frame
#'
#' This function takes a data frame and returns a new data frame with constant variables removed.
#'
#' @param data_frame A data frame from which constant variables should be removed.
#'
#' @return A data frame with the same row count as `data_frame` but with
#'   zero-variance columns (all values identical after coercion to character)
#'   removed. Returns `data_frame` unchanged when it is empty or has no
#'   constant columns.
#'
#' @seealso [mysterycall_preflight_check()] to audit data quality before
#'   removal; [mysterycall_assess_data_quality()] for missingness scoring.
#' @importFrom dplyr select where all_of
#'
#' @examples
#' df <- data.frame(a = 1:3, b = c(5, 5, 5), c = c("x", "y", "z"))
#' mysterycall_remove_constants(df)
#'
#' @family data quality
#' @export
mysterycall_remove_constants <- function(data_frame) {

  # Log: Starting the function
  message("Starting the function to remove constant variables.")

  # Log: Checking if the data frame is empty
  if (nrow(data_frame) == 0 || ncol(data_frame) == 0) {
    message("The data frame is empty. Exiting function.")
    return(data_frame)
  }

  # Identify constant variables
  message("Identifying constant variables...")
  const_vars <- dplyr::select(data_frame, dplyr::where(~ length(unique(as.character(.))) == 1)) %>% names()

  # Log: Number of constant variables found
  message(sprintf("Found %d constant variables.", length(const_vars)))

  # Remove constant variables if any
  if (length(const_vars) > 0) {
    # Log: Removing constant variables
    message("Removing constant variables...")
    data_frame <- data_frame %>% dplyr::select(-dplyr::all_of(const_vars))
  } else {
    # Log: No constant variables to remove
    message("No constant variables to remove.")
  }

  # Log: Function completed
  message("Function completed.")

  return(data_frame)
}
