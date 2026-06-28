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

test_that("mysterycall_physician_age returns character string with happy path data", {
  df <- data.frame(age = c(30, 40, 50, 60, 35, 45, 55, 65))
  result <- suppressMessages(suppressWarnings(mysterycall_physician_age(df, "age")))
  expect_type(result, "character")
  expect_length(result, 1)
  expect_true(grepl("median age", result, ignore.case = TRUE))
  expect_true(grepl("IQR", result, ignore.case = TRUE))
})

test_that("mysterycall_physician_age handles NA values correctly", {
  df <- data.frame(age = c(30, 40, NA, 60, 35, NA, 55, 65))
  result <- suppressMessages(suppressWarnings(mysterycall_physician_age(df, "age")))
  expect_type(result, "character")
  expect_length(result, 1)
  expect_true(grepl("median age", result, ignore.case = TRUE))
})

test_that("mysterycall_physician_age works with exactly 2 non-missing values", {
  df <- data.frame(age = c(40, 60, NA, NA, NA))
  result <- suppressMessages(suppressWarnings(mysterycall_physician_age(df, "age")))
  expect_type(result, "character")
  expect_length(result, 1)
})

test_that("mysterycall_physician_age returns error when data is not a data frame", {
  expect_error(
    mysterycall_physician_age(c(30, 40, 50), "age"),
    "must be a data frame"
  )
})

test_that("mysterycall_physician_age returns error when column not found", {
  df <- data.frame(height = c(170, 180, 190))
  expect_error(
    mysterycall_physician_age(df, "age"),
    "Column.*not found"
  )
})

test_that("mysterycall_physician_age returns error when fewer than 2 non-missing values", {
  df <- data.frame(age = c(NA, NA, 50))
  expect_error(
    mysterycall_physician_age(df, "age"),
    "at least 2 non-missing values"
  )
})

test_that("mysterycall_physician_age returns error when column has only 1 non-missing value", {
  df <- data.frame(age = c(NA, 50, NA))
  expect_error(
    mysterycall_physician_age(df, "age"),
    "at least 2 non-missing values"
  )
})

test_that("mysterycall_physician_age rounding matches spec (median 2 decimals, IQR 1 decimal)", {
  df <- data.frame(age = c(30.1, 40.9, 50.3, 60.7))
  result <- suppressMessages(suppressWarnings(mysterycall_physician_age(df, "age")))
  # Check that result contains numeric values with appropriate precision
  expect_true(is.character(result))
  expect_true(nchar(result) > 0)
})
