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

# Test 1: Happy path — normal-ish data with valid inputs and default labels
test_that("mysterycall_check_normality returns correct structure for normal data", {
  set.seed(1)
  normal_data <- data.frame(value = rnorm(20, mean = 100, sd = 15))
  result <- suppressMessages(
    mysterycall_check_normality(normal_data, "value")
  )

  # Check return type
  expect_true(is.list(result))

  # Check key fields present
  expect_true("is_normal" %in% names(result))
  expect_true("p_value" %in% names(result))
  expect_true("w_statistic" %in% names(result))
  expect_true("is_count" %in% names(result))
  expect_true("interpretation" %in% names(result))

  # For normal data, expect mean and sd (not median/iqr)
  if (result$is_normal) {
    expect_true("mean" %in% names(result))
    expect_true("sd" %in% names(result))
    expect_false("median" %in% names(result))
    expect_false("iqr" %in% names(result))
  }

  # Interpretation should be a character string
  expect_type(result$interpretation, "character")
  expect_true(nchar(result$interpretation) > 0)
})

# Test 2: Happy path — count data detected correctly
test_that("mysterycall_check_normality detects count data and recommends Poisson", {
  set.seed(2)
  # Create clearly count data (non-normal, non-negative integers)
  count_data <- data.frame(counts = c(0L, 1L, 1L, 2L, 2L, 2L, 3L, 3L, 3L, 5L, 7L, 10L))
  result <- suppressMessages(
    mysterycall_check_normality(count_data, "counts",
                                 outcome_label = "counts",
                                 group_label = "treatment")
  )

  # Check structure
  expect_true(is.list(result))
  expect_type(result$is_count, "logical")

  # Count data should be detected
  expect_true(result$is_count)

  # If not normal, should have median/iqr
  if (!result$is_normal) {
    expect_true("median" %in% names(result))
    expect_true("iqr" %in% names(result))
  }

  # Interpretation should mention Poisson for non-normal count data
  if (!result$is_normal && result$is_count) {
    expect_match(result$interpretation, "Poisson", ignore.case = TRUE)
  }
})

# Test 3: Non-count non-normal data
test_that("mysterycall_check_normality handles non-count continuous data", {
  set.seed(3)
  # Create non-normal but non-integer data
  continuous_data <- data.frame(values = c(0.5, 1.2, 1.8, 2.1, 3.5, 5.2, 8.1, 13.0, 21.3, 34.4))
  result <- suppressMessages(
    mysterycall_check_normality(continuous_data, "values")
  )

  # Should not be detected as count data (has decimals)
  expect_false(result$is_count)

  # Should have proper fields
  expect_type(result$p_value, "double")
  expect_type(result$w_statistic, "double")
  expect_type(result$interpretation, "character")
})

# Test 4: Edge case — minimum sample size (n=3)
test_that("mysterycall_check_normality works with minimum sample size n=3", {
  set.seed(4)
  minimal_data <- data.frame(value = c(1L, 2L, 3L))
  result <- suppressMessages(
    mysterycall_check_normality(minimal_data, "value")
  )

  # Should return valid result
  expect_true(is.list(result))
  expect_true("p_value" %in% names(result))
  expect_true(!is.na(result$p_value))
})

# Test 5: Edge case — data with NA values
test_that("mysterycall_check_normality handles NA values correctly", {
  set.seed(5)
  data_with_na <- data.frame(
    value = c(1L, 2L, 3L, 4L, 5L, NA, 6L, 7L, 8L, 9L)
  )
  result <- suppressMessages(
    mysterycall_check_normality(data_with_na, "value")
  )

  # Should return valid result after removing NAs
  expect_true(is.list(result))
  expect_type(result$p_value, "double")
  expect_true(!is.na(result$p_value))
})

# Test 6: Bad input — variable not in data frame
test_that("mysterycall_check_normality errors when variable not found", {
  expect_error(
    mysterycall_check_normality(AUDIT, "nonexistent_variable")
  )
})

# Test 7: Bad input — sample size too small (n < 3)
test_that("mysterycall_check_normality errors when sample size < 3", {
  tiny_data <- data.frame(value = c(1L, 2L))
  expect_error(
    suppressMessages(mysterycall_check_normality(tiny_data, "value")),
    "Sample size must be at least 3"
  )
})

# Test 8: Bad input — sample size too large (n > 5000)
test_that("mysterycall_check_normality errors when sample size > 5000", {
  set.seed(8)
  huge_data <- data.frame(value = rnorm(5001))
  expect_error(
    suppressMessages(mysterycall_check_normality(huge_data, "value")),
    "Sample size must be no more than 5000"
  )
})

# Test 9: Custom labels in interpretation
test_that("mysterycall_check_normality includes custom labels in interpretation", {
  set.seed(9)
  # Use highly skewed count data to ensure non-normality
  count_data <- data.frame(appointments = c(0L, 0L, 0L, 0L, 1L, 1L, 2L, 5L, 15L, 50L))
  result <- suppressMessages(
    mysterycall_check_normality(count_data, "appointments",
                                 outcome_label = "appointment delays",
                                 group_label = "clinic location")
  )

  # Interpretation should include the outcome label at minimum
  expect_match(result$interpretation, "appointment delays")
  # Group label appears only if non-normal and count data
  if (!result$is_normal && result$is_count) {
    expect_match(result$interpretation, "clinic location")
  }
})

# Test 10: Using AUDIT fixture data
test_that("mysterycall_check_normality works with AUDIT fixture", {
  result <- suppressMessages(
    mysterycall_check_normality(AUDIT, "business_days_until_appointment",
                                 outcome_label = "days to appointment",
                                 group_label = "insurance type")
  )

  # Basic structure checks
  expect_true(is.list(result))
  expect_true("is_normal" %in% names(result))
  expect_true("interpretation" %in% names(result))
  expect_type(result$is_count, "logical")
})
