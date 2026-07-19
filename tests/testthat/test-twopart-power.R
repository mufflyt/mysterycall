# Tests for mysterycall_twopart_power(), _type_i_check(), _find_mde()

test_that("returns one row per sample size with power in [0, 1]", {
  skip_if_not_installed("MASS")
  res <- mysterycall_twopart_power(
    n_total = c(100, 200), offer_ref = 0.7, offer_trt = 0.5,
    wait_ref = 14, wait_trt = 21, phi = 1.7, n_sim = 20, seed = 1)
  expect_s3_class(res, "mysterycall_twopart_power")
  expect_equal(nrow(res$table), 2L)
  expect_true(all(res$table$pow_offer >= 0 & res$table$pow_offer <= 1))
  expect_true(all(res$table$pow_wait  >= 0 & res$table$pow_wait  <= 1))
  expect_equal(res$table$n_ref + res$table$n_trt, res$table$n_total)
})

test_that("seed makes the result reproducible", {
  skip_if_not_installed("MASS")
  a <- mysterycall_twopart_power(300, 0.7, 0.5, 14, 21, 1.7, n_sim = 15, seed = 42)
  b <- mysterycall_twopart_power(300, 0.7, 0.5, 14, 21, 1.7, n_sim = 15, seed = 42)
  expect_identical(a$table, b$table)
})

test_that("power increases with sample size for a fixed effect", {
  skip_if_not_installed("MASS")
  res <- mysterycall_twopart_power(
    n_total = c(60, 600), offer_ref = 0.75, offer_trt = 0.45,
    wait_ref = 12, wait_trt = 24, phi = 1.5, n_sim = 40, seed = 7)
  expect_gte(res$table$pow_offer[2], res$table$pow_offer[1])
  expect_gte(res$table$pow_wait[2],  res$table$pow_wait[1])
})

test_that("a large offer gap yields high offer power at a big sample", {
  skip_if_not_installed("MASS")
  res <- mysterycall_twopart_power(
    n_total = 800, offer_ref = 0.85, offer_trt = 0.40,
    wait_ref = 14, wait_trt = 14, phi = 1.7, n_sim = 40, seed = 3)
  expect_gt(res$table$pow_offer, 0.8)
})

test_that("a null offer effect gives offer power near alpha", {
  skip_if_not_installed("MASS")
  res <- mysterycall_twopart_power(
    n_total = 400, offer_ref = 0.6, offer_trt = 0.6,
    wait_ref = 14, wait_trt = 14, phi = 1.7, n_sim = 200, seed = 11)
  # rejection rate under the null should be in the neighbourhood of 0.05
  expect_lt(res$table$pow_offer, 0.20)
})

test_that("as.data.frame returns the table", {
  skip_if_not_installed("MASS")
  res <- mysterycall_twopart_power(200, 0.7, 0.5, 14, 21, 1.7, n_sim = 10, seed = 1)
  expect_s3_class(as.data.frame(res), "data.frame")
})

# ---- type I check -----------------------------------------------------------

test_that("type_i_check flags an anti-conservative simulator", {
  # 20/100 rejections under the null at alpha = 0.05 is clearly too many
  res <- mysterycall_type_i_check(20, n_sim = 100, alpha = 0.05)
  expect_false(res$alpha_in_ci)
  expect_match(res$verdict, "anti-conservative")
})

test_that("type_i_check accepts a well-calibrated rate", {
  res <- mysterycall_type_i_check(5, n_sim = 100, alpha = 0.05)
  expect_true(res$alpha_in_ci)
  expect_match(res$verdict, "consistent")
})

test_that("type_i_check accepts a rate input in [0,1]", {
  res <- mysterycall_type_i_check(0.05, n_sim = 100)
  expect_equal(res$rejection_rate, 0.05)
})

test_that("type_i_check errors when rejections exceed n_sim", {
  expect_error(mysterycall_type_i_check(150, n_sim = 100), "more rejections")
})

# ---- find_mde ---------------------------------------------------------------

test_that("find_mde bisects a monotone power function to the target", {
  # power crosses 0.9 at effect = 5 by construction
  pf <- function(e) stats::plogis((e - 5) * 3)   # ~0 below 5, ~1 above
  res <- mysterycall_find_mde(pf, lower = 0, upper = 10, target_power = 0.9,
                              tol = 0.05)
  expect_true(res$mde > 4.5 && res$mde < 6)
  expect_gte(res$power_at_mde, 0.9)
  expect_s3_class(res$history, "tbl_df")
})

test_that("find_mde returns NA with a warning when the bracket is too low", {
  pf <- function(e) 0.2                            # never reaches target
  expect_warning(res <- mysterycall_find_mde(pf, 0, 10, target_power = 0.9),
                 "below target")
  expect_true(is.na(res$mde))
})
