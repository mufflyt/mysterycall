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

# Helper functions for creating mock model objects
.make_fake_poisson <- function(aic = 120, bic = 125, phi = 1.3, n_obs = 100L) {
  structure(
    list(
      irr_table      = data.frame(term = c("(Intercept)", "insuranceMedicaid"),
                                   irr = c(1.00, 1.28),
                                   ci_lower = c(NA, 1.05),
                                   ci_upper = c(NA, 1.56),
                                   p_value = c(NA, 0.014)),
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

.make_fake_nb <- function(aic = 118, bic = 124, phi = 2.8, theta = 1.5, n_obs = 100L) {
  structure(
    list(
      irr_table      = data.frame(term = c("(Intercept)", "insuranceMedicaid"),
                                   irr = c(1.00, 1.32),
                                   ci_lower = c(NA, 1.08),
                                   ci_upper = c(NA, 1.62),
                                   p_value = c(NA, 0.008)),
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

test_that("mysterycall_model_comparison_table: happy path returns correct structure", {
  set.seed(211)
  models <- list(
    "Poisson Base" = .make_fake_poisson(aic = 125, bic = 130),
    "NB Extended"  = .make_fake_nb(aic = 118, bic = 124)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_named(result, c("Model", "Family", "N", "Params", "AIC", "BIC",
                         "Phi (Pearson)", "Theta", "DeltaAIC", "DeltaBIC", "Winner"))
  expect_true(any(result$Winner == "*"))
  expect_equal(sum(result$Winner == "*"), 1L)
  expect_true("winner" %in% names(attributes(result)))
})

test_that("mysterycall_model_comparison_table: criterion='aic' selects by AIC", {
  set.seed(212)
  models <- list(
    "Model A" = .make_fake_poisson(aic = 150, bic = 155),
    "Model B" = .make_fake_nb(aic = 120, bic = 125)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models, criterion = "aic")
  ))

  expect_equal(result$Winner[result$Model == "Model B"], "*")
  expect_equal(result$Winner[result$Model == "Model A"], "")
  expect_equal(attr(result, "winner"), "Model B")
})

test_that("mysterycall_model_comparison_table: criterion='bic' selects by BIC", {
  set.seed(213)
  models <- list(
    "Model X" = .make_fake_poisson(aic = 120, bic = 150),
    "Model Y" = .make_fake_nb(aic = 125, bic = 130)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models, criterion = "bic")
  ))

  expect_equal(result$Winner[result$Model == "Model Y"], "*")
  expect_equal(attr(result, "winner"), "Model Y")
})

test_that("mysterycall_model_comparison_table: digits parameter controls formatting", {
  set.seed(214)
  models <- list(
    "M1" = .make_fake_poisson(aic = 123.456, bic = 128.789, phi = 1.234),
    "M2" = .make_fake_nb(aic = 118.901, bic = 124.567, phi = 2.345, theta = 1.567)
  )

  result_1 <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models, digits = 1L)
  ))
  result_3 <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models, digits = 3L)
  ))

  expect_type(result_1$AIC, "character")
  expect_type(result_3$AIC, "character")
  expect_match(result_1$AIC[1], "^\\d+\\.\\d$|^\\d+\\.$|^\\d+$")
})

test_that("mysterycall_model_comparison_table: handles 3+ models", {
  set.seed(215)
  models <- list(
    "M1" = .make_fake_poisson(aic = 140, bic = 145),
    "M2" = .make_fake_nb(aic = 120, bic = 125),
    "M3" = .make_fake_poisson(aic = 130, bic = 135, phi = 1.5)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models)
  ))

  expect_equal(nrow(result), 3L)
  expect_equal(sum(result$Winner == "*"), 1L)
})

test_that("mysterycall_model_comparison_table: error on unnamed list", {
  set.seed(216)
  models <- list(
    .make_fake_poisson(aic = 125),
    .make_fake_nb(aic = 120)
  )

  expect_error(
    mysterycall_model_comparison_table(models),
    "named list"
  )
})

test_that("mysterycall_model_comparison_table: error on insufficient models", {
  set.seed(217)
  models <- list("Only One" = .make_fake_poisson(aic = 125))

  expect_error(
    mysterycall_model_comparison_table(models),
    "at least 2"
  )
})

test_that("mysterycall_model_comparison_table: error on wrong model class", {
  set.seed(218)
  bad_model <- list(aic = 120, bic = 125)
  class(bad_model) <- "wrong_class"

  models <- list(
    "Good" = .make_fake_poisson(aic = 125),
    "Bad"  = bad_model
  )

  expect_error(
    mysterycall_model_comparison_table(models),
    "mysterycall_poisson_model|mysterycall_nb_model"
  )
})

test_that("mysterycall_model_comparison_table: computes DeltaAIC correctly", {
  set.seed(219)
  models <- list(
    "M1" = .make_fake_poisson(aic = 140, bic = 145),
    "M2" = .make_fake_nb(aic = 120, bic = 125)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models)
  ))

  m2_idx <- which(result$Model == "M2")
  m1_idx <- which(result$Model == "M1")
  expect_equal(as.numeric(result$DeltaAIC[m2_idx]), 0, tolerance = 0.01)
  expect_true(as.numeric(result$DeltaAIC[m1_idx]) > 0)
})

test_that("print.mysterycall_model_comparison_table: outputs with winner header", {
  set.seed(220)
  models <- list(
    "M1" = .make_fake_poisson(aic = 130),
    "M2" = .make_fake_nb(aic = 120)
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_model_comparison_table(models)
  ))
  class(result) <- c("mysterycall_model_comparison_table", class(result))

  out <- capture.output(suppressMessages(print(result)))
  expect_true(length(out) > 0)
  expect_true(any(grepl("Model comparison", out)))
})
