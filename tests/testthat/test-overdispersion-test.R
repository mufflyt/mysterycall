# test-overdispersion-test.R
# testthat 3rd edition — mysterycall_overdispersion_test()

# ---- helpers -----------------------------------------------------------------

# Standard Poisson GLM: phi expected near 1
make_fit_standard <- function() {
  set.seed(42)
  n <- 100L
  dat <- data.frame(y = rpois(n, lambda = 3), x = rnorm(n))
  stats::glm(y ~ x, family = "poisson", data = dat)
}

# Underdispersed: constant response forces all residuals ≈ 0, so phi << 1
make_fit_under <- function() {
  dat <- data.frame(y = rep(3L, 50L), x = seq_len(50L))
  stats::glm(y ~ x, family = "poisson", data = dat)
}

# Severely overdispersed: bimodal counts (0 vs 50) that x cannot explain
# phi = sum((y - mu)^2 / mu) / df ≈ (50*25 + 50*25) / 98 ≈ 25.5
make_fit_severe <- function() {
  set.seed(7)
  dat <- data.frame(
    y = c(rep(0L, 50L), rep(50L, 50L)),
    x = rnorm(100L)
  )
  stats::glm(y ~ x, family = "poisson", data = dat)
}

# ---- 1. class ----------------------------------------------------------------

test_that("returns list of class mysterycall_overdispersion_test", {
  result <- mysterycall_overdispersion_test(make_fit_standard())
  expect_s3_class(result, "mysterycall_overdispersion_test")
  expect_type(result, "list")
})

# ---- 2. phi ------------------------------------------------------------------

test_that("phi is numeric and positive", {
  result <- mysterycall_overdispersion_test(make_fit_standard())
  expect_true(is.numeric(result$phi))
  expect_length(result$phi, 1L)
  expect_gt(result$phi, 0)
})

# ---- 3. pearson_chisq --------------------------------------------------------

test_that("pearson_chisq is numeric and positive", {
  result <- mysterycall_overdispersion_test(make_fit_standard())
  expect_true(is.numeric(result$pearson_chisq))
  expect_length(result$pearson_chisq, 1L)
  expect_gt(result$pearson_chisq, 0)
})

# ---- 4. df -------------------------------------------------------------------

test_that("df is integer", {
  result <- mysterycall_overdispersion_test(make_fit_standard())
  expect_true(is.integer(result$df))
  expect_length(result$df, 1L)
  expect_gt(result$df, 0L)
})

# ---- 5. p_value --------------------------------------------------------------

test_that("p_value is in [0, 1]", {
  result <- mysterycall_overdispersion_test(make_fit_standard())
  expect_true(is.numeric(result$p_value))
  expect_gte(result$p_value, 0)
  expect_lte(result$p_value, 1)
})

# ---- 6. sentence contains "phi" ----------------------------------------------

test_that("sentence is character and contains the string 'phi'", {
  result <- mysterycall_overdispersion_test(make_fit_standard())
  expect_type(result$sentence, "character")
  expect_length(result$sentence, 1L)
  expect_true(grepl("phi", result$sentence, fixed = TRUE))
})

# ---- 7. interpretation -------------------------------------------------------

test_that("interpretation is a non-empty character string", {
  result <- mysterycall_overdispersion_test(make_fit_standard())
  expect_type(result$interpretation, "character")
  expect_length(result$interpretation, 1L)
  expect_gt(nchar(result$interpretation), 0L)
})

# ---- 8. recommendation -------------------------------------------------------

test_that("recommendation is a non-empty character string", {
  result <- mysterycall_overdispersion_test(make_fit_standard())
  expect_type(result$recommendation, "character")
  expect_length(result$recommendation, 1L)
  expect_gt(nchar(result$recommendation), 0L)
})

# ---- 9. underdispersion ------------------------------------------------------

test_that("phi < 1 produces underdispersion category and interpretation", {
  result <- mysterycall_overdispersion_test(make_fit_under())
  expect_lt(result$phi, 1)
  expect_equal(result$category, "underdispersion")
  expect_true(grepl("nderdispersion", result$interpretation))
})

# ---- 10. severe --------------------------------------------------------------

test_that("phi >= 2.0 produces severe category and interpretation", {
  result <- mysterycall_overdispersion_test(make_fit_severe())
  expect_gte(result$phi, 2.0)
  expect_equal(result$category, "severe")
  expect_true(grepl("evere", result$interpretation, ignore.case = TRUE))
})

# ---- 11. works with stats::glm (no lme4) ------------------------------------

test_that("works with stats::glm without lme4", {
  fit <- make_fit_standard()
  expect_s3_class(fit, "glm")
  result <- mysterycall_overdispersion_test(fit)
  expect_s3_class(result, "mysterycall_overdispersion_test")
  # phi * df must equal pearson_chisq (definition check)
  expect_equal(result$pearson_chisq, result$phi * result$df, tolerance = 1e-6)
})

# ---- 12. works with glmerMod (lme4) -----------------------------------------

test_that("works with glmerMod when lme4 is installed", {
  skip_if_not_installed("lme4")
  set.seed(99)
  dat <- data.frame(
    y   = rpois(100L, lambda = 2),
    x   = rnorm(100L),
    grp = factor(rep(seq_len(10L), each = 10L))
  )
  fit_me <- lme4::glmer(y ~ x + (1 | grp), data = dat, family = poisson())
  result <- mysterycall_overdispersion_test(fit_me)
  expect_s3_class(result, "mysterycall_overdispersion_test")
  expect_true(is.numeric(result$phi) && is.finite(result$phi))
  expect_gte(result$p_value, 0)
  expect_lte(result$p_value, 1)
})

# ---- 13. print method --------------------------------------------------------

test_that("print method returns the object invisibly and writes sentence to console", {
  result <- mysterycall_overdispersion_test(make_fit_standard())
  output <- capture.output(ret <- print(result))
  expect_identical(ret, result)
  expect_gte(length(output), 1L)
  expect_true(any(grepl("phi", output, fixed = TRUE)))
})

# ---- 14. digits parameter ----------------------------------------------------

test_that("digits parameter controls decimal precision in sentence", {
  fit <- make_fit_standard()
  r2  <- mysterycall_overdispersion_test(fit, digits = 2L)
  r5  <- mysterycall_overdispersion_test(fit, digits = 5L)
  phi <- r2$phi  # identical underlying value

  # The phi_fmt embedded in each sentence must match the requested precision
  expect_true(grepl(sprintf("%.2f", phi), r2$sentence, fixed = TRUE))
  expect_true(grepl(sprintf("%.5f", phi), r5$sentence, fixed = TRUE))

  # The two sentences must differ (phi is not zero to five decimal places)
  expect_false(identical(r2$sentence, r5$sentence))
})
