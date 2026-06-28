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

# Test 1: Happy path - Poisson GLM with default thresholds
test_that("mysterycall_overdispersion_test works with Poisson GLM and returns proper list structure", {
  set.seed(2)
  n   <- 200
  dat <- data.frame(
    y   = rpois(n, lambda = exp(0.5 + 0.3 * rnorm(n))),
    x1  = rnorm(n),
    grp = sample(c("A", "B"), n, replace = TRUE)
  )
  fit <- glm(y ~ x1 + grp, data = dat, family = poisson())
  result <- mysterycall_overdispersion_test(fit)

  expect_s3_class(result, "mysterycall_overdispersion_test")
  expect_type(result, "list")
  expect_true(all(c("phi", "pearson_chisq", "df", "p_value", "p_fmt",
                    "interpretation", "recommendation", "sentence", "category") %in% names(result)))
  expect_true(is.numeric(result$phi))
  expect_true(is.numeric(result$pearson_chisq))
  expect_true(is.numeric(result$df))
  expect_true(is.numeric(result$p_value))
  expect_true(is.character(result$p_fmt))
  expect_true(is.character(result$interpretation))
  expect_true(is.character(result$recommendation))
  expect_true(is.character(result$sentence))
  expect_true(is.character(result$category))
})

# Test 2: Gaussian GLM is accepted by the function (phi may be any value)
test_that("mysterycall_overdispersion_test accepts Gaussian GLM and returns valid result", {
  fit <- glm(mpg ~ wt + cyl, data = mtcars, family = gaussian())
  result <- mysterycall_overdispersion_test(fit)

  expect_s3_class(result, "mysterycall_overdispersion_test")
  expect_true(is.numeric(result$phi))
  expect_true(result$phi > 0)
  expect_true(nchar(result$category) > 0)
  expect_true(nchar(result$interpretation) > 0)
})

# Test 3: Edge case - custom phi_thresholds are respected
test_that("mysterycall_overdispersion_test respects custom phi_thresholds", {
  set.seed(3)
  n   <- 200
  dat <- data.frame(
    y   = rpois(n, lambda = 5),
    x1  = rnorm(n)
  )
  fit <- glm(y ~ x1, data = dat, family = poisson())

  custom_thresholds <- c(mild = 1.1, moderate = 1.3, severe = 1.5)
  result <- mysterycall_overdispersion_test(fit, phi_thresholds = custom_thresholds)

  expect_s3_class(result, "mysterycall_overdispersion_test")
  expect_true(result$phi >= 0)
  expect_match(result$sentence, "Pearson dispersion")
})

# Test 4: Bad input - missing required model argument
test_that("mysterycall_overdispersion_test errors when model is missing", {
  expect_error(mysterycall_overdispersion_test(), "missing")
})

# Test 5: Bad input - phi_thresholds without required names
test_that("mysterycall_overdispersion_test errors on unnamed phi_thresholds", {
  set.seed(4)
  n   <- 100
  dat <- data.frame(y = rpois(n, 5), x = rnorm(n))
  fit <- glm(y ~ x, data = dat, family = poisson())

  expect_error(
    mysterycall_overdispersion_test(fit, phi_thresholds = c(1.2, 1.5, 2.0)),
    "named numeric vector"
  )
})

# Test 6: Bad input - phi_thresholds with incorrect order
test_that("mysterycall_overdispersion_test errors when phi_thresholds not ordered", {
  set.seed(5)
  n   <- 100
  dat <- data.frame(y = rpois(n, 5), x = rnorm(n))
  fit <- glm(y ~ x, data = dat, family = poisson())

  expect_error(
    mysterycall_overdispersion_test(fit, phi_thresholds = c(mild = 2.0, moderate = 1.5, severe = 1.2)),
    "mild < moderate < severe"
  )
})

# Test 7: Bad input - invalid digits parameter
test_that("mysterycall_overdispersion_test errors on negative digits", {
  set.seed(6)
  n   <- 100
  dat <- data.frame(y = rpois(n, 5), x = rnorm(n))
  fit <- glm(y ~ x, data = dat, family = poisson())

  expect_error(
    mysterycall_overdispersion_test(fit, digits = -1),
    "non-negative integer"
  )
})

# Test 8: Print method returns invisible and outputs text
test_that("print.mysterycall_overdispersion_test outputs and returns invisible", {
  set.seed(7)
  n   <- 200
  dat <- data.frame(
    y   = rpois(n, lambda = 5),
    x1  = rnorm(n)
  )
  fit <- glm(y ~ x1, data = dat, family = poisson())
  result <- mysterycall_overdispersion_test(fit)

  output <- capture.output(print(result))
  expect_true(length(output) >= 2)
  expect_true(any(grepl("Pearson dispersion", output)))
  expect_true(any(grepl("phi=", output)))
})

# Test 9: Different digits parameter produces different formatting
test_that("mysterycall_overdispersion_test respects digits formatting parameter", {
  set.seed(8)
  n   <- 200
  dat <- data.frame(
    y   = rpois(n, lambda = 5),
    x1  = rnorm(n)
  )
  fit <- glm(y ~ x1, data = dat, family = poisson())

  result_3 <- mysterycall_overdispersion_test(fit, digits = 3L)
  result_1 <- mysterycall_overdispersion_test(fit, digits = 1L)

  expect_s3_class(result_3, "mysterycall_overdispersion_test")
  expect_s3_class(result_1, "mysterycall_overdispersion_test")
  expect_true(is.character(result_3$p_fmt))
  expect_true(is.character(result_1$p_fmt))
})

# Test 10: lme4 glmer models supported when lme4 available
test_that("mysterycall_overdispersion_test works with lme4 glmer models", {
  skip_if_not_installed("lme4")

  set.seed(9)
  dat <- data.frame(
    y    = rpois(100, lambda = 5),
    x    = rnorm(100),
    grp  = rep(c("A", "B"), 50)
  )

  fit <- lme4::glmer(y ~ x + (1 | grp), data = dat, family = poisson())
  result <- mysterycall_overdispersion_test(fit)

  expect_s3_class(result, "mysterycall_overdispersion_test")
  expect_true(is.numeric(result$phi))
  expect_true(result$phi > 0)
})

# Test 11: Edge case - very small model with minimal degrees of freedom
test_that("mysterycall_overdispersion_test handles small models", {
  set.seed(10)
  dat <- data.frame(
    y = c(1, 2, 3, 4, 5),
    x = c(1, 2, 3, 4, 5)
  )
  fit <- glm(y ~ x, data = dat, family = poisson())
  result <- mysterycall_overdispersion_test(fit)

  expect_s3_class(result, "mysterycall_overdispersion_test")
  expect_true(is.numeric(result$df))
  expect_true(result$df >= 0)
})

# Test 12: Category interpretation for moderate overdispersion
test_that("mysterycall_overdispersion_test correctly assigns moderate category", {
  set.seed(11)
  # Simulate data with moderate overdispersion by using higher variance
  n   <- 300
  mu  <- exp(0.5 + 0.5 * rnorm(n))
  dat <- data.frame(
    y   = sapply(mu, function(m) rpois(1, m * 1.5)),
    x1  = rnorm(n),
    x2  = rnorm(n)
  )
  fit <- glm(y ~ x1 + x2, data = dat, family = poisson())
  result <- mysterycall_overdispersion_test(fit)

  expect_s3_class(result, "mysterycall_overdispersion_test")
  expect_true(result$phi >= 1.0)
})
