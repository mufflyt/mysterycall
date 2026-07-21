# Tests for mysterycall_ttest_power and mysterycall_lm_interaction_power

test_that("ttest_power equal allocation matches pwr.t.test directly", {
  skip_if_not_installed("pwr")
  res <- mysterycall_ttest_power(mde = 5, sd = 12, group_frac = 0.5)
  d <- 5 / 12
  expect_equal(res$cohens_d, round(d, 3))
  n <- ceiling(pwr::pwr.t.test(d = d, sig.level = 0.05, power = 0.80,
                               type = "two.sample")$n)
  expect_equal(res$n_per_group_equal, n)
  expect_equal(res$equal_total_n, 2L * n)
})

test_that("unequal allocation needs a larger total than equal", {
  skip_if_not_installed("pwr")
  res <- mysterycall_ttest_power(mde = 5, sd = 12, group_frac = 0.15)
  expect_gt(res$natural_total_n, res$equal_total_n)
  # smaller group really is ~15%
  expect_equal(res$natural_n_small / res$natural_total_n, 0.15, tolerance = 0.02)
})

test_that("ttest_power vectorizes over mde", {
  skip_if_not_installed("pwr")
  res <- mysterycall_ttest_power(mde = c(3, 5, 7), sd = 12)
  expect_equal(nrow(res), 3L)
  # larger effect -> smaller required n
  expect_true(all(diff(res$n_per_group_equal) < 0))
})

test_that("lm_interaction_power returns an N column per f2 level", {
  skip_if_not_installed("pwr")
  res <- mysterycall_lm_interaction_power(
    terms = c("rural" = 1, "subspecialty" = 6, "rural x insurance" = 1),
    n_params = 2 * 7 * 2
  )
  expect_equal(nrow(res), 3L)
  expect_true(all(c("n_small", "n_medium") %in% names(res)))
  # medium effect needs fewer subjects than small
  expect_true(all(res$n_medium < res$n_small))
})

test_that("lm_interaction_power accepts a data-frame term spec", {
  skip_if_not_installed("pwr")
  tdf <- data.frame(term = c("a", "b"), df_num = c(1L, 6L))
  res <- mysterycall_lm_interaction_power(tdf, n_params = 10)
  expect_equal(res$term, c("a", "b"))
  # higher numerator df needs a larger N at the same f2
  expect_gt(res$n_small[2], res$n_small[1])
})

test_that("bad inputs error", {
  skip_if_not_installed("pwr")
  expect_error(mysterycall_ttest_power(mde = -1, sd = 12))
  expect_error(mysterycall_lm_interaction_power(c(1, 2), n_params = 5))  # unnamed
})
