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


test_that("mysterycall_sensitivity happy path: valid inputs return correct structure", {
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
  expect_named(result, c("table", "models", "subsets_run", "family"))
  expect_true(is.data.frame(result$table))
  expect_true(is.list(result$models))
  expect_true(is.character(result$subsets_run))
  expect_equal(result$family, "poisson")
  expect_true(all(c("subset_name", "term", "IRR", "ci_lower", "ci_upper", "p_value", "model_type")
                   %in% names(result$table)))
  expect_true(nrow(result$table) > 0)
})


test_that("mysterycall_sensitivity with subset_var stratification", {
  skip_if_not_installed("lme4")

  set.seed(43)
  df <- data.frame(
    wait    = rpois(100, 18),
    ins     = rep(c("Medicaid", "BCBS"), 50),
    setting = rep(c("Urban", "Rural"), 50),
    phys    = rep(paste0("Dr", 1:20), each = 5),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(
      df,
      outcome = "wait",
      predictors = "ins",
      random_intercept = "phys",
      subset_var = "setting",
      family = "poisson"
    )
  ))

  expect_s3_class(result, "mysterycall_sensitivity")
  subset_names <- unique(result$table$subset_name)
  expect_true("Full sample" %in% subset_names)
  expect_true(length(result$subsets_run) >= 1)
})


test_that("mysterycall_sensitivity with exclude_zeros parameter", {
  skip_if_not_installed("lme4")

  set.seed(44)
  df <- data.frame(
    wait    = c(rpois(40, 18), rep(0L, 10), rpois(30, 18)),
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
      exclude_zeros = TRUE,
      family = "poisson"
    )
  ))

  expect_s3_class(result, "mysterycall_sensitivity")
  subset_names <- unique(result$table$subset_name)
  expect_true("Full sample" %in% subset_names)
})


test_that("mysterycall_sensitivity with baseline_mean computes days_diff", {
  skip_if_not_installed("lme4")

  set.seed(45)
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
      baseline_mean = 15.5,
      family = "poisson"
    )
  ))

  expect_s3_class(result, "mysterycall_sensitivity")
  expect_true("days_diff" %in% names(result$table))
  if (nrow(result$table) > 0 && !is.na(result$table$IRR[1])) {
    expected_diff <- 15.5 * (result$table$IRR[1] - 1)
    expect_equal(result$table$days_diff[1], expected_diff, tolerance = 1e-10)
  }
})


test_that("mysterycall_sensitivity errors with invalid input types", {
  skip_if_not_installed("lme4")

  set.seed(46)
  df <- data.frame(
    wait = rpois(80, 18),
    ins = rep(c("Medicaid", "BCBS"), 40),
    phys = rep(paste0("Dr", 1:20), each = 4),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_sensitivity(
      list(a = 1),
      outcome = "wait",
      predictors = "ins",
      random_intercept = "phys"
    ),
    "data.*must be a data frame"
  )

  expect_error(
    mysterycall_sensitivity(
      df,
      outcome = "nonexistent_col",
      predictors = "ins",
      random_intercept = "phys"
    ),
    "outcome.*not found"
  )

  expect_error(
    mysterycall_sensitivity(
      df,
      outcome = "wait",
      predictors = character(0),
      random_intercept = "phys"
    ),
    "predictors.*non-empty"
  )

  expect_error(
    mysterycall_sensitivity(
      df,
      outcome = "wait",
      predictors = "ins",
      random_intercept = "nonexistent_col"
    ),
    "random_intercept.*not found"
  )

  expect_error(
    mysterycall_sensitivity(
      df,
      outcome = "wait",
      predictors = "ins",
      random_intercept = "phys",
      baseline_mean = -5
    ),
    "baseline_mean.*positive"
  )
})


test_that("mysterycall_sensitivity family parameter variations", {
  skip_if_not_installed("lme4")

  set.seed(47)
  df <- data.frame(
    wait    = rpois(80, 18),
    ins     = rep(c("Medicaid", "BCBS"), 40),
    phys    = rep(paste0("Dr", 1:20), each = 4),
    stringsAsFactors = FALSE
  )

  result_auto <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(
      df,
      outcome = "wait",
      predictors = "ins",
      random_intercept = "phys",
      family = "auto"
    )
  ))

  expect_equal(result_auto$family, "auto")

  result_poisson <- suppressWarnings(suppressMessages(
    mysterycall_sensitivity(
      df,
      outcome = "wait",
      predictors = "ins",
      random_intercept = "phys",
      family = "poisson"
    )
  ))

  expect_equal(result_poisson$family, "poisson")
})


test_that("print.mysterycall_sensitivity displays output correctly", {
  skip_if_not_installed("lme4")

  set.seed(48)
  df <- data.frame(
    wait    = rpois(60, 18),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
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

  output <- capture.output(print(result))
  expect_true(length(output) > 0)
  expect_true(any(grepl("Sensitivity analysis", output)))
  expect_true(any(grepl("poisson", output, ignore.case = TRUE)))
})
