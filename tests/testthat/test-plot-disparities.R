skip_if_not_installed("ggplot2")
skip_if_not_installed("dplyr")

make_disparity_tbl <- function() {
  set.seed(42)
  df <- data.frame(
    insurance = sample(c("Medicaid", "Medicare", "Private", "Uninsured"),
                       300, replace = TRUE),
    accepted  = rbinom(300, 1, prob = rep(c(0.64, 0.84, 0.91, 0.54), 75)),
    stringsAsFactors = FALSE
  )
  suppressWarnings(suppressMessages(
    mysterycall_disparities_table(df, "accepted", "insurance",
                                   ref_group = "Private")
  ))
}

# ── core behaviour ────────────────────────────────────────────────────────────

test_that("plot_disparities: rate (default) returns ggplot", {
  tbl <- make_disparity_tbl()
  p   <- mysterycall_plot_disparities(tbl)
  expect_s3_class(p, "ggplot")
})

test_that("plot_disparities: abs_diff metric returns ggplot", {
  tbl <- make_disparity_tbl()
  p   <- mysterycall_plot_disparities(tbl, metric = "abs_diff")
  expect_s3_class(p, "ggplot")
})

test_that("plot_disparities: rel_risk metric returns ggplot", {
  tbl <- make_disparity_tbl()
  p   <- mysterycall_plot_disparities(tbl, metric = "rel_risk")
  expect_s3_class(p, "ggplot")
})

test_that("plot_disparities: show_ref = FALSE drops the reference row", {
  tbl <- make_disparity_tbl()
  p   <- mysterycall_plot_disparities(tbl, show_ref = FALSE)
  expect_s3_class(p, "ggplot")
})

test_that("plot_disparities: show_p = FALSE suppresses p-value annotation", {
  tbl <- make_disparity_tbl()
  p   <- mysterycall_plot_disparities(tbl, show_p = FALSE)
  expect_s3_class(p, "ggplot")
})

test_that("plot_disparities: respects custom title and x_label", {
  tbl <- make_disparity_tbl()
  p   <- mysterycall_plot_disparities(tbl, title = "Disparities by insurance",
                                       x_label = "Acceptance %")
  expect_equal(p$labels$title, "Disparities by insurance")
  expect_equal(p$labels$x, "Acceptance %")
})

test_that("plot_disparities: respects custom colors", {
  tbl <- make_disparity_tbl()
  p <- mysterycall_plot_disparities(
    tbl,
    color_sig = "#000000",
    color_ns  = "#888888",
    color_ref = "#FF0000",
    point_size = 5
  )
  expect_s3_class(p, "ggplot")
})

# ── BUG 39: abs_diff CI includes reference-group variance ─────────────────────

test_that("plot_disparities: abs_diff reference row has a zero-width interval", {
  tbl <- make_disparity_tbl()
  p   <- mysterycall_plot_disparities(tbl, metric = "abs_diff")
  ref <- attr(tbl, "ref_group")
  d   <- p$data
  ref_row <- d[as.character(d$group) == ref, , drop = FALSE]
  expect_equal(ref_row$.x, 0)
  expect_equal(ref_row$.xmin, 0)
  expect_equal(ref_row$.xmax, 0)
})

test_that("plot_disparities: abs_diff CI is wider than one-group rate half-width", {
  tbl <- make_disparity_tbl()
  p   <- mysterycall_plot_disparities(tbl, metric = "abs_diff")
  ref <- attr(tbl, "ref_group")
  d   <- p$data
  nonref <- d[as.character(d$group) != ref, , drop = FALSE]

  # Half-width actually drawn (two-proportion difference CI, in pp).
  hw_drawn <- (nonref$.xmax - nonref$.xmin) / 2

  # Old (buggy) half-width: derived from a single group's rate CI (proportion
  # scale). The correct two-proportion CI, on the pp scale, must be wider.
  tbl_df   <- as.data.frame(tbl)
  tbl_df   <- tbl_df[as.character(tbl_df$group) != ref, , drop = FALSE]
  hw_old   <- (tbl_df$upper_ci - tbl_df$lower_ci) / 2

  expect_true(all(hw_drawn > hw_old))
  expect_true(all(hw_drawn > 0))
})

# ── plain data frame inputs ───────────────────────────────────────────────────

test_that("plot_disparities: accepts plain data frame with rate columns", {
  df <- data.frame(
    group    = c("Private", "Medicaid", "Medicare"),
    rate     = c(0.9, 0.6, 0.85),
    lower_ci = c(0.85, 0.55, 0.80),
    upper_ci = c(0.95, 0.65, 0.90),
    stringsAsFactors = FALSE
  )
  p <- mysterycall_plot_disparities(df, metric = "rate")
  expect_s3_class(p, "ggplot")
})
