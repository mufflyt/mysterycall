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


test_that("mysterycall_sensitivity_both_insurance: happy path with physicians called under both insurance types", {
  set.seed(231)
  df <- data.frame(
    phone = rep(c("P1", "P2", "P3"), each = 2L),
    insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), 3L),
    business_days_until_appointment = c(5L, 10L, 7L, 12L, 3L, 8L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )

  expect_type(result, "list")
  expect_named(result, c("n_both", "n_total", "both_data", "wait_comparison", "t_test", "sentence", "phone_ids"))
  expect_equal(result$n_total, 3L)
  expect_equal(result$n_both, 3L)
  expect_s3_class(result$both_data, "tbl_df")
  expect_s3_class(result$wait_comparison, "tbl_df")
  expect_true(is.character(result$sentence))
  expect_true(length(result$sentence) == 1L)
  expect_true(is.character(result$phone_ids))
  expect_equal(length(result$phone_ids), 3L)
})


test_that("mysterycall_sensitivity_both_insurance: no physicians called under both insurance types", {
  set.seed(232)
  df <- data.frame(
    phone = c("P1", "P1", "P2", "P2"),
    insurance = c("Medicaid", "Medicaid", "BCBS", "BCBS"),
    business_days_until_appointment = c(5L, 6L, 10L, 11L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )

  expect_equal(result$n_both, 0L)
  expect_equal(result$n_total, 2L)
  expect_equal(nrow(result$both_data), 0L)
  expect_equal(nrow(result$wait_comparison), 0L)
  expect_null(result$t_test)
  expect_true(grepl("none were called under both", result$sentence, ignore.case = TRUE))
  expect_equal(length(result$phone_ids), 0L)
})


test_that("mysterycall_sensitivity_both_insurance: empty data frame", {
  set.seed(233)
  df <- data.frame(
    phone = character(0L),
    insurance = character(0L),
    business_days_until_appointment = numeric(0L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )

  expect_equal(result$n_total, 0L)
  expect_equal(result$n_both, 0L)
  expect_equal(nrow(result$both_data), 0L)
  expect_equal(length(result$phone_ids), 0L)
})


test_that("mysterycall_sensitivity_both_insurance: missing required column raises error", {
  set.seed(234)
  df <- data.frame(
    phone = c("P1", "P1", "P2", "P2"),
    business_days_until_appointment = c(5L, 10L, 7L, 12L),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA),
    "insurance"
  )
})


test_that("mysterycall_sensitivity_both_insurance: non-data-frame input raises error", {
  set.seed(235)
  expect_error(
    mysterycall_sensitivity_both_insurance(list(), output_dir = NA),
    "data.frame"
  )
})


test_that("mysterycall_sensitivity_both_insurance: normalization of insurance labels", {
  set.seed(236)
  df <- data.frame(
    phone = c("P1", "P1", "P2", "P2"),
    insurance = c("  MEDICAID  ", "Blue Cross/Blue Shield", "medicaid", "  BLUE CROSS/BLUE SHIELD  "),
    business_days_until_appointment = c(5L, 10L, 7L, 12L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )

  expect_equal(result$n_both, 2L)
  expect_equal(result$n_total, 2L)
  expect_equal(nrow(result$both_data), 4L)
  expect_true(all(result$both_data$insurance %in% c("medicaid", "blue cross/blue shield")))
})


test_that("mysterycall_sensitivity_both_insurance: custom column names", {
  set.seed(237)
  df <- data.frame(
    npi = c("1001", "1001", "1002", "1002"),
    payer = c("medicaid", "bcbs", "medicaid", "bcbs"),
    days_to_apt = c(5L, 10L, 7L, 12L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_sensitivity_both_insurance(
      df,
      phone_col = "npi",
      insurance_col = "payer",
      outcome_col = "days_to_apt",
      medicaid_label = "medicaid",
      bcbs_label = "bcbs",
      output_dir = NA
    )
  )

  expect_equal(result$n_both, 2L)
  expect_equal(result$n_total, 2L)
})


test_that("mysterycall_sensitivity_both_insurance: handles NA values in outcome", {
  set.seed(238)
  df <- data.frame(
    phone = c("P1", "P1", "P2", "P2"),
    insurance = c("medicaid", "blue cross/blue shield", "medicaid", "blue cross/blue shield"),
    business_days_until_appointment = c(5L, NA_integer_, 7L, 12L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )

  expect_equal(result$n_both, 2L)
  expect_equal(nrow(result$wait_comparison), 2L)
  expect_true(is.numeric(result$wait_comparison$mean_wait))
})


test_that("mysterycall_sensitivity_both_insurance: t_test is NULL when insufficient data", {
  set.seed(239)
  df <- data.frame(
    phone = c("P1", "P1"),
    insurance = c("medicaid", "blue cross/blue shield"),
    business_days_until_appointment = c(5L, 10L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )

  expect_equal(result$n_both, 1L)
  expect_null(result$t_test)
  expect_true(is.character(result$sentence))
})


test_that("mysterycall_sensitivity_both_insurance: output_dir = NA skips file writing", {
  set.seed(240)
  df <- data.frame(
    phone = c("P1", "P1", "P2", "P2"),
    insurance = c("medicaid", "blue cross/blue shield", "medicaid", "blue cross/blue shield"),
    business_days_until_appointment = c(5L, 10L, 7L, 12L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_sensitivity_both_insurance(df, output_dir = NA)
    )
  )

  expect_type(result, "list")
  expect_equal(result$n_both, 2L)
})


test_that("mysterycall_sensitivity_both_insurance: sentence includes statistics when available", {
  set.seed(241)
  df <- data.frame(
    phone = c("P1", "P1", "P2", "P2", "P3", "P3"),
    insurance = rep(c("medicaid", "blue cross/blue shield"), 3L),
    business_days_until_appointment = c(5L, 10L, 7L, 12L, 8L, 14L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )

  expect_equal(result$n_both, 3L)
  expect_true(is.character(result$sentence))
  expect_true(nchar(result$sentence) > 0L)
  expect_true(grepl("mean", result$sentence, ignore.case = TRUE))
})


test_that("mysterycall_sensitivity_both_insurance: return types match specification", {
  set.seed(242)
  df <- data.frame(
    phone = c("P1", "P1", "P2", "P2"),
    insurance = c("medicaid", "blue cross/blue shield", "medicaid", "blue cross/blue shield"),
    business_days_until_appointment = c(5L, 10L, 7L, 12L),
    stringsAsFactax = FALSE
  )

  result <- suppressMessages(
    mysterycall_sensitivity_both_insurance(df, output_dir = NA)
  )

  expect_type(result$n_both, "integer")
  expect_type(result$n_total, "integer")
  expect_s3_class(result$both_data, "tbl_df")
  expect_s3_class(result$wait_comparison, "tbl_df")
  expect_type(result$sentence, "character")
  expect_type(result$phone_ids, "character")
})
