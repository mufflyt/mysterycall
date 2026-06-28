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


test_that("mysterycall_plot_stacked_bar returns ggplot with valid minimal inputs", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("A", "A", "B", "B"),
    outcome = c(0, 1, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_stacked_bar(df, outcome_col = "outcome", group_col = "group")
  ))

  expect_s3_class(result, "ggplot")
  expect_true(inherits(result, "gg"))
})


test_that("mysterycall_plot_stacked_bar with custom parameters returns ggplot", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    insurance = c("Medicaid", "Medicaid", "BCBS", "BCBS"),
    acceptance = c(0, 1, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_stacked_bar(
      df,
      outcome_col = "acceptance",
      group_col = "insurance",
      fill_labels = c("Denied", "Accepted"),
      colors = c("#FF0000", "#00FF00"),
      title = "Test Title",
      x_label = "Insurance Type",
      y_label = "Percentage (%)",
      show_n = FALSE,
      order_by_rate = FALSE
    )
  ))

  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_stacked_bar with NA outcomes filters and returns ggplot", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("A", "A", "B", "B", "B"),
    outcome = c(0, 1, NA, NA, 1),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_stacked_bar(df, outcome_col = "outcome", group_col = "group")
  ))

  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_stacked_bar errors on non-existent outcome_col", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("A", "B"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_plot_stacked_bar(df, outcome_col = "missing", group_col = "group"),
    "Column 'missing' not found"
  )
})


test_that("mysterycall_plot_stacked_bar errors on non-existent group_col", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    outcome = c(0, 1),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_plot_stacked_bar(df, outcome_col = "outcome", group_col = "missing"),
    "Column 'missing' not found"
  )
})


test_that("mysterycall_plot_stacked_bar errors on invalid outcome values", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("A", "B"),
    outcome = c(0, 2),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_plot_stacked_bar(df, outcome_col = "outcome", group_col = "group"),
    "must contain only 0, 1, or NA"
  )
})


test_that("mysterycall_plot_stacked_bar errors on non-data.frame input", {
  skip_if_not_installed("ggplot2")

  expect_error(
    mysterycall_plot_stacked_bar(list(a = 1), outcome_col = "x", group_col = "y"),
    "must be a data frame"
  )
})


test_that("mysterycall_plot_stacked_bar errors on insufficient colors", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("A", "B"),
    outcome = c(0, 1),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_plot_stacked_bar(
      df,
      outcome_col = "outcome",
      group_col = "group",
      colors = c("#FF0000")
    ),
    "colors.*at least 2"
  )
})


test_that("mysterycall_plot_stacked_bar errors when all outcomes are NA", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("A", "B"),
    outcome = c(NA, NA),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_plot_stacked_bar(df, outcome_col = "outcome", group_col = "group"),
    "No non-NA rows remain"
  )
})


test_that("mysterycall_plot_stacked_bar with single group returns ggplot", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("A", "A", "A", "A"),
    outcome = c(0, 0, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_stacked_bar(df, outcome_col = "outcome", group_col = "group")
  ))

  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_stacked_bar with all zeros returns ggplot", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("A", "A", "B", "B"),
    outcome = c(0, 0, 0, 0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_stacked_bar(df, outcome_col = "outcome", group_col = "group")
  ))

  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_stacked_bar with all ones returns ggplot", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("A", "A", "B", "B"),
    outcome = c(1, 1, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_stacked_bar(df, outcome_col = "outcome", group_col = "group")
  ))

  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_stacked_bar with order_by_rate=TRUE sorts by acceptance", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("Low", "Low", "Low", "High", "High"),
    outcome = c(0, 0, 0, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_stacked_bar(
      df,
      outcome_col = "outcome",
      group_col = "group",
      order_by_rate = TRUE
    )
  ))

  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_stacked_bar with order_by_rate=FALSE preserves order", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("Z", "Z", "A", "A"),
    outcome = c(1, 1, 0, 0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_stacked_bar(
      df,
      outcome_col = "outcome",
      group_col = "group",
      order_by_rate = FALSE
    )
  ))

  expect_s3_class(result, "ggplot")
})


test_that("mysterycall_plot_stacked_bar with show_n=FALSE returns ggplot", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    group = c("A", "A", "B", "B"),
    outcome = c(0, 1, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_plot_stacked_bar(
      df,
      outcome_col = "outcome",
      group_col = "group",
      show_n = FALSE
    )
  ))

  expect_s3_class(result, "ggplot")
})
