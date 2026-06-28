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

test_that("mysterycall_interaction_sentences: happy path with default parameters", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("lme4")

  set.seed(205)
  test_df <- data.frame(
    outcome = rpois(60, 8),
    var1 = rep(c("A", "B"), each = 30),
    var2 = rep(c("X", "Y", "Z"), times = 20),
    block = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(lme4::glmer(
    outcome ~ var1 * var2 + (1 | block),
    data = test_df,
    family = poisson()
  ))

  result <- suppressMessages(mysterycall_interaction_sentences(
    model = fit,
    var1 = "var1",
    var2 = "var2"
  ))

  expect_s3_class(result, "mysterycall_interaction_sentences")
  expect_named(result, c("sentences", "emmeans_table", "paragraph", "var1", "var2", "type"))
  expect_type(result$sentences, "character")
  expect_true(is.data.frame(result$emmeans_table))
  expect_type(result$paragraph, "character")
  expect_equal(result$var1, "var1")
  expect_equal(result$var2, "var2")
  expect_equal(result$type, "response")
})

test_that("mysterycall_interaction_sentences: parameter variation with ref_group2 and outcome_label", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("lme4")

  set.seed(206)
  test_df <- data.frame(
    outcome = rpois(60, 8),
    var1 = rep(c("A", "B"), each = 30),
    var2 = rep(c("X", "Y", "Z"), times = 20),
    block = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(lme4::glmer(
    outcome ~ var1 * var2 + (1 | block),
    data = test_df,
    family = poisson()
  ))

  result <- suppressMessages(mysterycall_interaction_sentences(
    model = fit,
    var1 = "var1",
    var2 = "var2",
    ref_group2 = "Y",
    outcome_label = "custom outcome (units)"
  ))

  expect_s3_class(result, "mysterycall_interaction_sentences")
  expect_true(grepl("custom outcome", result$paragraph))
  expect_equal(result$var1, "var1")
  expect_equal(result$var2, "var2")
})

test_that("mysterycall_interaction_sentences: type parameter variation", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("lme4")

  set.seed(207)
  test_df <- data.frame(
    outcome = rbinom(60, size = 1, prob = 0.5),
    var1 = rep(c("A", "B"), each = 30),
    var2 = rep(c("X", "Y", "Z"), times = 20),
    block = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(lme4::glmer(
    outcome ~ var1 * var2 + (1 | block),
    data = test_df,
    family = binomial()
  ))

  result <- suppressMessages(mysterycall_interaction_sentences(
    model = fit,
    var1 = "var1",
    var2 = "var2",
    type = "response"
  ))

  expect_s3_class(result, "mysterycall_interaction_sentences")
  expect_equal(result$type, "response")
  expect_true(is.data.frame(result$emmeans_table))
})

test_that("mysterycall_interaction_sentences: bad input - wrong types", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("lme4")

  set.seed(208)
  test_df <- data.frame(
    outcome = rpois(60, 8),
    var1 = rep(c("A", "B"), each = 30),
    var2 = rep(c("X", "Y", "Z"), times = 20),
    block = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(lme4::glmer(
    outcome ~ var1 * var2 + (1 | block),
    data = test_df,
    family = poisson()
  ))

  # var1 wrong type (numeric instead of character)
  expect_error(
    mysterycall_interaction_sentences(model = fit, var1 = 123, var2 = "var2"),
    "var1"
  )

  # var2 wrong type
  expect_error(
    mysterycall_interaction_sentences(model = fit, var1 = "var1", var2 = 456),
    "var2"
  )

  # conf_level out of bounds
  expect_error(
    mysterycall_interaction_sentences(model = fit, var1 = "var1", var2 = "var2", conf_level = 1.5),
    "conf_level"
  )

  # conf_level is 0 or 1 (boundary)
  expect_error(
    mysterycall_interaction_sentences(model = fit, var1 = "var1", var2 = "var2", conf_level = 0),
    "conf_level"
  )

  expect_error(
    mysterycall_interaction_sentences(model = fit, var1 = "var1", var2 = "var2", conf_level = 1),
    "conf_level"
  )
})

test_that("mysterycall_interaction_sentences: identical variables should error", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("lme4")

  set.seed(209)
  test_df <- data.frame(
    outcome = rpois(60, 8),
    var1 = rep(c("A", "B"), each = 30),
    var2 = rep(c("X", "Y", "Z"), times = 20),
    block = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(lme4::glmer(
    outcome ~ var1 * var2 + (1 | block),
    data = test_df,
    family = poisson()
  ))

  expect_error(
    mysterycall_interaction_sentences(model = fit, var1 = "var1", var2 = "var1"),
    "var1.*var2.*different"
  )
})

test_that("mysterycall_interaction_sentences: print method outputs paragraph", {
  skip_if_not_installed("emmeans")
  skip_if_not_installed("lme4")

  set.seed(210)
  test_df <- data.frame(
    outcome = rpois(60, 8),
    var1 = rep(c("A", "B"), each = 30),
    var2 = rep(c("X", "Y", "Z"), times = 20),
    block = rep(1:6, each = 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(lme4::glmer(
    outcome ~ var1 * var2 + (1 | block),
    data = test_df,
    family = poisson()
  ))

  result <- suppressMessages(mysterycall_interaction_sentences(
    model = fit,
    var1 = "var1",
    var2 = "var2"
  ))

  # Test that print method returns invisibly
  output <- capture.output(print(result))
  expect_true(length(output) > 0)
  expect_match(output[1], "var1")
})
