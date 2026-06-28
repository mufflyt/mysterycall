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


# ============================================================================
# TEST 1: Happy path - basic call with group_col and covariate_cols
# ============================================================================
test_that("mysterycall_missing_data_analysis works with group_col and covariate_cols", {
  set.seed(1)
  df <- data.frame(
    appt_date  = c(rep(as.Date("2024-03-01"), 60), rep(NA, 20)),
    insurance  = sample(c("BCBS", "Medicaid"), 80, replace = TRUE),
    physician  = rep(paste0("Dr", 1:20), each = 4),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_missing_data_analysis(
      df,
      outcome_col    = "appt_date",
      group_col      = "insurance",
      covariate_cols = "physician"
    )
  )

  expect_s3_class(result, "mysterycall_missing_data")
  expect_named(result, c("summary", "overall", "interpretation", "group_table", "outcome_col"))
  expect_type(result$summary, "list")
  expect_type(result$overall, "list")
  expect_equal(result$outcome_col, "appt_date")
  expect_equal(result$overall$n_total, 80)
  expect_equal(result$overall$n_missing, 20)
  expect_equal(result$overall$pct_missing, 25)
  expect_true(nrow(result$summary) >= 1)
  expect_false(is.null(result$group_table))
})


# ============================================================================
# TEST 2: Happy path - minimal call with only outcome_col (no group/covariates)
# ============================================================================
test_that("mysterycall_missing_data_analysis works with only outcome_col", {
  df <- data.frame(
    outcome = c(1, 2, 3, NA, 5),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "outcome"
    )
  )

  expect_s3_class(result, "mysterycall_missing_data")
  expect_equal(result$overall$n_total, 5)
  expect_equal(result$overall$n_missing, 1)
  expect_equal(result$overall$pct_missing, 20)
  expect_null(result$group_table)
})


# ============================================================================
# TEST 3: Edge case - no missing data in outcome column
# ============================================================================
test_that("mysterycall_missing_data_analysis handles zero missing values", {
  df <- data.frame(
    outcome  = c(1, 2, 3, 4, 5),
    group    = c("A", "B", "A", "B", "A"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "outcome",
      group_col   = "group"
    )
  )

  expect_equal(result$overall$n_missing, 0)
  expect_equal(result$overall$pct_missing, 0)
  expect_true(grepl("No missing data", result$interpretation))
})


# ============================================================================
# TEST 4: Edge case - all missing data in outcome column
# ============================================================================
test_that("mysterycall_missing_data_analysis handles all missing values", {
  df <- data.frame(
    outcome = rep(NA, 5),
    group   = c("A", "B", "A", "B", "A"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "outcome",
      group_col   = "group"
    )
  )

  expect_equal(result$overall$n_missing, 5)
  expect_equal(result$overall$pct_missing, 100)
  expect_true(nrow(result$summary) >= 1)
})


# ============================================================================
# TEST 5: Edge case - numeric outcome with only categorical predictors
# ============================================================================
test_that("mysterycall_missing_data_analysis tests categorical predictors", {
  set.seed(2)
  df <- data.frame(
    outcome = c(rep(100, 50), rep(NA, 10)),
    group   = rep(c("A", "B"), 30),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "outcome",
      group_col   = "group"
    )
  )

  expect_true(nrow(result$summary) >= 1)
  expect_true("group" %in% result$summary$variable)
  # Check for test types (Chi-square or Fisher)
  expect_true(all(result$summary$test %in% c("Chi-square", "Fisher", "insufficient data")))
})


# ============================================================================
# TEST 6: Error case - data is not a data frame
# ============================================================================
test_that("mysterycall_missing_data_analysis rejects non-data.frame input", {
  expect_error(
    mysterycall_missing_data_analysis(
      list(x = 1:5),
      outcome_col = "x"
    ),
    "`data` must be a data frame"
  )
})


# ============================================================================
# TEST 7: Error case - outcome_col not found in data
# ============================================================================
test_that("mysterycall_missing_data_analysis rejects missing outcome_col", {
  df <- data.frame(x = 1:5)
  expect_error(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "nonexistent"
    ),
    "outcome_col.*not found"
  )
})


# ============================================================================
# TEST 8: Error case - group_col not found in data
# ============================================================================
test_that("mysterycall_missing_data_analysis rejects missing group_col", {
  df <- data.frame(outcome = 1:5)
  expect_error(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "outcome",
      group_col   = "nonexistent"
    ),
    "group_col.*not found"
  )
})


# ============================================================================
# TEST 9: Error case - covariate_cols not found in data
# ============================================================================
test_that("mysterycall_missing_data_analysis rejects missing covariate_cols", {
  df <- data.frame(outcome = 1:5, group = c("A", "B", "A", "B", "A"))
  expect_error(
    mysterycall_missing_data_analysis(
      df,
      outcome_col    = "outcome",
      group_col      = "group",
      covariate_cols = c("missing_var")
    ),
    "Columns not found"
  )
})


# ============================================================================
# TEST 10: Error case - outcome_col is not a single character string
# ============================================================================
test_that("mysterycall_missing_data_analysis requires single-character outcome_col", {
  df <- data.frame(x = 1:5, y = 6:10)
  expect_error(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = c("x", "y")
    ),
    "outcome_col.*must be a single character string"
  )
})


# ============================================================================
# TEST 11: Error case - alpha outside (0, 1)
# ============================================================================
test_that("mysterycall_missing_data_analysis validates alpha bounds", {
  df <- data.frame(outcome = 1:5)
  expect_error(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "outcome",
      alpha       = 0
    ),
    "alpha.*must be a single number in \\(0, 1\\)"
  )
  expect_error(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "outcome",
      alpha       = 1
    ),
    "alpha.*must be a single number in \\(0, 1\\)"
  )
  expect_error(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "outcome",
      alpha       = 1.5
    ),
    "alpha.*must be a single number in \\(0, 1\\)"
  )
})


# ============================================================================
# TEST 12: Happy path - numeric predictor (Wilcoxon test)
# ============================================================================
test_that("mysterycall_missing_data_analysis applies Wilcoxon test to numeric predictors", {
  set.seed(3)
  df <- data.frame(
    outcome = c(rep(100, 50), rep(NA, 10)),
    score   = c(rnorm(60, mean = 50, sd = 10)),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_missing_data_analysis(
      df,
      outcome_col    = "outcome",
      covariate_cols = "score"
    )
  )

  expect_true("score" %in% result$summary$variable)
  score_row <- result$summary[result$summary$variable == "score", ]
  expect_true(score_row$test %in% c("Wilcoxon", "insufficient data"))
})


# ============================================================================
# TEST 13: Print method works
# ============================================================================
test_that("print.mysterycall_missing_data displays output correctly", {
  df <- data.frame(
    outcome = c(1, 2, NA, 4, 5),
    group   = c("A", "B", "A", "B", "A"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "outcome",
      group_col   = "group"
    )
  )

  output <- suppressMessages(
    capture.output(print(result))
  )

  expect_true(any(grepl("Missing Data Analysis", output)))
  expect_true(any(grepl("Overall", output)))
})


# ============================================================================
# TEST 14: Integration test with AUDIT fixture
# ============================================================================
test_that("mysterycall_missing_data_analysis works with AUDIT fixture", {
  # Create a version with missing appointment info
  audit_with_missing <- AUDIT
  audit_with_missing$business_days_until_appointment[c(1, 3)] <- NA

  result <- suppressMessages(
    mysterycall_missing_data_analysis(
      audit_with_missing,
      outcome_col    = "business_days_until_appointment",
      group_col      = "insurance",
      covariate_cols = c("offered", "wave")
    )
  )

  expect_s3_class(result, "mysterycall_missing_data")
  expect_equal(result$overall$n_total, 4)
  expect_equal(result$overall$n_missing, 2)
  expect_equal(result$overall$pct_missing, 50)
})


# ============================================================================
# TEST 15: Integration test with COUNT_DF fixture
# ============================================================================
test_that("mysterycall_missing_data_analysis works with COUNT_DF fixture", {
  # Add missing values
  count_with_missing <- COUNT_DF
  count_with_missing$days[c(10, 25, 50, 75)] <- NA

  result <- suppressMessages(
    mysterycall_missing_data_analysis(
      count_with_missing,
      outcome_col    = "days",
      group_col      = "insurance",
      covariate_cols = NULL
    )
  )

  expect_s3_class(result, "mysterycall_missing_data")
  expect_equal(result$overall$n_missing, 4)
  expect_false(is.null(result$group_table))
  expect_true("insurance" %in% result$summary$variable)
})
