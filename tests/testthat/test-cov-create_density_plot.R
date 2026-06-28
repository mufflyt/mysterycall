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

test_that("mysterycall_plot_density: happy path with valid inputs (no transformation)", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    waiting_days = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
                  "BCBS", "BCBS", "BCBS", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  expect_no_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_plot_density(
          data = test_data,
          x_var = "waiting_days",
          fill_var = "insurance",
          x_transform = "none",
          output_dir = NA,
          verbose = FALSE
        )
      )
    )
  )
})

test_that("mysterycall_plot_density: returns ggplot object", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    waiting_days = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
                  "BCBS", "BCBS", "BCBS", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_plot_density(
        data = test_data,
        x_var = "waiting_days",
        fill_var = "insurance",
        x_transform = "none",
        output_dir = NA,
        verbose = FALSE
      )
    )
  )

  expect_s3_class(result, c("gg", "ggplot"))
})

test_that("mysterycall_plot_density: error with invalid x_var column", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    waiting_days = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
                  "BCBS", "BCBS", "BCBS", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_plot_density(
          data = test_data,
          x_var = "nonexistent_column",
          fill_var = "insurance",
          x_transform = "none",
          output_dir = NA,
          verbose = FALSE
        )
      )
    )
  )
})

test_that("mysterycall_plot_density: error with invalid fill_var column", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    waiting_days = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
                  "BCBS", "BCBS", "BCBS", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_plot_density(
          data = test_data,
          x_var = "waiting_days",
          fill_var = "nonexistent_column",
          x_transform = "none",
          output_dir = NA,
          verbose = FALSE
        )
      )
    )
  )
})

test_that("mysterycall_plot_density: log transformation works", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    waiting_days = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
                  "BCBS", "BCBS", "BCBS", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_plot_density(
        data = test_data,
        x_var = "waiting_days",
        fill_var = "insurance",
        x_transform = "log",
        output_dir = NA,
        verbose = FALSE
      )
    )
  )

  expect_s3_class(result, c("gg", "ggplot"))
})

test_that("mysterycall_plot_density: sqrt transformation works", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    waiting_days = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
                  "BCBS", "BCBS", "BCBS", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_plot_density(
        data = test_data,
        x_var = "waiting_days",
        fill_var = "insurance",
        x_transform = "sqrt",
        output_dir = NA,
        verbose = FALSE
      )
    )
  )

  expect_s3_class(result, c("gg", "ggplot"))
})

test_that("mysterycall_plot_density: filters out zero and negative values", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    waiting_days = c(-1, 0, 1, 2, 3, 4, 5, 6, 7, 8),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
                  "BCBS", "BCBS", "BCBS", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  # Should not error; negative and zero values are filtered
  expect_no_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_plot_density(
          data = test_data,
          x_var = "waiting_days",
          fill_var = "insurance",
          x_transform = "none",
          output_dir = NA,
          verbose = FALSE
        )
      )
    )
  )
})

test_that("mysterycall_plot_density: handles NA values", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    waiting_days = c(1, 2, 3, 4, 5, NA, 7, 8, 9, 10),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
                  "BCBS", "BCBS", "BCBS", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  # Should not error; NA values are filtered
  expect_no_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_plot_density(
          data = test_data,
          x_var = "waiting_days",
          fill_var = "insurance",
          x_transform = "none",
          output_dir = NA,
          verbose = FALSE
        )
      )
    )
  )
})

test_that("mysterycall_plot_density: custom labels applied correctly", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    waiting_days = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
                  "BCBS", "BCBS", "BCBS", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_plot_density(
        data = test_data,
        x_var = "waiting_days",
        fill_var = "insurance",
        x_transform = "none",
        x_label = "Custom X Label",
        y_label = "Custom Y Label",
        plot_title = "Custom Title",
        output_dir = NA,
        verbose = FALSE
      )
    )
  )

  expect_s3_class(result, c("gg", "ggplot"))
  expect_equal(result$labels$x, "Custom X Label")
  expect_equal(result$labels$y, "Custom Y Label")
  expect_equal(result$labels$title, "Custom Title")
})

test_that("mysterycall_plot_density: error with invalid x_transform", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    waiting_days = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid",
                  "BCBS", "BCBS", "BCBS", "BCBS", "BCBS"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_plot_density(
          data = test_data,
          x_var = "waiting_days",
          fill_var = "insurance",
          x_transform = "invalid_transform",
          output_dir = NA,
          verbose = FALSE
        )
      )
    )
  )
})
