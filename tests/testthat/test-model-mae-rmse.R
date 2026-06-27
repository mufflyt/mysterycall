# tests/testthat/test-model-mae-rmse.R
#
# Tests for mysterycall_model_mae_rmse().
#
# Strategy: all fit objects are built with stats::lm() as the inner $model.
# predict.lm() silently accepts the extra named arguments (re.form, type) that
# the function passes via ..., so no lme4/glmmTMB is required for these tests.
# Edition 3 is set in DESCRIPTION (Config/testthat/edition: 3).

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Wrap a stats::lm() as a fake mysterycall_lmm so the function can dispatch.
make_fake_lmm <- function(data, formula, log_transformed = FALSE) {
  structure(
    list(
      model           = lm(formula, data = data),
      formula         = formula,
      log_transformed = log_transformed
    ),
    class = "mysterycall_lmm"
  )
}

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

# Eight-row data set with a clear linear trend.
base_dat <- data.frame(
  y  = c(10, 15, 12, 8, 20, 7, 18, 13),
  x1 = c( 1,  2,  3, 4,  5, 6,  7,  8)
)
fake_lmm <- make_fake_lmm(base_dat, y ~ x1)

# Saturated model: 3 observations, 3 parameters (intercept + x1 + x2).
# In-sample fitted values equal the observed values exactly.
sat_dat <- data.frame(
  y  = c(1.0, 2.0, 3.0),
  x1 = c(1, 0, 0),
  x2 = c(0, 1, 0)
)
sat_lmm <- make_fake_lmm(sat_dat, y ~ x1 + x2)

# ---------------------------------------------------------------------------
# 1. Class and type of return value
# ---------------------------------------------------------------------------

test_that("returns a list with S3 class mysterycall_model_mae_rmse", {
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = FALSE)
  expect_s3_class(res, "mysterycall_model_mae_rmse")
  expect_type(res, "list")
})

# ---------------------------------------------------------------------------
# 2. MAE is a non-negative numeric scalar
# ---------------------------------------------------------------------------

test_that("mae is a non-negative numeric scalar", {
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = FALSE)
  expect_true(is.numeric(res$mae))
  expect_length(res$mae, 1L)
  expect_gte(res$mae, 0)
})

# ---------------------------------------------------------------------------
# 3. RMSE >= MAE (QM-AM inequality: root-mean-square >= mean-absolute)
# ---------------------------------------------------------------------------

test_that("rmse is always >= mae", {
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = FALSE)
  expect_gte(res$rmse, res$mae)
})

# ---------------------------------------------------------------------------
# 4. r2_pearson is in [0, 1]
# ---------------------------------------------------------------------------

test_that("r2_pearson is in [0, 1]", {
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = FALSE)
  expect_true(is.numeric(res$r2_pearson))
  expect_gte(res$r2_pearson, 0)
  expect_lte(res$r2_pearson, 1)
})

# ---------------------------------------------------------------------------
# 5. n matches the count of non-NA actual/predicted pairs
# ---------------------------------------------------------------------------

test_that("n equals the number of complete (non-NA) observation pairs", {
  # Inject one NA into the outcome column; the predictor stays complete so
  # predict.lm() produces 5 non-NA predictions.
  newdata_na <- data.frame(y = c(10, NA, 12, 8, 20), x1 = c(1, 2, 3, 4, 5))

  res <- suppressWarnings(
    mysterycall:::mysterycall_model_mae_rmse(
      fake_lmm,
      newdata    = newdata_na,
      actual_col = "y",
      plot       = FALSE
    )
  )

  expect_equal(res$n, 4L)
  expect_equal(nrow(res$predictions), 4L)
})

# ---------------------------------------------------------------------------
# 6. sentence is a character scalar containing "MAE"
# ---------------------------------------------------------------------------

test_that("sentence is a character string containing the substring 'MAE'", {
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = FALSE)
  expect_type(res$sentence, "character")
  expect_length(res$sentence, 1L)
  expect_match(res$sentence, "MAE")
})

# ---------------------------------------------------------------------------
# 7. predictions data.frame has required columns
# ---------------------------------------------------------------------------

test_that("predictions is a data.frame with columns actual, predicted, residual", {
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = FALSE)
  expect_s3_class(res$predictions, "data.frame")
  expect_named(res$predictions, c("actual", "predicted", "residual"),
               ignore.order = FALSE)
  expect_true(is.numeric(res$predictions$actual))
  expect_true(is.numeric(res$predictions$predicted))
  expect_true(is.numeric(res$predictions$residual))
})

test_that("residual column equals actual minus predicted", {
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = FALSE)
  expect_equal(
    res$predictions$residual,
    res$predictions$actual - res$predictions$predicted,
    tolerance = 1e-10
  )
})

# ---------------------------------------------------------------------------
# 8. plot is NULL when plot = FALSE
# ---------------------------------------------------------------------------

test_that("plot element is NULL when plot = FALSE", {
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = FALSE)
  expect_null(res$plot)
})

# ---------------------------------------------------------------------------
# 9. plot element is a ggplot when plot = TRUE and ggplot2 is available
# ---------------------------------------------------------------------------

test_that("plot element is a ggplot object when plot = TRUE", {
  skip_if_not_installed("ggplot2")
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = TRUE)
  expect_s3_class(res$plot, "ggplot")
})

# ---------------------------------------------------------------------------
# 10. back_transform = FALSE suppresses exp() even when log_transformed = TRUE
# ---------------------------------------------------------------------------

test_that("back_transform = FALSE skips exp() on predictions and actuals", {
  # Outcome is already on the log scale; log(10..20) ≈ 2.3–3.0.
  log_dat <- data.frame(
    log_y = log(c(10, 15, 12, 8, 20)),
    x1    = c(1, 2, 3, 4, 5)
  )
  log_lmm <- make_fake_lmm(log_dat, log_y ~ x1, log_transformed = TRUE)

  res <- mysterycall:::mysterycall_model_mae_rmse(
    log_lmm,
    back_transform = FALSE,   # override auto-detect
    plot           = FALSE
  )

  # If exp() were applied, actual values would jump to 8–20.
  # With back_transform = FALSE they stay on the log scale (< 5).
  expect_true(all(res$predictions$actual < 5))
})

# ---------------------------------------------------------------------------
# 11. Error for unsupported model class
# ---------------------------------------------------------------------------

test_that("error is thrown when fit is not a supported model class", {
  bad_fit <- structure(list(), class = "unsupported_class")
  expect_error(
    mysterycall:::mysterycall_model_mae_rmse(bad_fit, plot = FALSE),
    regexp = "must be one of"
  )
})

# ---------------------------------------------------------------------------
# 12. Works with a structure()-built result (no lme4 needed)
# ---------------------------------------------------------------------------

test_that("structure()-built mysterycall_model_mae_rmse object satisfies all field contracts", {
  fake_result <- structure(
    list(
      mae        = 3.2,
      rmse       = 4.5,
      r2_pearson = 0.81,
      mape       = 12.3,
      n          = 80L,
      predictions = data.frame(
        actual    = c(20.0, 25.0, 18.0),
        predicted = c(18.3, 27.1, 19.5),
        residual  = c( 1.7, -2.1, -1.5),
        stringsAsFactors = FALSE
      ),
      plot     = NULL,
      sentence = paste0(
        "Model MAE = 3.2 days, RMSE = 4.5 days, ",
        "R2 = 0.81, MAPE = 12.3% (N=80)."
      )
    ),
    class = "mysterycall_model_mae_rmse"
  )

  expect_s3_class(fake_result, "mysterycall_model_mae_rmse")
  expect_gte(fake_result$mae, 0)
  expect_gte(fake_result$rmse, fake_result$mae)
  expect_true(fake_result$r2_pearson >= 0 && fake_result$r2_pearson <= 1)
  expect_match(fake_result$sentence, "MAE")
  expect_s3_class(fake_result$predictions, "data.frame")
  expect_named(fake_result$predictions, c("actual", "predicted", "residual"),
               ignore.order = FALSE)
})

# ---------------------------------------------------------------------------
# 13. Perfect predictions: mae = 0, rmse = 0, r2_pearson = 1
# ---------------------------------------------------------------------------

test_that("mae and rmse are exactly 0 when actual equals predicted", {
  # sat_lmm is a saturated model (n = p = 3): in-sample residuals are zero.
  res <- mysterycall:::mysterycall_model_mae_rmse(sat_lmm, plot = FALSE)
  expect_equal(res$mae,        0, tolerance = 1e-10)
  expect_equal(res$rmse,       0, tolerance = 1e-10)
  expect_equal(res$r2_pearson, 1, tolerance = 1e-10)
})

# ---------------------------------------------------------------------------
# 14. mape is a non-negative numeric when all actual values are positive
# ---------------------------------------------------------------------------

test_that("mape is a non-negative numeric when all actual values are non-zero", {
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = FALSE)
  expect_true(is.numeric(res$mape))
  expect_gte(res$mape, 0)
})

# ---------------------------------------------------------------------------
# 15. print method returns the object invisibly
# ---------------------------------------------------------------------------

test_that("print.mysterycall_model_mae_rmse returns the object invisibly", {
  res <- mysterycall:::mysterycall_model_mae_rmse(fake_lmm, plot = FALSE)
  # withVisible() detects whether the return was marked invisible.
  out <- withVisible(print(res))
  expect_false(out$visible)
  expect_identical(out$value, res)
})
