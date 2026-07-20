#' Calculate the Proportion of Each Level in a Categorical Variable
#'
#' This function calculates the proportion of each level in a specified categorical variable within a data frame.
#' It returns a data frame with the counts and percentages of each level.
#'
#' @param data A data frame containing the categorical variable.
#' @param variable_name The name of the categorical variable for which proportions are calculated, passed as an unquoted expression.
#'
#' @return A data frame with one row per unique non-missing level of
#'   `variable_name`. Columns: the variable itself, `n` (count), and `percent`
#'   (percentage of total, rounded to 2 decimal places).
#'
#' @details `variable_name` uses tidy evaluation (`{{ }}`), so pass the column
#'   name unquoted (e.g. `mysterycall_table_proportion(df, gender)`). Use
#'   [mysterycall_table_percentages()] when you have the column name as a
#'   string.
#'
#' @examples
#' # Example 1: Basic usage with a simple dataset
#' data <- data.frame(gender = c("Male", "Female", "Female", "Male", "Male", "Female"))
#' result <- mysterycall_table_proportion(data, gender)
#' print(result)
#'
#' # Example 2: Handling a dataset with missing values
#' df_na <- data.frame(gender = c("Male", NA, "Female", "Female", "Male", "Female", NA))
#' result <- mysterycall_table_proportion(df_na, gender)
#' print(result)
#'
#' # Example 3: Using a variable with multiple levels
#' df_multi <- data.frame(grade = c("A", "B", "A", "C", "B", "A", "C", "B"))
#' result <- mysterycall_table_proportion(df_multi, grade)
#' print(result)
#'
#' @importFrom dplyr count mutate across where
#' @family table helpers
#' @seealso [mysterycall_table_percentages()] for the string-based equivalent;
#'   [mysterycall_max_table()], [mysterycall_min_table()] for single-value
#'   mode/anti-mode queries.
#' @export
mysterycall_table_proportion <- function(data, variable_name) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  tabyl_result <- data %>%
    dplyr::filter(!is.na({{ variable_name }})) %>%
    count({{ variable_name }}, name = "n") %>%
    mutate(percent = n / sum(n) * 100)

  tabyl_result <- tabyl_result %>%
    mutate(across(where(is.numeric), \(x) round(x, 2)))

  return(tabyl_result)
}
