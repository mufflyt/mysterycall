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

# Test mysterycall_extract_zip5 - Happy path
test_that("mysterycall_extract_zip5 extracts standard ZIP formats correctly", {
  result <- suppressMessages(suppressWarnings(mysterycall_extract_zip5(c("80203", "80203-1234", " 80203 "))))

  expect_type(result, "character")
  expect_length(result, 3L)
  expect_equal(result, c("80203", "80203", "80203"))
})

# Test mysterycall_extract_zip5 - Left-padding
test_that("mysterycall_extract_zip5 left-pads short ZIPs with zeros", {
  result <- suppressMessages(suppressWarnings(mysterycall_extract_zip5(c("8020", "203", "70001"))))

  expect_type(result, "character")
  expect_equal(result, c("08020", "00203", "70001"))
})

# Test mysterycall_extract_zip5 - NA and edge cases
test_that("mysterycall_extract_zip5 returns NA for unparseable inputs", {
  result <- suppressMessages(suppressWarnings(mysterycall_extract_zip5(c("abc", "  ", "12", NA, ""))))

  expect_type(result, "character")
  expect_length(result, 5L)
  expect_true(is.na(result[1]))
  expect_true(is.na(result[2]))
  expect_true(is.na(result[3]))
  expect_true(is.na(result[4]))
  expect_true(is.na(result[5]))
})

# Test mysterycall_extract_zip5 - Takes first 5 digits
test_that("mysterycall_extract_zip5 takes only first 5 digits from longer strings", {
  result <- suppressMessages(suppressWarnings(mysterycall_extract_zip5(c("802031234", "9999988888"))))

  expect_type(result, "character")
  expect_equal(result[1], "80203")
  expect_equal(result[2], "99999")
})

# Test mysterycall_extract_zip5 - Type coercion
test_that("mysterycall_extract_zip5 coerces numeric input to character", {
  result <- suppressMessages(suppressWarnings(mysterycall_extract_zip5(c(80203, 80203))))

  expect_type(result, "character")
  expect_equal(result, c("80203", "80203"))
})
