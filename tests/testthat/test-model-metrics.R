# ── mysterycall:::mysterycall_model_metrics ─────────────────────────────────────────────────

m_lm <- lm(mpg ~ wt, data = mtcars)
m_glm <- glm(mpg ~ wt, data = mtcars, family = gaussian())

test_that("model_metrics: returns list with mae and rmse", {
  res <- mysterycall:::mysterycall_model_metrics(m_lm)
  expect_type(res, "list")
  expect_named(res, c("mae", "rmse"))
})

test_that("model_metrics: mae and rmse are non-negative numeric scalars", {
  res <- mysterycall:::mysterycall_model_metrics(m_lm)
  expect_true(is.numeric(res$mae) && length(res$mae) == 1L && res$mae >= 0)
  expect_true(is.numeric(res$rmse) && length(res$rmse) == 1L && res$rmse >= 0)
})

test_that("model_metrics: rmse >= mae (always true)", {
  res <- mysterycall:::mysterycall_model_metrics(m_lm)
  expect_gte(res$rmse, res$mae)
})

test_that("model_metrics: glm object accepted", {
  res <- mysterycall:::mysterycall_model_metrics(m_glm)
  expect_named(res, c("mae", "rmse"))
})

test_that("model_metrics: perfect fit → mae and rmse both 0", {
  df <- data.frame(y = 1:10, x = 1:10)
  m  <- lm(y ~ x, data = df)
  res <- mysterycall:::mysterycall_model_metrics(m)
  expect_lt(res$mae,  1e-10)
  expect_lt(res$rmse, 1e-10)
})

test_that("model_metrics: invalid model class errors", {
  expect_error(mysterycall:::mysterycall_model_metrics(list()), "must be")
})

test_that("model_metrics: known MAE within tolerance for mtcars lm", {
  res <- mysterycall:::mysterycall_model_metrics(m_lm)
  # mtcars lm(mpg ~ wt) residuals are well-known; MAE ≈ 2.3
  expect_lt(res$mae, 5)
  expect_gt(res$mae, 0.5)
})
