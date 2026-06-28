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


test_that("mysterycall_marginal_effects: basic glm with categorical predictor", {
  set.seed(210)
  m <- glm(days ~ factor(insurance), data = COUNT_DF, family = poisson())
  result <- suppressMessages(mysterycall_marginal_effects(m))

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
  expect_equal(colnames(result), c("term", "level", "ame", "variable_type"))
  expect_true(all(result$variable_type %in% c("continuous", "categorical")))
  expect_true(all(!is.na(result$ame)))
})


test_that("mysterycall_marginal_effects: term parameter filters output", {
  set.seed(210)
  m <- glm(days ~ factor(insurance), data = COUNT_DF, family = poisson())
  result <- suppressMessages(mysterycall_marginal_effects(m, term = "insurance"))

  expect_s3_class(result, "data.frame")
  expect_true(all(result$term == "insurance"))
  expect_true(all(result$variable_type == "categorical"))
})


test_that("mysterycall_marginal_effects: continuous predictor via numerical differentiation", {
  set.seed(210)
  cont_data <- data.frame(
    outcome = c(rpois(30, 5), rpois(30, 10)),
    x_cont = rnorm(60, mean = 50, sd = 10),
    x_cat = rep(c("A", "B"), times = 30),
    stringsAsFactors = FALSE
  )
  m <- glm(outcome ~ x_cont + x_cat, data = cont_data, family = poisson())
  result <- suppressMessages(mysterycall_marginal_effects(m, term = "x_cont"))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$term, "x_cont")
  expect_equal(result$variable_type, "continuous")
  expect_true(is.na(result$level))
  expect_true(is.numeric(result$ame))
})


test_that("mysterycall_marginal_effects: glm with multiple terms", {
  set.seed(210)
  multi_data <- data.frame(
    y = c(rpois(30, 5), rpois(30, 10)),
    x1 = rnorm(60, mean = 50, sd = 10),
    x2 = rep(c("A", "B"), times = 30),
    stringsAsFactors = FALSE
  )
  m <- glm(y ~ x1 + factor(x2), data = multi_data, family = poisson())
  result <- suppressMessages(mysterycall_marginal_effects(m))

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) >= 2)
  expect_equal(colnames(result), c("term", "level", "ame", "variable_type"))
  expect_true(all(!is.na(result$ame)))
  # Check that we have both continuous and categorical
  expect_true("continuous" %in% result$variable_type)
  expect_true("categorical" %in% result$variable_type)
})


test_that("mysterycall_marginal_effects: type='link' vs type='response'", {
  set.seed(210)
  m <- glm(days ~ factor(insurance), data = COUNT_DF, family = poisson())
  result_response <- suppressMessages(mysterycall_marginal_effects(m, type = "response"))
  result_link <- suppressMessages(mysterycall_marginal_effects(m, type = "link"))

  expect_s3_class(result_response, "data.frame")
  expect_s3_class(result_link, "data.frame")
  expect_equal(colnames(result_response), colnames(result_link))
  expect_equal(nrow(result_response), nrow(result_link))
})


test_that("mysterycall_marginal_effects: glmerMod with lme4", {
  skip_if_not_installed("lme4")

  set.seed(210)
  group_data <- data.frame(
    outcome = c(rpois(40, 5), rpois(40, 10)),
    predictor = rep(c("A", "B"), each = 40),
    group = rep(1:4, each = 10, length.out = 80),
    stringsAsFactors = FALSE
  )

  m <- suppressMessages(lme4::glmer(
    outcome ~ predictor + (1 | group),
    data = group_data,
    family = poisson()
  ))
  result <- suppressMessages(mysterycall_marginal_effects(m))

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)
  expect_equal(colnames(result), c("term", "level", "ame", "variable_type"))
})


test_that("mysterycall_marginal_effects: rejects invalid model class", {
  bad_model <- list(data = COUNT_DF)
  expect_error(
    suppressMessages(mysterycall_marginal_effects(bad_model)),
    "must be a glm, glmerMod"
  )
})


test_that("mysterycall_marginal_effects: rejects invalid eps parameter", {
  set.seed(210)
  m <- glm(days ~ factor(insurance), data = COUNT_DF, family = poisson())
  expect_error(
    mysterycall_marginal_effects(m, eps = -1),
    "must be a single positive number"
  )
  expect_error(
    mysterycall_marginal_effects(m, eps = 0),
    "must be a single positive number"
  )
})


test_that("mysterycall_marginal_effects: rejects term not in model", {
  set.seed(210)
  m <- glm(days ~ factor(insurance), data = COUNT_DF, family = poisson())
  expect_error(
    suppressMessages(mysterycall_marginal_effects(m, term = "nonexistent")),
    "not found in model"
  )
})


test_that("mysterycall_marginal_effects: rejects non-character term parameter", {
  set.seed(210)
  m <- glm(days ~ factor(insurance), data = COUNT_DF, family = poisson())
  expect_error(
    mysterycall_marginal_effects(m, term = 123),
    "must be a character vector or NULL"
  )
})
