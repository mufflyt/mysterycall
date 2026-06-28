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

# Test 1: Happy path - valid input with dates and grouping
test_that("mysterycall_flag_date_outliers flags date outliers within groups", {
  df <- data.frame(
    wave      = c(rep("A", 10), rep("B", 10)),
    call_date = as.Date(c(
      rep("2025-06-17", 9), "2025-07-17",   # wave A: 9 correct, 1 outlier (30 days off)
      rep("2025-09-03", 10)                 # wave B: all correct
    )),
    stringsAsFactors = FALSE
  )

  out <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = "wave",
    tolerance_days = 7L
  ))

  expect_s3_class(out, "data.frame")
  expect_true("date_flag" %in% names(out))
  expect_true("expected_date" %in% names(out))
  expect_equal(nrow(out), 20)

  # Wave A: 9 should be FALSE, 1 should be TRUE (the 2025-07-17)
  wave_a <- out[out$wave == "A", ]
  expect_equal(sum(wave_a$date_flag %in% TRUE), 1)
  expect_equal(sum(wave_a$date_flag %in% FALSE), 9)

  # Wave B: all should be FALSE
  wave_b <- out[out$wave == "B", ]
  expect_equal(sum(wave_b$date_flag %in% FALSE), 10)
  expect_equal(sum(wave_b$date_flag %in% TRUE), 0)
})

# Test 2: Edge case - no outliers (all within tolerance)
test_that("mysterycall_flag_date_outliers handles all dates within tolerance", {
  df <- data.frame(
    wave      = c(rep("A", 5)),
    call_date = as.Date(c(
      "2025-06-17", "2025-06-17", "2025-06-18", "2025-06-19", "2025-06-20"
    )),
    stringsAsFactors = FALSE
  )

  out <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = "wave",
    tolerance_days = 7L
  ))

  expect_s3_class(out, "data.frame")
  expect_equal(sum(out$date_flag %in% TRUE), 0)  # No outliers
  expect_equal(sum(out$date_flag %in% FALSE), 5) # All within tolerance
})

# Test 3: Edge case - groups too small (below min_group_size)
test_that("mysterycall_flag_date_outliers returns NA for small groups", {
  df <- data.frame(
    wave      = c(rep("A", 2), rep("B", 5)),  # Wave A has only 2 rows
    call_date = as.Date(c(
      "2025-06-17", "2025-07-17",             # Wave A: small group
      rep("2025-09-03", 5)                    # Wave B: normal group
    )),
    stringsAsFactors = FALSE
  )

  out <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = "wave",
    min_group_size = 3L
  ))

  # Wave A: should all be NA (group too small)
  wave_a <- out[out$wave == "A", ]
  expect_true(all(is.na(wave_a$date_flag)))
  expect_true(all(is.na(wave_a$expected_date)))

  # Wave B: should have TRUE/FALSE values
  wave_b <- out[out$wave == "B", ]
  expect_true(!any(is.na(wave_b$date_flag)))
})

# Test 4: Edge case - NULL group_col (process all data as one group)
test_that("mysterycall_flag_date_outliers works with NULL group_col", {
  df <- data.frame(
    call_date = as.Date(c(
      rep("2025-06-17", 9), "2025-07-17"
    )),
    stringsAsFactors = FALSE
  )

  out <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = NULL,
    tolerance_days = 7L
  ))

  expect_s3_class(out, "data.frame")
  expect_true("date_flag" %in% names(out))
  expect_equal(sum(out$date_flag %in% TRUE), 1)  # One outlier
  expect_equal(sum(out$date_flag %in% FALSE), 9) # Nine normals
})

# Test 5: Edge case - NA values in date column
test_that("mysterycall_flag_date_outliers handles NA values in date column", {
  df <- data.frame(
    wave      = c(rep("A", 5)),
    call_date = as.Date(c(
      "2025-06-17", "2025-06-17", NA, "2025-06-18", "2025-06-19"
    )),
    stringsAsFactors = FALSE
  )

  out <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = "wave",
    tolerance_days = 7L
  ))

  expect_s3_class(out, "data.frame")
  # The row with NA should have NA flag
  expect_true(is.na(out$date_flag[3]))
})

# Test 6: Bad input - missing date_col
test_that("mysterycall_flag_date_outliers errors on missing date_col", {
  df <- data.frame(
    wave      = c("A", "A"),
    call_date = as.Date(c("2025-06-17", "2025-06-18")),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_flag_date_outliers(df, date_col = "nonexistent_col"),
    "not found in `data`"
  )
})

# Test 7: Bad input - missing group_col
test_that("mysterycall_flag_date_outliers errors on missing group_col", {
  df <- data.frame(
    wave      = c("A", "A"),
    call_date = as.Date(c("2025-06-17", "2025-06-18")),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_flag_date_outliers(df, date_col = "call_date", group_col = "nonexistent_col"),
    "not found in `data`"
  )
})

# Test 8: Bad input - non-data.frame input
test_that("mysterycall_flag_date_outliers errors on non-data.frame input", {
  expect_error(
    mysterycall_flag_date_outliers(list(a = 1, b = 2), date_col = "a"),
    "must be a data frame"
  )
})

# Test 9: Bad input - invalid date_col (empty string)
test_that("mysterycall_flag_date_outliers errors on empty date_col", {
  df <- data.frame(call_date = as.Date("2025-06-17"))

  expect_error(
    mysterycall_flag_date_outliers(df, date_col = ""),
    "must be a single non-empty string"
  )
})

# Test 10: Bad input - invalid tolerance_days
test_that("mysterycall_flag_date_outliers errors on negative tolerance_days", {
  df <- data.frame(call_date = as.Date("2025-06-17"))

  expect_error(
    mysterycall_flag_date_outliers(df, date_col = "call_date", tolerance_days = -1),
    "must be a single non-negative number"
  )
})

# Test 11: Date coercion - character dates to Date
test_that("mysterycall_flag_date_outliers coerces character dates to Date", {
  df <- data.frame(
    wave      = c(rep("A", 5)),
    call_date = c(
      "2025-06-17", "2025-06-17", "2025-06-18", "2025-06-19", "2025-07-17"
    ),
    stringsAsFactors = FALSE
  )

  out <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = "wave",
    tolerance_days = 7L
  ))

  expect_s3_class(out$expected_date, "Date")
  expect_equal(sum(out$date_flag %in% TRUE), 1)
})

# Test 12: Tolerance boundary - exactly at tolerance
test_that("mysterycall_flag_date_outliers respects tolerance boundary", {
  df <- data.frame(
    wave      = c(rep("A", 3)),
    call_date = as.Date(c(
      "2025-06-17", "2025-06-17", "2025-06-24"  # 7 days apart
    )),
    stringsAsFactors = FALSE
  )

  # With tolerance_days = 7, the 2025-06-24 should NOT be flagged
  out <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = "wave",
    tolerance_days = 7L
  ))

  expect_equal(sum(out$date_flag %in% TRUE), 0)  # Not flagged

  # With tolerance_days = 6, it should be flagged
  out2 <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = "wave",
    tolerance_days = 6L
  ))

  expect_equal(sum(out2$date_flag %in% TRUE), 1)  # Flagged
})

# Test 13: All identical dates
test_that("mysterycall_flag_date_outliers handles all identical dates", {
  df <- data.frame(
    wave      = c(rep("A", 5)),
    call_date = as.Date(rep("2025-06-17", 5)),
    stringsAsFactors = FALSE
  )

  out <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = "wave"
  ))

  expect_equal(sum(out$date_flag %in% TRUE), 0)
  expect_equal(sum(out$date_flag %in% FALSE), 5)
  expect_true(all(out$expected_date == as.Date("2025-06-17")))
})

# Test 14: Custom flag and expected column names
test_that("mysterycall_flag_date_outliers uses custom column names", {
  df <- data.frame(
    wave      = c(rep("A", 5)),
    call_date = as.Date(c(
      rep("2025-06-17", 4), "2025-07-17"
    )),
    stringsAsFactors = FALSE
  )

  out <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = "wave",
    flag_col = "my_flag",
    expected_col = "my_expected"
  ))

  expect_true("my_flag" %in% names(out))
  expect_true("my_expected" %in% names(out))
  expect_false("date_flag" %in% names(out))
  expect_false("expected_date" %in% names(out))
})

# Test 15: tolerance_days = 0 (exact mode match only)
test_that("mysterycall_flag_date_outliers with tolerance_days = 0", {
  df <- data.frame(
    wave      = c(rep("A", 5)),
    call_date = as.Date(c(
      rep("2025-06-17", 3), "2025-06-18", "2025-06-19"
    )),
    stringsAsFactors = FALSE
  )

  out <- suppressMessages(mysterycall_flag_date_outliers(
    df,
    date_col = "call_date",
    group_col = "wave",
    tolerance_days = 0L
  ))

  # Only the 3 rows matching modal date should be FALSE, others TRUE
  expect_equal(sum(out$date_flag %in% TRUE), 2)
  expect_equal(sum(out$date_flag %in% FALSE), 3)
})

# Test 16: Invalid min_group_size
test_that("mysterycall_flag_date_outliers errors on invalid min_group_size", {
  df <- data.frame(call_date = as.Date("2025-06-17"))

  expect_error(
    mysterycall_flag_date_outliers(df, date_col = "call_date", min_group_size = 0),
    "must be a single positive integer"
  )
})

# Test 17: Warnings for column overwriting
test_that("mysterycall_flag_date_outliers warns when overwriting columns", {
  df <- data.frame(
    call_date = as.Date(c("2025-06-17", "2025-06-18", "2025-06-19")),
    date_flag = c(NA, NA, NA),
    expected_date = as.Date(rep(NA, 3)),
    stringsAsFactors = FALSE
  )

  expect_warning(
    suppressMessages(mysterycall_flag_date_outliers(
      df,
      date_col = "call_date"
    )),
    "already exists"
  )
})
