library(testthat)
library(mysterycall)

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


# ---- mysterycall_prepare_calls: happy path ------------------------------------

test_that("mysterycall_prepare_calls returns list of class mysterycall_prepared", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12"),
    contacted1 = c(1, 1, 1),
    contacted2 = c(99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03"),
    exclusions = c(0, 0, 0),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  expect_s3_class(result, "mysterycall_prepared")
  expect_true(is.list(result))
  expect_named(
    result,
    c("logistic_data", "waittime_data", "waterfall", "exclusion_summary",
      "caller_summary", "na_exclusion_records")
  )
})


test_that("mysterycall_prepare_calls logistic_data has required columns", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  expect_true(is.data.frame(result$logistic_data))
  expect_true("caller" %in% names(result$logistic_data))
  expect_true("appt_offered" %in% names(result$logistic_data))
  expect_true("reached" %in% names(result$logistic_data))
})


test_that("mysterycall_prepare_calls standardizes caller names to title case", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12"),
    contacted1 = c(1, 1, 1),
    contacted2 = c(99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03"),
    exclusions = c(0, 0, 0),
    initials   = c("alice smith", "BOB JONES", "charlie BROWN"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  expect_equal(
    result$logistic_data$caller,
    c("Alice Smith", "Bob Jones", "Charlie Brown")
  )
})


test_that("mysterycall_prepare_calls creates binary appt_offered outcome", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12"),
    contacted1 = c(1, 1, 1),
    contacted2 = c(99, 99, 99),
    appdate    = c("2024-02-01", "", NA),
    exclusions = c(0, 0, 0),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  expect_type(result$logistic_data$appt_offered, "integer")
  expect_equal(result$logistic_data$appt_offered, c(1L, 0L, 0L))
})


test_that("mysterycall_prepare_calls resolves reached from contacted1 OR contacted2", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12", "2024-01-13"),
    contacted1 = c(1, 0, 0, 0),
    contacted2 = c(99, 99, 1, 0),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03", "2024-02-04"),
    exclusions = c(0, 0, 0, 0),
    initials   = c("a", "b", "c", "d"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  # Rows 1 and 3 reached (contacted1=1 OR contacted2=1)
  expect_equal(nrow(result$logistic_data), 2)
})


# ---- mysterycall_prepare_calls: edge cases ------------------------------------

test_that("mysterycall_prepare_calls drops rows with NA calldate", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", NA, "2024-01-12"),
    contacted1 = c(1, 1, 1),
    contacted2 = c(99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03"),
    exclusions = c(0, 0, 0),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  expect_equal(nrow(result$logistic_data), 2)
  expect_true(all(!is.na(result$logistic_data$calldate1)))
})


test_that("mysterycall_prepare_calls handles empty calldate strings", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "  ", "2024-01-12"),
    contacted1 = c(1, 1, 1),
    contacted2 = c(99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03"),
    exclusions = c(0, 0, 0),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  expect_equal(nrow(result$logistic_data), 2)
})


test_that("mysterycall_prepare_calls handles NA exclusion codes with warn", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12"),
    contacted1 = c(1, 1, 1),
    contacted2 = c(99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03"),
    exclusions = c(0, NA, 0),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  expect_warning(
    suppressMessages(
      mysterycall_prepare_calls(df, na_exclusions = "warn")
    ),
    "NA exclusion codes"
  )

  # Also verify it returns valid structure
  result <- suppressMessages(suppressWarnings(
    mysterycall_prepare_calls(df, na_exclusions = "warn")
  ))
  expect_true(nrow(result$logistic_data) > 0)
})


test_that("mysterycall_prepare_calls handles na_exclusions drop option", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12"),
    contacted1 = c(1, 1, 1),
    contacted2 = c(99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03"),
    exclusions = c(0, NA, 0),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_prepare_calls(df, na_exclusions = "drop")
  ))

  # Function should return a valid mysterycall_prepared object
  expect_s3_class(result, "mysterycall_prepared")
  expect_true(is.data.frame(result$logistic_data))
})


test_that("mysterycall_prepare_calls handles zero-row data frame", {
  set.seed(42)
  df <- data.frame(
    calldate1  = character(0),
    contacted1 = integer(0),
    contacted2 = integer(0),
    appdate    = character(0),
    exclusions = integer(0),
    initials   = character(0),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  expect_equal(nrow(result$logistic_data), 0)
  expect_equal(nrow(result$waittime_data), 0)
})


test_that("mysterycall_prepare_calls handles missing initials column", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    exclusions = c(0, 0),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(
    expect_warning(
      mysterycall_prepare_calls(df),
      "Column 'initials' not found"
    )
  )

  expect_true(all(is.na(result$logistic_data$caller)))
})


test_that("mysterycall_prepare_calls handles missing appdate column", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(
    expect_warning(
      mysterycall_prepare_calls(df),
      "Column 'appdate' not found"
    )
  )

  expect_true(all(is.na(result$logistic_data$appt_offered)))
})


test_that("mysterycall_prepare_calls warns on negative calendar days", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-02-10"),
    contacted1 = c(1),
    contacted2 = c(99),
    appdate    = c("2024-02-01"),
    exclusions = c(0),
    initials   = c("alice"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages({
    expect_warning(
      mysterycall_prepare_calls(df),
      "negative calendar days"
    )
    suppressWarnings(mysterycall_prepare_calls(df))
  })

  expect_true(any(result$waittime_data$calendar_days < 0, na.rm = TRUE))
})


test_that("mysterycall_prepare_calls filters by exclusion codes", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12", "2024-01-13"),
    contacted1 = c(1, 1, 1, 1),
    contacted2 = c(99, 99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03", "2024-02-04"),
    exclusions = c(0, 7, 9, 5),
    initials   = c("a", "b", "c", "d"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  # Default codes = c(0, 7, 9, 10); code 5 excluded
  expect_equal(nrow(result$logistic_data), 3)
})


test_that("mysterycall_prepare_calls calculates calendar_days correctly", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-15"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-01-20", "2024-02-01"),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  expect_true("calendar_days" %in% names(result$waittime_data))
  expect_equal(result$waittime_data$calendar_days, c(10, 17))
})


test_that("mysterycall_prepare_calls uses custom column names", {
  set.seed(42)
  df <- data.frame(
    call_date  = c("2024-01-10", "2024-01-11"),
    reached_1  = c(1, 1),
    reached_2  = c(99, 99),
    apt_date   = c("2024-02-01", "2024-02-02"),
    excl_code  = c(0, 0),
    caller_id  = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_prepare_calls(
      df,
      col_calldate  = "call_date",
      col_contacted1 = "reached_1",
      col_contacted2 = "reached_2",
      col_appdate   = "apt_date",
      col_exclusions = "excl_code",
      col_initials   = "caller_id"
    )
  ))

  expect_equal(nrow(result$logistic_data), 2)
})


# ---- mysterycall_prepare_calls: bad input ------------------------------------

test_that("mysterycall_prepare_calls errors if data not data.frame", {
  expect_error(
    mysterycall_prepare_calls(list(a = 1, b = 2)),
    "must be a data frame"
  )
})


test_that("mysterycall_prepare_calls errors if calldate column missing", {
  set.seed(42)
  df <- data.frame(
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressWarnings(mysterycall_prepare_calls(df)),
    "Required columns not found"
  )
})


test_that("mysterycall_prepare_calls errors if exclusions column missing", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressWarnings(mysterycall_prepare_calls(df)),
    "Required columns not found"
  )
})


# ---- print.mysterycall_prepared: happy path ---------------------------------

test_that("print.mysterycall_prepared returns invisible object", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  output <- capture.output(x <- print(result))

  expect_identical(x, result)
  expect_true(length(output) > 0)
})


test_that("print.mysterycall_prepared shows waterfall info", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", NA),
    contacted1 = c(1, 1, 1),
    contacted2 = c(99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03"),
    exclusions = c(0, 0, 0),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  output <- capture.output(print(result))

  expect_true(any(grepl("Filtering Waterfall", output)))
  expect_true(any(grepl("calldate1 present", output)))
})


test_that("print.mysterycall_prepared shows logistic dataset stats", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", ""),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  output <- capture.output(print(result))

  expect_true(any(grepl("Logistic dataset", output)))
  expect_true(any(grepl("Appointment offered", output)))
})


test_that("print.mysterycall_prepared shows wait-time dataset", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  output <- capture.output(print(result))

  expect_true(any(grepl("Wait-time dataset", output)))
  expect_true(any(grepl("Calendar days", output)))
})


test_that("print.mysterycall_prepared shows exclusion summary", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12"),
    contacted1 = c(1, 1, 1),
    contacted2 = c(99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03"),
    exclusions = c(0, 7, 9),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  output <- capture.output(print(result))

  expect_true(any(grepl("Exclusion Code Summary", output)))
})


test_that("print.mysterycall_prepared handles NULL na_exclusion_records", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(mysterycall_prepare_calls(df)))

  output <- capture.output(print(result))

  expect_true(length(output) > 0)
  expect_null(result$na_exclusion_records)
})

# Regression (bug 36): with na_exclusions = "drop", the NA-flag vector must be
# subset alongside `d`/`exc` so downstream logical combining does not recycle a
# longer-than-nrow index and select phantom out-of-range rows.
test_that("na_exclusions = 'drop' does not create phantom rows", {
  df <- data.frame(
    calldate1  = rep("2024-01-10", 5L),
    contacted1 = rep(1, 5L),
    exclusions = c(0, NA, 0, NA, 7),
    stringsAsFactors = FALSE
  )
  result <- suppressWarnings(suppressMessages(
    mysterycall_prepare_calls(df, na_exclusions = "drop")
  ))
  # 2 NA-exclusion rows dropped -> 3 rows remain, all reached & in include codes.
  expect_equal(nrow(result$logistic_data), 3L)
  expect_false(any(is.na(result$logistic_data$exclusions_int)))
})
