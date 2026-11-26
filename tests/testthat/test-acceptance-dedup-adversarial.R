# Adversarial tests pinning the physician-level reachability fix.
# The bug being pinned: with duplicate call rows, a physician reachable in
# any row was still subtracted from the denominator when they also had an
# unreachable row. The numerator could then exceed the denominator, and the
# Wilson-interval prop.test() errored, crashing the entire calculation over
# one doubly-entered office.

mk <- function(phones, reasons, waits, insurance = "Medicaid") {
  data.frame(
    insurance = insurance,
    reason_for_exclusions = reasons,
    phone = phones,
    business_days_until_appointment = waits,
    stringsAsFactors = FALSE
  )
}

test_that("a physician reachable in ANY row is never excluded", {
  df <- mk(c("111", "111", "222"),
           c("Able to contact", "Office closed", "Able to contact"),
           c(5, NA, 3))
  r <- mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  expect_equal(r$table$n_excluded, 0L)
  expect_equal(r$table$n_denominator, 2L)
  expect_equal(r$table$n_numerator, 2L)
  # critically: no crash, and the rate is a possible value
  expect_lte(r$table$rate_pct, 100)
})

test_that("numerator can never exceed denominator, so prop.test never errors", {
  # worst case: every physician has BOTH an accepting row and an unreachable row
  df <- mk(c("111", "111", "222", "222", "333", "333"),
           rep(c("Able to contact", "Office closed"), 3L),
           c(5, NA, 3, NA, 1, NA))
  r <- mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  expect_lte(r$table$n_numerator, r$table$n_denominator)
  expect_equal(r$table$rate_pct, 100)
})

test_that("reached-but-declined physicians stay in the denominator even with a second unreachable row", {
  df <- mk(c("111", "111", "222"),
           c("Not accepting new patients", "Office closed", "Able to contact"),
           c(NA, NA, 3))
  r <- mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  expect_equal(r$table$n_excluded, 0L)
  expect_equal(r$table$n_denominator, 2L)
  expect_equal(r$table$n_numerator, 1L)
})

test_that("a truly unreachable physician is still excluded", {
  df <- mk(c("111", "222", "222"),
           c("Able to contact", "Office closed", "No answer"),
           c(5, NA, NA))
  r <- mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  expect_equal(r$table$n_excluded, 1L)
  expect_equal(r$table$n_denominator, 1L)
  expect_equal(r$table$n_numerator, 1L)
})

test_that("clean one-row-per-physician data is numerically unchanged", {
  df <- mk(c("111", "222", "333", "444"),
           c("Able to contact", "Office closed", "Not accepting new patients", "Able to contact"),
           c(5, NA, NA, 3))
  r <- mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  expect_equal(r$table$n_total, 4L)
  expect_equal(r$table$n_excluded, 1L)
  expect_equal(r$table$n_denominator, 3L)
  expect_equal(r$table$n_numerator, 2L)
})

test_that("same-day appointments (wait == 0) count as accepted", {
  df <- mk(c("111", "222"), c("Able to contact", "Able to contact"), c(0, 5))
  r <- mysterycall_acceptance_rate_calc(df, insurance_groups = "Medicaid")
  expect_equal(r$table$n_numerator, 2L)
})

test_that("the overall row obeys the same invariant", {
  df <- mk(c("111", "111", "222", "333", "333"),
           c("Able to contact", "Office closed", "Able to contact", "Office closed", "No answer"),
           c(5, NA, 3, NA, NA),
           insurance = c("Medicaid", "Medicaid", "BCBS", "BCBS", "BCBS"))
  r <- mysterycall_acceptance_rate_calc(df, insurance_groups = c("Medicaid", "BCBS"))
  expect_lte(r$overall$n_numerator, r$overall$n_denominator)
})
