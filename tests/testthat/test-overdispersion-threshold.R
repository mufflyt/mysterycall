library(testthat)

# ─────────────────────────────────────────────────────────────────────────────
# INVARIANT: one overdispersion threshold, used everywhere.
# Every Poisson-vs-NB decision routes through
# mysterycall_overdispersion_threshold() so the automated selector and the
# standalone diagnostics can never again disagree on the same phi.
# ─────────────────────────────────────────────────────────────────────────────

test_that("the shared threshold defaults to 1.5 and validates the option", {
  expect_equal(mysterycall_overdispersion_threshold(), 1.5)
  withr::with_options(
    list(mysterycall.overdispersion_threshold = 2.0),
    expect_equal(mysterycall_overdispersion_threshold(), 2.0)
  )
  withr::with_options(
    list(mysterycall.overdispersion_threshold = -1),
    expect_error(mysterycall_overdispersion_threshold(), "positive number")
  )
})

test_that("auto_model and marginal_power default their phi cutoffs to the shared value", {
  # Defaults are calls to the accessor, so they track the option live.
  expect_equal(eval(formals(mysterycall_auto_model)$phi_threshold), 1.5)
  expect_equal(eval(formals(mysterycall_marginal_power)$disp_threshold), 1.5)

  withr::with_options(
    list(mysterycall.overdispersion_threshold = 2.0),
    {
      expect_equal(eval(formals(mysterycall_auto_model)$phi_threshold), 2.0)
      expect_equal(eval(formals(mysterycall_marginal_power)$disp_threshold), 2.0)
    }
  )
})

test_that("poisson_model warns for overdispersion above, but not below, the shared threshold", {
  skip_if_not_installed("lme4")
  set.seed(42)
  # Build an overdispersed count outcome (phi well above 1.5).
  n  <- 200
  gp <- factor(rep(seq_len(50), each = 4))
  df <- data.frame(
    y     = rnbinom(n, mu = 6, size = 0.6),   # strong overdispersion
    x     = rnorm(n),
    group = gp
  )
  expect_warning(
    suppressMessages(mysterycall_poisson_model(df, "y", "x", "group")),
    regexp = "Overdispersion detected"
  )

  # An equidispersed Poisson outcome (phi ~ 1) must NOT warn.
  set.seed(7)
  df2 <- data.frame(
    y     = rpois(n, lambda = 5),
    x     = rnorm(n),
    group = gp
  )
  expect_no_warning(
    suppressMessages(mysterycall_poisson_model(df2, "y", "x", "group"))
  )
})
