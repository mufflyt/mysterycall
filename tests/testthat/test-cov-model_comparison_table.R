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

# ── Helper functions to create fake model objects ──────────────────────────

.make_fake_poisson <- function(model_name = "Model1", aic = 120, bic = 125,
                               phi = 1.3, n_obs = 100L, n_params = 3L) {
  irr <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid", "insuranceBCBS"),
    irr      = c(1.00, 1.28, 1.15),
    ci_lower = c(NA,   1.05, 0.92),
    ci_upper = c(NA,   1.56, 1.43),
    p_value  = c(NA,   0.014, 0.22),
    stringsAsFactors = FALSE
  )
  structure(
    list(
      irr_table      = irr,
      overdispersion = phi,
      theta          = NA_real_,
      model          = NULL,
      aic            = aic,
      bic            = bic,
      n_obs          = n_obs,
      n_dropped      = 2L
    ),
    class = "mysterycall_poisson_model"
  )
}

.make_fake_nb <- function(model_name = "Model2", aic = 118, bic = 124,
                          phi = 2.8, theta = 1.5, n_obs = 100L, n_params = 3L) {
  irr <- data.frame(
    term     = c("(Intercept)", "insuranceMedicaid", "insuranceBCBS"),
    irr      = c(1.00, 1.32, 1.18),
    ci_lower = c(NA,   1.08, 0.95),
    ci_upper = c(NA,   1.62, 1.47),
    p_value  = c(NA,   0.008, 0.14),
    stringsAsFactors = FALSE
  )
  structure(
    list(
      irr_table      = irr,
      overdispersion = phi,
      theta          = theta,
      model          = NULL,
      aic            = aic,
      bic            = bic,
      n_obs          = n_obs,
      n_dropped      = 2L
    ),
    class = "mysterycall_nb_model"
  )
}

# ── Test 1: Happy path — correct output with two models ────────────────────

test_that("returns a data.frame with expected columns for two models", {
  set.seed(1)
  models <- list(
    "Poisson" = .make_fake_poisson(aic = 125, bic = 130),
    "NB"      = .make_fake_nb(aic = 118, bic = 124)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models)
  ))

  expect_s3_class(result, "data.frame")
  expect_true(all(c("Model", "Family", "N", "Params", "AIC", "BIC",
                    "DeltaAIC", "DeltaBIC", "Phi (Pearson)", "Theta", "Winner")
                   %in% names(result)))
  expect_equal(nrow(result), 2L)
})

# ── Test 2: Happy path — winner identification by AIC ─────────────────────

test_that("correctly marks the AIC winner with asterisk", {
  set.seed(2)
  models <- list(
    "Model A" = .make_fake_poisson(aic = 150, bic = 155),  # Higher AIC = worse
    "Model B" = .make_fake_nb(aic = 120, bic = 125)        # Lower AIC = better
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models, criterion = "aic")
  ))

  expect_equal(result$Winner[result$Model == "Model B"], "*")
  expect_equal(result$Winner[result$Model == "Model A"], "")
  expect_equal(attr(result, "winner"), "Model B")
})

# ── Test 3: Happy path — winner identification by BIC ──────────────────────

test_that("correctly marks the BIC winner when criterion = 'bic'", {
  set.seed(3)
  models <- list(
    "Model A" = .make_fake_poisson(aic = 120, bic = 150),  # Higher BIC = worse
    "Model B" = .make_fake_nb(aic = 125, bic = 130)        # Lower BIC = better
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models, criterion = "bic")
  ))

  expect_equal(result$Winner[result$Model == "Model B"], "*")
  expect_equal(result$Winner[result$Model == "Model A"], "")
  expect_equal(attr(result, "winner"), "Model B")
})

# ── Test 4: Happy path — numeric formatting with digits parameter ─────────

test_that("formats numeric columns correctly with specified digits", {
  set.seed(4)
  models <- list(
    "M1" = .make_fake_poisson(aic = 123.456, bic = 128.789, phi = 1.234),
    "M2" = .make_fake_nb(aic = 118.901, bic = 124.567, phi = 2.345, theta = 1.567)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models, digits = 2L)
  ))

  # Check that AIC column is formatted as character with 2 decimal places
  expect_type(result$AIC, "character")
  expect_match(result$AIC[1], "^\\d+\\.\\d{2}$")

  # Check that Phi column is also formatted
  expect_type(result$`Phi (Pearson)`, "character")
})

# ── Test 5: Edge case — three or more models ──────────────────────────────

test_that("works with more than two models", {
  set.seed(5)
  models <- list(
    "M1" = .make_fake_poisson(aic = 140, bic = 145),
    "M2" = .make_fake_nb(aic = 120, bic = 125),
    "M3" = .make_fake_poisson(aic = 130, bic = 135, phi = 1.5)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models)
  ))

  expect_equal(nrow(result), 3L)
  expect_equal(sum(result$Winner == "*"), 1L)  # Only one winner
  expect_equal(result$Winner[result$Model == "M2"], "*")
})

# ── Test 6: Error case — unnamed list ──────────────────────────────────────

test_that("errors when models is unnamed list", {
  models <- list(
    .make_fake_poisson(aic = 125),
    .make_fake_nb(aic = 120)
  )

  expect_error(
    mysterycall_model_comparison_table(models),
    regexp = "named list"
  )
})

# ── Test 7: Error case — single model ──────────────────────────────────────

test_that("errors when models has fewer than 2 elements", {
  models <- list("Only" = .make_fake_poisson(aic = 125))

  expect_error(
    mysterycall_model_comparison_table(models),
    regexp = "at least 2"
  )
})

# ── Test 8: Error case — wrong class ──────────────────────────────────────

test_that("errors when model has wrong class", {
  models <- list(
    "Good"  = .make_fake_poisson(aic = 125),
    "Bad"   = list(aic = 120)  # Wrong class
  )

  expect_error(
    mysterycall_model_comparison_table(models),
    regexp = "mysterycall_poisson_model|mysterycall_nb_model"
  )
})

# ── Test 9: Edge case — NA values in metrics ──────────────────────────────

test_that("handles NA values in overdispersion and theta gracefully", {
  set.seed(6)
  models <- list(
    "M1" = structure(
      list(irr_table = data.frame(term = "(Intercept)", irr = 1,
                                   ci_lower = NA_real_, ci_upper = NA_real_,
                                   p_value = NA_real_),
           overdispersion = NA_real_, theta = NA_real_,
           model = NULL, aic = 125, bic = 130, n_obs = 100L, n_dropped = 0L),
      class = "mysterycall_poisson_model"
    ),
    "M2" = .make_fake_nb(aic = 120, bic = 125)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
})

# ── Test 10: DeltaAIC and DeltaBIC computation ────────────────────────────

test_that("correctly computes DeltaAIC and DeltaBIC as differences from best model", {
  set.seed(7)
  models <- list(
    "M1" = .make_fake_poisson(aic = 140, bic = 145),
    "M2" = .make_fake_nb(aic = 120, bic = 125)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models)
  ))

  # M2 has lowest AIC (120) and lowest BIC (125), so deltas should be 0 for M2
  m2_idx <- which(result$Model == "M2")
  expect_equal(as.numeric(result$DeltaAIC[m2_idx]), 0, tolerance = 0.01)
  expect_equal(as.numeric(result$DeltaBIC[m2_idx]), 0, tolerance = 0.01)

  # M1 should have positive deltas
  m1_idx <- which(result$Model == "M1")
  expect_true(as.numeric(result$DeltaAIC[m1_idx]) > 0)
  expect_true(as.numeric(result$DeltaBIC[m1_idx]) > 0)
})
