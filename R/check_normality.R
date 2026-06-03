#' Check Normality and Summarize Data
#'
#' This function checks the normality of a specified variable in a dataframe using the Shapiro-Wilk test
#' and provides summary statistics (mean and standard deviation if normal, median and IQR if not normal).
#'
#' @param data A dataframe containing the data.
#' @param variable A string specifying the column name of the variable to be checked and summarized.
#'
#' @return A named list with either:
#'   \describe{
#'     \item{mean, sd}{Numeric scalars (if Shapiro-Wilk p > 0.05, data approximately normal).}
#'     \item{median, iqr}{Numeric scalars (if Shapiro-Wilk p <= 0.05, data non-normal).}
#'   }
#'   Also emits a histogram + density plot and a Q-Q plot via side effects.
#'
#' @seealso [mysterycall_prepare_table1_vars()] for downstream variable
#'   standardization; [mysterycall_physician_age()] for age summary statistics.
#' @family modeling helpers
#' @export
#' @importFrom ggplot2 ggplot aes geom_histogram geom_density labs stat_qq stat_qq_line
#' @importFrom rlang sym
#' @importFrom stats shapiro.test IQR median
#'
#' @examples
#' sample_data <- data.frame(
#'   business_days_until_appointment = c(1.5, 2.0, 1.8, 2.2, 1.9, 2.1, 2.3)
#' )
#' mysterycall_check_normality(sample_data, "business_days_until_appointment")
mysterycall_check_normality <- function(data, variable) {
  # Start logging
  message("Starting normality check and summary calculation for variable: ", variable)

  # Extract the variable data and remove NA values
  if (!variable %in% names(data)) {
    stop("Variable not found in data frame: ", variable, call. = FALSE)
  }

  data_var <- stats::na.omit(data[[variable]])
  message("Data extracted for variable: ", variable)

  # Check if the sample size is adequate for the Shapiro-Wilk test
  if (length(data_var) < 3) {
    stop("Sample size must be at least 3 for the Shapiro-Wilk test.", call. = FALSE)
  }
  if (length(data_var) > 5000) {
    stop("Sample size must be no more than 5000 for the Shapiro-Wilk test.", call. = FALSE)
  }

  # Check normality using Shapiro-Wilk test
  normality_test <- stats::shapiro.test(data_var)
  p_value <- normality_test$p.value
  message("Shapiro-Wilk normality test completed with p-value: ", p_value)

  # Log interpretation of the Shapiro-Wilk test result
  if (p_value > 0.05) {
    message("The p-value is greater than 0.05, indicating that the data is approximately normal.")
  } else {
    message("The p-value is less than or equal to 0.05, indicating that the data is not normally distributed.")
  }

  # Create Histogram with Density Plot
  clean_data <- data[!is.na(data[[variable]]), , drop = FALSE]

  hist_plot <- ggplot2::ggplot(clean_data, ggplot2::aes(x = !!rlang::sym(variable))) +
    ggplot2::geom_histogram(ggplot2::aes(y = ggplot2::after_stat(density)),
                            binwidth = 0.5, fill = "lightblue", color = "black", na.rm = TRUE) +
    ggplot2::geom_density(alpha = 0.2, fill = "#FF6666", na.rm = TRUE) +
    ggplot2::labs(title = paste("Histogram and Density Plot of", variable), x = variable,
                  y = "Density")
  message("Histogram with Density Plot created.")

  # Create Q-Q Plot
  qq_plot <- ggplot2::ggplot(clean_data, ggplot2::aes(sample = !!rlang::sym(variable))) +
    ggplot2::stat_qq(na.rm = TRUE) +
    ggplot2::stat_qq_line(na.rm = TRUE) +
    ggplot2::labs(title = paste("Q-Q Plot of", variable))
  message("Q-Q Plot created.")

  # Print plots
  invisible(hist_plot)
  invisible(qq_plot)

  # Determine summary statistic based on normality
  if (p_value > 0.05) {
    # Data is approximately normal
    mean_value <- mean(data_var, na.rm = TRUE)
    sd_value <- sd(data_var, na.rm = TRUE)
    summary_stats <- list(mean = mean_value, sd = sd_value)
    message("Data is approximately normal. Mean: ", mean_value, ", SD: ", sd_value)
  } else {
    # Data is not normal
    median_value <- stats::median(data_var, na.rm = TRUE)
    iqr_value <- stats::IQR(data_var, na.rm = TRUE)
    summary_stats <- list(median = median_value, iqr = iqr_value)
    message("Data is NOT normally distributed. Use non-parametric measures like median: ", median_value, ", IQR: ", iqr_value)
  }

  # Output results
  message(capture.output(summary_stats))
  message("Summary calculation completed for variable: ", variable)

  return(summary_stats)
}

