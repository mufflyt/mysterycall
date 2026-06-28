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


# ============================================================================
# mysterycall_logistic_model() - HAPPY PATH
# ============================================================================

test_that("mysterycall_logistic_model: happy path with valid binary outcome", {
  skip_if_not_installed("lme4")

  set.seed(101)
  df <- data.frame(
    offered   = rbinom(80, 1L, 0.7),
    insurance = rep(c("Medicaid", "BCBS"), 40),
    physician = rep(paste0("Dr", 1:20), each = 4L),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(
    mysterycall_logistic_model(df, "offered", "insurance", "physician")
  )

  expect_s3_class(fit, "mysterycall_logistic_model")
  expect_type(fit, "list")
  expect_named(fit, c("model", "or_table", "random_effects", "factor_refs",
                      "formula", "n", "n_dropped", "n_clusters",
                      "convergence", "aic", "bic"))
  expect_equal(fit$n, 80)
  expect_equal(fit$n_dropped, 0)
  expect_equal(fit$n_clusters, 20)
})

test_that("mysterycall_logistic_model: happy path with logical outcome (TRUE/FALSE)", {
  skip_if_not_installed("lme4")

  set.seed(102)
  df <- data.frame(
    offered   = c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE),
    insurance = rep(c("Medicaid", "BCBS"), 3),
    physician = rep(c("A", "B"), each = 3),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_logistic_model(df, "offered", "insurance", "physician")
  ))

  expect_s3_class(fit, "mysterycall_logistic_model")
  expect_equal(fit$n, 6)
})

test_that("mysterycall_logistic_model: happy path with multiple predictors", {
  skip_if_not_installed("lme4")

  set.seed(103)
  df <- data.frame(
    offered   = rbinom(60, 1, 0.6),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    specialty = rep(c("OB/GYN", "Surgery"), 30),
    physician = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_logistic_model(df, "offered", c("insurance", "specialty"), "physician")
  ))

  expect_s3_class(fit, "mysterycall_logistic_model")
  expect_true(nrow(fit$or_table) >= 2)
  expect_setequal(names(fit$factor_refs), c("insurance", "specialty"))
})

# ============================================================================
# mysterycall_logistic_model() - EDGE CASES
# ============================================================================

test_that("mysterycall_logistic_model: edge case with missing values", {
  skip_if_not_installed("lme4")

  set.seed(104)
  df <- data.frame(
    offered   = c(rbinom(50, 1, 0.65), rep(NA, 10)),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    physician = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(
    mysterycall_logistic_model(df, "offered", "insurance", "physician")
  )

  expect_s3_class(fit, "mysterycall_logistic_model")
  expect_equal(fit$n, 50)
  expect_equal(fit$n_dropped, 10)
})

test_that("mysterycall_logistic_model: alternative conf_level (0.90)", {
  skip_if_not_installed("lme4")

  set.seed(105)
  df <- data.frame(
    offered   = rbinom(60, 1, 0.65),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    physician = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(
    mysterycall_logistic_model(df, "offered", "insurance", "physician", conf_level = 0.90)
  )

  expect_s3_class(fit, "mysterycall_logistic_model")
  expect_equal(fit$n, 60)
  expect_true(all(is.finite(fit$or_table$ci_lower)))
  expect_true(all(is.finite(fit$or_table$ci_upper)))
})

# ============================================================================
# mysterycall_logistic_model() - ERROR CASES
# ============================================================================

test_that("mysterycall_logistic_model: error on non-binary outcome", {
  skip_if_not_installed("lme4")

  df <- data.frame(
    outcome   = c(0, 1, 2, 3),
    insurance = c("A", "B", "A", "B"),
    physician = c("Dr1", "Dr1", "Dr2", "Dr2"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_logistic_model(df, "outcome", "insurance", "physician"),
    "must be binary"
  )
})

test_that("mysterycall_logistic_model: error on missing columns", {
  skip_if_not_installed("lme4")

  df <- data.frame(
    outcome = c(0, 1, 0, 1),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_logistic_model(df, "outcome", "missing_col", "physician"),
    "Required columns"
  )
})

test_that("mysterycall_logistic_model: error on outcome vector (not scalar)", {
  skip_if_not_installed("lme4")

  df <- data.frame(
    out1 = c(0, 1, 0, 1),
    out2 = c(1, 0, 1, 0),
    insurance = c("A", "B", "A", "B"),
    physician = c("Dr1", "Dr1", "Dr2", "Dr2"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_logistic_model(df, c("out1", "out2"), "insurance", "physician"),
    "single column name"
  )
})

test_that("mysterycall_logistic_model: error on invalid conf_level", {
  skip_if_not_installed("lme4")

  set.seed(106)
  df <- data.frame(
    offered   = rbinom(20, 1L, 0.7),
    insurance = rep(c("Medicaid", "BCBS"), 10),
    physician = rep(paste0("Dr", 1:5), each = 4L),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_logistic_model(df, "offered", "insurance", "physician", conf_level = 1.5),
    "between 0 and 1"
  )
})

test_that("mysterycall_logistic_model: error on conf_level = 0", {
  skip_if_not_installed("lme4")

  set.seed(107)
  df <- data.frame(
    offered   = rbinom(20, 1L, 0.7),
    insurance = rep(c("Medicaid", "BCBS"), 10),
    physician = rep(paste0("Dr", 1:5), each = 4L),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_logistic_model(df, "offered", "insurance", "physician", conf_level = 0),
    "between 0 and 1"
  )
})

# ============================================================================
# print.mysterycall_logistic_model() - HAPPY PATH
# ============================================================================

test_that("print.mysterycall_logistic_model: basic output structure", {
  skip_if_not_installed("lme4")

  set.seed(108)
  df <- data.frame(
    offered   = rbinom(60, 1, 0.65),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    physician = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(
    mysterycall_logistic_model(df, "offered", "insurance", "physician")
  )

  output <- capture.output(suppressMessages(print(fit)))
  expect_true(length(output) > 0)
  expect_true(any(grepl("Logistic GLMER", output)))
  expect_true(any(grepl("physicians", output)))
})

test_that("print.mysterycall_logistic_model: custom digits parameter", {
  skip_if_not_installed("lme4")

  set.seed(109)
  df <- data.frame(
    offered   = rbinom(60, 1, 0.65),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    physician = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(
    mysterycall_logistic_model(df, "offered", "insurance", "physician")
  )

  output <- capture.output(suppressMessages(print(fit, digits = 2)))
  expect_true(length(output) > 0)
})

test_that("print.mysterycall_logistic_model: returns invisible(x)", {
  skip_if_not_installed("lme4")

  set.seed(110)
  df <- data.frame(
    offered   = rbinom(60, 1, 0.65),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    physician = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(
    mysterycall_logistic_model(df, "offered", "insurance", "physician")
  )

  result <- suppressMessages(print(fit))
  expect_identical(result, fit)
})

# ============================================================================
# tidy.mysterycall_logistic_model() - HAPPY PATH
# ============================================================================

test_that("tidy.mysterycall_logistic_model: basic output structure", {
  skip_if_not_installed("lme4")

  set.seed(111)
  df <- data.frame(
    offered   = rbinom(60, 1, 0.65),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    physician = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(
    mysterycall_logistic_model(df, "offered", "insurance", "physician")
  )

  tidy_result <- mysterycall:::tidy.mysterycall_logistic_model(fit)

  expect_s3_class(tidy_result, "tbl_df")
  expect_named(tidy_result, c("term", "estimate", "std.error", "statistic",
                              "p.value", "conf.low", "conf.high"))
})

test_that("tidy.mysterycall_logistic_model: column types and content", {
  skip_if_not_installed("lme4")

  set.seed(112)
  df <- data.frame(
    offered   = rbinom(60, 1, 0.65),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    specialty = rep(c("OB/GYN", "Surgery"), 30),
    physician = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_logistic_model(df, "offered", c("insurance", "specialty"), "physician")
  ))

  tidy_result <- mysterycall:::tidy.mysterycall_logistic_model(fit)

  expect_type(tidy_result$term, "character")
  expect_type(tidy_result$estimate, "double")
  expect_type(tidy_result$std.error, "double")
  expect_type(tidy_result$statistic, "double")
  expect_type(tidy_result$p.value, "double")
  expect_type(tidy_result$conf.low, "double")
  expect_type(tidy_result$conf.high, "double")
  expect_true(all(is.finite(tidy_result$estimate)))
  expect_true(all(is.finite(tidy_result$p.value)))
})

test_that("tidy.mysterycall_logistic_model: no NA in critical columns", {
  skip_if_not_installed("lme4")

  set.seed(113)
  df <- data.frame(
    offered   = rbinom(60, 1, 0.65),
    insurance = rep(c("Medicaid", "BCBS"), 30),
    physician = rep(paste0("Dr", 1:10), each = 6),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(
    mysterycall_logistic_model(df, "offered", "insurance", "physician")
  )

  tidy_result <- mysterycall:::tidy.mysterycall_logistic_model(fit)

  expect_false(any(is.na(tidy_result$term)))
  expect_false(any(is.na(tidy_result$estimate)))
  expect_false(any(is.na(tidy_result$p.value)))
})
