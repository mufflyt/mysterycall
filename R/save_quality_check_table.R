#' Save Quality Check Table
#'
#' This function takes a data frame containing 'npi' and 'name' columns and creates a quality check table.
#' The table includes the count of observations for each 'npi' and 'name' combination where the count is greater than 2.
#' The resulting table is saved as a CSV file.
#'
#' @param data A data frame containing the columns 'npi' and 'name'.
#' @param filepath The path where the output file should be saved.
#' @param output_format Character scalar: `"csv"` (default) or `"parquet"`.
#'   CSV is written via `readr::write_csv()`; Parquet requires the `arrow`
#'   package and is more efficient for large tables. The file extension of
#'   `filepath` is ignored; this parameter controls what is actually written.
#' @return The filtered data frame (invisibly). A message is emitted indicating
#'   where the file was saved.
#' @details
#' The output table aggregates by `npi` and `name`, keeps combinations with more
#' than two records, sorts descending by frequency, and writes the result to the
#' specified format via `mysterycall_write_table()`.
#' This helper is useful for flagging repeated provider entries that may require
#' manual review.
#' @importFrom dplyr group_by summarize arrange filter n desc
#' @seealso [mysterycall_run_workflow()], [validate_dataframe()],
#'   [mysterycall_split_and_save()]
#' @family utilities
#' @export
#' @examplesIf interactive()
#' mysterycall_save_quality_table(my_data, "qc.csv")
mysterycall_save_quality_table <- function(data, filepath, output_format = c("csv", "parquet")) {
  output_format <- match.arg(output_format)
  required_cols <- c("npi", "name")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols)) {
    stop("Input data must contain columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  # Group by 'npi' and 'name', calculate counts, filter where count > 2, and arrange by count descending
  filtered_data <- data %>%
    dplyr::group_by(.data$npi, .data$name) %>%
    dplyr::summarize(count = n(), .groups = 'drop') %>%
    dplyr::filter(.data$count > 2) %>%
    dplyr::arrange(desc(.data$count))

  output_dir <- dirname(filepath)
  if (nzchar(output_dir) && output_dir != ".") {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  mysterycall_write_table(filtered_data, filepath, format = output_format)

  message(sprintf(
    "Saved quality-check table with %d row(s) to %s.",
    nrow(filtered_data),
    filepath
  ))

  invisible(filtered_data)
}
