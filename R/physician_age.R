#' Summarize physician age as median (IQR) text
#'
#' Computes the median, Q1, and Q3 of a numeric age column (ignoring `NA`)
#' and returns a ready-to-paste sentence for manuscript methods or results
#' sections.
#'
#' @param data A data frame containing the age data.
#' @param age_column Character scalar naming the numeric column in `data` that
#'   holds physician ages.
#'
#' @return A single character string of the form
#'   `"The median age was XX.XX years (IQR: Q1.X--Q3.X years)."` where
#'   the median is rounded to 2 decimal places and IQR bounds to 1.
#'
#' @details
#'   `NA` values in `age_column` are removed before computing quantiles
#'   (i.e., `na.rm = TRUE`).  All quantiles use the default R `type = 7`
#'   interpolation.
#'
#' @examples
#' # Example 1: Basic usage with a small dataset
#' data <- data.frame(age = c(30, 40, 50, 60, 35, 45, 55, 65))
#' summary_sentence <- mysterycall_physician_age(data, "age")
#' print(summary_sentence)
#'
#' # Example 2: Handling missing data
#' df_with_na <- data.frame(age = c(30, 40, NA, 60, 35, NA, 55, 65))
#' summary_sentence <- mysterycall_physician_age(df_with_na, "age")
#' print(summary_sentence)
#'
#' # Example 3: Different age distribution
#' df_large <- data.frame(age = c(rep(30, 70), rep(40, 30), rep(50, 20), rep(60, 10)))
#' summary_sentence <- mysterycall_physician_age(df_large, "age")
#' print(summary_sentence)
#'
#' @seealso [mysterycall_impute_age()] to derive age from graduation year;
#'   [mysterycall_age_category()] to bin ages into publication-ready groups.
#' @family provider characteristics
#' @export
mysterycall_physician_age <- function(data, age_column) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!age_column %in% names(data)) {
    stop(sprintf("Column '%s' not found in data.", age_column), call. = FALSE)
  }

  age_vals <- data[[age_column]][!is.na(data[[age_column]])]
  if (length(age_vals) < 2) {
    stop(sprintf("Column '%s' must have at least 2 non-missing values to compute age statistics.", age_column), call. = FALSE)
  }

  # Calculate the median age
  median_age <- round(median(age_vals), 2)

  # Calculate the 25th and 75th percentiles
  q25 <- quantile(age_vals, probs = 0.25)
  q75 <- quantile(age_vals, probs = 0.75)

  # Round the percentiles to one decimal place
  q25 <- round(q25, 1)
  q75 <- round(q75, 1)

  # Create the sentence
  sentence <- paste0(
    "The median age of the dataset was ", median_age,
    " (IQR 25th percentile ", q25, " to 75th percentile ", q75, ")."
  )

  return(sentence)
}
