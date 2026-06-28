library(testthat)
library(mysterycall)

# Tests for the acgme dataset and ACGME_PROGRAM_INDICATORS exported object

test_that("acgme dataset loads and has expected structure", {
  data(acgme, package = "mysterycall", envir = environment())
  expect_s3_class(acgme, "data.frame")
  expect_equal(nrow(acgme), 318L)
  expect_equal(ncol(acgme), 142L)
  required_cols <- c(
    "program_name", "address", "zip", "city", "state",
    "phone", "accreditation_status", "program_code",
    "sponsoring_institution_name"
  )
  expect_true(all(required_cols %in% names(acgme)),
    info = paste("Missing columns:", paste(setdiff(required_cols, names(acgme)), collapse = ", "))
  )
})

test_that("acgme key columns are non-empty character vectors", {
  data(acgme, package = "mysterycall", envir = environment())
  expect_true(is.character(acgme$program_name) || is.factor(acgme$program_name))
  expect_equal(sum(is.na(acgme$program_name)), 0L,
    info = "program_name should have no NAs"
  )
  expect_equal(sum(is.na(acgme$program_code)), 0L,
    info = "program_code should have no NAs"
  )
  expect_true(all(nchar(trimws(acgme$program_name)) > 0),
    info = "program_name values should not be blank"
  )
})

test_that("acgme state column contains valid US state names", {
  data(acgme, package = "mysterycall", envir = environment())
  states_present <- unique(acgme$state)
  expect_true(length(states_present) >= 40L,
    info = "Expected programs across at least 40 states"
  )
  # All state values should be non-NA non-empty strings
  expect_false(any(is.na(acgme$state)))
  expect_false(any(nchar(trimws(acgme$state)) == 0))
})

test_that("ACGME_PROGRAM_INDICATORS is a non-empty character vector with expected entries", {
  expect_type(ACGME_PROGRAM_INDICATORS, "character")
  expect_true(length(ACGME_PROGRAM_INDICATORS) >= 1L)
  expect_true("RESIDENCY PROGRAM" %in% ACGME_PROGRAM_INDICATORS)
  expect_true("FELLOWSHIP PROGRAM" %in% ACGME_PROGRAM_INDICATORS)
  expect_false(any(is.na(ACGME_PROGRAM_INDICATORS)))
  expect_false(any(nchar(trimws(ACGME_PROGRAM_INDICATORS)) == 0))
})

test_that("acgme accreditation_status column contains only known status values", {
  data(acgme, package = "mysterycall", envir = environment())
  known_statuses <- c(
    "Continued Accreditation",
    "Initial Accreditation",
    "Accreditation Withdrawn",
    "Continued Accreditation with Warning",
    "Voluntary Withdrawal",
    "Continued Accreditation without Outcomes",
    "Initial Accreditation with Warning",
    "Probationary Accreditation",
    "Expedited Withdrawal"
  )
  unexpected <- setdiff(unique(acgme$accreditation_status), known_statuses)
  expect_equal(length(unexpected), 0L,
    info = paste("Unexpected accreditation_status values:", paste(unexpected, collapse = ", "))
  )
})
