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

# ---- Test 1: Happy path with proportion outcome (auto-detection) ----
test_that("mysterycall_compare_waves returns data frame with proportions (auto-detect)", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_compare_waves(AUDIT, "wave", "offered")
  ))

  # Check return type
  expect_s3_class(result, "data.frame")

  # Check expected columns for proportion outcome
  expected_cols <- c("wave", "n", "n_accepted", "rate", "lower_ci", "upper_ci", "p_vs_ref")
  expect_true(all(expected_cols %in% names(result)))

  # Check that we have 2 rows (one per wave)
  expect_equal(nrow(result), 2)

  # Check that ref_wave attribute is set
  expect_equal(attr(result, "ref_wave"), 1)

  # Check data types
  expect_true(is.numeric(result$rate))
  expect_true(is.numeric(result$lower_ci))
  expect_true(is.numeric(result$upper_ci))
})

# ---- Test 2: Happy path with continuous outcome (explicit type) ----
test_that("mysterycall_compare_waves returns data frame with continuous stats", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_compare_waves(AUDIT, "wave", "wait_days", type = "continuous")
  ))

  # Check return type
  expect_s3_class(result, "data.frame")

  # Check expected columns for continuous outcome
  expected_cols <- c("wave", "n", "mean", "median", "sd", "iqr", "p_vs_ref")
  expect_true(all(expected_cols %in% names(result)))

  # Check that we have 2 rows
  expect_equal(nrow(result), 2)

  # Check that ref_wave attribute is set
  expect_equal(attr(result, "ref_wave"), 1)

  # Check data types
  expect_true(is.numeric(result$mean))
  expect_true(is.numeric(result$median))
  expect_true(is.numeric(result$sd))
  expect_true(is.numeric(result$iqr))
})

# ---- Test 3: Group stratification ----
test_that("mysterycall_compare_waves stratifies by group when group_col provided", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_compare_waves(AUDIT, "wave", "offered", group_col = "insurance")
  ))

  # Check return type
  expect_s3_class(result, "data.frame")

  # Check that group column is present
  expect_true("group" %in% names(result))

  # Should have 2 waves × 2 groups = 4 rows
  expect_equal(nrow(result), 4)

  # Check that groups are present
  expect_true(all(c("Medicaid", "BCBS") %in% result$group))
})

# ---- Test 4: Custom reference wave ----
test_that("mysterycall_compare_waves uses custom ref_wave when specified", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_compare_waves(AUDIT, "wave", "offered", ref_wave = 2)
  ))

  # Check that ref_wave attribute is set correctly
  expect_equal(attr(result, "ref_wave"), 2)

  # Reference wave should have NA for p_vs_ref
  ref_row <- result[result$wave == 2, ]
  expect_true(is.na(ref_row$p_vs_ref))
})

# ---- Test 5: Error on missing wave_col ----
test_that("mysterycall_compare_waves errors when wave_col not in data", {
  expect_error(
    mysterycall_compare_waves(AUDIT, "nonexistent", "offered"),
    "wave_col.*not found"
  )
})

# ---- Test 6: Error on missing outcome_col ----
test_that("mysterycall_compare_waves errors when outcome_col not in data", {
  expect_error(
    mysterycall_compare_waves(AUDIT, "wave", "nonexistent"),
    "outcome_col.*not found"
  )
})

# ---- Test 7: Error on missing group_col ----
test_that("mysterycall_compare_waves errors when group_col not in data", {
  expect_error(
    mysterycall_compare_waves(AUDIT, "wave", "offered", group_col = "nonexistent"),
    "group_col.*not found"
  )
})

# ---- Test 8: Error on insufficient unique waves ----
test_that("mysterycall_compare_waves errors with fewer than 2 waves", {
  single_wave <- AUDIT[AUDIT$wave == 1, ]
  expect_error(
    mysterycall_compare_waves(single_wave, "wave", "offered"),
    "At least 2 unique waves"
  )
})

# ---- Test 9: Error on invalid ref_wave ----
test_that("mysterycall_compare_waves errors when ref_wave not in data", {
  expect_error(
    mysterycall_compare_waves(AUDIT, "wave", "offered", ref_wave = 999),
    "ref_wave.*not found"
  )
})

# ---- Test 10: Error on non-data.frame input ----
test_that("mysterycall_compare_waves errors on non-data.frame input", {
  expect_error(
    mysterycall_compare_waves(list(a = 1), "wave", "offered"),
    "is.data.frame"
  )
})

# ---- Test 11: Edge case with NA values in outcome ----
test_that("mysterycall_compare_waves handles NA values in outcome", {
  data_with_na <- AUDIT
  data_with_na$offered[1] <- NA

  result <- suppressMessages(suppressWarnings(
    mysterycall_compare_waves(data_with_na, "wave", "offered")
  ))

  # Should still compute, just with adjusted n
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  # First wave should have n=1 instead of 2
  expect_equal(result[result$wave == 1, "n"], 1)
})

# ---- Test 12: Edge case with all-NA wave subset ----
test_that("mysterycall_compare_waves handles all-NA outcome in subset", {
  data_with_na <- AUDIT
  data_with_na$offered[1:2] <- NA

  result <- suppressMessages(suppressWarnings(
    mysterycall_compare_waves(data_with_na, "wave", "offered")
  ))

  expect_s3_class(result, "data.frame")
  # First wave should have n=0 and rate=NA
  first_row <- result[result$wave == 1, ]
  expect_equal(first_row$n, 0)
  expect_true(is.na(first_row$rate))
})

# ---- Test 13: Type parameter explicit "proportion" ----
test_that("mysterycall_compare_waves respects explicit type='proportion'", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_compare_waves(AUDIT, "wave", "offered", type = "proportion")
  ))

  # Should have proportion columns
  expect_true(all(c("rate", "lower_ci", "upper_ci") %in% names(result)))
  expect_false("mean" %in% names(result))
})

# ---- Test 14: Type parameter explicit "continuous" ----
test_that("mysterycall_compare_waves respects explicit type='continuous'", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_compare_waves(AUDIT, "wave", "wait_days", type = "continuous")
  ))

  # Should have continuous columns
  expect_true(all(c("mean", "median", "sd", "iqr") %in% names(result)))
  expect_false("rate" %in% names(result))
})

# ---- Test 15: Continuous outcome with GROUP and custom ref_wave ----
test_that("mysterycall_compare_waves combines continuous + group + ref_wave", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_compare_waves(
      AUDIT,
      "wave",
      "wait_days",
      group_col = "insurance",
      type = "continuous",
      ref_wave = 2
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_true("group" %in% names(result))
  expect_equal(attr(result, "ref_wave"), 2)
  expect_equal(nrow(result), 4)
})
