#' Distribution summary for a categorical column
#'
#' @name mysterycall_distribution_summary
NULL

#' Frequency distribution and modal level for a categorical column
#'
#' Returns the modal (most frequent) level of a categorical column together
#' with a full frequency table, mirroring the source-Rmd pattern:
#' \preformatted{
#' df \%>\%
#'   filter(!is.na(!!sym(column))) \%>\%
#'   group_by(!!sym(column)) \%>\%
#'   summarise(count = n()) \%>\%
#'   mutate(total = sum(count), percent = (count / total) * 100) \%>\%
#'   arrange(desc(count)) \%>\%
#'   slice(1)
#' }
#'
#' @param data A data frame.
#' @param column Character scalar. Name of the categorical column.
#' @param digits Integer. Decimal places for the percentage. Default `1`.
#'
#' @return A named list:
#' \describe{
#'   \item{`level`}{The modal category value (as character).}
#'   \item{`count`}{Frequency of the modal level.}
#'   \item{`total`}{Total non-NA observations.}
#'   \item{`percent`}{Percentage of total for the modal level, rounded to
#'     `digits` decimal places.}
#'   \item{`sentence`}{Character string:
#'     \code{"The most common [column] was [level] (n = [count]/N = [total], [percent]\%)."}}
#'   \item{`full_table`}{A [tibble::tibble()] with columns `level`, `count`,
#'     and `percent` for every non-NA category, ordered descending by `count`.}
#' }
#'
#' @family descriptive helpers
#' @seealso [mysterycall_descriptive_stats()] for numeric summaries.
#' @importFrom dplyr group_by summarise mutate arrange desc filter n
#' @importFrom rlang sym !!
#' @importFrom tibble as_tibble tibble
#' @export
#'
#' @examples
#' df <- data.frame(
#'   insurance = c("Medicaid", "BCBS", "Medicaid", "Medicaid", "BCBS", NA),
#'   stringsAsFactors = FALSE
#' )
#' mysterycall_distribution_summary(df, "insurance")
mysterycall_distribution_summary <- function(
    data,
    column,
    digits = 1L
) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!is.character(column) || length(column) != 1L) {
    stop("`column` must be a single character string.", call. = FALSE)
  }
  if (!column %in% names(data)) {
    stop(sprintf("Column '%s' not found in data.", column), call. = FALSE)
  }
  if (!is.numeric(digits) || length(digits) != 1L || is.na(digits)) {
    stop("`digits` must be a single non-NA number.", call. = FALSE)
  }

  col_sym <- rlang::sym(column)

  non_na_data <- dplyr::filter(data, !is.na(!!col_sym))

  if (nrow(non_na_data) == 0L) {
    stop(sprintf(
      "Column '%s' contains only NA values; cannot compute distribution.", column
    ), call. = FALSE)
  }

  freq_tbl <- non_na_data |>
    dplyr::group_by(!!col_sym) |>
    dplyr::summarise(count = dplyr::n(), .groups = "drop") |>
    dplyr::mutate(
      total   = sum(.data$count),
      percent = round((.data$count / .data$total) * 100, digits)
    ) |>
    dplyr::arrange(dplyr::desc(.data$count))

  # Rename the level column to "level" for a clean full_table
  full_table <- tibble::as_tibble(freq_tbl)
  names(full_table)[1L] <- "level"
  full_table$level <- as.character(full_table$level)
  full_table <- full_table[, c("level", "count", "percent"), drop = FALSE]

  top <- full_table[1L, , drop = FALSE]
  modal_level <- top$level
  modal_count <- top$count
  total_n     <- sum(freq_tbl$count)
  modal_pct   <- top$percent

  sentence <- sprintf(
    "The most common %s was %s (n = %d/N = %d, %s%%).",
    column,
    modal_level,
    modal_count,
    total_n,
    format(round(modal_pct, digits), nsmall = digits)
  )

  list(
    level      = modal_level,
    count      = modal_count,
    total      = total_n,
    percent    = modal_pct,
    sentence   = sentence,
    full_table = full_table
  )
}
