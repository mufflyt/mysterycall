test_that("flags a fat-fingered month (June → July)", {
  df <- data.frame(
    call_date = as.Date(c(rep("2025-06-17", 9), "2025-07-17")),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_flag_date_outliers(df, "call_date")
  expect_equal(nrow(out), 10L)
  expect_true("date_flag" %in% names(out))
  expect_true("expected_date" %in% names(out))
  # row 10 is flagged, rows 1-9 are not
  expect_false(any(out$date_flag[1:9]))
  expect_true(out$date_flag[10])
  # expected date is the modal date
  expect_equal(out$expected_date[1], as.Date("2025-06-17"))
})

test_that("uses group_col for independent per-wave detection", {
  df <- data.frame(
    wave = c(rep("A", 10), rep("B", 10)),
    call_date = as.Date(c(
      rep("2025-06-17", 9), "2025-07-17",
      rep("2025-09-03", 10)
    )),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_flag_date_outliers(df, "call_date", group_col = "wave")
  # wave A: only row 10 flagged
  wave_a <- out[out$wave == "A", ]
  expect_equal(sum(wave_a$date_flag, na.rm = TRUE), 1L)
  expect_true(wave_a$date_flag[wave_a$call_date == as.Date("2025-07-17")])
  # wave B: no flags
  wave_b <- out[out$wave == "B", ]
  expect_false(any(wave_b$date_flag))
})

test_that("tolerance_days = 0 flags any deviation from mode", {
  df <- data.frame(
    call_date = as.Date(c("2025-06-17", "2025-06-17", "2025-06-18")),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_flag_date_outliers(df, "call_date", tolerance_days = 0)
  expect_true(out$date_flag[3])
  expect_false(out$date_flag[1])
})

test_that("tolerance_days = 30 allows one-day slippage without flagging", {
  df <- data.frame(
    call_date = as.Date(c(rep("2025-06-17", 9), "2025-06-18")),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_flag_date_outliers(df, "call_date", tolerance_days = 30)
  expect_false(any(out$date_flag))
})

test_that("groups smaller than min_group_size return NA flags", {
  df <- data.frame(
    wave = c("A", "A", "B", "B", "B", "B", "B"),
    call_date = as.Date(c("2025-06-17", "2025-07-17",
                          rep("2025-09-03", 4), "2025-10-03")),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_flag_date_outliers(df, "call_date",
                                        group_col = "wave",
                                        min_group_size = 3L)
  # wave A has 2 rows < min_group_size=3, so flags are NA
  wave_a <- out[out$wave == "A", ]
  expect_true(all(is.na(wave_a$date_flag)))
  # wave B has 5 rows, outlier row is flagged
  wave_b <- out[out$wave == "B", ]
  expect_true(wave_b$date_flag[wave_b$call_date == as.Date("2025-10-03")])
})

test_that("NA dates are handled without error", {
  df <- data.frame(
    call_date = as.Date(c("2025-06-17", NA, "2025-06-17",
                          "2025-06-17", "2025-07-17")),
    stringsAsFactors = FALSE
  )
  expect_no_error(out <- mysterycall_flag_date_outliers(df, "call_date"))
  expect_equal(nrow(out), 5L)
  expect_true(out$date_flag[5])
  expect_true(is.na(out$date_flag[2]))  # NA date → NA flag
})

test_that("custom flag_col and expected_col names are used", {
  df <- data.frame(
    dt = as.Date(c(rep("2025-01-01", 5), "2025-03-01")),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_flag_date_outliers(df, "dt",
                                        flag_col = "is_outlier",
                                        expected_col = "modal_dt")
  expect_true("is_outlier" %in% names(out))
  expect_true("modal_dt" %in% names(out))
  expect_false("date_flag" %in% names(out))
})

test_that("error on missing date_col", {
  df <- data.frame(x = 1:3)
  expect_error(mysterycall_flag_date_outliers(df, "call_date"),
               "'call_date' not found")
})

test_that("error on missing group_col", {
  df <- data.frame(call_date = as.Date("2025-06-17"))
  expect_error(mysterycall_flag_date_outliers(df, "call_date", group_col = "wave"),
               "'wave' not found")
})

test_that("error on non-data-frame input", {
  expect_error(mysterycall_flag_date_outliers(list(a = 1), "a"),
               "must be a data frame")
})

test_that("character date column is coerced to Date", {
  df <- data.frame(
    call_date = c(rep("2025-06-17", 9), "2025-07-17"),
    stringsAsFactors = FALSE
  )
  expect_no_error(out <- mysterycall_flag_date_outliers(df, "call_date"))
  expect_true(out$date_flag[10])
})

test_that("year transposition is caught (2025 vs 2026)", {
  df <- data.frame(
    call_date = as.Date(c(rep("2025-06-17", 9), "2026-06-17")),
    stringsAsFactors = FALSE
  )
  out <- mysterycall_flag_date_outliers(df, "call_date")
  expect_true(out$date_flag[10])
})
