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

test_that("mysterycall_r2_sentence returns list with expected structure and class", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")

  set.seed(226)
  data <- data.frame(
    y = c(rnorm(50, 10, 2), rnorm(50, 12, 2)),
    x = rep(c(0, 1), each = 50),
    group = rep(1:10, each = 10)
  )

  mod <- suppressMessages(lme4::lmer(y ~ x + (1 | group), data = data))
  res <- suppressMessages(mysterycall_r2_sentence(mod))

  expect_type(res, "list")
  expect_named(res, c("marginal_r2", "conditional_r2", "fixed_effects", "random_effects", "sentence"))
  expect_type(res$marginal_r2, "double")
  expect_type(res$conditional_r2, "double")
  expect_type(res$fixed_effects, "character")
  expect_type(res$random_effects, "character")
  expect_type(res$sentence, "character")
})

test_that("mysterycall_r2_sentence returns valid R² values in [0,1]", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")

  set.seed(227)
  data <- data.frame(
    y = c(rnorm(100, 10, 1), rnorm(100, 12, 1)),
    x = rep(c(0, 1), each = 100),
    group = rep(1:20, each = 10)
  )

  mod <- suppressMessages(lme4::lmer(y ~ x + (1 | group), data = data))
  res <- suppressMessages(mysterycall_r2_sentence(mod))

  expect_true(res$marginal_r2 >= 0 && res$marginal_r2 <= 1)
  # conditional_r2 may be NA if random effect variances cannot be computed
  if (!is.na(res$conditional_r2)) {
    expect_true(res$conditional_r2 >= 0 && res$conditional_r2 <= 1)
    expect_true(res$conditional_r2 >= res$marginal_r2)
  }
})

test_that("mysterycall_r2_sentence respects digits and digits_pct parameters", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")

  set.seed(228)
  data <- data.frame(
    y = c(rnorm(50, 10, 2), rnorm(50, 12, 2)),
    x = rep(c(0, 1), each = 50),
    group = rep(1:10, each = 10)
  )

  mod <- suppressMessages(lme4::lmer(y ~ x + (1 | group), data = data))

  # Test with digits = 2 and digits_pct = 0
  res_short <- suppressMessages(mysterycall_r2_sentence(mod, digits = 2, digits_pct = 0))
  expect_type(res_short$sentence, "character")
  expect_true(nchar(res_short$sentence) > 0)

  # Test with digits = 5 and digits_pct = 3
  res_long <- suppressMessages(mysterycall_r2_sentence(mod, digits = 5, digits_pct = 3))
  expect_type(res_long$sentence, "character")
  expect_true(nchar(res_long$sentence) > nchar(res_short$sentence))
})

test_that("mysterycall_r2_sentence errors on fixed-effects-only lm model", {
  skip_if_not_installed("lme4")

  set.seed(229)
  data <- data.frame(
    y = c(rnorm(50, 10, 2), rnorm(50, 12, 2)),
    x = rep(c(0, 1), each = 50)
  )

  mod_lm <- lm(y ~ x, data = data)

  expect_error(
    mysterycall_r2_sentence(mod_lm),
    "must be a fitted mixed model"
  )
})

test_that("mysterycall_r2_sentence errors on invalid object types", {
  skip_if_not_installed("lme4")

  # Pass a data frame instead of a model
  expect_error(
    mysterycall_r2_sentence(data.frame(x = 1:10, y = 1:10)),
    "must be a fitted mixed model"
  )

  # Pass a list
  expect_error(
    mysterycall_r2_sentence(list(a = 1, b = 2)),
    "must be a fitted mixed model"
  )

  # Pass a numeric vector
  expect_error(
    mysterycall_r2_sentence(c(1, 2, 3)),
    "must be a fitted mixed model"
  )
})

test_that("mysterycall_r2_sentence sentence contains expected interpretive text", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")

  set.seed(230)
  data <- data.frame(
    y = c(rnorm(50, 10, 2), rnorm(50, 12, 2)),
    x = rep(c(0, 1), each = 50),
    group = rep(1:10, each = 10)
  )

  mod <- suppressMessages(lme4::lmer(y ~ x + (1 | group), data = data))
  res <- suppressMessages(mysterycall_r2_sentence(mod))

  expect_true(grepl("marginal R²", res$sentence))
  expect_true(grepl("conditional R²", res$sentence))
  expect_true(grepl("fixed effects", res$sentence))
  expect_true(grepl("random effects", res$sentence))
  expect_true(grepl("%", res$sentence))
  expect_true(grepl("variance explained", res$sentence))
})
