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


test_that("mysterycall_check_zero_inflation works with basic glm model", {
  skip_if_not_installed("DHARMa")
  set.seed(1)

  fit <- glm(days ~ insurance, family = poisson(), data = COUNT_DF)

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_check_zero_inflation(fit, n_sim = 100L, plot = FALSE)
    )
  )

  expect_s3_class(result, "DHARMaTest")
  expect_true("p.value" %in% names(result))
  expect_type(result$p.value, "double")
})


test_that("mysterycall_check_zero_inflation returns invisible result", {
  skip_if_not_installed("DHARMa")
  set.seed(2)

  fit <- glm(days ~ insurance, family = poisson(), data = COUNT_DF)

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_check_zero_inflation(fit, n_sim = 50L, plot = FALSE)
    )
  )

  expect_s3_class(result, "DHARMaTest")
  expect_true(is.numeric(result$p.value))
})


test_that("mysterycall_check_zero_inflation errors on invalid model type", {
  skip_if_not_installed("DHARMa")

  bad_model <- list(x = 1, y = 2)

  expect_error(
    mysterycall_check_zero_inflation(bad_model, plot = FALSE),
    "must be a mysterycall_poisson_model"
  )
})


test_that("mysterycall_check_zero_inflation respects n_sim parameter", {
  skip_if_not_installed("DHARMa")
  set.seed(3)

  fit <- glm(days ~ insurance, family = poisson(), data = COUNT_DF)

  result_small <- suppressMessages(
    suppressWarnings(
      mysterycall_check_zero_inflation(fit, n_sim = 50L, plot = FALSE)
    )
  )

  result_large <- suppressMessages(
    suppressWarnings(
      mysterycall_check_zero_inflation(fit, n_sim = 200L, plot = FALSE)
    )
  )

  expect_s3_class(result_small, "DHARMaTest")
  expect_s3_class(result_large, "DHARMaTest")
  expect_true(!is.na(result_small$p.value))
  expect_true(!is.na(result_large$p.value))
})


test_that("mysterycall_check_zero_inflation works with plot = TRUE", {
  skip_if_not_installed("DHARMa")
  set.seed(4)

  fit <- glm(days ~ insurance, family = poisson(), data = COUNT_DF)

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_check_zero_inflation(fit, n_sim = 50L, plot = TRUE)
    )
  )

  expect_s3_class(result, "DHARMaTest")
  expect_true("p.value" %in% names(result))
})
