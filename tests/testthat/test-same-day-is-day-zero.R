library(testthat)
library(mysterycall)

# ─────────────────────────────────────────────────────────────────────────────
# INVARIANT: a same-day appointment is a 0-day wait — everywhere.
#
# Every function that converts a (call_date, appointment_date) pair into a
# day count must map same-day -> 0 (never NA, never dropped, never 1). This
# is the study's stated convention (README) and the source of a latent bug in
# external Heckman/hurdle scripts that used `appt <= call -> NA`. This file
# pins the convention across ALL package functions that own that conversion,
# so any regression is caught here rather than in a downstream model.
#
# The owning functions (verified by grepping for date-difference / bizdays
# sites in R/): count_business_days, business_days, appointment_obtained,
# prepare_calls. Everything else consumes the numeric wait these produce.
# ─────────────────────────────────────────────────────────────────────────────

SAME <- as.Date("2026-02-02")  # a Monday

# 1. mysterycall_count_business_days --------------------------------------------

test_that("count_business_days: same-day = 0", {
  expect_equal(
    suppressWarnings(mysterycall_count_business_days(SAME, SAME)),
    0L
  )
})

test_that("count_business_days: same-day = 0 vectorized, mixed with multi-day", {
  out <- suppressWarnings(mysterycall_count_business_days(
    c(SAME, SAME),
    c(SAME, SAME + 4)  # same-day, then Mon->Fri
  ))
  expect_equal(out[1], 0L)
  expect_true(out[2] > 0L)          # a real gap is positive
  expect_false(is.na(out[1]))       # same-day is never NA
})

# 2. mysterycall_business_days (adds a column) ----------------------------------

test_that("business_days: same-day row = 0", {
  df <- data.frame(
    call_date        = c(SAME, SAME),
    appointment_date = c(SAME, SAME + 7),
    stringsAsFactors = FALSE
  )
  out <- suppressWarnings(suppressMessages(mysterycall_business_days(df)))
  expect_equal(out$business_days_until_appointment[1], 0L)
  expect_false(is.na(out$business_days_until_appointment[1]))
})

# 3. mysterycall_appointment_obtained -------------------------------------------

test_that("appointment_obtained: same-day = obtained (1) with wait 0", {
  df <- data.frame(
    call_date        = c(SAME, SAME),
    appointment_date = c(SAME, SAME + 3),
    stringsAsFactors = FALSE
  )
  out <- suppressWarnings(suppressMessages(mysterycall_appointment_obtained(df)))
  expect_equal(out$appt_obtained[1], 1L)
  expect_equal(out$business_days_until_appointment[1], 0L)
})

# 4. mysterycall_prepare_calls (calendar days) ----------------------------------

test_that("prepare_calls: same-day appointment = 0 calendar days", {
  raw <- data.frame(
    calldate1  = c("2026-02-02", "2026-02-02"),
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2026-02-02", "2026-02-09"),  # same-day, then +7
    exclusions = c(0, 0),
    initials   = c("aa", "bb"),
    stringsAsFactors = FALSE
  )
  prepared <- suppressWarnings(suppressMessages(mysterycall_prepare_calls(raw)))
  wt <- prepared$waittime_data
  same_row <- wt[wt$calldate1 == "2026-02-02" & wt$appdate == "2026-02-02", ]
  expect_equal(nrow(same_row), 1L)                 # same-day row is retained
  expect_equal(same_row$calendar_days, 0)          # ... as a 0-day wait
})

# 5. Consumer sanity: a 0-day wait is the shortest bin, not an outlier ----------

test_that("categorize_wait: 0 lands in the lowest bin and is under threshold", {
  cats <- mysterycall_categorize_wait(c(0, 30), threshold_days = 14)
  # 0 is the shortest wait -> first (lowest) ordered-factor bin, not over threshold
  expect_equal(as.integer(cats$bin[1]), 1L)
  expect_equal(as.character(cats$bin[1]), levels(cats$bin)[1])
  expect_false(cats$over_threshold[1])
})

# 6. Cross-function agreement ---------------------------------------------------

test_that("all owning functions agree: same-day -> 0", {
  df <- data.frame(
    call_date        = SAME,
    appointment_date = SAME,
    stringsAsFactors = FALSE
  )
  cbd <- suppressWarnings(mysterycall_count_business_days(SAME, SAME))
  bd  <- suppressWarnings(suppressMessages(
    mysterycall_business_days(df)))$business_days_until_appointment
  ao  <- suppressWarnings(suppressMessages(
    mysterycall_appointment_obtained(df)))$business_days_until_appointment

  expect_equal(unique(c(cbd, bd, ao)), 0L)
})
