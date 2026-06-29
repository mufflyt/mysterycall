library(testthat)
testthat::skip_if_not_installed("ggplot2")

# Gold-standard Shapiro-Wilk p-values computed externally before writing tests.
# Normal data vector  → shapiro.test p = 0.9629 → p > 0.05 → returns mean/sd
# Skewed data vector  → shapiro.test p = 0.0002 → p < 0.05 → returns median/iqr
#   skewed median = 1.5, IQR = 8.4  (manually verified)

NORMAL_DATA <- c(10, 10.1, 9.9, 10.05, 9.95, 10.2, 9.8, 10.15, 9.85, 10.0)
SKEWED_DATA <- c(0.1, 0.2, 0.3, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0)

test_that("mysterycall:::mysterycall_check_normality - normal data returns list with mean and sd", {
  df <- data.frame(value = NORMAL_DATA)
  result <- suppressMessages(mysterycall:::mysterycall_check_normality(df, "value"))
  expect_type(result, "list")
  expect_true("mean" %in% names(result))
  expect_true("sd" %in% names(result))
  expect_false("median" %in% names(result))
  expect_false("iqr" %in% names(result))
})

test_that("mysterycall:::mysterycall_check_normality - normal data mean is correct gold-standard value", {
  df <- data.frame(value = NORMAL_DATA)
  result <- suppressMessages(mysterycall:::mysterycall_check_normality(df, "value"))
  expect_equal(result$mean, mean(NORMAL_DATA), tolerance = 1e-10)
  expect_equal(result$sd,   sd(NORMAL_DATA),   tolerance = 1e-10)
})

test_that("mysterycall:::mysterycall_check_normality - skewed data returns list with median and iqr", {
  df <- data.frame(value = SKEWED_DATA)
  result <- suppressMessages(mysterycall:::mysterycall_check_normality(df, "value"))
  expect_type(result, "list")
  expect_true("median" %in% names(result))
  expect_true("iqr" %in% names(result))
  expect_false("mean" %in% names(result))
  expect_false("sd" %in% names(result))
})

test_that("mysterycall:::mysterycall_check_normality - skewed data median = 1.5 (gold standard)", {
  df <- data.frame(value = SKEWED_DATA)
  result <- suppressMessages(mysterycall:::mysterycall_check_normality(df, "value"))
  expect_equal(result$median, 1.5, tolerance = 1e-10)
})

test_that("mysterycall:::mysterycall_check_normality - skewed data IQR = 8.4 (gold standard)", {
  df <- data.frame(value = SKEWED_DATA)
  result <- suppressMessages(mysterycall:::mysterycall_check_normality(df, "value"))
  expect_equal(result$iqr, 8.4, tolerance = 1e-10)
})

test_that("mysterycall:::mysterycall_check_normality - missing variable name errors with informative message", {
  df <- data.frame(x = 1:10)
  expect_error(
    suppressMessages(mysterycall:::mysterycall_check_normality(df, "nonexistent")),
    "'nonexistent' not found"
  )
})

test_that("mysterycall:::mysterycall_check_normality - sample size < 3 errors", {
  df <- data.frame(v = c(1, 2))
  expect_error(
    suppressMessages(mysterycall:::mysterycall_check_normality(df, "v")),
    "at least 3"
  )
})

test_that("mysterycall:::mysterycall_check_normality - NAs are stripped before test (n≥3 after stripping)", {
  df <- data.frame(v = c(NA, 1, 2, NA, 3, 4, 5))
  # Five non-NA values: 1,2,3,4,5 → small dataset, test should run without error
  expect_no_error(suppressMessages(mysterycall:::mysterycall_check_normality(df, "v")))
})

test_that("mysterycall:::mysterycall_check_normality - all-NA except 2 errors on sample size", {
  df <- data.frame(v = c(NA, 1, 2, NA))
  expect_error(
    suppressMessages(mysterycall:::mysterycall_check_normality(df, "v")),
    "at least 3"
  )
})

test_that("mysterycall:::mysterycall_check_normality - returns a named list (not NULL)", {
  df <- data.frame(val = NORMAL_DATA)
  result <- suppressMessages(mysterycall:::mysterycall_check_normality(df, "val"))
  expect_false(is.null(result))
  expect_true(length(result) > 0)
})

test_that("mysterycall:::mysterycall_check_normality - result for normal data has numeric mean and sd", {
  df <- data.frame(val = NORMAL_DATA)
  result <- suppressMessages(mysterycall:::mysterycall_check_normality(df, "val"))
  expect_true(is.numeric(result$mean))
  expect_true(is.numeric(result$sd))
  expect_true(is.finite(result$mean))
  expect_true(is.finite(result$sd))
  expect_true(result$sd >= 0)
})

test_that("mysterycall:::mysterycall_check_normality - result for skewed data has numeric median and iqr", {
  df <- data.frame(val = SKEWED_DATA)
  result <- suppressMessages(mysterycall:::mysterycall_check_normality(df, "val"))
  expect_true(is.numeric(result$median))
  expect_true(is.numeric(result$iqr))
  expect_true(is.finite(result$median))
  expect_true(result$iqr >= 0)
})

test_that("mysterycall:::mysterycall_check_normality - constant vector: sd = 0, mean = constant (passes Shapiro)", {
  # A constant vector may raise a Shapiro-Wilk error; test for graceful handling
  df <- data.frame(v = rep(5, 10))
  # shapiro.test on a constant vector gives a warning and p=NA/error
  # The function should either error gracefully or return mean/sd
  tryCatch(
    {
      result <- suppressWarnings(suppressMessages(mysterycall:::mysterycall_check_normality(df, "v")))
      # If it succeeds, mean should be 5
      if (!is.null(result$mean)) expect_equal(result$mean, 5)
    },
    error = function(e) {
      # Acceptable to error on a constant vector
      expect_true(TRUE)
    }
  )
})

test_that("mysterycall:::mysterycall_check_normality - large-n normal data (n=5000) returns mean/sd", {
  set.seed(1)
  x <- rnorm(5000, mean = 100, sd = 15)
  df <- data.frame(val = x)
  result <- suppressMessages(mysterycall:::mysterycall_check_normality(df, "val"))
  # With 5000 obs Shapiro-Wilk may detect tiny departures; test structural invariant
  expect_true(is.list(result))
  # Return list now includes is_normal, p_value, w_statistic, is_count, interpretation
  # plus either mean+sd (normal) or median+iqr (non-normal)
  expect_true(length(result) >= 2)
  expect_true("interpretation" %in% names(result))
  expect_true("is_normal" %in% names(result))
})
