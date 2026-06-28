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
# Test 1: Basic calendar drift only (date_col provided)
# ============================================================================

test_that("mysterycall_caller_drift happy path: calendar drift only", {
  set.seed(42)
  n <- 120L
  df <- data.frame(
    call_date = seq(as.Date("2023-01-02"), by = "day", length.out = n),
    offered   = rbinom(n, 1L, 0.55),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_caller_drift(
    df,
    outcome_col = "offered",
    date_col    = "call_date",
    week_or_day = "week",
    plot        = FALSE
  ))

  expect_s3_class(res, "mysterycall_caller_drift")
  expect_true(is.list(res))
  expect_named(res, c("calendar", "sequence", "plot", "sentence"))

  # Calendar component should exist
  expect_true(!is.null(res$calendar))
  expect_true(is.list(res$calendar))
  expect_named(res$calendar, c("rate_by_period", "slope", "slope_se", "p_value", "p_fmt", "unit", "sentence"))

  # Check rate_by_period structure
  expect_true(is.data.frame(res$calendar$rate_by_period))
  expect_named(res$calendar$rate_by_period, c("period", "time_index", "rate", "n"))
  expect_true(nrow(res$calendar$rate_by_period) > 0L)

  # Check slope is numeric
  expect_true(is.numeric(res$calendar$slope))
  expect_true(is.numeric(res$calendar$slope_se))
  expect_true(is.numeric(res$calendar$p_value))

  # Sentence should be a character string
  expect_true(is.character(res$sentence))
  expect_true(nchar(res$sentence) > 0L)

  # Sequence should be NULL (not provided)
  expect_true(is.null(res$sequence))
})

# ============================================================================
# Test 2: Sequence drift only (call_seq_col provided)
# ============================================================================

test_that("mysterycall_caller_drift happy path: sequence drift only", {
  set.seed(42)
  n <- 100L
  df <- data.frame(
    seq_num = seq_len(n),
    offered = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_caller_drift(
    df,
    outcome_col  = "offered",
    call_seq_col = "seq_num",
    plot         = FALSE
  ))

  expect_s3_class(res, "mysterycall_caller_drift")
  expect_true(!is.null(res$sequence))
  expect_true(is.list(res$sequence))
  expect_named(res$sequence, c("rate_by_seq", "slope", "slope_se", "p_value", "p_fmt", "unit", "sentence"))

  # Check rate_by_seq structure
  expect_true(is.data.frame(res$sequence$rate_by_seq))
  expect_named(res$sequence$rate_by_seq, c("seq_bin", "mean_seq", "rate", "n"))
  expect_true(nrow(res$sequence$rate_by_seq) > 0L)

  # Calendar should be NULL
  expect_true(is.null(res$calendar))
})

# ============================================================================
# Test 3: Both calendar and sequence drift (derived from date/caller)
# ============================================================================

test_that("mysterycall_caller_drift happy path: both calendar and sequence", {
  set.seed(42)
  n <- 120L
  df <- data.frame(
    call_date = seq(as.Date("2023-01-02"), by = "day", length.out = n),
    caller    = rep(c("Alice", "Bob", "Carol"), times = n / 3L),
    offered   = rbinom(n, 1L, 0.55),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_caller_drift(
    df,
    outcome_col = "offered",
    date_col    = "call_date",
    caller_col  = "caller",
    week_or_day = "week",
    plot        = FALSE
  ))

  expect_s3_class(res, "mysterycall_caller_drift")
  expect_true(!is.null(res$calendar))
  expect_true(!is.null(res$sequence))

  # Both should have proper structure
  expect_true(is.data.frame(res$calendar$rate_by_period))
  expect_true(is.data.frame(res$sequence$rate_by_seq))

  # Sentence should reference both
  expect_true(grepl("study period", res$sentence))
  expect_true(grepl("call sequence", res$sentence))
})

# ============================================================================
# Test 4: Edge case - NA values and small sample
# ============================================================================

test_that("mysterycall_caller_drift edge case: NA values", {
  set.seed(42)
  df <- data.frame(
    call_date = seq(as.Date("2023-01-01"), by = "day", length.out = 30),
    offered   = c(rbinom(20, 1L, 0.5), rep(NA, 10)),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(suppressWarnings(mysterycall_caller_drift(
    df,
    outcome_col = "offered",
    date_col    = "call_date",
    plot        = FALSE
  )))

  expect_s3_class(res, "mysterycall_caller_drift")
  # Should handle NA gracefully
  expect_true(!is.null(res$calendar))
})

# ============================================================================
# Test 5: Day-level aggregation instead of week
# ============================================================================

test_that("mysterycall_caller_drift happy path: day-level aggregation", {
  set.seed(42)
  n <- 30L
  df <- data.frame(
    call_date = seq(as.Date("2023-01-01"), by = "day", length.out = n),
    offered   = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_caller_drift(
    df,
    outcome_col = "offered",
    date_col    = "call_date",
    week_or_day = "day",
    plot        = FALSE
  ))

  expect_s3_class(res, "mysterycall_caller_drift")
  expect_true(!is.null(res$calendar))
  expect_equal(res$calendar$unit, "day")
  # Should have day-level periods (YYYY-MM-DD format)
  expect_true(all(grepl("^\\d{4}-\\d{2}-\\d{2}$", res$calendar$rate_by_period$period)))
})

# ============================================================================
# Test 6: Bad input - missing required arguments
# ============================================================================

test_that("mysterycall_caller_drift bad input: neither date_col nor call_seq_col", {
  set.seed(42)
  df <- data.frame(
    offered = rbinom(50, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_caller_drift(df, outcome_col = "offered"),
    "At least one of date_col or call_seq_col must be provided"
  )
})

# ============================================================================
# Test 7: Bad input - outcome column not found
# ============================================================================

test_that("mysterycall_caller_drift bad input: outcome_col not in data", {
  set.seed(42)
  df <- data.frame(
    call_date = seq(as.Date("2023-01-01"), by = "day", length.out = 30),
    other_col = rbinom(30, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_caller_drift(df, outcome_col = "missing_col", date_col = "call_date"),
    "outcome_col.*not found"
  )
})

# ============================================================================
# Test 8: Bad input - date_col not found
# ============================================================================

test_that("mysterycall_caller_drift bad input: date_col not in data", {
  set.seed(42)
  df <- data.frame(
    offered = rbinom(30, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_caller_drift(df, outcome_col = "offered", date_col = "missing_date"),
    "date_col.*not found"
  )
})

# ============================================================================
# Test 9: Bad input - invalid date column (cannot coerce to Date)
# ============================================================================

test_that("mysterycall_caller_drift bad input: date_col cannot coerce to Date", {
  set.seed(42)
  df <- data.frame(
    call_date = c("not a date", "also not a date"),
    offered   = c(1, 0),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_caller_drift(df, outcome_col = "offered", date_col = "call_date"),
    "Could not coerce date_col"
  )
})

# ============================================================================
# Test 10: print.mysterycall_caller_drift happy path
# ============================================================================

test_that("print.mysterycall_caller_drift happy path: both components", {
  set.seed(42)
  n <- 120L
  df <- data.frame(
    call_date = seq(as.Date("2023-01-02"), by = "day", length.out = n),
    caller    = rep(c("Alice", "Bob", "Carol"), times = n / 3L),
    offered   = rbinom(n, 1L, 0.55),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_caller_drift(
    df,
    outcome_col = "offered",
    date_col    = "call_date",
    caller_col  = "caller",
    week_or_day = "week",
    plot        = FALSE
  ))

  # Capture output
  output <- capture.output(suppressMessages(print(res)))

  expect_true(length(output) > 0L)
  expect_true(any(grepl("mysterycall_caller_drift", output)))
  expect_true(any(grepl("Calendar drift", output)))
  expect_true(any(grepl("Sequence drift", output)))
})

# ============================================================================
# Test 11: print.mysterycall_caller_drift with calendar only
# ============================================================================

test_that("print.mysterycall_caller_drift edge case: calendar only", {
  set.seed(42)
  df <- data.frame(
    call_date = seq(as.Date("2023-01-01"), by = "day", length.out = 60),
    offered   = rbinom(60, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_caller_drift(
    df,
    outcome_col = "offered",
    date_col    = "call_date",
    plot        = FALSE
  ))

  output <- capture.output(suppressMessages(print(res)))
  expect_true(any(grepl("Calendar drift", output)))
  expect_true(any(grepl("not analysed", output)))
})

# ============================================================================
# Test 12: print.mysterycall_caller_drift returns invisible
# ============================================================================

test_that("print.mysterycall_caller_drift returns invisible object", {
  set.seed(42)
  df <- data.frame(
    call_date = seq(as.Date("2023-01-01"), by = "day", length.out = 60),
    offered   = rbinom(60, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_caller_drift(
    df,
    outcome_col = "offered",
    date_col    = "call_date",
    plot        = FALSE
  ))

  # Verify it's the same object
  invisible_res <- suppressMessages(print(res))
  expect_identical(invisible_res, res)
})

# ============================================================================
# Test 13: Non-binary outcome handling
# ============================================================================

test_that("mysterycall_caller_drift edge case: non-binary outcome", {
  set.seed(42)
  df <- data.frame(
    call_date = seq(as.Date("2023-01-01"), by = "day", length.out = 60),
    offered   = sample(c(0, 1, 2), 60, replace = TRUE),  # includes 2
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(suppressWarnings(mysterycall_caller_drift(
    df,
    outcome_col = "offered",
    date_col    = "call_date",
    plot        = FALSE
  )))

  # Should still work but issue warning
  expect_s3_class(res, "mysterycall_caller_drift")
})

# ============================================================================
# Test 14: plot = FALSE doesn't require ggplot2
# ============================================================================

test_that("mysterycall_caller_drift with plot=FALSE works without ggplot2", {
  set.seed(42)
  df <- data.frame(
    call_date = seq(as.Date("2023-01-01"), by = "day", length.out = 60),
    offered   = rbinom(60, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_caller_drift(
    df,
    outcome_col = "offered",
    date_col    = "call_date",
    plot        = FALSE
  ))

  expect_true(is.null(res$plot))
})

# ============================================================================
# Test 15: Explicit call_seq_col without date_col
# ============================================================================

test_that("mysterycall_caller_drift: explicit call_seq_col, no date_col", {
  set.seed(42)
  n <- 80L
  df <- data.frame(
    seq_num = seq_len(n),
    offered = rbinom(n, 1L, 0.5),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(mysterycall_caller_drift(
    df,
    outcome_col  = "offered",
    call_seq_col = "seq_num",
    plot         = FALSE
  ))

  expect_s3_class(res, "mysterycall_caller_drift")
  expect_true(!is.null(res$sequence))
  expect_true(is.null(res$calendar))
  expect_true(is.data.frame(res$sequence$rate_by_seq))
})
