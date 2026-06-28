#' Flag Records with Exclusions That Also Have a Wait Time
#'
#' A quality-control check that finds records where `reason_for_exclusions`
#' indicates the call was NOT successfully completed (i.e. not
#' `"Able to contact"`) but `business_days_until_appointment` is nonetheless
#' non-negative — a logical discrepancy suggesting a data-entry error.
#'
#' @param data A data frame of mystery-caller records.
#' @param days_col Character scalar. Name of the wait-time column.
#'   Default `"business_days_until_appointment"`.
#' @param exclusion_col Character scalar. Name of the exclusion-reason column.
#'   Default `"reason_for_exclusions"`.
#' @param contact_value Character scalar. The value in `exclusion_col` that
#'   means the call succeeded (no exclusion). Default `"Able to contact"`.
#' @param select_cols Character vector of extra columns to include in the
#'   returned table. Default returns a standard audit set.
#' @param min_days Numeric scalar. Lower bound for the wait-time comparison
#'   (inclusive). Default `0` (any non-negative value is flagged).
#' @param output_dir Character scalar or `NULL`. Directory for the CSV output.
#'   `NULL` (default) writes to a session temp directory via
#'   [mysterycall_tempdir()]. Pass `NA` to skip writing entirely.
#' @param filename Character scalar. Output CSV file name.
#'   Default `"discrepancy_rows.csv"`.
#'
#' @return A [tibble::tibble()] of discrepant rows, sorted descending by the
#'   id column (if present). Returns a zero-row tibble (invisibly) when no
#'   discrepancies are found.
#'
#' @section What this detects:
#' If a call is logged as excluded (e.g. `reason_for_exclusions ==
#' "Physician not available"`) but also has `business_days_until_appointment
#' >= 0`, the record is contradictory — an excluded call should not have a
#' valid appointment wait time. These rows must be resolved before analysis.
#'
#' @family quality control
#' @seealso [mysterycall_flag_repeat_physicians()] for duplicate-entry checks;
#'   [mysterycall_sanity_checks()] for broader pre-analysis validation.
#' @importFrom dplyr filter arrange desc select all_of any_of
#' @importFrom utils write.csv
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_number
#' @export
#'
#' @examples
#' df <- data.frame(
#'   physician_information          = c("Dr A", "Dr B", "Dr C"),
#'   id_number                      = c("001", "002", "003"),
#'   notes                          = c("Called twice", NA, "Left VM"),
#'   reason_for_exclusions          = c("Physician not available",
#'                                      "Able to contact",
#'                                      "Number disconnected"),
#'   business_days_until_appointment = c(5, 3, 0),
#'   stringsAsFactors = FALSE
#' )
#' # Dr A and Dr C are flagged: excluded but have a wait time >= 0
#' result <- mysterycall_flag_exclusion_discrepancy(df, output_dir = NA)
#' result
mysterycall_flag_exclusion_discrepancy <- function(
    data,
    days_col       = "business_days_until_appointment",
    exclusion_col  = "reason_for_exclusions",
    contact_value  = "Able to contact",
    select_cols    = c("physician_information", "id_number", "notes",
                       "reason_for_exclusions",
                       "business_days_until_appointment"),
    min_days       = 0,
    output_dir     = NULL,
    filename       = "discrepancy_rows.csv") {

  checkmate::assert_data_frame(data, min.rows = 0)
  checkmate::assert_string(days_col)
  checkmate::assert_string(exclusion_col)
  checkmate::assert_names(names(data), must.include = c(days_col, exclusion_col))
  checkmate::assert_string(contact_value)
  checkmate::assert_number(min_days)

  result <- data |>
    dplyr::filter(
      .data[[days_col]]      >= min_days,
      .data[[exclusion_col]] != contact_value
    )

  # Sort by id_number descending if present
  if ("id_number" %in% names(result)) {
    result <- dplyr::arrange(result, dplyr::desc(.data$id_number))
  }

  # Keep only the audit columns that exist in the data
  keep <- intersect(select_cols, names(result))
  if (length(keep) > 0L) {
    result <- dplyr::select(result, dplyr::all_of(keep))
  }

  n_disc <- nrow(result)

  if (n_disc == 0L) {
    message("Quality check passed: no records with exclusions and a valid wait time.")
    return(invisible(result))
  }

  message(sprintf(
    "Quality check: %d record(s) are marked as excluded but have %s >= %g.",
    n_disc, days_col, min_days
  ))

  # -- Write CSV unless explicitly skipped (output_dir = NA) -------------------
  if (!isTRUE(is.na(output_dir))) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("quality_checks", create = TRUE)
    }
    if (!dir.exists(output_dir))
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

    out_path <- file.path(output_dir, filename)
    utils::write.csv(result, out_path, row.names = FALSE)
    message(sprintf("Discrepancy rows written to: %s", out_path))
  }

  result
}
