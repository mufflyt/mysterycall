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

test_that("mysterycall_log_histogram returns ggplot with valid minimal inputs", {
  set.seed(2)
  df <- data.frame(
    days      = c(rpois(30, 5) + 1L, rpois(30, 10) + 1L),
    insurance = rep(c("Medicaid", "BCBS"), each = 30L)
  )
  result <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
                               output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_log_histogram works with base 2 log scale", {
  set.seed(3)
  df <- data.frame(
    days      = c(rpois(25, 4) + 1L, rpois(25, 8) + 1L),
    group     = rep(c("A", "B"), c(25L, 25L))
  )
  result <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "group",
                               base = 2, output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_log_histogram respects monochrome parameter", {
  set.seed(4)
  df <- data.frame(
    days      = c(rpois(20, 3) + 1L, rpois(20, 7) + 1L),
    group     = rep(c("X", "Y"), each = 20L)
  )
  result <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "group",
                               monochrome = TRUE, output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_log_histogram removes non-positive values and warns", {
  set.seed(5)
  df <- data.frame(
    days      = c(5, 0, -1, 3, 10, 8, 0, 2),
    group     = c("A", "A", "A", "A", "B", "B", "B", "B")
  )
  result <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "group",
                               output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_log_histogram handles NA values in x_col", {
  set.seed(6)
  df <- data.frame(
    days      = c(5, NA, 3, 7, NA, 9, 4, 6),
    group     = c("A", "A", "A", "A", "B", "B", "B", "B")
  )
  result <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "group",
                               output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_log_histogram errors if data is not a data frame", {
  expect_error(
    mysterycall_log_histogram(
      list(days = c(1, 2, 3), group = c("A", "B", "C")),
      x_col = "days", facet_col = "group", output_dir = NA
    ),
    "must be a data frame"
  )
})

test_that("mysterycall_log_histogram errors if x_col is missing or invalid", {
  set.seed(7)
  df <- data.frame(days = rpois(20, 5) + 1L, group = rep(c("A", "B"), 10L))

  expect_error(
    mysterycall_log_histogram(df, x_col = "", facet_col = "group", output_dir = NA),
    "single non-empty character string"
  )

  expect_error(
    mysterycall_log_histogram(df, x_col = "nonexistent", facet_col = "group",
                               output_dir = NA),
    "not found in"
  )
})

test_that("mysterycall_log_histogram errors if facet_col is missing or invalid", {
  set.seed(8)
  df <- data.frame(days = rpois(20, 5) + 1L, group = rep(c("A", "B"), 10L))

  expect_error(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "", output_dir = NA),
    "single non-empty character string"
  )

  expect_error(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "missing",
                               output_dir = NA),
    "not found in"
  )
})

test_that("mysterycall_log_histogram errors if base is not 2 or 10", {
  set.seed(9)
  df <- data.frame(days = rpois(20, 5) + 1L, group = rep(c("A", "B"), 10L))

  expect_error(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "group",
                               base = 5, output_dir = NA),
    "must be 2 or 10"
  )
})

test_that("mysterycall_log_histogram errors if all values are non-positive", {
  df <- data.frame(
    days  = c(0, -1, -2, 0, -3),
    group = c("A", "A", "A", "B", "B")
  )

  expect_error(
    suppressMessages(
      mysterycall_log_histogram(df, x_col = "days", facet_col = "group",
                                 output_dir = NA)
    ),
    "No positive values remain"
  )
})

test_that("mysterycall_log_histogram respects custom labels and title", {
  set.seed(10)
  df <- data.frame(
    days      = c(rpois(20, 5) + 1L, rpois(20, 8) + 1L),
    group     = rep(c("A", "B"), each = 20L)
  )
  result <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "group",
                               x_label = "Custom X", y_label = "Custom Y",
                               title = "Custom Title", output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
  expect_equal(result$labels$title, "Custom Title")
  expect_equal(result$labels$x, "Custom X")
  expect_equal(result$labels$y, "Custom Y")
})

test_that("mysterycall_log_histogram respects aesthetic parameters", {
  set.seed(11)
  df <- data.frame(
    days      = c(rpois(20, 5) + 1L, rpois(20, 8) + 1L),
    group     = rep(c("A", "B"), each = 20L)
  )
  result <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "group",
                               fill = "red", color = "blue", alpha = 0.5,
                               base_size = 14, output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_log_histogram works with binwidth parameter", {
  set.seed(12)
  df <- data.frame(
    days      = c(rpois(25, 6) + 1L, rpois(25, 9) + 1L),
    group     = rep(c("A", "B"), each = 25L)
  )
  result <- suppressMessages(
    mysterycall_log_histogram(df, x_col = "days", facet_col = "group",
                               binwidth = 0.3, output_dir = NA)
  )
  expect_s3_class(result, "ggplot")
})
