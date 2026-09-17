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

# Test 1: Happy path - valid inputs return proper data.frame structure
test_that("mysterycall_sensitivity_table returns data.frame with correct structure", {

  # Create sample logistic models using structure()
  m1 <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        or          = c(3.50, 0.62),
        ci_lower    = c(2.10, 0.40),
        ci_upper    = c(5.80, 0.97),
        p_value     = c(0.0001, 0.036),
        p_value_fmt = c("< 0.001", "0.036"),
        stringsAsFactors = FALSE
      ),
      n   = 160L,
      aic = 210.4
    ),
    class = "mysterycall_logistic_model"
  )

  m2 <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid", "settingAcademic"),
        or          = c(3.20, 0.65, 1.18),
        ci_lower    = c(1.80, 0.42, 0.79),
        ci_upper    = c(5.70, 1.01, 1.77),
        p_value     = c(0.0003, 0.055, 0.417),
        p_value_fmt = c("< 0.001", "0.055", "0.417"),
        stringsAsFactors = FALSE
      ),
      n   = 160L,
      aic = 208.1
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("Unadjusted" = m1, "Adjusted" = m2),
    exposure_term = "insuranceMedicaid",
    digits        = 2L
  ))

  expect_s3_class(result, "data.frame")
  expect_true("Characteristic" %in% names(result))
  expect_true("Unadjusted" %in% names(result))
  expect_true("Adjusted" %in% names(result))
  expect_equal(nrow(result), 3)  # exposure row + Sample size + AIC
})

# Test 2: Edge case - missing terms return em-dash
test_that("mysterycall_sensitivity_table returns em-dash for missing terms", {

  m_has_term <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        or          = c(3.50, 0.62),
        ci_lower    = c(2.10, 0.40),
        ci_upper    = c(5.80, 0.97),
        p_value     = c(0.0001, 0.036),
        p_value_fmt = c("< 0.001", "0.036"),
        stringsAsFactors = FALSE
      ),
      n   = 160L,
      aic = 210.4
    ),
    class = "mysterycall_logistic_model"
  )

  m_missing_term <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "settingAcademic"),
        or          = c(3.20, 1.18),
        ci_lower    = c(1.80, 0.79),
        ci_upper    = c(5.70, 1.77),
        p_value     = c(0.0003, 0.417),
        p_value_fmt = c("< 0.001", "0.417"),
        stringsAsFactors = FALSE
      ),
      n   = 160L,
      aic = 208.1
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("Model1" = m_has_term, "Model2" = m_missing_term),
    exposure_term = "insuranceMedicaid",
    digits        = 2L
  ))

  # First data column (Model1) should contain estimate
  expect_match(result[1, 2], "0.62")
  # Second data column (Model2) should contain em-dash for missing term
  expect_equal(result[1, 3], "—")
})

# Test 3: Bad input - empty list should error
test_that("mysterycall_sensitivity_table errors on empty or unnamed list", {

  m1 <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        or          = c(3.50, 0.62),
        ci_lower    = c(2.10, 0.40),
        ci_upper    = c(5.80, 0.97),
        p_value     = c(0.0001, 0.036),
        p_value_fmt = c("< 0.001", "0.036"),
        stringsAsFactors = FALSE
      ),
      n   = 160L,
      aic = 210.4
    ),
    class = "mysterycall_logistic_model"
  )

  # Empty list
  expect_error(
    mysterycall_sensitivity_table(
      models        = list(),
      exposure_term = "insuranceMedicaid"
    )
  )

  # Unnamed list
  expect_error(
    mysterycall_sensitivity_table(
      models        = list(m1),
      exposure_term = "insuranceMedicaid"
    )
  )

  # Empty exposure_term
  expect_error(
    mysterycall_sensitivity_table(
      models        = list("Model1" = m1),
      exposure_term = ""
    )
  )
})

# Test 4: Bad input - wrong model class should error
test_that("mysterycall_sensitivity_table errors on unsupported model class", {

  bad_model <- list(
    or_table = data.frame(term = "x", or = 1.0),
    n = 100L,
    aic = 200.0
  )
  class(bad_model) <- "wrong_class"

  expect_error(
    mysterycall_sensitivity_table(
      models        = list("BadModel" = bad_model),
      exposure_term = "insuranceMedicaid"
    ),
    "unsupported class"
  )
})

# Test 5: Parameter variation - include_n and include_aic control row inclusion
test_that("mysterycall_sensitivity_table respects include_n and include_aic", {

  m1 <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        or          = c(3.50, 0.62),
        ci_lower    = c(2.10, 0.40),
        ci_upper    = c(5.80, 0.97),
        p_value     = c(0.0001, 0.036),
        p_value_fmt = c("< 0.001", "0.036"),
        stringsAsFactors = FALSE
      ),
      n   = 160L,
      aic = 210.4
    ),
    class = "mysterycall_logistic_model"
  )

  # Both included (default)
  result_both <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("M1" = m1),
    exposure_term = "insuranceMedicaid",
    include_n     = TRUE,
    include_aic   = TRUE
  ))
  expect_equal(nrow(result_both), 3)  # exposure + n + aic

  # Only n included
  result_n_only <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("M1" = m1),
    exposure_term = "insuranceMedicaid",
    include_n     = TRUE,
    include_aic   = FALSE
  ))
  expect_equal(nrow(result_n_only), 2)  # exposure + n

  # Only aic included
  result_aic_only <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("M1" = m1),
    exposure_term = "insuranceMedicaid",
    include_n     = FALSE,
    include_aic   = TRUE
  ))
  expect_equal(nrow(result_aic_only), 2)  # exposure + aic

  # Neither included
  result_none <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("M1" = m1),
    exposure_term = "insuranceMedicaid",
    include_n     = FALSE,
    include_aic   = FALSE
  ))
  expect_equal(nrow(result_none), 1)  # exposure only
})

# Test 6: Mixed model types (logistic + Poisson)
test_that("mysterycall_sensitivity_table handles mixed logistic and Poisson models", {

  m_logistic <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        or          = c(3.50, 0.62),
        ci_lower    = c(2.10, 0.40),
        ci_upper    = c(5.80, 0.97),
        p_value     = c(0.0001, 0.036),
        p_value_fmt = c("< 0.001", "0.036"),
        stringsAsFactors = FALSE
      ),
      n   = 160L,
      aic = 210.4
    ),
    class = "mysterycall_logistic_model"
  )

  m_poisson <- structure(
    list(
      irr_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        irr         = c(18.3, 1.41),
        ci_lower    = c(14.1, 1.08),
        ci_upper    = c(23.7, 1.84),
        p_value     = c(0.0001, 0.012),
        p_value_fmt = c("< 0.001", "0.012"),
        stringsAsFactors = FALSE
      ),
      n   = 145L,
      aic = 893.6
    ),
    class = "mysterycall_poisson_model"
  )

  result <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("Offered (OR)" = m_logistic, "Days (IRR)" = m_poisson),
    exposure_term = "insuranceMedicaid",
    digits        = 2L
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)  # exposure + n + aic
  # Logistic model contributes OR type
  expect_match(result[1, 2], "0.62")
  # Poisson model contributes IRR type
  expect_match(result[1, 3], "1.41")
})

# Test 7: Negative binomial model support
test_that("mysterycall_sensitivity_table handles negative binomial models", {

  m_nb <- structure(
    list(
      irr_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        irr         = c(5.2, 0.95),
        ci_lower    = c(3.8, 0.70),
        ci_upper    = c(7.1, 1.29),
        p_value     = c(0.0001, 0.732),
        p_value_fmt = c("< 0.001", "0.732"),
        stringsAsFactors = FALSE
      ),
      n   = 120L,
      aic = 450.2
    ),
    class = "mysterycall_nb_model"
  )

  result <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("NB Model" = m_nb),
    exposure_term = "insuranceMedicaid",
    digits        = 2L
  ))

  expect_s3_class(result, "data.frame")
  expect_match(result[1, 1], "insuranceMedicaid \\(IRR\\)")
  expect_match(result[1, 2], "0.95")
})

# Test 8: LMM (linear mixed model) support
test_that("mysterycall_sensitivity_table handles LMM objects", {
  skip_if_not_installed("lme4")

  m_lmm <- structure(
    list(
      coef_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        estimate    = c(5.5, -0.8),
        ci_lower    = c(3.2, -1.5),
        ci_upper    = c(7.8, -0.1),
        p_value     = c(0.0001, 0.023),
        p_value_fmt = c("< 0.001", "0.023"),
        stringsAsFactors = FALSE
      ),
      n   = 100L,
      aic = 325.6
    ),
    class = "mysterycall_lmm"
  )

  result <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("LMM" = m_lmm),
    exposure_term = "insuranceMedicaid",
    digits        = 2L
  ))

  expect_s3_class(result, "data.frame")
  expect_match(result[1, 1], "insuranceMedicaid \\(beta\\)")
  expect_match(result[1, 2], "-0.80")
})

# Test 9: Digits parameter controls decimal places
test_that("mysterycall_sensitivity_table respects digits parameter", {

  m1 <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        or          = c(3.5001, 0.6234),
        ci_lower    = c(2.1005, 0.3999),
        ci_upper    = c(5.8012, 0.9876),
        p_value     = c(0.0001, 0.036),
        p_value_fmt = c("< 0.001", "0.036"),
        stringsAsFactors = FALSE
      ),
      n   = 160L,
      aic = 210.4
    ),
    class = "mysterycall_logistic_model"
  )

  # 0 digits
  result_0 <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("M" = m1),
    exposure_term = "insuranceMedicaid",
    digits        = 0L
  ))
  expect_match(result_0[1, 2], "1 \\(0 to 1\\)")

  # 3 digits
  result_3 <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("M" = m1),
    exposure_term = "insuranceMedicaid",
    digits        = 3L
  ))
  expect_match(result_3[1, 2], "0.623 \\(0.400 to 0.988\\)")
})

# Test 10: NA values in model metadata (n, aic)
test_that("mysterycall_sensitivity_table handles NA in n or aic", {

  m_with_na_aic <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        or          = c(3.50, 0.62),
        ci_lower    = c(2.10, 0.40),
        ci_upper    = c(5.80, 0.97),
        p_value     = c(0.0001, 0.036),
        p_value_fmt = c("< 0.001", "0.036"),
        stringsAsFactors = FALSE
      ),
      n   = 160L,
      aic = NA_real_
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressMessages(mysterycall_sensitivity_table(
    models        = list("M" = m_with_na_aic),
    exposure_term = "insuranceMedicaid",
    include_aic   = TRUE
  ))

  expect_equal(result[3, 2], "—")  # AIC row should have em-dash for NA
})
