#' Generate a Summary Sentence for the Most Common Gender, Specialty, Training, and Academic Affiliation
#'
#' This function calculates and returns a sentence that describes the most common gender, specialty, training, and academic affiliation in the provided dataset.
#'
#' @param data A data frame containing the columns `gender`, `specialty`, `Provider.Credential.Text`, and `academic_affiliation`.
#'
#' @return A length-1 character string naming the most common value and its
#'   proportion (rounded to 1 decimal place) for each of `gender`, `specialty`,
#'   `Provider.Credential.Text`, and `academic_affiliation`. When a column is
#'   entirely `NA`, the proportion is reported as `NaN`. In case of a tie,
#'   the level that sorts first alphabetically is returned.
#'
#' @details The function filters out missing values in each column before determining the most common value. It then calculates the proportion of this most common value relative to the total non-missing values in that column.
#'
#' @examples
#' # Example 1: Basic usage with a small dataset
#' data <- data.frame(
#'   gender = c("Male", "Female", "Female", "Male", "Male"),
#'   specialty = c("Cardiology", "Cardiology", "Neurology", "Cardiology", "Neurology"),
#'   Provider.Credential.Text = c("MD", "MD", "DO", "MD", "DO"),
#'   academic_affiliation = c("Yes", "No", "Yes", "No", "Yes")
#' )
#' result <- mysterycall_most_common_gender(data)
#' print(result)
#'
#' # Example 2: Handling missing data
#' df_with_na <- data.frame(
#'   gender = c("Male", NA, "Female", "Male", "Male"),
#'   specialty = c("Cardiology", "Cardiology", "Neurology", NA, "Neurology"),
#'   Provider.Credential.Text = c("MD", "MD", "DO", "MD", "DO"),
#'   academic_affiliation = c("Yes", "No", "Yes", "No", NA)
#' )
#' result <- mysterycall_most_common_gender(df_with_na)
#' print(result)
#'
#' # Example 3: Different proportions with a larger dataset
#' df_large <- data.frame(
#'   gender = c(rep("Male", 70), rep("Female", 30)),
#'   specialty = c(rep("Cardiology", 50), rep("Neurology", 30), rep("Orthopedics", 20)),
#'   Provider.Credential.Text = c(rep("MD", 60), rep("DO", 40)),
#'   academic_affiliation = c(rep("Yes", 40), rep("No", 60))
#' )
#' result <- mysterycall_most_common_gender(df_large)
#' print(result)
#'
#' @seealso [mysterycall_table_percentages()] for tabulating any single
#'   categorical variable; [mysterycall_prepare_table1_vars()] for upstream
#'   gender standardization.
#' @importFrom dplyr filter count arrange desc slice
#' @importFrom rlang sym
#' @family provider characteristics
#' @export
mysterycall_most_common_gender <- function(data) {
  required_cols <- c("gender", "specialty", "Provider.Credential.Text", "academic_affiliation")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols)) {
    stop("Input data must contain columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  # Helper function to get the most common value and proportion
  calculate_proportion <- function(input_data, column) {
    input_data <- input_data %>% filter(!is.na(!!sym(column)))
    total_count <- nrow(input_data)
    if (total_count == 0) {
      return(list(value = "", proportion = NaN))
    }
    most_common <- input_data %>%
      dplyr::count(!!sym(column), sort = TRUE) %>%
      dplyr::arrange(desc(n), !!sym(column)) %>%
      dplyr::slice(1)  # Select the first row after sorting by count and column
    proportion <- round((most_common$n / total_count) * 100, 1)
    list(value = most_common[[1]], proportion = proportion)
  }

  # Most common gender. Fold case/whitespace first so "Male" and "male" are one
  # level, not two — otherwise the mode and its proportion split across casings
  # (e.g. "Male"/"male"/"female" reads as a 3-way tie instead of 2/3 male).
  # Matches mysterycall_prepare_table1_vars() and the lowercase output below.
  data_gender <- data
  data_gender[["gender"]] <- tolower(trimws(as.character(data_gender[["gender"]])))
  gender_info <- calculate_proportion(data_gender, "gender")
  most_gender <- gender_info$value          # already lowercase
  proportion_gender <- gender_info$proportion

  # Most common specialty
  specialty_info <- calculate_proportion(data, "specialty")
  most_specialty <- specialty_info$value
  proportion_specialty <- specialty_info$proportion

  # Most common training
  training_info <- calculate_proportion(data, "Provider.Credential.Text")
  most_training <- training_info$value
  proportion_training <- training_info$proportion

  # Most common academic affiliation
  academic_info <- calculate_proportion(data, "academic_affiliation")
  most_academic <- tolower(academic_info$value)
  proportion_academic <- academic_info$proportion

  # Create the sentence
  sentence <- paste0(
    "The most common gender in the dataset was ", most_gender,
    " (", proportion_gender, "%). The most common specialty was ", most_specialty,
    " (", proportion_specialty, "%). The most common training was ", most_training,
    " (", proportion_training, "%). The academic affiliation status most frequently occurring was ", most_academic,
    " (", proportion_academic, "%)."
  )

  return(sentence)
}
