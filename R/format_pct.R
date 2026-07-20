#' Format a Numeric Value as a Percentage
#'
#' This function formats a numeric value as a percentage with a specified number of decimal places.
#'
#' @param x A numeric value or vector that you want to format as a percentage.
#' @param digits An integer specifying the number of decimal places to include in the formatted percentage. The default is 1.
#'
#' @return A character vector representing the formatted percentage(s) with the specified number of decimal places.
#'
#' @details Uses `formatC(format = "f")` so trailing zeros are always
#'   preserved, ensuring values like `10.0%` align correctly in fixed-width
#'   output.
#'
#' @examples
#' # Example 1: Format a single numeric value
#' result <- mysterycall_format_pct(0.12345)
#' print(result)  # Output: "12.3%"
#'
#' # Example 2: Format a vector of numeric values with 2 decimal places
#' values <- c(0.12345, 0.6789, 0.54321)
#' formatted_values <- mysterycall_format_pct(values, digits = 2)
#' print(formatted_values)  # Output: "12.35%", "67.89%", "54.32%"
#'
#' # Example 3: Format a value with no decimal places
#' no_decimal <- mysterycall_format_pct(0.5, digits = 0)
#' print(no_decimal)  # Output: "50%"
#'
#' @family table helpers
#' @export
mysterycall_format_pct <- function(x, digits = 1) {
  checkmate::assert_numeric(x)
  checkmate::assert_count(digits)
  result <- paste0(formatC(100 * x, format = "f", digits = digits), "%")
  result[is.na(x)] <- NA_character_
  result
}
