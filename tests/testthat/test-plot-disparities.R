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
