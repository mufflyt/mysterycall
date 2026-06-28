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

# Test 1: Happy path with full state names
test_that("medicaid_expansion_status returns correct status for full state names", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_medicaid_expansion_status(c("California", "Texas", "New York"))
  ))

  expect_type(result, "character")
  expect_length(result, 3)
  expect_equal(result[1], "Expanded")      # California expanded
  expect_equal(result[2], "Not Expanded")  # Texas did not expand
  expect_equal(result[3], "Expanded")      # New York expanded
})

# Test 2: Happy path with state abbreviations
test_that("medicaid_expansion_status returns correct status for state abbreviations", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_medicaid_expansion_status(c("CA", "TX", "NY", "FL"))
  ))

  expect_type(result, "character")
  expect_length(result, 4)
  expect_equal(result[1], "Expanded")      # CA expanded
  expect_equal(result[2], "Not Expanded")  # TX did not expand
  expect_equal(result[3], "Expanded")      # NY expanded
  expect_equal(result[4], "Not Expanded")  # FL did not expand
})

# Test 3: Edge case - single state
test_that("medicaid_expansion_status handles single state input", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_medicaid_expansion_status("Massachusetts")
  ))

  expect_type(result, "character")
  expect_length(result, 1)
  expect_equal(result, "Expanded")
})

# Test 4: Edge case - NA input returns NA
test_that("medicaid_expansion_status returns NA for NA input", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_medicaid_expansion_status(NA_character_)
  ))

  expect_type(result, "character")
  expect_length(result, 1)
  expect_true(is.na(result))
})

# Test 5: Edge case - NA within vector
test_that("medicaid_expansion_status handles NA within a vector", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_medicaid_expansion_status(c("Texas", NA, "Colorado"))
  ))

  expect_type(result, "character")
  expect_length(result, 3)
  expect_equal(result[1], "Not Expanded")
  expect_true(is.na(result[2]))
  expect_equal(result[3], "Expanded")
})

# Test 6: Edge case - empty vector
test_that("medicaid_expansion_status handles empty vector", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_medicaid_expansion_status(character(0))
  ))

  expect_type(result, "character")
  expect_length(result, 0)
})

# Test 7: Error path - non-character input
test_that("medicaid_expansion_status raises error for non-character input", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_medicaid_expansion_status(12345)
    ))
  )
})

# Test 8: Error path - missing required argument
test_that("medicaid_expansion_status raises error when argument is missing", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_medicaid_expansion_status()
    ))
  )
})

# Test 9: Case insensitivity (if supported)
test_that("medicaid_expansion_status handles case variations in state names", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_medicaid_expansion_status(c("texas", "CALIFORNIA", "neW york"))
  ))

  expect_type(result, "character")
  expect_length(result, 3)
})

# Test 10: Edge case - non-expansion states documented in dataset
test_that("medicaid_expansion_status correctly identifies all non-expansion states", {
  non_expanded_states <- c("Alabama", "Florida", "Georgia", "Kansas",
                            "Mississippi", "South Carolina", "Tennessee",
                            "Texas", "Wisconsin", "Wyoming")
  result <- suppressMessages(suppressWarnings(
    mysterycall_medicaid_expansion_status(non_expanded_states)
  ))

  expect_type(result, "character")
  expect_length(result, 10)
  expect_true(all(result == "Not Expanded"))
})
