# Tests for mysterycall_marginal_power()

test_that("returns structured power table with values in [0, 1]", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("marginaleffects")
  res <- mysterycall_marginal_power(
    n_subject = c(80, 160),
    cell_means = c(14, 18, 17, 24),
    sigma_subject = 0.4, phi = 1.7,
    stratum_sampling = 0.5, pop_stratum = 0.15,
    n_sim = 10, seed = 1)
  expect_s3_class(res, "mysterycall_marginal_power")
  expect_equal(nrow(res$table), 2L)
  for (col in c("pow_cond_interaction", "pow_marg_unweighted",
                "pow_marg_popweighted")) {
    expect_true(all(res$table[[col]] >= 0 & res$table[[col]] <= 1))
  }
  expect_equal(res$table$n_calls, res$table$n_subject * 2L)
})

test_that("the true marginal effect matches the post-stratification formula", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("marginaleffects")
  # pop-weighted: 0.15*(24-17) + 0.85*(18-14) = 1.05 + 3.4 = 4.45
  res <- mysterycall_marginal_power(
    n_subject = 60, cell_means = c(14, 18, 17, 24),
    sigma_subject = 0.3, phi = 1.7,
    stratum_sampling = 0.5, pop_stratum = 0.15,
    n_sim = 5, seed = 2)
  expect_equal(res$truth, 0.15 * (24 - 17) + 0.85 * (18 - 14))
})

test_that("seed makes it reproducible", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("marginaleffects")
  args <- list(n_subject = 80, cell_means = c(14, 18, 17, 24),
               sigma_subject = 0.4, phi = 1.7, stratum_sampling = 0.5,
               pop_stratum = 0.2, n_sim = 8, seed = 99)
  a <- do.call(mysterycall_marginal_power, args)
  b <- do.call(mysterycall_marginal_power, args)
  expect_identical(a$table, b$table)
})

test_that("mean population-weighted estimate tracks the true marginal effect", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("marginaleffects")
  res <- mysterycall_marginal_power(
    n_subject = 400, cell_means = c(14, 18, 17, 24),
    sigma_subject = 0.4, phi = 1.7,
    stratum_sampling = 0.5, pop_stratum = 0.15,
    n_sim = 25, seed = 5)
  # estimate should be within a reasonable band of the truth (4.45 days)
  expect_equal(res$table$mean_marg_pop_est, res$truth, tolerance = 2)
})

test_that("cell_means must have length 4", {
  expect_error(
    mysterycall_marginal_power(
      n_subject = 80, cell_means = c(14, 18, 17),
      sigma_subject = 0.4, phi = 1.7,
      stratum_sampling = 0.5, pop_stratum = 0.15, n_sim = 5),
    "length 4|len"
  )
})

test_that("as.data.frame returns the table", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("marginaleffects")
  res <- mysterycall_marginal_power(
    n_subject = 60, cell_means = c(14, 18, 17, 24),
    sigma_subject = 0.3, phi = 1.7,
    stratum_sampling = 0.5, pop_stratum = 0.15, n_sim = 5, seed = 3)
  expect_s3_class(as.data.frame(res), "data.frame")
})
