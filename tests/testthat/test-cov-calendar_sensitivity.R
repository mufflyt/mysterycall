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

# Test data for calendar sensitivity tests
set.seed(202)
test_data <- data.frame(
  wait_days     = round(rnorm(60, 21, 8)),
  business_days = round(rnorm(60, 15, 6)),
  scenario      = rep(c("Straight", "Lesbian", "Single"), 20),
  practice      = rep(paste0("P", 1:20), each = 3),
  stringsAsFactors = FALSE
)

test_that("mysterycall_calendar_sensitivity: happy path returns correct structure", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  expect_s3_class(res, "mysterycall_calendar_sensitivity")
  expect_true(is.list(res))
  expect_named(
    res,
    c("calendar_lmm", "business_lmm", "comparison_table", "summary_table",
      "n_calendar", "n_business", "all_consistent", "paragraph", "docx_path")
  )
})

test_that("mysterycall_calendar_sensitivity: returns correct data frame types", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  expect_s3_class(res$comparison_table, "data.frame")
  expect_s3_class(res$summary_table, "data.frame")
  expect_true(is.numeric(res$n_calendar))
  expect_true(is.numeric(res$n_business))
  expect_true(is.logical(res$all_consistent))
  expect_true(is.character(res$paragraph))
})

test_that("mysterycall_calendar_sensitivity: comparison_table has expected columns", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  expected_cols <- c("term", "cal_est", "cal_ci_lo", "cal_ci_hi", "cal_p",
                     "biz_est", "biz_ci_lo", "biz_ci_hi", "biz_p",
                     "direction_consistent", "magnitude_ratio")
  expect_true(all(expected_cols %in% names(res$comparison_table)))
})

test_that("mysterycall_calendar_sensitivity: direction_consistent is logical", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  expect_true(is.logical(res$comparison_table$direction_consistent))
  expect_true(is.logical(res$all_consistent))
})

test_that("mysterycall_calendar_sensitivity: handles NA values gracefully", {
  skip_if_not_installed("lme4")

  # Add some NA values to test data
  test_data_na <- test_data
  test_data_na$wait_days[1:3] <- NA_real_
  test_data_na$business_days[4:6] <- NA_real_

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data_na,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  expect_true(is.list(res))
  expect_s3_class(res, "mysterycall_calendar_sensitivity")
  # n values should be less than original due to listwise deletion
  expect_true(res$n_calendar < nrow(test_data))
})

test_that("mysterycall_calendar_sensitivity: errors on missing required column", {
  skip_if_not_installed("lme4")

  test_data_missing <- test_data
  test_data_missing$wait_days <- NULL

  expect_error(
    suppressMessages(
      mysterycall_calendar_sensitivity(
        data              = test_data_missing,
        calendar_col      = "wait_days",
        business_col      = "business_days",
        predictors        = "scenario",
        random_intercept  = "practice"
      )
    ),
    "not found in data"
  )
})

test_that("mysterycall_calendar_sensitivity: errors on non-numeric calendar_col", {
  skip_if_not_installed("lme4")

  test_data_chr <- test_data
  test_data_chr$wait_days <- as.character(test_data_chr$wait_days)

  expect_error(
    suppressMessages(
      mysterycall_calendar_sensitivity(
        data              = test_data_chr,
        calendar_col      = "wait_days",
        business_col      = "business_days",
        predictors        = "scenario",
        random_intercept  = "practice"
      )
    ),
    "must be numeric"
  )
})

test_that("mysterycall_calendar_sensitivity: errors on non-numeric business_col", {
  skip_if_not_installed("lme4")

  test_data_chr <- test_data
  test_data_chr$business_days <- as.character(test_data_chr$business_days)

  expect_error(
    suppressMessages(
      mysterycall_calendar_sensitivity(
        data              = test_data_chr,
        calendar_col      = "wait_days",
        business_col      = "business_days",
        predictors        = "scenario",
        random_intercept  = "practice"
      )
    ),
    "must be numeric"
  )
})

test_that("mysterycall_calendar_sensitivity: errors on non-data.frame input", {
  skip_if_not_installed("lme4")

  expect_error(
    suppressMessages(
      mysterycall_calendar_sensitivity(
        data              = as.matrix(test_data),
        calendar_col      = "wait_days",
        business_col      = "business_days",
        predictors        = "scenario",
        random_intercept  = "practice"
      )
    ),
    "must be a data frame"
  )
})

test_that("mysterycall_calendar_sensitivity: accepts custom conf_level", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice",
      conf_level        = 0.90
    )
  )

  expect_s3_class(res, "mysterycall_calendar_sensitivity")
})

test_that("mysterycall_calendar_sensitivity: accepts ref_label and supp_table_num", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice",
      ref_label         = "Straight couple",
      supp_table_num    = "S2"
    )
  )

  expect_s3_class(res, "mysterycall_calendar_sensitivity")
  expect_true(grepl("Straight couple", res$paragraph))
  expect_true(grepl("S2", res$paragraph))
})

test_that("mysterycall_calendar_sensitivity: errors on invalid supp_table_num", {
  skip_if_not_installed("lme4")

  expect_error(
    suppressMessages(
      mysterycall_calendar_sensitivity(
        data              = test_data,
        calendar_col      = "wait_days",
        business_col      = "business_days",
        predictors        = "scenario",
        random_intercept  = "practice",
        supp_table_num    = c("S1", "S2")
      )
    ),
    "must be a single character string"
  )
})

test_that("print.mysterycall_calendar_sensitivity: prints without error", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  # Capture output to check structure
  output <- capture.output(print(res))
  expect_true(length(output) > 0)
  expect_true(any(grepl("Calendar vs. Business Days", output)))
})

test_that("print.mysterycall_calendar_sensitivity: shows n values", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  output <- capture.output(print(res))
  output_text <- paste(output, collapse = "\n")
  expect_true(grepl(sprintf("%d", res$n_calendar), output_text) ||
              grepl("Calendar model", output_text))
})

test_that("print.mysterycall_calendar_sensitivity: shows consistency status", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  output <- capture.output(print(res))
  output_text <- paste(output, collapse = "\n")
  # Should mention direction consistency
  expect_true(grepl("consistent", tolower(output_text)))
})

test_that("print.mysterycall_calendar_sensitivity: returns invisible(x)", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  result <- withVisible(print(res))
  expect_false(result$visible)
  expect_identical(result$value, res)
})

test_that("mysterycall_calendar_sensitivity: paragraph includes method details", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  # Paragraph should mention key methodological elements
  expect_true(is.character(res$paragraph))
  expect_true(length(res$paragraph) == 1)
  expect_true(grepl("business days", tolower(res$paragraph)))
  expect_true(grepl("sensitivity", tolower(res$paragraph)))
})

test_that("mysterycall_calendar_sensitivity: works with multiple predictors", {
  skip_if_not_installed("lme4")

  # Add another predictor column
  test_data_multi <- test_data
  test_data_multi$gender <- rep(c("M", "F"), length.out = nrow(test_data))

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data_multi,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = c("scenario", "gender"),
      random_intercept  = "practice"
    )
  )

  expect_s3_class(res, "mysterycall_calendar_sensitivity")
  # Comparison table should have rows for both predictors
  expect_true(nrow(res$comparison_table) >= 3)
})

test_that("mysterycall_calendar_sensitivity: magnitude_ratio calculated correctly", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  # magnitude_ratio should be biz_est / cal_est
  for (i in seq_len(nrow(res$comparison_table))) {
    if (abs(res$comparison_table$cal_est[i]) > 1e-10) {
      expected_ratio <- res$comparison_table$biz_est[i] /
                        res$comparison_table$cal_est[i]
      expect_equal(
        res$comparison_table$magnitude_ratio[i],
        expected_ratio,
        tolerance = 1e-6
      )
    }
  }
})

test_that("mysterycall_calendar_sensitivity: summary_table is print-ready format", {
  skip_if_not_installed("lme4")

  res <- suppressMessages(
    mysterycall_calendar_sensitivity(
      data              = test_data,
      calendar_col      = "wait_days",
      business_col      = "business_days",
      predictors        = "scenario",
      random_intercept  = "practice"
    )
  )

  # Summary table should have formatted strings with parentheses and commas
  expect_true(all(grepl("(", res$summary_table$`Calendar days`, fixed = TRUE)))
  expect_true(all(grepl("(", res$summary_table$`Business days`, fixed = TRUE)))
})
