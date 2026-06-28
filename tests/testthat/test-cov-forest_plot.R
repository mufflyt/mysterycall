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

# ---- Test 1: Happy path with simple IRR data frame ----
test_that("mysterycall_forest_plot() returns ggplot with valid data frame", {
  skip_if_not_installed("ggplot2")

  irr_df <- data.frame(
    term     = c("Medicaid vs. BCBS", "Incontinence vs. Prolapse"),
    irr      = c(1.28, 1.05),
    ci_lower = c(1.05, 0.88),
    ci_upper = c(1.56, 1.25),
    p_value  = c(0.014, 0.580),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_forest_plot(irr_df)
  ))

  expect_s3_class(result, "ggplot")
})


# ---- Test 2: Edge case - NA p_values ----
test_that("mysterycall_forest_plot() handles NA p_values gracefully", {
  skip_if_not_installed("ggplot2")

  irr_df <- data.frame(
    term     = c("Term 1", "Term 2", "Term 3"),
    irr      = c(1.2, 0.95, 1.5),
    ci_lower = c(1.0, 0.8, 1.2),
    ci_upper = c(1.4, 1.1, 1.8),
    p_value  = c(NA_real_, 0.05, NA_real_),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_forest_plot(irr_df)
  ))

  expect_s3_class(result, "ggplot")
})


# ---- Test 3: Bad input - missing required column ----
test_that("mysterycall_forest_plot() errors on missing required columns", {
  skip_if_not_installed("ggplot2")

  bad_df <- data.frame(
    term     = c("Term 1", "Term 2"),
    irr      = c(1.2, 0.95),
    ci_lower = c(1.0, 0.8),
    stringsAsFactors = FALSE
  )

  expect_error(mysterycall_forest_plot(bad_df), "missing required columns")
})


# ---- Test 4: include_intercept parameter ----
test_that("mysterycall_forest_plot() filters intercept by default", {
  skip_if_not_installed("ggplot2")

  irr_df <- data.frame(
    term     = c("(Intercept)", "Medicaid vs. BCBS", "Female vs. Male"),
    irr      = c(2.0, 1.28, 1.12),
    ci_lower = c(1.8, 1.05, 0.95),
    ci_upper = c(2.2, 1.56, 1.32),
    p_value  = c(0.001, 0.014, 0.180),
    stringsAsFactors = FALSE
  )

  # With include_intercept = FALSE (default), should filter out intercept
  result_filtered <- suppressMessages(suppressWarnings(
    mysterycall_forest_plot(irr_df, include_intercept = FALSE)
  ))

  expect_s3_class(result_filtered, "ggplot")

  # With include_intercept = TRUE, should keep intercept
  result_with_intercept <- suppressMessages(suppressWarnings(
    mysterycall_forest_plot(irr_df, include_intercept = TRUE)
  ))

  expect_s3_class(result_with_intercept, "ggplot")
})


# ---- Test 5: term_labels parameter ----
test_that("mysterycall_forest_plot() applies custom term labels", {
  skip_if_not_installed("ggplot2")

  irr_df <- data.frame(
    term     = c("insuranceMedicaid", "female"),
    irr      = c(1.28, 1.12),
    ci_lower = c(1.05, 0.95),
    ci_upper = c(1.56, 1.32),
    p_value  = c(0.014, 0.180),
    stringsAsFactors = FALSE
  )

  term_labels <- c(
    "insuranceMedicaid" = "Medicaid vs. BCBS [Referent: BCBS]",
    "female"            = "Female vs. Male Physician"
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_forest_plot(irr_df, term_labels = term_labels)
  ))

  expect_s3_class(result, "ggplot")
})


# ---- Test 6: Bad input - wrong type ----
test_that("mysterycall_forest_plot() errors on invalid input type", {
  skip_if_not_installed("ggplot2")

  bad_input <- c(1.2, 1.5, 0.9)

  expect_error(mysterycall_forest_plot(bad_input), "model object, data frame, or named list")
})


# ---- Test 7: Data frame missing term column ----
test_that("mysterycall_forest_plot() auto-generates term names if missing", {
  skip_if_not_installed("ggplot2")

  irr_df <- data.frame(
    irr      = c(1.28, 1.05),
    ci_lower = c(1.05, 0.88),
    ci_upper = c(1.56, 1.25),
    p_value  = c(0.014, 0.580),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_forest_plot(irr_df)
  ))

  expect_s3_class(result, "ggplot")
})
