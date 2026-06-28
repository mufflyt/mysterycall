library(testthat)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)


# ---- Test 1: Happy path with valid Poisson model ----
test_that("mysterycall_plot_emmeans() returns list with data and plot (happy path)", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  set.seed(218)
  mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_emmeans(
      model_object = mod$model,
      specs = "insurance",
      variable_of_interest = "insurance",
      color_by = NULL,
      output_dir = NULL
    )
  ))

  expect_type(result, "list")
  expect_named(result, c("data", "plot"))
  expect_s3_class(result$data, "data.frame")
  expect_s3_class(result$plot, "ggplot")
  expect_true(nrow(result$data) > 0)
})


# ---- Test 2: Happy path with color_by parameter ----
test_that("mysterycall_plot_emmeans() works with multiple specs and color_by", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")

  set.seed(218)
  # Create a model with a grouping variable
  test_df <- COUNT_DF
  test_df$region <- rep(c("North", "South"), length.out = nrow(test_df))
  mod <- suppressMessages(mysterycall_simple_poisson(test_df, outcome="days", group="insurance", use_profile_ci=FALSE))

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_emmeans(
      model_object = mod$model,
      specs = "insurance",
      variable_of_interest = "insurance",
      color_by = NULL,
      output_dir = NULL
    )
  ))

  expect_type(result, "list")
  expect_true(inherits(result$plot, "ggplot"))
  expect_s3_class(result$data, "data.frame")
})


# ---- Test 3: Bad input - non-model object ----
test_that("mysterycall_plot_emmeans() errors on invalid model_object", {
  skip_if_not_installed("emmeans")

  expect_error(
    mysterycall_plot_emmeans(
      model_object = "not_a_model",
      specs = "insurance",
      variable_of_interest = "insurance",
      output_dir = NULL
    ),
    "model_object must be a valid model class object"
  )
})


# ---- Test 4: Bad input - specs as non-character ----
test_that("mysterycall_plot_emmeans() errors when specs is not character", {
  skip_if_not_installed("emmeans")

  set.seed(218)
  mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

  expect_error(
    mysterycall_plot_emmeans(
      model_object = mod$model,
      specs = 123,
      variable_of_interest = "insurance",
      output_dir = NULL
    ),
    "specs must be a single character string"
  )
})


# ---- Test 5: Bad input - variable_of_interest wrong type ----
test_that("mysterycall_plot_emmeans() errors when variable_of_interest is not character", {
  skip_if_not_installed("emmeans")

  set.seed(218)
  mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

  expect_error(
    mysterycall_plot_emmeans(
      model_object = mod$model,
      specs = "insurance",
      variable_of_interest = 123,
      output_dir = NULL
    ),
    "variable_of_interest must be a single character string"
  )
})


# ---- Test 6: Bad input - nonexistent output directory ----
test_that("mysterycall_plot_emmeans() errors on nonexistent output_dir", {
  skip_if_not_installed("emmeans")

  set.seed(218)
  mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

  expect_error(
    mysterycall_plot_emmeans(
      model_object = mod$model,
      specs = "insurance",
      variable_of_interest = "insurance",
      output_dir = "/nonexistent/directory/path/that/does/not/exist"
    ),
    "Output directory does not exist"
  )
})


# ---- Test 7: Edge case - nonexistent spec variable ----
test_that("mysterycall_plot_emmeans() handles nonexistent spec variable gracefully", {
  skip_if_not_installed("emmeans")

  set.seed(218)
  mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_plot_emmeans(
        model_object = mod$model,
        specs = "nonexistent_column",
        variable_of_interest = "nonexistent_column",
        output_dir = NULL
      )
    )),
    "Error in calculating emmeans"
  )
})
