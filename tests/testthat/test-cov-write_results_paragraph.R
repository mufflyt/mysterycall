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

test_that("write_results_paragraph returns character for valid data frame input", {
  irr_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured"),
    irr      = c(1.0, 0.72, 0.55),
    ci_lower = c(NA, 0.60, 0.40),
    ci_upper = c(NA, 0.86, 0.75),
    p_value  = c(NA, 0.0003, 0.0000001),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_write_results_paragraph(
    irr_tbl,
    "commercial insurance",
    "insurance"
  )

  expect_type(result, "character")
  expect_length(result, 1)
  expect_true(nchar(result) > 0)
  expect_true(grepl("Poisson regression", result))
  expect_true(grepl("Medicaid", result))
})

test_that("write_results_paragraph handles NA p-values correctly", {
  irr_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    irr      = c(1.0, 0.72),
    ci_lower = c(NA, 0.60),
    ci_upper = c(NA, 0.86),
    p_value  = c(NA, NA),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_write_results_paragraph(
    irr_tbl,
    "commercial insurance",
    "insurance"
  )

  expect_type(result, "character")
  expect_true(grepl("p = NA", result))
})

test_that("write_results_paragraph errors on missing required columns", {
  irr_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    irr      = c(1.0, 0.72),
    ci_lower = c(NA, 0.60),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_write_results_paragraph(
      irr_tbl,
      "commercial insurance",
      "insurance"
    ),
    "missing required columns"
  )
})

test_that("write_results_paragraph errors on non-matching exposure_col", {
  irr_tbl <- data.frame(
    term     = c("(Intercept)", "othervarMedicaid"),
    irr      = c(1.0, 0.72),
    ci_lower = c(NA, 0.60),
    ci_upper = c(NA, 0.86),
    p_value  = c(NA, 0.0003),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_write_results_paragraph(
      irr_tbl,
      "commercial insurance",
      "insurance"
    ),
    "No coefficient found"
  )
})

test_that("write_results_paragraph respects digit formatting parameters", {
  irr_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    irr      = c(1.0, 0.7234),
    ci_lower = c(NA, 0.6012),
    ci_upper = c(NA, 0.8567),
    p_value  = c(NA, 0.0003456),
    stringsAsFactors = FALSE
  )

  result_2dig <- mysterycall_write_results_paragraph(
    irr_tbl,
    "commercial insurance",
    "insurance",
    irr_digits = 2L,
    ci_digits = 2L,
    p_digits = 3L
  )

  result_3dig <- mysterycall_write_results_paragraph(
    irr_tbl,
    "commercial insurance",
    "insurance",
    irr_digits = 3L,
    ci_digits = 3L,
    p_digits = 4L
  )

  expect_type(result_2dig, "character")
  expect_type(result_3dig, "character")
  expect_true(grepl("0.72", result_2dig))
  expect_true(grepl("0.723", result_3dig))
})

test_that("write_results_paragraph errors on empty or invalid ref_group", {
  irr_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    irr      = c(1.0, 0.72),
    ci_lower = c(NA, 0.60),
    ci_upper = c(NA, 0.86),
    p_value  = c(NA, 0.0003),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_write_results_paragraph(
      irr_tbl,
      "",
      "insurance"
    )
  )
})

test_that("write_results_paragraph errors on invalid input type for model_result", {
  expect_error(
    mysterycall_write_results_paragraph(
      list(a = 1),
      "commercial insurance",
      "insurance"
    ),
    "must be a"
  )
})

test_that("write_results_paragraph handles p < 0.001 threshold", {
  irr_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    irr      = c(1.0, 0.72),
    ci_lower = c(NA, 0.60),
    ci_upper = c(NA, 0.86),
    p_value  = c(NA, 0.00000001),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_write_results_paragraph(
    irr_tbl,
    "commercial insurance",
    "insurance"
  )

  expect_type(result, "character")
  expect_true(grepl("p < 0.001", result))
  expect_false(grepl("p = 0.00", result))
})

test_that("write_results_paragraph includes custom outcome_label", {
  irr_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    irr      = c(1.0, 0.72),
    ci_lower = c(NA, 0.60),
    ci_upper = c(NA, 0.86),
    p_value  = c(NA, 0.0003),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_write_results_paragraph(
    irr_tbl,
    "commercial insurance",
    "insurance",
    outcome_label = "call completion"
  )

  expect_type(result, "character")
  expect_true(grepl("call completion", result))
  expect_false(grepl("appointment acceptance", result))
})

test_that("write_results_paragraph formats multiple levels", {
  irr_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured", "insuranceMedicare"),
    irr      = c(1.0, 0.72, 0.55, 0.85),
    ci_lower = c(NA, 0.60, 0.40, 0.70),
    ci_upper = c(NA, 0.86, 0.75, 1.00),
    p_value  = c(NA, 0.0003, 0.0000001, 0.08),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_write_results_paragraph(
    irr_tbl,
    "commercial insurance",
    "insurance"
  )

  expect_type(result, "character")
  expect_true(grepl("Medicaid", result))
  expect_true(grepl("Uninsured", result))
  expect_true(grepl("Medicare", result))
})
