#' Deduplicate data by insurance and physician phone
#'
#' @name mysterycall_dedup_by_insurance
NULL

#' Deduplicate mystery-caller data by insurance \eqn{\times} phone combination
#'
#' Removes duplicate rows so that each unique combination of `phone_col` and
#' `insurance_col` (and optionally `name_col`) appears only once, mirroring the
#' source-Rmd pattern:
#' \code{df \%>\% dplyr::distinct(insurance, phone, physician_information, .keep_all = TRUE)}.
#'
#' @param data A data frame of mystery-caller records.
#' @param phone_col Character scalar. Column used as the unique physician
#'   identifier (typically a phone number). Default `"phone"`.
#' @param insurance_col Character scalar. Column identifying the insurance type.
#'   Default `"insurance"`.
#' @param name_col Character scalar or `NULL`. An additional column (e.g.
#'   `"physician_information"`) included in the distinctness check. Pass `NULL`
#'   to deduplicate on `phone_col` \eqn{\times} `insurance_col` only.
#'   Default `"physician_information"`.
#' @param keep_all Logical. When `TRUE` (default), all columns are retained in
#'   the output (equivalent to `.keep_all = TRUE` in [dplyr::distinct()]).
#' @param output_dir Character scalar or `NULL`. Directory for the CSV output.
#'   `NULL` (default) writes to a session temp directory via
#'   [mysterycall_tempdir()]. Pass `NA` to skip writing entirely.
#' @param filename Character scalar. Name of the output CSV file.
#'   Default `"deduped_by_insurance.csv"`.
#'
#' @return A [tibble::tibble()] with one row per unique `phone_col` \eqn{\times}
#'   `insurance_col` (and `name_col`, if supplied) combination.
#'
#' @family quality control
#' @seealso [mysterycall_flag_repeat_physicians()] for duplicate-call detection;
#'   [mysterycall_sanity_checks()] for broader pre-analysis validation.
#' @importFrom dplyr distinct all_of
#' @importFrom tibble as_tibble
#' @importFrom utils write.csv
#' @export
#'
#' @examples
#' df <- data.frame(
#'   phone                = c("555-1234", "555-1234", "555-9999"),
#'   insurance            = c("Medicaid", "Medicaid", "BCBS"),
#'   physician_information = c("Dr A", "Dr A", "Dr B"),
#'   wait_days            = c(3, 3, 7),
#'   stringsAsFactors     = FALSE
#' )
#' mysterycall_dedup_by_insurance(df, output_dir = NA)
mysterycall_dedup_by_insurance <- function(
    data,
    phone_col     = "phone",
    insurance_col = "insurance",
    name_col      = "physician_information",
    keep_all      = TRUE,
    output_dir    = NULL,
    filename      = "deduped_by_insurance.csv"
) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!is.character(phone_col) || length(phone_col) != 1L) {
    stop("`phone_col` must be a single character string.", call. = FALSE)
  }
  if (!is.character(insurance_col) || length(insurance_col) != 1L) {
    stop("`insurance_col` must be a single character string.", call. = FALSE)
  }
  if (!phone_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in data.", phone_col), call. = FALSE)
  }
  if (!insurance_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in data.", insurance_col), call. = FALSE)
  }
  if (!is.null(name_col)) {
    if (!is.character(name_col) || length(name_col) != 1L) {
      stop("`name_col` must be a single character string or NULL.", call. = FALSE)
    }
    if (!name_col %in% names(data)) {
      stop(sprintf("Column '%s' not found in data.", name_col), call. = FALSE)
    }
  }

  n_before <- nrow(data)

  distinct_cols <- c(insurance_col, phone_col)
  if (!is.null(name_col)) {
    distinct_cols <- c(distinct_cols, name_col)
  }

  result <- dplyr::distinct(data, dplyr::across(dplyr::all_of(distinct_cols)),
                             .keep_all = keep_all)
  result <- tibble::as_tibble(result)

  n_after   <- nrow(result)
  n_removed <- n_before - n_after
  message(sprintf(
    "Removed %d duplicate row%s; %d row%s retained.",
    n_removed, if (n_removed == 1L) "" else "s",
    n_after,   if (n_after   == 1L) "" else "s"
  ))

  if (!isTRUE(is.na(output_dir))) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("dedup_by_insurance", create = TRUE)
    }
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    }
    out_path <- file.path(output_dir, filename)
    utils::write.csv(result, out_path, row.names = FALSE)
    message(sprintf("Deduplicated data written to: %s", out_path))
  }

  result
}
