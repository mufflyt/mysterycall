# ── mysterycall_plot_emmeans_interaction ──────────────────────────────────────

test_that("plot_emmeans_interaction: errors without emmeans", {
  skip_if(requireNamespace("emmeans", quietly = TRUE),
          "emmeans is installed; skipping absence test")
  expect_error(
    mysterycall_plot_emmeans_interaction(lm(mpg ~ wt, mtcars), "wt", "MPG"),
    "emmeans"
  )
})

test_that("plot_emmeans_interaction: returns ggplot with emmeans installed", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")
  m   <- lm(mpg ~ factor(cyl) + wt, data = mtcars)
  res <- mysterycall_plot_emmeans_interaction(m, specs = "cyl", variable = "mpg")
  expect_s3_class(res, "ggplot")
})

test_that("plot_emmeans_interaction: two-spec version returns ggplot", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")
  mt  <- mtcars
  mt$cyl_f <- factor(mt$cyl)
  mt$am_f  <- factor(mt$am, labels = c("Auto","Manual"))
  m   <- lm(mpg ~ cyl_f * am_f, data = mt)
  res <- mysterycall_plot_emmeans_interaction(m, specs = c("cyl_f","am_f"),
                                               variable = "mpg")
  expect_s3_class(res, "ggplot")
})

test_that("plot_emmeans_interaction: use_color=FALSE returns ggplot", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")
  m   <- lm(mpg ~ factor(cyl), data = mtcars)
  res <- mysterycall_plot_emmeans_interaction(m, "cyl", "mpg", use_color = FALSE)
  expect_s3_class(res, "ggplot")
})

test_that("plot_emmeans_interaction: handles Poisson model on response scale (BUG 38)", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("ggplot2")
  set.seed(3)
  d <- data.frame(
    count = rpois(80, 5),
    grp   = factor(rep(c("a", "b"), each = 40L))
  )
  m   <- glm(count ~ grp, data = d, family = poisson())
  res <- mysterycall_plot_emmeans_interaction(m, specs = "grp", variable = "count")

  expect_s3_class(res, "ggplot")
  # type = "response" produces a rate column (not emmean) with asymptotic CIs;
  # the plot must build without the old hardcoded lower.CL/upper.CL error.
  expect_true("rate" %in% names(res$data))
  expect_true(any(c("asymp.LCL", "lower.CL") %in% names(res$data)))
  expect_no_error(ggplot2::ggplot_build(res))
})

test_that("plot_emmeans_interaction: empty specs errors", {
  skip_if_not_installed("emmeans")
  expect_error(
    mysterycall_plot_emmeans_interaction(lm(mpg ~ wt, mtcars), character(0), "mpg"),
    "character vector"
  )
})
