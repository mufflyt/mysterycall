library(testthat)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)

# Build upstream model for model-dependent tests
set.seed(213)
mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

test_that("mysterycall_select_best_model: happy path with AIC criterion (default)", {
  m1 <- glm(mpg ~ wt, data = mtcars, family = gaussian())
  m2 <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian())

  result <- suppressMessages(mysterycall_select_best_model(list(base = m1, full = m2)))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_equal(colnames(result), c("model", "AIC", "delta_AIC", "winner"))
  expect_true(any(result$winner))
  expect_equal(sum(result$winner), 1L)
})

test_that("mysterycall_select_best_model: happy path with BIC criterion", {
  m1 <- glm(mpg ~ wt, data = mtcars, family = gaussian())
  m2 <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian())
  m3 <- glm(mpg ~ wt + hp + am, data = mtcars, family = gaussian())

  result <- suppressMessages(mysterycall_select_best_model(
    list(base = m1, full = m2, extended = m3),
    criterion = "bic"
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3L)
  expect_equal(colnames(result), c("model", "BIC", "delta_BIC", "winner"))
  expect_true(any(result$winner))
  expect_true(all(result$delta_BIC >= 0))
})

test_that("mysterycall_select_best_model: happy path with LRT criterion", {
  m1 <- glm(mpg ~ wt, data = mtcars, family = gaussian())
  m2 <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian())

  result <- suppressMessages(mysterycall_select_best_model(
    list(base = m1, full = m2),
    criterion = "lrt"
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(colnames(result), c("comparison", "Chisq", "df", "p_value"))
  expect_true(grepl("base vs full", result$comparison[[1L]]))
})

test_that("mysterycall_select_best_model: bad input - unnamed list", {
  m1 <- glm(mpg ~ wt, data = mtcars, family = gaussian())
  m2 <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian())

  expect_error(
    mysterycall_select_best_model(list(m1, m2)),
    "must be a named list"
  )
})

test_that("mysterycall_select_best_model: bad input - zero models", {
  expect_error(
    mysterycall_select_best_model(list()),
    "must be a named list"
  )
})

test_that("mysterycall_select_best_model: bad input - LRT with single model", {
  m1 <- glm(mpg ~ wt, data = mtcars, family = gaussian())

  expect_error(
    mysterycall_select_best_model(list(base = m1), criterion = "lrt"),
    "At least 2 models are required for LRT"
  )
})

test_that("mysterycall_select_best_model: bad input - not a list", {
  m1 <- glm(mpg ~ wt, data = mtcars, family = gaussian())

  expect_error(mysterycall_select_best_model(m1))
})

test_that("mysterycall_select_best_model: AIC ranking orders correctly", {
  m1 <- glm(mpg ~ wt, data = mtcars, family = gaussian())
  m2 <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian())
  m3 <- glm(mpg ~ 1, data = mtcars, family = gaussian())

  result <- suppressMessages(mysterycall_select_best_model(
    list(base = m1, full = m2, null = m3)
  ))

  expect_true(is.numeric(result$AIC))
  expect_true(is.numeric(result$delta_AIC))
  expect_true(all(diff(result$AIC) >= 0))
})

test_that("mysterycall_select_best_model: delta scores computed correctly", {
  m1 <- glm(mpg ~ wt, data = mtcars, family = gaussian())
  m2 <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian())

  result <- suppressMessages(mysterycall_select_best_model(
    list(base = m1, full = m2),
    criterion = "aic"
  ))

  min_aic <- min(result$AIC)
  expected_delta <- result$AIC - min_aic
  expect_equal(result$delta_AIC, expected_delta)
})

test_that("mysterycall_select_best_model: works with mysterycall wrapper objects", {
  skip_if_not_installed("lme4")

  # Wrap the model (mod is already available from setup)
  if (!is.null(mod$model)) {
    m1 <- glm(mpg ~ wt, data = mtcars, family = gaussian())

    result <- suppressMessages(mysterycall_select_best_model(
      list(model = mod, baseline = m1)
    ))

    expect_s3_class(result, "data.frame")
    expect_true(nrow(result) >= 1L)
  }
})
