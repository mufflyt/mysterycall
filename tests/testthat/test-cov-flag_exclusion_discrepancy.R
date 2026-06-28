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

# ------- Test 1: Happy path with discrepancies detected -------
test_that("flag_exclusion_discrepancy detects records with exclusions and wait times", {
  df <- data.frame(
    physician_information          = c("Dr A", "Dr B", "Dr C", "Dr D"),
    id_number                      = c("001", "002", "003", "004"),
    reason_for_exclusions          = c("Physician not available",
                                       "Able to contact",
                                       "Number disconnected",
                                       "Able to contact"),
    business_days_until_appointment = c(5, 3, 0, 7),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, output_dir = NA)
  )

  # Should return a data frame/tibble with 2 rows (Dr A and Dr C)
  expect_true(is.data.frame(result) || tibble::is_tibble(result))
  expect_equal(nrow(result), 2L)
  expect_true(all(result$reason_for_exclusions != "Able to contact"))
  expect_true(all(result$business_days_until_appointment >= 0))
})

# ------- Test 2: No discrepancies found (empty result) -------
test_that("flag_exclusion_discrepancy returns empty tibble when no discrepancies exist", {
  df <- data.frame(
    physician_information          = c("Dr A", "Dr B", "Dr C"),
    id_number                      = c("001", "002", "003"),
    reason_for_exclusions          = c("Able to contact", "Able to contact", "Able to contact"),
    business_days_until_appointment = c(5, 3, 2),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, output_dir = NA)
  )

  # Should return an invisible empty tibble
  expect_true(is.data.frame(result) || tibble::is_tibble(result))
  expect_equal(nrow(result), 0L)
})

# ------- Test 3: Missing required column raises error -------
test_that("flag_exclusion_discrepancy errors when required column is missing", {
  df <- data.frame(
    physician_information = c("Dr A", "Dr B"),
    id_number             = c("001", "002"),
    reason_for_exclusions = c("Excluded", "Able to contact"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_flag_exclusion_discrepancy(df, output_dir = NA),
    "business_days_until_appointment"
  )
})

# ------- Test 4: Empty data frame input -------
test_that("flag_exclusion_discrepancy handles empty input gracefully", {
  df <- data.frame(
    physician_information          = character(0),
    reason_for_exclusions          = character(0),
    business_days_until_appointment = integer(0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, output_dir = NA)
  )

  expect_equal(nrow(result), 0L)
  expect_true(is.data.frame(result) || tibble::is_tibble(result))
})

# ------- Test 5: Custom column names and contact_value -------
test_that("flag_exclusion_discrepancy respects custom parameter names", {
  df <- data.frame(
    physician                = c("Dr A", "Dr B", "Dr C"),
    record_id                = c("001", "002", "003"),
    exclusion_reason         = c("Excluded", "Success", "Excluded"),
    days_to_appointment      = c(5, 3, 0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(
      df,
      days_col       = "days_to_appointment",
      exclusion_col  = "exclusion_reason",
      contact_value  = "Success",
      select_cols    = c("physician", "record_id", "exclusion_reason", "days_to_appointment"),
      output_dir     = NA
    )
  )

  expect_equal(nrow(result), 2L)
  expect_true(all(result$exclusion_reason != "Success"))
})

# ------- Test 6: min_days parameter threshold -------
test_that("flag_exclusion_discrepancy respects min_days threshold", {
  df <- data.frame(
    physician_information          = c("Dr A", "Dr B", "Dr C", "Dr D"),
    id_number                      = c("001", "002", "003", "004"),
    reason_for_exclusions          = c("Excluded", "Excluded", "Excluded", "Able to contact"),
    business_days_until_appointment = c(0, 1, 5, 10),
    stringsAsFactors = FALSE
  )

  # With min_days = 0 (default), all excluded records with days >= 0 flagged
  result_0 <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, min_days = 0, output_dir = NA)
  )
  expect_equal(nrow(result_0), 3L)

  # With min_days = 2, only records with days >= 2 flagged
  result_2 <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, min_days = 2, output_dir = NA)
  )
  expect_equal(nrow(result_2), 1L)
  expect_equal(result_2$business_days_until_appointment, 5)
})

# ------- Test 7: id_number sorting (descending) -------
test_that("flag_exclusion_discrepancy sorts by id_number descending when present", {
  df <- data.frame(
    physician_information          = c("Dr A", "Dr B", "Dr C", "Dr D"),
    id_number                      = c("005", "003", "002", "001"),
    reason_for_exclusions          = c("Excluded", "Excluded", "Able to contact", "Excluded"),
    business_days_until_appointment = c(1, 2, 3, 4),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, output_dir = NA)
  )

  # Expect 3 flagged records (Dr A, B, D), sorted descending by id_number: 005, 003, 001
  expect_equal(nrow(result), 3L)
  expect_equal(result$id_number, c("005", "003", "001"))
})

# ------- Test 8: Column selection behavior -------
test_that("flag_exclusion_discrepancy selects only requested columns", {
  df <- data.frame(
    physician_information          = c("Dr A", "Dr B"),
    id_number                      = c("001", "002"),
    notes                          = c("Note 1", "Note 2"),
    reason_for_exclusions          = c("Excluded", "Able to contact"),
    business_days_until_appointment = c(5, 3),
    extra_field                    = c("Extra1", "Extra2"),
    stringsAsFactors = FALSE
  )

  # Use default select_cols
  result <- suppressMessages(
    mysterycall_flag_exclusion_discrepancy(df, output_dir = NA)
  )

  # Should only have the default columns that exist in the data
  default_cols <- c("physician_information", "id_number", "notes",
                    "reason_for_exclusions", "business_days_until_appointment")
  existing_cols <- intersect(default_cols, names(df))
  expect_equal(names(result), existing_cols)
})

# ------- Test 9: Bad input - non-data-frame -------
test_that("flag_exclusion_discrepancy errors on non-data-frame input", {
  expect_error(
    mysterycall_flag_exclusion_discrepancy(list(x = 1:5), output_dir = NA),
    "data"
  )
})

# ------- Test 10: Bad input - min_days wrong type -------
test_that("flag_exclusion_discrepancy errors when min_days is not numeric", {
  df <- data.frame(
    reason_for_exclusions          = c("Excluded"),
    business_days_until_appointment = c(5),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_flag_exclusion_discrepancy(df, min_days = "zero", output_dir = NA),
    "min_days"
  )
})
