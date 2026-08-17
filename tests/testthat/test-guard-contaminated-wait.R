# Guard against a carry-forward-contaminated wait-time column.
#
# The point of these tests is not that the guard runs. It is that the guard
# FAILS on data it should reject: a guard that cannot fail is worse than no
# guard, because it converts an unexamined column into an apparently audited
# one. Each contamination signature therefore gets a positive control (must
# stop) and the honest version of the same frame gets a negative control (must
# pass), so a change that quietly neuters the check breaks a test.

test_that("an honest wait column passes", {
  good <- data.frame(
    appointment_date                = as.Date(c("2019-07-11", NA, NA, "2019-08-23")),
    business_days_until_appointment = c(10, NA, NA, 25)
  )
  expect_true(
    mysterycall_guard_contaminated_wait(good, appointment_col = "appointment_date")
  )
})

test_that("a wait time with no appointment date is rejected", {
  bad <- data.frame(
    appointment_date                = as.Date(c("2019-07-11", NA)),
    business_days_until_appointment = c(10, 10)
  )
  expect_error(
    mysterycall_guard_contaminated_wait(bad, appointment_col = "appointment_date"),
    "must not be analysed"
  )
})

test_that("a wait time on an excluded call is rejected", {
  bad <- data.frame(
    reason_for_exclusions           = c("Able to contact", "Went to voicemail"),
    business_days_until_appointment = c(10, 10)
  )
  expect_error(
    mysterycall_guard_contaminated_wait(bad, exclusion_col = "reason_for_exclusions"),
    "must not be analysed"
  )
})

test_that("the historical fill-down signature is caught", {
  # The shape of the real defect: the frame is ordered so that each answered
  # call is followed by calls that were never answered, and the wait of the
  # answered call has been carried down onto them. Every value is plausible;
  # only the pairing with a missing appointment date gives it away.
  contaminated <- data.frame(
    appointment_date = as.Date(c("2019-07-11", NA, NA,
                                 "2019-08-23", NA,
                                 "2019-09-03", NA, NA, NA)),
    reason_for_exclusions = c("Able to contact", "Went to voicemail", "Wrong number listed",
                              "Able to contact", "Went to voicemail",
                              "Able to contact", "Wrong number listed",
                              "Went to voicemail", "Went to voicemail"),
    business_days_until_appointment = c(8, 8, 8, 16, 16, 28, 28, 28, 28)
  )
  cond <- tryCatch(
    mysterycall_guard_contaminated_wait(
      contaminated,
      appointment_col = "appointment_date",
      exclusion_col   = "reason_for_exclusions"
    ),
    mysterycall_contaminated_wait = function(e) e
  )
  expect_s3_class(cond, "mysterycall_contaminated_wait")
  # the six rows without an appointment are all implicated
  expect_equal(cond$rows, c(2L, 3L, 5L, 7L, 8L, 9L))
  expect_equal(cond$counts[["wait_without_appointment"]], 6L)
  # and they are specifically identified as carried forward, not merely odd
  expect_equal(cond$counts[["carry_forward_runs"]], 6L)
})

test_that("the same frame passes once the contamination is removed", {
  # Negative control for the test above: identical data, with the fabricated
  # waits set back to missing. If this ever fails, the guard has become
  # over-eager rather than correct.
  clean <- data.frame(
    appointment_date = as.Date(c("2019-07-11", NA, NA,
                                 "2019-08-23", NA,
                                 "2019-09-03", NA, NA, NA)),
    reason_for_exclusions = c("Able to contact", "Went to voicemail", "Wrong number listed",
                              "Able to contact", "Went to voicemail",
                              "Able to contact", "Wrong number listed",
                              "Went to voicemail", "Went to voicemail"),
    business_days_until_appointment = c(8, NA, NA, 16, NA, 28, NA, NA, NA)
  )
  expect_true(
    mysterycall_guard_contaminated_wait(
      clean,
      appointment_col = "appointment_date",
      exclusion_col   = "reason_for_exclusions"
    )
  )
})

test_that("repeated waits are not flagged when each has its own appointment", {
  # Two offices can genuinely offer the same wait. Consecutive equal values are
  # only suspicious when the later row has no appointment to justify them.
  legit <- data.frame(
    appointment_date                = as.Date(c("2019-07-11", "2019-07-12", "2019-07-15")),
    business_days_until_appointment = c(10, 10, 10)
  )
  expect_true(
    mysterycall_guard_contaminated_wait(legit, appointment_col = "appointment_date")
  )
})

test_that("action = 'warn' warns instead of stopping", {
  bad <- data.frame(
    appointment_date                = as.Date(c("2019-07-11", NA)),
    business_days_until_appointment = c(10, 10)
  )
  expect_warning(
    res <- mysterycall_guard_contaminated_wait(
      bad, appointment_col = "appointment_date", action = "warn"
    ),
    "must not be analysed"
  )
  expect_false(res)
})

test_that("a non-numeric wait column is refused rather than silently passed", {
  # The 2020 file also carries a banded, categorical wait. Passing it would
  # report a clean bill of health for a column the guard never examined.
  banded <- data.frame(
    appointment_date                = as.Date(c("2019-07-11", NA)),
    business_days_until_appointment = c("1 to 10 business days", NA)
  )
  expect_error(
    mysterycall_guard_contaminated_wait(banded, appointment_col = "appointment_date"),
    "not numeric"
  )
})

test_that("a missing wait column is an error, not a pass", {
  expect_error(
    mysterycall_guard_contaminated_wait(data.frame(x = 1)),
    "business_days_until_appointment"
  )
})

test_that("the condition carries the offending rows for triage", {
  bad <- data.frame(
    appointment_date                = as.Date(c("2019-07-11", NA, "2019-08-01", NA)),
    business_days_until_appointment = c(10, 10, 20, 20)
  )
  cond <- tryCatch(
    mysterycall_guard_contaminated_wait(bad, appointment_col = "appointment_date"),
    mysterycall_contaminated_wait = function(e) e
  )
  expect_equal(cond$rows, c(2L, 4L))
  expect_true(all(c("wait_without_appointment", "wait_on_excluded_call",
                    "carry_forward_runs") %in% names(cond$counts)))
})
