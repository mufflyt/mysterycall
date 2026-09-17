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


test_that("mysterycall_combined_results_table: happy path with data.frame (no baseline_mean)", {
  irr_df <- data.frame(
    term        = c("insuranceMedicaid", "insuranceUninsured"),
    irr         = c(1.28, 0.81),
    ci_lower    = c(1.05, 0.61),
    ci_upper    = c(1.56, 1.07),
    p_value     = c(0.014, 0.134),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(irr_df)
  ))

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
})


test_that("mysterycall_combined_results_table: happy path with data.frame (with baseline_mean)", {
  irr_df <- data.frame(
    term        = c("insuranceMedicaid", "insuranceUninsured"),
    irr         = c(1.28, 0.81),
    ci_lower    = c(1.05, 0.61),
    ci_upper    = c(1.56, 1.07),
    p_value     = c(0.014, 0.134),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(
      irr_df,
      baseline_mean = 21,
      exposure_col = "insurance",
      ref_group = "BCBS"
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
  expect_true(attr(result, "has_days"))
})


test_that("mysterycall_combined_results_table: output structure and columns", {
  irr_df <- data.frame(
    term        = c("insuranceMedicaid", "insuranceUninsured", "(Intercept)"),
    irr         = c(1.28, 0.81, 5.0),
    ci_lower    = c(1.05, 0.61, 4.5),
    ci_upper    = c(1.56, 1.07, 5.5),
    p_value     = c(0.014, 0.134, 0.001),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(irr_df, baseline_mean = 21)
  ))

  expected_cols <- c("Term", "IRR", "IRR 95% CI", "p-value", "Days Diff", "Days 95% CI", "Significance")
  expect_equal(names(result), expected_cols)

  # Check that intercept was excluded by default
  expect_false(any(grepl("Intercept", result$Term)))

  # Check attributes
  expect_true("significant_rows" %in% names(attributes(result)))
  expect_true("has_days" %in% names(attributes(result)))
})


test_that("mysterycall_combined_results_table: significant_rows attribute correct", {
  irr_df <- data.frame(
    term        = c("insuranceMedicaid", "insuranceUninsured", "insuranceDual"),
    irr         = c(1.28, 0.81, 1.5),
    ci_lower    = c(1.05, 0.61, 1.2),
    ci_upper    = c(1.56, 1.07, 1.8),
    p_value     = c(0.014, 0.134, 0.045),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(irr_df)
  ))

  sig_rows <- attr(result, "significant_rows")
  expect_type(sig_rows, "integer")
  expect_equal(sig_rows, c(1L, 3L))
})


test_that("mysterycall_combined_results_table: include_intercept=TRUE", {
  irr_df <- data.frame(
    term        = c("insuranceMedicaid", "(Intercept)"),
    irr         = c(1.28, 5.0),
    ci_lower    = c(1.05, 4.5),
    ci_upper    = c(1.56, 5.5),
    p_value     = c(0.014, 0.001),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(irr_df, include_intercept = TRUE)
  ))

  expect_true(any(grepl("Intercept", result$Term)))
  expect_equal(nrow(result), 2L)
})


test_that("mysterycall_combined_results_table: digits parameter controls formatting", {
  irr_df <- data.frame(
    term        = c("insuranceMedicaid"),
    irr         = c(1.23456),
    ci_lower    = c(1.05234),
    ci_upper    = c(1.56789),
    p_value     = c(0.01234),
    stringsAsFactors = FALSE
  )

  result_2dp <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(irr_df, digits = 2L)
  ))

  result_3dp <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(irr_df, digits = 3L)
  ))

  expect_equal(result_2dp$IRR, "1.23")
  expect_equal(result_3dp$IRR, "1.235")
  expect_equal(result_2dp$`IRR 95% CI`, "1.05 to 1.57")
  expect_equal(result_3dp$`IRR 95% CI`, "1.052 to 1.568")
})


test_that("mysterycall_combined_results_table: error when baseline_mean invalid", {
  irr_df <- data.frame(
    term        = c("insuranceMedicaid"),
    irr         = c(1.28),
    ci_lower    = c(1.05),
    ci_upper    = c(1.56),
    p_value     = c(0.014),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_combined_results_table(irr_df, baseline_mean = -5)
    )),
    "baseline_mean.*single positive number"
  )

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_combined_results_table(irr_df, baseline_mean = c(5, 10))
    )),
    "baseline_mean.*single positive number"
  )

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_combined_results_table(irr_df, baseline_mean = "twenty")
    )),
    "baseline_mean.*single positive number"
  )
})


test_that("mysterycall_combined_results_table: error when missing required columns", {
  incomplete_df <- data.frame(
    term        = c("insuranceMedicaid"),
    irr         = c(1.28),
    ci_lower    = c(1.05),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_combined_results_table(incomplete_df)
    )),
    "missing required columns"
  )
})


test_that("mysterycall_combined_results_table: error when model_result wrong type", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_combined_results_table(list(foo = 1))
    )),
    "mysterycall_poisson_model.*mysterycall_nb_model.*data frame"
  )
})


test_that("mysterycall_combined_results_table: error when no rows remain", {
  irr_df <- data.frame(
    term        = c("(Intercept)"),
    irr         = c(5.0),
    ci_lower    = c(4.5),
    ci_upper    = c(5.5),
    p_value     = c(0.001),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_combined_results_table(irr_df, include_intercept = FALSE)
    )),
    "No rows remaining"
  )
})


test_that("mysterycall_combined_results_table: p-value formatting", {
  irr_df <- data.frame(
    term        = c("var1", "var2", "var3", "var4"),
    irr         = c(1.0, 1.1, 1.2, 1.3),
    ci_lower    = c(0.9, 1.0, 1.1, 1.2),
    ci_upper    = c(1.1, 1.2, 1.3, 1.4),
    p_value     = c(0.0001, 0.05, 0.123, NA),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(irr_df)
  ))

  expect_equal(result$`p-value`[1], "< 0.001")
  expect_equal(result$`p-value`[2], "0.050")
  expect_equal(result$`p-value`[3], "0.123")
  expect_true(is.na(result$`p-value`[4]))
})


test_that("mysterycall_combined_results_table: significance column correct", {
  irr_df <- data.frame(
    term        = c("sig_var", "non_sig_var"),
    irr         = c(1.28, 0.81),
    ci_lower    = c(1.05, 0.61),
    ci_upper    = c(1.56, 1.07),
    p_value     = c(0.01, 0.15),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(irr_df)
  ))

  expect_equal(result$Significance[1], "*")
  expect_equal(result$Significance[2], "")
})


test_that("mysterycall_combined_results_table: has_days attribute reflects baseline_mean", {
  irr_df <- data.frame(
    term        = c("insuranceMedicaid"),
    irr         = c(1.28),
    ci_lower    = c(1.05),
    ci_upper    = c(1.56),
    p_value     = c(0.014),
    stringsAsFactors = FALSE
  )

  result_no_baseline <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(irr_df)
  ))

  result_with_baseline <- suppressMessages(suppressWarnings(
    mysterycall_combined_results_table(irr_df, baseline_mean = 21)
  ))

  expect_false(attr(result_no_baseline, "has_days"))
  expect_true(attr(result_with_baseline, "has_days"))
})
