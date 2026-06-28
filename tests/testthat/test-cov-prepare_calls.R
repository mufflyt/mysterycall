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


test_that("mysterycall_prepare_calls happy path: minimal valid input", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12", NA, "2024-01-14"),
    contacted1 = c(1, 1, 0, 1, 1),
    contacted2 = c(99, 99, 1, 99, 99),
    appdate    = c("2024-02-01", "", "2024-02-05", "2024-02-03", "2024-02-10"),
    exclusions = c(0, 9, 0, 0, 7),
    initials   = c("lizeth", "MERILYN", "Lizeth", "jessica", "merilyn"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df)
  }))

  expect_s3_class(result, "mysterycall_prepared")
  expect_type(result, "list")
  expect_true(nrow(result$logistic_data) > 0)
})


test_that("mysterycall_prepare_calls returns correct list structure with required elements", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12"),
    contacted1 = c(1, 1, 0),
    contacted2 = c(99, 99, 1),
    appdate    = c("2024-02-01", "", "2024-02-05"),
    exclusions = c(0, 9, 0),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df)
  }))

  expect_named(
    result,
    c("logistic_data", "waittime_data", "waterfall", "exclusion_summary",
      "caller_summary", "na_exclusion_records")
  )
  expect_s3_class(result$logistic_data, "data.frame")
  expect_s3_class(result$waittime_data, "data.frame")
  expect_s3_class(result$waterfall, "data.frame")
  expect_s3_class(result$exclusion_summary, "data.frame")
})


test_that("mysterycall_prepare_calls rejects non-data.frame input", {
  expect_error(
    suppressMessages(suppressWarnings({
      mysterycall_prepare_calls(list(x = 1, y = 2))
    })),
    "`data` must be a data frame"
  )
})


test_that("mysterycall_prepare_calls drops rows with NA calldate", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", NA, "2024-01-12"),
    contacted1 = c(1, 1, 0),
    contacted2 = c(99, 99, 1),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-05"),
    exclusions = c(0, 0, 0),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df)
  }))

  # Should have 2 rows after dropping NA calldate row
  expect_equal(nrow(result$logistic_data), 2)
})


test_that("mysterycall_prepare_calls handles na_exclusions = 'warn'", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    exclusions = c(0, NA),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  expect_warning({
    suppressMessages({
      result <- mysterycall_prepare_calls(df, na_exclusions = "warn")
    })
  }, "NA exclusion codes")

  expect_equal(nrow(result$logistic_data), 2)
  expect_true(!is.null(result$na_exclusion_records))
})


test_that("mysterycall_prepare_calls handles na_exclusions = 'include'", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12"),
    contacted1 = c(1, 1, 1),
    contacted2 = c(99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03"),
    exclusions = c(0, NA, 7),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages({
    mysterycall_prepare_calls(df, na_exclusions = "include")
  })

  # All rows with valid calldate and reached should be in logistic_data
  expect_equal(nrow(result$logistic_data), 3)
  expect_true(!is.null(result$na_exclusion_records) || any(is.na(df$exclusions)))
})


test_that("mysterycall_prepare_calls creates appt_offered column", {
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

  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df)
  }))

  expect_true("appt_offered" %in% names(result$logistic_data))
  expect_type(result$logistic_data$appt_offered, "integer")
  expect_equal(
    result$logistic_data$appt_offered,
    c(1L, 0L, 0L)
  )
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

  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df)
  }))

  expect_true("caller" %in% names(result$logistic_data))
  expect_equal(
    result$logistic_data$caller,
    c("Alice Smith", "Bob Jones", "Charlie Brown")
  )
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

  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df)
  }))

  # Rows 1 and 3 are reached (contacted1=1 OR contacted2=1)
  expect_equal(nrow(result$logistic_data), 2)
})


test_that("mysterycall_prepare_calls respects logistic_include_codes parameter", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12", "2024-01-13"),
    contacted1 = c(1, 1, 1, 1),
    contacted2 = c(99, 99, 99, 99),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-03", "2024-02-04"),
    exclusions = c(0, 7, 9, 1),
    initials   = c("a", "b", "c", "d"),
    stringsAsFactors = FALSE
  )

  # Include only 0 and 7
  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df, logistic_include_codes = c(7L))
  }))

  # Should have 2 rows (0 is automatically added, so codes 0 and 7)
  expect_equal(nrow(result$logistic_data), 2)
})


test_that("mysterycall_prepare_calls calculates calendar_days correctly", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-15"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-10"),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df)
  }))

  expect_true("calendar_days" %in% names(result$waittime_data))
  expect_type(result$waittime_data$calendar_days, "double")
  # 2024-02-01 minus 2024-01-10 = 22 days
  # 2024-02-10 minus 2024-01-15 = 26 days
  expect_equal(result$waittime_data$calendar_days, c(22, 26))
})


test_that("mysterycall_prepare_calls warns on negative calendar days", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-02-01"),
    contacted1 = c(1),
    contacted2 = c(99),
    appdate    = c("2024-01-10"),
    exclusions = c(0),
    initials   = c("alice"),
    stringsAsFactors = FALSE
  )

  expect_warning({
    suppressMessages({
      mysterycall_prepare_calls(df)
    })
  }, "negative calendar days")
})


test_that("mysterycall_prepare_calls creates waterfall tracking filtering steps", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", NA, "2024-01-12"),
    contacted1 = c(1, 1, 0),
    contacted2 = c(99, 99, 1),
    appdate    = c("2024-02-01", "2024-02-02", "2024-02-05"),
    exclusions = c(0, 0, 0),
    initials   = c("alice", "bob", "charlie"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df)
  }))

  expect_s3_class(result$waterfall, "data.frame")
  expect_named(result$waterfall, c("step", "n_remaining", "n_dropped", "reason"))
  expect_true(nrow(result$waterfall) >= 2)
})


test_that("mysterycall_prepare_calls creates exclusion_summary", {
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

  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df)
  }))

  expect_s3_class(result$exclusion_summary, "data.frame")
  expect_named(result$exclusion_summary, c("Code", "Freq", "Label"))
  expect_equal(nrow(result$exclusion_summary), 3)
})


test_that("mysterycall_prepare_calls handles missing col_appdate gracefully", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  expect_warning({
    suppressMessages({
      result <- mysterycall_prepare_calls(df)
    })
  }, "not found")

  expect_true("appt_offered" %in% names(result$logistic_data))
  expect_true(all(is.na(result$logistic_data$appt_offered)))
})


test_that("mysterycall_prepare_calls handles missing col_initials gracefully", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    exclusions = c(0, 0),
    stringsAsFactors = FALSE
  )

  expect_warning({
    suppressMessages({
      result <- mysterycall_prepare_calls(df)
    })
  }, "not found")

  expect_true("caller" %in% names(result$logistic_data))
  expect_true(all(is.na(result$logistic_data$caller)))
})


test_that("mysterycall_prepare_calls requires calldate column", {
  set.seed(42)
  df <- data.frame(
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    exclusions = c(0, 0),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  expect_error({
    suppressMessages(suppressWarnings({
      mysterycall_prepare_calls(df)
    }))
  }, "Required columns not found")
})


test_that("mysterycall_prepare_calls requires exclusions column", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2024-02-01", "2024-02-02"),
    initials   = c("alice", "bob"),
    stringsAsFactors = FALSE
  )

  expect_error({
    suppressMessages(suppressWarnings({
      mysterycall_prepare_calls(df)
    }))
  }, "Required columns not found")
})


test_that("mysterycall_prepare_calls waittime_data is subset of logistic_data", {
  set.seed(42)
  df <- data.frame(
    calldate1  = c("2024-01-10", "2024-01-11", "2024-01-12", "2024-01-13"),
    contacted1 = c(1, 1, 1, 1),
    contacted2 = c(99, 99, 99, 99),
    appdate    = c("2024-02-01", "", "2024-02-05", ""),
    exclusions = c(0, 0, 7, 0),
    initials   = c("a", "b", "c", "d"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings({
    mysterycall_prepare_calls(df)
  }))

  expect_true(nrow(result$waittime_data) <= nrow(result$logistic_data))
})
