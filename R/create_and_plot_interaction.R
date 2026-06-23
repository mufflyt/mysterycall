#' Create and plot interaction effects from a Poisson GLMM
#'
#' Reads an `.rds` dataset, fits a Poisson generalized linear mixed model with
#' an interaction term, and saves a publication-ready interaction plot.
#'
#' @param data_path A character string specifying the path to the .rds file containing the dataset.
#' @param response_variable A character string specifying the name of the response variable in the dataset.
#' @param variable_of_interest A character string specifying the first categorical predictor variable in the interaction.
#' @param interaction_variable A character string specifying the second categorical predictor variable in the interaction.
#' @param random_intercept A character string specifying the variable to be used as the random intercept in the model (e.g., "city").
#' @param output_path A character string specifying the directory where the interaction plot will be saved.
#' @param resolution Integer DPI used when saving the plot. Defaults to `100`.
#'
#' @return A named list with two elements:
#' \describe{
#'   \item{`model`}{The fitted `lme4::glmer()` model object (class `glmerMod`).}
#'   \item{`effects_plot_data`}{A data frame with one row per
#'     `interaction_variable` x `variable_of_interest` combination and columns
#'     named after those two arguments plus `mean_pred` (numeric mean predicted
#'     response on the link scale).}
#' }
#' A PNG file is also written to `output_path` as a side effect.
#'
#' @details
#' The function:
#' \enumerate{
#'   \item loads data from `data_path`,
#'   \item standardizes selected columns for modeling,
#'   \item fits `response ~ interaction + (1 | random_intercept)` with a Poisson link,
#'   \item computes grouped mean predicted responses, and
#'   \item writes a PNG plot to `output_path`.
#' }
#'
#' Use this helper when comparing how two categorical predictors jointly relate
#' to a count-like outcome (for example, business days until appointment).
#'
#' @examplesIf interactive()
#' # Example 1: Analyzing the effect of gender and appointment center on wait times
#' result <- mysterycall_plot_interaction(
#'   data_path = "Ari/data/Phase2/late_phase_2_ENT_analysis_3.rds",
#'   response_variable = "business_days_until_appointment",
#'   variable_of_interest = "central_number_e_g_appointment_center",
#'   interaction_variable = "gender",
#'   random_intercept = "city",
#'   output_path = "Ari/data/figures",
#'   resolution = 100
#' )
#'
#' # Example 2: Examining the interaction between insurance type and scenario on appointment delays
#' result <- mysterycall_plot_interaction(
#'   data_path = "data/healthcare_calls.rds",
#'   response_variable = "business_days_until_appointment",
#'   variable_of_interest = "insurance_type",
#'   interaction_variable = "scenario",
#'   random_intercept = "state",
#'   output_path = "figures/insurance_scenario_interaction",
#'   resolution = 150
#' )
#'
#' # Example 3: Studying the interaction between gender and subspecialty in wait times
#' result <- mysterycall_plot_interaction(
#'   data_path = "data/mystery_caller_study.rds",
#'   response_variable = "waiting_time_days",
#'   variable_of_interest = "subspecialty",
#'   interaction_variable = "gender",
#'   random_intercept = "clinic_id",
#'   output_path = "results/waiting_times",
#'   resolution = 300
#' )
#'
#' @importFrom dplyr rename mutate group_by summarize
#' @seealso [mysterycall_plot_emmeans()], [mysterycall_create_formula()]
#' @family modeling helpers
#' @export
mysterycall_plot_interaction <- function(data_path, response_variable, variable_of_interest, interaction_variable, random_intercept, output_path, resolution = 100) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("Package 'lme4' is required for mysterycall_plot_interaction()", call. = FALSE)
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for mysterycall_plot_interaction(). Install with: install.packages('ggplot2')", call. = FALSE)
  }
  # Read the data
  data <- readRDS(data_path)

  # Ensure the data is a data frame
  if (!is.data.frame(data)) {
    stop("Data must be a data.frame", call. = FALSE)
  }

  required_cols <- c(response_variable, variable_of_interest, interaction_variable, random_intercept)
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols)) {
    stop("The following required columns were not found in the data: ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  # Log inputs
  cat("Inputs:\n")
  cat("response_variable:", response_variable, "\n")
  cat("variable_of_interest:", variable_of_interest, "\n")
  cat("interaction_variable:", interaction_variable, "\n")
  cat("random_intercept:", random_intercept, "\n")
  cat("output_path:", output_path, "\n")
  cat("resolution:", resolution, "\n\n")

  # Rename the columns for simplicity
  data <- data %>%
    dplyr::rename(
      response_var = !!rlang::sym(response_variable),
      var_interest = !!rlang::sym(variable_of_interest),
      int_var = !!rlang::sym(interaction_variable)
    )

  # Ensure the columns are in the correct format
  data <- data %>%
    dplyr::mutate(
      response_var = as.numeric(.data$response_var),
      var_interest = as.factor(.data$var_interest),
      int_var = as.factor(.data$int_var)
    )

  # Remove any rows with NA values
  data <- na.omit(data)

  # Log a data summary without truncating rows
  cat("Data summary after renaming and type conversion:\n")
  cat("Rows:", nrow(data), "Columns:", ncol(data), "\n")
  cat("Column classes:\n")

  cat("\n\n")

  # Construct the model formula
  interaction_term <- "int_var * var_interest"
  model_formula <- as.formula(paste("response_var ~", interaction_term, "+ (1 |", random_intercept, ")"))

  # Log model formula
  cat("Model formula:", deparse(model_formula), "\n\n")

  # Fit the model with interaction
  cat("Fitting the model...\n")
  glmer_model <- lme4::glmer(model_formula,
                             data = data,
                             family = poisson(link = "log"),
                             nAGQ = 0,
                             verbose = 0L)
  cat("Model fitted successfully.\n\n")

  # Log model summary
  cat("Model summary:\n")
  message(capture.output(summary(glmer_model)))
  cat("\n\n")

  # Create the effects plot manually
  cat("Creating effects plot...\n")
  pred_data <- data %>%
    dplyr::mutate(pred = predict(glmer_model, type = "response"))

  plot_data <- pred_data %>%
    dplyr::group_by(.data$int_var, .data$var_interest) %>%
    dplyr::summarize(mean_pred = mean(.data$pred, na.rm = TRUE), .groups = 'drop')

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = int_var, y = mean_pred, color = var_interest)) +
    ggplot2::geom_point() +
    ggplot2::geom_line(ggplot2::aes(group = var_interest)) +
    ggplot2::labs(title = "Interaction Effect Plot", y = response_variable, x = interaction_variable) +
    ggplot2::theme_minimal()

  # Save the plot
  dir.create(output_path, recursive = TRUE, showWarnings = FALSE)
  plot_filename <- file.path(output_path, paste0("interaction_", interaction_variable, "_", variable_of_interest, ".png"))
  cat("Saving effects plot to:", plot_filename, "\n")
  ggplot2::ggsave(plot_filename, plot = p, width = 6, height = 4, dpi = resolution)
  cat("Effects plot saved successfully.\n\n")

  message(capture.output(glmer_model))
  message("Effects plot object computed.")

  # Return the model and effects plot data
  return(list(model = glmer_model, effects_plot_data = plot_data))
}
