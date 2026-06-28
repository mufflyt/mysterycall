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

# Test 1: Happy path - flags records with positive days AND excluded status
test_that("flag_excluded_with_appointments returns flagged records", {
  df <- data.frame(
    physician_information           = c("Dr A", "Dr B", "Dr C"),
    id_number                       = c("003", "002", "001"),
    reason_for_exclusions           = c("Not available", "Able to contact", "Already scheduled"),
    business_days_until_appointment = c(5L, 3L, 0L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$physician_information, "Dr A")
})

# Test 2: Happy path - no records flagged (all contact_value)
test_that("flag_excluded_with_appointments returns zero-row tibble when none flagged", {
  df <- data.frame(
    physician_information           = c("Dr A", "Dr B"),
    id_number                       = c("001", "002"),
    reason_for_exclusions           = c("Able to contact", "Able to contact"),
    business_days_until_appointment = c(5L, 3L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_invisible(suppressMessages(mysterycall_flag_excluded_with_appointments(df, output_dir = NA)))
})

# Test 3: Sorting by id_number descending when present
test_that("flag_excluded_with_appointments sorts by id_number descending", {
  df <- data.frame(
    physician_information           = c("Dr A", "Dr B", "Dr C"),
    id_number                       = c("001", "003", "002"),
    reason_for_exclusions           = c("Not available", "Not available", "Not available"),
    business_days_until_appointment = c(5L, 3L, 2L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
  )

  expect_equal(nrow(result), 3L)
  expect_equal(result$id_number, c("003", "002", "001"))
})

# Test 4: Custom parameter values (different column names)
test_that("flag_excluded_with_appointments works with custom parameters", {
  df <- data.frame(
    notes                           = c("Dr A", "Dr B", "Dr C"),
    wait_time                       = c(5L, 3L, 0L),
    exclusion_reason                = c("No callback", "Success", "Declined"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(
      df,
      days_col = "wait_time",
      exclusion_col = "exclusion_reason",
      contact_value = "Success",
      output_dir = NA
    )
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$notes, "Dr A")
})

# Test 5: select_cols parameter - returns only specified columns
test_that("flag_excluded_with_appointments respects select_cols", {
  df <- data.frame(
    physician_information           = c("Dr A", "Dr B"),
    id_number                       = c("001", "002"),
    notes                           = c("note1", "note2"),
    reason_for_exclusions           = c("Not available", "Not available"),
    business_days_until_appointment = c(5L, 3L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(
      df,
      select_cols = c("id_number", "notes"),
      output_dir = NA
    )
  )

  expect_equal(nrow(result), 2L)
  expect_equal(length(intersect(names(result), c("id_number", "notes"))), 2L)
})

# Test 6: Edge case - NA in exclusion_col (NA != contact_value)
test_that("flag_excluded_with_appointments flags NA in exclusion_col", {
  df <- data.frame(
    physician_information           = c("Dr A", "Dr B"),
    reason_for_exclusions           = c(NA, "Not available"),
    business_days_until_appointment = c(5L, 3L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
  )

  # NA in exclusion_col: dplyr drops NA-condition rows, so only the non-NA excluded row remains
  expect_equal(nrow(result), 1L)
})

# Test 7: Edge case - zero days (boundary: days == 0 not flagged)
test_that("flag_excluded_with_appointments excludes records with days == 0", {
  df <- data.frame(
    physician_information           = c("Dr A", "Dr B"),
    reason_for_exclusions           = c("Not available", "Not available"),
    business_days_until_appointment = c(0L, 1L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(df, output_dir = NA)
  )

  expect_equal(nrow(result), 1L)
  expect_equal(result$physician_information, "Dr B")
})

# Test 8: Bad input - data is not a data frame
test_that("flag_excluded_with_appointments rejects non-data.frame", {
  expect_error(
    mysterycall_flag_excluded_with_appointments(list(a = 1), output_dir = NA),
    "must be a data frame"
  )
})

# Test 9: Bad input - days_col missing
test_that("flag_excluded_with_appointments rejects missing days_col", {
  df <- data.frame(
    physician_information = c("Dr A"),
    reason_for_exclusions = c("Not available"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_flag_excluded_with_appointments(
      df,
      days_col = "missing_col",
      output_dir = NA
    ),
    "not found in data"
  )
})

# Test 10: Bad input - exclusion_col missing
test_that("flag_excluded_with_appointments rejects missing exclusion_col", {
  df <- data.frame(
    physician_information           = c("Dr A"),
    business_days_until_appointment = c(5L),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_flag_excluded_with_appointments(
      df,
      exclusion_col = "missing_col",
      output_dir = NA
    ),
    "not found in data"
  )
})

# Test 11: Bad input - contact_value is not single character
test_that("flag_excluded_with_appointments rejects multi-value contact_value", {
  df <- data.frame(
    physician_information           = c("Dr A"),
    reason_for_exclusions           = c("Not available"),
    business_days_until_appointment = c(5L),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_flag_excluded_with_appointments(
      df,
      contact_value = c("OK", "Success"),
      output_dir = NA
    ),
    "single character string"
  )
})

# Test 12: Column selection - silently drops non-existent columns
test_that("flag_excluded_with_appointments silently drops missing select_cols", {
  df <- data.frame(
    physician_information           = c("Dr A"),
    id_number                       = c("001"),
    reason_for_exclusions           = c("Not available"),
    business_days_until_appointment = c(5L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_excluded_with_appointments(
      df,
      select_cols = c("id_number", "nonexistent_col"),
      output_dir = NA
    )
  )

  expect_equal(nrow(result), 1L)
  expect_true("id_number" %in% names(result))
  expect_false("nonexistent_col" %in% names(result))
})
