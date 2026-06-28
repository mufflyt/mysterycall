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

test_that("mysterycall_random_effect_variance returns correct list structure", {
  skip_if_not_installed("lme4")

  set.seed(227)
  lmm_data <- data.frame(
    wait_days = c(rnorm(40, 10, 3), rnorm(40, 15, 3)),
    insurance = rep(c("Medicaid", "BCBS"), each = 40L),
    physician = rep(paste0("Dr", 1:20), each = 4L),
    stringsAsFactors = FALSE
  )
  mod <- suppressMessages(suppressWarnings(mysterycall_lmm(lmm_data, "wait_days", "insurance", "physician", auto_log = FALSE, sensitivity_poisson = FALSE)))

  result <- mysterycall_random_effect_variance(mod$model)

  expect_type(result, "list")
  expect_named(result, c("icc", "random_variance", "residual_variance", "random_effect_group", "var_table", "interpretation", "sentence"))
  expect_type(result$sentence, "character")
  expect_type(result$random_effect_group, "character")
  expect_s3_class(result$var_table, "data.frame")
})

test_that("mysterycall_random_effect_variance rejects invalid model object", {
  skip_if_not_installed("lme4")

  expect_error(mysterycall_random_effect_variance("not a model"), "must be a fitted mixed model")
  expect_error(mysterycall_random_effect_variance(list(x = 1)), "must be a fitted mixed model")
  expect_error(mysterycall_random_effect_variance(NULL), "must be a fitted mixed model")
})

test_that("mysterycall_random_effect_variance rejects invalid variance_threshold", {
  skip_if_not_installed("lme4")

  set.seed(227)
  lmm_data <- data.frame(
    wait_days = c(rnorm(40, 10, 3), rnorm(40, 15, 3)),
    insurance = rep(c("Medicaid", "BCBS"), each = 40L),
    physician = rep(paste0("Dr", 1:20), each = 4L),
    stringsAsFactors = FALSE
  )
  mod <- suppressMessages(suppressWarnings(mysterycall_lmm(lmm_data, "wait_days", "insurance", "physician", auto_log = FALSE, sensitivity_poisson = FALSE)))

  expect_error(mysterycall_random_effect_variance(mod$model, variance_threshold = -0.5), "non-negative numeric scalar")
  expect_error(mysterycall_random_effect_variance(mod$model, variance_threshold = "0.01"), "non-negative numeric scalar")
  expect_error(mysterycall_random_effect_variance(mod$model, variance_threshold = c(0.01, 0.02)), "non-negative numeric scalar")
})

test_that("mysterycall_random_effect_variance var_table includes Significant column", {
  skip_if_not_installed("lme4")

  set.seed(227)
  lmm_data <- data.frame(
    wait_days = c(rnorm(40, 10, 3), rnorm(40, 15, 3)),
    insurance = rep(c("Medicaid", "BCBS"), each = 40L),
    physician = rep(paste0("Dr", 1:20), each = 4L),
    stringsAsFactors = FALSE
  )
  mod <- suppressMessages(suppressWarnings(mysterycall_lmm(lmm_data, "wait_days", "insurance", "physician", auto_log = FALSE, sensitivity_poisson = FALSE)))

  result_low <- mysterycall_random_effect_variance(mod$model, variance_threshold = 0.001)
  result_high <- mysterycall_random_effect_variance(mod$model, variance_threshold = 100.0)

  expect_true("Significant" %in% names(result_low$var_table))
  expect_true("Significant" %in% names(result_high$var_table))
  expect_true(all(result_low$var_table$Significant %in% c("Yes", "No")))
  expect_true(all(result_high$var_table$Significant %in% c("Yes", "No")))
})

test_that("mysterycall_random_effect_variance digits parameter controls ICC rounding", {
  skip_if_not_installed("lme4")

  set.seed(227)
  lmm_data <- data.frame(
    wait_days = c(rnorm(40, 10, 3), rnorm(40, 15, 3)),
    insurance = rep(c("Medicaid", "BCBS"), each = 40L),
    physician = rep(paste0("Dr", 1:20), each = 4L),
    stringsAsFactors = FALSE
  )
  mod <- suppressMessages(suppressWarnings(mysterycall_lmm(lmm_data, "wait_days", "insurance", "physician", auto_log = FALSE, sensitivity_poisson = FALSE)))

  result_1 <- mysterycall_random_effect_variance(mod$model, digits = 1)
  result_3 <- mysterycall_random_effect_variance(mod$model, digits = 3)

  # ICC values should be identical (same underlying computation)
  expect_equal(result_1$icc, result_3$icc)

  # But sentences should contain appropriately rounded ICC values
  if (!is.na(result_1$icc)) {
    expect_true(grepl(as.character(round(result_1$icc, 1)), result_1$sentence))
    expect_true(grepl(as.character(round(result_3$icc, 3)), result_3$sentence))
  }
})

test_that("mysterycall_random_effect_variance handles mixed model appropriately", {
  skip_if_not_installed("lme4")

  set.seed(227)
  lmm_data <- data.frame(
    wait_days = c(rnorm(40, 10, 3), rnorm(40, 15, 3)),
    insurance = rep(c("Medicaid", "BCBS"), each = 40L),
    physician = rep(paste0("Dr", 1:20), each = 4L),
    stringsAsFactors = FALSE
  )
  mod <- suppressMessages(suppressWarnings(mysterycall_lmm(lmm_data, "wait_days", "insurance", "physician", auto_log = FALSE, sensitivity_poisson = FALSE)))

  result <- mysterycall_random_effect_variance(mod$model)

  # LMM should have ICC and residual variance
  expect_true(is.numeric(result$icc) && !is.na(result$icc))
  expect_true(is.numeric(result$residual_variance) && !is.na(result$residual_variance))
  expect_type(result$random_variance, "double")
  expect_true(result$random_effect_group == "physician")

  # ICC should be between 0 and 1
  expect_true(result$icc >= 0 && result$icc <= 1)
  expect_true(result$interpretation %in% c("high", "moderate", "low to moderate", "low"))
})
