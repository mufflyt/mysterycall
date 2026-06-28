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

# ---- mysterycall_irr_table tests ----

test_that("mysterycall_irr_table returns gt_tbl with p_value column", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    term       = c("BCBS", "Medicare"),
    irr        = c(1.05, 0.95),
    ci_lower   = c(0.98, 0.87),
    ci_upper   = c(1.13, 1.04),
    p_value    = c(0.001, 0.15),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_irr_table(irr_data)))

  expect_s3_class(result, "gt_tbl")
})

test_that("mysterycall_irr_table works with 'level' column instead of term", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    level      = c("Group A", "Group B"),
    irr        = c(1.2, 0.8),
    ci_lower   = c(1.0, 0.6),
    ci_upper   = c(1.4, 1.0),
    p_value    = c(0.01, 0.5),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_irr_table(irr_data)))

  expect_s3_class(result, "gt_tbl")
})

test_that("mysterycall_irr_table handles p_value_fmt column", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    term        = c("A", "B"),
    irr         = c(1.1, 0.9),
    ci_lower    = c(1.0, 0.8),
    ci_upper    = c(1.2, 1.0),
    p_value_fmt = c("< 0.001", "0.234"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_irr_table(irr_data)))

  expect_s3_class(result, "gt_tbl")
})

test_that("mysterycall_irr_table handles NA p_values gracefully", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    term     = c("A", "B", "C"),
    irr      = c(1.0, 1.2, 0.8),
    ci_lower = c(0.9, 1.0, 0.6),
    ci_upper = c(1.1, 1.4, 1.0),
    p_value  = c(NA_real_, 0.03, 0.5),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_irr_table(irr_data)))

  expect_s3_class(result, "gt_tbl")
})

test_that("mysterycall_irr_table handles zero-row input", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    term     = character(0),
    irr      = numeric(0),
    ci_lower = numeric(0),
    ci_upper = numeric(0),
    p_value  = numeric(0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_irr_table(irr_data)))

  expect_s3_class(result, "gt_tbl")
})

test_that("mysterycall_irr_table throws error when term/level missing", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    irr      = c(1.0, 1.2),
    ci_lower = c(0.9, 1.0),
    ci_upper = c(1.1, 1.4),
    p_value  = c(0.01, 0.5),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_irr_table(irr_data))
})

test_that("mysterycall_irr_table throws error when p_value and p_value_fmt both missing", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    term     = c("A", "B"),
    irr      = c(1.0, 1.2),
    ci_lower = c(0.9, 1.0),
    ci_upper = c(1.1, 1.4),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_irr_table(irr_data))
})

test_that("mysterycall_irr_table throws error when required irr columns missing", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    term     = c("A", "B"),
    irr      = c(1.0, 1.2),
    p_value  = c(0.01, 0.5),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_irr_table(irr_data))
})

test_that("mysterycall_irr_table respects digits parameter", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    term     = c("A"),
    irr      = c(1.123456),
    ci_lower = c(0.987654),
    ci_upper = c(1.234567),
    p_value  = c(0.05),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_irr_table(irr_data, digits = 3L)
  ))

  expect_s3_class(result, "gt_tbl")
})

test_that("mysterycall_irr_table customizes title and subtitle", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    term     = c("A"),
    irr      = c(1.0),
    ci_lower = c(0.9),
    ci_upper = c(1.1),
    p_value  = c(0.5),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_irr_table(
    irr_data,
    title = "Custom Title",
    subtitle = "Custom Subtitle"
  )))

  expect_s3_class(result, "gt_tbl")
})

test_that("mysterycall_irr_table assigns stars correctly by p-value", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    term     = c("A", "B", "C", "D"),
    irr      = c(1.1, 1.2, 1.3, 1.4),
    ci_lower = c(1.0, 1.1, 1.2, 1.3),
    ci_upper = c(1.2, 1.3, 1.4, 1.5),
    p_value  = c(0.0001, 0.005, 0.03, 0.5),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_irr_table(irr_data, add_significance_stars = TRUE)
  ))

  expect_s3_class(result, "gt_tbl")
})

test_that("mysterycall_irr_table omits stars when add_significance_stars=FALSE", {
  skip_if_not_installed("gt")

  irr_data <- data.frame(
    term     = c("A", "B"),
    irr      = c(1.1, 1.2),
    ci_lower = c(1.0, 1.1),
    ci_upper = c(1.2, 1.3),
    p_value  = c(0.001, 0.5),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_irr_table(irr_data, add_significance_stars = FALSE)
  ))

  expect_s3_class(result, "gt_tbl")
})

# ---- mysterycall_model_gt tests ----

test_that("mysterycall_model_gt returns gt_tbl from poisson result", {
  skip_if_not_installed("gt")

  set.seed(2)
  model <- suppressMessages(suppressWarnings(mysterycall_simple_poisson(
    COUNT_DF,
    outcome = "days",
    group = "insurance",
    use_profile_ci = FALSE
  )))

  result <- suppressMessages(suppressWarnings(mysterycall_model_gt(model)))

  expect_s3_class(result, "gt_tbl")
})

test_that("mysterycall_model_gt throws error for non-poisson object", {
  skip_if_not_installed("gt")

  not_poisson <- data.frame(x = 1:5)

  expect_error(mysterycall_model_gt(not_poisson))
})

test_that("mysterycall_model_gt passes ... arguments to mysterycall_irr_table", {
  skip_if_not_installed("gt")

  set.seed(3)
  model <- suppressMessages(suppressWarnings(mysterycall_simple_poisson(
    COUNT_DF,
    outcome = "days",
    group = "insurance",
    use_profile_ci = FALSE
  )))

  result <- suppressMessages(suppressWarnings(mysterycall_model_gt(
    model,
    title = "Custom Poisson Title",
    digits = 3L
  )))

  expect_s3_class(result, "gt_tbl")
})
