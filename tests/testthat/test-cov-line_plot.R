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

test_that("mysterycall_plot_line() happy path with minimal inputs", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    x_var = rep(c("A", "B", "C"), each = 5),
    y_var = rnorm(15, mean = 10, sd = 2),
    stringsAsFactors = FALSE
  )

  expect_no_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_plot_line(
          plot_data = test_data,
          x_var = "x_var",
          y_var = "y_var",
          output_dir = tempdir(),
          verbose = FALSE
        )
      )
    )
  )
})

test_that("mysterycall_plot_line() returns ggplot object", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    category = rep(c("Control", "Treatment"), each = 10),
    value = rnorm(20, mean = 50, sd = 5),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_plot_line(
        plot_data = test_data,
        x_var = "category",
        y_var = "value",
        output_dir = tempdir(),
        verbose = FALSE
      )
    )
  )

  expect_s3_class(result, c("gg", "ggplot"))
})

test_that("mysterycall_plot_line() respects y_transform parameter", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    group = rep(c("X", "Y"), each = 8),
    count = c(1, 2, 3, 4, 5, 6, 7, 8, 10, 20, 30, 40, 50, 60, 70, 80),
    stringsAsFactors = FALSE
  )

  # Test log transformation
  result_log <- suppressMessages(
    suppressWarnings(
      mysterycall_plot_line(
        plot_data = test_data,
        x_var = "group",
        y_var = "count",
        y_transform = "log",
        output_dir = tempdir(),
        verbose = FALSE
      )
    )
  )
  expect_s3_class(result_log, c("gg", "ggplot"))

  # Test sqrt transformation
  result_sqrt <- suppressMessages(
    suppressWarnings(
      mysterycall_plot_line(
        plot_data = test_data,
        x_var = "group",
        y_var = "count",
        y_transform = "sqrt",
        output_dir = tempdir(),
        verbose = FALSE
      )
    )
  )
  expect_s3_class(result_sqrt, c("gg", "ggplot"))
})

test_that("mysterycall_plot_line() errors on missing required columns", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    a = 1:5,
    b = 6:10,
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_plot_line(
          plot_data = test_data,
          x_var = "nonexistent_x",
          y_var = "b",
          output_dir = tempdir(),
          verbose = FALSE
        )
      )
    )
  )
})

test_that("mysterycall_plot_line() handles NAs in y_var correctly", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    group = c("A", "A", "B", "B", "C", "C"),
    value = c(1, NA, 3, 4, NA, 6),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_plot_line(
        plot_data = test_data,
        x_var = "group",
        y_var = "value",
        output_dir = tempdir(),
        verbose = FALSE
      )
    )
  )

  expect_s3_class(result, c("gg", "ggplot"))
})

test_that("mysterycall_plot_line() works with geom_line grouping", {
  skip_if_not_installed("ggplot2")

  set.seed(42)
  test_data <- data.frame(
    x = rep(c("Low", "High"), each = 6),
    y = rnorm(12, mean = 50, sd = 5),
    id = rep(1:6, 2),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_plot_line(
        plot_data = test_data,
        x_var = "x",
        y_var = "y",
        use_geom_line = TRUE,
        geom_line_group = "id",
        output_dir = tempdir(),
        verbose = FALSE
      )
    )
  )

  expect_s3_class(result, c("gg", "ggplot"))
})
