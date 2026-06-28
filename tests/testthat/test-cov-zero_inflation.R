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

test_that("mysterycall_check_zero_inflation works with mysterycall_simple_poisson model (happy path)", {
  skip_if_not_installed("DHARMa")

  set.seed(237)
  mod <- suppressMessages(mysterycall_simple_poisson(COUNT_DF, outcome="days", group="insurance", use_profile_ci=FALSE))

  result <- suppressMessages(suppressWarnings(
    mysterycall_check_zero_inflation(mod$model, n_sim = 100L, plot = FALSE)
  ))

  expect_s3_class(result, "htest")
  expect_true(hasName(result, "statistic"))
  expect_true(hasName(result, "p.value"))
  expect_true(is.numeric(result$statistic) || is.na(result$statistic))
})

test_that("mysterycall_check_zero_inflation works with bare glm model", {
  skip_if_not_installed("DHARMa")

  set.seed(238)
  fit <- glm(days ~ insurance, family = poisson(), data = COUNT_DF)

  result <- suppressMessages(suppressWarnings(
    mysterycall_check_zero_inflation(fit, n_sim = 50L, plot = FALSE)
  ))

  expect_s3_class(result, "htest")
  expect_true(hasName(result, "p.value"))
  expect_true(is.numeric(result$p.value) || is.na(result$p.value))
})

test_that("mysterycall_check_zero_inflation with plot = TRUE (graphics enabled)", {
  skip_if_not_installed("DHARMa")

  set.seed(239)
  fit <- glm(days ~ insurance, family = poisson(), data = COUNT_DF)

  result <- suppressMessages(suppressWarnings(
    mysterycall_check_zero_inflation(fit, n_sim = 50L, plot = TRUE)
  ))

  expect_s3_class(result, "htest")
  expect_true(hasName(result, "p.value"))
})

test_that("mysterycall_check_zero_inflation respects n_sim parameter (edge case: low n_sim)", {
  skip_if_not_installed("DHARMa")

  set.seed(240)
  fit <- glm(days ~ insurance, family = poisson(), data = COUNT_DF)

  result <- suppressMessages(suppressWarnings(
    mysterycall_check_zero_inflation(fit, n_sim = 10L, plot = FALSE)
  ))

  expect_s3_class(result, "htest")
  expect_true(is.numeric(result$p.value) || is.na(result$p.value))
})

test_that("mysterycall_check_zero_inflation errors on invalid model type (bad input)", {
  skip_if_not_installed("DHARMa")

  bad_model <- list(x = 1, y = 2)

  expect_error(
    suppressMessages(mysterycall_check_zero_inflation(bad_model, plot = FALSE)),
    "must be a mysterycall_poisson_model"
  )
})

test_that("mysterycall_check_zero_inflation errors on missing model argument (bad input)", {
  skip_if_not_installed("DHARMa")

  expect_error(
    suppressMessages(mysterycall_check_zero_inflation()),
    "argument \"model\" is missing"
  )
})
