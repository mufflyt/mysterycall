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

test_that("univariate_lmm_screen: happy path with valid minimal inputs", {
  skip_if_not_installed("lmerTest")

  set.seed(100)
  df <- data.frame(
    business_days_until_appointment = rpois(60, 10),
    insurance = rep(c("BCBS", "Medicaid"), 30),
    gender = rep(c("M", "F"), 30),
    last = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_univariate_lmm_screen(df, output_dir = NA))

  expect_type(result, "list")
  expect_named(result, c("results", "significant", "sentence", "alpha"))
  expect_s3_class(result$results, "tbl_df")
  expect_s3_class(result$significant, "tbl_df")
  expect_type(result$sentence, "character")
  expect_type(result$alpha, "double")
  expect_true(nrow(result$results) > 0)
})

test_that("univariate_lmm_screen: results has correct columns", {
  skip_if_not_installed("lmerTest")

  set.seed(101)
  df <- data.frame(
    business_days_until_appointment = rpois(60, 10),
    insurance = rep(c("BCBS", "Medicaid"), 30),
    last = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_univariate_lmm_screen(df, output_dir = NA))

  expected_cols <- c("Predictor", "P_Value", "P_Formatted", "Estimate", "CI_Lower", "CI_Upper")
  expect_true(all(expected_cols %in% names(result$results)))
})

test_that("univariate_lmm_screen: p_adjust_method='BH' adds adjusted columns", {
  skip_if_not_installed("lmerTest")

  set.seed(102)
  df <- data.frame(
    business_days_until_appointment = rpois(60, 10),
    insurance = rep(c("BCBS", "Medicaid"), 30),
    gender = rep(c("M", "F"), 30),
    last = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, p_adjust_method = "BH", output_dir = NA)
  )

  expect_true("P_Value_Adjusted" %in% names(result$results))
  expect_true("P_Adjusted_Formatted" %in% names(result$results))
})

test_that("univariate_lmm_screen: alpha threshold controls significant subset", {
  skip_if_not_installed("lmerTest")

  set.seed(103)
  df <- data.frame(
    business_days_until_appointment = rpois(60, 10),
    insurance = rep(c("BCBS", "Medicaid"), 30),
    gender = rep(c("M", "F"), 30),
    last = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  result_tight <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, alpha = 0.01, output_dir = NA)
  )
  result_loose <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, alpha = 0.5, output_dir = NA)
  )

  expect_true(nrow(result_tight$significant) <= nrow(result_loose$significant))
  expect_equal(result_tight$alpha, 0.01)
  expect_equal(result_loose$alpha, 0.5)
})

test_that("univariate_lmm_screen: exclude_cols parameter works", {
  skip_if_not_installed("lmerTest")

  set.seed(104)
  df <- data.frame(
    business_days_until_appointment = rpois(60, 10),
    insurance = rep(c("BCBS", "Medicaid"), 30),
    gender = rep(c("M", "F"), 30),
    exclude_me = rep(c("A", "B"), 30),
    last = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  result_default <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, output_dir = NA)
  )
  result_custom_exclude <- suppressMessages(
    mysterycall_univariate_lmm_screen(
      df,
      exclude_cols = c("business_days_until_appointment", "last", "exclude_me"),
      output_dir = NA
    )
  )

  expect_false("exclude_me" %in% result_custom_exclude$results$Predictor)
})

test_that("univariate_lmm_screen: custom outcome and random_effect columns", {
  skip_if_not_installed("lmerTest")

  set.seed(105)
  df <- data.frame(
    my_outcome = rpois(60, 10),
    my_random = rep(paste0("Group", 1:10), 6),
    predictor1 = rep(c("A", "B"), 30),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_lmm_screen(
      df,
      outcome_col = "my_outcome",
      random_effect = "my_random",
      exclude_cols = c("my_outcome", "my_random"),
      output_dir = NA
    )
  )

  expect_s3_class(result$results, "tbl_df")
  expect_true(nrow(result$results) > 0)
})

test_that("univariate_lmm_screen: NA values in outcome are dropped", {
  skip_if_not_installed("lmerTest")

  set.seed(106)
  df <- data.frame(
    business_days_until_appointment = c(rpois(50, 10), rep(NA, 10)),
    insurance = rep(c("BCBS", "Medicaid"), 30),
    last = rep(paste0("Dr", 1:10), 6),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_univariate_lmm_screen(df, output_dir = NA))

  expect_s3_class(result$results, "tbl_df")
  expect_type(result$sentence, "character")
})

test_that("univariate_lmm_screen: constant predictor is skipped", {
  skip_if_not_installed("lmerTest")

  set.seed(107)
  df <- data.frame(
    business_days_until_appointment = rpois(60, 10),
    constant_col = rep("A", 60),
    varying_col = rep(c("A", "B"), 30),
    last = rep(paste0("Dr", 1:10), 6),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_lmm_screen(
      df,
      exclude_cols = c("business_days_until_appointment", "last"),
      output_dir = NA
    )
  )

  expect_false("constant_col" %in% result$results$Predictor)
  expect_true("varying_col" %in% result$results$Predictor)
})

test_that("univariate_lmm_screen: error when data is not a data frame", {
  skip_if_not_installed("lmerTest")

  expect_error(
    mysterycall_univariate_lmm_screen(list(a = 1:10), output_dir = NA),
    "`data` must be a data frame"
  )
})

test_that("univariate_lmm_screen: error when outcome_col not in data", {
  skip_if_not_installed("lmerTest")

  set.seed(108)
  df <- data.frame(
    insurance = rep(c("BCBS", "Medicaid"), 30),
    last = rep(paste0("Dr", 1:10), 6),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_univariate_lmm_screen(df, outcome_col = "nonexistent", output_dir = NA),
    "outcome_col 'nonexistent' not found"
  )
})

test_that("univariate_lmm_screen: error when random_effect not in data", {
  skip_if_not_installed("lmerTest")

  set.seed(109)
  df <- data.frame(
    business_days_until_appointment = rpois(60, 10),
    insurance = rep(c("BCBS", "Medicaid"), 30),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_univariate_lmm_screen(df, random_effect = "nonexistent", output_dir = NA),
    "random_effect 'nonexistent' not found"
  )
})

test_that("univariate_lmm_screen: significant subset is sorted by p-value", {
  skip_if_not_installed("lmerTest")

  set.seed(110)
  df <- data.frame(
    business_days_until_appointment = rpois(60, 10),
    insurance = rep(c("BCBS", "Medicaid"), 30),
    gender = rep(c("M", "F"), 30),
    last = rep(paste0("Dr", 1:10), 6),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, alpha = 0.5, output_dir = NA)
  )

  if (nrow(result$significant) > 1) {
    pvals <- result$significant$P_Value
    expect_true(all(pvals == sort(pvals)))
  }
})

test_that("univariate_lmm_screen: sentence reflects significant predictors", {
  skip_if_not_installed("lmerTest")

  set.seed(111)
  df <- data.frame(
    business_days_until_appointment = rpois(60, 10),
    insurance = rep(c("BCBS", "Medicaid"), 30),
    last = rep(paste0("Dr", 1:10), 6),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_univariate_lmm_screen(df, alpha = 0.2, output_dir = NA)
  )

  expect_type(result$sentence, "character")
  expect_true(length(result$sentence) == 1)
  if (nrow(result$significant) == 0) {
    expect_true(grepl("No significant predictors", result$sentence))
  }
})
