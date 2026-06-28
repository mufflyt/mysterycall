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

skip_if_not_installed("bizdays")

# ============================================================================
# mysterycall_us_federal_calendar()
# ============================================================================

test_that("mysterycall_us_federal_calendar returns a calendar object with correct class", {
  cal <- suppressMessages(mysterycall_us_federal_calendar(2026, 2026))
  expect_s3_class(cal, "Calendar")
})

test_that("mysterycall_us_federal_calendar includes all 11 federal holidays per year", {
  cal <- suppressMessages(mysterycall_us_federal_calendar(2026, 2026))
  # 2026 has 11 holidays (all are weekdays, no shift needed)
  # The calendar object contains holidays attribute
  expect_true(length(cal$holidays) >= 11)
})

test_that("mysterycall_us_federal_calendar handles year range correctly", {
  cal_single <- suppressMessages(mysterycall_us_federal_calendar(2026, 2026))
  cal_multi  <- suppressMessages(mysterycall_us_federal_calendar(2026, 2028))
  # Multi-year calendar should have more holidays
  expect_true(length(cal_multi$holidays) > length(cal_single$holidays))
})

test_that("mysterycall_us_federal_calendar rejects end_year < start_year", {
  expect_error(
    suppressMessages(mysterycall_us_federal_calendar(2028, 2026)),
    "end_year.*must be.*start_year"
  )
})

test_that("mysterycall_us_federal_calendar rejects non-numeric year inputs", {
  expect_error(
    suppressMessages(mysterycall_us_federal_calendar("2026", 2028)),
    "must each be a single number"
  )
})

test_that("mysterycall_us_federal_calendar rejects vector-length year inputs", {
  expect_error(
    suppressMessages(mysterycall_us_federal_calendar(c(2026, 2027), 2028)),
    "must each be a single number"
  )
})

# ============================================================================
# mysterycall_count_business_days()
# ============================================================================

test_that("mysterycall_count_business_days counts business days correctly", {
  # 2026-02-02 is Monday, 2026-02-06 is Friday: 4 business days
  result <- suppressMessages(mysterycall_count_business_days(
    "2026-02-02",
    "2026-02-06"
  ))
  expect_equal(result, 4L)
})

test_that("mysterycall_count_business_days returns integer vector", {
  result <- suppressMessages(mysterycall_count_business_days(
    c("2026-02-02", "2026-02-03"),
    c("2026-02-06", "2026-02-06")
  ))
  expect_type(result, "integer")
  expect_length(result, 2L)
})

test_that("mysterycall_count_business_days handles vectorization with recycling", {
  # Single start_date, multiple end_dates
  result <- suppressMessages(mysterycall_count_business_days(
    "2026-02-02",
    c("2026-02-06", "2026-02-09")
  ))
  expect_equal(length(result), 2L)
  expect_true(result[2] > result[1])
})

test_that("mysterycall_count_business_days returns 0 when start == end", {
  result <- suppressMessages(mysterycall_count_business_days(
    "2026-02-02",
    "2026-02-02"
  ))
  expect_equal(result, 0L)
})

test_that("mysterycall_count_business_days handles NA values", {
  result <- suppressMessages(mysterycall_count_business_days(
    c("2026-02-02", NA),
    c("2026-02-06", "2026-02-09")
  ))
  expect_equal(result[1], 4L)
  expect_true(is.na(result[2]))
})

test_that("mysterycall_count_business_days warns and returns NA for reverse dates", {
  result <- suppressWarnings(suppressMessages(mysterycall_count_business_days(
    c("2026-02-06", "2026-02-02"),
    c("2026-02-02", "2026-02-06")
  )))
  expect_true(is.na(result[1]))
  expect_equal(result[2], 4L)
})

test_that("mysterycall_count_business_days accepts Date objects", {
  result <- suppressMessages(mysterycall_count_business_days(
    as.Date("2026-02-02"),
    as.Date("2026-02-06")
  ))
  expect_equal(result, 4L)
})

test_that("mysterycall_count_business_days rejects mismatched non-recyclable lengths", {
  expect_error(
    suppressMessages(mysterycall_count_business_days(
      c("2026-02-02", "2026-02-03", "2026-02-04"),
      c("2026-02-06", "2026-02-09")
    )),
    "same length"
  )
})

test_that("mysterycall_count_business_days respects provided calendar", {
  cal <- suppressMessages(mysterycall_us_federal_calendar(2026, 2026))
  result <- suppressMessages(mysterycall_count_business_days(
    "2026-02-02",
    "2026-02-06",
    calendar = cal
  ))
  expect_equal(result, 4L)
})

# ============================================================================
# mysterycall_business_days()
# ============================================================================

test_that("mysterycall_business_days adds column to data frame", {
  df <- data.frame(
    physician        = c("Dr. Smith", "Dr. Jones"),
    call_date        = as.Date(c("2026-02-02", "2026-02-13")),
    appointment_date = as.Date(c("2026-02-10", "2026-02-20")),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_business_days(df))
  expect_s3_class(result, "data.frame")
  expect_true("business_days_until_appointment" %in% names(result))
  expect_equal(nrow(result), 2L)
})

test_that("mysterycall_business_days returns correct business day counts", {
  df <- data.frame(
    call_date        = as.Date(c("2026-02-02")),
    appointment_date = as.Date(c("2026-02-06")),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_business_days(df))
  expect_equal(result$business_days_until_appointment[1], 4L)
})

test_that("mysterycall_business_days accepts custom column names", {
  df <- data.frame(
    call_dt      = as.Date(c("2026-02-02")),
    appointment_dt = as.Date(c("2026-02-06")),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_business_days(
    df,
    call_col = "call_dt",
    appt_col = "appointment_dt",
    result_col = "biz_days"
  ))
  expect_true("biz_days" %in% names(result))
  expect_equal(result$biz_days[1], 4L)
})

test_that("mysterycall_business_days handles NA values in date columns", {
  df <- data.frame(
    call_date        = as.Date(c("2026-02-02", NA)),
    appointment_date = as.Date(c("2026-02-06", "2026-02-09")),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_business_days(df))
  expect_equal(result$business_days_until_appointment[1], 4L)
  expect_true(is.na(result$business_days_until_appointment[2]))
})

test_that("mysterycall_business_days validates required columns", {
  df <- data.frame(
    other_col = c("a", "b"),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_business_days(df)),
    "missing"
  )
})

test_that("mysterycall_business_days rejects invalid result_col", {
  df <- data.frame(
    call_date        = as.Date(c("2026-02-02")),
    appointment_date = as.Date(c("2026-02-06")),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_business_days(df, result_col = "")),
    "non-empty character scalar"
  )
})

test_that("mysterycall_business_days rejects result_col same as input cols", {
  df <- data.frame(
    call_date        = as.Date(c("2026-02-02")),
    appointment_date = as.Date(c("2026-02-06")),
    stringsAsFactors = FALSE
  )
  expect_error(
    suppressMessages(mysterycall_business_days(df, result_col = "call_date")),
    "cannot be the same"
  )
})

test_that("mysterycall_business_days works with POSIXct dates", {
  df <- data.frame(
    call_date        = as.POSIXct(c("2026-02-02 09:00:00")),
    appointment_date = as.POSIXct(c("2026-02-06 14:00:00")),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_business_days(df))
  expect_equal(result$business_days_until_appointment[1], 4L)
})

test_that("mysterycall_business_days respects provided calendar", {
  df <- data.frame(
    call_date        = as.Date(c("2026-02-02")),
    appointment_date = as.Date(c("2026-02-06")),
    stringsAsFactors = FALSE
  )
  cal <- suppressMessages(mysterycall_us_federal_calendar(2026, 2026))
  result <- suppressMessages(mysterycall_business_days(
    df,
    calendar = cal
  ))
  expect_equal(result$business_days_until_appointment[1], 4L)
})
