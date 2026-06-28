#' Retrieve detailed records for a set of flagged physician IDs
#'
#' @name mysterycall_physicians_with_detail
NULL

#' Pull physician detail rows for a vector of flagged IDs
#'
#' Filters the full mystery-caller data frame to the rows whose `id_col` value
#' appears in `flagged_ids`, then returns the requested `select_cols` arranged
#' by `id_col`. Mirrors the source-Rmd pattern:
#' \preformatted{
#' df \%>\%
#'   filter(id_number \%in\% unique(temp$id_number)) \%>\%
#'   dplyr::select(id_number, physician_information,
#'                 reason_for_exclusions, insurance,
#'                 business_days_until_appointment) \%>\%
#'   arrange(id_number)
#' }
#'
#' @param data A data frame of mystery-caller records.
#' @param flagged_ids A character or numeric vector of IDs to look up, **or** a
#'   data frame that contains a column named `id_col` (the unique values of that
#'   column are used as the lookup set).
#' @param id_col Character scalar. Column to match on in both `data` and
#'   (when `flagged_ids` is a data frame) `flagged_ids`. Default `"id_number"`.
#' @param select_cols Character vector. Columns to return (only those that
#'   actually exist in `data` are kept). Default:
#'   `c("id_number", "physician_information", "reason_for_exclusions",
#'      "insurance", "business_days_until_appointment")`.
#' @param output_dir Character scalar or `NULL`. Directory for the CSV output.
#'   `NULL` (default) writes to a session temp directory via
#'   [mysterycall_tempdir()]. Pass `NA` to skip writing entirely.
#' @param filename Character scalar. Name of the output CSV file.
#'   Default `"physicians_with_detail.csv"`.
#'
#' @return A [tibble::tibble()] of matching rows arranged by `id_col`. Returns
#'   a zero-row tibble (with the requested columns) when no IDs match.
#'
#' @family descriptive helpers
#' @seealso [mysterycall_flag_exclusion_discrepancy()],
#'   [mysterycall_flag_repeat_physicians()]
#' @importFrom dplyr filter arrange select all_of any_of
#' @importFrom tibble as_tibble
#' @importFrom utils write.csv
#' @importFrom checkmate assert_data_frame assert_string assert_names
#' @export
#'
#' @examples
#' df <- data.frame(
#'   id_number                      = c("001", "002", "003", "004"),
#'   physician_information          = c("Dr A", "Dr B", "Dr C", "Dr D"),
#'   reason_for_exclusions          = c("Able to contact", NA,
#'                                      "No appointment", "Able to contact"),
#'   insurance                      = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
#'   business_days_until_appointment = c(5, NA, NA, 10),
#'   stringsAsFactors               = FALSE
#' )
#' mysterycall_physicians_with_detail(df, flagged_ids = c("001", "003"),
#'                                    output_dir = NA)
mysterycall_physicians_with_detail <- function(
    data,
    flagged_ids,
    id_col      = "id_number",
    select_cols = c("id_number", "physician_information",
                    "reason_for_exclusions", "insurance",
                    "business_days_until_appointment"),
    output_dir  = NULL,
    filename    = "physicians_with_detail.csv"
) {
  checkmate::assert_data_frame(data, min.rows = 0)
  checkmate::assert_string(id_col)
  checkmate::assert_names(names(data), must.include = id_col)

  # Accept a data frame or a plain vector for flagged_ids
  if (is.data.frame(flagged_ids)) {
    checkmate::assert_names(names(flagged_ids), must.include = id_col)
    id_vec <- unique(flagged_ids[[id_col]])
  } else if (is.vector(flagged_ids) || is.factor(flagged_ids)) {
    id_vec <- unique(as.character(flagged_ids))
  } else {
    stop("`flagged_ids` must be a vector or data frame.", call. = FALSE)
  }

  # Convert data id_col to character for comparison (handles numeric IDs)
  matched <- data[as.character(data[[id_col]]) %in% id_vec, , drop = FALSE]

  # Sort by id_col
  matched <- matched[order(matched[[id_col]]), , drop = FALSE]

  # Select only existing columns from select_cols, always keep id_col
  keep_cols <- intersect(union(select_cols, id_col), names(matched))
  # Maintain the original select_cols order, then ensure id_col is first if missing
  keep_ordered <- c(
    intersect(select_cols, keep_cols),
    setdiff(keep_cols, select_cols)
  )
  if (length(keep_ordered) > 0L) {
    matched <- matched[, keep_ordered, drop = FALSE]
  }

  result  <- tibble::as_tibble(matched)
  n_rows  <- nrow(result)
  n_ids   <- length(id_vec)

  message(sprintf(
    "Found %d matching record%s for %d unique ID%s.",
    n_rows, if (n_rows == 1L) "" else "s",
    n_ids,  if (n_ids  == 1L) "" else "s"
  ))

  if (!isTRUE(is.na(output_dir))) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("physicians_with_detail", create = TRUE)
    }
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    }
    out_path <- file.path(output_dir, filename)
    utils::write.csv(result, out_path, row.names = FALSE)
    message(sprintf("Physician detail written to: %s", out_path))
  }

  result
}
