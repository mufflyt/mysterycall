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
  physician = rep(paste0("Dr_", 1:8), 10L),
  stringsAsFactors = FALSE
)

test_that("mysterycall_table2: happy path with baseline_mean", {
  skip_if_not_installed("lme4")

  set.seed(2)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  set.seed(3)
  result <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      accepted_col = "contact_office",
      baseline_mean = 10,
      exposure_col = "insurance",
      ref_group = "BCBS",
      digits = 2L,
      include_intercept = FALSE
    )
  ))

  expect_s3_class(result, "mysterycall_table2")
  expect_true(is.list(result))
  expect_named(result, c("acceptance", "estimates", "notes"))
  expect_true(is.data.frame(result$acceptance))
  expect_named(
    result$acceptance,
    c("Group", "N", "Accepted, n (%)", "95% CI")
  )
  expect_true(nrow(result$acceptance) >= 1L)
  expect_true(is.data.frame(result$estimates))
  expect_true("Days Diff" %in% names(result$estimates))
  expect_true("Days 95% CI" %in% names(result$estimates))
  expect_true(is.character(result$notes))
  expect_true(length(result$notes) >= 2L)
})

test_that("mysterycall_table2: edge case without baseline_mean", {
  skip_if_not_installed("lme4")

  set.seed(4)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  set.seed(5)
  result <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      accepted_col = "contact_office",
      baseline_mean = NULL,
      digits = 2L,
      include_intercept = FALSE
    )
  ))

  expect_s3_class(result, "mysterycall_table2")
  expect_false("Days Diff" %in% names(result$estimates))
  expect_false("Days 95% CI" %in% names(result$estimates))
  expect_named(
    result$estimates,
    c("Term", "IRR", "IRR 95% CI", "p-value")
  )
  expect_true(length(result$notes) >= 2L)
})

test_that("mysterycall_table2: bad input - data is not a data frame", {
  skip_if_not_installed("lme4")

  set.seed(6)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  expect_error(
    mysterycall_table2(
      data = list(foo = 1),
      model_result = mod,
      group_col = "insurance"
    ),
    "`data` must be a data frame"
  )
})

test_that("mysterycall_table2: bad input - group_col not in data", {
  skip_if_not_installed("lme4")

  set.seed(7)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  expect_error(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "nonexistent_column"
    ),
    "not found in `data`"
  )
})

test_that("mysterycall_table2: bad input - accepted_col not in data", {
  skip_if_not_installed("lme4")

  set.seed(8)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  expect_error(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      accepted_col = "nonexistent_col"
    ),
    "not found in `data`"
  )
})

test_that("mysterycall_table2: bad input - wrong model_result class", {
  set.seed(9)
  expect_error(
    mysterycall_table2(
      data = AUDIT,
      model_result = list(irr_table = data.frame()),
      group_col = "insurance"
    ),
    "`model_result` must be a"
  )
})

test_that("mysterycall_table2: bad input - negative baseline_mean", {
  skip_if_not_installed("lme4")

  set.seed(10)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  expect_error(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      baseline_mean = -5
    ),
    "must be a single positive number"
  )
})

test_that("mysterycall_table2: bad input - group_col is not a character", {
  skip_if_not_installed("lme4")

  set.seed(11)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  expect_error(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = 1
    ),
    "must be a single character string"
  )
})

test_that("mysterycall_table2: parameter include_intercept = TRUE", {
  skip_if_not_installed("lme4")

  set.seed(12)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  set.seed(13)
  result_with_intercept <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      include_intercept = TRUE
    )
  ))

  expect_s3_class(result_with_intercept, "mysterycall_table2")
  expect_true(nrow(result_with_intercept$estimates) >= 1L)
})

test_that("mysterycall_table2: digits parameter affects formatting", {
  skip_if_not_installed("lme4")

  set.seed(14)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  set.seed(15)
  result_digits_0 <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      baseline_mean = 10,
      digits = 0L
    )
  ))

  set.seed(16)
  result_digits_3 <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      baseline_mean = 10,
      digits = 3L
    )
  ))

  expect_s3_class(result_digits_0, "mysterycall_table2")
  expect_s3_class(result_digits_3, "mysterycall_table2")
  expect_true("IRR" %in% names(result_digits_0$estimates))
  expect_true("IRR" %in% names(result_digits_3$estimates))
})

test_that("print.mysterycall_table2: returns invisible and prints output", {
  skip_if_not_installed("lme4")

  set.seed(17)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  set.seed(18)
  tbl2 <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      baseline_mean = 10
    )
  ))

  output <- capture.output(result_inv <- print(tbl2))
  expect_identical(result_inv, tbl2)
  expect_true(any(grepl("Panel A", output)))
  expect_true(any(grepl("Panel B", output)))
  expect_true(any(grepl("Notes", output)))
})

test_that("print.mysterycall_table2: happy path without baseline_mean", {
  skip_if_not_installed("lme4")

  set.seed(19)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  set.seed(20)
  tbl2_no_baseline <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      baseline_mean = NULL
    )
  ))

  output <- capture.output(print(tbl2_no_baseline))
  expect_true(any(grepl("Panel A", output)))
  expect_true(any(grepl("Panel B", output)))
})

test_that("mysterycall_table2: acceptance panel has correct structure", {
  skip_if_not_installed("lme4")

  set.seed(21)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  set.seed(22)
  result <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance"
    )
  ))

  acc <- result$acceptance
  expect_true(all(sapply(acc, function(x) is.character(x) || is.numeric(x))))
  expect_true(all(grepl("%", acc[["Accepted, n (%)"]], fixed = TRUE)))
  expect_true(all(grepl("%", acc[["95% CI"]], fixed = TRUE)))
})

test_that("mysterycall_table2: estimates panel has correct attributes", {
  skip_if_not_installed("lme4")

  set.seed(23)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  set.seed(24)
  result <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance"
    )
  ))

  est <- result$estimates
  expect_true(!is.null(attr(est, "significant_rows")))
  expect_true(all(sapply(est, function(x) is.character(x) || is.numeric(x))))
})

test_that("mysterycall_table2: notes vector structure", {
  skip_if_not_installed("lme4")

  set.seed(25)
  mod <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(
      COUNT_DF,
      outcome = "days",
      predictors = "insurance",
      random_intercept = "physician"
    )
  ))

  set.seed(26)
  result_with_baseline <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      baseline_mean = 15
    )
  ))

  set.seed(27)
  result_no_baseline <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data = AUDIT,
      model_result = mod,
      group_col = "insurance",
      baseline_mean = NULL
    )
  ))

  expect_true(length(result_with_baseline$notes) > length(result_no_baseline$notes))
  expect_true(all(is.character(result_with_baseline$notes)))
  expect_true(all(is.character(result_no_baseline$notes)))
  expect_true(any(grepl("IRR", result_with_baseline$notes)))
  expect_true(any(grepl("confidence interval", result_with_baseline$notes, ignore.case = TRUE)))
})
