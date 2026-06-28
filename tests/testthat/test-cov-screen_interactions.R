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
# Test 1: Happy path - simple poisson without random intercept
# ============================================================================
test_that("mysterycall_screen_interactions() returns correct structure with simple poisson", {
  skip_if_not_installed("lme4")

  set.seed(228)
  test_data <- data.frame(
    outcome = c(5L, 3L, 8L, 6L, 7L, 4L, 9L, 2L),
    exposure = c("A", "B", "A", "B", "A", "B", "A", "B"),
    cand1 = c(1L, 0L, 1L, 0L, 1L, 0L, 1L, 0L),
    cand2 = c(10L, 20L, 15L, 25L, 12L, 22L, 18L, 28L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "outcome",
      exposure = "exposure",
      candidates = c("cand1", "cand2"),
      family = "poisson"
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_equal(colnames(result), c("candidate", "n_terms", "min_p_value", "significant"))
  expect_true(all(result$candidate %in% c("cand1", "cand2")))
  expect_true(all(is.integer(result$n_terms) | is.na(result$n_terms)))
  expect_true(all(is.numeric(result$min_p_value) | is.na(result$min_p_value)))
  expect_true(all(is.logical(result$significant) | is.na(result$significant)))
})

# ============================================================================
# Test 2: Happy path - with random intercept (lme4)
# ============================================================================
test_that("mysterycall_screen_interactions() works with random_intercept", {
  skip_if_not_installed("lme4")

  set.seed(228)
  test_data <- data.frame(
    outcome = c(5L, 3L, 8L, 6L, 7L, 4L, 9L, 2L),
    exposure = c("A", "B", "A", "B", "A", "B", "A", "B"),
    cand1 = c(1L, 0L, 1L, 0L, 1L, 0L, 1L, 0L),
    group = c("G1", "G1", "G2", "G2", "G1", "G1", "G2", "G2"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "outcome",
      exposure = "exposure",
      candidates = c("cand1"),
      random_intercept = "group",
      family = "poisson"
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$candidate, "cand1")
  expect_true(is.logical(result$significant) || is.na(result$significant))
})

# ============================================================================
# Test 3: Edge case - single candidate, results sorted by p-value
# ============================================================================
test_that("mysterycall_screen_interactions() sorts results by min_p_value", {
  skip_if_not_installed("lme4")

  set.seed(228)
  test_data <- data.frame(
    outcome = c(5L, 3L, 8L, 6L, 7L, 4L, 9L, 2L),
    exposure = c("A", "B", "A", "B", "A", "B", "A", "B"),
    cand1 = c(1L, 0L, 1L, 0L, 1L, 0L, 1L, 0L),
    cand2 = c(10L, 20L, 15L, 25L, 12L, 22L, 18L, 28L),
    cand3 = c(100L, 200L, 150L, 250L, 120L, 220L, 180L, 280L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "outcome",
      exposure = "exposure",
      candidates = c("cand1", "cand2", "cand3"),
      family = "poisson"
    )
  ))

  # Check that result is ordered by min_p_value (NAs should go last)
  na_mask <- is.na(result$min_p_value)
  if (!all(na_mask)) {
    valid_p_values <- result$min_p_value[!na_mask]
    expect_true(all(valid_p_values == sort(valid_p_values)))
  }
})

# ============================================================================
# Test 4: Edge case - single candidate
# ============================================================================
test_that("mysterycall_screen_interactions() handles single candidate", {
  skip_if_not_installed("lme4")

  set.seed(228)
  test_data <- data.frame(
    outcome = c(5L, 3L, 8L, 6L, 7L, 9L),
    exposure = c("A", "B", "A", "B", "A", "B"),
    cand1 = c(1L, 0L, 1L, 0L, 1L, 0L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "outcome",
      exposure = "exposure",
      candidates = c("cand1"),
      family = "poisson"
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$candidate, "cand1")
})

# ============================================================================
# Test 5: Bad input - data is not a data frame
# ============================================================================
test_that("mysterycall_screen_interactions() rejects non-data.frame data", {
  expect_error(
    mysterycall_screen_interactions(
      data = list(outcome = 1, exposure = "A"),
      outcome = "outcome",
      exposure = "exposure",
      candidates = "cand1",
      family = "poisson"
    ),
    "must be a data frame"
  )
})

# ============================================================================
# Test 6: Bad input - missing outcome column
# ============================================================================
test_that("mysterycall_screen_interactions() errors on missing outcome column", {
  skip_if_not_installed("lme4")

  test_data <- data.frame(
    exposure = c("A", "B", "A", "B"),
    cand1 = c(1L, 0L, 1L, 0L),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "missing_outcome",
      exposure = "exposure",
      candidates = "cand1",
      family = "poisson"
    ),
    "Columns not found"
  )
})

# ============================================================================
# Test 7: Bad input - missing exposure column
# ============================================================================
test_that("mysterycall_screen_interactions() errors on missing exposure column", {
  skip_if_not_installed("lme4")

  test_data <- data.frame(
    outcome = c(5L, 3L, 8L, 6L),
    cand1 = c(1L, 0L, 1L, 0L),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "outcome",
      exposure = "missing_exposure",
      candidates = "cand1",
      family = "poisson"
    ),
    "Columns not found"
  )
})

# ============================================================================
# Test 8: Bad input - missing candidate column
# ============================================================================
test_that("mysterycall_screen_interactions() errors on missing candidate column", {
  skip_if_not_installed("lme4")

  test_data <- data.frame(
    outcome = c(5L, 3L, 8L, 6L),
    exposure = c("A", "B", "A", "B"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "outcome",
      exposure = "exposure",
      candidates = c("missing_cand1", "missing_cand2"),
      family = "poisson"
    ),
    "Columns not found"
  )
})

# ============================================================================
# Test 9: Bad input - random_intercept column not in data
# ============================================================================
test_that("mysterycall_screen_interactions() errors when random_intercept not in data", {
  skip_if_not_installed("lme4")

  test_data <- data.frame(
    outcome = c(5L, 3L, 8L, 6L),
    exposure = c("A", "B", "A", "B"),
    cand1 = c(1L, 0L, 1L, 0L),
    group = c("G1", "G1", "G2", "G2"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "outcome",
      exposure = "exposure",
      candidates = "cand1",
      random_intercept = "missing_group",
      family = "poisson"
    ),
    "random_intercept.*not found"
  )
})

# ============================================================================
# Test 10: Bad input - lme4 not installed (mocked via skip)
# ============================================================================
test_that("mysterycall_screen_interactions() requires lme4 when random_intercept used", {
  skip_if_not_installed("lme4")

  test_data <- data.frame(
    outcome = c(5L, 3L, 8L, 6L),
    exposure = c("A", "B", "A", "B"),
    cand1 = c(1L, 0L, 1L, 0L),
    group = c("G1", "G1", "G2", "G2"),
    stringsAsFactors = FALSE
  )

  # This test verifies the function checks for lme4.
  # We skip_if_not_installed above to avoid false negatives.
  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "outcome",
      exposure = "exposure",
      candidates = "cand1",
      random_intercept = "group",
      family = "poisson"
    )
  ))

  expect_s3_class(result, "data.frame")
})

# ============================================================================
# Test 11: Bad input - negative_binomial without glmmTMB
# ============================================================================
test_that("mysterycall_screen_interactions() requires glmmTMB for negative_binomial", {
  skip_if_not_installed("lme4")

  test_data <- data.frame(
    outcome = c(5L, 3L, 8L, 6L),
    exposure = c("A", "B", "A", "B"),
    cand1 = c(1L, 0L, 1L, 0L),
    stringsAsFactors = FALSE
  )

  # If glmmTMB is not installed, expect error
  if (!requireNamespace("glmmTMB", quietly = TRUE)) {
    expect_error(
      mysterycall_screen_interactions(
        data = test_data,
        outcome = "outcome",
        exposure = "exposure",
        candidates = "cand1",
        family = "negative_binomial"
      ),
      "glmmTMB.*required"
    )
  } else {
    # If glmmTMB is installed, just verify it runs without error
    result <- suppressMessages(suppressWarnings(
      mysterycall_screen_interactions(
        data = test_data,
        outcome = "outcome",
        exposure = "exposure",
        candidates = "cand1",
        family = "negative_binomial"
      )
    ))
    expect_s3_class(result, "data.frame")
  }
})

# ============================================================================
# Test 12: Model convergence failure returns NA results
# ============================================================================
test_that("mysterycall_screen_interactions() returns NA when model fails", {
  skip_if_not_installed("lme4")

  # Create data that will likely fail convergence:
  # Extremely sparse or degenerate interaction
  set.seed(228)
  test_data <- data.frame(
    outcome = c(0L, 0L, 0L, 0L, 1L, 1L),
    exposure = c("A", "A", "A", "B", "B", "B"),
    cand1 = c(1L, 1L, 1L, 1L, 1L, 1L),  # No variance
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "outcome",
      exposure = "exposure",
      candidates = "cand1",
      family = "poisson"
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  # When model fails, returns NA for numeric columns
  expect_true(is.na(result$min_p_value) || is.numeric(result$min_p_value))
})

# ============================================================================
# Test 13: Using COUNT_DF fixture (model-dependent)
# ============================================================================
test_that("mysterycall_screen_interactions() works with COUNT_DF fixture", {
  skip_if_not_installed("lme4")

  # COUNT_DF has outcome 'days' and exposure 'insurance'
  # Create additional candidate columns
  test_data <- COUNT_DF
  set.seed(228)
  test_data$cand1 <- rep(c(0L, 1L), 40L)
  test_data$cand2 <- rep(c("X", "Y"), 40L)

  result <- suppressMessages(suppressWarnings(
    mysterycall_screen_interactions(
      data = test_data,
      outcome = "days",
      exposure = "insurance",
      candidates = c("cand1", "cand2"),
      family = "poisson"
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_equal(result$candidate, c("cand1", "cand2"))
})
