#' Flag Excluded Records That Still Have a Positive Wait Time
#'
#' Finds records where `business_days_until_appointment > 0` but
#' `reason_for_exclusions` is not `contact_value`. These are logical
#' contradictions: a call that failed contact should not have a valid positive
#' wait time.
#'
#' @param data A data frame of mystery-caller records.
#' @param days_col Character scalar. Name of the wait-time column.
#'   Default `"business_days_until_appointment"`.
#' @param exclusion_col Character scalar. Name of the exclusion-reason column.
#'   Default `"reason_for_exclusions"`.
#' @param contact_value Character scalar. The value in `exclusion_col` that
#'   means the call succeeded. Default `"Able to contact"`.
#' @param select_cols Character vector of columns to return. Columns not
#'   present in `data` are silently dropped.
#' @param output_dir Character scalar or `NULL`. Directory for CSV output.
#'   `NULL` writes to a session temp directory via [mysterycall_tempdir()].
#'   Pass `NA` to skip writing.
#' @param filename Character scalar. Output CSV file name.
#'
#' @return A [tibble::tibble()] of flagged rows, sorted descending by
#'   `id_number` (when present). Returns a zero-row tibble (invisibly) when
#'   no records are flagged.
#'
#' @family quality control
#' @seealso [mysterycall_flag_exclusion_discrepancy()] for the `>= 0` variant;
#'   [mysterycall_flag_included_na_appointments()] for the complementary check.
#' @importFrom dplyr filter arrange desc select all_of
#' @importFrom utils write.csv
#' @export
#'
#' @examples
#' df <- data.frame(
#'   physician_information           = c("Dr A", "Dr B", "Dr C"),
#'   id_number                       = c("001", "002", "003"),
#'   notes                           = c(NA, NA, NA),
#'   reason_for_exclusions           = c("Not available", "Able to contact", "Not available"),
#'   business_days_until_appointment = c(5L, 3L, 0L),
#'   stringsAsFactors = FALSE
#' )
#' # Only Dr A is flagged (days > 0 AND excluded)
#' mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
mysterycall_flag_excluded_with_appointments <- function(
    data,
    days_col      = "business_days_until_appointment",
    exclusion_col = "reason_for_exclusions",
    contact_value = "Able to contact",
    select_cols   = c("physician_information", "id_number", "notes",
                      "reason_for_exclusions",
                      "business_days_until_appointment"),
    output_dir    = NULL,
    filename      = "excluded_with_appointments.csv") {

  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (!days_col %in% names(data))
    stop(sprintf("Column '%s' not found in data.", days_col), call. = FALSE)
  if (!exclusion_col %in% names(data))
    stop(sprintf("Column '%s' not found in data.", exclusion_col), call. = FALSE)
  if (!is.character(contact_value) || length(contact_value) != 1L)
    stop("`contact_value` must be a single character string.", call. = FALSE)

  result <- data |>
    dplyr::filter(
      .data[[days_col]]      >  0,
      .data[[exclusion_col]] != contact_value
    )

  if ("id_number" %in% names(result)) {
    result <- dplyr::arrange(result, dplyr::desc(.data$id_number))
  }

  keep <- intersect(select_cols, names(result))
  if (length(keep) > 0L) {
    result <- dplyr::select(result, dplyr::all_of(keep))
  }

  n_flagged <- nrow(result)

  if (n_flagged == 0L) {
    message("Quality check passed: no excluded records have a positive wait time.")
    return(invisible(result))
  }

  message(sprintf(
    "Quality check: %d record(s) have a positive wait time but are marked as excluded.",
    n_flagged
  ))

  if (!isTRUE(is.na(output_dir))) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("quality_checks", create = TRUE)
    }
    if (!dir.exists(output_dir))
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    out_path <- file.path(output_dir, filename)
    utils::write.csv(result, out_path, row.names = FALSE)
    message(sprintf("Results written to: %s", out_path))
  }

  result
}
