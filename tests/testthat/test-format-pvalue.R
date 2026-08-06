library(testthat)

# .mc_format_p is the single source of truth for p-value strings. It emits the
# spaced canonical "< 0.001" below threshold, fixed-decimal otherwise, NA -> NA.

test_that(".mc_format_p emits the spaced canonical form", {
  expect_equal(mysterycall:::.mc_format_p(0.0005), "< 0.001")
  expect_equal(mysterycall:::.mc_format_p(0.0432), "0.043")
  expect_equal(mysterycall:::.mc_format_p(0.5),    "0.500")
  expect_true(is.na(mysterycall:::.mc_format_p(NA_real_)))
})

test_that(".mc_format_p is vectorised and NA-safe", {
  expect_equal(
    mysterycall:::.mc_format_p(c(0.0001, 0.5, NA_real_)),
    c("< 0.001", "0.500", NA_character_)
  )
})

test_that(".mc_format_p threshold stays at 0.001; digits controls decimals only", {
  expect_equal(mysterycall:::.mc_format_p(0.0005, digits = 2), "< 0.001")
  expect_equal(mysterycall:::.mc_format_p(0.1234, digits = 2), "0.12")
})

test_that("the routed per-model formatters now emit the spaced canonical form", {
  # Previously these emitted the unspaced "<0.001"; all now share .mc_format_p.
  expect_equal(mysterycall:::.fmt_nb_pval(0.0004),    "< 0.001")
  expect_equal(mysterycall:::.fmt_model_pval(0.0004), "< 0.001")
  expect_equal(mysterycall:::.t1_fmt_pval(0.0004),    "< 0.001")
  expect_equal(mysterycall:::.fmt_pvalue(0.0004),     "< 0.001")
  # non-boundary values are unchanged
  expect_equal(mysterycall:::.fmt_nb_pval(0.0321),    "0.032")
})
