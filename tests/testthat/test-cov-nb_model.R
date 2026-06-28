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

# Test 1: mysterycall_nb_model happy path - basic fit with valid inputs
test_that("mysterycall_nb_model fits valid data and returns correct structure", {
  skip_if_not_installed("glmmTMB")

  set.seed(301)
  df <- data.frame(
    wait_days = c(rpois(30, 5), rpois(30, 8)),
    insurance = rep(c("Medicaid", "BCBS"), each = 30),
    physician = rep(paste0("Dr_", 1:5), each = 12),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician"
  ))

  expect_s3_class(result, "mysterycall_nb_model")
  expect_true(is.list(result))
  expect_named(result, c("model", "irr_table", "theta", "overdispersion",
                         "random_effects", "factor_refs", "formula", "n",
                         "n_dropped", "n_clusters", "convergence", "aic", "bic"))
  expect_s3_class(result$irr_table, "data.frame")
  expect_true(is.numeric(result$theta))
  expect_true(is.numeric(result$aic))
  expect_true(result$n > 0L)
})

# Test 2: edge case - missing values dropped correctly
test_that("mysterycall_nb_model drops NA rows and reports count", {
  skip_if_not_installed("glmmTMB")

  set.seed(302)
  df <- data.frame(
    wait_days = c(rpois(20, 5), NA, rpois(10, 8)),
    insurance = rep(c("Medicaid", "BCBS"), length.out = 31),
    physician = rep(paste0("Dr_", 1:4), length.out = 31),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician"
  ))

  expect_gt(result$n_dropped, 0L)
  expect_equal(result$n + result$n_dropped, 31L)
  expect_s3_class(result, "mysterycall_nb_model")
})

# Test 3: bad input - non-numeric outcome column
test_that("mysterycall_nb_model rejects non-numeric outcome", {
  skip_if_not_installed("glmmTMB")

  df <- data.frame(
    outcome_col = c("a", "b", "c", "d"),
    insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
    physician = c("Dr_1", "Dr_1", "Dr_2", "Dr_2"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_nb_model(
      data = df,
      outcome = "outcome_col",
      predictors = "insurance",
      random_intercept = "physician"
    ),
    "must be numeric"
  )
})

# Test 4: bad input - missing required outcome column
test_that("mysterycall_nb_model errors when outcome column missing", {
  skip_if_not_installed("glmmTMB")

  df <- data.frame(
    insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
    physician = c("Dr_1", "Dr_1", "Dr_2", "Dr_2"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_nb_model(
      data = df,
      outcome = "nonexistent_col",
      predictors = "insurance",
      random_intercept = "physician"
    )
  )
})

# Test 5: bad input - negative values in outcome
test_that("mysterycall_nb_model rejects negative outcome values", {
  skip_if_not_installed("glmmTMB")

  df <- data.frame(
    wait_days = c(-5, 3, 2, 4),
    insurance = c("Medicaid", "BCBS", "Medicaid", "BCBS"),
    physician = c("Dr_1", "Dr_1", "Dr_2", "Dr_2"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_nb_model(
      data = df,
      outcome = "wait_days",
      predictors = "insurance",
      random_intercept = "physician"
    ),
    "negative values"
  )
})

# Test 6: bad input - invalid conf_level
test_that("mysterycall_nb_model rejects conf_level outside (0,1)", {
  skip_if_not_installed("glmmTMB")

  set.seed(303)
  df <- data.frame(
    wait_days = rpois(20, 5),
    insurance = rep(c("Medicaid", "BCBS"), length.out = 20),
    physician = rep(paste0("Dr_", 1:3), length.out = 20),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_nb_model(
      data = df,
      outcome = "wait_days",
      predictors = "insurance",
      random_intercept = "physician",
      conf_level = 1.5
    )),
    "strictly between 0 and 1"
  )
})

# Test 7: multiple predictors
test_that("mysterycall_nb_model handles multiple predictors", {
  skip_if_not_installed("glmmTMB")

  set.seed(304)
  df <- data.frame(
    wait_days = c(rpois(25, 5), rpois(25, 8)),
    insurance = rep(c("Medicaid", "BCBS"), length.out = 50),
    gender = rep(c("M", "F"), length.out = 50),
    physician = rep(paste0("Dr_", 1:5), each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = c("insurance", "gender"),
    random_intercept = "physician"
  ))

  expect_s3_class(result, "mysterycall_nb_model")
  expect_true(nrow(result$irr_table) >= 3L)
})

# Test 8: offset_col parameter included in formula
test_that("mysterycall_nb_model includes offset_col in formula", {
  skip_if_not_installed("glmmTMB")

  set.seed(305)
  df <- data.frame(
    wait_days = c(rpois(20, 5), rpois(20, 8)),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    exposure = rep(c(100, 200), length.out = 40),
    physician = rep(paste0("Dr_", 1:4), each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_nb_model(
      data = df,
      outcome = "wait_days",
      predictors = "insurance",
      random_intercept = "physician",
      offset_col = "exposure"
    )
  ))

  expect_s3_class(result, "mysterycall_nb_model")
  expect_true(grepl("offset", deparse(result$formula)))
})

# Test 9: conf_level affects confidence interval width
test_that("mysterycall_nb_model conf_level affects CI width", {
  skip_if_not_installed("glmmTMB")

  set.seed(306)
  df <- data.frame(
    wait_days = c(rpois(30, 5), rpois(30, 8)),
    insurance = rep(c("Medicaid", "BCBS"), each = 30),
    physician = rep(paste0("Dr_", 1:5), each = 12),
    stringsAsFactors = FALSE
  )

  result_95 <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician",
    conf_level = 0.95
  ))

  result_90 <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician",
    conf_level = 0.90
  ))

  # 95% CI should be wider than 90% CI
  ci_width_95 <- mean(result_95$irr_table$ci_upper - result_95$irr_table$ci_lower)
  ci_width_90 <- mean(result_90$irr_table$ci_upper - result_90$irr_table$ci_lower)
  expect_gt(ci_width_95, ci_width_90)
})

# Test 10: IRR table has expected columns
test_that("mysterycall_nb_model irr_table has all expected columns", {
  skip_if_not_installed("glmmTMB")

  set.seed(307)
  df <- data.frame(
    wait_days = c(rpois(25, 5), rpois(25, 8)),
    insurance = rep(c("Medicaid", "BCBS"), length.out = 50),
    physician = rep(paste0("Dr_", 1:5), each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician"
  ))

  expected_cols <- c("term", "estimate", "se", "z_value", "p_value",
                     "p_value_fmt", "irr", "ci_lower", "ci_upper")
  expect_true(all(expected_cols %in% names(result$irr_table)))
})

# Test 11: print method outputs without error
test_that("print.mysterycall_nb_model outputs summary statistics", {
  skip_if_not_installed("glmmTMB")

  set.seed(308)
  df <- data.frame(
    wait_days = c(rpois(20, 5), rpois(20, 8)),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:4), each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician"
  ))

  expect_output(print(result), "Negative Binomial GLMM")
  expect_output(print(result), "Dispersion")
})

# Test 12: print method with custom digits parameter
test_that("print.mysterycall_nb_model respects digits parameter", {
  skip_if_not_installed("glmmTMB")

  set.seed(309)
  df <- data.frame(
    wait_days = c(rpois(20, 5), rpois(20, 8)),
    insurance = rep(c("Medicaid", "BCBS"), each = 20),
    physician = rep(paste0("Dr_", 1:4), each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician"
  ))

  expect_output(print(result, digits = 2))
  expect_output(print(result, digits = 4))
})

# Test 13: factor reference levels detected
test_that("mysterycall_nb_model identifies factor reference levels", {
  skip_if_not_installed("glmmTMB")

  set.seed(310)
  df <- data.frame(
    wait_days = c(rpois(25, 5), rpois(25, 8)),
    insurance = factor(rep(c("BCBS", "Medicaid"), length.out = 50),
                       levels = c("BCBS", "Medicaid")),
    physician = rep(paste0("Dr_", 1:5), each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician"
  ))

  expect_true("insurance" %in% names(result$factor_refs))
  expect_equal(result$factor_refs$insurance, "BCBS")
})

# Test 14: theta and overdispersion are numeric
test_that("mysterycall_nb_model returns numeric theta and overdispersion", {
  skip_if_not_installed("glmmTMB")

  set.seed(311)
  df <- data.frame(
    wait_days = c(rpois(30, 5), rpois(30, 8)),
    insurance = rep(c("Medicaid", "BCBS"), each = 30),
    physician = rep(paste0("Dr_", 1:5), each = 12),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician"
  ))

  expect_true(is.numeric(result$theta))
  expect_true(length(result$theta) == 1L)
  expect_true(is.numeric(result$overdispersion))
  expect_true(length(result$overdispersion) == 1L)
})

# Test 15: convergence field structure
test_that("mysterycall_nb_model convergence field has correct structure", {
  skip_if_not_installed("glmmTMB")

  set.seed(312)
  df <- data.frame(
    wait_days = c(rpois(25, 5), rpois(25, 8)),
    insurance = rep(c("Medicaid", "BCBS"), length.out = 50),
    physician = rep(paste0("Dr_", 1:5), each = 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_nb_model(
    data = df,
    outcome = "wait_days",
    predictors = "insurance",
    random_intercept = "physician"
  ))

  expect_true(is.list(result$convergence))
  expect_true("converged" %in% names(result$convergence))
  expect_true("messages" %in% names(result$convergence))
  expect_true(is.logical(result$convergence$converged))
  expect_true(is.character(result$convergence$messages))
})
