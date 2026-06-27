#' Descriptive statistics for a numeric column
#'
#' @name mysterycall_descriptive_stats
NULL

#' Compute median, IQR, and missingness for a numeric column
#'
#' Computes the median, 25th and 75th percentiles, non-missing count, and
#' missing count for a named numeric column in a data frame, mirroring the
#' source-Rmd pattern:
#' \preformatted{
#' median_val <- round(median(df[[column]], na.rm = TRUE), 2)
#' q25 <- quantile(df[[column]], probs = 0.25, na.rm = TRUE)
#' q75 <- quantile(df[[column]], probs = 0.75, na.rm = TRUE)
#' list(median = median_val, q25 = q25, q75 = q75)
#' }
#'
#' Also returns a human-readable `$sentence` field.
#'
#' @param data A data frame.
#' @param column Character scalar. Name of the numeric column to summarise.
#' @param digits Integer. Number of decimal places for the median. Default `2`.
#' @param digits_q Integer. Number of decimal places for the quartiles
#'   (Q1 and Q3). Default `0`.
#'
#' @return A named list with elements:
#' \describe{
#'   \item{`median`}{Rounded median (non-NA values).}
#'   \item{`q25`}{25th percentile, rounded to `digits_q` places.}
#'   \item{`q75`}{75th percentile, rounded to `digits_q` places.}
#'   \item{`n`}{Number of non-NA observations.}
#'   \item{`n_missing`}{Number of NA observations.}
#'   \item{`sentence`}{Character string:
#'     \code{"Median [column]: [median] (IQR: [q25]–[q75])."}}
#' }
#'
#' @family descriptive helpers
#' @seealso [mysterycall_distribution_summary()] for categorical summaries.
#' @importFrom stats median quantile
#' @export
#'
#' @examples
#' df <- data.frame(wait = c(1, 3, 5, 7, NA))
#' mysterycall_descriptive_stats(df, "wait")
mysterycall_descriptive_stats <- function(
    data,
    column,
    digits   = 2L,
    digits_q = 0L
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
  if (!is.numeric(digits)   || length(digits)   != 1L || is.na(digits)) {
    stop("`digits` must be a single non-NA number.", call. = FALSE)
  }
  if (!is.numeric(digits_q) || length(digits_q) != 1L || is.na(digits_q)) {
    stop("`digits_q` must be a single non-NA number.", call. = FALSE)
  }

  x <- data[[column]]

  if (!is.numeric(x)) {
    stop(sprintf(
      "Column '%s' must be numeric, not %s.", column, class(x)[1L]
    ), call. = FALSE)
  }

  n_missing <- sum(is.na(x))
  n_valid   <- sum(!is.na(x))

  if (n_valid == 0L) {
    # All-NA: return NAs gracefully
    return(list(
      median    = NA_real_,
      q25       = NA_real_,
      q75       = NA_real_,
      n         = 0L,
      n_missing = n_missing,
      sentence  = sprintf("Median %s: NA (IQR: NA-NA).", column)
    ))
  }

  med <- round(stats::median(x, na.rm = TRUE), digits)
  q25 <- round(unname(stats::quantile(x, probs = 0.25, na.rm = TRUE)), digits_q)
  q75 <- round(unname(stats::quantile(x, probs = 0.75, na.rm = TRUE)), digits_q)

  sentence <- sprintf(
    "Median %s: %s (IQR: %s–%s).",
    column,
    format(med, nsmall = digits),
    format(q25, nsmall = digits_q),
    format(q75, nsmall = digits_q)
  )

  list(
    median    = med,
    q25       = q25,
    q75       = q75,
    n         = n_valid,
    n_missing = n_missing,
    sentence  = sentence
  )
}
