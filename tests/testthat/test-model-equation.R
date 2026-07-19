# Tests for mysterycall_model_equation()

test_that("logistic model gives a logit-link equation", {
  set.seed(1)
  d <- data.frame(y = rbinom(200, 1, 0.5), x = rnorm(200))
  fit <- glm(y ~ x, family = binomial, data = d)
  eq <- mysterycall_model_equation(fit)
  expect_type(eq, "character")
  expect_match(eq, "operatorname\\{logit\\}", fixed = FALSE)
  expect_match(eq, "\\beta_0", fixed = TRUE)
  expect_match(eq, "\\beta_{1}", fixed = TRUE)
  expect_true(startsWith(eq, "$$") && endsWith(eq, "$$"))   # wrapped by default
})

test_that("poisson model gives a log-link equation; wrap = FALSE omits $$", {
  set.seed(2)
  d <- data.frame(y = rpois(200, 3), x = rnorm(200))
  fit <- glm(y ~ x, family = poisson, data = d)
  eq <- mysterycall_model_equation(fit, wrap = FALSE)
  expect_match(eq, "\\log", fixed = TRUE)
  expect_false(startsWith(eq, "$$"))
})

test_that("coefficients = TRUE substitutes fitted numbers for the betas", {
  set.seed(3)
  d <- data.frame(y = rbinom(200, 1, 0.5), x = rnorm(200))
  fit <- glm(y ~ x, family = binomial, data = d)
  eq <- mysterycall_model_equation(fit, coefficients = TRUE)
  expect_false(grepl("\\beta", eq, fixed = TRUE))   # no symbolic betas
  expect_match(eq, "cdot", fixed = FALSE)            # has term * value
})

test_that("a legend maps each beta to its term label (symbolic form)", {
  set.seed(4)
  d <- data.frame(y = rbinom(200, 1, 0.5), a = rnorm(200), b = rnorm(200))
  fit <- glm(y ~ a + b, family = binomial, data = d)
  eq <- mysterycall_model_equation(fit)
  leg <- attr(eq, "legend")
  expect_length(leg, 2L)
  expect_match(leg[1], "= a$")
  expect_match(leg[2], "= b$")
})

test_that("a mixed model shows a random intercept and its variance", {
  skip_if_not_installed("lme4")
  set.seed(5)
  d <- data.frame(y = rbinom(300, 1, 0.5), x = rnorm(300),
                  grp = factor(sample(letters[1:8], 300, TRUE)))
  fit <- suppressWarnings(
    lme4::glmer(y ~ x + (1 | grp), family = binomial, data = d))
  eq <- mysterycall_model_equation(fit)
  expect_match(eq, "u_\\{", fixed = FALSE)
  expect_match(eq, "sigma\\^2", fixed = FALSE)
  expect_match(eq, "grp", fixed = FALSE)
})

test_that("underscores in term names are escaped for LaTeX", {
  set.seed(6)
  d <- data.frame(y = rbinom(200, 1, 0.5), wait_days = rnorm(200))
  fit <- glm(y ~ wait_days, family = binomial, data = d)
  eq <- mysterycall_model_equation(fit)
  expect_match(eq, "wait\\\\_days", fixed = FALSE)   # underscore escaped
})

test_that("a mysterycall model wrapper is unwrapped", {
  set.seed(7)
  d <- data.frame(
    npi = rep(sprintf("1%09d", 1:60), each = 2),
    insurance = rep(c("Commercial", "Medicaid"), 60),
    appt_offered = rbinom(120, 1, 0.6))
  fit <- mysterycall_logistic_model(d, "appt_offered", "insurance", "npi")
  eq <- mysterycall_model_equation(fit)
  expect_match(eq, "operatorname\\{logit\\}", fixed = FALSE)
  expect_match(eq, "u_\\{", fixed = FALSE)           # has the npi random intercept
})
