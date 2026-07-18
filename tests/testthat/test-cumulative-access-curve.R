# Tests for mysterycall_cumulative_access_curve()

curve_data <- function() {
  data.frame(
    wait_days = c(5, 12, NA, 30, 8, NA, 45, 20),
    offered   = c(1, 1, 0, 1, 1, 0, 1, 1),
    group     = rep(c("A", "B"), each = 4),
    stringsAsFactors = FALSE
  )
}

test_that("plateau equals each group's offer rate", {
  d <- curve_data()
  res <- mysterycall_cumulative_access_curve(d, "wait_days", "offered", "group",
                                             horizon = 60)
  expect_s3_class(res, "mysterycall_cumulative_access_curve")
  # group A: 3 of 4 offered; group B: 3 of 4 offered
  expect_equal(res$plateau$offer_rate, c(0.75, 0.75))
  # final day of each curve equals the plateau
  last <- res$table[res$table$day == 60, ]
  expect_equal(sort(last$p), c(0.75, 0.75))
})

test_that("curve is monotone non-decreasing and starts at/near 0", {
  d <- curve_data()
  res <- mysterycall_cumulative_access_curve(d, "wait_days", "offered", "group",
                                             horizon = 60)
  for (g in unique(res$table$group)) {
    p <- res$table$p[res$table$group == g]
    expect_true(all(diff(p) >= 0))
    expect_equal(p[1], 0)                 # nobody has a wait <= 0 here
  }
})

test_that("cumulative proportion at day t counts waits <= t over the full group n", {
  d <- curve_data()
  res <- mysterycall_cumulative_access_curve(d, "wait_days", "offered", "group",
                                             horizon = 60)
  # group A waits (offered): 5, 12, 30 over n=4 -> by day 12, 2/4 = 0.5
  a12 <- res$table$p[res$table$group == "A" & res$table$day == 12]
  expect_equal(a12, 0.5)
})

test_that("horizon caps waits: a wait beyond the horizon is not yet counted", {
  d <- data.frame(wait_days = c(100, 5), offered = c(1, 1))
  res <- mysterycall_cumulative_access_curve(d, "wait_days", "offered",
                                             horizon = 30)
  # only the wait of 5 is within horizon -> plateau at day 30 is 1/2
  expect_equal(res$table$p[res$table$day == 30], 0.5)
  # but offer rate (plateau field) is still 1.0 (both offered)
  expect_equal(res$plateau$offer_rate, 1)
})

test_that("single overall curve when group_col is NULL", {
  d <- curve_data()
  res <- mysterycall_cumulative_access_curve(d, "wait_days", "offered")
  expect_equal(nrow(res$plateau), 1L)
  expect_equal(res$plateau$group, "All")
})

test_that("offered accepts TRUE/FALSE and character forms", {
  d <- data.frame(
    wait_days = c(5, 10, 20),
    offered   = c("TRUE", "FALSE", "TRUE"),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_cumulative_access_curve(d, "wait_days", "offered",
                                             horizon = 30)
  expect_equal(res$plateau$offer_rate, 2 / 3)
})

test_that("as.data.frame returns the tidy table and CSV export works", {
  d <- curve_data()
  dir <- withr::local_tempdir()
  res <- mysterycall_cumulative_access_curve(
    d, "wait_days", "offered", "group", horizon = 30,
    output_dir = dir, filename = "curve.csv")
  expect_s3_class(as.data.frame(res), "data.frame")
  expect_true(file.exists(file.path(dir, "curve.csv")))
})

test_that("plot = TRUE attaches a ggplot", {
  skip_if_not_installed("ggplot2")
  d <- curve_data()
  res <- mysterycall_cumulative_access_curve(d, "wait_days", "offered", "group",
                                             plot = TRUE)
  expect_s3_class(res$plot, "ggplot")
})
