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
  physician                        = c("Dr_1", "Dr_1", "Dr_2", "Dr_2"),
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


test_that("mysterycall_table2 returns valid object with minimal inputs", {
  skip_if_not_installed("lme4")

  set.seed(42)
  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(COUNT_DF, "days", "insurance", "physician")
  ))

  result <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data      = AUDIT,
      model_result = model,
      group_col = "insurance"
    )
  ))

  expect_s3_class(result, "mysterycall_table2")
  expect_named(result, c("acceptance", "estimates", "notes"))
  expect_s3_class(result$acceptance, "data.frame")
  expect_s3_class(result$estimates, "data.frame")
  expect_type(result$notes, "character")
})


test_that("mysterycall_table2 output has correct structure", {
  skip_if_not_installed("lme4")

  set.seed(42)
  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(COUNT_DF, "days", "insurance", "physician")
  ))

  result <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data      = AUDIT,
      model_result = model,
      group_col = "insurance"
    )
  ))

  # Panel A: acceptance
  expect_true(nrow(result$acceptance) > 0L)
  expect_true(all(c("Group", "N", "Accepted, n (%)", "95% CI") %in% names(result$acceptance)))

  # Panel B: estimates
  expect_true(nrow(result$estimates) > 0L)
  expect_true(all(c("Term", "IRR", "IRR 95% CI", "p-value") %in% names(result$estimates)))

  # Notes
  expect_true(length(result$notes) >= 2L)
})


test_that("mysterycall_table2 adds Days columns when baseline_mean provided", {
  skip_if_not_installed("lme4")

  set.seed(42)
  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(COUNT_DF, "days", "insurance", "physician")
  ))

  result <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data         = AUDIT,
      model_result = model,
      group_col    = "insurance",
      baseline_mean = 7.5,
      exposure_col = "insurance"
    )
  ))

  expect_true(all(c("Days Diff", "Days 95% CI") %in% names(result$estimates)))
  expect_equal(length(result$notes), 3L)
})


test_that("mysterycall_table2 errors on invalid data argument", {
  skip_if_not_installed("lme4")

  set.seed(42)
  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(COUNT_DF, "days", "insurance", "physician")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_table2(
        data         = as.list(AUDIT),
        model_result = model,
        group_col    = "insurance"
      )
    )),
    "`data` must be a data frame"
  )
})


test_that("mysterycall_table2 errors on invalid group_col argument", {
  skip_if_not_installed("lme4")

  set.seed(42)
  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(COUNT_DF, "days", "insurance", "physician")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_table2(
        data         = AUDIT,
        model_result = model,
        group_col    = c("insurance", "wave")
      )
    )),
    "`group_col` must be a single character string"
  )
})


test_that("mysterycall_table2 errors on missing group_col in data", {
  skip_if_not_installed("lme4")

  set.seed(42)
  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(COUNT_DF, "days", "insurance", "physician")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_table2(
        data         = AUDIT,
        model_result = model,
        group_col    = "nonexistent_column"
      )
    )),
    "Column 'nonexistent_column' not found"
  )
})


test_that("mysterycall_table2 errors on invalid model_result", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_table2(
        data         = AUDIT,
        model_result = list(some = "object"),
        group_col    = "insurance"
      )
    )),
    "`model_result` must be a `mysterycall_poisson_model` or `mysterycall_nb_model`"
  )
})


test_that("mysterycall_table2 errors on invalid baseline_mean", {
  skip_if_not_installed("lme4")

  set.seed(42)
  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(COUNT_DF, "days", "insurance", "physician")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_table2(
        data         = AUDIT,
        model_result = model,
        group_col    = "insurance",
        baseline_mean = -5
      )
    )),
    "`baseline_mean` must be a single positive number"
  )
})


test_that("print.mysterycall_table2 produces output without error", {
  skip_if_not_installed("lme4")

  set.seed(42)
  model <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(COUNT_DF, "days", "insurance", "physician")
  ))

  result <- suppressMessages(suppressWarnings(
    mysterycall_table2(
      data      = AUDIT,
      model_result = model,
      group_col = "insurance"
    )
  ))

  expect_output(print(result), "Panel A")
  expect_output(print(result), "Panel B")
  expect_output(print(result), "Notes")
})
