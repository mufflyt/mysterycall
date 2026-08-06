library(testthat)

# Regression tests for BUGS.md item 46: the wait-time unit label must follow the
# fitted scale (log1p(days) under a log transform, else raw days) and must be the
# SAME in print() and plot() (previously plot() hardcoded "days").

test_that(".lmm_time_unit switches on log_transformed", {
  expect_equal(mysterycall:::.lmm_time_unit(TRUE),  "log1p(days)")
  expect_equal(mysterycall:::.lmm_time_unit(FALSE), "days")
  expect_equal(mysterycall:::.lmm_time_unit(NA),    "days")   # non-TRUE -> days
  expect_equal(mysterycall:::.lmm_time_unit(NULL),  "days")
})

test_that("lmm print and plot report raw 'days' units for an untransformed fit", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("ggplot2")
  set.seed(1)
  df <- data.frame(
    wait_days = c(rpois(20, 6), rpois(20, 9)),
    insurance = rep(c("A", "B"), each = 20),
    physician = factor(rep(1:20, times = 2))          # each physician: one A, one B
  )
  fit <- suppressWarnings(suppressMessages(
    mysterycall_lmm(df, "wait_days", "insurance", "physician", auto_log = FALSE)))
  expect_false(fit$log_transformed)

  out <- paste(utils::capture.output(print(fit)), collapse = "\n")
  expect_match(out, "Residual SD = .* days")
  expect_no_match(out, "log1p")

  skip_if_not_installed("patchwork")
  p <- suppressWarnings(suppressMessages(plot(fit)))
  # residuals-vs-fitted is the second panel; its units must match print()
  expect_equal(p[[2]]$labels$y, "Residuals (days)")
  expect_equal(p[[2]]$labels$x, "Fitted values (days)")
})
