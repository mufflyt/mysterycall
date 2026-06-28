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


test_that("mysterycall_results_report: happy path with full params", {
  skip_if_not_installed("lme4")

  set.seed(1)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(
      fit,
      baseline_mean    = 21,
      exposure_col     = "ins",
      ref_group        = "BCBS",
      outcome_label    = "appointment wait time",
      digits           = 2L,
      include_intercept = FALSE
    )
  ))

  expect_s3_class(report, "mysterycall_results_report")
  expect_type(report, "list")
  expect_named(report, c("combined_table", "irr_days", "paragraph", "day_sentences", "acceptance", "docx_path"))
  expect_true(is.data.frame(report$combined_table))
  expect_true(is.character(report$paragraph) || is.null(report$paragraph))
})


test_that("mysterycall_results_report: with data for acceptance rates", {
  skip_if_not_installed("lme4")

  set.seed(2)
  df <- data.frame(
    wait        = rpois(60, 21),
    ins         = rep(c("Medicaid", "BCBS"), 30),
    phys        = rep(paste0("Dr", 1:10), each = 6),
    contact_office = rep(c(TRUE, FALSE), 30),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(
      fit,
      baseline_mean = 21,
      exposure_col  = "ins",
      ref_group     = "BCBS",
      data          = df,
      accepted_col  = "contact_office",
      group_col     = "ins"
    )
  ))

  expect_s3_class(report, "mysterycall_results_report")
  expect_true(is.list(report$acceptance) || is.null(report$acceptance))
})


test_that("mysterycall_results_report: baseline_mean = NULL omits day columns", {
  skip_if_not_installed("lme4")

  set.seed(3)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(
      fit,
      baseline_mean = NULL,
      exposure_col  = "ins",
      ref_group     = "BCBS"
    )
  ))

  expect_s3_class(report, "mysterycall_results_report")
  expect_null(report$irr_days)
  expect_null(report$day_sentences)
})


test_that("mysterycall_results_report: exposure_col = NULL omits paragraph and sentences", {
  skip_if_not_installed("lme4")

  set.seed(4)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(
      fit,
      baseline_mean = 21,
      exposure_col  = NULL,
      ref_group     = "BCBS"
    )
  ))

  expect_s3_class(report, "mysterycall_results_report")
  expect_null(report$paragraph)
  expect_null(report$day_sentences)
})


test_that("mysterycall_results_report: data = NULL omits acceptance rates", {
  skip_if_not_installed("lme4")

  set.seed(5)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(
      fit,
      baseline_mean = 21,
      exposure_col  = "ins",
      ref_group     = "BCBS",
      data          = NULL
    )
  ))

  expect_null(report$acceptance)
})


test_that("mysterycall_results_report: rejects wrong model class", {
  bad_model <- list(coef = c(1, 2))

  expect_error(
    mysterycall_results_report(bad_model, baseline_mean = 21),
    "must be a `mysterycall_poisson_model` or `mysterycall_nb_model`"
  )
})


test_that("mysterycall_results_report: rejects negative baseline_mean", {
  skip_if_not_installed("lme4")

  set.seed(6)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_results_report(fit, baseline_mean = -5)
    )),
    "baseline_mean.*must be a single positive number or NULL"
  )
})


test_that("mysterycall_results_report: rejects zero baseline_mean", {
  skip_if_not_installed("lme4")

  set.seed(7)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_results_report(fit, baseline_mean = 0)
    )),
    "baseline_mean.*must be a single positive number or NULL"
  )
})


test_that("mysterycall_results_report: rejects non-numeric baseline_mean", {
  skip_if_not_installed("lme4")

  set.seed(8)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_results_report(fit, baseline_mean = "21")
    )),
    "baseline_mean.*must be a single positive number or NULL"
  )
})


test_that("mysterycall_results_report: rejects vector baseline_mean", {
  skip_if_not_installed("lme4")

  set.seed(9)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_results_report(fit, baseline_mean = c(5, 10))
    )),
    "baseline_mean.*must be a single positive number or NULL"
  )
})


test_that("mysterycall_results_report: rejects non-character exposure_col", {
  skip_if_not_installed("lme4")

  set.seed(10)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_results_report(fit, baseline_mean = 21, exposure_col = 123)
    )),
    "exposure_col.*must be a single character string or NULL"
  )
})


test_that("mysterycall_results_report: rejects vector exposure_col", {
  skip_if_not_installed("lme4")

  set.seed(11)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_results_report(fit, baseline_mean = 21, exposure_col = c("ins", "other"))
    )),
    "exposure_col.*must be a single character string or NULL"
  )
})


test_that("mysterycall_results_report: rejects non-data.frame data", {
  skip_if_not_installed("lme4")

  set.seed(12)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_results_report(fit, baseline_mean = 21, data = "not_a_df")
    )),
    "data.*must be a data frame or NULL"
  )
})


test_that("mysterycall_results_report: rejects list as data", {
  skip_if_not_installed("lme4")

  set.seed(13)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_results_report(fit, baseline_mean = 21, data = list(a = 1))
    )),
    "data.*must be a data frame or NULL"
  )
})


test_that("print.mysterycall_results_report: returns invisibly with all components", {
  skip_if_not_installed("lme4")

  set.seed(14)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(
      fit,
      baseline_mean = 21,
      exposure_col  = "ins",
      ref_group     = "BCBS",
      data          = AUDIT,
      group_col     = "insurance"
    )
  ))

  output <- suppressMessages(suppressWarnings(
    capture.output(result <- print(report))
  ))

  expect_type(output, "character")
  expect_true(any(grepl("Combined Results Table", output)))
  expect_true(any(grepl("Results Paragraph", output)))
  expect_true(any(grepl("Absolute Day-Difference Sentences", output)))
  expect_true(any(grepl("Appointment Acceptance Rates", output)))
  expect_identical(result, report)
})


test_that("print.mysterycall_results_report: handles minimal components", {
  skip_if_not_installed("lme4")

  set.seed(15)
  df <- data.frame(
    wait    = rpois(60, 21),
    ins     = rep(c("Medicaid", "BCBS"), 30),
    phys    = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_poisson_model(df, "wait", "ins", "phys")
  ))

  report <- suppressMessages(suppressWarnings(
    mysterycall_results_report(fit)
  ))

  output <- suppressMessages(suppressWarnings(
    capture.output(result <- print(report))
  ))

  expect_type(output, "character")
  expect_true(any(grepl("Combined Results Table", output)))
  expect_identical(result, report)
})
