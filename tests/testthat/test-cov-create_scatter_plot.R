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

test_that("mysterycall_plot_scatter: happy path with minimal inputs", {
  skip_if_not_installed("ggplot2")

  p <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = AUDIT,
      x_var = "insurance",
      y_var = "wait_days",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))

  expect_s3_class(p, c("gg", "ggplot"))
})

test_that("mysterycall_plot_scatter: returns ggplot object", {
  skip_if_not_installed("ggplot2")

  p <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = AUDIT,
      x_var = "insurance",
      y_var = "wait_days",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))

  expect_s3_class(p, c("gg", "ggplot"))
})

test_that("mysterycall_plot_scatter: handles y_transform parameter", {
  skip_if_not_installed("ggplot2")

  # Test log transformation
  p_log <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = AUDIT,
      x_var = "insurance",
      y_var = "wait_days",
      y_transform = "log",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))
  expect_s3_class(p_log, c("gg", "ggplot"))

  # Test sqrt transformation
  p_sqrt <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = AUDIT,
      x_var = "insurance",
      y_var = "wait_days",
      y_transform = "sqrt",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))
  expect_s3_class(p_sqrt, c("gg", "ggplot"))
})

test_that("mysterycall_plot_scatter: rejects invalid y_transform", {
  skip_if_not_installed("ggplot2")

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_plot_scatter(
        plot_data = AUDIT,
        x_var = "insurance",
        y_var = "wait_days",
        y_transform = "invalid_transform",
        output_dir = tempdir()
      )
    )),
    regexp = "should be one of"
  )
})

test_that("mysterycall_plot_scatter: filters out negative/zero/NA values", {
  skip_if_not_installed("ggplot2")

  # Create data with problematic values
  test_data <- data.frame(
    insurance = c("A", "B", "A", "B", "A", "B"),
    days = c(5, 10, 0, -3, NA, 7),
    stringsAsFactors = FALSE
  )

  p <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = test_data,
      x_var = "insurance",
      y_var = "days",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))

  expect_s3_class(p, c("gg", "ggplot"))
})

test_that("mysterycall_plot_scatter: accepts custom labels", {
  skip_if_not_installed("ggplot2")

  p <- suppressMessages(suppressWarnings(
    mysterycall_plot_scatter(
      plot_data = AUDIT,
      x_var = "insurance",
      y_var = "wait_days",
      x_label = "Insurance Type",
      y_label = "Days to Appointment",
      plot_title = "Appointment Waiting Times",
      output_dir = tempdir(),
      verbose = FALSE
    )
  ))

  expect_s3_class(p, c("gg", "ggplot"))
})

test_that("mysterycall_plot_scatter: errors when x_var column missing", {
  skip_if_not_installed("ggplot2")

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_plot_scatter(
        plot_data = AUDIT,
        x_var = "nonexistent_col",
        y_var = "wait_days",
        output_dir = tempdir()
      )
    ))
  )
})

test_that("mysterycall_plot_scatter: errors when y_var column missing", {
  skip_if_not_installed("ggplot2")

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_plot_scatter(
        plot_data = AUDIT,
        x_var = "insurance",
        y_var = "nonexistent_col",
        output_dir = tempdir()
      )
    ))
  )
})
