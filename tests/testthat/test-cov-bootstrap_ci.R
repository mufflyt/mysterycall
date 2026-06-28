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

# ---- Test 1: Happy path - proportion with grouping ----
test_that("mysterycall_bootstrap_ci returns correct structure for proportion with groups", {
  set.seed(100)
  df <- data.frame(
    group = rep(c("A", "B"), each = 50),
    outcome = c(rbinom(50, 1, 0.6), rbinom(50, 1, 0.7)),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_bootstrap_ci(df, "outcome", group_col = "group", n_boot = 500L, seed = 42)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_equal(colnames(result), c("group", "n", "estimate", "lower_ci", "upper_ci", "n_boot"))
  expect_equal(result$group, c("A", "B"))
  expect_equal(result$n_boot, c(500L, 500L))
  expect_true(all(result$estimate >= 0 & result$estimate <= 1))
  expect_true(all(result$lower_ci <= result$upper_ci))
})

# ---- Test 2: Happy path - mean without grouping ----
test_that("mysterycall_bootstrap_ci computes mean statistic with Overall group", {
  set.seed(101)
  df <- data.frame(
    values = rnorm(100, mean = 10, sd = 2),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_bootstrap_ci(df, "values", stat = "mean", n_boot = 500L, seed = 43)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$group, "Overall")
  expect_equal(result$n, 100L)
  expect_true(is.numeric(result$estimate))
  expect_true(result$lower_ci < result$upper_ci)
  expect_true(is.na(result$estimate) == FALSE)
})

# ---- Test 3: Happy path - median statistic ----
test_that("mysterycall_bootstrap_ci computes median correctly", {
  set.seed(102)
  df <- data.frame(
    group = rep(c("X", "Y"), times = 40),
    values = c(rnorm(40, 5, 1), rnorm(40, 8, 1.5)),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_bootstrap_ci(df, "values", group_col = "group", stat = "median", n_boot = 600L, seed = 44)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_equal(result$n_boot, c(600L, 600L))
  expect_true(all(!is.na(result$estimate)))
  expect_true(all(result$lower_ci <= result$estimate & result$estimate <= result$upper_ci))
})

# ---- Test 4: Edge case - factor grouping variable ----
test_that("mysterycall_bootstrap_ci handles factor group_col", {
  set.seed(103)
  df <- data.frame(
    group = factor(c("A", "B", "A", "B", "A", "B"), levels = c("B", "A")),
    outcome = c(1, 0, 1, 1, 0, 1),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_bootstrap_ci(df, "outcome", group_col = "group", n_boot = 200L, seed = 45)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_equal(result$group, c("B", "A"))
  expect_true(all(result$n > 0))
})

# ---- Test 5: Edge case - all NA in a group ----
test_that("mysterycall_bootstrap_ci returns NA rows for groups with all NA", {
  set.seed(104)
  df <- data.frame(
    group = c("A", "A", "B", "B"),
    value = c(1, 2, NA, NA),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_bootstrap_ci(df, "value", group_col = "group", n_boot = 200L)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_equal(result$n[1L], 2L)
  expect_equal(result$n[2L], 0L)
  expect_true(!is.na(result$estimate[1L]))
  expect_true(is.na(result$estimate[2L]))
  expect_true(is.na(result$lower_ci[2L]))
})

# ---- Test 6: Edge case - single observation ----
test_that("mysterycall_bootstrap_ci works with single non-NA observation per group", {
  set.seed(105)
  df <- data.frame(
    group = c("A", "B"),
    value = c(5.0, 3.0),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_bootstrap_ci(df, "value", group_col = "group", n_boot = 100L, seed = 46)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_equal(result$n, c(1L, 1L))
  expect_equal(result$estimate, c(5.0, 3.0))
  expect_true(result$lower_ci[1L] <= result$estimate[1L])
  expect_true(result$lower_ci[2L] <= result$estimate[2L])
})

# ---- Test 7: Bad input - missing column ----
test_that("mysterycall_bootstrap_ci errors on missing outcome_col", {
  df <- data.frame(a = c(1, 2, 3), stringsAsFactors = FALSE)
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_bootstrap_ci(df, "nonexistent", n_boot = 200L)
    )),
    "not found"
  )
})

# ---- Test 8: Bad input - missing group column ----
test_that("mysterycall_bootstrap_ci errors on missing group_col", {
  df <- data.frame(outcome = c(0, 1, 1), stringsAsFactors = FALSE)
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_bootstrap_ci(df, "outcome", group_col = "missing", n_boot = 200L)
    )),
    "not found"
  )
})

# ---- Test 9: Bad input - non-character outcome_col ----
test_that("mysterycall_bootstrap_ci errors on non-character outcome_col", {
  df <- data.frame(a = c(1, 2, 3), stringsAsFactors = FALSE)
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_bootstrap_ci(df, 1, n_boot = 200L)
    )),
    "must be a single character string"
  )
})

# ---- Test 10: Bad input - invalid n_boot ----
test_that("mysterycall_bootstrap_ci errors on n_boot < 100", {
  df <- data.frame(x = c(0, 1, 1), stringsAsFactors = FALSE)
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_bootstrap_ci(df, "x", n_boot = 50L)
    )),
    ">= 100"
  )
})

# ---- Test 11: Bad input - invalid alpha ----
test_that("mysterycall_bootstrap_ci errors on alpha outside (0, 1)", {
  df <- data.frame(x = c(0, 1, 1), stringsAsFactors = FALSE)
  expect_error(
    mysterycall_bootstrap_ci(df, "x", n_boot = 200L, alpha = 1.5),
    "0, 1"
  )
})

# ---- Test 12: Bad input - not a data.frame ----
test_that("mysterycall_bootstrap_ci errors when data is not a data.frame", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_bootstrap_ci(list(a = 1), "x", n_boot = 200L)
    )),
    "must be a data.frame"
  )
})

# ---- Test 13: Seed reproducibility ----
test_that("mysterycall_bootstrap_ci with seed produces identical results", {
  set.seed(106)
  df <- data.frame(
    value = rnorm(50, 10, 2),
    stringsAsFactors = FALSE
  )
  result1 <- suppressMessages(suppressWarnings(
    mysterycall_bootstrap_ci(df, "value", n_boot = 300L, seed = 999)
  ))
  result2 <- suppressMessages(suppressWarnings(
    mysterycall_bootstrap_ci(df, "value", n_boot = 300L, seed = 999)
  ))

  expect_equal(result1$estimate, result2$estimate)
  expect_equal(result1$lower_ci, result2$lower_ci)
  expect_equal(result1$upper_ci, result2$upper_ci)
})

# ---- Test 14: CI bounds relationship ----
test_that("mysterycall_bootstrap_ci produces valid CI (lower <= estimate <= upper)", {
  set.seed(107)
  df <- data.frame(
    group = rep(c("G1", "G2", "G3"), each = 100),
    outcome = c(
      rbinom(100, 1, 0.4),
      rbinom(100, 1, 0.6),
      rbinom(100, 1, 0.8)
    ),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_bootstrap_ci(df, "outcome", group_col = "group", n_boot = 500L, seed = 48)
  ))

  expect_equal(nrow(result), 3L)
  for (i in 1:nrow(result)) {
    expect_true(result$lower_ci[i] <= result$estimate[i] + 1e-6,
                label = sprintf("Row %d: lower <= estimate", i))
    expect_true(result$estimate[i] <= result$upper_ci[i] + 1e-6,
                label = sprintf("Row %d: estimate <= upper", i))
  }
})

# ---- Test 15: Zero rows data frame ----
test_that("mysterycall_bootstrap_ci returns NA for zero-row data.frame", {
  df <- data.frame(
    x = numeric(0),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_bootstrap_ci(df, "x", n_boot = 200L)
  ))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$n[1L], 0L)
})
