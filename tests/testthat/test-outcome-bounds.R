# Tests for mysterycall_outcome_bounds()

test_that("bounds match the hand-computed Manski interval", {
  d <- data.frame(
    offered = c(TRUE, FALSE, TRUE, NA, NA, TRUE, FALSE, NA))
  #  observed = 5 (rows 1,2,3,6,7); positives = 3; missing = 3; universe = 8
  res <- mysterycall_outcome_bounds(d, "offered")
  expect_s3_class(res, "mysterycall_outcome_bounds")
  expect_equal(res$n_universe, 8L)
  expect_equal(res$n_observed, 5L)
  expect_equal(res$n_missing, 3L)
  expect_equal(res$n_positive, 3L)
  expect_equal(res$complete_case_rate, 3 / 5)
  expect_equal(res$lower_bound, 3 / 8)          # all missing fail
  expect_equal(res$upper_bound, (3 + 3) / 8)    # all missing succeed
  expect_equal(res$bound_width, 3 / 8)
})

test_that("bounds bracket the complete-case rate", {
  d <- data.frame(offered = c(TRUE, TRUE, FALSE, NA, NA))
  res <- mysterycall_outcome_bounds(d, "offered")
  expect_true(res$lower_bound <= res$complete_case_rate)
  expect_true(res$upper_bound >= res$complete_case_rate)
})

test_that("an explicit observed column overrides NA-based detection", {
  # outcome present for all, but 'complete' marks two as unobserved
  d <- data.frame(
    offered  = c(TRUE, FALSE, TRUE, TRUE, FALSE),
    complete = c("Y", "Y", "Y", "N", "N"))
  res <- mysterycall_outcome_bounds(d, "offered", observed = "complete")
  expect_equal(res$n_observed, 3L)
  expect_equal(res$n_missing, 2L)
  expect_equal(res$n_positive, 2L)              # rows 1,3 are observed positives
})

test_that("a logical observed vector is accepted", {
  d <- data.frame(offered = c(TRUE, FALSE, TRUE, TRUE))
  res <- mysterycall_outcome_bounds(d, "offered",
                                    observed = c(TRUE, TRUE, FALSE, FALSE))
  expect_equal(res$n_observed, 2L)
  expect_equal(res$n_positive, 1L)
})

test_that("Wilson CI on the complete-case rate is present and ordered", {
  d <- data.frame(offered = c(rep(TRUE, 7), rep(FALSE, 3), NA, NA))
  res <- mysterycall_outcome_bounds(d, "offered")
  expect_true(res$cc_ci_lower <= res$complete_case_rate)
  expect_true(res$cc_ci_upper >= res$complete_case_rate)
})

test_that("no missing data gives zero-width bounds equal to the rate", {
  d <- data.frame(offered = c(TRUE, FALSE, TRUE, TRUE))
  res <- mysterycall_outcome_bounds(d, "offered")
  expect_equal(res$bound_width, 0)
  expect_equal(res$lower_bound, res$upper_bound)
  expect_equal(res$lower_bound, 0.75)
})

test_that("character/1-0 positive values are matched", {
  d <- data.frame(offered = c("TRUE", "FALSE", "TRUE", NA))
  res <- mysterycall_outcome_bounds(d, "offered", positive_values = c(TRUE, "TRUE"))
  expect_equal(res$n_positive, 2L)
})

test_that("as.data.frame returns a one-row tibble", {
  d <- data.frame(offered = c(TRUE, FALSE, NA))
  df <- as.data.frame(mysterycall_outcome_bounds(d, "offered"))
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 1L)
})
