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


test_that("mysterycall_sensitivity runs without error on valid inputs with poisson family", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait    = rpois(80, 18),
    ins     = rep(c("Medicaid", "BCBS"), 40),
    phys    = rep(paste0("Dr", 1:20), each = 4),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(
      df,
      outcome = "wait",
      predictors = "ins",
      random_intercept = "phys",
      family = "poisson"
    )
  ))

  expect_s3_class(result, "mysterycall_sensitivity")
})


test_that("mysterycall_sensitivity returns correct structure with all required fields", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait    = rpois(80, 18),
    ins     = rep(c("Medicaid", "BCBS"), 40),
    phys    = rep(paste0("Dr", 1:20), each = 4),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(
      df,
      outcome = "wait",
      predictors = "ins",
      random_intercept = "phys",
      family = "poisson"
    )
  ))

  expect_named(result, c("table", "models", "subsets_run", "family"))
  expect_true(is.data.frame(result$table))
  expect_true(is.list(result$models))
  expect_true(is.character(result$subsets_run))
  expect_equal(result$family, "poisson")
  expect_true(all(c("subset_name", "term", "IRR", "ci_lower", "ci_upper", "p_value", "model_type")
                   %in% names(result$table)))
})


test_that("mysterycall_sensitivity errors when data is not a data frame", {
  skip_if_not_installed("lme4")

  expect_error(
    mysterycall_sensitivity(
      list(a = 1),
      outcome = "wait",
      predictors = "ins",
      random_intercept = "phys"
    ),
    "data.*must be a data frame"
  )
})


test_that("mysterycall_sensitivity errors when outcome is not in data", {
  skip_if_not_installed("lme4")

  set.seed(42)
  df <- data.frame(
    wait = rpois(80, 18),
    ins = rep(c("Medicaid", "BCBS"), 40),
    phys = rep(paste0("Dr", 1:20), each = 4),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressWarnings(suppressMessages(
      mysterycall_sensitivity(
        df,
        outcome = "nonexistent_col",
        predictors = "ins",
        random_intercept = "phys"
      )
    )),
    "outcome.*single column name"
  )
})
