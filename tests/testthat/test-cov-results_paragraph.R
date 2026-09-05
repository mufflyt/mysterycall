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


test_that("mysterycall_results_paragraph returns character with valid data frame", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured"),
    or       = c(2.10, 0.62, 0.41),
    ci_lower = c(1.20, 0.41, 0.22),
    ci_upper = c(3.68, 0.94, 0.76),
    p_value  = c(0.008, 0.024, 0.0004),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_results_paragraph(
    or_tbl,
    "commercial insurance",
    "insurance"
  )
  expect_type(result, "character")
  expect_length(result, 1L)
  expect_true(nchar(result) > 0L)
  expect_match(result, "Medicaid")
  expect_match(result, "Uninsured")
})

test_that("mysterycall_results_paragraph formats OR > 1 as 'more likely'", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 1.50),
    ci_lower = c(0.95, 1.10),
    ci_upper = c(1.05, 1.90),
    p_value  = c(0.5, 0.01),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_results_paragraph(or_tbl, "ref", "insurance")
  expect_match(result, "more likely")
  expect_match(result, "50%")
})

test_that("mysterycall_results_paragraph formats OR < 1 as 'less likely'", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 0.50),
    ci_lower = c(0.95, 0.30),
    ci_upper = c(1.05, 0.70),
    p_value  = c(0.5, 0.01),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_results_paragraph(or_tbl, "ref", "insurance")
  expect_match(result, "less likely")
  expect_match(result, "50%")
})

test_that("mysterycall_results_paragraph formats OR ≈ 1 as 'similar odds'", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 1.0001),
    ci_lower = c(0.95, 0.80),
    ci_upper = c(1.05, 1.20),
    p_value  = c(0.5, 0.95),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_results_paragraph(or_tbl, "ref", "insurance", or_digits = 2L)
  expect_match(result, "similar odds")
})

test_that("mysterycall_results_paragraph formats p < 0.001 correctly", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 0.50),
    ci_lower = c(0.95, 0.30),
    ci_upper = c(1.05, 0.70),
    p_value  = c(0.5, 0.0005),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_results_paragraph(or_tbl, "ref", "insurance")
  expect_match(result, "p < 0.001")
  expect_false(grepl("p=0.000", result))
})

test_that("mysterycall_results_paragraph respects or_digits parameter", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 1.2345),
    ci_lower = c(0.95, 1.10),
    ci_upper = c(1.05, 1.35),
    p_value  = c(0.5, 0.01),
    stringsAsFactors = FALSE
  )
  result_2 <- mysterycall_results_paragraph(or_tbl, "ref", "insurance", or_digits = 2L)
  result_4 <- mysterycall_results_paragraph(or_tbl, "ref", "insurance", or_digits = 4L)
  expect_match(result_2, "OR 1.23")
  expect_match(result_4, "OR 1.2345")
})

test_that("mysterycall_results_paragraph respects ci_digits parameter", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 1.2),
    ci_lower = c(0.95, 1.111),
    ci_upper = c(1.05, 1.333),
    p_value  = c(0.5, 0.01),
    stringsAsFactors = FALSE
  )
  result_2 <- mysterycall_results_paragraph(or_tbl, "ref", "insurance", ci_digits = 2L)
  result_3 <- mysterycall_results_paragraph(or_tbl, "ref", "insurance", ci_digits = 3L)
  expect_match(result_2, "1.11 to 1.33")
  expect_match(result_3, "1.111 to 1.333")
})

test_that("mysterycall_results_paragraph respects p_digits parameter", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 1.2),
    ci_lower = c(0.95, 1.10),
    ci_upper = c(1.05, 1.30),
    p_value  = c(0.5, 0.012345),
    stringsAsFactors = FALSE
  )
  result_2 <- mysterycall_results_paragraph(or_tbl, "ref", "insurance", p_digits = 2L)
  result_4 <- mysterycall_results_paragraph(or_tbl, "ref", "insurance", p_digits = 4L)
  expect_match(result_2, "p=0.01")
  expect_match(result_4, "p=0.0123")
})

test_that("mysterycall_results_paragraph respects custom outcome_label", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 1.5),
    ci_lower = c(0.95, 1.10),
    ci_upper = c(1.05, 1.90),
    p_value  = c(0.5, 0.01),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_results_paragraph(
    or_tbl,
    "ref",
    "insurance",
    outcome_label = "service access"
  )
  expect_match(result, "service access")
  expect_false(grepl("appointment acceptance", result))
})

test_that("mysterycall_results_paragraph stops when required columns missing", {
  or_tbl <- data.frame(
    term     = c("insuranceMedicaid"),
    or       = c(0.62),
    ci_lower = c(0.41),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_results_paragraph(or_tbl, "ref", "insurance"),
    "missing required column"
  )
})

test_that("mysterycall_results_paragraph stops when no exposure_col match found", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 0.62),
    ci_lower = c(0.95, 0.41),
    ci_upper = c(1.05, 0.94),
    p_value  = c(0.5, 0.024),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_results_paragraph(or_tbl, "ref", "nonexistent"),
    "No coefficient found matching exposure_col"
  )
})

test_that("mysterycall_results_paragraph stops on invalid model_result type", {
  expect_error(
    mysterycall_results_paragraph(
      list(a = 1),
      "ref",
      "insurance"
    ),
    "must be a `mysterycall_logistic_model` object or a data frame"
  )
})

test_that("mysterycall_results_paragraph stops when alpha is out of range", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 0.62),
    ci_lower = c(0.95, 0.41),
    ci_upper = c(1.05, 0.94),
    p_value  = c(0.5, 0.024),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_results_paragraph(or_tbl, "ref", "insurance", alpha = 1.5),
    "alpha"
  )
})

test_that("mysterycall_results_paragraph stops when ref_group is empty string", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 0.62),
    ci_lower = c(0.95, 0.41),
    ci_upper = c(1.05, 0.94),
    p_value  = c(0.5, 0.024),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_results_paragraph(or_tbl, "", "insurance"),
    "ref_group"
  )
})

test_that("mysterycall_results_paragraph handles multiple exposure levels", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured", "insuranceOther"),
    or       = c(1.0, 0.62, 0.41, 1.25),
    ci_lower = c(0.95, 0.41, 0.22, 0.90),
    ci_upper = c(1.05, 0.94, 0.76, 1.60),
    p_value  = c(0.5, 0.024, 0.0004, 0.18),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_results_paragraph(or_tbl, "ref", "insurance")
  expect_match(result, "Medicaid")
  expect_match(result, "Uninsured")
  expect_match(result, "Other")
  sentence_count <- length(strsplit(result, "\\. ")[[1]])
  expect_equal(sentence_count, 3L)
})

test_that("mysterycall_results_paragraph handles NA p_value gracefully", {
  or_tbl <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid"),
    or       = c(1.0, 0.62),
    ci_lower = c(0.95, 0.41),
    ci_upper = c(1.05, 0.94),
    p_value  = c(0.5, NA),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_results_paragraph(or_tbl, "ref", "insurance")
  expect_match(result, "p = NA")
})
