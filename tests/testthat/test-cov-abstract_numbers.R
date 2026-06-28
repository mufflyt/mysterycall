library(testthat)
library(mysterycall)

# ---- Fixtures ----

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

# ---- Minimal test fixtures for model objects ----

fake_logistic_basic <- structure(
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

fake_poisson_basic <- structure(
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

fake_nb_basic <- structure(
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
  class = "mysterycall_nb_model"
)

fake_lmm_basic <- structure(
  list(
    n              = 250L,
    log_transformed = FALSE,
    coef_table     = data.frame(
      term     = c("(Intercept)", "insuranceMedicaid"),
      estimate = c(7.5, 1.2),
      ci_lower = c(6.1, 0.8),
      ci_upper = c(8.9, 1.6),
      p_value  = c(0.001, 0.042),
      stringsAsFactors = FALSE
    )
  ),
  class = "mysterycall_lmm"
)

fake_lmm_log <- structure(
  list(
    n              = 250L,
    log_transformed = TRUE,
    coef_table     = data.frame(
      term     = c("(Intercept)", "insuranceMedicaid"),
      estimate = c(1.95, 0.15),
      ci_lower = c(1.80, 0.05),
      ci_upper = c(2.10, 0.25),
      p_value  = c(0.001, 0.042),
      stringsAsFactors = FALSE
    )
  ),
  class = "mysterycall_lmm"
)


# ---- Test mysterycall_abstract_numbers() ----

test_that("mysterycall_abstract_numbers happy path: logistic only", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      exposure_term    = "insuranceMedicaid",
      ref_label        = "commercial insurance",
      comparison_label = "Medicaid",
      acceptance_rate  = c(ref = 0.82, comparison = 0.61)
    )
  ))

  expect_s3_class(result, "mysterycall_abstract_numbers")
  expect_type(result, "list")
  expect_true(all(c("n_total", "or", "or_ci", "or_p", "irr", "irr_ci",
                     "irr_p", "beta", "beta_ci", "beta_p", "absolute_gap",
                     "abstract_sentence", "numbers_list") %in% names(result)))
  expect_equal(result$n_total, 412L)
  expect_equal(result$or, 0.62)
  expect_type(result$or_ci, "character")
  expect_true(grepl("appointment", result$abstract_sentence))
  expect_true(is.na(result$irr))
  expect_true(is.na(result$beta))
})

test_that("mysterycall_abstract_numbers happy path: poisson only", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      poisson_fit      = fake_poisson_basic,
      exposure_term    = "insuranceMedicaid",
      ref_label        = "commercial insurance"
    )
  ))

  expect_s3_class(result, "mysterycall_abstract_numbers")
  expect_equal(result$n_total, 298L)
  expect_equal(result$irr, 1.40)
  expect_type(result$irr_ci, "character")
  expect_true(is.na(result$or))
  expect_true(is.na(result$beta))
  expect_match(result$abstract_sentence, "wait times")
})

test_that("mysterycall_abstract_numbers happy path: NB model", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      poisson_fit   = fake_nb_basic,
      exposure_term = "insuranceMedicaid"
    )
  ))

  expect_s3_class(result, "mysterycall_abstract_numbers")
  expect_equal(result$irr, 1.40)
  expect_true(is.na(result$or))
})

test_that("mysterycall_abstract_numbers happy path: LMM only", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      lmm_fit       = fake_lmm_basic,
      exposure_term = "insuranceMedicaid"
    )
  ))

  expect_s3_class(result, "mysterycall_abstract_numbers")
  expect_equal(result$n_total, 250L)
  expect_equal(result$beta, 1.20)
  expect_type(result$beta_ci, "character")
  expect_true(is.na(result$or))
  expect_true(is.na(result$irr))
  expect_match(result$abstract_sentence, "days")
})

test_that("mysterycall_abstract_numbers happy path: LMM log-transformed", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      lmm_fit       = fake_lmm_log,
      exposure_term = "insuranceMedicaid"
    )
  ))

  expect_s3_class(result, "mysterycall_abstract_numbers")
  expect_equal(result$beta, 0.15)
  expect_match(result$abstract_sentence, "log-days")
})

test_that("mysterycall_abstract_numbers happy path: combined logistic + poisson", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      poisson_fit      = fake_poisson_basic,
      exposure_term    = "insuranceMedicaid",
      ref_label        = "commercial insurance",
      acceptance_rate  = c(ref = 0.82, comparison = 0.61)
    )
  ))

  expect_s3_class(result, "mysterycall_abstract_numbers")
  expect_equal(result$or, 0.62)
  expect_equal(result$irr, 1.40)
  expect_true(is.na(result$beta))
  expect_match(result$abstract_sentence, "appointment")
  expect_match(result$abstract_sentence, "wait times")
})

test_that("mysterycall_abstract_numbers happy path: all three models", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      poisson_fit      = fake_poisson_basic,
      lmm_fit          = fake_lmm_basic,
      exposure_term    = "insuranceMedicaid"
    )
  ))

  expect_s3_class(result, "mysterycall_abstract_numbers")
  expect_equal(result$or, 0.62)
  expect_equal(result$irr, 1.40)
  expect_equal(result$beta, 1.20)
})

test_that("mysterycall_abstract_numbers: numbers_list is character vector", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit  = fake_logistic_basic,
      exposure_term = "insuranceMedicaid"
    )
  ))

  expect_type(result$numbers_list, "character")
  expect_true(all(nzchar(result$numbers_list)))
  expect_true("n_total" %in% names(result$numbers_list))
  expect_true("abstract_sentence" %in% names(result$numbers_list))
})

test_that("mysterycall_abstract_numbers: absolute_gap calculated correctly", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      exposure_term    = "insuranceMedicaid",
      acceptance_rate  = c(ref = 0.82, comparison = 0.61)
    )
  ))

  expect_equal(result$absolute_gap, 0.21, tolerance = 0.001)
  expect_match(result$abstract_sentence, "absolute")
})

test_that("mysterycall_abstract_numbers: acceptance_rate NULL produces NA gap", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit  = fake_logistic_basic,
      exposure_term = "insuranceMedicaid",
      acceptance_rate = NULL
    )
  ))

  expect_true(is.na(result$absolute_gap))
  expect_false(grepl("absolute", result$abstract_sentence))
})

test_that("mysterycall_abstract_numbers: derived comparison_label from exposure_term", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      exposure_term    = "insuranceMedicaid",
      comparison_label = NULL
    )
  ))

  expect_s3_class(result, "mysterycall_abstract_numbers")
  expect_match(result$abstract_sentence, "Medicaid")
})

test_that("mysterycall_abstract_numbers: exposure_term not found produces warning", {
  expect_warning({
    mysterycall_abstract_numbers(
      logistic_fit  = fake_logistic_basic,
      exposure_term = "insuranceNotFound"
    )
  }, "not found")
})

test_that("mysterycall_abstract_numbers: exposure_term not found results in NA or/irr/beta", {
  result <- suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit  = fake_logistic_basic,
      exposure_term = "insuranceNotFound"
    )
  )

  expect_true(is.na(result$or))
  expect_true(is.na(result$or_ci))
  expect_true(is.na(result$or_p))
})

test_that("mysterycall_abstract_numbers: digits_or and digits_p control precision", {
  result_2 <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit  = fake_logistic_basic,
      exposure_term = "insuranceMedicaid",
      digits_or     = 2L,
      digits_p      = 3L
    )
  ))

  result_1 <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit  = fake_logistic_basic,
      exposure_term = "insuranceMedicaid",
      digits_or     = 1L,
      digits_p      = 1L
    )
  ))

  expect_equal(result_2$or, 0.62)
  expect_equal(result_1$or, 0.6)
})

# ---- Edge cases: exposure_term validation ----

test_that("mysterycall_abstract_numbers: exposure_term must be character scalar", {
  expect_error(
    mysterycall_abstract_numbers(
      logistic_fit = fake_logistic_basic,
      exposure_term = 123
    ),
    "must be a non-empty character scalar"
  )
})

test_that("mysterycall_abstract_numbers: exposure_term cannot be empty string", {
  expect_error(
    mysterycall_abstract_numbers(
      logistic_fit = fake_logistic_basic,
      exposure_term = ""
    ),
    "must be a non-empty character scalar"
  )
})

test_that("mysterycall_abstract_numbers: exposure_term cannot be vector", {
  expect_error(
    mysterycall_abstract_numbers(
      logistic_fit = fake_logistic_basic,
      exposure_term = c("term1", "term2")
    ),
    "must be a non-empty character scalar"
  )
})

# ---- Edge cases: model class validation ----

test_that("mysterycall_abstract_numbers: logistic_fit must be correct class", {
  expect_error(
    mysterycall_abstract_numbers(
      logistic_fit  = list(n = 100),
      exposure_term = "test"
    ),
    "mysterycall_logistic_model"
  )
})

test_that("mysterycall_abstract_numbers: poisson_fit must be correct class", {
  expect_error(
    mysterycall_abstract_numbers(
      poisson_fit   = list(n = 100),
      exposure_term = "test"
    ),
    "mysterycall_poisson_model"
  )
})

test_that("mysterycall_abstract_numbers: lmm_fit must be correct class", {
  expect_error(
    mysterycall_abstract_numbers(
      lmm_fit       = list(n = 100),
      exposure_term = "test"
    ),
    "mysterycall_lmm"
  )
})

test_that("mysterycall_abstract_numbers: at least one model must be provided", {
  expect_error(
    mysterycall_abstract_numbers(
      exposure_term = "test"
    ),
    "At least one"
  )
})

# ---- Edge cases: acceptance_rate validation ----

test_that("mysterycall_abstract_numbers: acceptance_rate must be 2-element vector", {
  expect_error(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      exposure_term    = "insuranceMedicaid",
      acceptance_rate  = c(0.82)
    ),
    "two-element"
  )
})

test_that("mysterycall_abstract_numbers: acceptance_rate must be named correctly", {
  expect_error(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      exposure_term    = "insuranceMedicaid",
      acceptance_rate  = c(a = 0.82, b = 0.61)
    ),
    "named with elements"
  )
})

test_that("mysterycall_abstract_numbers: acceptance_rate must be numeric", {
  expect_error(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      exposure_term    = "insuranceMedicaid",
      acceptance_rate  = c(ref = "0.82", comparison = "0.61")
    ),
    "must be a two-element named numeric vector"
  )
})

# ---- Print method tests ----

test_that("print.mysterycall_abstract_numbers: basic functionality", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      exposure_term    = "insuranceMedicaid",
      acceptance_rate  = c(ref = 0.82, comparison = 0.61)
    )
  ))

  output <- capture.output({
    print(result)
  })

  expect_true(any(grepl("mysterycall_abstract_numbers", output)))
  expect_true(any(grepl("n_total", output)))
  expect_true(any(grepl("abstract_sentence", output)))
})

test_that("print.mysterycall_abstract_numbers: returns invisible", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit  = fake_logistic_basic,
      exposure_term = "insuranceMedicaid"
    )
  ))

  out <- withVisible(print(result))
  expect_identical(out$value, result)
  expect_false(out$visible)
})

test_that("print.mysterycall_abstract_numbers: all numbers_list entries printed", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      poisson_fit      = fake_poisson_basic,
      exposure_term    = "insuranceMedicaid",
      acceptance_rate  = c(ref = 0.82, comparison = 0.61)
    )
  ))

  output <- capture.output({
    print(result)
  })

  output_text <- paste(output, collapse = " ")
  expect_true(grepl("OR", output_text))
  expect_true(grepl("IRR", output_text))
})

# ---- Reference label customization ----

test_that("mysterycall_abstract_numbers: custom ref_label in sentence", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      exposure_term    = "insuranceMedicaid",
      ref_label        = "BCBS-insured"
    )
  ))

  expect_match(result$abstract_sentence, "BCBS-insured")
})

test_that("mysterycall_abstract_numbers: custom outcome_label in sentence", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit     = fake_logistic_basic,
      exposure_term    = "insuranceMedicaid",
      outcome_label    = "timely scheduling"
    )
  ))

  expect_match(result$abstract_sentence, "timely scheduling")
})

# ---- P-value formatting edge cases ----

test_that("mysterycall_abstract_numbers: p < 0.001 formatted as 'p < 0.001'", {
  # Create fake model with very small p-value
  fake_small_p <- structure(
    list(
      n        = 100L,
      or_table = data.frame(
        term     = c("(Intercept)", "testTerm"),
        or       = c(1.5, 2.0),
        ci_lower = c(1.0, 1.5),
        ci_upper = c(2.0, 2.5),
        p_value  = c(0.05, 0.0001),
        stringsAsFactors = FALSE
      )
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit  = fake_small_p,
      exposure_term = "testTerm"
    )
  ))

  expect_match(result$or_p, "< 0.001")
})

test_that("mysterycall_abstract_numbers: normal p-value formatted with digits_p", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_abstract_numbers(
      logistic_fit  = fake_logistic_basic,
      exposure_term = "insuranceMedicaid",
      digits_p      = 3L
    )
  ))

  expect_match(result$or_p, "0.024")
})
