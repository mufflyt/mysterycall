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

test_that("physicians_with_detail returns tibble with vector input", {
  df <- data.frame(
    id_number = c("001", "002", "003", "004"),
    physician_information = c("Dr A", "Dr B", "Dr C", "Dr D"),
    reason_for_exclusions = c("Able to contact", NA, "No appointment", "Able to contact"),
    insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
    business_days_until_appointment = c(5, NA, NA, 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = c("001", "003"), output_dir = NA)
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2L)
  expect_equal(result$id_number, c("001", "003"))
})

test_that("physicians_with_detail accepts data frame as flagged_ids", {
  df <- data.frame(
    id_number = c("001", "002", "003", "004"),
    physician_information = c("Dr A", "Dr B", "Dr C", "Dr D"),
    reason_for_exclusions = c("Able to contact", NA, "No appointment", "Able to contact"),
    insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
    business_days_until_appointment = c(5, NA, NA, 10),
    stringsAsFactors = FALSE
  )

  flagged_df <- data.frame(
    id_number = c("001", "002"),
    some_flag = c(TRUE, FALSE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = flagged_df, output_dir = NA)
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2L)
  expect_setequal(result$id_number, c("001", "002"))
})

test_that("physicians_with_detail respects select_cols parameter", {
  df <- data.frame(
    id_number = c("001", "002"),
    physician_information = c("Dr A", "Dr B"),
    reason_for_exclusions = c("Able to contact", "No appointment"),
    insurance = c("Medicaid", "BCBS"),
    business_days_until_appointment = c(5, 10),
    extra_col = c("X", "Y"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(
      df,
      flagged_ids = c("001", "002"),
      select_cols = c("id_number", "physician_information", "insurance"),
      output_dir = NA
    )
  )

  expect_true(all(c("id_number", "physician_information", "insurance") %in% names(result)))
  expect_false("extra_col" %in% names(result))
})

test_that("physicians_with_detail returns zero-row tibble with no matches", {
  df <- data.frame(
    id_number = c("001", "002", "003"),
    physician_information = c("Dr A", "Dr B", "Dr C"),
    reason_for_exclusions = c("Able to contact", "No appointment", "Able to contact"),
    insurance = c("Medicaid", "BCBS", "Medicaid"),
    business_days_until_appointment = c(5, 10, 7),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = c("999", "888"), output_dir = NA)
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
  expect_true(all(c("id_number", "physician_information") %in% names(result)))
})

test_that("physicians_with_detail handles custom id_col", {
  df <- data.frame(
    npi = c("1234567891", "1234567892", "1234567893"),
    physician_information = c("Dr A", "Dr B", "Dr C"),
    reason_for_exclusions = c("Able to contact", "No appointment", "Able to contact"),
    insurance = c("Medicaid", "BCBS", "Medicaid"),
    business_days_until_appointment = c(5, 10, 7),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(
      df,
      flagged_ids = c("1234567891", "1234567893"),
      id_col = "npi",
      output_dir = NA
    )
  )

  expect_equal(nrow(result), 2L)
  expect_equal(result$npi, c("1234567891", "1234567893"))
})

test_that("physicians_with_detail removes duplicates from flagged_ids vector", {
  df <- data.frame(
    id_number = c("001", "002", "003"),
    physician_information = c("Dr A", "Dr B", "Dr C"),
    reason_for_exclusions = c("Able to contact", "No appointment", "Able to contact"),
    insurance = c("Medicaid", "BCBS", "Medicaid"),
    business_days_until_appointment = c(5, 10, 7),
    stringsAsFactors = FALSE
  )

  # Pass duplicate IDs
  result <- suppressMessages(
    mysterycall_physicians_with_detail(
      df,
      flagged_ids = c("001", "001", "002"),
      output_dir = NA
    )
  )

  expect_equal(nrow(result), 2L)
  expect_equal(result$id_number, c("001", "002"))
})

test_that("physicians_with_detail arranges by id_col", {
  df <- data.frame(
    id_number = c("001", "003", "002"),
    physician_information = c("Dr A", "Dr C", "Dr B"),
    reason_for_exclusions = c("Able to contact", "No appointment", "Able to contact"),
    insurance = c("Medicaid", "BCBS", "Medicaid"),
    business_days_until_appointment = c(5, 10, 7),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(
      df,
      flagged_ids = c("003", "001", "002"),
      output_dir = NA
    )
  )

  expect_equal(result$id_number, c("001", "002", "003"))
})

test_that("physicians_with_detail handles numeric ID columns", {
  df <- data.frame(
    id_number = c(1L, 2L, 3L),
    physician_information = c("Dr A", "Dr B", "Dr C"),
    reason_for_exclusions = c("Able to contact", "No appointment", "Able to contact"),
    insurance = c("Medicaid", "BCBS", "Medicaid"),
    business_days_until_appointment = c(5, 10, 7),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(
      df,
      flagged_ids = c(1, 3),
      output_dir = NA
    )
  )

  expect_equal(nrow(result), 2L)
  expect_equal(result$id_number, c(1L, 3L))
})

test_that("physicians_with_detail handles factor input for flagged_ids", {
  df <- data.frame(
    id_number = c("001", "002", "003"),
    physician_information = c("Dr A", "Dr B", "Dr C"),
    reason_for_exclusions = c("Able to contact", "No appointment", "Able to contact"),
    insurance = c("Medicaid", "BCBS", "Medicaid"),
    business_days_until_appointment = c(5, 10, 7),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(
      df,
      flagged_ids = factor(c("001", "003")),
      output_dir = NA
    )
  )

  expect_equal(nrow(result), 2L)
  expect_equal(result$id_number, c("001", "003"))
})

test_that("physicians_with_detail throws error for non-existent id_col", {
  df <- data.frame(
    id_number = c("001", "002"),
    physician_information = c("Dr A", "Dr B"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_physicians_with_detail(df, flagged_ids = "001", id_col = "missing_col", output_dir = NA)
    ),
    regexp = "must.include"
  )
})

test_that("physicians_with_detail throws error for non-data-frame input", {
  expect_error(
    mysterycall_physicians_with_detail(
      list(a = 1, b = 2),
      flagged_ids = "001",
      output_dir = NA
    )
  )
})

test_that("physicians_with_detail throws error for invalid flagged_ids type", {
  df <- data.frame(
    id_number = c("001", "002"),
    physician_information = c("Dr A", "Dr B"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_physicians_with_detail(df, flagged_ids = new.env(), output_dir = NA)
    ),
    regexp = "must be a vector or data frame"
  )
})

test_that("physicians_with_detail handles empty data frame", {
  df <- data.frame(
    id_number = character(0),
    physician_information = character(0),
    reason_for_exclusions = character(0),
    insurance = character(0),
    business_days_until_appointment = integer(0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = "001", output_dir = NA)
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
})

test_that("physicians_with_detail preserves all rows when flagged_ids includes all IDs", {
  df <- data.frame(
    id_number = c("001", "002", "003"),
    physician_information = c("Dr A", "Dr B", "Dr C"),
    reason_for_exclusions = c("Able to contact", "No appointment", "Able to contact"),
    insurance = c("Medicaid", "BCBS", "Medicaid"),
    business_days_until_appointment = c(5, 10, 7),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = c("001", "002", "003"), output_dir = NA)
  )

  expect_equal(nrow(result), 3L)
  expect_equal(result$id_number, c("001", "002", "003"))
})

test_that("physicians_with_detail keeps only columns in select_cols that exist in data", {
  df <- data.frame(
    id_number = c("001", "002"),
    physician_information = c("Dr A", "Dr B"),
    extra_col = c("X", "Y"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_physicians_with_detail(
      df,
      flagged_ids = "001",
      select_cols = c("id_number", "physician_information", "missing_col"),
      output_dir = NA
    )
  )

  expect_true("id_number" %in% names(result))
  expect_true("physician_information" %in% names(result))
  expect_false("missing_col" %in% names(result))
  expect_false("extra_col" %in% names(result))
})
