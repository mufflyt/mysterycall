#' Flag Physicians Included More Than a Threshold Number of Times
#'
#' A quality-control check that identifies physician-call combinations
#' appearing more than `threshold` times in the dataset. Returns a summary
#' table and optionally writes it to CSV for audit review.
#'
#' @param data A data frame of mystery-caller records.
#' @param id_col Character scalar. Name of the physician identifier column
#'   (e.g. `"id_number"`, `"npi"`).
#' @param name_col Character scalar. Name of the physician name/info column
#'   (e.g. `"physician_information"`). Set to `NULL` to group by `id_col` only.
#' @param threshold Integer. Flag physicians with a call count **greater than**
#'   this value. Default `2`.
#' @param output_dir Character scalar or `NULL`. Directory for the CSV output.
#'   `NULL` (default) writes to a session temp directory via
#'   [mysterycall_tempdir()]. Pass `NA` to skip writing entirely.
#' @param filename Character scalar. Name of the output CSV file.
#'   Default `"quality_check_repeat_physicians.csv"`.
#'
#' @return A [tibble::tibble()] with one row per flagged physician group,
#'   columns `<id_col>`, `<name_col>` (if supplied), and `n_calls`
#'   (descending). Returns a zero-row tibble (invisibly) when no physicians
#'   exceed the threshold.
#'
#' @section Quality control interpretation:
#' In mystery-caller studies each target physician is typically called once
#' or twice per wave. A count exceeding the threshold may indicate duplicate
#' data entry, a scheduling error, or a data-linkage problem that should be
#' resolved before analysis.
#'
#' @family quality control
#' @seealso [mysterycall_sanity_checks()] for broader pre-analysis checks.
#' @importFrom dplyr group_by summarise arrange filter n desc
#' @importFrom tibble tibble
#' @importFrom utils write.csv
#' @export
#'
#' @examples
#' df <- data.frame(
#'   id_number            = c("A", "A", "A", "B", "B", "C"),
#'   physician_information = c("Dr Smith", "Dr Smith", "Dr Smith",
#'                             "Dr Jones", "Dr Jones", "Dr Lee"),
#'   stringsAsFactors = FALSE
#' )
#' # Dr Smith appears 3 times (> 2) and should be flagged
#' result <- mysterycall_flag_repeat_physicians(df, output_dir = NA)
#' result
mysterycall_flag_repeat_physicians <- function(data,
                                               id_col    = "id_number",
                                               name_col  = "physician_information",
                                               threshold = 2L,
                                               output_dir = NULL,
                                               filename   = "quality_check_repeat_physicians.csv") {

  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (!id_col %in% names(data))
    stop(sprintf("Column '%s' not found in data.", id_col), call. = FALSE)
  if (!is.null(name_col) && !name_col %in% names(data))
    stop(sprintf("Column '%s' not found in data.", name_col), call. = FALSE)
  if (!is.numeric(threshold) || length(threshold) != 1L || threshold < 0)
    stop("`threshold` must be a non-negative number.", call. = FALSE)

  threshold <- as.integer(threshold)
  group_cols <- if (!is.null(name_col)) c(id_col, name_col) else id_col

  result <- data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
    dplyr::summarise(n_calls = dplyr::n(), .groups = "drop") |>
    dplyr::arrange(dplyr::desc(.data$n_calls)) |>
    dplyr::filter(.data$n_calls > threshold)

  n_flagged <- nrow(result)

  if (n_flagged == 0L) {
    message(sprintf(
      "Quality check passed: no physicians appear more than %d time(s).",
      threshold
    ))
    return(invisible(result))
  }

  message(sprintf(
    "Quality check: %d physician record(s) appear more than %d time(s).",
    n_flagged, threshold
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
    message(sprintf("Results written to: %s", out_path))
  }

  result
}
