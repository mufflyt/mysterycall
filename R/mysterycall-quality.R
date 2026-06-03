#' Convert numeric scores to qualitative tiers
#'
#' @param score Numeric value between 0 and 1.
#' @param thresholds Named numeric vector with `high` and `medium` entries.
#'
#' @return A quality tier of `"high"`, `"medium"`, or `"low"` (or `NA` when
#'   the score is missing).
#' @family utilities
#' @export
#' @examples
#' mysterycall_quality_tier(0.95)
#' mysterycall_quality_tier(0.80)
#' mysterycall_quality_tier(0.50)
mysterycall_quality_tier <- function(score, thresholds = c(high = 0.9, medium = 0.75)) {
  if (is.null(score) || is.na(score)) {
    return(NA_character_)
  }
  if (!is.numeric(score) || length(score) != 1L || score < 0 || score > 1) {
    stop("`score` must be a single number between 0 and 1.", call. = FALSE)
  }
  if (!all(c("high", "medium") %in% names(thresholds))) {
    stop("`thresholds` must be a named vector with 'high' and 'medium' entries.", call. = FALSE)
  }

  high_cutoff <- thresholds[["high"]]
  medium_cutoff <- thresholds[["medium"]]

  if (score >= high_cutoff) {
    "high"
  } else if (score >= medium_cutoff) {
    "medium"
  } else {
    "low"
  }
}

#' Assess completeness for required data columns
#'
#' @param data A data frame to assess.
#' @param required Columns that must be present and non-missing.
#' @param id_cols Optional identifier columns used to compute uniqueness.
#' @param thresholds Named numeric vector with `high` and `medium` breakpoints
#'   between 0 and 1 determining the quality tier.
#'
#' @return A named list with three elements:
#' \describe{
#'   \item{`summary`}{A [tibble::tibble()] with one row per entry in `required`
#'     (plus one uniqueness row when `id_cols` is supplied). Columns: `column`
#'     (character), `completeness` (numeric, proportion 0-1 of non-missing
#'     values), `missing` (numeric, `1 - completeness`).}
#'   \item{`quality`}{Character scalar: `"high"`, `"medium"`, or `"low"` based
#'     on the mean completeness score relative to `thresholds`.}
#'   \item{`score`}{Numeric scalar. Mean completeness across all `required`
#'     columns (and the uniqueness row when `id_cols` is supplied).}
#' }
#' @importFrom dplyr bind_rows
#' @importFrom tibble tibble
#' @importFrom stats complete.cases
#' @family utilities
#' @export
#' @examples
#' df <- tibble::tibble(id = 1:3, value = c(1, NA, 3))
#' mysterycall_check_data_completeness(df, required = c("id", "value"))
mysterycall_check_data_completeness <- function(data, required = NULL, id_cols = NULL, thresholds = c(high = 0.9, medium = 0.75)) {
  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
  validate_required_columns(data, required, name = "data")

  if (!is.null(id_cols)) {
    validate_required_columns(data, id_cols, name = "data")
  }

  total_rows <- nrow(data)
  completeness <- vapply(required, function(col) {
    mean(stats::complete.cases(data[[col]]))
  }, numeric(1))

  summary <- tibble::tibble(
    column = required,
    completeness = completeness,
    missing = 1 - completeness
  )

  if (!is.null(id_cols) && length(id_cols)) {
    unique_rows <- nrow(unique(data[id_cols]))
    summary <- dplyr::bind_rows(
      summary,
      tibble::tibble(
        column = paste(id_cols, collapse = "+"),
        completeness = unique_rows / total_rows,
        missing = 1 - (unique_rows / total_rows)
      )
    )
  }

  overall_score <- mean(summary$completeness, na.rm = TRUE)
  quality <- mysterycall_quality_tier(overall_score, thresholds = thresholds)

  list(summary = summary, quality = quality, score = overall_score)
}

