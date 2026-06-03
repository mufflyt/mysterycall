#' Create a Formula for Poisson Model
#'
#' This function creates a formula for a Poisson model based on the provided data,
#' response variable, and optional random effect.
#'
#' @param data A data frame containing all predictor and response variables.
#'   Factor columns are detected automatically and included as-is; all other
#'   non-response columns are treated as fixed-effect predictors.
#' @param response_var Character scalar naming the count/numeric response
#'   (outcome) column in `data`.
#' @param random_effect Optional character scalar naming a grouping column to
#'   add as a random intercept `(1 | random_effect)` term, e.g. `"physician"`.
#'   Default `NULL` (no random effects; produces a fixed-effects-only formula).
#'
#' @return A `formula` object.  When `random_effect` is `NULL` the formula is
#'   suitable for [stats::glm()]; when provided it is suitable for
#'   [lme4::glmer()].
#' @seealso [mysterycall_poisson_model()] which uses this formula builder
#'   internally.
#' @importFrom stats as.formula
#'
#' @examples
#' df <- data.frame(days = c(5, 10, 15), age = c(30, 40, 50), name = c("A", "B", "C"))
#' mysterycall_create_formula(df, "days", random_effect = "name")
#' mysterycall_create_formula(df, "days")  # fixed-effects only
#'
#' @family modeling helpers
#' @keywords internal
mysterycall_create_formula <- function(data, response_var, random_effect = NULL) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!response_var %in% names(data)) {
    stop(sprintf("Response variable '%s' not found in data.", response_var), call. = FALSE)
  }
  if (!is.null(random_effect) && !random_effect %in% names(data)) {
    stop(sprintf("Random effect variable '%s' not found in data.", random_effect), call. = FALSE)
  }

  message(sprintf("Creating formula with response variable: %s", response_var))

  # Get the column names of the dataframe except for the response variable and random effect
  predictor_vars <- setdiff(names(data), c(response_var, random_effect))

  if (length(predictor_vars) == 0) {
    stop("No predictor variables remain after excluding response_var and random_effect.", call. = FALSE)
  }
  message(sprintf(
    "Predictor variables identified: %s",
    paste(predictor_vars, collapse = ", ")
  ))

  # Enclose predictor variables in backticks to handle special characters or spaces
  predictor_vars <- vapply(predictor_vars, function(x) paste0("`", x, "`"), character(1L))
  message(sprintf(
    "Predictor variables after formatting: %s",
    paste(predictor_vars, collapse = ", ")
  ))

  # Create the initial formula string without the random effect
  formula_str <- paste(response_var, "~", paste(predictor_vars, collapse = " + "))
  message(sprintf("Initial formula string: %s", formula_str))

  # If a random effect is provided, append it to the formula
  if (!is.null(random_effect)) {
    formula_str <- paste(formula_str, "+ (1 |", random_effect, ")")
    message(sprintf("Formula string with random effect: %s", formula_str))
  }

  # Convert the formula string to a formula object
  formula_obj <- as.formula(formula_str)
  message(sprintf("Final formula object created: %s", deparse(formula_obj)))

  return(formula_obj)
}
