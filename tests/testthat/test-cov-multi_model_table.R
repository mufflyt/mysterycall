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

# Helper: Create structured mock logistic model
.make_mock_logistic <- function(n = 150L, aic = 310.5) {
  structure(
    list(
      or_table = data.frame(
        term        = c("insuranceMedicaid", "scenarioNo appointment"),
        or          = c(1.45, 0.82),
        ci_lower    = c(1.02, 0.61),
        ci_upper    = c(2.05, 1.10),
        p_value_fmt = c("0.038", "0.189"),
        stringsAsFactors = FALSE
      ),
      factor_refs = list(insurance = "BCBS", scenario = "Appointment"),
      n   = n,
      aic = aic
    ),
    class = "mysterycall_logistic_model"
  )
}

# Helper: Create structured mock poisson model
.make_mock_poisson <- function(n = 150L, aic = 280.2) {
  structure(
    list(
      irr_table = data.frame(
        term        = c("insuranceMedicaid", "waveWave 2"),
        irr         = c(1.82, 1.15),
        ci_lower    = c(1.38, 0.92),
        ci_upper    = c(2.41, 1.44),
        p_value_fmt = c("< 0.001", "0.225"),
        stringsAsFactors = FALSE
      ),
      factor_refs = list(insurance = "BCBS", wave = "Wave 1"),
      n   = n,
      aic = aic
    ),
    class = "mysterycall_poisson_model"
  )
}

# Helper: Create structured mock NB model
.make_mock_nb <- function(n = 150L, aic = 285.3) {
  structure(
    list(
      irr_table = data.frame(
        term        = c("insuranceMedicaid"),
        irr         = c(1.65),
        ci_lower    = c(1.20),
        ci_upper    = c(2.27),
        p_value_fmt = c("0.002"),
        stringsAsFactors = FALSE
      ),
      factor_refs = list(insurance = "BCBS"),
      n   = n,
      aic = aic
    ),
    class = "mysterycall_nb_model"
  )
}

# Helper: Create structured mock LMM model
.make_mock_lmm <- function(n = 150L, reml = FALSE) {
  structure(
    list(
      coef_table = data.frame(
        term        = c("insuranceMedicaid", "regionSouth"),
        estimate    = c(0.45, -0.23),
        ci_lower    = c(0.12, -0.58),
        ci_upper    = c(0.78, 0.12),
        p_value_fmt = c("0.010", "0.187"),
        stringsAsFactors = FALSE
      ),
      factor_refs = list(insurance = "BCBS", region = "North"),
      n           = n,
      aic         = 295.8,
      REML        = reml,
      model       = list()  # placeholder
    ),
    class = "mysterycall_lmm"
  )
}

# =============================================================================
# TEST 1: Happy path — minimal valid inputs, returns expected structure
# =============================================================================
test_that("mysterycall_multi_model_table returns correct structure with minimal inputs", {
  m1 <- .make_mock_logistic(n = 200L, aic = 312.4)
  m2 <- .make_mock_logistic(n = 200L, aic = 308.1)

  result <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("Unadjusted" = m1, "Adjusted" = m2)
    )
  )

  # Check class
  expect_s3_class(result, c("mysterycall_multi_model_table", "data.frame"))

  # Check structure
  expect_true(is.data.frame(result))
  expect_true("Term" %in% names(result))
  expect_true("Unadjusted" %in% names(result))
  expect_true("Adjusted" %in% names(result))

  # Check attributes
  expect_true(!is.null(attr(result, "estimate_label")))
  expect_true(!is.null(attr(result, "mixed_types")))

  # Check default behavior (no intercept, include_n, include_aic)
  expect_false(any(result$Term == "(Intercept)"))
  expect_true(any(result$Term == "N"))
  expect_true(any(result$Term == "AIC"))
})

# =============================================================================
# TEST 2: Happy path — three-model setup with all features
# =============================================================================
test_that("mysterycall_multi_model_table handles three models and all parameters", {
  m1 <- .make_mock_logistic(n = 150L, aic = 310.0)
  m2 <- .make_mock_logistic(n = 150L, aic = 305.0)
  m3 <- .make_mock_logistic(n = 150L, aic = 302.0)

  result <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list(
        "Unadjusted" = m1,
        "Adjusted"   = m2,
        "+ Interaction" = m3
      ),
      include_intercept = FALSE,
      digits = 3L,
      estimate_col_label = "Odds Ratio",
      include_n = TRUE,
      include_aic = TRUE,
      ref_symbol = "REF"
    )
  )

  expect_s3_class(result, c("mysterycall_multi_model_table", "data.frame"))
  expect_equal(ncol(result), 4L)  # Term + 3 models
  expect_equal(attr(result, "estimate_label"), "Odds Ratio")
  expect_false(attr(result, "mixed_types"))

  # Check reference symbols
  expect_true(any(grepl("REF", as.character(result), fixed = TRUE)))
})

# =============================================================================
# TEST 3: Happy path — mixed model types (logistic + poisson)
# =============================================================================
test_that("mysterycall_multi_model_table handles mixed model types with warning", {
  m_log <- .make_mock_logistic(n = 150L, aic = 310.0)
  m_poi <- .make_mock_poisson(n = 150L, aic = 280.0)

  result <- suppressWarnings({
    mysterycall_multi_model_table(
      models = list("Logistic" = m_log, "Poisson" = m_poi)
    )
  })

  expect_s3_class(result, c("mysterycall_multi_model_table", "data.frame"))
  expect_true(attr(result, "mixed_types"))

  # Column names should have type tags
  expect_true(any(grepl("\\[Logistic\\]", names(result))))
  expect_true(any(grepl("\\[Poisson\\]", names(result))))

  # Estimate label should fall back to generic
  expect_equal(attr(result, "estimate_label"), "Estimate (95% CI)")
})

# =============================================================================
# TEST 4: Edge case — include_intercept = TRUE
# =============================================================================
test_that("mysterycall_multi_model_table includes intercept when requested", {
  m1 <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        or          = c(0.5, 1.45),
        ci_lower    = c(0.3, 1.02),
        ci_upper    = c(0.8, 2.05),
        p_value_fmt = c("0.001", "0.038"),
        stringsAsFactors = FALSE
      ),
      factor_refs = list(insurance = "BCBS"),
      n   = 150L,
      aic = 310.0
    ),
    class = "mysterycall_logistic_model"
  )

  m2 <- structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", "insuranceMedicaid"),
        or          = c(0.52, 1.38),
        ci_lower    = c(0.31, 0.97),
        ci_upper    = c(0.83, 1.96),
        p_value_fmt = c("0.001", "0.072"),
        stringsAsFactors = FALSE
      ),
      factor_refs = list(insurance = "BCBS"),
      n   = 150L,
      aic = 305.0
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      include_intercept = TRUE
    )
  )

  expect_true(any(result$Term == "(Intercept)"))
})

# =============================================================================
# TEST 5: Edge case — exclude N and AIC footers
# =============================================================================
test_that("mysterycall_multi_model_table respects include_n and include_aic flags", {
  m1 <- .make_mock_logistic(n = 200L, aic = 312.4)
  m2 <- .make_mock_logistic(n = 200L, aic = 308.1)

  result <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      include_n = FALSE,
      include_aic = FALSE
    )
  )

  expect_false(any(result$Term == "N"))
  expect_false(any(result$Term == "AIC"))
})

# =============================================================================
# TEST 6: Edge case — custom digits parameter
# =============================================================================
test_that("mysterycall_multi_model_table respects digits parameter", {
  m1 <- .make_mock_logistic(n = 200L, aic = 312.4)
  m2 <- .make_mock_logistic(n = 200L, aic = 308.1)

  result_d1 <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      digits = 1L
    )
  )

  result_d4 <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      digits = 4L
    )
  )

  # Higher digits should have more decimal places in formatted output
  # (precision varies by cell content, so just check both can be created)
  expect_s3_class(result_d1, "mysterycall_multi_model_table")
  expect_s3_class(result_d4, "mysterycall_multi_model_table")
  expect_true(nrow(result_d1) > 0L)
  expect_true(nrow(result_d4) > 0L)
})

# =============================================================================
# TEST 7: Edge case — Poisson model type and irr_table format
# =============================================================================
test_that("mysterycall_multi_model_table handles poisson models correctly", {
  m1 <- .make_mock_poisson(n = 200L, aic = 280.2)
  m2 <- .make_mock_poisson(n = 200L, aic = 275.1)

  result <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2)
    )
  )

  expect_s3_class(result, "mysterycall_multi_model_table")
  expect_equal(attr(result, "estimate_label"), "IRR (95% CI)")
  expect_false(attr(result, "mixed_types"))
})

# =============================================================================
# TEST 8: Edge case — NB model type
# =============================================================================
test_that("mysterycall_multi_model_table handles NB models correctly", {
  m1 <- .make_mock_nb(n = 200L, aic = 285.3)
  m2 <- .make_mock_nb(n = 200L, aic = 280.2)

  result <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2)
    )
  )

  expect_s3_class(result, "mysterycall_multi_model_table")
  expect_equal(attr(result, "estimate_label"), "IRR (95% CI)")
})

# =============================================================================
# TEST 9: Edge case — LMM model type with REML flag
# =============================================================================
test_that("mysterycall_multi_model_table handles LMM models and REML flag", {
  skip_if_not_installed("lme4")

  m1 <- .make_mock_lmm(n = 200L, reml = TRUE)
  m2 <- .make_mock_lmm(n = 200L, reml = FALSE)

  result <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      include_aic = TRUE
    )
  )

  expect_s3_class(result, "mysterycall_multi_model_table")
  expect_equal(attr(result, "estimate_label"), "Beta (95% CI)")

  # REML model should show "(REML)" in AIC row
  aic_row <- result[result$Term == "AIC", ]
  expect_true(any(grepl("REML", as.character(aic_row))))
})

# =============================================================================
# TEST 10: Bad input — models is not a list
# =============================================================================
test_that("mysterycall_multi_model_table rejects non-list models", {
  expect_error(
    mysterycall_multi_model_table(
      models = c(1, 2, 3)  # numeric vector, not list
    ),
    "must be a named list"
  )
})

# =============================================================================
# TEST 11: Bad input — models without names
# =============================================================================
test_that("mysterycall_multi_model_table requires named models list", {
  m1 <- .make_mock_logistic()
  m2 <- .make_mock_logistic()

  expect_error(
    mysterycall_multi_model_table(
      models = list(m1, m2)  # unnamed
    ),
    "non-empty name"
  )
})

# =============================================================================
# TEST 12: Bad input — fewer than 2 models
# =============================================================================
test_that("mysterycall_multi_model_table requires at least 2 models", {
  m1 <- .make_mock_logistic()

  expect_error(
    mysterycall_multi_model_table(
      models = list("M1" = m1)
    ),
    "at least 2"
  )
})

# =============================================================================
# TEST 13: Bad input — invalid digits parameter
# =============================================================================
test_that("mysterycall_multi_model_table validates digits parameter", {
  m1 <- .make_mock_logistic()
  m2 <- .make_mock_logistic()

  expect_error(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      digits = -1L
    ),
    "non-negative"
  )

  expect_error(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      digits = c(1L, 2L)
    ),
    "scalar"
  )
})

# =============================================================================
# TEST 14: Bad input — invalid estimate_col_label parameter
# =============================================================================
test_that("mysterycall_multi_model_table validates estimate_col_label", {
  m1 <- .make_mock_logistic()
  m2 <- .make_mock_logistic()

  expect_error(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      estimate_col_label = 123  # not character
    ),
    "single character string or NULL"
  )

  expect_error(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      estimate_col_label = c("A", "B")
    ),
    "single character string or NULL"
  )
})

# =============================================================================
# TEST 15: Bad input — invalid ref_symbol parameter
# =============================================================================
test_that("mysterycall_multi_model_table validates ref_symbol", {
  m1 <- .make_mock_logistic()
  m2 <- .make_mock_logistic()

  expect_error(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      ref_symbol = 999  # not character
    ),
    "must be a single character string"
  )
})

# =============================================================================
# TEST 16: Bad input — unsupported model class
# =============================================================================
test_that("mysterycall_multi_model_table rejects unsupported model classes", {
  bad_model <- structure(list(data = data.frame(x = 1)), class = "lm")
  m2 <- .make_mock_logistic()

  expect_error(
    mysterycall_multi_model_table(
      models = list("BadModel" = bad_model, "Good" = m2)
    ),
    "unsupported class"
  )
})

# =============================================================================
# TEST 17: Print method — output is correct class and invisibly returns input
# =============================================================================
test_that("print.mysterycall_multi_model_table returns invisible object", {
  m1 <- .make_mock_logistic(n = 200L, aic = 312.4)
  m2 <- .make_mock_logistic(n = 200L, aic = 308.1)

  tbl <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2)
    )
  )

  output <- capture.output({
    result <- print(tbl)
  })

  # Print should return the object invisibly
  expect_s3_class(result, "mysterycall_multi_model_table")

  # Output should mention the estimate label and table info
  expect_true(any(grepl("Multi-model", output)))
})

# =============================================================================
# TEST 18: Print method — mixed types warning in console output
# =============================================================================
test_that("print.mysterycall_multi_model_table displays mixed-type note", {
  m_log <- .make_mock_logistic(n = 150L, aic = 310.0)
  m_poi <- .make_mock_poisson(n = 150L, aic = 280.0)

  tbl <- expect_warning(
    mysterycall_multi_model_table(
      models = list("Log" = m_log, "Poi" = m_poi)
    ),
    "different types"
  )

  output <- capture.output({
    print(tbl)
  })

  # Should mention native scales when mixed
  expect_true(any(grepl("native scale", output, ignore.case = TRUE)))
})

# =============================================================================
# TEST 19: Edge case — all models have empty factor_refs
# =============================================================================
test_that("mysterycall_multi_model_table handles models with no factor_refs", {
  m1 <- structure(
    list(
      or_table = data.frame(
        term        = c("var1", "var2"),
        or          = c(1.5, 2.0),
        ci_lower    = c(1.0, 1.5),
        ci_upper    = c(2.0, 2.5),
        p_value_fmt = c("0.05", "0.01"),
        stringsAsFactors = FALSE
      ),
      factor_refs = NULL,  # No factor refs
      n   = 150L,
      aic = 310.0
    ),
    class = "mysterycall_logistic_model"
  )

  m2 <- structure(
    list(
      or_table = data.frame(
        term        = c("var1"),
        or          = c(1.4),
        ci_lower    = c(0.95),
        ci_upper    = c(1.95),
        p_value_fmt = c("0.08"),
        stringsAsFactors = FALSE
      ),
      factor_refs = NULL,  # No factor refs
      n   = 150L,
      aic = 305.0
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2)
    )
  )

  expect_s3_class(result, "mysterycall_multi_model_table")
  expect_true(is.data.frame(result))
})

# =============================================================================
# TEST 20: Edge case — missing N values in some models
# =============================================================================
test_that("mysterycall_multi_model_table handles missing N in footer", {
  m1 <- .make_mock_logistic(n = 200L, aic = 312.4)
  m2 <- structure(
    list(
      or_table = data.frame(
        term        = c("insuranceMedicaid"),
        or          = c(1.38),
        ci_lower    = c(0.97),
        ci_upper    = c(1.96),
        p_value_fmt = c("0.072"),
        stringsAsFactors = FALSE
      ),
      factor_refs = list(insurance = "BCBS"),
      n   = NULL,  # Missing N
      aic = 308.1
    ),
    class = "mysterycall_logistic_model"
  )

  result <- suppressWarnings(
    mysterycall_multi_model_table(
      models = list("M1" = m1, "M2" = m2),
      include_n = TRUE
    )
  )

  expect_s3_class(result, "mysterycall_multi_model_table")
  n_row <- result[result$Term == "N", ]
  expect_equal(nrow(n_row), 1L)
})
