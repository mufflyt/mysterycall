library(testthat)
library(mysterycall)

# Tests that verify error messages are actionable:
# each error should tell the user WHAT went wrong, WHAT was expected,
# and HOW to fix it (available columns, install commands, counts found).

# ── mysterycall_sensitivity() ─────────────────────────────────────────────────

test_that("sensitivity: wrong data type names the received type", {
  expect_error(
    mysterycall_sensitivity("not_a_df", "wait", "ins", "npi"),
    "not character"
  )
})

test_that("sensitivity: missing outcome column shows available columns", {
  df <- data.frame(wait = 1:4, ins = c("M","B","M","B"), npi = 1:4)
  err <- tryCatch(
    mysterycall_sensitivity(df, "typo_col", "ins", "npi"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "typo_col")
  expect_match(err, "Available columns")
  expect_match(err, "wait")
})

test_that("sensitivity: missing predictor column shows available columns", {
  df <- data.frame(wait = 1:4, ins = c("M","B","M","B"), npi = 1:4)
  err <- tryCatch(
    mysterycall_sensitivity(df, "wait", "bad_pred", "npi"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "bad_pred")
  expect_match(err, "Available columns")
})

test_that("sensitivity: missing random_intercept column shows available columns", {
  df <- data.frame(wait = 1:4, ins = c("M","B","M","B"), npi = 1:4)
  err <- tryCatch(
    mysterycall_sensitivity(df, "wait", "ins", "bad_cluster"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "bad_cluster")
  expect_match(err, "Available columns")
})

test_that("sensitivity: glmmTMB missing error includes install command", {
  skip_if(requireNamespace("glmmTMB", quietly = TRUE), "glmmTMB is installed")
  skip_if_not_installed("lme4")
  set.seed(1)
  df <- data.frame(
    wait = rpois(40L, 10L),
    ins  = rep(c("M","B"), 20L),
    npi  = rep(paste0("Dr", 1:10), 4L)
  )
  err <- tryCatch(
    suppressMessages(mysterycall_sensitivity(df, "wait", "ins", "npi", family = "nb")),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "install.packages")
  expect_match(err, "glmmTMB")
})


# ── mysterycall_compare_waves() ───────────────────────────────────────────────

test_that("compare_waves: missing wave_col shows available columns", {
  df <- data.frame(wave = c(1L,2L), offered = c(1L,0L))
  err <- tryCatch(
    mysterycall_compare_waves(df, "typo_wave", "offered"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "typo_wave")
  expect_match(err, "Available columns")
  expect_match(err, "wave")
})

test_that("compare_waves: missing outcome_col shows available columns", {
  df <- data.frame(wave = c(1L,2L), offered = c(1L,0L))
  err <- tryCatch(
    mysterycall_compare_waves(df, "wave", "typo_outcome"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "typo_outcome")
  expect_match(err, "Available columns")
})

test_that("compare_waves: single wave shows count and value", {
  df <- data.frame(wave = rep(1L, 10L), offered = rbinom(10L, 1L, 0.5))
  err <- tryCatch(
    mysterycall_compare_waves(df, "wave", "offered"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "found 1")
  expect_match(err, "1")   # the actual wave value
})

test_that("compare_waves: bad ref_wave shows available wave values", {
  df <- data.frame(wave = c(1L,1L,2L,2L), offered = c(1L,0L,1L,1L))
  err <- tryCatch(
    mysterycall_compare_waves(df, "wave", "offered", ref_wave = 99L),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "99")
  expect_match(err, "Available wave values")
})


# ── mysterycall_caller_drift() ────────────────────────────────────────────────

test_that("caller_drift: missing outcome_col shows available columns", {
  df <- data.frame(seq = 1:5, offered = c(1,0,1,1,0))
  err <- tryCatch(
    mysterycall_caller_drift(df, outcome_col = "bad_col", call_seq_col = "seq"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "bad_col")
  expect_match(err, "Available columns")
})

test_that("caller_drift: missing date_col shows available columns", {
  df <- data.frame(seq = 1:5, offered = c(1,0,1,1,0))
  err <- tryCatch(
    mysterycall_caller_drift(df, outcome_col = "offered", date_col = "missing_date"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "missing_date")
  expect_match(err, "Available columns")
})

test_that("caller_drift: missing call_seq_col shows available columns", {
  df <- data.frame(date = Sys.Date(), offered = 1L)
  err <- tryCatch(
    mysterycall_caller_drift(df, outcome_col = "offered", call_seq_col = "bad_seq"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "bad_seq")
  expect_match(err, "Available columns")
})


# ── mysterycall_missing_data_analysis() ──────────────────────────────────────

test_that("missing_data_analysis: wrong data type names received type", {
  err <- tryCatch(
    mysterycall_missing_data_analysis(list(a = 1), "a"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "list")
})

test_that("missing_data_analysis: missing outcome_col shows available columns", {
  df <- data.frame(appt = c(1L, NA), ins = c("M","B"))
  err <- tryCatch(
    mysterycall_missing_data_analysis(df, "typo", group_col = "ins"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "typo")
  expect_match(err, "Available columns")
  expect_match(err, "appt")
})

test_that("missing_data_analysis: missing group_col shows available columns", {
  df <- data.frame(appt = c(1L, NA), ins = c("M","B"))
  err <- tryCatch(
    mysterycall_missing_data_analysis(df, "appt", group_col = "bad_group"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "bad_group")
  expect_match(err, "Available columns")
})

test_that("missing_data_analysis: bad covariate shows which column is missing", {
  df <- data.frame(appt = c(1L, NA), ins = c("M","B"))
  err <- tryCatch(
    mysterycall_missing_data_analysis(df, "appt", covariate_cols = "nonexistent"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "nonexistent")
  expect_match(err, "Available columns")
})


# ── mysterycall_select_best_model() ──────────────────────────────────────────

test_that("select_best_model: unnamed list includes example in error", {
  m <- glm(mpg ~ wt, data = mtcars)
  err <- tryCatch(
    mysterycall_select_best_model(list(m)),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "named list")
  expect_match(err, "Example")
})

test_that("select_best_model: LRT with 1 model shows count and guidance", {
  m <- glm(mpg ~ wt, data = mtcars)
  err <- tryCatch(
    mysterycall_select_best_model(list(only = m), criterion = "lrt"),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "1 provided")
  expect_match(err, "2 or more")
})
