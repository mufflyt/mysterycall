test_that("r2_sentence errors on non-model objects", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  expect_error(
    mysterycall_r2_sentence(list(a = 1)),
    "mixed model"
  )
  expect_error(
    mysterycall_r2_sentence("not a model"),
    "mixed model"
  )
  expect_error(
    mysterycall_r2_sentence(42),
    "mixed model"
  )
})

test_that("r2_sentence errors on a pure fixed-effects lm", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  m_lm <- lm(mpg ~ wt, data = mtcars)
  expect_error(mysterycall_r2_sentence(m_lm), "mixed model")
})

test_that("r2_sentence returns correct list structure for lmerMod", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_r2_sentence(m)
  expect_named(res, c("marginal_r2", "conditional_r2", "fixed_effects",
                       "random_effects", "sentence"))
})

test_that("r2_sentence marginal <= conditional R2", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_r2_sentence(m)
  expect_true(res$marginal_r2 <= res$conditional_r2)
})

test_that("r2_sentence R2 values are between 0 and 1", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_r2_sentence(m)
  expect_true(res$marginal_r2 >= 0 && res$marginal_r2 <= 1)
  expect_true(res$conditional_r2 >= 0 && res$conditional_r2 <= 1)
})

test_that("r2_sentence fixed_effects includes (Intercept) and Days", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_r2_sentence(m)
  expect_true("Days" %in% res$fixed_effects)
})

test_that("r2_sentence random_effects includes Subject", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_r2_sentence(m)
  expect_true("Subject" %in% res$random_effects)
})

test_that("r2_sentence sentence contains marginal and conditional R2 values", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_r2_sentence(m)
  expect_match(res$sentence, as.character(round(res$marginal_r2, 3)), fixed = TRUE)
  expect_match(res$sentence, as.character(round(res$conditional_r2, 3)), fixed = TRUE)
})

test_that("r2_sentence sentence contains percentage values", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res <- mysterycall_r2_sentence(m)
  pct_marginal <- round(res$marginal_r2 * 100, 1)
  expect_match(res$sentence, as.character(pct_marginal), fixed = TRUE)
})

test_that("r2_sentence digits argument affects output precision", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  library(lme4)
  m <- lmer(Reaction ~ Days + (1 | Subject), data = sleepstudy)
  res2 <- mysterycall_r2_sentence(m, digits = 2)
  res4 <- mysterycall_r2_sentence(m, digits = 4)
  expect_match(res2$sentence, as.character(round(res2$marginal_r2, 2)), fixed = TRUE)
  expect_match(res4$sentence, as.character(round(res4$marginal_r2, 4)), fixed = TRUE)
})

test_that("r2_sentence works with glmerMod (binary outcome)", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("performance")
  library(lme4)
  set.seed(1)
  df <- data.frame(
    y    = rbinom(200, 1, 0.5),
    x    = rnorm(200),
    grp  = rep(letters[1:20], 10)
  )
  m <- glmer(y ~ x + (1 | grp), data = df, family = binomial)
  res <- mysterycall_r2_sentence(m)
  expect_true(is.numeric(res$marginal_r2))
  expect_true(is.character(res$sentence))
})
