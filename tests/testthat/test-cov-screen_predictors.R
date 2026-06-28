
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

# ====================================================================
# Test 1: Happy path - basic Poisson screening with minimal inputs
# ====================================================================

test_that("mysterycall_screen_predictors returns correct structure with Poisson", {
  skip_if_not_installed("lme4")

  set.seed(2)
  df <- data.frame(
    outcome = rpois(60, 5),
    group   = rep(c("A", "B", "C"), each = 20),
    factor1 = sample(c("X", "Y"), 60, replace = TRUE),
    factor2 = sample(c("1", "2"), 60, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group",
      family           = "poisson"
    )
  ))

  expect_s3_class(result, "mysterycall_screen_predictors")
  expect_true(is.list(result))
  expect_named(result, c("table", "n_screened", "n_significant", "family", "sentence", "significant_predictors"))
  expect_s3_class(result$table, "tbl")
  expect_identical(result$family, "poisson")
  expect_type(result$n_screened, "integer")
  expect_type(result$n_significant, "integer")
  expect_type(result$sentence, "character")
  expect_type(result$significant_predictors, "character")
})

# ====================================================================
# Test 2: Edge case - data with NA values and low variance
# ====================================================================

test_that("mysterycall_screen_predictors handles NA values correctly", {
  skip_if_not_installed("lme4")

  set.seed(3)
  df <- data.frame(
    outcome = c(rpois(40, 5), NA, NA),
    group   = rep(c("A", "B"), 21),
    pred1   = c(rep("X", 30), NA, NA, rep("Y", 10)),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group",
      candidate_cols   = c("pred1"),
      family           = "poisson"
    )
  ))

  expect_s3_class(result, "mysterycall_screen_predictors")
  expect_true(nrow(result$table) >= 1L)
  expect_true("predictor" %in% names(result$table))
  expect_true("n_levels" %in% names(result$table))
  expect_true("skipped" %in% names(result$table))
})

# ====================================================================
# Test 3: Bad input - missing required argument outcome_col
# ====================================================================

test_that("mysterycall_screen_predictors errors when outcome_col missing", {
  skip_if_not_installed("lme4")

  set.seed(4)
  df <- data.frame(
    outcome = rpois(30, 5),
    group   = rep(c("A", "B", "C"), 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_screen_predictors(
      data             = df,
      random_intercept = "group"
    ),
    "outcome_col"
  )
})

# ====================================================================
# Test 4: Bad input - wrong data type for outcome_col
# ====================================================================

test_that("mysterycall_screen_predictors errors when outcome_col not character", {
  skip_if_not_installed("lme4")

  set.seed(5)
  df <- data.frame(
    outcome = rpois(30, 5),
    group   = rep(c("A", "B", "C"), 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = 1L,
      random_intercept = "group"
    ),
    "single character string"
  )
})

# ====================================================================
# Test 5: Logistic family with binary outcome
# ====================================================================

test_that("mysterycall_screen_predictors works with logistic family", {
  skip_if_not_installed("lme4")

  set.seed(6)
  df <- data.frame(
    outcome  = rbinom(50, 1, 0.5),
    group    = rep(c("A", "B"), 25),
    pred1    = sample(c("X", "Y"), 50, replace = TRUE),
    pred2    = sample(c("1", "2", "3"), 50, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group",
      family           = "logistic"
    )
  ))

  expect_identical(result$family, "logistic")
  expect_true(nrow(result$table) >= 1L)
  expect_true(grepl("logistic GLMM", result$sentence))
})

# ====================================================================
# Test 6: Test print method
# ====================================================================

test_that("print.mysterycall_screen_predictors displays output", {
  skip_if_not_installed("lme4")

  set.seed(7)
  df <- data.frame(
    outcome = rpois(50, 5),
    group   = rep(c("A", "B"), 25),
    pred1   = sample(c("X", "Y"), 50, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group"
    )
  ))

  expect_output(print(result), "mysterycall_screen_predictors")
  expect_output(print(result), "Family")
  expect_output(print(result), "Screened")
})

# ====================================================================
# Test 7: Exclude columns parameter
# ====================================================================

test_that("mysterycall_screen_predictors respects exclude_cols", {
  skip_if_not_installed("lme4")

  set.seed(8)
  df <- data.frame(
    outcome   = rpois(60, 5),
    group     = rep(c("A", "B", "C"), 20),
    include_me = sample(c("X", "Y"), 60, replace = TRUE),
    exclude_me = sample(c("1", "2"), 60, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group",
      exclude_cols     = "exclude_me"
    )
  ))

  expect_false("exclude_me" %in% result$table$predictor)
  expect_true("include_me" %in% result$table$predictor)
})

# ====================================================================
# Test 8: min_levels parameter filters low-variance predictors
# ====================================================================

test_that("mysterycall_screen_predictors skips predictors with too few levels", {
  skip_if_not_installed("lme4")

  set.seed(9)
  df <- data.frame(
    outcome = rpois(50, 5),
    group   = rep(c("A", "B"), 25),
    varied  = sample(c("X", "Y", "Z"), 50, replace = TRUE),
    constant = rep("A", 50),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data       = df,
      outcome_col = "outcome",
      random_intercept = "group",
      min_levels = 2L
    )
  ))

  constant_row <- result$table[result$table$predictor == "constant", , drop = FALSE]
  expect_true(nrow(constant_row) > 0L)
  expect_true(constant_row$skipped[1L])
})

# ====================================================================
# Test 9: alpha_screen threshold affects significant_predictors
# ====================================================================

test_that("mysterycall_screen_predictors uses alpha_screen correctly", {
  skip_if_not_installed("lme4")

  set.seed(10)
  df <- data.frame(
    outcome = rpois(60, 5),
    group   = rep(c("A", "B", "C"), 20),
    pred1   = sample(c("X", "Y"), 60, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Strict threshold
  result_strict <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group",
      alpha_screen     = 0.01
    )
  ))

  # Liberal threshold
  result_liberal <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group",
      alpha_screen     = 0.90
    )
  ))

  expect_true(result_liberal$n_significant >= result_strict$n_significant)
})

# ====================================================================
# Test 10: Invalid alpha_screen bounds
# ====================================================================

test_that("mysterycall_screen_predictors errors on invalid alpha_screen", {
  skip_if_not_installed("lme4")

  set.seed(11)
  df <- data.frame(
    outcome = rpois(30, 5),
    group   = rep(c("A", "B", "C"), 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group",
      alpha_screen     = 1.5
    ),
    "alpha_screen.*must be.*0.*1"
  )

  expect_error(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group",
      alpha_screen     = 0
    ),
    "alpha_screen.*must be.*0.*1"
  )
})

# ====================================================================
# Test 11: candidate_cols parameter specification
# ====================================================================

test_that("mysterycall_screen_predictors respects explicit candidate_cols", {
  skip_if_not_installed("lme4")

  set.seed(12)
  df <- data.frame(
    outcome  = rpois(50, 5),
    group    = rep(c("A", "B"), 25),
    pred1    = sample(c("X", "Y"), 50, replace = TRUE),
    pred2    = sample(c("1", "2"), 50, replace = TRUE),
    pred3    = sample(c("P", "Q"), 50, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group",
      candidate_cols   = c("pred1", "pred2")
    )
  ))

  expect_true("pred1" %in% result$table$predictor)
  expect_true("pred2" %in% result$table$predictor)
  expect_false("pred3" %in% result$table$predictor)
})

# ====================================================================
# Test 12: max_predictors truncation
# ====================================================================

test_that("mysterycall_screen_predictors respects max_predictors limit", {
  skip_if_not_installed("lme4")

  set.seed(13)
  df <- data.frame(
    outcome = rpois(50, 5),
    group   = rep(c("A", "B"), 25),
    stringsAsFactors = FALSE
  )

  for (i in 1:5) {
    df[[paste0("pred", i)]] <- sample(c("X", "Y"), 50, replace = TRUE)
  }

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group",
      max_predictors   = 2L
    )
  ))

  expect_true(nrow(result$table) <= 2L)
})

# ====================================================================
# Test 13: Table columns and structure
# ====================================================================

test_that("mysterycall_screen_predictors table has all required columns", {
  skip_if_not_installed("lme4")

  set.seed(14)
  df <- data.frame(
    outcome = rpois(50, 5),
    group   = rep(c("A", "B"), 25),
    pred    = sample(c("X", "Y"), 50, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "group"
    )
  ))

  required_cols <- c("predictor", "estimate", "ci_lower", "ci_upper",
                     "p_value", "p_fmt", "n_levels", "significant",
                     "skipped", "skip_reason")

  for (col in required_cols) {
    expect_true(col %in% names(result$table),
                label = paste("Column", col, "missing from result$table"))
  }
})

# ====================================================================
# Test 14: Non-existent outcome column error
# ====================================================================

test_that("mysterycall_screen_predictors errors on non-existent outcome_col", {
  skip_if_not_installed("lme4")

  set.seed(15)
  df <- data.frame(
    outcome = rpois(30, 5),
    group   = rep(c("A", "B", "C"), 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "nonexistent",
      random_intercept = "group"
    ),
    "not found"
  )
})

# ====================================================================
# Test 15: Non-existent random_intercept column error
# ====================================================================

test_that("mysterycall_screen_predictors errors on non-existent random_intercept", {
  skip_if_not_installed("lme4")

  set.seed(16)
  df <- data.frame(
    outcome = rpois(30, 5),
    group   = rep(c("A", "B", "C"), 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_screen_predictors(
      data             = df,
      outcome_col      = "outcome",
      random_intercept = "nonexistent"
    ),
    "not found"
  )
})
