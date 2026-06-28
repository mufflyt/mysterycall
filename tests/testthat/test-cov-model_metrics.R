library(testthat)
library(mysterycall)

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------
set.seed(123)
LM_FIT <- lm(mpg ~ wt + cyl, data = mtcars)

set.seed(123)
GLM_POIS_FIT <- glm(
  round(Postwt) ~ Treat,
  data   = MASS::anorexia,
  family = poisson()
)

set.seed(123)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid", "BCBS"), each = 40L),
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# Tests for mysterycall_model_metrics
# ---------------------------------------------------------------------------

test_that("mysterycall_model_metrics returns mae and rmse for an lm object", {
  result <- suppressWarnings(suppressMessages(
    mysterycall_model_metrics(LM_FIT)
  ))

  expect_type(result, "list")
  expect_named(result, c("mae", "rmse"))
  expect_true(is.numeric(result$mae))
  expect_true(is.numeric(result$rmse))
  expect_true(result$mae >= 0)
  expect_true(result$rmse >= 0)
  # RMSE >= MAE by Jensen's inequality
  expect_true(result$rmse >= result$mae)
})

test_that("mysterycall_model_metrics works with a Poisson glm object", {
  skip_if_not_installed("MASS")

  result <- suppressWarnings(suppressMessages(
    mysterycall_model_metrics(GLM_POIS_FIT)
  ))

  expect_type(result, "list")
  expect_named(result, c("mae", "rmse"))
  expect_true(is.finite(result$mae))
  expect_true(is.finite(result$rmse))
  expect_true(result$mae >= 0)
  expect_true(result$rmse >= 0)
})

test_that("mysterycall_model_metrics works when fed the glm from mysterycall_simple_poisson", {
  sp <- suppressWarnings(suppressMessages(
    mysterycall_simple_poisson(COUNT_DF, "days", "insurance",
                               reference      = "BCBS",
                               use_profile_ci = FALSE)
  ))
  # $model is a plain glm — accepted by mysterycall_model_metrics
  result <- suppressWarnings(suppressMessages(
    mysterycall_model_metrics(sp$model)
  ))

  expect_type(result, "list")
  expect_named(result, c("mae", "rmse"))
  expect_true(result$mae >= 0)
  expect_true(result$rmse >= 0)
})

test_that("mysterycall_model_metrics errors on a non-model input", {
  expect_error(
    mysterycall_model_metrics(list(a = 1, b = 2)),
    regexp = "must be"
  )
  expect_error(
    mysterycall_model_metrics("not a model"),
    regexp = "must be"
  )
  expect_error(
    mysterycall_model_metrics(42L),
    regexp = "must be"
  )
})

test_that("mysterycall_model_metrics scalar values are length-1 numerics", {
  result <- suppressWarnings(suppressMessages(
    mysterycall_model_metrics(LM_FIT)
  ))

  expect_length(result$mae,  1L)
  expect_length(result$rmse, 1L)
  expect_false(is.na(result$mae))
  expect_false(is.na(result$rmse))
})
