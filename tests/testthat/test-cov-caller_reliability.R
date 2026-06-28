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

# ---- Test mysterycall_caller_reliability() ----

test_that("mysterycall_caller_reliability with gold_col computes kappa", {
  df <- data.frame(
    caller  = c("A", "A", "B", "B"),
    outcome = c(1, 0, 1, 0),
    gold    = c(1, 0, 1, 1),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", gold_col = "gold"))

  expect_s3_class(res, "mysterycall_reliability")
  expect_named(res, c("type", "statistic", "lower_ci", "upper_ci", "n_pairs", "interpretation"))
  expect_equal(res$type, "kappa")
  expect_equal(res$n_pairs, 4)
  expect_true(is.numeric(res$statistic))
  expect_true(is.numeric(res$lower_ci))
  expect_true(is.numeric(res$upper_ci))
})

test_that("mysterycall_caller_reliability with pair_col reshapes wide and computes", {
  set.seed(2)
  df <- data.frame(
    caller = rep(c("A", "B"), each = 30),
    pair   = c(1:30, 1:30),
    outcome = c(rbinom(30, 1, 0.6), rbinom(30, 1, 0.6)),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", pair_col = "pair"))

  expect_s3_class(res, "mysterycall_reliability")
  expect_equal(res$n_pairs, 30)
  expect_equal(res$type, "kappa")
  expect_true(is.numeric(res$statistic))
})

test_that("mysterycall_caller_reliability auto-detects icc for continuous outcomes", {
  set.seed(3)
  df <- data.frame(
    caller = rep(c("A", "B"), each = 30),
    pair   = c(1:30, 1:30),
    outcome = c(rnorm(30, 5, 2), rnorm(30, 5, 2)),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", pair_col = "pair", type = "auto"))

  expect_equal(res$type, "icc")
  expect_true(is.numeric(res$statistic))
  expect_equal(res$n_pairs, 30)
})

test_that("mysterycall_caller_reliability computes percent_agreement for factors", {
  set.seed(4)
  df <- data.frame(
    caller = rep(c("A", "B"), each = 30),
    pair   = c(1:30, 1:30),
    outcome = factor(c(sample(c("yes", "no"), 30, replace = TRUE),
                      sample(c("yes", "no"), 30, replace = TRUE))),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", pair_col = "pair", type = "percent_agreement"))

  expect_equal(res$type, "percent_agreement")
  expect_true(res$statistic >= 0 && res$statistic <= 100)
  expect_equal(res$n_pairs, 30)
})

test_that("mysterycall_caller_reliability fallback compares first two callers", {
  set.seed(5)
  df <- data.frame(
    caller = rep(c("A", "B"), each = 30),
    outcome = c(rbinom(30, 1, 0.5), rbinom(30, 1, 0.5)),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome"))

  expect_equal(res$n_pairs, 30)
  expect_equal(res$type, "kappa")
})

test_that("mysterycall_caller_reliability excludes NA values from pairs", {
  df <- data.frame(
    caller = c("A", "A", "A", "B", "B", "B"),
    outcome = c(1, NA, 1, 0, 0, 0),
    gold = c(1, 0, NA, 1, 1, 1),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", gold_col = "gold"))

  # Rows with both outcome and gold non-NA: rows 1, 4, 5, 6 = 4 pairs
  expect_equal(res$n_pairs, 4)
})

test_that("mysterycall_caller_reliability warns with fewer than 30 pairs", {
  df <- data.frame(
    caller = c("A", "A", "B", "B"),
    outcome = c(1, 0, 1, 0),
    gold = c(1, 0, 1, 1),
    stringsAsFactors = FALSE
  )
  expect_message(
    mysterycall_caller_reliability(df, "caller", "outcome", gold_col = "gold"),
    "Only.*complete pair"
  )
})

test_that("mysterycall_caller_reliability errors on missing required column", {
  df <- data.frame(
    caller = c("A", "B"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_caller_reliability(df, "missing_col", "outcome"),
    "not found"
  )
})

test_that("mysterycall_caller_reliability errors when fewer than 2 callers", {
  df <- data.frame(
    caller = c("A", "A"),
    outcome = c(1, 0),
    stringsAsFactors = FALSE
  )
  expect_error(
    mysterycall_caller_reliability(df, "caller", "outcome"),
    "at least 2 callers"
  )
})

test_that("mysterycall_caller_reliability validates alpha parameter", {
  df <- data.frame(
    caller = c("A", "A", "B", "B"),
    outcome = c(1, 0, 1, 0),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", alpha = 1.5)),
    "alpha"
  )
})

test_that("mysterycall_caller_reliability kappa has Landis & Koch interpretation", {
  df <- data.frame(
    caller = c("A", "A", "B", "B"),
    outcome = c(1, 0, 1, 0),
    gold = c(1, 0, 1, 1),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", gold_col = "gold", type = "kappa"))

  expect_true(!is.na(res$interpretation))
  expect_true(res$interpretation %in% c("poor", "fair", "moderate", "good", "excellent"))
})

test_that("mysterycall_caller_reliability icc has NA interpretation", {
  set.seed(6)
  df <- data.frame(
    caller = rep(c("A", "B"), each = 30),
    pair   = c(1:30, 1:30),
    outcome = c(rnorm(30, 5, 2), rnorm(30, 5, 2)),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", pair_col = "pair", type = "icc"))

  expect_true(is.na(res$interpretation))
})

test_that("mysterycall_caller_reliability percent_agreement has NA interpretation", {
  set.seed(7)
  df <- data.frame(
    caller = rep(c("A", "B"), each = 30),
    pair   = c(1:30, 1:30),
    outcome = c(sample(c("x", "y"), 30, replace = TRUE),
                sample(c("x", "y"), 30, replace = TRUE)),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", pair_col = "pair", type = "percent_agreement"))

  expect_true(is.na(res$interpretation))
})

test_that("mysterycall_caller_reliability respects invalid type argument", {
  df <- data.frame(
    caller = c("A", "A", "B", "B"),
    outcome = c(1, 0, 1, 0),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", type = "invalid")),
    "should be one of"
  )
})

# ---- Test print.mysterycall_reliability() ----

test_that("print.mysterycall_reliability displays header and elements", {
  df <- data.frame(
    caller = c("A", "A", "B", "B"),
    outcome = c(1, 0, 1, 0),
    gold = c(1, 0, 1, 1),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", gold_col = "gold"))

  output <- capture.output(print(res))
  expect_true(any(grepl("mysterycall_caller_reliability", output)))
  expect_true(any(grepl("Method", output)))
  expect_true(any(grepl("Statistic", output)))
  expect_true(any(grepl("95% CI", output)))
  expect_true(any(grepl("N pairs", output)))
})

test_that("print.mysterycall_reliability shows interpretation for kappa", {
  df <- data.frame(
    caller = c("A", "A", "B", "B"),
    outcome = c(1, 0, 1, 0),
    gold = c(1, 0, 1, 1),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", gold_col = "gold", type = "kappa"))

  output <- capture.output(print(res))
  expect_true(any(grepl("Interpretation", output)))
})

test_that("print.mysterycall_reliability returns object invisibly", {
  df <- data.frame(
    caller = c("A", "A", "B", "B"),
    outcome = c(1, 0, 1, 0),
    gold = c(1, 0, 1, 1),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(mysterycall_caller_reliability(df, "caller", "outcome", gold_col = "gold"))

  result <- invisible(print(res))
  expect_equal(result, res)
})
