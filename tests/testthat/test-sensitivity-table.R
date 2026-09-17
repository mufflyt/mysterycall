# testthat 3rd edition
# Tests for mysterycall_sensitivity_table()
# All fake model objects built with structure() — no lme4 / real fitting needed.

# ── shared helpers ────────────────────────────────────────────────────────────

.fake_logistic <- function(term      = "insuranceMedicaid",
                            or        = 0.62,
                            ci_lower  = 0.40,
                            ci_upper  = 0.97,
                            p_value   = 0.036,
                            p_value_fmt = "0.036",
                            n         = 160L,
                            aic       = 210.4) {
  structure(
    list(
      or_table = data.frame(
        term        = c("(Intercept)", term),
        or          = c(3.50,          or),
        ci_lower    = c(2.10,          ci_lower),
        ci_upper    = c(5.80,          ci_upper),
        p_value     = c(0.0001,        p_value),
        p_value_fmt = c("< 0.001",     p_value_fmt),
        stringsAsFactors = FALSE
      ),
      n   = n,
      aic = aic
    ),
    class = "mysterycall_logistic_model"
  )
}

.fake_poisson <- function(term        = "insuranceMedicaid",
                           irr         = 1.41,
                           ci_lower    = 1.08,
                           ci_upper    = 1.84,
                           p_value     = 0.012,
                           p_value_fmt = "0.012",
                           n           = 145L,
                           aic         = 893.6) {
  structure(
    list(
      irr_table = data.frame(
        term        = c("(Intercept)", term),
        irr         = c(18.3,          irr),
        ci_lower    = c(14.1,          ci_lower),
        ci_upper    = c(23.7,          ci_upper),
        p_value     = c(0.0001,        p_value),
        p_value_fmt = c("< 0.001",     p_value_fmt),
        stringsAsFactors = FALSE
      ),
      n   = n,
      aic = aic
    ),
    class = "mysterycall_poisson_model"
  )
}

.fake_lmm <- function(term        = "insuranceMedicaid",
                       estimate    = -3.2,
                       ci_lower    = -5.8,
                       ci_upper    = -0.6,
                       p_value     = 0.016,
                       p_value_fmt = "0.016",
                       n           = 200L,
                       aic         = 1045.3) {
  structure(
    list(
      coef_table = data.frame(
        term        = c("(Intercept)", term),
        estimate    = c(12.1,          estimate),
        ci_lower    = c(9.5,           ci_lower),
        ci_upper    = c(14.7,          ci_upper),
        p_value     = c(0.0001,        p_value),
        p_value_fmt = c("< 0.001",     p_value_fmt),
        stringsAsFactors = FALSE
      ),
      n   = n,
      aic = aic
    ),
    class = "mysterycall_lmm"
  )
}

# ── 1. Returns a data.frame ───────────────────────────────────────────────────

test_that("returns a data.frame", {
  m1 <- .fake_logistic()
  out <- mysterycall_sensitivity_table(
    models        = list(Unadjusted = m1),
    exposure_term = "insuranceMedicaid"
  )
  expect_s3_class(out, "data.frame")
})

# ── 2. Column names match the model names ─────────────────────────────────────

test_that("column names equal Characteristic plus supplied model names", {
  m1 <- .fake_logistic()
  m2 <- .fake_logistic(or = 0.65, aic = 208.1)
  out <- mysterycall_sensitivity_table(
    models        = list("Model 1" = m1, "Model 2" = m2),
    exposure_term = "insuranceMedicaid"
  )
  expect_equal(colnames(out), c("Characteristic", "Model 1", "Model 2"))
})

# ── 3. Characteristic column is present ──────────────────────────────────────

test_that("Characteristic column is always present", {
  out <- mysterycall_sensitivity_table(
    models        = list(A = .fake_logistic()),
    exposure_term = "insuranceMedicaid"
  )
  expect_true("Characteristic" %in% colnames(out))
})

# ── 4. Exposure-term row appears in Characteristic ───────────────────────────

test_that("exposure_term label appears as a row in Characteristic", {
  out <- mysterycall_sensitivity_table(
    models        = list(A = .fake_logistic()),
    exposure_term = "insuranceMedicaid"
  )
  expect_true(any(grepl("insuranceMedicaid", out$Characteristic)))
})

# ── 5. Sample-size row present when include_n = TRUE (default) ───────────────

test_that("Sample size row present when include_n = TRUE", {
  out <- mysterycall_sensitivity_table(
    models        = list(A = .fake_logistic()),
    exposure_term = "insuranceMedicaid",
    include_n     = TRUE
  )
  expect_true(any(out$Characteristic == "Sample size"))
})

# ── 6. Sample-size row absent when include_n = FALSE ─────────────────────────

test_that("Sample size row absent when include_n = FALSE", {
  out <- mysterycall_sensitivity_table(
    models        = list(A = .fake_logistic()),
    exposure_term = "insuranceMedicaid",
    include_n     = FALSE
  )
  expect_false(any(out$Characteristic == "Sample size"))
})

# ── 7. AIC row present when include_aic = TRUE (default) ─────────────────────

test_that("AIC row present when include_aic = TRUE", {
  out <- mysterycall_sensitivity_table(
    models        = list(A = .fake_logistic()),
    exposure_term = "insuranceMedicaid",
    include_aic   = TRUE
  )
  expect_true(any(out$Characteristic == "AIC"))
})

# ── 8. AIC row absent when include_aic = FALSE ───────────────────────────────

test_that("AIC row absent when include_aic = FALSE", {
  out <- mysterycall_sensitivity_table(
    models        = list(A = .fake_logistic()),
    exposure_term = "insuranceMedicaid",
    include_aic   = FALSE
  )
  expect_false(any(out$Characteristic == "AIC"))
})

# ── 9. Error on unnamed list ──────────────────────────────────────────────────

test_that("error when models is an unnamed list", {
  expect_error(
    mysterycall_sensitivity_table(
      models        = list(.fake_logistic()),   # no names
      exposure_term = "insuranceMedicaid"
    ),
    regexp = "named list"
  )
})

# ── 10. Error when models contains an unsupported class ──────────────────────

test_that("error when a model has an unsupported class", {
  bad <- structure(list(or_table = data.frame(), n = 10L, aic = 99),
                   class = "some_random_class")
  expect_error(
    mysterycall_sensitivity_table(
      models        = list(Bad = bad),
      exposure_term = "insuranceMedicaid"
    ),
    regexp = "unsupported class|mysterycall_logistic_model"
  )
})

# ── 11. Missing term produces em-dash, not an error ──────────────────────────

test_that("exposure_term absent from all models yields em-dash cells, not an error", {
  m1 <- .fake_logistic()   # contains "insuranceMedicaid", not "scenarioB"
  out <- mysterycall_sensitivity_table(
    models        = list(A = m1),
    exposure_term = "scenarioB",
    include_n     = FALSE,
    include_aic   = FALSE
  )
  # Only one row: the exposure row
  expect_equal(nrow(out), 1L)
  expect_equal(out[["A"]][[1L]], "—")   # em-dash U+2014
})

# ── 12. Cell format contains parenthetical CI ────────────────────────────────

test_that("exposure cell follows '<est> (<lo> to <hi>), p=<p>' pattern", {
  m1 <- .fake_logistic(
    or          = 0.62,
    ci_lower    = 0.40,
    ci_upper    = 0.97,
    p_value_fmt = "0.036"
  )
  out <- mysterycall_sensitivity_table(
    models        = list(A = m1),
    exposure_term = "insuranceMedicaid",
    include_n     = FALSE,
    include_aic   = FALSE
  )
  cell <- out[["A"]][[1L]]
  # Must match:  est (lo to hi), p=   -- SAMPL asks for "to" between the
  # endpoints so a negative lower bound cannot be read as a minus sign.
  expect_match(cell, "\\(.* to .*\\),\\s*p=", perl = TRUE)
  expect_false(grepl("–", cell, fixed = TRUE))
})
