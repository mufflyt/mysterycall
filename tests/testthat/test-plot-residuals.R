# ── mysterycall_plot_residuals ────────────────────────────────────────────────

m <- lm(mpg ~ wt, data = mtcars)

test_that("plot_residuals: returns list of three ggplot objects", {
  skip_if_not_installed("ggplot2")
  res <- mysterycall_plot_residuals(m, use_dharma = FALSE)
  expect_type(res, "list")
  expect_named(res, c("residuals_vs_fitted", "qq", "scale_location"))
  expect_s3_class(res$residuals_vs_fitted, "ggplot")
  expect_s3_class(res$qq,                 "ggplot")
  expect_s3_class(res$scale_location,     "ggplot")
})

test_that("plot_residuals: works with glm", {
  skip_if_not_installed("ggplot2")
  m_glm <- glm(mpg ~ wt, data = mtcars, family = gaussian())
  res   <- mysterycall_plot_residuals(m_glm, use_dharma = FALSE)
  expect_s3_class(res$qq, "ggplot")
})

test_that("plot_residuals: invalid model class errors", {
  expect_error(mysterycall_plot_residuals(list()), "must be")
})

test_that("plot_residuals: plot titles are set", {
  skip_if_not_installed("ggplot2")
  res <- mysterycall_plot_residuals(m, use_dharma = FALSE)
  expect_match(res$residuals_vs_fitted$labels$title, "Residuals")
  expect_match(res$qq$labels$title, "Q-Q")
  expect_match(res$scale_location$labels$title, "Scale")
})
