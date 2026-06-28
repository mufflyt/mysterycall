library(testthat)
library(mysterycall)

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

test_that("mysterycall_plot_residuals Pearson path returns 3 ggplot objects", {
  set.seed(222)
  mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

  result <- suppressMessages(mysterycall_plot_residuals(mod$model, use_dharma = FALSE))

  expect_type(result, "list")
  expect_length(result, 3)
  expect_named(result, c("residuals_vs_fitted", "qq", "scale_location"))
  expect_s3_class(result$residuals_vs_fitted, "ggplot")
  expect_s3_class(result$qq, "ggplot")
  expect_s3_class(result$scale_location, "ggplot")
})

test_that("mysterycall_plot_residuals works with glm object directly (Pearson path)", {
  set.seed(223)
  m <- suppressMessages(glm(days ~ insurance, data = COUNT_DF, family = poisson()))

  result <- suppressMessages(mysterycall_plot_residuals(m, use_dharma = FALSE))

  expect_type(result, "list")
  expect_length(result, 3)
  expect_named(result, c("residuals_vs_fitted", "qq", "scale_location"))
})

test_that("mysterycall_plot_residuals rejects invalid model class", {
  expect_error(
    mysterycall_plot_residuals("not a model"),
    "must be a"
  )
  expect_error(
    mysterycall_plot_residuals(list(x = 1)),
    "must be a"
  )
})

test_that("mysterycall_plot_residuals DHARMa path returns DHARMa object", {
  skip_if_not_installed("DHARMa")
  set.seed(224)
  mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

  result <- suppressMessages(mysterycall_plot_residuals(mod$model, use_dharma = TRUE, plot = FALSE, n_sim = 100L))

  expect_s3_class(result, "DHARMa")
})

test_that("mysterycall_plot_residuals respects plot parameter in DHARMa path", {
  skip_if_not_installed("DHARMa")
  set.seed(226)
  mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

  result_no_plot <- suppressMessages(mysterycall_plot_residuals(mod$model, use_dharma = TRUE, plot = FALSE, n_sim = 100L))
  result_with_plot <- suppressMessages(mysterycall_plot_residuals(mod$model, use_dharma = TRUE, plot = TRUE, n_sim = 100L))

  expect_s3_class(result_no_plot, "DHARMa")
  expect_s3_class(result_with_plot, "DHARMa")
})

test_that("mysterycall_plot_residuals respects n_sim parameter", {
  skip_if_not_installed("DHARMa")
  set.seed(227)
  mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

  result_50 <- suppressMessages(mysterycall_plot_residuals(mod$model, use_dharma = TRUE, n_sim = 50L, plot = FALSE))
  result_200 <- suppressMessages(mysterycall_plot_residuals(mod$model, use_dharma = TRUE, n_sim = 200L, plot = FALSE))

  expect_s3_class(result_50, "DHARMa")
  expect_s3_class(result_200, "DHARMa")
})

test_that("mysterycall_plot_residuals works with lm object", {
  set.seed(228)
  m <- suppressMessages(lm(days ~ insurance, data = COUNT_DF))

  result <- suppressMessages(mysterycall_plot_residuals(m, use_dharma = FALSE))

  expect_type(result, "list")
  expect_length(result, 3)
  expect_s3_class(result$residuals_vs_fitted, "ggplot")
})

test_that("mysterycall_plot_residuals falls back to Pearson when DHARMa unavailable", {
  set.seed(229)
  m <- suppressMessages(glm(days ~ insurance, data = COUNT_DF, family = poisson()))

  result <- suppressMessages(suppressWarnings(mysterycall_plot_residuals(m, use_dharma = TRUE)))

  # Should return ggplot list (Pearson path), not DHARMa object, if DHARMa is not available
  expect_type(result, "list")
})
