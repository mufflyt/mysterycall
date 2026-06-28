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

# Test 1: Happy path - valid state names with ACOG system
test_that("mysterycall_assign_region maps valid state names to ACOG districts", {
  states <- c("Colorado", "Texas", "New York", "California")
  result <- mysterycall_assign_region(states, system = "acog")

  expect_type(result, "character")
  expect_length(result, 4L)
  expect_equal(result[1], "District VIII")
  expect_equal(result[2], "District XI")
  expect_equal(result[3], "District II")
  expect_equal(result[4], "District IX")
})

# Test 2: All three classification systems work correctly
test_that("mysterycall_assign_region supports acog, aao_hns, and census systems", {
  state <- "California"

  acog_result <- mysterycall_assign_region(state, system = "acog")
  aao_hns_result <- mysterycall_assign_region(state, system = "aao_hns")
  census_result <- mysterycall_assign_region(state, system = "census")

  expect_equal(acog_result, "District IX")
  expect_equal(aao_hns_result, "District 8")
  expect_equal(census_result, "West")
})

# Test 3: Two-letter state abbreviations are expanded correctly
test_that("mysterycall_assign_region expands state abbreviations (e.g., CO, TX, NY)", {
  states <- c("CO", "TX", "CA", "NY", "FL")
  result <- mysterycall_assign_region(states, system = "acog")

  expect_length(result, 5L)
  expect_equal(result[1], "District VIII")  # CO = Colorado
  expect_equal(result[2], "District XI")    # TX = Texas
  expect_equal(result[3], "District IX")    # CA = California
  expect_equal(result[4], "District II")    # NY = New York
  expect_equal(result[5], "District XII")   # FL = Florida
})

# Test 4: Edge cases with NA values, mixed case, and unrecognized states
test_that("mysterycall_assign_region handles NA, case-insensitivity, and unknown states", {
  states <- c("colorado", "TEXAS", "new york", NA, "InvalidState")
  result <- mysterycall_assign_region(states, system = "acog", na_label = "Unknown")

  expect_length(result, 5L)
  expect_equal(result[1], "District VIII")
  expect_equal(result[2], "District XI")
  expect_equal(result[3], "District II")
  expect_equal(result[4], "Unknown")       # NA input
  expect_equal(result[5], "Unknown")       # Unrecognized state
})

# Test 5: Custom na_label and factor input support
test_that("mysterycall_assign_region accepts custom na_label and factor input", {
  # Test custom na_label
  states <- c("California", NA)
  result <- mysterycall_assign_region(states, system = "census", na_label = "MissingData")
  expect_equal(result[2], "MissingData")

  # Test factor input (should be converted to character)
  state_factor <- factor(c("Texas", "Colorado"))
  result_from_factor <- mysterycall_assign_region(state_factor, system = "acog")
  expect_type(result_from_factor, "character")
  expect_equal(result_from_factor[1], "District XI")
  expect_equal(result_from_factor[2], "District VIII")
})

# Test 6: Error handling for invalid inputs
test_that("mysterycall_assign_region rejects invalid types and parameters", {
  # Non-character/non-factor state input
  expect_error(
    mysterycall_assign_region(c(123, 456), system = "acog"),
    "`state` must be a character vector or factor"
  )

  # Invalid system argument
  expect_error(
    mysterycall_assign_region("CA", system = "invalid_system"),
    "should be one of"
  )

  # Invalid na_label (not a single string)
  expect_error(
    mysterycall_assign_region("CA", na_label = c("A", "B")),
    "`na_label` must be a single character string"
  )

  # Invalid na_label (numeric)
  expect_error(
    mysterycall_assign_region("CA", na_label = 123),
    "`na_label` must be a single character string"
  )
})

# Test 7: Mixed format input (abbreviations and full names)
test_that("mysterycall_assign_region handles mixed abbreviation and full-name input", {
  states <- c("CO", "Texas", "ca", "NEW YORK")
  result <- mysterycall_assign_region(states, system = "aao_hns")

  expect_length(result, 4L)
  expect_equal(result[1], "District 7")   # CO = Colorado
  expect_equal(result[2], "District 6")   # Texas
  expect_equal(result[3], "District 8")   # ca = California
  expect_equal(result[4], "District 2")   # NEW YORK = New York
})
