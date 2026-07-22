library(testthat)
library(mysterycall)

skip_if_no_bizdays <- function() skip_if_not_installed("bizdays")

base_df <- function() {
  data.frame(
    practice         = c("A", "B", "C", "D"),
    call_date        = as.Date(rep("2026-02-02", 4)),
    appointment_date = as.Date(c(
      "2026-02-02",  # same day   -> obtained, wait 0
      "2026-02-06",  # 4 biz days -> obtained
      NA,            # none        -> not obtained
      "2026-01-30"   # before call -> undetermined
    )),
    stringsAsFactors = FALSE
  )
}

# ── the core fix ──────────────────────────────────────────────────────────────

test_that("same-day appointment is obtained with wait 0 (not NA, not not-obtained)", {
  skip_if_no_bizdays()
  out <- suppressWarnings(suppressMessages(
    mysterycall_appointment_obtained(base_df())
  ))
  expect_equal(out$appt_obtained[1], 1L)
  expect_equal(out$business_days_until_appointment[1], 0L)
})

test_that("obtained / not-obtained / undetermined are classified correctly", {
  skip_if_no_bizdays()
  out <- suppressWarnings(suppressMessages(
    mysterycall_appointment_obtained(base_df())
  ))
  expect_equal(out$appt_obtained, c(1L, 1L, 0L, NA))
})

test_that("a normal multi-day wait is counted (Mon->Fri = 4)", {
  skip_if_no_bizdays()
  out <- suppressWarnings(suppressMessages(
    mysterycall_appointment_obtained(base_df())
  ))
  expect_equal(out$business_days_until_appointment[2], 4L)
})

test_that("wait is NA for every not-obtained / undetermined row", {
  skip_if_no_bizdays()
  out <- suppressWarnings(suppressMessages(
    mysterycall_appointment_obtained(base_df())
  ))
  # rows 3 (not obtained) and 4 (undetermined) carry no modelable wait
  expect_true(is.na(out$business_days_until_appointment[3]))
  expect_true(is.na(out$business_days_until_appointment[4]))
})

# ── output shape matches hurdle_wait expectations ─────────────────────────────

test_that("output columns satisfy hurdle_wait's non-negative wait | obtained contract", {
  skip_if_no_bizdays()
  out <- suppressWarnings(suppressMessages(
    mysterycall_appointment_obtained(base_df())
  ))
  w <- out$business_days_until_appointment
  # among obtained rows, wait is present and >= 0
  obt <- out$appt_obtained %in% 1L
  expect_true(all(!is.na(w[obt])))
  expect_true(all(w[obt] >= 0))
})

# ── a same-day appointment before the fix would have been dropped ─────────────

test_that("an all-same-day cohort yields all-obtained, all-zero-wait", {
  skip_if_no_bizdays()
  df <- data.frame(
    call_date        = as.Date(rep("2026-03-02", 5)),
    appointment_date = as.Date(rep("2026-03-02", 5)),
    stringsAsFactors = FALSE
  )
  out <- suppressWarnings(suppressMessages(
    mysterycall_appointment_obtained(df)
  ))
  expect_true(all(out$appt_obtained == 1L))
  expect_true(all(out$business_days_until_appointment == 0L))
})

# ── options ───────────────────────────────────────────────────────────────────

test_that("add_wait = FALSE adds only the obtained indicator", {
  skip_if_no_bizdays()
  out <- suppressWarnings(suppressMessages(
    mysterycall_appointment_obtained(base_df(), add_wait = FALSE)
  ))
  expect_true("appt_obtained" %in% names(out))
  expect_false("business_days_until_appointment" %in% names(out))
})

test_that("custom column names are honored", {
  skip_if_no_bizdays()
  out <- suppressWarnings(suppressMessages(
    mysterycall_appointment_obtained(
      base_df(), obtained_col = "got_appt", wait_col = "bd_wait"
    )
  ))
  expect_true(all(c("got_appt", "bd_wait") %in% names(out)))
})

test_that("character date columns are accepted and empty strings mean no appointment", {
  skip_if_no_bizdays()
  df <- data.frame(
    call_date        = c("2026-02-02", "2026-02-02"),
    appointment_date = c("2026-02-02", ""),  # same-day, then none
    stringsAsFactors = FALSE
  )
  out <- suppressWarnings(suppressMessages(
    mysterycall_appointment_obtained(df)
  ))
  expect_equal(out$appt_obtained, c(1L, 0L))
  expect_equal(out$business_days_until_appointment[1], 0L)
})

# ── announcement ──────────────────────────────────────────────────────────────

test_that("it announces the same-day count", {
  skip_if_no_bizdays()
  expect_message(
    suppressWarnings(mysterycall_appointment_obtained(base_df())),
    regexp = "same-day, wait 0"
  )
})

# ── validation ────────────────────────────────────────────────────────────────

test_that("missing columns and bad args error", {
  expect_error(
    mysterycall_appointment_obtained(base_df(), call_col = "nope"),
    regexp = "missing"
  )
  expect_error(
    mysterycall_appointment_obtained(data.frame()),
    regexp = "row"
  )
  expect_error(
    mysterycall_appointment_obtained(base_df(), add_wait = "yes")
  )
})
