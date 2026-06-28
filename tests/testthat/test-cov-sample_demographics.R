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

# Test 1: Happy path - basic functionality with valid data
test_that("mysterycall_sample_demographics returns list with correct structure", {
  df <- data.frame(
    id_number = paste0("P", 1:6),
    phone     = paste0("555-000", 1:6),
    state     = c("Colorado", "Texas", "Colorado", "Florida", "Texas", "Georgia"),
    insurance = c("Medicaid", "Medicaid", "Blue Cross/Blue Shield",
                  "Blue Cross/Blue Shield", "Medicaid", "Blue Cross/Blue Shield"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_sample_demographics(df, output_dir = NA))

  expect_type(result, "list")
  expect_named(result, c("unique_physicians_count", "total_calls", "count_by_insurance",
                         "included_states", "excluded_states", "num_included_states",
                         "excluded_states_series", "summary_sentence"))
  expect_equal(result$unique_physicians_count, 6L)
  expect_equal(result$total_calls, 6L)
  expect_type(result$count_by_insurance, "integer")
  expect_true(is.character(result$included_states))
  expect_true(is.character(result$excluded_states))
  expect_type(result$num_included_states, "integer")
  expect_type(result$excluded_states_series, "character")
  expect_type(result$summary_sentence, "character")
})

# Test 2: Edge case - empty dataframe
test_that("mysterycall_sample_demographics handles empty dataframe", {
  all_states_list <- c("Colorado", "Texas", "Florida")
  df <- data.frame(
    id_number = character(0),
    state     = character(0),
    insurance = character(0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_sample_demographics(
    df,
    all_states = all_states_list,
    output_dir = NA
  ))

  expect_equal(result$unique_physicians_count, 0L)
  expect_equal(result$total_calls, 0L)
  expect_length(result$count_by_insurance, 0L)
  expect_length(result$included_states, 0L)
  expect_equal(result$num_included_states, 0L)
})

# Test 3: Edge case - all states represented (no excluded states)
test_that("mysterycall_sample_demographics with no excluded states", {
  all_states_list <- c("Colorado", "Texas", "Florida")
  df <- data.frame(
    id_number = paste0("P", 1:3),
    phone     = paste0("555-000", 1:3),
    state     = c("Colorado", "Texas", "Florida"),
    insurance = c("Medicaid", "Medicaid", "Medicaid"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_sample_demographics(
    df,
    all_states = all_states_list,
    output_dir = NA
  ))

  expect_equal(result$num_included_states, 3L)
  expect_equal(result$excluded_states_series, "No states were excluded.")
  expect_length(result$excluded_states, 0L)
})

# Test 4: Edge case - NA values in state column are omitted
test_that("mysterycall_sample_demographics handles NA in state column", {
  df <- data.frame(
    id_number = paste0("P", 1:5),
    phone     = paste0("555-000", 1:5),
    state     = c("Colorado", "Texas", NA, "Florida", "Colorado"),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid", "Medicaid"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_sample_demographics(df, output_dir = NA))

  expect_equal(result$unique_physicians_count, 5L)
  expect_equal(length(result$included_states), 3L)
  expect_false(NA %in% result$included_states)
})

# Test 5: Bad input - missing required column throws error
test_that("mysterycall_sample_demographics errors on missing required column", {
  df <- data.frame(
    id_number = paste0("P", 1:3),
    insurance = c("Medicaid", "Medicaid", "Medicaid"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_sample_demographics(df, state_col = "state", output_dir = NA)
  )
})

# Test 6: phone_col not in data falls back to id_col
test_that("mysterycall_sample_demographics falls back to id_col when phone_col absent", {
  df <- data.frame(
    id_number = c("P1", "P2", "P3", "P1"),
    state     = c("Colorado", "Texas", "Colorado", "Colorado"),
    insurance = c("Medicaid", "Medicaid", "Medicaid", "Medicaid"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_sample_demographics(
    df,
    phone_col = "phone",
    output_dir = NA
  ))

  expect_equal(result$unique_physicians_count, 4L)
  expect_equal(as.integer(result$count_by_insurance[1]), 3L)
})

# Test 7: Custom column names work correctly
test_that("mysterycall_sample_demographics works with custom column names", {
  df <- data.frame(
    custom_id = paste0("P", 1:3),
    custom_state = c("Colorado", "Texas", "Florida"),
    custom_insurance = c("Medicaid", "BCBS", "Medicaid"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_sample_demographics(
    df,
    id_col = "custom_id",
    state_col = "custom_state",
    insurance_col = "custom_insurance",
    output_dir = NA
  ))

  expect_equal(result$unique_physicians_count, 3L)
  expect_true("Colorado" %in% result$included_states)
  expect_true("Texas" %in% result$included_states)
  expect_true("Florida" %in% result$included_states)
})

# Test 8: Excluded states series formats correctly for multiple states
test_that("mysterycall_sample_demographics formats excluded_states_series correctly", {
  all_states_list <- c("Colorado", "Texas", "Florida", "Georgia", "Alaska")
  df <- data.frame(
    id_number = paste0("P", 1:2),
    state     = c("Colorado", "Texas"),
    insurance = c("Medicaid", "Medicaid"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_sample_demographics(
    df,
    all_states = all_states_list,
    output_dir = NA
  ))

  # Should have "Florida, Georgia and Alaska"
  expect_true(grepl("and", result$excluded_states_series))
  expect_true(grepl("Florida", result$excluded_states_series))
})

# Test 9: count_by_insurance groups correctly by phone when present
test_that("mysterycall_sample_demographics uses phone_col for distinct physician count", {
  df <- data.frame(
    id_number = c("P1", "P1", "P2", "P3"),
    phone     = c("555-0001", "555-0001", "555-0002", "555-0003"),
    state     = c("Colorado", "Colorado", "Texas", "Colorado"),
    insurance = c("Medicaid", "Medicaid", "BCBS", "Medicaid"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_sample_demographics(
    df,
    phone_col = "phone",
    output_dir = NA
  ))

  # Should count 3 unique phones total
  expect_equal(sum(result$count_by_insurance), 3L)
})

# Test 10: Bad input - wrong data type
test_that("mysterycall_sample_demographics errors on non-data.frame input", {
  expect_error(
    suppressMessages(mysterycall_sample_demographics(
      list(id_number = c("P1", "P2"), state = c("CO", "TX"), insurance = c("Medicaid", "BCBS")),
      output_dir = NA
    ))
  )
})
