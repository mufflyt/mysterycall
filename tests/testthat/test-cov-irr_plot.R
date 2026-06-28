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

test_that("mysterycall_irr_plot accepts data frame with required columns and returns ggplot", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    term = c("insurance_BCBS", "age_years"),
    irr = c(1.25, 0.98),
    ci_lower = c(1.05, 0.95),
    ci_upper = c(1.48, 1.01),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(mysterycall_irr_plot(df))

  expect_s3_class(result, "ggplot")
  expect_true(inherits(result, "ggplot"))
})

test_that("mysterycall_irr_plot colors by significance when p_value is present", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    term = c("insurance_BCBS", "age_years", "(Intercept)"),
    irr = c(1.25, 0.98, 0.50),
    ci_lower = c(1.05, 0.95, 0.40),
    ci_upper = c(1.48, 1.01, 0.62),
    p_value = c(0.02, 0.15, 0.001),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(mysterycall_irr_plot(df))

  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_irr_plot drops intercept by default", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    term = c("insurance_BCBS", "(Intercept)"),
    irr = c(1.25, 0.50),
    ci_lower = c(1.05, 0.40),
    ci_upper = c(1.48, 0.62),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(mysterycall_irr_plot(df, include_intercept = FALSE))

  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_irr_plot includes intercept when requested", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    term = c("insurance_BCBS", "(Intercept)"),
    irr = c(1.25, 0.50),
    ci_lower = c(1.05, 0.40),
    ci_upper = c(1.48, 0.62),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(mysterycall_irr_plot(df, include_intercept = TRUE))

  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_irr_plot applies custom parameters (colors, labels, x_log)", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    term = c("term_A", "term_B"),
    irr = c(1.5, 2.0),
    ci_lower = c(1.2, 1.7),
    ci_upper = c(1.9, 2.4),
    p_value = c(0.01, 0.05),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(
    mysterycall_irr_plot(
      df,
      color_sig = "#FF0000",
      color_ns = "#0000FF",
      x_label = "Custom IRR Label",
      title = "Forest Plot",
      x_log = TRUE,
      point_size = 5,
      reference_line = 1.2
    )
  )

  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_irr_plot errors when data frame missing required columns", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    term = c("term_A", "term_B"),
    irr = c(1.5, 2.0),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_irr_plot(df),
    "missing required columns"
  )
})

test_that("mysterycall_irr_plot errors when x is invalid type", {
  skip_if_not_installed("ggplot2")

  expect_error(
    mysterycall_irr_plot(list(a = 1, b = 2)),
    "must be a `mysterycall_poisson_model`"
  )
})

test_that("mysterycall_irr_plot errors when no rows remain after filtering", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    term = c("(Intercept)"),
    irr = c(0.50),
    ci_lower = c(0.40),
    ci_upper = c(0.62),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_irr_plot(df, include_intercept = FALSE),
    "No rows remain after filtering"
  )
})
