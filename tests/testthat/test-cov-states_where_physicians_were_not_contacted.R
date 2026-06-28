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


test_that("mysterycall_not_contacted_states returns character output with basic input", {
  data <- data.frame(
    state = c("California", "New York", "Texas"),
    npi = c("123", "456", "789"),
    contact_office = c(TRUE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data)
  )

  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(grepl("unique physicians", result))
  expect_true(grepl("states", result))
})


test_that("mysterycall_not_contacted_states identifies excluded states correctly", {
  data <- data.frame(
    state = c("California", "New York"),
    npi = c("111", "222"),
    contact_office = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  all_states <- c("California", "New York", "Texas", "Florida")

  result <- suppressMessages(
    mysterycall_not_contacted_states(data, all_states = all_states)
  )

  expect_true(grepl("Texas", result))
  expect_true(grepl("Florida", result))
  expect_true(grepl("excluded", result, ignore.case = TRUE))
})


test_that("mysterycall_not_contacted_states filters by contact_office logical values", {
  data <- data.frame(
    state = c("California", "California", "New York"),
    npi = c("111", "222", "333"),
    contact_office = c(TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data)
  )

  # Only 2 physicians were contacted (rows with contact_office = TRUE)
  expect_true(grepl("2 unique physicians", result))
})


test_that("mysterycall_not_contacted_states handles character contact indicators", {
  data <- data.frame(
    state = c("California", "California", "New York"),
    npi = c("111", "222", "333"),
    contact_office = c("yes", "no", "true"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data)
  )

  # Only rows with "yes" and "true" should be counted
  expect_true(grepl("2 unique physicians", result))
})


test_that("mysterycall_not_contacted_states filters by included_in_study column", {
  data <- data.frame(
    state = c("California", "New York", "Texas"),
    npi = c("111", "222", "333"),
    included_in_study = c(TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data)
  )

  # Only 2 physicians in included_in_study = TRUE rows
  expect_true(grepl("2 unique physicians", result))
})


test_that("mysterycall_not_contacted_states handles numeric contact indicators", {
  data <- data.frame(
    state = c("California", "New York", "Texas"),
    npi = c("111", "222", "333"),
    contact_office = c(1, 0, 2),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data)
  )

  # Rows with 1 and 2 (non-zero) should be counted
  expect_true(grepl("2 unique physicians", result))
})


test_that("mysterycall_not_contacted_states returns 'No states' when all states included", {
  all_states <- c("California", "New York")
  data <- data.frame(
    state = c("California", "New York"),
    npi = c("111", "222"),
    contact_office = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data, all_states = all_states)
  )

  expect_true(grepl("No states were excluded", result))
})


test_that("mysterycall_not_contacted_states uses correct physician identifier priority", {
  # Test that npi is prioritized over name
  data <- data.frame(
    state = c("California", "California"),
    npi = c("111", "111"),
    name = c("John", "Jane"),
    contact_office = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data)
  )

  # Should count unique npis (1), not unique names (2)
  expect_true(grepl("1 unique physician", result))
})


test_that("mysterycall_not_contacted_states handles zero rows", {
  data <- data.frame(
    state = character(),
    npi = character(),
    contact_office = logical(),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data)
  )

  expect_type(result, "character")
  expect_true(grepl("0 unique physicians", result))
})


test_that("mysterycall_not_contacted_states handles missing state column", {
  data <- data.frame(
    npi = c("111", "222"),
    contact_office = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data)
  )

  expect_type(result, "character")
  # Should still return string even without state column
  expect_true(grepl("unique physicians", result))
})


test_that("mysterycall_not_contacted_states handles NA values in physician identifiers", {
  data <- data.frame(
    state = c("California", "New York"),
    npi = c("111", NA),
    contact_office = c(TRUE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data)
  )

  # Only one non-NA physician should be counted
  expect_true(grepl("1 unique physician", result))
})


test_that("mysterycall_not_contacted_states uses default state list when all_states is NULL", {
  data <- data.frame(
    state = c("California"),
    npi = c("111"),
    contact_office = c(TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data, all_states = NULL)
  )

  # Should reference many excluded states using the default list (49 states excluded)
  expect_true(grepl("excluded", result, ignore.case = TRUE))
  expect_type(result, "character")
})


test_that("mysterycall_not_contacted_states handles multiple excluded states formatting", {
  all_states <- c("California", "New York", "Texas", "Florida", "Illinois")
  data <- data.frame(
    state = c("California"),
    npi = c("111"),
    contact_office = c(TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_not_contacted_states(data, all_states = all_states)
  )

  # Should format multiple excluded states with commas and "and"
  expect_true(grepl("Texas, Florida, and Illinois", result) ||
              grepl("Texas, Illinois, and Florida", result) ||
              grepl("Texas.*and.*Illinois", result))
})


test_that("mysterycall_not_contacted_states requires filtered_data to be data.frame-like", {
  # This should work fine since it's a valid data.frame
  data <- data.frame(state = c("CA"), npi = c("111"), contact_office = c(TRUE))
  result <- suppressMessages(mysterycall_not_contacted_states(data))
  expect_type(result, "character")
})
