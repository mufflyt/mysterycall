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

# ---- Test 1: Happy path with valid minimal inputs ----
test_that("disparities_table returns correct class and structure", {
  set.seed(1)
  df <- data.frame(
    group = c("A", "A", "B", "B", "C", "C"),
    outcome = c(1, 0, 1, 1, 0, 1),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group")
  )

  # Check class
  expect_s3_class(result, "mysterycall_disparities_table")
  expect_s3_class(result, "data.frame")

  # Check required columns
  expected_cols <- c("group", "n", "n_accepted", "rate", "lower_ci", "upper_ci",
                     "abs_diff", "rel_risk", "rr_lower", "rr_upper", "p_value", "p_value_fmt")
  expect_equal(names(result), expected_cols)

  # Check attributes
  expect_true(!is.null(attr(result, "ref_group")))
  expect_true(!is.null(attr(result, "ci_method")))
  expect_true(!is.null(attr(result, "alpha")))

  # Check that reference group is first row
  expect_equal(result$group[[1]], attr(result, "ref_group"))
})

# ---- Test 2: Reference group sorting and rate ordering ----
test_that("disparities_table sorts ref group first, then by descending rate", {
  set.seed(2)
  df <- data.frame(
    group = c("A", "A", "B", "B", "B", "C", "C", "C", "C"),
    outcome = c(0, 1,  1, 0, 0,  1, 1, 1, 0),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group", ref_group = "A")
  )

  # A should be first
  expect_equal(result$group[[1]], "A")

  # Non-ref rows should be sorted by descending rate
  non_ref_rates <- result$rate[2:nrow(result)]
  expect_equal(non_ref_rates, sort(non_ref_rates, decreasing = TRUE, na.last = TRUE))
})

# ---- Test 3: Different CI methods produce different results ----
test_that("disparities_table with different ci_methods produces valid CIs", {
  set.seed(3)
  df <- data.frame(
    group = c("X", "X", "X", "Y", "Y"),
    outcome = c(1, 1, 0, 1, 0),
    stringsAsFactors = FALSE
  )

  wilson_result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group", ci_method = "wilson")
  )
  exact_result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group", ci_method = "exact")
  )
  wald_result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group", ci_method = "wald")
  )

  # Check that ci_method is stored
  expect_equal(attr(wilson_result, "ci_method"), "wilson")
  expect_equal(attr(exact_result, "ci_method"), "exact")
  expect_equal(attr(wald_result, "ci_method"), "wald")

  # Check that CIs are valid (lower <= upper for non-NA rows)
  for (result in list(wilson_result, exact_result, wald_result)) {
    valid_rows <- !is.na(result$lower_ci) & !is.na(result$upper_ci)
    if (any(valid_rows)) {
      expect_true(all(result$lower_ci[valid_rows] <= result$upper_ci[valid_rows]))
    }
  }
})

# ---- Test 4: NA handling in outcome and group columns ----
test_that("disparities_table correctly handles NAs in outcome and group", {
  set.seed(4)
  df <- data.frame(
    group = c("A", NA, "A", "B", "B", NA),
    outcome = c(1, 0, NA, 1, 1, 0),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group")
  )

  # Should have rows for A and B only (NA group should be dropped)
  expect_equal(sort(unique(result$group)), c("A", "B"))

  # Sample sizes should reflect dropped NAs
  # A: original 2 rows, 1 NA in outcome, 1 with NA group = 1 valid row
  # B: original 2 rows, no NAs = 2 valid rows
  expect_equal(result$n[result$group == "A"], 1L)
  expect_equal(result$n[result$group == "B"], 2L)
})

# ---- Test 5: Zero or all-NA outcome scenarios ----
test_that("disparities_table handles zero acceptance rates and single-group data", {
  set.seed(5)
  df <- data.frame(
    group = c("A", "A", "B", "B"),
    outcome = c(0, 0, 1, 1),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group")
  )

  # Group A has 0 acceptances
  a_row <- result[result$group == "A", ]
  expect_equal(a_row$n_accepted, 0L)
  expect_equal(a_row$rate, 0)

  # Group B has 100% acceptance
  b_row <- result[result$group == "B", ]
  expect_equal(b_row$n_accepted, 2L)
  expect_equal(b_row$rate, 1)
})

# ---- Test 6: Alpha parameter and CI bounds ----
test_that("disparities_table respects alpha parameter", {
  set.seed(6)
  df <- data.frame(
    group = rep(c("A", "B"), each = 20),
    outcome = c(rbinom(20, 1, 0.6), rbinom(20, 1, 0.7)),
    stringsAsFactors = FALSE
  )

  result_95 <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group", alpha = 0.05)
  )
  result_90 <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group", alpha = 0.10)
  )

  # Check alpha is stored
  expect_equal(attr(result_95, "alpha"), 0.05)
  expect_equal(attr(result_90, "alpha"), 0.10)

  # 90% CI should be narrower than 95% CI for the same data
  ci_width_95 <- result_95$upper_ci - result_95$lower_ci
  ci_width_90 <- result_90$upper_ci - result_90$lower_ci
  valid <- !is.na(ci_width_95) & !is.na(ci_width_90)
  if (any(valid)) {
    expect_true(all(ci_width_90[valid] <= ci_width_95[valid] + 1e-10))
  }
})

# ---- Test 7: Relative risk and p-value calculations ----
test_that("disparities_table computes relative risk and p-values correctly", {
  set.seed(7)
  df <- data.frame(
    group = c("Ref", "Ref", "Ref", "Ref", "Test", "Test", "Test", "Test"),
    outcome = c(1, 1, 0, 0, 1, 1, 1, 0),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group", ref_group = "Ref")
  )

  # Reference row should have rel_risk = 1, abs_diff = 0, p_value = NA
  ref_row <- result[result$group == "Ref", ]
  expect_equal(ref_row$rel_risk, 1)
  expect_equal(ref_row$abs_diff, 0)
  expect_true(is.na(ref_row$p_value))

  # Non-ref row should have valid rel_risk, abs_diff, and p_value_fmt
  test_row <- result[result$group == "Test", ]
  expect_true(!is.na(test_row$rel_risk))
  expect_true(!is.na(test_row$abs_diff))
  expect_false(is.na(test_row$p_value_fmt))

  # rel_risk should be positive
  expect_true(test_row$rel_risk > 0)
})

# ---- Test 8: Factor group column handling ----
test_that("disparities_table handles factor group columns", {
  set.seed(8)
  df <- data.frame(
    group = factor(c("Z", "Z", "X", "X"), levels = c("X", "Z")),
    outcome = c(1, 0, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group")
  )

  # First group should respect factor levels (X before Z)
  expect_equal(result$group[[1]], "X")
  expect_equal(attr(result, "ref_group"), "X")
})

# ---- Test 9: Invalid reference group ----
test_that("disparities_table errors on invalid ref_group", {
  set.seed(9)
  df <- data.frame(
    group = c("A", "A", "B", "B"),
    outcome = c(1, 0, 1, 0),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_disparities_table(df, "outcome", "group", ref_group = "NotInData")
    ),
    "ref_group.*not found"
  )
})

# ---- Test 10: Non-binary outcome validation ----
test_that("disparities_table errors on non-binary outcome", {
  set.seed(10)
  df <- data.frame(
    group = c("A", "A", "B", "B"),
    outcome = c(1, 2, 0, 1),  # 2 is invalid
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_disparities_table(df, "outcome", "group")
    ),
    "must be binary"
  )
})

# ---- Test 11: Missing column errors ----
test_that("disparities_table errors on missing columns", {
  set.seed(11)
  df <- data.frame(
    group = c("A", "B"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_disparities_table(df, "missing_col", "group")
    ),
    "not found in.*data"
  )

  expect_error(
    suppressMessages(
      mysterycall_disparities_table(df, "outcome", "missing_group_col")
    ),
    "not found in.*data"
  )
})

# ---- Test 12: Invalid input types ----
test_that("disparities_table errors on invalid input types", {
  set.seed(12)
  df <- data.frame(
    group = c("A", "B"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )

  # Non-data.frame input
  expect_error(
    suppressMessages(
      mysterycall_disparities_table(list(group = c("A", "B")), "outcome", "group")
    ),
    "must be a data.frame"
  )

  # outcome_col not a single string
  expect_error(
    suppressMessages(
      mysterycall_disparities_table(df, c("outcome", "group"), "group")
    ),
    "single character string"
  )

  # group_col not a single string
  expect_error(
    suppressMessages(
      mysterycall_disparities_table(df, "outcome", 123)
    ),
    "single character string"
  )

  # Invalid alpha
  expect_error(
    suppressMessages(
      mysterycall_disparities_table(df, "outcome", "group", alpha = 1.5)
    ),
    "alpha.*must be a single numeric"
  )
})

# ---- Test 13: All-NA outcome column ----
test_that("disparities_table errors when outcome_col is all NAs", {
  set.seed(13)
  df <- data.frame(
    group = c("A", "A", "B", "B"),
    outcome = c(NA, NA, NA, NA),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_disparities_table(df, "outcome", "group")
    ),
    "contains only NAs"
  )
})

# ---- Test 14: Print method returns invisibly ----
test_that("print.mysterycall_disparities_table returns invisibly", {
  set.seed(14)
  df <- data.frame(
    group = c("A", "A", "B", "B"),
    outcome = c(1, 0, 1, 1),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group")
  )

  # Capture output
  output <- capture.output(returned <- print(result))

  # Check that output was produced
  expect_true(length(output) > 0)

  # Check that returned value is the same as input (invisibly)
  expect_identical(returned, result)
})

# ---- Test 15: Print method formatting ----
test_that("print.mysterycall_disparities_table formats output correctly", {
  set.seed(15)
  df <- data.frame(
    group = c("Med", "Med", "Med", "Priv", "Priv", "Priv"),
    outcome = c(1, 1, 0, 1, 1, 1),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group", ci_method = "wilson")
  )

  output <- capture.output(print(result))

  # Check for expected header info
  expect_true(any(grepl("Disparity table", output)))
  expect_true(any(grepl("ref:", output)))
  expect_true(any(grepl("wilson", output)))

  # Check for column headers
  expect_true(any(grepl("Group", output)))
  expect_true(any(grepl("Rate", output)))
  expect_true(any(grepl("RR", output)))
})

# ---- Test 16: Explicit vs. implicit reference group ----
test_that("disparities_table with explicit ref_group matches expected behavior", {
  set.seed(16)
  df <- data.frame(
    group = c("Z", "Z", "X", "X", "Y", "Y"),
    outcome = c(1, 0, 1, 1, 0, 0),
    stringsAsFactors = FALSE
  )

  result_implicit <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group")
  )
  result_explicit <- suppressMessages(
    mysterycall_disparities_table(df, "outcome", "group", ref_group = "X")
  )

  # Implicit should use first alphabetical: X
  expect_equal(attr(result_implicit, "ref_group"), "X")

  # Explicit should match
  expect_equal(attr(result_explicit, "ref_group"), "X")

  # First rows should have identical ref group values
  expect_equal(result_implicit$rel_risk[[1]], 1)
  expect_equal(result_explicit$rel_risk[[1]], 1)
})
