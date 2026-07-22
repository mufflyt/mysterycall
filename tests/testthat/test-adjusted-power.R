# Tests for mysterycall_adjusted_power

test_that("returns a one-row tibble with the documented columns", {
  skip_if_not_installed("glmmTMB")
  res <- mysterycall_adjusted_power(
    n_total = 300, rural_frac = 0.2,
    wait_urban = 20, wait_rural = 30, phi = 1.7,
    state_icc = 0.05, n_sim = 8, seed = 1
  )
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1L)
  expect_true(all(c("power", "mean_log_effect", "sigma_state",
                    "convergence_rate", "n_rural", "n_urban") %in% names(res)))
  expect_true(res$power >= 0 && res$power <= 1)
})

test_that("ICC -> sigma mapping is correct", {
  skip_if_not_installed("glmmTMB")
  res <- mysterycall_adjusted_power(
    n_total = 120, rural_frac = 0.25,
    wait_urban = 20, wait_rural = 20, phi = 1.7,
    state_icc = 0.10, n_sim = 3, seed = 2
  )
  # Inverts the same latent-scale decomposition as mysterycall_icc(): for the NB
  # model the level-1 variance is trigamma(1/phi) + pi^2/3, not 1/phi.
  expect_equal(
    res$sigma_state,
    sqrt(0.10 / 0.90 * (psigamma(1 / 1.7, deriv = 1L) + pi^2 / 3)),
    tolerance = 1e-9
  )
})

test_that("seed makes the simulation reproducible", {
  skip_if_not_installed("glmmTMB")
  a <- mysterycall_adjusted_power(200, 0.2, 20, 28, 1.7, n_sim = 5, seed = 42)
  b <- mysterycall_adjusted_power(200, 0.2, 20, 28, 1.7, n_sim = 5, seed = 42)
  expect_equal(a$power, b$power)
  expect_equal(a$mean_log_effect, b$mean_log_effect)
})

test_that("n_rural + n_urban equals n_total", {
  skip_if_not_installed("glmmTMB")
  res <- mysterycall_adjusted_power(250, 0.3, 20, 25, 1.7, n_sim = 3, seed = 1)
  expect_equal(res$n_rural + res$n_urban, 250)
})

test_that("bad inputs error via checkmate", {
  expect_error(mysterycall_adjusted_power(300, 1.5, 20, 30, 1.7))   # rural_frac
  expect_error(mysterycall_adjusted_power(300, 0.2, 20, 30, 1.7,
                                          state_icc = 0.95))        # icc range
})
