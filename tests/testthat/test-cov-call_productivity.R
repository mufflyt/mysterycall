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

# ====== TEST 1: Happy path - minimal input (caller_col only) ======
test_that("mysterycall_call_productivity returns correct structure with minimal input", {
  df <- data.frame(
    caller = c("Alice", "Alice", "Bob", "Bob"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_call_productivity(df, "caller"))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_equal(
    colnames(result),
    c("caller", "n_calls", "n_days", "calls_per_day",
      "n_accepted", "acceptance_rate", "mean_hold_sec", "mean_call_sec")
  )
  expect_equal(result$caller, c("Alice", "Bob"))
  expect_equal(result$n_calls, c(2L, 2L))
  expect_true(all(is.na(result$n_days)))
  expect_true(all(is.na(result$calls_per_day)))
  expect_true(all(is.na(result$n_accepted)))
  expect_true(all(is.na(result$acceptance_rate)))
  expect_true(all(is.na(result$mean_hold_sec)))
  expect_true(all(is.na(result$mean_call_sec)))
})

# ====== TEST 2: Happy path - all optional columns provided ======
test_that("mysterycall_call_productivity with all optional columns computes all metrics", {
  set.seed(2)
  df <- data.frame(
    caller = c("Alice", "Alice", "Bob", "Bob"),
    call_date = as.Date(c("2024-01-01", "2024-01-02", "2024-01-01", "2024-01-03")),
    outcome = c(1, 0, 1, 1),
    hold_time = c("1:30", "2:15", "0:45", "1:20"),
    call_time = c(300, 450, 120, 240),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_call_productivity(
      df, "caller",
      date_col = "call_date",
      outcome_col = "outcome",
      hold_time_col = "hold_time",
      call_time_col = "call_time"
    )
  )

  expect_equal(result$n_calls, c(2L, 2L))
  expect_equal(result$n_days, c(2, 2))
  expect_equal(result$calls_per_day, c(1, 1))
  expect_equal(result$n_accepted, c(1, 2))
  expect_equal(result$acceptance_rate, c("50.0%", "100.0%"))
  expect_equal(result$mean_hold_sec, c(112.5, 62.5))
  expect_equal(result$mean_call_sec, c(375, 180))
})

# ====== TEST 3: Edge case - outcome column with NA values ======
test_that("mysterycall_call_productivity handles NA values in outcome column", {
  set.seed(3)
  df <- data.frame(
    caller = c("Alice", "Alice", "Alice", "Bob", "Bob"),
    outcome = c(1, NA, 0, 1, 1),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_call_productivity(df, "caller", outcome_col = "outcome")
  )

  expect_equal(result$n_calls, c(3L, 2L))
  expect_equal(result$n_accepted, c(1, 2))
  expect_equal(result$acceptance_rate, c("33.3%", "100.0%"))
})

# ====== TEST 4: Edge case - time format conversion (MM:SS and numeric mixed) ======
test_that("mysterycall_call_productivity converts MM:SS and numeric time formats", {
  set.seed(4)
  df <- data.frame(
    caller = c("Alice", "Alice", "Bob", "Bob"),
    hold_time = c("2:30", "1:15", 45, 60),
    call_time = c(500, 400, "3:20", "4:00"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_call_productivity(
      df, "caller",
      hold_time_col = "hold_time",
      call_time_col = "call_time"
    )
  )

  # Alice: hold (150 + 75)/2 = 112.5; call (500 + 400)/2 = 450
  # Bob: hold (45 + 60)/2 = 52.5; call (200 + 240)/2 = 220
  expect_equal(result$mean_hold_sec[1], 112.5)
  expect_equal(result$mean_call_sec[1], 450)
  expect_equal(result$mean_hold_sec[2], 52.5)
  expect_equal(result$mean_call_sec[2], 220)
})

# ====== TEST 5: Edge case - date column with different date types ======
test_that("mysterycall_call_productivity coerces Date, POSIXct, and character dates", {
  set.seed(5)

  # Test with Date
  df_date <- data.frame(
    caller = c("Alice", "Alice", "Bob", "Bob"),
    call_date = as.Date(c("2024-01-01", "2024-01-01", "2024-01-01", "2024-01-02")),
    stringsAsFactors = FALSE
  )
  result_date <- suppressMessages(
    mysterycall_call_productivity(df_date, "caller", date_col = "call_date")
  )
  expect_equal(result_date$n_days, c(1, 2))

  # Test with POSIXct
  df_posixct <- data.frame(
    caller = c("Alice", "Alice", "Bob", "Bob"),
    call_date = as.POSIXct(c("2024-01-01", "2024-01-01", "2024-01-01", "2024-01-02")),
    stringsAsFactors = FALSE
  )
  result_posixct <- suppressMessages(
    mysterycall_call_productivity(df_posixct, "caller", date_col = "call_date")
  )
  expect_equal(result_posixct$n_days, c(1, 2))

  # Test with character
  df_char <- data.frame(
    caller = c("Alice", "Alice", "Bob", "Bob"),
    call_date = c("2024-01-01", "2024-01-01", "2024-01-01", "2024-01-02"),
    stringsAsFactors = FALSE
  )
  result_char <- suppressMessages(
    mysterycall_call_productivity(df_char, "caller", date_col = "call_date")
  )
  expect_equal(result_char$n_days, c(1, 2))
})

# ====== TEST 6: Input validation - missing caller_col ======
test_that("mysterycall_call_productivity errors when caller_col not in data", {
  df <- data.frame(
    caller = c("Alice", "Bob"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_call_productivity(df, "nonexistent_col")),
    "nonexistent_col"
  )
})

# ====== TEST 7: Input validation - wrong type for caller_col ======
test_that("mysterycall_call_productivity errors when caller_col is not character", {
  df <- data.frame(
    caller = c("Alice", "Bob"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_call_productivity(df, 123)),
    "is.character"
  )
})

# ====== TEST 8: Input validation - insufficient unique callers ======
test_that("mysterycall_call_productivity requires at least 2 unique callers", {
  df <- data.frame(
    caller = c("Alice", "Alice", "Alice"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_call_productivity(df, "caller")),
    "At least 2 unique callers"
  )
})

# ====== TEST 9: Input validation - optional column not found ======
test_that("mysterycall_call_productivity errors when optional column not in data", {
  df <- data.frame(
    caller = c("Alice", "Bob"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_call_productivity(df, "caller", date_col = "missing_date")),
    "missing_date"
  )
})

# ====== TEST 10: Return structure - total_calls_all attribute ======
test_that("mysterycall_call_productivity sets total_calls_all attribute", {
  set.seed(10)
  df <- data.frame(
    caller = c("Alice", "Alice", "Bob", "Charlie"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_call_productivity(df, "caller"))

  expect_equal(attr(result, "total_calls_all"), 4L)
  expect_equal(nrow(result), 3L)
})

# ====== TEST 11: Output sorting - sorted by n_calls descending ======
test_that("mysterycall_call_productivity sorts output by n_calls descending", {
  set.seed(11)
  df <- data.frame(
    caller = c("Alice", "Bob", "Bob", "Bob", "Charlie", "Charlie"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_call_productivity(df, "caller"))

  expect_equal(result$caller, c("Bob", "Charlie", "Alice"))
  expect_equal(result$n_calls, c(3L, 2L, 1L))
})

# ====== TEST 12: Edge case - hold_time_col with NA values ======
test_that("mysterycall_call_productivity handles NA in hold_time_col", {
  set.seed(12)
  df <- data.frame(
    caller = c("Alice", "Alice", "Bob", "Bob"),
    hold_time = c(60, NA, 120, 90),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_call_productivity(df, "caller", hold_time_col = "hold_time")
  )

  # Alice: mean(60, NA, na.rm=TRUE) = 60
  # Bob: mean(120, 90, na.rm=TRUE) = 105
  expect_equal(result$mean_hold_sec, c(60, 105))
})

# ====== TEST 13: Integration - all parameters with AUDIT data ======
test_that("mysterycall_call_productivity works with realistic AUDIT dataset", {
  set.seed(13)
  df <- data.frame(
    caller_id = c("A", "A", "B", "B", "A", "B"),
    call_date = as.Date(c("2024-01-01", "2024-01-02", "2024-01-01", "2024-01-03", "2024-01-04", "2024-01-02")),
    outcome = c(1, 0, 1, 1, 0, 1),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_call_productivity(
      df, "caller_id",
      date_col = "call_date",
      outcome_col = "outcome"
    )
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_equal(result$caller, c("A", "B"))
  expect_equal(result$n_calls, c(3L, 3L))
  expect_true(!is.na(result$n_days[1]))
  expect_true(!is.na(result$acceptance_rate[1]))
})
