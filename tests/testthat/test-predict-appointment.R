test_that("wrong class throws informative error", {
  expect_error(
    mysterycall_predict_appointment(list(), data.frame(x = 1)),
    "mysterycall_logistic_model"
  )
})

test_that("empty newdata throws error", {
  skip_if_not_installed("lme4")
  set.seed(1)
  df <- data.frame(
    practice  = rep(paste0("P", 1:10), each = 6),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    accepted  = rbinom(60, 1, 0.5)
  )
  fit <- mysterycall_logistic_model(df, "accepted", "insurance", "practice")
  expect_error(
    mysterycall_predict_appointment(fit, data.frame()),
    "non-empty"
  )
})

test_that("returns newdata with prob, ci_lower, ci_upper", {
  skip_if_not_installed("lme4")
  set.seed(2)
  df <- data.frame(
    practice  = rep(paste0("P", 1:10), each = 6),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    accepted  = rbinom(60, 1, 0.5)
  )
  fit <- mysterycall_logistic_model(df, "accepted", "insurance", "practice")
  nd  <- data.frame(insurance = c("Medicaid", "BCBS"), practice = "new1")
  out <- mysterycall_predict_appointment(fit, nd)

  expect_s3_class(out, "data.frame")
  expect_true(all(c("prob", "ci_lower", "ci_upper") %in% names(out)))
  expect_equal(nrow(out), 2L)
  expect_true(all(out$prob >= 0 & out$prob <= 1))
  expect_true(all(out$ci_lower <= out$prob))
  expect_true(all(out$ci_upper >= out$prob))
})

test_that("Medicaid < BCBS probability when signal is strong", {
  skip_if_not_installed("lme4")
  set.seed(3)
  true_prob <- ifelse(rep(c("Medicaid", "BCBS"), 30) == "Medicaid", 0.2, 0.8)
  df <- data.frame(
    practice  = rep(paste0("P", 1:10), each = 6),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    accepted  = rbinom(60, 1, true_prob)
  )
  fit <- mysterycall_logistic_model(df, "accepted", "insurance", "practice")
  nd  <- data.frame(insurance = c("Medicaid", "BCBS"), practice = "new1")
  out <- mysterycall_predict_appointment(fit, nd)

  expect_lt(out$prob[out$insurance == "Medicaid"],
            out$prob[out$insurance == "BCBS"])
})

test_that("ci=FALSE returns NA for confidence bounds", {
  skip_if_not_installed("lme4")
  set.seed(4)
  df <- data.frame(
    practice  = rep(paste0("P", 1:10), each = 6),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    accepted  = rbinom(60, 1, 0.5)
  )
  fit <- mysterycall_logistic_model(df, "accepted", "insurance", "practice")
  nd  <- data.frame(insurance = "Medicaid", practice = "new1")
  out <- mysterycall_predict_appointment(fit, nd, ci = FALSE)

  expect_true(is.na(out$ci_lower))
  expect_true(is.na(out$ci_upper))
  expect_false(is.na(out$prob))
})

test_that("higher conf_level gives wider CI", {
  skip_if_not_installed("lme4")
  set.seed(5)
  df <- data.frame(
    practice  = rep(paste0("P", 1:10), each = 6),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    accepted  = rbinom(60, 1, 0.5)
  )
  fit <- suppressWarnings(
    mysterycall_logistic_model(df, "accepted", "insurance", "practice")
  )
  # Include both insurance levels so model.matrix infers reference correctly
  nd <- data.frame(insurance = c("Medicaid", "BCBS"), practice = "new1")

  out90 <- mysterycall_predict_appointment(fit, nd, conf_level = 0.90)
  out99 <- mysterycall_predict_appointment(fit, nd, conf_level = 0.99)

  width90 <- out90$ci_upper[1L] - out90$ci_lower[1L]
  width99 <- out99$ci_upper[1L] - out99$ci_lower[1L]

  expect_false(is.na(width90))
  expect_gt(width99, width90)
})
