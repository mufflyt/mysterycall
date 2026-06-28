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

# mysterycall_predicted_means requires mysterycall_poisson_model (needs random_intercept)
set.seed(1)
POI_DF <- data.frame(
  days         = c(rpois(40, 5), rpois(40, 10)),
  insurance    = rep(c("Medicaid", "BCBS"), each = 40L),
  physician_id = rep(paste0("P", 1:10), 8L),
  stringsAsFactors = FALSE
)


# ============================================================================
# Test 1: Happy path with valid inputs using emmeans
# ============================================================================
test_that("mysterycall_predicted_means returns correct class and structure with emmeans", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(225)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(POI_DF, outcome = "days",
                              predictors = "insurance",
                              random_intercept = "physician_id")
  ))

  result <- suppressMessages(suppressWarnings(
    mysterycall_predicted_means(mod, group_col = "insurance")
  ))

  expect_s3_class(result, "data.frame")
  expect_true(all(c("group", "predicted_mean", "ci_lower", "ci_upper") %in% names(result)))
  expect_gte(nrow(result), 2L)
  expect_true(all(result$ci_lower <= result$ci_upper + 1e-6))
})


# ============================================================================
# Test 2: Bad input - wrong class for model_result
# ============================================================================
test_that("mysterycall_predicted_means rejects invalid model_result class", {
  expect_error(
    mysterycall_predicted_means(data.frame(x = 1:5), group_col = "insurance"),
    "must be a"
  )
})


# ============================================================================
# Test 3: Bad input - missing group_col argument
# ============================================================================
test_that("mysterycall_predicted_means rejects missing group_col", {
  skip_if_not_installed("lme4")

  set.seed(227)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(POI_DF, outcome = "days",
                              predictors = "insurance",
                              random_intercept = "physician_id")
  ))

  expect_error(mysterycall_predicted_means(mod))
})


# ============================================================================
# Test 4: Bad input - invalid conf_level
# ============================================================================
test_that("mysterycall_predicted_means rejects invalid conf_level", {
  skip_if_not_installed("lme4")

  set.seed(228)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(POI_DF, outcome = "days",
                              predictors = "insurance",
                              random_intercept = "physician_id")
  ))

  expect_error(
    mysterycall_predicted_means(mod, "insurance", conf_level = 1.5)
  )
  expect_error(
    mysterycall_predicted_means(mod, "insurance", conf_level = 0)
  )
})


# ============================================================================
# Test 5: Print method - basic output
# ============================================================================
test_that("print.mysterycall_predicted_means produces expected output", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(229)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(POI_DF, outcome = "days",
                              predictors = "insurance",
                              random_intercept = "physician_id")
  ))

  result <- suppressMessages(suppressWarnings(
    mysterycall_predicted_means(mod, group_col = "insurance")
  ))

  captured <- capture.output(print(result))
  expect_true(length(captured) > 0L)
  expect_invisible(print(result))
})


# ============================================================================
# Test 6: Custom conf_level parameter
# ============================================================================
test_that("mysterycall_predicted_means respects custom conf_level", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(231)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(POI_DF, outcome = "days",
                              predictors = "insurance",
                              random_intercept = "physician_id")
  ))

  result_90 <- suppressMessages(suppressWarnings(
    mysterycall_predicted_means(mod, group_col = "insurance", conf_level = 0.90)
  ))
  result_95 <- suppressMessages(suppressWarnings(
    mysterycall_predicted_means(mod, group_col = "insurance", conf_level = 0.95)
  ))

  expect_true(is.data.frame(result_90))
  expect_true(is.data.frame(result_95))

  ci_range_90 <- result_90$ci_upper - result_90$ci_lower
  ci_range_95 <- result_95$ci_upper - result_95$ci_lower
  expect_true(all(ci_range_90 <= ci_range_95 + 1e-6))
})
