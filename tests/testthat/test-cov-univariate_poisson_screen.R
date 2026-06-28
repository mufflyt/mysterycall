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

# Happy path: basic functionality with valid data
test_that("mysterycall_univariate_poisson_screen returns list with correct structure", {
  set.seed(1)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    pred2 = rnorm(100),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      output_dir = NA
    )
  )

  expect_type(result, "list")
  expect_true(all(c("results", "significant", "sentence", "alpha") %in% names(result)))
  expect_s3_class(result$results, "tbl")
  expect_s3_class(result$significant, "tbl")
  expect_type(result$sentence, "character")
  expect_type(result$alpha, "double")
})

# Happy path: results tibble has correct columns
test_that("mysterycall_univariate_poisson_screen results has required columns", {
  set.seed(2)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    pred2 = sample(c("X", "Y", "Z"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      output_dir = NA
    )
  )

  expected_cols <- c("Variable", "P_Value", "Formatted_P_Value", "Direction")
  expect_true(all(expected_cols %in% names(result$results)))
  expect_true(nrow(result$results) >= 1)
})

# Happy path: direction is always Higher or Lower
test_that("mysterycall_univariate_poisson_screen Direction is Higher or Lower", {
  set.seed(3)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    pred2 = rnorm(100),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      output_dir = NA
    )
  )

  if (nrow(result$results) > 0) {
    expect_true(all(result$results$Direction %in% c("Higher", "Lower")))
  }
})

# Happy path: outcome_col is automatically excluded
test_that("mysterycall_univariate_poisson_screen excludes outcome_col by default", {
  set.seed(4)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      output_dir = NA
    )
  )

  expect_false("outcome" %in% result$results$Variable)
})

# Happy path: sentence summarizes findings
test_that("mysterycall_univariate_poisson_screen sentence is meaningful", {
  set.seed(5)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      output_dir = NA
    )
  )

  expect_type(result$sentence, "character")
  expect_true(nchar(result$sentence) > 0)
  expect_true(grepl("Significant|No significant", result$sentence))
})

# Edge case: empty data frame
test_that("mysterycall_univariate_poisson_screen handles empty data", {
  df <- data.frame(
    outcome = integer(0),
    pred1 = character(0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      output_dir = NA
    )
  )

  expect_s3_class(result$results, "tbl")
  expect_equal(nrow(result$results), 0)
})

# Edge case: respects exclude_cols parameter
test_that("mysterycall_univariate_poisson_screen respects exclude_cols", {
  set.seed(6)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    pred2 = rnorm(100),
    to_exclude = sample(c("X", "Y"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      exclude_cols = c("outcome", "to_exclude"),
      output_dir = NA
    )
  )

  expect_false("to_exclude" %in% result$results$Variable)
})

# Edge case: skips constant (single unique value) predictors
test_that("mysterycall_univariate_poisson_screen skips constant predictors", {
  set.seed(7)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred_constant = rep("A", 100),
    pred_varying = sample(c("B", "C"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      output_dir = NA
    )
  )

  expect_false("pred_constant" %in% result$results$Variable)
  expect_true("pred_varying" %in% result$results$Variable)
})

# Edge case: p-value adjustment with different methods
test_that("mysterycall_univariate_poisson_screen handles p_adjust_method", {
  set.seed(8)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    pred2 = rnorm(100),
    pred3 = sample(1:3, 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      p_adjust_method = "BH",
      output_dir = NA
    )
  )

  expect_true("P_Value_Adjusted" %in% names(result$results))
  expect_true(all(!is.na(result$results$P_Value_Adjusted)))
})

# Edge case: custom alpha threshold
test_that("mysterycall_univariate_poisson_screen uses custom alpha", {
  set.seed(9)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      alpha = 0.01,
      output_dir = NA
    )
  )

  expect_equal(result$alpha, 0.01)
  # significant should only contain rows where p < alpha
  if (nrow(result$significant) > 0) {
    expect_true(all(result$significant$P_Value < 0.01))
  }
})

# Edge case: NA values in predictor
test_that("mysterycall_univariate_poisson_screen handles NA values", {
  set.seed(10)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred_with_na = c(sample(c("A", "B"), 90, replace = TRUE), rep(NA, 10)),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      output_dir = NA
    )
  )

  expect_s3_class(result$results, "tbl")
  # Should complete without error even with NAs
})

# Bad input: missing outcome_col in data
test_that("mysterycall_univariate_poisson_screen errors when outcome_col not in data", {
  df <- data.frame(
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    pred2 = rnorm(100),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_univariate_poisson_screen(
        df,
        outcome_col = "nonexistent",
        output_dir = NA
      )
    )
  )
})

# Bad input: invalid alpha (outside 0-1)
test_that("mysterycall_univariate_poisson_screen errors with invalid alpha", {
  set.seed(11)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_univariate_poisson_screen(
        df,
        outcome_col = "outcome",
        alpha = 1.5,
        output_dir = NA
      )
    )
  )
})

# Bad input: wrong data type for data argument
test_that("mysterycall_univariate_poisson_screen errors with non-data.frame data", {
  expect_error(
    suppressMessages(
      mysterycall_univariate_poisson_screen(
        data = list(a = 1, b = 2),
        outcome_col = "outcome",
        output_dir = NA
      )
    )
  )
})

# Bad input: non-string outcome_col
test_that("mysterycall_univariate_poisson_screen errors with non-string outcome_col", {
  set.seed(12)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(
      mysterycall_univariate_poisson_screen(
        df,
        outcome_col = 1,
        output_dir = NA
      )
    )
  )
})

# Verify no files written when output_dir = NA
test_that("mysterycall_univariate_poisson_screen output_dir = NA skips file write", {
  set.seed(13)
  df <- data.frame(
    outcome = rpois(100, 5),
    pred1 = sample(c("A", "B"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Should not produce any messages about files being written
  result <- suppressMessages(
    mysterycall_univariate_poisson_screen(
      df,
      outcome_col = "outcome",
      output_dir = NA
    )
  )

  expect_s3_class(result$results, "tbl")
})
