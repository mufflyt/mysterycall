library(testthat)

# Decision: business days are the canonical wait outcome. prepare_calls() must
# emit business_days_until_appointment (the name the modelling functions default
# to), computed with the shared same-day=0 counter, alongside calendar_days.

test_that("prepare_calls emits the canonical business-days outcome column", {
  skip_if_not_installed("bizdays")
  raw <- data.frame(
    calldate1  = c("2026-02-02", "2026-02-02"),  # both Monday
    contacted1 = c(1, 1),
    contacted2 = c(99, 99),
    appdate    = c("2026-02-02", "2026-02-09"),  # same-day, then +7 calendar (Mon)
    exclusions = c(0, 0),
    initials   = c("aa", "bb"),
    stringsAsFactors = FALSE
  )
  prepared <- suppressWarnings(suppressMessages(mysterycall_prepare_calls(raw)))
  wt <- prepared$waittime_data

  expect_true("business_days_until_appointment" %in% names(wt))
  expect_true("calendar_days" %in% names(wt))

  same <- wt[wt$appdate == "2026-02-02", ]
  wk   <- wt[wt$appdate == "2026-02-09", ]

  # same-day: 0 business AND 0 calendar
  expect_equal(same$business_days_until_appointment, 0L)
  expect_equal(same$calendar_days, 0)

  # one week later: 5 business days (spans a weekend) but 7 calendar days —
  # the two columns are genuinely different, and the canonical one is business.
  expect_equal(wk$business_days_until_appointment, 5L)
  expect_equal(wk$calendar_days, 7)
})

test_that("business_days fallback WARNS (not silently) when bizdays is absent", {
  # We can't uninstall bizdays; assert the warning wiring by checking the
  # source path emits a warning condition class, not a message, for the
  # fallback branch. Skipped when bizdays IS present (the fallback won't run).
  skip_if(requireNamespace("bizdays", quietly = TRUE),
          "bizdays installed; calendar fallback path not exercised")
  df <- data.frame(
    call_date        = as.Date("2026-02-06"),
    appointment_date = as.Date("2026-02-09")
  )
  expect_warning(mysterycall_business_days(df), regexp = "CALENDAR days")
})
