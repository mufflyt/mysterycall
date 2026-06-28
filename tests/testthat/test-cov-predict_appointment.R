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

test_that("mysterycall_predict_appointment returns data frame with prob and CI columns", {
  skip_if_not_installed("lme4")

  set.seed(224)
  df <- data.frame(
    practice  = rep(paste0("P", 1:5), each = 8),
    insurance = rep(c("Medicaid", "BCBS"), 20),
    accepted  = rbinom(40, 1, prob = 0.5),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(mysterycall_logistic_model(
    df, "accepted", "insurance", "practice"
  ))

  new_profiles <- data.frame(
    insurance = c("Medicaid", "BCBS"),
    practice  = c("new1", "new2"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_predict_appointment(fit, new_profiles))

  expect_s3_class(result, "data.frame")
  expect_true("prob" %in% names(result))
  expect_true("ci_lower" %in% names(result))
  expect_true("ci_upper" %in% names(result))
  expect_equal(nrow(result), 2L)
  expect_true(all(result$prob >= 0 & result$prob <= 1))
  expect_true(all(result$ci_lower >= 0 & result$ci_lower <= 1, na.rm = TRUE))
  expect_true(all(result$ci_upper >= 0 & result$ci_upper <= 1, na.rm = TRUE))
})

test_that("mysterycall_predict_appointment with ci=FALSE returns NA for CI columns", {
  skip_if_not_installed("lme4")

  set.seed(225)
  df <- data.frame(
    practice  = rep(paste0("P", 1:5), each = 8),
    insurance = rep(c("Medicaid", "BCBS"), 20),
    accepted  = rbinom(40, 1, prob = 0.5),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(mysterycall_logistic_model(
    df, "accepted", "insurance", "practice"
  ))

  new_profiles <- data.frame(
    insurance = "Medicaid",
    practice  = "new1",
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_predict_appointment(
    fit, new_profiles, ci = FALSE
  ))

  expect_true(all(is.na(result$ci_lower)))
  expect_true(all(is.na(result$ci_upper)))
  expect_false(any(is.na(result$prob)))
})

test_that("mysterycall_predict_appointment rejects invalid fit object", {
  skip_if_not_installed("lme4")

  new_profiles <- data.frame(
    insurance = "Medicaid",
    practice  = "new1"
  )

  bad_fit <- list(model = NULL)

  expect_error(
    mysterycall_predict_appointment(bad_fit, new_profiles),
    "fit.*mysterycall_logistic_model"
  )
})

test_that("mysterycall_predict_appointment rejects empty newdata", {
  skip_if_not_installed("lme4")

  set.seed(226)
  df <- data.frame(
    practice  = rep(paste0("P", 1:5), each = 8),
    insurance = rep(c("Medicaid", "BCBS"), 20),
    accepted  = rbinom(40, 1, prob = 0.5),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(mysterycall_logistic_model(
    df, "accepted", "insurance", "practice"
  ))

  empty_df <- df[FALSE, c("insurance", "practice")]

  expect_error(
    mysterycall_predict_appointment(fit, empty_df),
    "non-empty data frame"
  )
})

test_that("mysterycall_predict_appointment validates conf_level parameter", {
  skip_if_not_installed("lme4")

  set.seed(227)
  df <- data.frame(
    practice  = rep(paste0("P", 1:5), each = 8),
    insurance = rep(c("Medicaid", "BCBS"), 20),
    accepted  = rbinom(40, 1, prob = 0.5),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(mysterycall_logistic_model(
    df, "accepted", "insurance", "practice"
  ))

  new_profiles <- data.frame(
    insurance = "Medicaid",
    practice  = "new1"
  )

  expect_error(
    mysterycall_predict_appointment(fit, new_profiles, conf_level = 1.5),
    "conf_level.*must be"
  )

  expect_error(
    mysterycall_predict_appointment(fit, new_profiles, conf_level = 0),
    "conf_level.*must be"
  )
})

test_that("mysterycall_predict_appointment handles re.form parameter for conditional predictions", {
  skip_if_not_installed("lme4")

  set.seed(228)
  df <- data.frame(
    practice  = rep(paste0("P", 1:5), each = 8),
    insurance = rep(c("Medicaid", "BCBS"), 20),
    accepted  = rbinom(40, 1, prob = 0.5),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(mysterycall_logistic_model(
    df, "accepted", "insurance", "practice"
  ))

  # Use a practice from training data
  new_profiles <- data.frame(
    insurance = "Medicaid",
    practice  = "P1",
    stringsAsFactors = FALSE
  )

  result_pop <- suppressMessages(mysterycall_predict_appointment(
    fit, new_profiles, re.form = NA
  ))
  result_cond <- suppressMessages(mysterycall_predict_appointment(
    fit, new_profiles, re.form = NULL
  ))

  expect_s3_class(result_pop, "data.frame")
  expect_s3_class(result_cond, "data.frame")
  expect_true("prob" %in% names(result_pop))
  expect_true("prob" %in% names(result_cond))
})
