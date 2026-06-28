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

test_that("mysterycall_overdispersion_sentence happy path with GLM", {
  m <- suppressWarnings(glm(breaks ~ wool + tension, data = warpbreaks, family = poisson))
  res <- mysterycall_overdispersion_sentence(m)

  expect_type(res, "list")
  expect_named(res, c("chisq", "ratio", "df", "p_value", "p_formatted",
                      "interpretation", "sentence", "overdispersed"))
  expect_true(is.numeric(res$chisq))
  expect_true(is.numeric(res$ratio))
  expect_true(is.numeric(res$df))
  expect_true(is.numeric(res$p_value))
  expect_type(res$p_formatted, "character")
  expect_type(res$interpretation, "character")
  expect_type(res$sentence, "character")
  expect_type(res$overdispersed, "logical")

  # Check that sentence contains expected key phrases
  expect_true(grepl("Pearson dispersion ratio", res$sentence))
  expect_true(grepl("chi-square", res$sentence))

  # Check numeric bounds
  expect_true(res$ratio > 0)
  expect_true(res$chisq >= 0)
  expect_true(res$df > 0)
  expect_true(res$p_value >= 0 && res$p_value <= 1)
})

test_that("mysterycall_overdispersion_sentence with custom digit parameters", {
  m <- suppressWarnings(glm(breaks ~ wool + tension, data = warpbreaks, family = poisson))

  # Test with digits_ratio = 0
  res0 <- mysterycall_overdispersion_sentence(m, digits_ratio = 0, digits_p = 0)
  expect_type(res0, "list")
  expect_type(res0$sentence, "character")

  # Test with digits_ratio = 4, digits_p = 5
  res4 <- mysterycall_overdispersion_sentence(m, digits_ratio = 4, digits_p = 5)
  expect_type(res4, "list")
  expect_type(res4$sentence, "character")

  # Sentences should differ due to different rounding
  expect_false(identical(res0$sentence, res4$sentence))
})

test_that("mysterycall_overdispersion_sentence with linear model", {
  set.seed(216)
  lm_fit <- lm(breaks ~ wool + tension, data = warpbreaks)
  res <- mysterycall_overdispersion_sentence(lm_fit)

  expect_type(res, "list")
  expect_named(res, c("chisq", "ratio", "df", "p_value", "p_formatted",
                      "interpretation", "sentence", "overdispersed"))
  expect_true(is.numeric(res$chisq))
  expect_true(is.numeric(res$ratio))
  expect_true(is.numeric(res$df))
  expect_true(is.numeric(res$p_value))
  expect_type(res$overdispersed, "logical")
})

test_that("mysterycall_overdispersion_sentence errors on invalid model", {
  # Test with object that has no df.residual method or returns NULL
  expect_error(
    mysterycall_overdispersion_sentence(list(a = 1, b = 2)),
    "df.residual"
  )
})

test_that("mysterycall_overdispersion_sentence errors on invalid digit parameters", {
  m <- suppressWarnings(glm(breaks ~ wool + tension, data = warpbreaks, family = poisson))

  # digits_ratio should be >= 0
  expect_error(
    mysterycall_overdispersion_sentence(m, digits_ratio = -1),
    ">= 0"
  )

  # digits_p should be >= 0
  expect_error(
    mysterycall_overdispersion_sentence(m, digits_p = -1),
    ">= 0"
  )

  # digits_ratio must be length 1
  expect_error(
    mysterycall_overdispersion_sentence(m, digits_ratio = c(1, 2)),
    "len"
  )
})

test_that("mysterycall_overdispersion_sentence p-value formatting for very small p", {
  # Create a model with very overdispersed data to get small p-value
  set.seed(216)
  od_data <- data.frame(
    y = c(rep(100, 20), rep(50, 20)),
    x = rep(c(0, 1), each = 20)
  )
  m <- suppressWarnings(glm(y ~ x, data = od_data, family = poisson))
  res <- mysterycall_overdispersion_sentence(m, digits_p = 3)

  # Check that p_formatted is properly formatted
  expect_type(res$p_formatted, "character")
  expect_true(nchar(res$p_formatted) > 0)

  # If p is very small, should show "< 0.001"
  if (res$p_value < 0.001) {
    expect_equal(res$p_formatted, "< 0.001")
  } else {
    # Otherwise should be a number string with 3 decimal places
    expect_match(res$p_formatted, "^[0-9]+\\.[0-9]{3}$")
  }
})
