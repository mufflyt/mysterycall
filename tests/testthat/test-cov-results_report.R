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


test_that("mysterycall_results_report returns correct class and structure with valid model", {
  skip_if_not_installed("lme4")
  set.seed(1)
  df <- data.frame(
    wait = rpois(60, 21),
    ins = rep(c("Medicaid", "BCBS"), 30),
    phys = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(fit)
  ))

  expect_s3_class(report, "mysterycall_results_report")
  expect_type(report, "list")
  expect_true("combined_table" %in% names(report))
  expect_true("irr_days" %in% names(report))
  expect_true("paragraph" %in% names(report))
  expect_true("day_sentences" %in% names(report))
  expect_true("acceptance" %in% names(report))
  expect_true("docx_path" %in% names(report))
})


test_that("mysterycall_results_report includes irr_days and paragraph when baseline_mean and exposure_col supplied", {
  skip_if_not_installed("lme4")
  set.seed(1)
  df <- data.frame(
    wait = rpois(60, 21),
    ins = rep(c("Medicaid", "BCBS"), 30),
    phys = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(
      fit,
      baseline_mean = 21,
      exposure_col = "ins",
      ref_group = "BCBS"
    )
  ))

  expect_false(is.null(report$irr_days))
  expect_false(is.null(report$paragraph))
  expect_false(is.null(report$day_sentences))
  expect_type(report$paragraph, "character")
  expect_type(report$day_sentences, "character")
})


test_that("mysterycall_results_report omits irr_days and day_sentences when baseline_mean is NULL", {
  skip_if_not_installed("lme4")
  set.seed(2)
  df <- data.frame(
    wait = rpois(60, 21),
    ins = rep(c("Medicaid", "BCBS"), 30),
    phys = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(fit)
  ))

  expect_null(report$irr_days)
  expect_null(report$day_sentences)
})


test_that("mysterycall_results_report includes acceptance table when data parameter supplied", {
  skip_if_not_installed("lme4")
  set.seed(3)
  df <- data.frame(
    wait = rpois(60, 21),
    ins = rep(c("Medicaid", "BCBS"), 30),
    phys = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(
      fit,
      baseline_mean = 21,
      exposure_col = "ins",
      ref_group = "BCBS",
      data = AUDIT,
      group_col = "insurance"
    )
  ))

  expect_false(is.null(report$acceptance))
  expect_type(report$acceptance, "list")
})


test_that("mysterycall_results_report errors on invalid model_result class", {
  expect_error(
    mysterycall_results_report(list(some = "thing")),
    "must be a `mysterycall_poisson_model` or `mysterycall_nb_model`"
  )
  expect_error(
    mysterycall_results_report(data.frame()),
    "must be a `mysterycall_poisson_model` or `mysterycall_nb_model`"
  )
})


test_that("mysterycall_results_report errors on invalid baseline_mean", {
  skip_if_not_installed("lme4")
  set.seed(4)
  df <- data.frame(
    wait = rpois(60, 21),
    ins = rep(c("Medicaid", "BCBS"), 30),
    phys = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    mysterycall_results_report(fit, baseline_mean = -5),
    "must be a single positive number or NULL"
  )
  expect_error(
    mysterycall_results_report(fit, baseline_mean = 0),
    "must be a single positive number or NULL"
  )
  expect_error(
    mysterycall_results_report(fit, baseline_mean = c(5, 10)),
    "must be a single positive number or NULL"
  )
})


test_that("mysterycall_results_report errors on invalid exposure_col", {
  skip_if_not_installed("lme4")
  set.seed(5)
  df <- data.frame(
    wait = rpois(60, 21),
    ins = rep(c("Medicaid", "BCBS"), 30),
    phys = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    mysterycall_results_report(fit, exposure_col = 123),
    "must be a single character string or NULL"
  )
  expect_error(
    mysterycall_results_report(fit, exposure_col = c("ins", "other")),
    "must be a single character string or NULL"
  )
})


test_that("mysterycall_results_report errors when data is not a data frame", {
  skip_if_not_installed("lme4")
  set.seed(6)
  df <- data.frame(
    wait = rpois(60, 21),
    ins = rep(c("Medicaid", "BCBS"), 30),
    phys = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    mysterycall_results_report(fit, data = "not a data frame"),
    "must be a data frame or NULL"
  )
  expect_error(
    mysterycall_results_report(fit, data = list(a = 1)),
    "must be a data frame or NULL"
  )
})


test_that("mysterycall_results_report print method displays all components", {
  skip_if_not_installed("lme4")
  set.seed(7)
  df <- data.frame(
    wait = rpois(60, 21),
    ins = rep(c("Medicaid", "BCBS"), 30),
    phys = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )
  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(
      fit,
      baseline_mean = 21,
      exposure_col = "ins",
      ref_group = "BCBS",
      data = AUDIT,
      group_col = "insurance"
    )
  ))

  output <- capture.output(print(report))
  expect_type(output, "character")
  expect_true(any(grepl("Combined Results Table", output)))
  expect_true(any(grepl("Results Paragraph", output)))
  expect_true(any(grepl("Absolute Day-Difference Sentences", output)))
  expect_true(any(grepl("Appointment Acceptance Rates", output)))
})
