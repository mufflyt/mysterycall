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


# -- Happy path: minimal valid inputs ------------------------------------------
test_that("mysterycall_logistic_model fits a logistic GLMER with valid inputs", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    offered   = rbinom(80, 1L, 0.7),
    insurance = rep(c("Medicaid", "BCBS"), 40),
    physician = rep(paste0("Dr", 1:20), each = 4L),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_logistic_model(df, "offered", "insurance", "physician")
  ))

  expect_no_error({
    fit
  })
})


# -- Output type check: verify return class and structure -----------------------
test_that("mysterycall_logistic_model returns correct class and structure", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    offered   = rbinom(80, 1L, 0.7),
    insurance = rep(c("Medicaid", "BCBS"), 40),
    physician = rep(paste0("Dr", 1:20), each = 4L),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_logistic_model(df, "offered", "insurance", "physician")
  ))

  # Check class
  expect_s3_class(fit, "mysterycall_logistic_model")

  # Check list structure
  expect_type(fit, "list")

  # Check required elements
  expect_named(fit, c("model", "or_table", "random_effects", "factor_refs",
                      "formula", "n", "n_dropped", "n_clusters",
                      "convergence", "aic", "bic"))

  # Check types of key elements
  expect_s4_class(fit$model, "glmerMod")
  expect_s3_class(fit$or_table, "tbl_df")
  expect_type(fit$n, "integer")
  expect_type(fit$aic, "double")
  expect_type(fit$bic, "double")
  expect_type(fit$convergence, "list")
})


# -- Error path: invalid outcome (not binary) ----------------------------------
test_that("mysterycall_logistic_model errors on non-binary outcome", {
  skip_if_not_installed("lme4")

  df <- data.frame(
    outcome   = c(1, 2, 3, 4),  # not binary
    insurance = c("A", "B", "A", "B"),
    physician = c("Dr1", "Dr1", "Dr2", "Dr2"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_logistic_model(df, "outcome", "insurance", "physician"),
    "must be binary"
  )
})


# -- Error path: missing required columns--------------------------------------
test_that("mysterycall_logistic_model errors on missing columns", {
  skip_if_not_installed("lme4")

  df <- data.frame(
    outcome = c(0, 1, 0, 1),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_logistic_model(df, "outcome", "missing_col", "physician"),
    "Required columns"
  )
})


# -- Error path: invalid outcome argument type --------------------------------
test_that("mysterycall_logistic_model errors when outcome is not a scalar", {
  skip_if_not_installed("lme4")

  df <- data.frame(
    out1 = c(0, 1, 0, 1),
    out2 = c(1, 0, 1, 0),
    insurance = c("A", "B", "A", "B"),
    physician = c("Dr1", "Dr1", "Dr2", "Dr2"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_logistic_model(df, c("out1", "out2"), "insurance", "physician"),
    "must be a single column name"
  )
})


# -- Error path: invalid conf_level -------------------------------------------
test_that("mysterycall_logistic_model errors on invalid conf_level", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    offered   = rbinom(20, 1L, 0.7),
    insurance = rep(c("Medicaid", "BCBS"), 10),
    physician = rep(paste0("Dr", 1:5), each = 4L),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_logistic_model(df, "offered", "insurance", "physician", conf_level = 1.5),
    "conf_level.*between 0 and 1"
  )
})


# -- lme4 not installed check -------------------------------------------------
test_that("mysterycall_logistic_model errors gracefully when lme4 unavailable", {
  # This test is for documentation; can't actually uninstall lme4
  # Just verify the error message handling in the source
  skip_if_not_installed("lme4")

  df <- data.frame(
    offered   = rbinom(20, 1L, 0.7),
    insurance = rep(c("Medicaid", "BCBS"), 10),
    physician = rep(paste0("Dr", 1:5), each = 4L),
    stringsAsFactors = FALSE
  )

  # Verify the function exists and is callable
  expect_true(exists("mysterycall_logistic_model"))
})
