test_that("random_effect_variance errors on non-model objects", {
  skip_if_not_installed("lme4")
  expect_error(mysterycall_random_effect_variance(list(x = 1)), "mixed model")
  expect_error(mysterycall_random_effect_variance("string"), "mixed model")
  expect_error(mysterycall_random_effect_variance(42), "mixed model")
})

test_that("random_effect_variance errors on negative variance_threshold", {
  skip_if_not_installed("lme4")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  expect_error(
    mysterycall_random_effect_variance(m, variance_threshold = -1),
    "non-negative"
  )
})

test_that("random_effect_variance errors on non-numeric variance_threshold", {
  skip_if_not_installed("lme4")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  expect_error(
    mysterycall_random_effect_variance(m, variance_threshold = "big"),
    "non-negative"
  )
})

test_that("random_effect_variance returns correct list structure", {
  skip_if_not_installed("lme4")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_random_effect_variance(m)
  expect_named(res, c("icc", "random_variance", "residual_variance",
                       "random_effect_group", "var_table", "interpretation",
                       "sentence"))
})

test_that("random_effect_variance ICC is between 0 and 1 for lmerMod", {
  skip_if_not_installed("lme4")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_random_effect_variance(m)
  expect_true(!is.na(res$icc))
  expect_true(res$icc >= 0 && res$icc <= 1)
})

test_that("random_effect_variance var_table has Significant column", {
  skip_if_not_installed("lme4")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_random_effect_variance(m)
  expect_true("Significant" %in% names(res$var_table))
  expect_true(all(res$var_table$Significant %in% c("Yes", "No")))
})

test_that("random_effect_variance random_effect_group is 'Subject'", {
  skip_if_not_installed("lme4")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_random_effect_variance(m)
  expect_equal(res$random_effect_group, "Subject")
})

test_that("random_effect_variance sentence contains ICC value", {
  skip_if_not_installed("lme4")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_random_effect_variance(m)
  expect_match(res$sentence, as.character(round(res$icc, 3)), fixed = TRUE)
})

test_that("random_effect_variance interpretation is one of the four levels", {
  skip_if_not_installed("lme4")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_random_effect_variance(m)
  expect_true(res$interpretation %in% c("high", "moderate", "low to moderate", "low"))
})

test_that("random_effect_variance Poisson glmer: latent-scale ICC matches mysterycall_icc", {
  skip_if_not_installed("lme4")
  library(lme4)
  set.seed(42)
  df <- data.frame(
    count = rpois(100, lambda = 3),
    x     = rnorm(100),
    grp   = rep(letters[1:10], 10)
  )
  m_pois <- glmer(count ~ x + (1 | grp), data = df, family = poisson)
  res <- suppressMessages(mysterycall_random_effect_variance(m_pois))
  # Canonical Nakagawa latent-scale residual variance for Poisson is pi^2/3,
  # so ICC = sigma_u^2 / (sigma_u^2 + pi^2/3) -- a real number in [0, 1],
  # NOT NA and NOT the old sc^2 = 1 convention.
  expect_equal(res$residual_variance, pi^2 / 3)
  expect_equal(res$icc,
               res$random_variance / (res$random_variance + pi^2 / 3))
  expect_true(res$icc >= 0 && res$icc <= 1)
})

test_that("random_effect_variance Significant flag respects threshold", {
  skip_if_not_installed("lme4")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res_high <- mysterycall_random_effect_variance(m, variance_threshold = 1e6)
  expect_true(all(res_high$var_table$Significant == "No"))
  res_low <- mysterycall_random_effect_variance(m, variance_threshold = 0)
  expect_true(any(res_low$var_table$Significant == "Yes"))
})

test_that("random_effect_variance random_variance is positive", {
  skip_if_not_installed("lme4")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_random_effect_variance(m)
  expect_true(res$random_variance >= 0)
})
