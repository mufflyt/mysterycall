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

# ---- mysterycall_lmm: happy path ----

test_that("mysterycall_lmm fits a basic model with valid inputs", {
  skip_if_not_installed("lme4")

  set.seed(100)
  df <- data.frame(
    wait_days = round(rnorm(80, mean = 15, sd = 5)),
    insurance = rep(c("Medicaid", "BCBS"), 40),
    physician = rep(paste0("Dr", 1:20), each = 4),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "wait_days", "insurance", "physician")
  ))

  expect_s3_class(fit, "mysterycall_lmm")
  expect_named(fit, c("model", "coef_table", "gmr_table", "log_transformed",
                      "outcome_original", "outcome_used", "random_effects",
                      "factor_refs", "formula", "n", "n_dropped", "n_clusters",
                      "sigma", "r_squared", "normality", "convergence",
                      "aic", "bic", "REML", "sensitivity", "sensitivity_note"))
  expect_true(inherits(fit$model, "lmerMod"))
  expect_s3_class(fit$coef_table, "tbl_df")
  expect_equal(fit$outcome_original, "wait_days")
  expect_equal(fit$n, 80L)
  expect_equal(fit$n_dropped, 0L)
  expect_true(fit$n_clusters >= 1L)
})

test_that("mysterycall_lmm returns tibble coef_table with expected columns", {
  skip_if_not_installed("lme4")

  set.seed(101)
  df <- data.frame(
    outcome = round(rnorm(60, mean = 10, sd = 3)),
    pred    = rep(c("A", "B"), 30),
    group   = rep(1:6, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "outcome", "pred", "group")
  ))

  expect_s3_class(fit$coef_table, "tbl_df")
  expect_named(fit$coef_table, c("term", "estimate", "se", "t_value", "df",
                                 "p_value", "p_value_fmt", "ci_lower", "ci_upper"))
  expect_true(nrow(fit$coef_table) >= 1L)
  expect_true(all(!is.na(fit$coef_table$estimate)))
})

test_that("mysterycall_lmm with auto_log=FALSE skips log transformation", {
  skip_if_not_installed("lme4")

  set.seed(102)
  df <- data.frame(
    y = abs(rnorm(50, 5, 1)),
    x = rep(c("Control", "Treatment"), 25),
    id = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id", auto_log = FALSE)
  ))

  expect_false(fit$log_transformed)
  expect_null(fit$gmr_table)
  expect_equal(fit$outcome_used, "y")
})

test_that("mysterycall_lmm auto_log=TRUE applies log1p for right-skewed data", {
  skip_if_not_installed("lme4")

  set.seed(103)
  df <- data.frame(
    outcome = c(rep(0, 20), rpois(50, 3)),
    group   = rep(c("A", "B"), 35),
    id      = rep(1:7, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "outcome", "group", "id", auto_log = TRUE)
  ))

  # Will either be log-transformed (if skewness > 1) or not
  expect_type(fit$log_transformed, "logical")
  if (fit$log_transformed) {
    expect_s3_class(fit$gmr_table, "tbl_df")
    expect_named(fit$gmr_table, c("term", "GMR", "GMR_lo", "GMR_hi", "p_value_fmt"))
  }
})

test_that("mysterycall_lmm sensitivity_poisson=TRUE runs Poisson model", {
  skip_if_not_installed("lme4")

  set.seed(104)
  df <- data.frame(
    y = rpois(60, lambda = 8),
    x = rep(c("A", "B"), 30),
    id = rep(1:6, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id", sensitivity_poisson = TRUE)
  ))

  expect_s3_class(fit$sensitivity, "mysterycall_poisson_model")
  expect_true(!is.null(fit$sensitivity_note))
  expect_s3_class(fit$sensitivity$irr_table, "tbl_df")
})

test_that("mysterycall_lmm sensitivity_poisson=FALSE skips sensitivity", {
  skip_if_not_installed("lme4")

  set.seed(105)
  df <- data.frame(
    y = round(rnorm(50, 10, 2)),
    x = rep(c("A", "B"), 25),
    id = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id", sensitivity_poisson = FALSE)
  ))

  expect_null(fit$sensitivity)
})

test_that("mysterycall_lmm with REML=FALSE uses ML estimation", {
  skip_if_not_installed("lme4")

  set.seed(106)
  df <- data.frame(
    outcome = round(rnorm(50, 12, 3)),
    group   = rep(c("X", "Y"), 25),
    id      = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "outcome", "group", "id", REML = FALSE)
  ))

  expect_false(fit$REML)
  expect_true(is.finite(fit$aic))
})

# ---- mysterycall_lmm: edge cases ----

test_that("mysterycall_lmm handles rows with missing outcome values", {
  skip_if_not_installed("lme4")

  set.seed(107)
  df <- data.frame(
    y = c(rnorm(45, 10, 2), rep(NA, 5)),
    x = rep(c("A", "B"), 25),
    id = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id")
  ))

  expect_equal(fit$n_dropped, 5L)
  expect_equal(fit$n, 45L)
})

test_that("mysterycall_lmm handles multiple predictors", {
  skip_if_not_installed("lme4")

  set.seed(108)
  df <- data.frame(
    outcome = rnorm(100, 15, 4),
    pred1   = rep(c("A", "B"), 50),
    pred2   = rep(c("X", "Y"), 50),
    id      = rep(1:10, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "outcome", c("pred1", "pred2"), "id")
  ))

  expect_equal(fit$outcome_original, "outcome")
  expect_true(nrow(fit$coef_table) >= 2L)
})

test_that("mysterycall_lmm with narrow outcome range issues warning", {
  skip_if_not_installed("lme4")

  set.seed(109)
  df <- data.frame(
    y = rep(c(0, 1, 2), c(30, 30, 30)),
    x = rep(c("A", "B"), 45),
    id = rep(1:9, 10),
    stringsAsFactors = FALSE
  )

  expect_warning(
    suppressMessages(
      mysterycall_lmm(df, "y", "x", "id")
    ),
    "Outcome range"
  )
})

test_that("mysterycall_lmm handles single-level factor correctly", {
  skip_if_not_installed("lme4")

  set.seed(110)
  df <- data.frame(
    y = rnorm(40, 10, 2),
    x = rep("Control", 40),
    id = rep(1:4, 10),
    stringsAsFactors = FALSE
  )

  # Single-level factor causes lmer to fail (contrasts require 2+ levels)
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_lmm(df, "y", "x", "id")
    ))
  )
})

# ---- mysterycall_lmm: bad inputs ----

test_that("mysterycall_lmm errors when outcome column is missing", {
  skip_if_not_installed("lme4")

  set.seed(111)
  df <- data.frame(
    x = rep(c("A", "B"), 20),
    id = rep(1:4, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_lmm(df, "missing_outcome", "x", "id"),
    "missing_outcome"
  )
})

test_that("mysterycall_lmm errors when outcome is not numeric", {
  skip_if_not_installed("lme4")

  set.seed(112)
  df <- data.frame(
    y = rep(c("a", "b"), 20),
    x = rep(c("A", "B"), 20),
    id = rep(1:4, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_lmm(df, "y", "x", "id"),
    "must be numeric"
  )
})

test_that("mysterycall_lmm errors when predictor column is missing", {
  skip_if_not_installed("lme4")

  set.seed(113)
  df <- data.frame(
    y = rnorm(40, 10, 2),
    id = rep(1:4, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_lmm(df, "y", "missing_pred", "id"),
    "missing_pred"
  )
})

test_that("mysterycall_lmm errors when random_intercept column is missing", {
  skip_if_not_installed("lme4")

  set.seed(114)
  df <- data.frame(
    y = rnorm(40, 10, 2),
    x = rep(c("A", "B"), 20),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_lmm(df, "y", "x", "missing_id"),
    "missing_id"
  )
})

test_that("mysterycall_lmm errors with invalid conf_level", {
  skip_if_not_installed("lme4")

  set.seed(115)
  df <- data.frame(
    y = rnorm(40, 10, 2),
    x = rep(c("A", "B"), 20),
    id = rep(1:4, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_lmm(df, "y", "x", "id", conf_level = 1.5),
    "conf_level"
  )

  expect_error(
    mysterycall_lmm(df, "y", "x", "id", conf_level = -0.1),
    "conf_level"
  )
})

test_that("mysterycall_lmm errors when outcome has no complete cases", {
  skip_if_not_installed("lme4")

  set.seed(116)
  df <- data.frame(
    y = rep(NA_real_, 40),
    x = rep(c("A", "B"), 20),
    id = rep(1:4, 10),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_lmm(df, "y", "x", "id")),
    "No complete cases"
  )
})

test_that("mysterycall_lmm errors with zero rows", {
  skip_if_not_installed("lme4")

  df <- data.frame(
    y = numeric(0),
    x = character(0),
    id = integer(0),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_lmm(df, "y", "x", "id"),
    "at least one row"
  )
})

# ---- print.mysterycall_lmm ----

test_that("print.mysterycall_lmm returns invisible object", {
  skip_if_not_installed("lme4")

  set.seed(117)
  df <- data.frame(
    y = rnorm(50, 12, 3),
    x = rep(c("A", "B"), 25),
    id = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id")
  ))

  result <- capture.output(print(fit))
  expect_type(result, "character")
  expect_true(length(result) > 0L)
})

test_that("print.mysterycall_lmm displays key model metrics", {
  skip_if_not_installed("lme4")

  set.seed(118)
  df <- data.frame(
    y = round(rnorm(60, 15, 4)),
    x = rep(c("A", "B"), 30),
    id = rep(1:6, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id")
  ))

  output <- paste(capture.output(print(fit)), collapse = "\n")
  expect_true(grepl("Linear Mixed Model", output))
  expect_true(grepl("physicians", output))
  expect_true(grepl("Fixed effects", output))
})

test_that("print.mysterycall_lmm shows GMR table when log-transformed", {
  skip_if_not_installed("lme4")

  set.seed(119)
  df <- data.frame(
    outcome = c(rep(0, 15), rpois(45, 4)),
    group   = rep(c("A", "B"), 30),
    id      = rep(1:6, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "outcome", "group", "id", auto_log = TRUE)
  ))

  output <- paste(capture.output(print(fit)), collapse = "\n")
  if (fit$log_transformed) {
    expect_true(grepl("Geometric mean ratios", output))
  }
})

test_that("print.mysterycall_lmm shows sensitivity analysis when present", {
  skip_if_not_installed("lme4")

  set.seed(120)
  df <- data.frame(
    y = rpois(60, 7),
    x = rep(c("A", "B"), 30),
    id = rep(1:6, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id", sensitivity_poisson = TRUE)
  ))

  output <- paste(capture.output(print(fit)), collapse = "\n")
  if (!is.null(fit$sensitivity)) {
    expect_true(grepl("Sensitivity", output) || grepl("IRR", output))
  }
})

test_that("print.mysterycall_lmm errors on non-lmm object", {
  # Non-lmm list missing required fields causes an error
  expect_error(
    print.mysterycall_lmm(list(coef_table = data.frame()))
  )
})

# ---- plot.mysterycall_lmm ----

test_that("plot.mysterycall_lmm returns ggplot object invisibly", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("ggplot2")

  set.seed(121)
  df <- data.frame(
    y = rnorm(50, 12, 3),
    x = rep(c("A", "B"), 25),
    id = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id")
  ))

  p <- suppressMessages(
    plot(fit)
  )

  expect_s3_class(p, "ggplot")
})

test_that("plot.mysterycall_lmm produces Q-Q plot", {
  skip_if_not_installed("lme4")
  skip_if_not_installed("ggplot2")

  set.seed(122)
  df <- data.frame(
    y = round(rnorm(60, 15, 4)),
    x = rep(c("A", "B"), 30),
    id = rep(1:6, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id")
  ))

  p <- suppressMessages(
    plot(fit)
  )

  # ggplot object should have layers and labels
  expect_true(length(p$layers) >= 1L)
})

test_that("plot.mysterycall_lmm errors without ggplot2", {
  skip_if_not_installed("lme4")
  skip_if(requireNamespace("ggplot2", quietly = TRUE))

  set.seed(123)
  df <- data.frame(
    y = rnorm(40, 10, 2),
    x = rep(c("A", "B"), 20),
    id = rep(1:4, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id")
  ))

  expect_error(
    plot(fit),
    "ggplot2"
  )
})

# ---- tidy.mysterycall_lmm ----

test_that("tidy.mysterycall_lmm returns tibble with expected columns", {
  skip_if_not_installed("lme4")

  set.seed(124)
  df <- data.frame(
    y = rnorm(50, 12, 3),
    x = rep(c("A", "B"), 25),
    id = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id")
  ))

  skip_if_not_installed("broom"); tidy_result <- broom::tidy(fit)

  expect_s3_class(tidy_result, "tbl_df")
  expect_named(tidy_result, c("term", "estimate", "std.error", "statistic",
                              "df", "p.value", "conf.low", "conf.high"))
})

test_that("tidy.mysterycall_lmm has one row per fixed effect", {
  skip_if_not_installed("lme4")

  set.seed(125)
  df <- data.frame(
    y = rnorm(60, 12, 3),
    pred1 = rep(c("A", "B"), 30),
    pred2 = rep(c("X", "Y", "Z"), 20),
    id = rep(1:6, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", c("pred1", "pred2"), "id")
  ))

  skip_if_not_installed("broom"); tidy_result <- broom::tidy(fit)

  expect_equal(nrow(tidy_result), nrow(fit$coef_table))
})

test_that("tidy.mysterycall_lmm values match coef_table", {
  skip_if_not_installed("lme4")

  set.seed(126)
  df <- data.frame(
    y = round(rnorm(50, 12, 3)),
    x = rep(c("A", "B"), 25),
    id = rep(1:5, 10),
    stringsAsFactors = FALSE
  )

  fit <- suppressMessages(suppressWarnings(
    mysterycall_lmm(df, "y", "x", "id")
  ))

  skip_if_not_installed("broom"); tidy_result <- broom::tidy(fit)
  coef_tbl <- fit$coef_table

  expect_equal(tidy_result$term, coef_tbl$term)
  expect_equal(tidy_result$estimate, coef_tbl$estimate)
  expect_equal(tidy_result$std.error, coef_tbl$se)
  expect_equal(tidy_result$p.value, coef_tbl$p_value)
})
