skip_if_not_installed("effects")
skip_if_not_installed("ggplot2")
skip_if_not_installed("sjPlot")

# ── mysterycall_plot_effect ───────────────────────────────────────────────────

test_that("plot_effect: returns ggplot for lm model", {
  m   <- lm(mpg ~ wt + hp, data = mtcars)
  out <- mysterycall_plot_effect(m, "wt")
  expect_s3_class(out, "ggplot")
})

test_that("plot_effect: respects custom axis labels", {
  m   <- lm(mpg ~ wt, data = mtcars)
  out <- mysterycall_plot_effect(m, "wt", x_label = "Weight (1000 lbs)", y_label = "MPG")
  expect_s3_class(out, "ggplot")
  expect_equal(out$labels$x, "Weight (1000 lbs)")
  expect_equal(out$labels$y, "MPG")
})

test_that("plot_effect: link type label differs from response", {
  m       <- glm(am ~ wt, data = mtcars, family = binomial())
  out_resp <- mysterycall_plot_effect(m, "wt", type = "response")
  out_link <- mysterycall_plot_effect(m, "wt", type = "link")
  expect_equal(out_resp$labels$y, "Predicted response")
  expect_equal(out_link$labels$y, "Linear predictor")
})

test_that("plot_effect: type is passed to data extraction (BUG 41)", {
  set.seed(1)
  d <- data.frame(y = rpois(60, 4), x = rnorm(60))
  m <- glm(y ~ x, data = d, family = poisson())
  out_resp <- mysterycall_plot_effect(m, "x", type = "response")
  out_link <- mysterycall_plot_effect(m, "x", type = "link")

  # Link-scale fit must be the log of the response-scale fit for a Poisson
  # model; if type were ignored the two would be identical (the bug).
  expect_false(isTRUE(all.equal(out_resp$data$fit, out_link$data$fit)))
  expect_equal(log(out_resp$data$fit), out_link$data$fit, tolerance = 1e-6)
})

test_that("plot_effect: rejects non-character term", {
  m <- lm(mpg ~ wt, data = mtcars)
  expect_error(mysterycall_plot_effect(m, 42), "single character")
})

test_that("plot_effect: surfaces effects::effect failure", {
  m <- lm(mpg ~ wt, data = mtcars)
  expect_error(mysterycall_plot_effect(m, "nonexistent_term"), "effects::effect")
})

# ── mysterycall_plot_sjplot_interaction ───────────────────────────────────────

test_that("plot_sjplot_interaction: returns ggplot for lm with interaction", {
  m   <- lm(mpg ~ wt * cyl, data = mtcars)
  out <- suppressMessages(suppressWarnings(
    mysterycall_plot_sjplot_interaction(m, terms = c("wt", "cyl"))
  ))
  expect_s3_class(out, "ggplot")
})

test_that("plot_sjplot_interaction: rejects empty terms", {
  m <- lm(mpg ~ wt, data = mtcars)
  expect_error(mysterycall_plot_sjplot_interaction(m, character(0)),
               "non-empty character")
})

test_that("plot_sjplot_interaction: rejects non-character terms", {
  m <- lm(mpg ~ wt, data = mtcars)
  expect_error(mysterycall_plot_sjplot_interaction(m, 1:2), "non-empty character")
})
