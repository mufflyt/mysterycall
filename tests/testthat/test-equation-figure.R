# ── mysterycall_equation_figure ───────────────────────────────────────────────

test_that("equation_figure: returns ggplot object", {
  skip_if_not_installed("ggplot2")
  res <- mysterycall_equation_figure(lambda0 = 14, irr_seq = seq(1.1, 1.5, 0.1))
  expect_s3_class(res, "ggplot")
})

test_that("equation_figure: x-axis label mentions IRR", {
  skip_if_not_installed("ggplot2")
  res <- mysterycall_equation_figure(lambda0 = 14, irr_seq = c(1.2, 1.4, 1.6))
  expect_match(res$labels$x, "IRR", ignore.case = TRUE)
})

test_that("equation_figure: y-axis label mentions sample size", {
  skip_if_not_installed("ggplot2")
  res <- mysterycall_equation_figure(lambda0 = 14, irr_seq = c(1.2, 1.4, 1.6))
  expect_match(res$labels$y, "sample size", ignore.case = TRUE)
})

test_that("equation_figure: IRR=1 excluded from sequence errors on length-1 input", {
  # irr_seq must have at least 2 values; c(1.0) is too short
  expect_error(
    mysterycall_equation_figure(lambda0 = 14, irr_seq = c(1.0)),
    "at least 2"
  )
})

test_that("equation_figure: larger IRR → smaller required n", {
  skip_if_not_installed("ggplot2")
  n_small <- mysterycall_poisson_power(1.2, 14)$n_per_arm
  n_large <- mysterycall_poisson_power(1.8, 14)$n_per_arm
  expect_gt(n_small, n_large)
})

test_that("equation_figure: non-numeric irr_seq errors", {
  expect_error(mysterycall_equation_figure(irr_seq = "fast"), "numeric")
})

test_that("equation_figure: two valid IRRs → ggplot (no error)", {
  skip_if_not_installed("ggplot2")
  res <- suppressMessages(mysterycall_equation_figure(lambda0 = 14, irr_seq = c(1.2, 1.5)))
  expect_s3_class(res, "ggplot")
})
