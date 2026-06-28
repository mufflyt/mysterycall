library(testthat)
library(mysterycall)

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


test_that("mysterycall_plot_scatter: happy path with minimal inputs returns ggplot", {
  skip_if_not_installed("ggplot2")
  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = COUNT_DF,
      x_var = "insurance",
      y_var = "days",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))
  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_scatter: y_transform parameter works correctly", {
  skip_if_not_installed("ggplot2")

  # Test "none" transformation
  result_none <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = COUNT_DF,
      x_var = "insurance",
      y_var = "days",
      y_transform = "none",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))
  expect_s3_class(result_none, "ggplot")

  # Test "log" transformation
  result_log <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = COUNT_DF,
      x_var = "insurance",
      y_var = "days",
      y_transform = "log",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))
  expect_s3_class(result_log, "ggplot")

  # Test "sqrt" transformation
  result_sqrt <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = COUNT_DF,
      x_var = "insurance",
      y_var = "days",
      y_transform = "sqrt",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))
  expect_s3_class(result_sqrt, "ggplot")
})


test_that("mysterycall_plot_scatter: edge case with negative, zero, and NA values", {
  skip_if_not_installed("ggplot2")
  set.seed(2)
  test_data <- data.frame(
    category = c("A", "A", "A", "B", "B", "B"),
    value = c(5, 0, -3, 10, NA, 20),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = test_data,
      x_var = "category",
      y_var = "value",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))
  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_scatter: custom labels and jitter parameters", {
  skip_if_not_installed("ggplot2")
  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = COUNT_DF,
      x_var = "insurance",
      y_var = "days",
      x_label = "Insurance Type",
      y_label = "Days to Appointment",
      plot_title = "Waiting Times by Insurance",
      jitter_width = 0.3,
      jitter_height = 0.1,
      point_alpha = 0.8,
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))
  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_scatter: errors on invalid y_transform", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_plot_scatter(
      plot_data = COUNT_DF,
      x_var = "insurance",
      y_var = "days",
      y_transform = "invalid_transform",
      output_dir = tempdir()
    ),
    regexp = "should be one of"
  )
})


test_that("mysterycall_plot_scatter: errors when required arguments missing", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_plot_scatter(
      plot_data = COUNT_DF,
      x_var = "insurance"
    )
  )
})


test_that("mysterycall_plot_scatter: errors when x_var column not in data", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_plot_scatter(
      plot_data = COUNT_DF,
      x_var = "nonexistent_col",
      y_var = "days",
      output_dir = tempdir()
    )
  )
})


test_that("mysterycall_plot_scatter: errors when y_var column not in data", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_plot_scatter(
      plot_data = COUNT_DF,
      x_var = "insurance",
      y_var = "nonexistent_col",
      output_dir = tempdir()
    )
  )
})


test_that("mysterycall_plot_scatter: handles single category data", {
  skip_if_not_installed("ggplot2")
  set.seed(3)
  single_cat <- data.frame(
    category = rep("A", 10),
    value = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = single_cat,
      x_var = "category",
      y_var = "value",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))
  expect_s3_class(result, "ggplot")
})
