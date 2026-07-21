#' Summarise Wait Times by Group
#'
#' Computes the median, first quartile (Q1), third quartile (Q3), and
#' non-missing count of an appointment-wait-time column, stratified by a
#' grouping variable.
#'
#' @param data A data frame.
#' @param outcome_col Character scalar. Column containing wait-time values
#'   (numeric). Default `"business_days_until_appointment"`.
#' @param group_col Character scalar. Column to group by (e.g. `"scenario"`).
#' @param digits_median Integer. Rounding digits for the median. Default `1`.
#' @param digits_q Integer. Rounding digits for Q1 and Q3. Default `0`.
#' @param filter_positive Logical. If `TRUE`, pre-filter rows where
#'   `outcome_col > 0` before computing statistics. Default `FALSE`.
#' @param reorder Logical. If `TRUE`, result rows are sorted from highest to
#'   lowest `median_days` so the group with the longest wait appears first.
#'   (Rennie 2024 — order groups by a summary statistic.)  Default `FALSE`.
#' @param output_dir Character scalar or `NULL`. Directory for CSV output.
#'   `NULL` writes to a session temp directory via [mysterycall_tempdir()].
#'   Pass `NA` to skip writing.
#' @param filename Character scalar. Output CSV file name. Default
#'   `"wait_time_by_group.csv"`.
#'
#' @return A [tibble::tibble()] with columns:
#' \describe{
#'   \item{`<group_col>`}{The grouping variable values.}
#'   \item{`median_days`}{Median wait time (rounded to `digits_median`).}
#'   \item{`q1`}{25th percentile (rounded to `digits_q`).}
#'   \item{`q3`}{75th percentile (rounded to `digits_q`).}
#'   \item{`n`}{Non-NA count per group.}
#' }
#'
#' @family outcomes
#' @seealso [mysterycall_wait_time_summary()], which reports the same
#'   median/Q1/Q3 columns plus mean/SD/range and a group-comparison test with an
#'   interpretation sentence. Use this leaner helper when you only need the
#'   quantile table (with optional CSV export).
#' @importFrom dplyr group_by summarise n arrange desc
#' @importFrom stats median quantile na.omit
#' @importFrom utils write.csv
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_flag assert_integerish
#' @export
#'
#' @examples
#' df <- data.frame(
#'   scenario = c("A", "A", "B", "B", "B"),
#'   business_days_until_appointment = c(3, 7, 14, 21, 28),
#'   stringsAsFactors = FALSE
#' )
#' mysterycall_wait_time_by_group(df, group_col = "scenario", output_dir = NA)
mysterycall_wait_time_by_group <- function(
    data,
    outcome_col    = "business_days_until_appointment",
    group_col,
    digits_median  = 1L,
    digits_q       = 0L,
    filter_positive = FALSE,
    reorder        = FALSE,
    output_dir     = NULL,
    filename       = "wait_time_by_group.csv") {

  checkmate::assert_data_frame(data, min.rows = 0)
  checkmate::assert_string(outcome_col)
  checkmate::assert_string(group_col)
  checkmate::assert_names(names(data), must.include = c(outcome_col, group_col))
  checkmate::assert_integerish(digits_median, lower = 0, len = 1)
  checkmate::assert_integerish(digits_q,      lower = 0, len = 1)
  checkmate::assert_flag(filter_positive)
  checkmate::assert_flag(reorder)

  df <- data
  if (isTRUE(filter_positive)) {
    df <- df[!is.na(df[[outcome_col]]) & df[[outcome_col]] > 0, , drop = FALSE]
  }

  grp_sym <- as.name(group_col)
  out_sym <- as.name(outcome_col)

  result <- df |>
    dplyr::group_by(.data[[group_col]]) |>
    dplyr::summarise(
      median_days = round(
        stats::median(.data[[outcome_col]], na.rm = TRUE),
        digits = digits_median
      ),
      q1 = round(
        stats::quantile(.data[[outcome_col]], 0.25, na.rm = TRUE),
        digits = digits_q
      ),
      q3 = round(
        stats::quantile(.data[[outcome_col]], 0.75, na.rm = TRUE),
        digits = digits_q
      ),
      n = sum(!is.na(.data[[outcome_col]])),
      .groups = "drop"
    )

  # Optional reordering (Rennie 2024: order groups by summary stat)
  if (isTRUE(reorder)) {
    result <- dplyr::arrange(result, dplyr::desc(median_days))
  }

  # Write CSV
  if (!isTRUE(is.na(output_dir))) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("wait_time_by_group", create = TRUE)
    }
    if (!dir.exists(output_dir))
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    out_path <- file.path(output_dir, filename)
    utils::write.csv(result, out_path, row.names = FALSE)
    message(sprintf("Wait-time summary written to: %s", out_path))
  }

  result
}
