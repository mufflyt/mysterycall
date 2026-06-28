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

test_that("mysterycall_impute_calls: happy path with missing outcome values", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    offered   = c(1L, 1L, 0L, 1L, 1L, NA_integer_, 0L, 1L, NA_integer_, 1L),
    insurance = rep(c("Medicaid", "BCBS"), 5L),
    physician = rep(paste0("Dr", 1:5), 2L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_impute_calls(
      data             = df,
      outcome_col      = "offered",
      predictors       = "insurance",
      random_intercept = "physician",
      m                = 5L,
      maxit            = 3L,
      seed             = 42L,
      conf_level       = 0.95,
      verbose          = FALSE
    )
  )

  expect_s3_class(result, "mysterycall_impute_calls")
  expect_true(is.list(result))
  expect_named(result, c("pooled_table", "m", "n_missing", "pct_missing",
                          "individual_fits", "sentence"))
  expect_equal(result$m, 5L)
  expect_equal(result$n_missing, 2L)
  expect_equal(result$pct_missing, 20.0)
  expect_equal(length(result$individual_fits), 5L)
  expect_true(is.data.frame(result$pooled_table))
  expect_true(nrow(result$pooled_table) > 0L)
  expect_true(is.character(result$sentence))
})

test_that("mysterycall_impute_calls: warns on zero or minimal missingness", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    offered   = c(1L, 1L, 0L, 1L, 1L, 1L, 0L, 1L, 1L, 1L),
    insurance = rep(c("Medicaid", "BCBS"), 5L),
    physician = rep(paste0("Dr", 1:5), 2L),
    stringsAsFactors = FALSE
  )

  # No missing values: should warn
  expect_warning(
    suppressMessages(
      mysterycall_impute_calls(
        data             = df,
        outcome_col      = "offered",
        predictors       = "insurance",
        random_intercept = "physician",
        m                = 3L,
        seed             = 42L,
        verbose          = FALSE
      )
    ),
    "No missing values"
  )
})

test_that("mysterycall_impute_calls: rejects missing required argument", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    offered   = c(1L, 1L, 0L, NA_integer_),
    insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
    physician = c("Dr1", "Dr1", "Dr2", "Dr2"),
    stringsAsFactors = FALSE
  )

  # Missing outcome_col argument
  expect_error(
    mysterycall_impute_calls(
      data             = df,
      predictors       = "insurance",
      random_intercept = "physician",
      m                = 3L,
      seed             = 42L
    ),
    NA
  )
})

test_that("mysterycall_impute_calls: rejects invalid outcome_col type", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    offered   = c(1L, 1L, 0L, NA_integer_),
    insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
    physician = c("Dr1", "Dr1", "Dr2", "Dr2"),
    stringsAsFactors = FALSE
  )

  # outcome_col as numeric instead of character
  expect_error(
    mysterycall_impute_calls(
      data             = df,
      outcome_col      = 1L,
      predictors       = "insurance",
      random_intercept = "physician",
      m                = 3L,
      seed             = 42L
    ),
    "must be a single character"
  )
})

test_that("mysterycall_impute_calls: rejects invalid m parameter", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    offered   = c(1L, 1L, 0L, NA_integer_),
    insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
    physician = c("Dr1", "Dr1", "Dr2", "Dr2"),
    stringsAsFactors = FALSE
  )

  # m < 2
  expect_error(
    mysterycall_impute_calls(
      data             = df,
      outcome_col      = "offered",
      predictors       = "insurance",
      random_intercept = "physician",
      m                = 1L,
      seed             = 42L
    ),
    "must be an integer >= 2"
  )
})

test_that("print.mysterycall_impute_calls: formats output correctly", {
  skip_if_not_installed("mice")
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    offered   = c(1L, 1L, 0L, 1L, 1L, NA_integer_, 0L, 1L, NA_integer_, 1L),
    insurance = rep(c("Medicaid", "BCBS"), 5L),
    physician = rep(paste0("Dr", 1:5), 2L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_impute_calls(
      data             = df,
      outcome_col      = "offered",
      predictors       = "insurance",
      random_intercept = "physician",
      m                = 3L,
      maxit            = 2L,
      seed             = 42L,
      verbose          = FALSE
    )
  )

  # Capture print output
  output <- capture.output(print(result))

  # Check that output contains expected elements
  expect_true(any(grepl("Multiple Imputation", output)))
  expect_true(any(grepl("Pooled fixed effects", output)))
  expect_true(any(grepl("m = 3", output)))
})
