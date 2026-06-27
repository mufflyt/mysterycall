# testthat 3rd edition tests for mysterycall_abstract_numbers()

# ---------------------------------------------------------------------------
# Shared fake model objects (built with structure(), no real fitting)
# ---------------------------------------------------------------------------

fake_logistic <- structure(
  list(
    n        = 412L,
    or_table = data.frame(
      term     = c("(Intercept)", "insuranceMedicaid"),
      or       = c(2.10, 0.62),
      ci_lower = c(1.20, 0.41),
      ci_upper = c(3.68, 0.94),
      p_value  = c(0.008, 0.024),
      stringsAsFactors = FALSE
    )
  ),
  class = "mysterycall_logistic_model"
)

fake_poisson <- structure(
  list(
    n         = 298L,
    irr_table = data.frame(
      term     = c("(Intercept)", "insuranceMedicaid"),
      irr      = c(0.95, 1.40),
      ci_lower = c(0.70, 1.12),
      ci_upper = c(1.29, 1.75),
      p_value  = c(0.782, 0.003),
      stringsAsFactors = FALSE
    )
  ),
  class = "mysterycall_poisson_model"
)

fake_lmm <- structure(
  list(
    n               = 180L,
    log_transformed = FALSE,
    coef_table      = data.frame(
      term     = c("(Intercept)", "insuranceMedicaid"),
      estimate = c(14.2, -3.1),
      ci_lower = c(11.0, -5.8),
      ci_upper = c(17.4, -0.4),
      p_value  = c(0.001, 0.018),
      stringsAsFactors = FALSE
    )
  ),
  class = "mysterycall_lmm"
)

# ---------------------------------------------------------------------------
# 1. Returns a list with S3 class mysterycall_abstract_numbers
# ---------------------------------------------------------------------------

test_that("returns list of class mysterycall_abstract_numbers", {
  result <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    exposure_term = "insuranceMedicaid"
  )
  expect_type(result, "list")
  expect_s3_class(result, "mysterycall_abstract_numbers")
})

# ---------------------------------------------------------------------------
# 2. abstract_sentence is a character scalar
# ---------------------------------------------------------------------------

test_that("abstract_sentence is a character scalar", {
  result <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    exposure_term = "insuranceMedicaid"
  )
  expect_type(result$abstract_sentence, "character")
  expect_length(result$abstract_sentence, 1L)
  expect_true(nzchar(result$abstract_sentence))
})

# ---------------------------------------------------------------------------
# 3. n_total is extracted from logistic_fit$n
# ---------------------------------------------------------------------------

test_that("n_total is extracted from logistic_fit$n", {
  result <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    exposure_term = "insuranceMedicaid"
  )
  expect_equal(result$n_total, 412L)
  expect_type(result$n_total, "integer")
})

# ---------------------------------------------------------------------------
# 4. or is rounded to digits_or decimal places
# ---------------------------------------------------------------------------

test_that("or is rounded to digits_or decimal places", {
  result2 <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    exposure_term = "insuranceMedicaid",
    digits_or     = 2L
  )
  expect_equal(result2$or, round(0.62, 2))

  result3 <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    exposure_term = "insuranceMedicaid",
    digits_or     = 3L
  )
  # OR value should differ in representation; both numeric, no extra rounding artifact
  expect_equal(result3$or, round(0.62, 3))
  expect_match(result3$numbers_list[["OR"]], "^0\\.620$")
})

# ---------------------------------------------------------------------------
# 5. or_ci contains parentheses and a dash
# ---------------------------------------------------------------------------

test_that("or_ci contains parentheses and dash", {
  result <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    exposure_term = "insuranceMedicaid"
  )
  expect_type(result$or_ci, "character")
  expect_match(result$or_ci, "\\(")
  expect_match(result$or_ci, "-")
  # Full format: "0.62 (0.41-0.94)"
  expect_match(result$or_ci, "^0\\.62 \\(0\\.41-0\\.94\\)$")
})

# ---------------------------------------------------------------------------
# 6. numbers_list is a named character vector
# ---------------------------------------------------------------------------

test_that("numbers_list is a named character vector", {
  result <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    exposure_term = "insuranceMedicaid"
  )
  expect_type(result$numbers_list, "character")
  expect_false(is.null(names(result$numbers_list)))
  expect_true(all(nzchar(names(result$numbers_list))))
  # Must contain at least n_total and OR entries
  expect_true("n_total" %in% names(result$numbers_list))
  expect_true("OR"      %in% names(result$numbers_list))
})

# ---------------------------------------------------------------------------
# 7. Works with only logistic_fit (poisson_fit = NULL)
# ---------------------------------------------------------------------------

test_that("works with only logistic_fit supplied", {
  expect_no_error(
    result <- mysterycall_abstract_numbers(
      logistic_fit  = fake_logistic,
      poisson_fit   = NULL,
      exposure_term = "insuranceMedicaid"
    )
  )
  expect_false(is.na(result$or))
  expect_true(is.na(result$irr))
  expect_true(is.na(result$beta))
  expect_equal(result$n_total, 412L)
})

# ---------------------------------------------------------------------------
# 8. Works with only poisson_fit (logistic_fit = NULL)
# ---------------------------------------------------------------------------

test_that("works with only poisson_fit supplied", {
  expect_no_error(
    result <- mysterycall_abstract_numbers(
      logistic_fit  = NULL,
      poisson_fit   = fake_poisson,
      exposure_term = "insuranceMedicaid"
    )
  )
  expect_true(is.na(result$or))
  expect_false(is.na(result$irr))
  # n_total should now come from poisson_fit$n
  expect_equal(result$n_total, 298L)
})

# ---------------------------------------------------------------------------
# 9. Warning (not hard error) when exposure_term not found; result is NA
# ---------------------------------------------------------------------------

test_that("warns and sets or to NA when exposure_term absent from logistic_fit", {
  expect_warning(
    result <- mysterycall_abstract_numbers(
      logistic_fit  = fake_logistic,
      exposure_term = "insuranceMissing"
    ),
    regexp = "not found"
  )
  expect_true(is.na(result$or))
  expect_true(is.na(result$or_ci))
})

# ---------------------------------------------------------------------------
# 10. absolute_gap computed correctly from acceptance_rate argument
# ---------------------------------------------------------------------------

test_that("absolute_gap is ref minus comparison acceptance rate", {
  result <- mysterycall_abstract_numbers(
    logistic_fit    = fake_logistic,
    exposure_term   = "insuranceMedicaid",
    acceptance_rate = c(ref = 0.82, comparison = 0.61)
  )
  expect_equal(result$absolute_gap, 0.82 - 0.61, tolerance = 1e-9)
  # When acceptance_rate is NULL the gap must be NA
  result_null <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    exposure_term = "insuranceMedicaid"
  )
  expect_true(is.na(result_null$absolute_gap))
})

# ---------------------------------------------------------------------------
# 11. Print method produces output and returns the object invisibly
# ---------------------------------------------------------------------------

test_that("print method produces output and returns invisibly", {
  result <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    exposure_term = "insuranceMedicaid"
  )
  output <- capture.output(ret <- print(result))
  expect_true(length(output) > 0L)
  expect_true(any(grepl("mysterycall_abstract_numbers", output)))
  # Return value must be the original object (invisible)
  expect_identical(ret, result)
})

# ---------------------------------------------------------------------------
# 12. irr extracted from poisson_fit when provided
# ---------------------------------------------------------------------------

test_that("irr is extracted from poisson_fit when provided", {
  result <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    poisson_fit   = fake_poisson,
    exposure_term = "insuranceMedicaid"
  )
  expect_false(is.na(result$irr))
  expect_equal(result$irr, round(1.40, 2))
  expect_true("IRR" %in% names(result$numbers_list))
  expect_match(result$irr_ci, "\\(")
  expect_match(result$irr_ci, "-")
})

# ---------------------------------------------------------------------------
# 13. Error when all three fit arguments are NULL
# ---------------------------------------------------------------------------

test_that("errors when all fit arguments are NULL", {
  expect_error(
    mysterycall_abstract_numbers(
      logistic_fit  = NULL,
      poisson_fit   = NULL,
      lmm_fit       = NULL,
      exposure_term = "insuranceMedicaid"
    ),
    regexp = "At least one"
  )
})

# ---------------------------------------------------------------------------
# 14. abstract_sentence embeds n_total from the leading model
# ---------------------------------------------------------------------------

test_that("abstract_sentence contains the n_total count", {
  result <- mysterycall_abstract_numbers(
    logistic_fit  = fake_logistic,
    exposure_term = "insuranceMedicaid"
  )
  expect_match(result$abstract_sentence, "412")
})

# ---------------------------------------------------------------------------
# 15. lmm_fit only: beta extracted; irr and or remain NA
# ---------------------------------------------------------------------------

test_that("works with only lmm_fit; beta extracted, or and irr are NA", {
  expect_no_error(
    result <- mysterycall_abstract_numbers(
      lmm_fit       = fake_lmm,
      exposure_term = "insuranceMedicaid"
    )
  )
  expect_true(is.na(result$or))
  expect_true(is.na(result$irr))
  expect_false(is.na(result$beta))
  expect_equal(result$beta, round(-3.1, 2))
  expect_equal(result$n_total, 180L)
})
