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

test_that("validate_npi: happy path with valid NPIs", {
  result <- suppressMessages(mysterycall_validate_npi(AUDIT))
  expect_s3_class(result, "data.frame")
  expect_true("npi_is_valid" %in% names(result))
  expect_true("npi" %in% names(result))
  expect_true(all(result$npi_is_valid, na.rm = TRUE))
  expect_equal(class(result$npi), "character")
  expect_equal(nrow(result), 2L)
})

test_that("validate_npi: edge case with NA and empty strings", {
  df <- data.frame(
    npi = c("1234567893", NA_character_, "", "1234567893"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_validate_npi(df))
  expect_s3_class(result, "data.frame")
  expect_true("npi_is_valid" %in% names(result))
  expect_equal(nrow(result), 2L)
  expect_equal(result$npi, c("1234567893", "1234567893"))
})

test_that("validate_npi: edge case with zero-length input", {
  df <- data.frame(npi = character(0), other_col = integer(0), stringsAsFactors = FALSE)
  result <- suppressMessages(mysterycall_validate_npi(df))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_true("npi_is_valid" %in% names(result))
  expect_true("other_col" %in% names(result))
})

test_that("validate_npi: edge case with wrong length NPIs", {
  df <- data.frame(
    npi = c("123456789", "12345678901", "1234567893"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_validate_npi(df))
  expect_s3_class(result, "data.frame")
  expect_true("npi_is_valid" %in% names(result))
  expect_equal(nrow(result), 1L)
  expect_equal(result$npi, "1234567893")
})

test_that("validate_npi: edge case with non-digit characters", {
  df <- data.frame(
    npi = c("123-456-7893", "1234567893", "ABCDEFGHIJ"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_validate_npi(df))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_true(all(result$npi == "1234567893"))
})

test_that("validate_npi: error on missing npi column", {
  df <- data.frame(
    other_col = c("value1", "value2"),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_validate_npi(df),
    "missing required column `npi`"
  )
})

test_that("validate_npi: error on wrong input type", {
  expect_error(
    mysterycall_validate_npi(123),
    "must be a data frame or a single CSV file path"
  )
  expect_error(
    mysterycall_validate_npi(list(npi = "1234567893")),
    "must be a data frame or a single CSV file path"
  )
})

test_that("validate_npi: error on non-existent file path", {
  expect_error(
    suppressMessages(mysterycall_validate_npi("/nonexistent/file.csv")),
    "CSV file not found"
  )
})

test_that("validate_npi: preserves all columns in output", {
  df <- data.frame(
    npi = c("1234567893", "1234567893"),
    col_a = c("x", "y"),
    col_b = c(1L, 2L),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_validate_npi(df))
  expect_true(all(c("npi", "col_a", "col_b", "npi_is_valid") %in% names(result)))
  expect_equal(result$col_a, c("x", "y"))
  expect_equal(result$col_b, c(1L, 2L))
})

test_that("validate_npi: converts numeric NPI to character", {
  df <- data.frame(
    npi = c(1234567893, 1234567893),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_validate_npi(df))
  expect_equal(class(result$npi), "character")
  expect_equal(nrow(result), 2L)
})

test_that("validate_npi: handles whitespace in NPI", {
  df <- data.frame(
    npi = c("  1234567893  ", "1234567893"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_validate_npi(df))
  expect_equal(nrow(result), 2L)
  expect_equal(result$npi, c("1234567893", "1234567893"))
})

test_that("validate_npi: returns npi_is_valid as first logical column position", {
  df <- data.frame(
    npi = c("1234567893"),
    other = c("value"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_validate_npi(df))
  expect_true(is.logical(result$npi_is_valid))
  expect_equal(length(result$npi_is_valid), 1L)
})

test_that("validate_npi: all rows in result have npi_is_valid = TRUE", {
  df <- data.frame(
    npi = c("1234567893", "1234567893", "9876543210"),
    col = c("a", "b", "c"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_validate_npi(df))
  expect_true(all(result$npi_is_valid))
})
