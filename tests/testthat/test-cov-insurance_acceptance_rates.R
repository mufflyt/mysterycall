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

# ============================================================================
# Test 1: Happy Path - Basic function call with valid data and defaults
# ============================================================================
test_that("mysterycall_insurance_acceptance_rates returns correct structure with valid data", {
  df <- data.frame(
    phone                           = c("555-0001", "555-0001", "555-0002", "555-0002", "555-0003", "555-0003"),
    insurance                       = c("Medicaid", "Medicaid", "Blue Cross/Blue Shield", "Blue Cross/Blue Shield", "Medicaid", "Medicaid"),
    reason_for_exclusions           = c("Able to contact", "Able to contact", "Able to contact", "Not available", "Able to contact", "Able to contact"),
    business_days_until_appointment = c(5L, 5L, 3L, NA, 7L, 7L),
    does_the_physician_accept_medicaid = c("Yes", "Yes", "Yes", "Yes", NA, "No"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )

  expect_type(result, "list")
  expect_length(result, 12L)
  expect_named(
    result,
    c(
      "count_accepts_medicaid", "count_medicaid_excluded", "total_count_medicaid",
      "count_medicaid_denom", "medicaid_acceptance_rate",
      "count_accepts_bcbs", "count_bcbs_excluded", "total_count_bcbs",
      "count_bcbs_denom", "bcbs_acceptance_rate",
      "paragraph", "summary_sentence"
    )
  )

  # Check return types
  expect_type(result$count_accepts_medicaid, "integer")
  expect_type(result$count_medicaid_excluded, "integer")
  expect_type(result$total_count_medicaid, "integer")
  expect_type(result$count_medicaid_denom, "integer")
  expect_type(result$medicaid_acceptance_rate, "double")
  expect_type(result$paragraph, "character")
  expect_type(result$summary_sentence, "character")

  # Check reasonableness
  expect_true(result$count_medicaid_denom >= 0)
  expect_true(result$count_accepts_medicaid >= 0)
  expect_true(result$medicaid_acceptance_rate >= 0 && result$medicaid_acceptance_rate <= 100)
})

# ============================================================================
# Test 2: Edge Case - Missing medicaid_accept_col, zero rows, NA values
# ============================================================================
test_that("mysterycall_insurance_acceptance_rates handles missing medicaid_accept_col gracefully", {
  df <- data.frame(
    phone                           = c("555-0001", "555-0002"),
    insurance                       = c("Medicaid", "Blue Cross/Blue Shield"),
    reason_for_exclusions           = c("Able to contact", "Able to contact"),
    business_days_until_appointment = c(5L, 3L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )

  expect_type(result, "list")
  expect_length(result, 12L)
  expect_true(result$count_accepts_medicaid >= 0)
  expect_true(result$count_accepts_bcbs >= 0)
})

test_that("mysterycall_insurance_acceptance_rates handles zero-row data frame", {
  df <- data.frame(
    phone                           = character(),
    insurance                       = character(),
    reason_for_exclusions           = character(),
    business_days_until_appointment = integer(),
    does_the_physician_accept_medicaid = character(),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )

  expect_type(result, "list")
  expect_equal(result$count_accepts_medicaid, 0L)
  expect_equal(result$total_count_medicaid, 0L)
  expect_equal(result$count_accepts_bcbs, 0L)
  expect_equal(result$total_count_bcbs, 0L)
})

test_that("mysterycall_insurance_acceptance_rates handles all-NA days column", {
  df <- data.frame(
    phone                           = c("555-0001", "555-0002"),
    insurance                       = c("Medicaid", "Blue Cross/Blue Shield"),
    reason_for_exclusions           = c("Able to contact", "Able to contact"),
    business_days_until_appointment = c(NA_integer_, NA_integer_),
    does_the_physician_accept_medicaid = c("Yes", "Yes"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )

  expect_type(result, "list")
  # When business_days_until_appointment is NA or <=0, no acceptances counted
  expect_equal(result$count_accepts_medicaid, 0L)
  expect_equal(result$count_accepts_bcbs, 0L)
})

# ============================================================================
# Test 3: Bad Input - Missing required columns, wrong data type
# ============================================================================
test_that("mysterycall_insurance_acceptance_rates raises error for missing required column", {
  df <- data.frame(
    phone                           = c("555-0001", "555-0002"),
    insurance                       = c("Medicaid", "Blue Cross/Blue Shield"),
    reason_for_exclusions           = c("Able to contact", "Able to contact"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA),
    "must.include"
  )
})

test_that("mysterycall_insurance_acceptance_rates raises error for non-data.frame input", {
  expect_error(
    mysterycall_insurance_acceptance_rates(list(a = 1), output_dir = NA),
    "data.frame"
  )
})

test_that("mysterycall_insurance_acceptance_rates raises error for non-string column name", {
  df <- data.frame(
    phone                           = c("555-0001", "555-0002"),
    insurance                       = c("Medicaid", "Blue Cross/Blue Shield"),
    reason_for_exclusions           = c("Able to contact", "Able to contact"),
    business_days_until_appointment = c(5L, 3L),
    does_the_physician_accept_medicaid = c("Yes", "Yes"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_insurance_acceptance_rates(df, insurance_col = 123, output_dir = NA),
    "string"
  )
})

# ============================================================================
# Test 4: Parameter Variation - Custom column names and labels
# ============================================================================
test_that("mysterycall_insurance_acceptance_rates works with custom column names", {
  df <- data.frame(
    phone_num                       = c("555-0001", "555-0001", "555-0002", "555-0002"),
    insur_type                      = c("Medicaid", "Medicaid", "BCBS", "BCBS"),
    excl_reason                     = c("Able to contact", "Able to contact", "Able to contact", "Not available"),
    appt_days                       = c(5L, 5L, 3L, NA),
    accepts_medicaid                = c("Yes", "Yes", "No", "No"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_insurance_acceptance_rates(
      df,
      phone_col           = "phone_num",
      insurance_col       = "insur_type",
      exclusion_col       = "excl_reason",
      days_col            = "appt_days",
      medicaid_accept_col = "accepts_medicaid",
      bcbs_label          = "BCBS",
      output_dir          = NA
    )
  )

  expect_type(result, "list")
  expect_length(result, 12L)
  expect_true(result$total_count_medicaid >= 0)
  expect_true(result$total_count_bcbs >= 0)
})

test_that("mysterycall_insurance_acceptance_rates works with custom insurance labels", {
  df <- data.frame(
    phone                           = c("555-0001", "555-0001", "555-0002", "555-0002"),
    insurance                       = c("Medicaid", "Medicaid", "Private", "Private"),
    reason_for_exclusions           = c("Able to contact", "Able to contact", "Able to contact", "Able to contact"),
    business_days_until_appointment = c(5L, 5L, 3L, 7L),
    does_the_physician_accept_medicaid = c("Yes", "Yes", "No", "No"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_insurance_acceptance_rates(
      df,
      medicaid_label = "Medicaid",
      bcbs_label     = "Private",
      output_dir     = NA
    )
  )

  expect_type(result, "list")
  expect_named(result, c(
    "count_accepts_medicaid", "count_medicaid_excluded", "total_count_medicaid",
    "count_medicaid_denom", "medicaid_acceptance_rate",
    "count_accepts_bcbs", "count_bcbs_excluded", "total_count_bcbs",
    "count_bcbs_denom", "bcbs_acceptance_rate",
    "paragraph", "summary_sentence"
  ))
})

# ============================================================================
# Test 5: Digits Parameter and Output File Handling
# ============================================================================
test_that("mysterycall_insurance_acceptance_rates respects digits parameter", {
  df <- data.frame(
    phone                           = c("555-0001", "555-0002", "555-0003"),
    insurance                       = c("Medicaid", "Blue Cross/Blue Shield", "Medicaid"),
    reason_for_exclusions           = c("Able to contact", "Able to contact", "Able to contact"),
    business_days_until_appointment = c(5L, 3L, 7L),
    does_the_physician_accept_medicaid = c("Yes", "Yes", "Yes"),
    stringsAsFactors = FALSE
  )

  result_1 <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, digits = 1L, output_dir = NA)
  )
  result_3 <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, digits = 3L, output_dir = NA)
  )

  # Both should be valid numbers but may differ in formatting
  expect_type(result_1$medicaid_acceptance_rate, "double")
  expect_type(result_3$medicaid_acceptance_rate, "double")
  expect_true(result_1$medicaid_acceptance_rate >= 0)
  expect_true(result_3$medicaid_acceptance_rate >= 0)
})

test_that("mysterycall_insurance_acceptance_rates skips file writing with output_dir = NA", {
  df <- data.frame(
    phone                           = c("555-0001", "555-0002"),
    insurance                       = c("Medicaid", "Blue Cross/Blue Shield"),
    reason_for_exclusions           = c("Able to contact", "Able to contact"),
    business_days_until_appointment = c(5L, 3L),
    does_the_physician_accept_medicaid = c("Yes", "Yes"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )

  expect_type(result, "list")
  # No error should occur, function completes successfully
  expect_true(length(result) == 12L)
})

test_that("mysterycall_insurance_acceptance_rates output contains meaningful sentences", {
  df <- data.frame(
    phone                           = c("555-0001", "555-0002", "555-0003"),
    insurance                       = c("Medicaid", "Blue Cross/Blue Shield", "Medicaid"),
    reason_for_exclusions           = c("Able to contact", "Able to contact", "Able to contact"),
    business_days_until_appointment = c(5L, 3L, 7L),
    does_the_physician_accept_medicaid = c("Yes", "Yes", "Yes"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )

  expect_type(result$paragraph, "character")
  expect_type(result$summary_sentence, "character")
  expect_true(nchar(result$paragraph) > 0)
  expect_true(nchar(result$summary_sentence) > 0)
  expect_true(grepl("Medicaid", result$paragraph))
  expect_true(grepl("Blue Cross", result$paragraph))
  expect_true(grepl("acceptance rate", result$summary_sentence))
})

# Regression (BUG 28): BCBS acceptance must not be screened by the Medicaid-only
# accept field. When that field is NA on BCBS rows, BCBS acceptances still count.
test_that("BCBS rate ignores the Medicaid-accept NA screen", {
  df <- data.frame(
    phone = c("555-0001", "555-0002", "555-0003", "555-0004"),
    insurance = c("Blue Cross/Blue Shield", "Blue Cross/Blue Shield",
                  "Medicaid", "Medicaid"),
    reason_for_exclusions = rep("Able to contact", 4),
    business_days_until_appointment = c(5L, 8L, 6L, 4L),
    # Medicaid-only field is NA on BCBS rows (as expected in real data)
    does_the_physician_accept_medicaid = c(NA, NA, "Yes", "Yes"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_insurance_acceptance_rates(df, output_dir = NA)
  )

  # Both BCBS physicians were reachable with an appointment -> 2 accepts, 100%.
  expect_equal(result$count_accepts_bcbs, 2L)
  expect_equal(result$total_count_bcbs, 2L)
  expect_equal(result$bcbs_acceptance_rate, 100)
})
