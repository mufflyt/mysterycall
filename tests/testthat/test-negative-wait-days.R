library(testthat)
library(mysterycall)

# Tests that negative wait days are caught BEFORE any model runs.
# Negative days are impossible in a mystery-caller study — they indicate
# a date calculation bug (e.g. appointment date < call date) or data entry error.

# ── Shared fixtures ───────────────────────────────────────────────────────────

make_df <- function(wait, insurance = NULL, npi = NULL) {
  n <- length(wait)
  data.frame(
    wait_days = wait,
    insurance = if (!is.null(insurance)) insurance else rep(c("Medicaid","BCBS"), length.out = n),
    npi       = if (!is.null(npi)) npi else rep(paste0("Dr", 1:10), length.out = n),
    stringsAsFactors = FALSE
  )
}

# ── mysterycall_simple_poisson() ──────────────────────────────────────────────

test_that("simple_poisson errors on any negative wait day", {
  df <- make_df(c(5L, -1L, 3L, 7L))
  expect_error(
    suppressMessages(mysterycall_simple_poisson(df, outcome = "wait_days", group = "insurance")),
    "negative"
  )
})

test_that("simple_poisson error names the column, count, and minimum", {
  df <- make_df(c(10L, -3L, -7L, 8L))
  err <- tryCatch(
    suppressMessages(mysterycall_simple_poisson(df, outcome = "wait_days", group = "insurance")),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "wait_days")
  expect_match(err, "2")         # 2 negative values
  expect_match(err, "-7")        # minimum value
  expect_match(err, "impossible|date calculation|data entry")
})

test_that("simple_poisson accepts zero wait days (same-day appointment)", {
  df <- make_df(c(0L, 0L, 3L, 5L))
  expect_no_error(
    suppressMessages(
      mysterycall_simple_poisson(df, outcome = "wait_days", group = "insurance")
    )
  )
})

test_that("simple_poisson with all-NA outcome does not false-positive on negative check", {
  df <- make_df(c(NA_integer_, NA_integer_, 5L, 3L))
  expect_no_error(
    suppressMessages(
      mysterycall_simple_poisson(df, outcome = "wait_days", group = "insurance")
    )
  )
})

# ── mysterycall_auto_model() ──────────────────────────────────────────────────

test_that("auto_model errors on negative wait day before fitting any model", {
  skip_if_not_installed("lme4")
  df <- make_df(c(5L, 12L, -2L, 8L, 3L, 10L, 7L, 4L, 6L, 9L))
  expect_error(
    suppressMessages(
      mysterycall_auto_model(
        df,
        outcome          = "wait_days",
        predictors       = "insurance",
        random_intercept = "npi"
      )
    ),
    "negative|impossible"
  )
})

test_that("auto_model error names the outcome column and minimum value", {
  skip_if_not_installed("lme4")
  set.seed(1)
  n <- 40L
  df <- make_df(
    c(-5L, rpois(n - 1L, 10L)),
    insurance = rep(c("Medicaid","BCBS"), length.out = n),
    npi       = rep(paste0("Dr", 1:10), length.out = n)
  )
  err <- tryCatch(
    suppressMessages(
      mysterycall_auto_model(
        df,
        outcome          = "wait_days",
        predictors       = "insurance",
        random_intercept = "npi"
      )
    ),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "wait_days")
  expect_match(err, "-5")
})

test_that("auto_model proceeds normally with all non-negative outcomes", {
  skip_if_not_installed("lme4")
  set.seed(2)
  n <- 40L
  df <- make_df(
    c(rpois(20L, 18L), rpois(20L, 10L)),
    insurance = rep(c("Medicaid","BCBS"), each = 20L),
    npi       = rep(paste0("Dr", 1:10), length.out = n)
  )
  expect_no_error(
    suppressMessages(
      mysterycall_auto_model(
        df,
        outcome          = "wait_days",
        predictors       = "insurance",
        random_intercept = "npi"
      )
    )
  )
})

# ── mysterycall_check_normality() ─────────────────────────────────────────────

test_that("check_normality warns (not errors) on negative values", {
  df <- data.frame(wait_days = c(5L, -1L, 3L, 7L, 2L))
  expect_warning(
    suppressMessages(mysterycall_check_normality(df, "wait_days")),
    "negative|impossible"
  )
})

test_that("check_normality warning names the column and minimum", {
  df <- data.frame(wait_days = c(10L, -4L, 8L, 6L))
  w <- tryCatch(
    suppressMessages(withCallingHandlers(
      mysterycall_check_normality(df, "wait_days"),
      warning = function(w) { invokeRestart("muffleWarning"); w }
    )),
    warning = function(w) conditionMessage(w)
  )
  # Capture the warning message
  warns <- character(0)
  withCallingHandlers(
    suppressMessages(mysterycall_check_normality(df, "wait_days")),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_true(any(grepl("wait_days", warns)))
  expect_true(any(grepl("-4", warns)))
})

test_that("check_normality does not warn when all values are non-negative", {
  df <- data.frame(wait_days = c(0L, 3L, 7L, 14L, 5L))
  expect_no_warning(
    suppressMessages(mysterycall_check_normality(df, "wait_days"))
  )
})

test_that("check_normality still returns a result even when negatives present", {
  df <- data.frame(wait_days = c(5L, -1L, 3L, 7L))
  result <- suppressWarnings(
    suppressMessages(mysterycall_check_normality(df, "wait_days"))
  )
  expect_true(is.list(result))
  expect_true("is_normal" %in% names(result))
})

# ── Year-typo guard: wait > 365 days ─────────────────────────────────────────
# E.g. appointment date entered as 2027 instead of 2026 → wait = 400 days.
# Should warn (not hard-error) so the analyst sees the problem but still gets
# model output they can inspect.

test_that("simple_poisson warns on wait days > 365 (year typo)", {
  df <- make_df(c(5L, 10L, 400L, 8L))  # 400 = year-typo artifact
  expect_warning(
    suppressMessages(
      mysterycall_simple_poisson(df, outcome = "wait_days", group = "insurance")
    ),
    "365|year.typo|one year"
  )
})

test_that("simple_poisson warning names column, count, and max value", {
  df <- make_df(c(7L, 366L, 400L, 5L))
  warns <- character(0)
  withCallingHandlers(
    suppressMessages(
      mysterycall_simple_poisson(df, outcome = "wait_days", group = "insurance")
    ),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  long_warn <- warns[grepl("365|year", warns, ignore.case = TRUE)]
  expect_gt(length(long_warn), 0L)
  expect_true(any(grepl("wait_days", long_warn)))
  expect_true(any(grepl("400", long_warn)))   # max value
  expect_true(any(grepl("2", long_warn)))     # count of >365 values
})

test_that("simple_poisson does not warn when max wait is exactly 365", {
  df <- make_df(c(5L, 30L, 365L, 90L))
  expect_no_warning(
    suppressMessages(
      mysterycall_simple_poisson(df, outcome = "wait_days", group = "insurance")
    )
  )
})

test_that("auto_model warns on wait days > 365 before fitting", {
  skip_if_not_installed("lme4")
  set.seed(3)
  n <- 40L
  df <- make_df(
    c(400L, rpois(n - 1L, 10L)),
    insurance = rep(c("Medicaid","BCBS"), length.out = n),
    npi       = rep(paste0("Dr", 1:10), length.out = n)
  )
  expect_warning(
    suppressMessages(
      mysterycall_auto_model(
        df, outcome = "wait_days",
        predictors = "insurance", random_intercept = "npi"
      )
    ),
    "365|year.typo|one year"
  )
})

test_that("check_normality warns on wait days > 365", {
  df <- data.frame(wait_days = c(5L, 10L, 400L, 8L))
  warns <- character(0)
  withCallingHandlers(
    suppressMessages(mysterycall_check_normality(df, "wait_days")),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  long_warn <- warns[grepl("365|year", warns, ignore.case = TRUE)]
  expect_gt(length(long_warn), 0L)
  expect_true(any(grepl("wait_days", long_warn)))
  expect_true(any(grepl("400", long_warn)))
})

test_that("check_normality does not warn when all values are <= 365", {
  df <- data.frame(wait_days = c(0L, 14L, 90L, 365L))
  warns <- character(0)
  withCallingHandlers(
    suppressMessages(mysterycall_check_normality(df, "wait_days")),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  long_warn <- warns[grepl("365|year", warns, ignore.case = TRUE)]
  expect_equal(length(long_warn), 0L)
})
