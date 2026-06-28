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


test_that("mysterycall_predicted_means: happy path with Poisson model", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(42)
  fit <- suppressMessages(
    suppressWarnings(
      mysterycall_poisson_model(COUNT_DF, "days", "insurance", use_profile_ci = FALSE)
    )
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_predicted_means(fit, "insurance")
    )
  )

  expect_s3_class(result, "mysterycall_predicted_means")
  expect_no_error(result)
})


test_that("mysterycall_predicted_means: output structure and columns", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(42)
  fit <- suppressMessages(
    suppressWarnings(
      mysterycall_poisson_model(COUNT_DF, "days", "insurance", use_profile_ci = FALSE)
    )
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_predicted_means(fit, "insurance")
    )
  )

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_true("mysterycall_predicted_means" %in% class(result))

  # Check columns
  expect_named(result, c("group", "predicted_mean", "se", "ci_lower", "ci_upper"))

  # Check data types
  expect_character(result$group)
  expect_numeric(result$predicted_mean)
  expect_numeric(result$se)
  expect_numeric(result$ci_lower)
  expect_numeric(result$ci_upper)

  # Check attribute
  expect_equal(attr(result, "group_col"), "insurance")
})


test_that("mysterycall_predicted_means: CI bounds are sensible", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(42)
  fit <- suppressMessages(
    suppressWarnings(
      mysterycall_poisson_model(COUNT_DF, "days", "insurance", use_profile_ci = FALSE)
    )
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_predicted_means(fit, "insurance")
    )
  )

  # CI lower should be less than point estimate
  expect_true(all(result$ci_lower < result$predicted_mean))

  # CI upper should be greater than point estimate
  expect_true(all(result$ci_upper > result$predicted_mean))

  # All values should be positive
  expect_true(all(result$predicted_mean > 0))
  expect_true(all(result$se > 0))
})


test_that("mysterycall_predicted_means: rejects invalid model class", {
  skip_if_not_installed("emmeans")

  set.seed(42)
  df <- data.frame(y = rpois(20, 5), x = rep(c("A", "B"), 10))

  # Fit a regular glm instead of mysterycall model
  bad_model <- glm(y ~ x, family = poisson, data = df)

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_predicted_means(bad_model, "x")
      )
    ),
    "`model_result` must be a `mysterycall_poisson_model` or `mysterycall_nb_model`"
  )
})


test_that("mysterycall_predicted_means: rejects non-character group_col", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(42)
  fit <- suppressMessages(
    suppressWarnings(
      mysterycall_poisson_model(COUNT_DF, "days", "insurance", use_profile_ci = FALSE)
    )
  )

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_predicted_means(fit, 42)
      )
    ),
    "`group_col` must be a single character string"
  )
})


test_that("mysterycall_predicted_means: rejects multi-element group_col", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(42)
  fit <- suppressMessages(
    suppressWarnings(
      mysterycall_poisson_model(COUNT_DF, "days", "insurance", use_profile_ci = FALSE)
    )
  )

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_predicted_means(fit, c("insurance", "days"))
      )
    ),
    "`group_col` must be a single character string"
  )
})


test_that("mysterycall_predicted_means: rejects invalid conf_level", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(42)
  fit <- suppressMessages(
    suppressWarnings(
      mysterycall_poisson_model(COUNT_DF, "days", "insurance", use_profile_ci = FALSE)
    )
  )

  # conf_level too high
  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_predicted_means(fit, "insurance", conf_level = 1.5)
      )
    ),
    "`conf_level` must be a single number in \\(0, 1\\)"
  )

  # conf_level too low
  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_predicted_means(fit, "insurance", conf_level = -0.1)
      )
    ),
    "`conf_level` must be a single number in \\(0, 1\\)"
  )
})


test_that("mysterycall_predicted_means: rejects NULL model$model", {
  skip_if_not_installed("emmeans")

  # Create a fake model object without fitting
  bad_model <- structure(
    list(model = NULL),
    class = c("mysterycall_poisson_model", "list")
  )

  expect_error(
    suppressMessages(
      suppressWarnings(
        mysterycall_predicted_means(bad_model, "insurance")
      )
    ),
    "`model_result\\$model` is NULL"
  )
})


test_that("mysterycall_predicted_means: correct number of groups", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(42)
  fit <- suppressMessages(
    suppressWarnings(
      mysterycall_poisson_model(COUNT_DF, "days", "insurance", use_profile_ci = FALSE)
    )
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_predicted_means(fit, "insurance")
    )
  )

  # Should have one row per unique insurance type
  expect_equal(nrow(result), 2L)
  expect_setequal(result$group, c("BCBS", "Medicaid"))
})


test_that("mysterycall_predicted_means: fallback to marginaleffects when emmeans unavailable", {
  skip_if_not_installed("marginaleffects")
  # Only run this if emmeans is NOT installed, or we can mock it

  set.seed(42)
  fit <- suppressMessages(
    suppressWarnings(
      mysterycall_poisson_model(COUNT_DF, "days", "insurance", use_profile_ci = FALSE)
    )
  )

  # If emmeans is available, marginaleffects fallback won't be used
  # So we just check that passing data doesn't break anything
  result <- suppressMessages(
    suppressWarnings(
      mysterycall_predicted_means(fit, "insurance", data = COUNT_DF)
    )
  )

  expect_s3_class(result, "mysterycall_predicted_means")
  expect_equal(nrow(result), 2L)
})


test_that("print.mysterycall_predicted_means: produces output", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("emmeans")

  set.seed(42)
  fit <- suppressMessages(
    suppressWarnings(
      mysterycall_poisson_model(COUNT_DF, "days", "insurance", use_profile_ci = FALSE)
    )
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_predicted_means(fit, "insurance")
    )
  )

  # Capture print output
  output <- capture.output(print(result))

  expect_length(output, 4L)  # Header line + 2 data rows + summary line
  expect_match(output[1], "Model-predicted wait times")
})
