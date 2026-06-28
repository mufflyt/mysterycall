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
  physician = rep(1:4, 20),
  stringsAsFactors = FALSE
)

# ============================================================================
# mysterycall_sample_size_text
# ============================================================================

test_that("mysterycall_sample_size_text returns character with default margin_of_error", {
  result <- mysterycall_sample_size_text(369)
  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(grepl("Cochran formula", result))
  expect_true(grepl("minimum sample size", result))
  expect_true(grepl("369", result))
})

test_that("mysterycall_sample_size_text handles different N and margin_of_error values", {
  result_small <- mysterycall_sample_size_text(100, margin_of_error = 0.10)
  result_large <- mysterycall_sample_size_text(5000, margin_of_error = 0.02)
  expect_type(result_small, "character")
  expect_type(result_large, "character")
  expect_true(grepl("100", result_small))
  expect_true(grepl("5,000", result_large))
})

test_that("mysterycall_sample_size_text rejects invalid N", {
  expect_error(mysterycall_sample_size_text(0), "positive number")
  expect_error(mysterycall_sample_size_text(-10), "positive number")
  expect_error(mysterycall_sample_size_text("not_numeric"), "positive number")
})

# ============================================================================
# mysterycall_summarize_demographics
# ============================================================================

test_that("mysterycall_summarize_demographics returns character with valid input", {
  df <- data.frame(
    gender  = c("Female", "Male", "Female", NA),
    setting = c("Academic", "Private Practice", "Academic", "Academic"),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_summarize_demographics(df, female_col = "gender", setting_col = "setting")
  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(grepl("N = 4", result))
  expect_true(grepl("% female", result))
  expect_true(grepl("% academic", result))
})

test_that("mysterycall_summarize_demographics handles logical female column", {
  df <- data.frame(
    female = c(TRUE, FALSE, TRUE, TRUE),
    setting = c("Academic", "Private", "Academic", "Private"),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_summarize_demographics(df, female_col = "female", setting_col = "setting")
  expect_type(result, "character")
  expect_true(grepl("75.0% female", result))
  expect_true(grepl("50.0% academic", result))
})

test_that("mysterycall_summarize_demographics handles missing columns gracefully", {
  df <- data.frame(x = 1:10, stringsAsFactors = FALSE)
  result <- mysterycall_summarize_demographics(df, female_col = "missing", setting_col = "also_missing")
  expect_type(result, "character")
  expect_true(grepl("N = 10", result))
  expect_false(grepl("% female", result))
  expect_false(grepl("% academic", result))
})

test_that("mysterycall_summarize_demographics handles NULL column arguments", {
  df <- data.frame(x = 1:5, stringsAsFactors = FALSE)
  result <- mysterycall_summarize_demographics(df, female_col = NULL, setting_col = NULL)
  expect_type(result, "character")
  expect_equal(result, "N = 5")
})

test_that("mysterycall_summarize_demographics rejects non-data-frame input", {
  expect_error(mysterycall_summarize_demographics(list(x = 1)), "must be a data frame")
  expect_error(mysterycall_summarize_demographics(c(1, 2, 3)), "must be a data frame")
  expect_error(mysterycall_summarize_demographics(matrix(1:4, 2, 2)), "must be a data frame")
})

# ============================================================================
# mysterycall_methods_paragraph
# ============================================================================

test_that("mysterycall_methods_paragraph returns character with valid inputs", {
  result <- mysterycall_methods_paragraph(
    n_physicians  = 369,
    n_cities      = 10,
    specialties   = c("otolaryngology", "neurotology"),
    insurance_types = c("Medicaid", "Blue Cross Blue Shield")
  )
  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(grepl("mystery-caller", result))
  expect_true(grepl("369", result))
  expect_true(grepl("10", result))
  expect_true(grepl("otolaryngology", result))
  expect_true(grepl("neurotology", result))
})

test_that("mysterycall_methods_paragraph handles single specialty", {
  result <- mysterycall_methods_paragraph(
    n_physicians = 216,
    n_cities = 12,
    specialties = "otolaryngology",
    model_family = "negative_binomial"
  )
  expect_type(result, "character")
  expect_true(grepl("negative binomial", result))
  expect_true(grepl("216", result))
})

test_that("mysterycall_methods_paragraph respects model_family parameter", {
  result_poisson <- mysterycall_methods_paragraph(
    n_physicians = 100, n_cities = 5, specialties = "cardiology",
    model_family = "poisson"
  )
  result_nb <- mysterycall_methods_paragraph(
    n_physicians = 100, n_cities = 5, specialties = "cardiology",
    model_family = "negative_binomial"
  )
  result_auto <- mysterycall_methods_paragraph(
    n_physicians = 100, n_cities = 5, specialties = "cardiology",
    model_family = "auto"
  )
  expect_true(grepl("Poisson", result_poisson))
  expect_true(grepl("negative binomial", result_nb))
  expect_true(grepl("Poisson", result_auto))
})

test_that("mysterycall_methods_paragraph rejects invalid n_physicians", {
  expect_error(mysterycall_methods_paragraph(0, 5, "test"), "positive number")
  expect_error(mysterycall_methods_paragraph(-10, 5, "test"), "positive number")
  expect_error(mysterycall_methods_paragraph("not_numeric", 5, "test"), "positive number")
})

test_that("mysterycall_methods_paragraph rejects invalid n_cities", {
  expect_error(mysterycall_methods_paragraph(100, 0, "test"), "positive number")
  expect_error(mysterycall_methods_paragraph(100, -5, "test"), "positive number")
  expect_error(mysterycall_methods_paragraph(100, "not_numeric", "test"), "positive number")
})

test_that("mysterycall_methods_paragraph rejects invalid specialties", {
  expect_error(mysterycall_methods_paragraph(100, 5, character(0)), "non-empty character")
  expect_error(mysterycall_methods_paragraph(100, 5, 123), "non-empty character")
})

# ============================================================================
# mysterycall_format_results_table
# ============================================================================

test_that("mysterycall_format_results_table returns formatted data frame with valid irr_table", {
  skip_if_not_installed("lme4")
  set.seed(209)
  mod <- suppressMessages(mysterycall_poisson_model(COUNT_DF, outcome="days", predictors="insurance", random_intercept="physician"))

  result <- mysterycall_format_results_table(mod$irr_table)
  expect_s3_class(result, "data.frame")
  expect_true(all(c("Term", "IRR", "95% CI", "p-value") %in% names(result)))
  expect_true(!is.null(attr(result, "significant_rows")))
  expect_type(attr(result, "significant_rows"), "integer")
})

test_that("mysterycall_format_results_table excludes intercept by default", {
  skip_if_not_installed("lme4")
  set.seed(209)
  mod <- suppressMessages(mysterycall_poisson_model(COUNT_DF, outcome="days", predictors="insurance", random_intercept="physician"))

  result_no_intercept <- mysterycall_format_results_table(mod$irr_table, include_intercept = FALSE)
  expect_false(any(result_no_intercept$Term == "(Intercept)"))
})

test_that("mysterycall_format_results_table includes intercept when requested", {
  skip_if_not_installed("lme4")
  set.seed(209)
  mod <- suppressMessages(mysterycall_poisson_model(COUNT_DF, outcome="days", predictors="insurance", random_intercept="physician"))

  result_with_intercept <- mysterycall_format_results_table(mod$irr_table, include_intercept = TRUE)
  expect_true(any(result_with_intercept$Term == "(Intercept)"))
})

test_that("mysterycall_format_results_table respects digits parameter", {
  skip_if_not_installed("lme4")
  set.seed(209)
  mod <- suppressMessages(mysterycall_poisson_model(COUNT_DF, outcome="days", predictors="insurance", random_intercept="physician"))

  result_2 <- mysterycall_format_results_table(mod$irr_table, digits = 2L)
  result_4 <- mysterycall_format_results_table(mod$irr_table, digits = 4L)

  expect_type(result_2$IRR, "character")
  expect_type(result_4$IRR, "character")
  # 4-digit version should have more decimal places
  expect_true(nchar(result_4$IRR[1]) >= nchar(result_2$IRR[1]))
})

test_that("mysterycall_format_results_table accepts model object directly", {
  skip_if_not_installed("lme4")
  set.seed(209)
  mod <- suppressMessages(mysterycall_poisson_model(COUNT_DF, outcome="days", predictors="insurance", random_intercept="physician"))

  result <- mysterycall_format_results_table(mod)
  expect_s3_class(result, "data.frame")
  expect_true(all(c("Term", "IRR", "95% CI", "p-value") %in% names(result)))
})

test_that("mysterycall_format_results_table formats p-values correctly", {
  skip_if_not_installed("lme4")
  set.seed(209)
  mod <- suppressMessages(mysterycall_poisson_model(COUNT_DF, outcome="days", predictors="insurance", random_intercept="physician"))

  result <- mysterycall_format_results_table(mod$irr_table)
  # Check that p-value column exists and contains formatted values
  expect_true(all(is.character(result$`p-value`)))
})

test_that("mysterycall_format_results_table rejects missing required columns", {
  df <- data.frame(
    term = c("a", "b"),
    irr = c(1.0, 1.1),
    stringsAsFactors = FALSE
  )
  expect_error(mysterycall_format_results_table(df), "Missing columns")
})

test_that("mysterycall_format_results_table rejects non-data-frame/non-model input", {
  expect_error(mysterycall_format_results_table(list(x = 1)), "must be a data frame")
  expect_error(mysterycall_format_results_table(c(1, 2, 3)), "must be a data frame")
})
