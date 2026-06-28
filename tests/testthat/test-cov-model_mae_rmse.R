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
  grp       = rep(1:8, each = 10L),
  stringsAsFactors = FALSE
)

# --- Test 1: Happy path with Poisson model, in-sample ---
test_that("mysterycall_model_mae_rmse returns correct class and structure for Poisson model", {
  skip_if_not_installed("lme4")

  set.seed(212)
  mod <- suppressWarnings(mysterycall_poisson_model(
    COUNT_DF,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "grp"
  ))

  result <- suppressMessages(suppressWarnings(mysterycall_model_mae_rmse(
    fit = mod,
    newdata = NULL,
    plot = FALSE
  )))

  expect_s3_class(result, "mysterycall_model_mae_rmse")
  expect_type(result$mae, "double")
  expect_type(result$rmse, "double")
  expect_type(result$r2_pearson, "double")
  expect_type(result$n, "integer")
  expect_type(result$sentence, "character")
  expect_s3_class(result$predictions, "data.frame")
  expect_null(result$plot)
})

# --- Test 2: Metrics are in valid ranges ---
test_that("mysterycall_model_mae_rmse computes metrics in valid ranges", {
  skip_if_not_installed("lme4")

  set.seed(212)
  mod <- suppressWarnings(mysterycall_poisson_model(
    COUNT_DF,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "grp"
  ))

  result <- suppressMessages(suppressWarnings(mysterycall_model_mae_rmse(
    fit = mod,
    plot = FALSE
  )))

  expect_true(result$mae >= 0)
  expect_true(result$rmse >= 0)
  expect_true(result$rmse >= result$mae)  # RMSE >= MAE always
  expect_true(result$r2_pearson >= 0 && result$r2_pearson <= 1)
  expect_true(result$n > 0)
  expect_equal(nrow(result$predictions), result$n)
  expect_true(all(c("actual", "predicted", "residual") %in% names(result$predictions)))
})

# --- Test 3: Prediction data frame has correct dimensions ---
test_that("mysterycall_model_mae_rmse predictions data.frame is well-formed", {
  skip_if_not_installed("lme4")

  set.seed(212)
  mod <- suppressWarnings(mysterycall_poisson_model(
    COUNT_DF,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "grp"
  ))

  result <- suppressMessages(suppressWarnings(mysterycall_model_mae_rmse(
    fit = mod,
    plot = FALSE
  )))

  pred_df <- result$predictions
  expect_equal(nrow(pred_df), result$n)
  expect_equal(ncol(pred_df), 3)
  expect_equal(colnames(pred_df), c("actual", "predicted", "residual"))

  # Residual should be actual - predicted
  expected_resid <- pred_df$actual - pred_df$predicted
  expect_equal(pred_df$residual, expected_resid, tolerance = 1e-10)
})

# --- Test 4: Error on invalid fit class ---
test_that("mysterycall_model_mae_rmse errors on invalid fit class", {
  bad_fit <- list(model = NULL, formula = y ~ x)
  class(bad_fit) <- "some_random_class"

  expect_error(
    mysterycall_model_mae_rmse(fit = bad_fit),
    "must be one of"
  )
})

# --- Test 5: Error on invalid conf_level ---
test_that("mysterycall_model_mae_rmse errors on invalid conf_level values", {
  skip_if_not_installed("lme4")

  set.seed(212)
  mod <- suppressWarnings(mysterycall_poisson_model(
    COUNT_DF,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "grp"
  ))

  expect_error(
    suppressWarnings(mysterycall_model_mae_rmse(fit = mod, conf_level = 1.5)),
    "conf_level"
  )

  expect_error(
    suppressWarnings(mysterycall_model_mae_rmse(fit = mod, conf_level = -0.1)),
    "conf_level"
  )

  expect_error(
    suppressWarnings(mysterycall_model_mae_rmse(fit = mod, conf_level = c(0.8, 0.9))),
    "conf_level"
  )
})

# --- Test 6: Error when actual_col not found in newdata ---
test_that("mysterycall_model_mae_rmse errors when actual_col absent from newdata", {
  skip_if_not_installed("lme4")

  set.seed(212)
  mod <- suppressWarnings(mysterycall_poisson_model(
    COUNT_DF,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "grp"
  ))

  bad_newdata <- data.frame(insurance = c("Medicaid", "BCBS"), grp = 1:2, x = 1:2)

  expect_error(
    suppressWarnings(mysterycall_model_mae_rmse(
      fit = mod,
      newdata = bad_newdata,
      actual_col = "days"
    )),
    "not found"
  )
})

# --- Test 7: Print method works and returns invisibly ---
test_that("print.mysterycall_model_mae_rmse outputs summary and returns invisibly", {
  skip_if_not_installed("lme4")

  set.seed(212)
  mod <- suppressWarnings(mysterycall_poisson_model(
    COUNT_DF,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "grp"
  ))

  result <- suppressMessages(suppressWarnings(mysterycall_model_mae_rmse(
    fit = mod,
    plot = FALSE
  )))

  output <- capture.output(invisible_result <- print(result))

  expect_identical(invisible_result, result)
  expect_true(any(grepl("Model MAE", output)))
  expect_true(any(grepl("RMSE", output)))
})

# --- Test 8: plot=FALSE produces NULL plot, plot=TRUE attempts to plot ---
test_that("mysterycall_model_mae_rmse respects plot parameter", {
  skip_if_not_installed("lme4")

  set.seed(212)
  mod <- suppressWarnings(mysterycall_poisson_model(
    COUNT_DF,
    outcome = "days",
    predictors = "insurance",
    random_intercept = "grp"
  ))

  result_no_plot <- suppressMessages(suppressWarnings(mysterycall_model_mae_rmse(
    fit = mod,
    plot = FALSE
  )))

  expect_null(result_no_plot$plot)

  result_with_plot <- suppressMessages(suppressWarnings(mysterycall_model_mae_rmse(
    fit = mod,
    plot = TRUE
  )))

  # plot could be ggplot or NULL depending on ggplot2 availability
  expect_true(is.null(result_with_plot$plot) || inherits(result_with_plot$plot, "ggplot"))
})
