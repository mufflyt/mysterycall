# Tests for mysterycall_plot_raincloud and mysterycall_plot_paired_slope

rc_df <- function() {
  set.seed(1)
  data.frame(
    wait     = c(rpois(30, 10), rpois(30, 25)),
    scenario = rep(c("Commercial", "Medicaid"), each = 30),
    stringsAsFactors = FALSE
  )
}

pair_df <- function() {
  set.seed(2)
  data.frame(
    practice = rep(1:15, each = 2),
    scenario = rep(c("Commercial", "Medicaid"), 15),
    wait     = c(rbind(rpois(15, 10), rpois(15, 22))),
    stringsAsFactors = FALSE
  )
}

test_that("raincloud returns a ggplot with violin/box/point/text layers", {
  skip_if_not_installed("ggplot2")
  p <- mysterycall_plot_raincloud(rc_df(), "wait", "scenario")
  expect_s3_class(p, "ggplot")
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomViolin" %in% geoms)
  expect_true("GeomBoxplot" %in% geoms)
  expect_true(any(geoms %in% c("GeomPoint", "GeomJitter")))
  expect_true("GeomText" %in% geoms)  # median labels on by default
})

test_that("raincloud can suppress median labels", {
  skip_if_not_installed("ggplot2")
  p <- mysterycall_plot_raincloud(rc_df(), "wait", "scenario",
                                  add_median_labels = FALSE)
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_false("GeomText" %in% geoms)
})

test_that("raincloud rejects a non-numeric value column", {
  skip_if_not_installed("ggplot2")
  d <- rc_df(); d$wait <- as.character(d$wait)
  expect_error(mysterycall_plot_raincloud(d, "wait", "scenario"), "numeric")
})

test_that("paired slope returns a ggplot with line + point layers", {
  skip_if_not_installed("ggplot2")
  p <- mysterycall_plot_paired_slope(pair_df(), "wait", "scenario", "practice")
  expect_s3_class(p, "ggplot")
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], character(1))
  expect_true("GeomLine" %in% geoms)
  expect_true("GeomPoint" %in% geoms)
})

test_that("paired slope drops single-scenario clusters and errors if none pair", {
  skip_if_not_installed("ggplot2")
  # every practice has only one scenario -> nothing to pair
  d <- data.frame(practice = 1:6,
                  scenario = rep(c("A", "B"), 3),
                  wait = 1:6)
  d$practice <- seq_len(nrow(d))  # all unique ids, each 1 row
  expect_error(
    mysterycall_plot_paired_slope(d, "wait", "scenario", "practice"),
    "two or more scenarios"
  )
})

test_that("paired slope keeps only 2+-scenario clusters in plotted data", {
  skip_if_not_installed("ggplot2")
  d <- rbind(pair_df(),
             data.frame(practice = 99, scenario = "Commercial", wait = 5))
  p <- mysterycall_plot_paired_slope(d, "wait", "scenario", "practice")
  expect_false(99 %in% p$data$practice)  # singleton dropped
})
