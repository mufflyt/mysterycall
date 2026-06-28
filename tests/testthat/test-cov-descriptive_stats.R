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

test_that("mysterycall_descriptive_stats happy path: integer column", {
  result <- suppressMessages(mysterycall_descriptive_stats(AUDIT, "wait_days"))

  expect_type(result, "list")
  expect_named(result, c("median", "q25", "q75", "n", "n_missing", "sentence"))
  expect_true(is.numeric(result$median))
  expect_true(is.numeric(result$q25))
  expect_true(is.numeric(result$q75))
  expect_true(is.integer(result$n))
  expect_true(is.integer(result$n_missing))
  expect_true(is.character(result$sentence))
  expect_equal(result$n, 4L)
  expect_equal(result$n_missing, 0L)
})

test_that("mysterycall_descriptive_stats happy path: numeric column with decimals", {
  set.seed(2)
  df <- data.frame(value = rnorm(20, mean = 100, sd = 15))
  result <- suppressMessages(mysterycall_descriptive_stats(df, "value", digits = 2, digits_q = 1))

  expect_type(result, "list")
  expect_named(result, c("median", "q25", "q75", "n", "n_missing", "sentence"))
  expect_equal(result$n, 20L)
  expect_equal(result$n_missing, 0L)
  expect_true(grepl("Median value:", result$sentence))
})

test_that("mysterycall_descriptive_stats with NA values", {
  set.seed(3)
  df <- data.frame(x = c(1, 2, NA, 4, 5, NA, NA))
  result <- suppressMessages(mysterycall_descriptive_stats(df, "x"))

  expect_type(result, "list")
  expect_equal(result$n, 4L)
  expect_equal(result$n_missing, 3L)
  expect_true(is.numeric(result$median))
  expect_false(is.na(result$median))
})

test_that("mysterycall_descriptive_stats all-NA edge case", {
  df <- data.frame(x = c(NA_real_, NA_real_, NA_real_))
  result <- suppressMessages(mysterycall_descriptive_stats(df, "x"))

  expect_type(result, "list")
  expect_equal(result$n, 0L)
  expect_equal(result$n_missing, 3L)
  expect_true(is.na(result$median))
  expect_true(is.na(result$q25))
  expect_true(is.na(result$q75))
  expect_true(grepl("NA \\(IQR: NA-NA\\)", result$sentence))
})

test_that("mysterycall_descriptive_stats zero-row data frame", {
  df <- data.frame(x = numeric(0))
  result <- suppressMessages(mysterycall_descriptive_stats(df, "x"))

  expect_type(result, "list")
  expect_equal(result$n, 0L)
  expect_equal(result$n_missing, 0L)
  expect_true(is.na(result$median))
})

test_that("mysterycall_descriptive_stats digits parameter controls median rounding", {
  set.seed(4)
  df <- data.frame(x = c(1.123, 2.456, 3.789, 4.111, 5.999))

  result_2 <- suppressMessages(mysterycall_descriptive_stats(df, "x", digits = 2))
  result_0 <- suppressMessages(mysterycall_descriptive_stats(df, "x", digits = 0))

  expect_true(is.numeric(result_2$median))
  expect_true(is.numeric(result_0$median))
  # Check sentence formatting reflects digits parameter
  expect_true(grepl("\\.", result_2$sentence))
})

test_that("mysterycall_descriptive_stats digits_q parameter controls quartile rounding", {
  set.seed(5)
  df <- data.frame(x = c(1.567, 2.234, 3.891, 4.123, 5.456, 6.789))

  result_1 <- suppressMessages(mysterycall_descriptive_stats(df, "x", digits_q = 1))
  result_0 <- suppressMessages(mysterycall_descriptive_stats(df, "x", digits_q = 0))

  expect_true(is.numeric(result_1$q25))
  expect_true(is.numeric(result_0$q25))
  # Results should still be numeric
  expect_type(result_1$q25, "double")
  expect_type(result_0$q25, "double")
})

test_that("mysterycall_descriptive_stats sentence includes column name", {
  df <- data.frame(my_col = c(10, 20, 30, 40, 50))
  result <- suppressMessages(mysterycall_descriptive_stats(df, "my_col"))

  expect_true(grepl("my_col", result$sentence))
  expect_true(grepl("Median", result$sentence))
  expect_true(grepl("IQR:", result$sentence))
})

test_that("mysterycall_descriptive_stats rejects non-numeric column", {
  df <- data.frame(name = c("a", "b", "c"))

  expect_error(
    mysterycall_descriptive_stats(df, "name"),
    "must be numeric"
  )
})

test_that("mysterycall_descriptive_stats rejects missing column", {
  df <- data.frame(x = c(1, 2, 3))

  expect_error(
    mysterycall_descriptive_stats(df, "missing_col"),
    "not found"
  )
})

test_that("mysterycall_descriptive_stats rejects non-string column argument", {
  df <- data.frame(x = c(1, 2, 3))

  expect_error(
    mysterycall_descriptive_stats(df, 1),
    "string"
  )
})

test_that("mysterycall_descriptive_stats rejects non-data.frame input", {
  expect_error(
    mysterycall_descriptive_stats(list(x = c(1, 2, 3)), "x"),
    "data.frame"
  )
})

test_that("mysterycall_descriptive_stats negative digits parameter", {
  df <- data.frame(x = c(1, 2, 3))

  expect_error(
    mysterycall_descriptive_stats(df, "x", digits = -1)
  )
})

test_that("mysterycall_descriptive_stats with COUNT_DF fixture", {
  result <- suppressMessages(mysterycall_descriptive_stats(COUNT_DF, "days", digits = 2))

  expect_type(result, "list")
  expect_named(result, c("median", "q25", "q75", "n", "n_missing", "sentence"))
  expect_equal(result$n, 80L)
  expect_equal(result$n_missing, 0L)
  expect_true(is.numeric(result$median))
  expect_true(grepl("days", result$sentence))
})

test_that("mysterycall_descriptive_stats single value", {
  df <- data.frame(x = 42)
  result <- suppressMessages(mysterycall_descriptive_stats(df, "x"))

  expect_equal(result$n, 1L)
  expect_equal(result$n_missing, 0L)
  expect_equal(result$median, 42)
  expect_equal(result$q25, 42)
  expect_equal(result$q75, 42)
})

test_that("mysterycall_descriptive_stats two values", {
  df <- data.frame(x = c(10, 20))
  result <- suppressMessages(mysterycall_descriptive_stats(df, "x"))

  expect_equal(result$n, 2L)
  expect_equal(result$median, 15)
  expect_true(is.numeric(result$q25))
  expect_true(is.numeric(result$q75))
})
