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

test_that("mysterycall_flag_included_na_appointments: happy path with flagged records", {
  df <- data.frame(
    physician_information           = c("Dr A", "Dr B", "Dr C", "Dr D"),
    id_number                       = c("001", "002", "003", "004"),
    reason_for_exclusions           = c("Able to contact", "Able to contact", "Not available", "Able to contact"),
    business_days_until_appointment = c(NA, NA, NA, 7L),
    notes                           = c("gap", "gap2", "excluded", "ok"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_flag_included_na_appointments(df, output_dir = NA))

  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(result), 2L)
  expect_true("physician_information" %in% names(result))
  expect_true(all(result$reason_for_exclusions == "Able to contact"))
  expect_true(all(is.na(result$business_days_until_appointment)))
})

test_that("mysterycall_flag_included_na_appointments: no records flagged (all have wait times)", {
  df <- data.frame(
    physician_information           = c("Dr A", "Dr B", "Dr C"),
    id_number                       = c("001", "002", "003"),
    reason_for_exclusions           = c("Able to contact", "Able to contact", "Not available"),
    business_days_until_appointment = c(5L, 12L, NA),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_flag_included_na_appointments(df, output_dir = NA))

  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(result), 0L)
})

test_that("mysterycall_flag_included_na_appointments: empty input data frame", {
  df <- data.frame(
    physician_information           = character(0),
    reason_for_exclusions           = character(0),
    business_days_until_appointment = integer(0)
  )
  result <- suppressMessages(mysterycall_flag_included_na_appointments(df, output_dir = NA))

  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(result), 0L)
})

test_that("mysterycall_flag_included_na_appointments: bad input - not a data frame", {
  expect_error(
    mysterycall_flag_included_na_appointments(list(x = 1), output_dir = NA),
    "`data` must be a data frame"
  )
})

test_that("mysterycall_flag_included_na_appointments: bad input - missing required column", {
  df <- data.frame(
    reason_for_exclusions = c("Able to contact"),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_flag_included_na_appointments(df, output_dir = NA),
    "Column 'business_days_until_appointment' not found"
  )
})

test_that("mysterycall_flag_included_na_appointments: bad input - invalid contact_value", {
  df <- data.frame(
    reason_for_exclusions           = c("Able to contact"),
    business_days_until_appointment = c(NA),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_flag_included_na_appointments(df, contact_value = c("A", "B"), output_dir = NA),
    "`contact_value` must be a single character string"
  )
})

test_that("mysterycall_flag_included_na_appointments: custom column names", {
  df <- data.frame(
    physician_information = c("Dr A", "Dr B"),
    custom_days           = c(NA, 5L),
    custom_exclusion      = c("Included", "Included"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_flag_included_na_appointments(
      df,
      days_col      = "custom_days",
      exclusion_col = "custom_exclusion",
      contact_value = "Included",
      output_dir    = NA
    )
  )

  expect_equal(nrow(result), 1L)
  expect_equal(result$physician_information[1], "Dr A")
})

test_that("mysterycall_flag_included_na_appointments: select_cols parameter filters output", {
  df <- data.frame(
    physician_information           = c("Dr A", "Dr B"),
    id_number                       = c("001", "002"),
    notes                           = c("gap", "ok"),
    reason_for_exclusions           = c("Able to contact", "Able to contact"),
    business_days_until_appointment = c(NA, 5L),
    extra_col                       = c("x", "y"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_flag_included_na_appointments(
      df,
      select_cols = c("physician_information", "id_number"),
      output_dir  = NA
    )
  )

  expect_equal(nrow(result), 1L)
  expect_equal(ncol(result), 2L)
  expect_true("physician_information" %in% names(result))
  expect_true("id_number" %in% names(result))
  expect_false("extra_col" %in% names(result))
})

test_that("mysterycall_flag_included_na_appointments: id_number sorting descending", {
  df <- data.frame(
    physician_information           = c("Dr A", "Dr B", "Dr C"),
    id_number                       = c("100", "050", "200"),
    reason_for_exclusions           = c("Able to contact", "Able to contact", "Able to contact"),
    business_days_until_appointment = c(NA, NA, NA),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_flag_included_na_appointments(df, output_dir = NA))

  expect_equal(nrow(result), 3L)
  expect_equal(result$id_number, c("200", "100", "050"))
})
