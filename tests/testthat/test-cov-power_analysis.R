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


# =============================================================================
# Tests for mysterycall_cochran_n
# =============================================================================

test_that("mysterycall_cochran_n: happy path with defaults", {
  result <- mysterycall_cochran_n(N = 369)
  expect_type(result, "list")
  expect_named(result, c("n", "N", "margin_of_error", "effective_margin"))
  expect_type(result$n, "integer")
  expect_type(result$N, "double")
  expect_type(result$margin_of_error, "double")
  expect_type(result$effective_margin, "double")
  expect_true(result$n > 0)
  expect_equal(result$N, 369)
  expect_equal(result$margin_of_error, 0.05)
})

test_that("mysterycall_cochran_n: custom margin of error", {
  result <- mysterycall_cochran_n(N = 215, margin_of_error = 0.10)
  expect_type(result, "list")
  expect_true(result$n >= 1)
  expect_equal(result$margin_of_error, 0.10)
  # With larger margin of error, sample size should be smaller
  result_5pct <- mysterycall_cochran_n(N = 215, margin_of_error = 0.05)
  expect_true(result$n < result_5pct$n)
})

test_that("mysterycall_cochran_n: boundary cases", {
  # Very small N
  result_small <- mysterycall_cochran_n(N = 1)
  expect_true(result_small$n >= 1)

  # Large N
  result_large <- mysterycall_cochran_n(N = 10000)
  expect_true(result_large$n > 0)
  expect_true(result_large$n < 10000)

  # Very small margin of error
  result_tight <- mysterycall_cochran_n(N = 100, margin_of_error = 0.001)
  expect_true(result_tight$n > 0)
})

test_that("mysterycall_cochran_n: rejects invalid N", {
  expect_error(mysterycall_cochran_n(N = 0), "`N` must be a single positive number")
  expect_error(mysterycall_cochran_n(N = -1), "`N` must be a single positive number")
  expect_error(mysterycall_cochran_n(N = "abc"), "`N` must be a single positive number")
  expect_error(mysterycall_cochran_n(N = c(100, 200)), "`N` must be a single positive number")
})

test_that("mysterycall_cochran_n: rejects invalid margin_of_error", {
  expect_error(mysterycall_cochran_n(N = 100, margin_of_error = 0),
               "`margin_of_error` must be a single number strictly between 0 and 1")
  expect_error(mysterycall_cochran_n(N = 100, margin_of_error = 1),
               "`margin_of_error` must be a single number strictly between 0 and 1")
  expect_error(mysterycall_cochran_n(N = 100, margin_of_error = -0.05),
               "`margin_of_error` must be a single number strictly between 0 and 1")
  expect_error(mysterycall_cochran_n(N = 100, margin_of_error = 1.5),
               "`margin_of_error` must be a single number strictly between 0 and 1")
})


# =============================================================================
# Tests for mysterycall_poisson_power
# =============================================================================

test_that("mysterycall_poisson_power: happy path", {
  result <- suppressMessages(mysterycall_poisson_power(irr = 1.40, lambda_ref = 14))
  expect_type(result, "list")
  expect_named(result, c("n_per_arm", "n_total", "n_total_calls", "irr",
                         "lambda_ref", "lambda_trt", "alpha", "power", "design_effect"))
  expect_type(result$n_per_arm, "integer")
  expect_type(result$n_total, "integer")
  expect_type(result$n_total_calls, "integer")
  expect_true(result$n_per_arm > 0)
  expect_equal(result$irr, 1.40)
  expect_equal(result$lambda_ref, 14)
  expect_equal(result$lambda_trt, 1.40 * 14)
})

test_that("mysterycall_poisson_power: both_arms = FALSE requires more providers", {
  result_paired <- suppressMessages(
    mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, both_arms = TRUE)
  )
  result_unpaired <- suppressMessages(
    mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, both_arms = FALSE)
  )
  expect_true(result_unpaired$n_total > result_paired$n_total)
})

test_that("mysterycall_poisson_power: higher power requires larger n", {
  result_80 <- suppressMessages(
    mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, power = 0.80)
  )
  result_90 <- suppressMessages(
    mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, power = 0.90)
  )
  expect_true(result_90$n_per_arm > result_80$n_per_arm)
})

test_that("mysterycall_poisson_power: icc inflation effect", {
  result_no_cluster <- suppressMessages(
    mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, icc = 0)
  )
  result_cluster <- suppressMessages(
    mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, icc = 0.10, calls_per_cluster = 4L)
  )
  expect_true(result_cluster$n_per_arm > result_no_cluster$n_per_arm)
  expect_equal(result_cluster$design_effect, 1 + (4 - 1) * 0.10)
})

test_that("mysterycall_poisson_power: rejects invalid irr", {
  expect_error(mysterycall_poisson_power(irr = 1, lambda_ref = 14),
               "`irr` must be a single positive number not equal to 1")
  expect_error(mysterycall_poisson_power(irr = 0, lambda_ref = 14),
               "`irr` must be a single positive number not equal to 1")
  expect_error(mysterycall_poisson_power(irr = -1.5, lambda_ref = 14),
               "`irr` must be a single positive number not equal to 1")
})

test_that("mysterycall_poisson_power: rejects invalid lambda_ref", {
  expect_error(mysterycall_poisson_power(irr = 1.40, lambda_ref = 0),
               "`lambda_ref` must be a single positive number")
  expect_error(mysterycall_poisson_power(irr = 1.40, lambda_ref = -5),
               "`lambda_ref` must be a single positive number")
})

test_that("mysterycall_poisson_power: rejects invalid alpha", {
  expect_error(suppressMessages(mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, alpha = 0)),
               "`alpha` must be a single number in \\(0, 1\\)")
  expect_error(suppressMessages(mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, alpha = 1)),
               "`alpha` must be a single number in \\(0, 1\\)")
})

test_that("mysterycall_poisson_power: rejects invalid power", {
  expect_error(suppressMessages(mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, power = 0)),
               "`power` must be a single number in \\(0, 1\\)")
  expect_error(suppressMessages(mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, power = 1)),
               "`power` must be a single number in \\(0, 1\\)")
})

test_that("mysterycall_poisson_power: rejects invalid icc", {
  expect_error(suppressMessages(mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, icc = -0.05)),
               "`icc` must be a single number in \\[0, 1\\)")
  expect_error(suppressMessages(mysterycall_poisson_power(irr = 1.40, lambda_ref = 14, icc = 1)),
               "`icc` must be a single number in \\[0, 1\\)")
})


# =============================================================================
# Tests for mysterycall_equation_figure
# =============================================================================

test_that("mysterycall_equation_figure: happy path", {
  skip_if_not_installed("ggplot2")
  result <- suppressMessages(
    mysterycall_equation_figure(lambda0 = 14, irr_seq = seq(1.1, 1.8, 0.1))
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_equation_figure: returns ggplot with correct structure", {
  skip_if_not_installed("ggplot2")
  result <- suppressMessages(
    mysterycall_equation_figure(lambda0 = 10, irr_seq = seq(1.1, 2.0, 0.2))
  )
  expect_s3_class(result, "ggplot")
  expect_true("ggplot" %in% class(result))
})

test_that("mysterycall_equation_figure: filters out IRR = 1", {
  skip_if_not_installed("ggplot2")
  # irr_seq includes 1, but function should filter it out
  result <- suppressMessages(
    mysterycall_equation_figure(lambda0 = 14, irr_seq = c(0.5, 1.0, 1.5, 2.0))
  )
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_equation_figure: rejects empty irr_seq", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_equation_figure(irr_seq = numeric(0)),
    "`irr_seq` must be a numeric vector with at least 2 values"
  )
})

test_that("mysterycall_equation_figure: rejects single-value irr_seq", {
  skip_if_not_installed("ggplot2")
  expect_error(
    mysterycall_equation_figure(irr_seq = c(1.5)),
    "`irr_seq` must be a numeric vector with at least 2 values"
  )
})

test_that("mysterycall_equation_figure: requires ggplot2", {
  skip("ggplot2 always available in CI — cannot test missing-package error path")
})


# =============================================================================
# Tests for mysterycall_power_calc
# =============================================================================

test_that("mysterycall_power_calc: happy path with p1 and p2", {
  result <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50))
  expect_type(result, "list")
  expect_named(result, c("n_simple", "n_adjusted", "vif", "p1", "p2", "alpha",
                         "power", "icc", "m", "message"))
  expect_type(result$n_simple, "integer")
  expect_type(result$n_adjusted, "integer")
  expect_type(result$vif, "double")
  expect_type(result$message, "character")
  expect_true(result$n_simple > 0)
  expect_true(result$n_adjusted > 0)
  expect_true(result$vif >= 1)
})

test_that("mysterycall_power_calc: with custom clustering parameters", {
  result <- suppressMessages(
    mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0.15, m = 6)
  )
  expect_type(result, "list")
  expected_vif <- 1 + (6 - 1) * 0.15
  expect_equal(result$vif, expected_vif)
  expect_true(result$n_adjusted >= result$n_simple)
})

test_that("mysterycall_power_calc: higher power requires larger n", {
  result_80 <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, power = 0.80))
  result_90 <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, power = 0.90))
  expect_true(result_90$n_simple >= result_80$n_simple)
})

test_that("mysterycall_power_calc: back-calculate power with supplied n", {
  n_val <- 100
  result <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, n = n_val))
  expect_type(result, "list")
  expect_equal(result$n_simple, as.integer(ceiling(n_val)))
  expect_type(result$power, "double")
  expect_true(result$power > 0 && result$power < 1)
})

test_that("mysterycall_power_calc: clustering adjustment with icc > 0", {
  result_no_cluster <- suppressMessages(
    mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0)
  )
  result_cluster <- suppressMessages(
    mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0.10, m = 4)
  )
  # With clustering, adjusted n should be larger
  expect_true(result_cluster$n_adjusted >= result_cluster$n_simple)
  expect_true(result_cluster$n_adjusted > result_no_cluster$n_simple)
})

test_that("mysterycall_power_calc: rejects invalid p1", {
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0, p2 = 0.5)),
               "`p1` must be a single number in \\(0, 1\\)")
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 1, p2 = 0.5)),
               "`p1` must be a single number in \\(0, 1\\)")
  expect_error(suppressMessages(mysterycall_power_calc(p1 = -0.1, p2 = 0.5)),
               "`p1` must be a single number in \\(0, 1\\)")
})

test_that("mysterycall_power_calc: rejects invalid p2", {
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0)),
               "`p2` must be a single number in \\(0, 1\\) or NULL")
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 1)),
               "`p2` must be a single number in \\(0, 1\\) or NULL")
})

test_that("mysterycall_power_calc: rejects p1 == p2", {
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.70)),
               "`p1` and `p2` must differ")
})

test_that("mysterycall_power_calc: rejects missing both p2 and n", {
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70)),
               "Either `p2` or `n` must be non-NULL")
})

test_that("mysterycall_power_calc: rejects when n provided but p2 missing", {
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, n = 100)),
               "`p2` must be provided to compute power")
})

test_that("mysterycall_power_calc: rejects invalid icc", {
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = -0.05)),
               "`icc` must be a single number in \\[0, 1\\)")
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 1)),
               "`icc` must be a single number in \\[0, 1\\)")
})

test_that("mysterycall_power_calc: rejects invalid m", {
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, m = 0)),
               "`m` must be a single number >= 1")
})

test_that("mysterycall_power_calc: rejects invalid alpha", {
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, alpha = 0)),
               "`alpha` must be a single number in \\(0, 1\\)")
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, alpha = 1)),
               "`alpha` must be a single number in \\(0, 1\\)")
})

test_that("mysterycall_power_calc: rejects invalid power", {
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, power = 0)),
               "`power` must be a single number in \\(0, 1\\)")
  expect_error(suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, power = 1)),
               "`power` must be a single number in \\(0, 1\\)")
})
