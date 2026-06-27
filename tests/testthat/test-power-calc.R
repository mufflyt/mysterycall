test_that("mysterycall_power_calc returns a list with all required elements", {
  res <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50))
  expect_true(is.list(res))
  expect_true(all(c("n_simple", "n_adjusted", "vif", "message") %in% names(res)))
})

test_that("n_adjusted is always >= n_simple (clustering inflates sample size)", {
  res <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0.10, m = 4))
  expect_gte(res$n_adjusted, res$n_simple)
})

test_that("VIF is computed as 1 + (m - 1) * icc", {
  res <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0.10, m = 5))
  expect_equal(res$vif, 1 + (5 - 1) * 0.10)

  res2 <- suppressMessages(mysterycall_power_calc(p1 = 0.60, p2 = 0.40, icc = 0.20, m = 3))
  expect_equal(res2$vif, 1 + (3 - 1) * 0.20)
})

test_that("when icc = 0, vif = 1 and n_adjusted equals n_simple", {
  res <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0))
  expect_equal(res$vif, 1)
  expect_equal(res$n_adjusted, res$n_simple)
})

test_that("higher icc produces a strictly larger n_adjusted", {
  low  <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0.05, m = 4))
  high <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0.25, m = 4))
  expect_gt(high$n_adjusted, low$n_adjusted)
})

test_that("power is back-calculated when both n and p2 are provided", {
  res <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, n = 100))
  expect_true(is.numeric(res$power))
  expect_gt(res$power, 0)
  expect_lt(res$power, 1)
})

test_that("back-calculated power matches the manual pnorm formula", {
  p1 <- 0.70; p2 <- 0.50; n_val <- 100; alpha <- 0.05
  res <- suppressMessages(mysterycall_power_calc(p1 = p1, p2 = p2, n = n_val, alpha = alpha))
  pooled_var     <- p1 * (1 - p1) + p2 * (1 - p2)
  delta_sq       <- (p1 - p2)^2
  z_a2           <- stats::qnorm(1 - alpha / 2)
  expected_power <- stats::pnorm(sqrt(n_val * delta_sq / pooled_var) - z_a2)
  expect_equal(res$power, expected_power, tolerance = 1e-10)
})

test_that("errors when both p2 and n are NULL", {
  expect_error(
    mysterycall_power_calc(p1 = 0.70, p2 = NULL, n = NULL),
    regexp = "Either.*p2.*or.*n.*must be non-NULL",
    fixed  = FALSE
  )
})

test_that("errors when only n is supplied without p2", {
  expect_error(
    mysterycall_power_calc(p1 = 0.70, p2 = NULL, n = 100),
    regexp = "p2"
  )
})

test_that("errors when p1 is on or outside the boundary (0, 1)", {
  expect_error(mysterycall_power_calc(p1 = 0,    p2 = 0.50), regexp = "p1")
  expect_error(mysterycall_power_calc(p1 = 1,    p2 = 0.50), regexp = "p1")
  expect_error(mysterycall_power_calc(p1 = -0.1, p2 = 0.50), regexp = "p1")
  expect_error(mysterycall_power_calc(p1 = 1.5,  p2 = 0.50), regexp = "p1")
})

test_that("errors when icc is outside [0, 1)", {
  expect_error(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = -0.01), regexp = "icc")
  expect_error(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 1.0),   regexp = "icc")
  expect_error(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 2.0),   regexp = "icc")
})

test_that("message element is a single character string", {
  res <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50))
  expect_type(res$message, "character")
  expect_length(res$message, 1L)
  expect_gt(nchar(res$message), 0L)
})

test_that("n_adjusted is stored as an integer (ceiling applied)", {
  res <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50, icc = 0.07, m = 3))
  expect_true(is.integer(res$n_adjusted))
  # Verify ceiling relationship holds exactly
  expect_equal(res$n_adjusted, ceiling(res$n_simple * res$vif))
})

test_that("n_simple is stored as an integer", {
  res <- suppressMessages(mysterycall_power_calc(p1 = 0.70, p2 = 0.50))
  expect_true(is.integer(res$n_simple))
})

test_that("n_adjusted >= n_simple holds even when icc = 0 (no inflation)", {
  res <- suppressMessages(mysterycall_power_calc(p1 = 0.60, p2 = 0.40, icc = 0, m = 6))
  # With icc = 0 they should be equal, satisfying >=
  expect_gte(res$n_adjusted, res$n_simple)
  expect_equal(res$n_adjusted, res$n_simple)
})
