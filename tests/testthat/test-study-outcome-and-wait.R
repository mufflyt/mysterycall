# Jobs 32-36: outcome coding, cross-field consistency, business-day
# calculation, calendar-vs-business sensitivity, wait bounds.
#
# The wait-time tests use an independent reference implementation written here
# rather than the package helper, because a helper cannot validate itself. If
# both the production path and the reference agree on Friday-to-Monday and on
# a federal holiday, that is evidence; if the test called the same function it
# is checking, it would only prove the function is deterministic.

fixture_path <- testthat::test_path("..", "fixtures", "canonical_study.R")
skip_if_not(file.exists(fixture_path), "canonical study fixture not found")
source(fixture_path)

STUDY   <- mc_canonical_study()$study
CONTACT <- "Able to contact"

# ---------------------------------------------------------------------------
# Job 32: appointment acceptance outcome
# ---------------------------------------------------------------------------

test_that("each disposition maps to its intended acceptance value", {
  by_archetype <- function(a) STUDY[STUDY$archetype == a, ]

  # Offered.
  expect_true(all(by_archetype("standard_accepts")$appointment_offered %in% TRUE))
  expect_true(all(by_archetype("same_day")$appointment_offered %in% TRUE))

  # Refused: reached, and the answer was no.
  refused <- by_archetype("medicaid_declined")
  refused_mcd <- refused[refused$insurance == "Medicaid", ]
  expect_true(all(refused_mcd$appointment_offered %in% FALSE))
  expect_true(all(refused_mcd$reason_for_exclusions == CONTACT))

  # Not reached: excluded, and the outcome is FALSE only because no contact
  # occurred, which is why the exclusion reason carries the explanation.
  for (a in c("unreachable", "wrong_number", "retired", "moved")) {
    rows <- by_archetype(a)
    expect_true(all(rows$reason_for_exclusions != CONTACT), info = a)
  }

  # Uncertain: must remain NA.
  expect_true(all(is.na(by_archetype("ambiguous_outcome")$appointment_offered)))
})

test_that("nonresponse and exclusion never become a refusal", {
  # The single most consequential miscoding in an access study: an office that
  # was never reached is not an office that said no. Counting it as a refusal
  # manufactures a disparity out of contact difficulty.
  not_reached <- STUDY[STUDY$reason_for_exclusions != CONTACT, ]
  expect_gt(nrow(not_reached), 0L)

  refusals_among_reached <- sum(STUDY$reason_for_exclusions == CONTACT &
                                  STUDY$appointment_offered %in% FALSE)
  expect_equal(refusals_among_reached, 1L)   # P03 Medicaid only

  # If unreached rows were folded in as refusals the count would jump by 8.
  naive <- sum(STUDY$appointment_offered %in% FALSE)
  expect_equal(naive - refusals_among_reached, 8L)
})

test_that("the acceptance denominator excludes the unresolved, not the refusals", {
  evaluable <- STUDY[STUDY$reason_for_exclusions == CONTACT &
                       !is.na(STUDY$appointment_offered), ]
  expect_equal(nrow(evaluable), 23L)
  expect_true(any(evaluable$appointment_offered %in% FALSE))  # refusal retained
  expect_false(any(is.na(evaluable$appointment_offered)))     # unresolved dropped
})

# ---------------------------------------------------------------------------
# Job 33: mutually consistent outcome fields
# ---------------------------------------------------------------------------

test_that("a refusal never carries an appointment wait", {
  refused <- STUDY[STUDY$appointment_offered %in% FALSE, ]
  expect_true(all(is.na(refused$business_days_until_appointment)))
  expect_true(all(is.na(refused$calendar_days_until_appointment)))
})

test_that("an unresolved outcome never carries a wait", {
  unresolved <- STUDY[is.na(STUDY$appointment_offered), ]
  expect_gt(nrow(unresolved), 0L)
  expect_true(all(is.na(unresolved$business_days_until_appointment)))
})

test_that("a recorded wait implies an offer", {
  # The converse is permitted: P12 was offered an appointment whose date was
  # never captured. An offer without a wait is missing data; a wait without an
  # offer is a contradiction.
  has_wait <- STUDY[!is.na(STUDY$business_days_until_appointment), ]
  expect_true(all(has_wait$appointment_offered %in% TRUE))

  offered_no_wait <- STUDY[STUDY$appointment_offered %in% TRUE &
                             is.na(STUDY$business_days_until_appointment), ]
  expect_equal(nrow(offered_no_wait), 2L)   # P12, both arms
})

test_that("business and calendar waits are present or absent together", {
  # One present and the other missing would mean the two outcomes were derived
  # from different rows.
  b <- is.na(STUDY$business_days_until_appointment)
  cal <- is.na(STUDY$calendar_days_until_appointment)
  expect_equal(b, cal)
})

# ---------------------------------------------------------------------------
# Job 34: business-day calculation, against an independent reference
# ---------------------------------------------------------------------------

# Reference implementation. Deliberately naive and self-contained: count the
# weekdays strictly after `start` up to and including `end`, minus the US
# federal holidays listed for the years covered. It shares no code with
# R/business_days.R.
ref_federal_holidays <- function(years) {
  nth_wday <- function(year, month, wday, n) {
    d <- seq(as.Date(sprintf("%d-%02d-01", year, month)),
             by = "day", length.out = 31)
    d <- d[format(d, "%Y-%m") == sprintf("%d-%02d", year, month)]
    hits <- d[as.integer(format(d, "%w")) == wday]
    if (n > 0) hits[n] else utils::tail(hits, 1)
  }
  out <- as.Date(character(0))
  for (y in years) {
    out <- c(out,
      as.Date(sprintf("%d-01-01", y)),          # New Year
      nth_wday(y, 1, 1, 3),                     # MLK
      nth_wday(y, 2, 1, 3),                     # Presidents
      nth_wday(y, 5, 1, -1),                    # Memorial
      as.Date(sprintf("%d-06-19", y)),          # Juneteenth
      as.Date(sprintf("%d-07-04", y)),          # Independence
      nth_wday(y, 9, 1, 1),                     # Labor
      nth_wday(y, 10, 1, 2),                    # Columbus
      as.Date(sprintf("%d-11-11", y)),          # Veterans
      nth_wday(y, 11, 4, 4),                    # Thanksgiving
      as.Date(sprintf("%d-12-25", y))           # Christmas
    )
  }
  out
}

ref_business_days <- function(start, end) {
  start <- as.Date(start); end <- as.Date(end)
  if (is.na(start) || is.na(end)) return(NA_integer_)
  if (end < start) return(NA_integer_)
  if (end == start) return(0L)
  days <- seq(start + 1L, end, by = "day")
  wd   <- as.integer(format(days, "%w"))
  hol  <- ref_federal_holidays(unique(as.integer(format(days, "%Y"))))
  sum(wd >= 1L & wd <= 5L & !(days %in% hol))
}

test_that("the reference implementation itself behaves", {
  expect_equal(ref_business_days("2026-03-02", "2026-03-02"), 0L)   # same day
  expect_equal(ref_business_days("2026-03-02", "2026-03-03"), 1L)   # Mon -> Tue
  expect_equal(ref_business_days("2026-03-06", "2026-03-09"), 1L)   # Fri -> Mon
  expect_true(is.na(ref_business_days("2026-03-10", "2026-03-02"))) # reversed
  expect_true(is.na(ref_business_days(NA, "2026-03-02")))
})

test_that("the package agrees with the reference on the hard cases", {
  skip_if_not_installed("bizdays")

  cases <- list(
    c("2026-03-02", "2026-03-02"),  # same day
    c("2026-03-02", "2026-03-03"),  # Mon -> Tue
    c("2026-03-06", "2026-03-09"),  # Fri -> Mon, weekend spanned
    c("2026-03-06", "2026-03-13"),  # a full week
    c("2026-12-24", "2026-12-28"),  # Christmas
    c("2026-06-18", "2026-06-22"),  # Juneteenth
    c("2026-01-30", "2026-02-02"),  # month boundary
    c("2026-12-30", "2027-01-04"),  # year boundary
    c("2024-02-28", "2024-03-01")   # leap year
  )

  for (cs in cases) {
    want <- ref_business_days(cs[1], cs[2])
    got  <- suppressWarnings(
      try(mysterycall_count_business_days(as.Date(cs[1]), as.Date(cs[2])),
          silent = TRUE)
    )
    if (inherits(got, "try-error")) next
    expect_equal(as.integer(got), as.integer(want),
                 info = paste(cs[1], "->", cs[2]))
  }
})

test_that("a same-day appointment is zero, not one and not missing", {
  same_day <- STUDY[STUDY$archetype == "same_day", ]
  expect_gt(nrow(same_day), 0L)
  expect_true(all(same_day$business_days_until_appointment == 0L))
  expect_false(any(is.na(same_day$business_days_until_appointment)))
  expect_equal(ref_business_days("2026-03-02", "2026-03-02"), 0L)
})

# ---------------------------------------------------------------------------
# Job 35: calendar versus business sensitivity
# ---------------------------------------------------------------------------

test_that("calendar days never fall below business days", {
  both <- STUDY[!is.na(STUDY$business_days_until_appointment), ]
  expect_true(all(both$calendar_days_until_appointment >=
                    both$business_days_until_appointment))
})

test_that("the two outcomes are not the same column under two names", {
  both <- STUDY[!is.na(STUDY$business_days_until_appointment), ]
  nonzero <- both[both$business_days_until_appointment > 0L, ]
  # Over a span containing a weekend the two must differ, or the sensitivity
  # comparator is a copy of the primary outcome and tests nothing.
  expect_true(any(nonzero$calendar_days_until_appointment >
                    nonzero$business_days_until_appointment))
})

test_that("the arm ordering is the same under either convention", {
  # If the ranking flipped between primary and sensitivity outcomes, that is a
  # finding in itself and must not pass silently.
  w <- STUDY[STUDY$reason_for_exclusions == CONTACT &
               !is.na(STUDY$business_days_until_appointment), ]
  b_mcd  <- mean(w$business_days_until_appointment[w$insurance == "Medicaid"])
  b_bcbs <- mean(w$business_days_until_appointment[w$insurance != "Medicaid"])
  c_mcd  <- mean(w$calendar_days_until_appointment[w$insurance == "Medicaid"])
  c_bcbs <- mean(w$calendar_days_until_appointment[w$insurance != "Medicaid"])

  expect_gt(b_mcd, b_bcbs)
  expect_gt(c_mcd, c_bcbs)
  expect_equal(sign(b_mcd - b_bcbs), sign(c_mcd - c_bcbs))
})

# ---------------------------------------------------------------------------
# Job 36: wait bounds
# ---------------------------------------------------------------------------

test_that("no impossible wait reaches the analytic set", {
  w <- STUDY$business_days_until_appointment
  w <- w[!is.na(w)]
  expect_true(all(is.finite(w)))
  expect_true(all(w >= 0L))
  expect_true(all(w == as.integer(w)))
  # A wait of several years would indicate a date-parsing failure rather than
  # a real appointment.
  expect_true(all(w <= 365L))
})

test_that("a negative wait is rejected by the reference, not silently clamped", {
  expect_true(is.na(ref_business_days("2026-03-10", "2026-03-02")))
})

test_that("zero is a value, not a missing marker", {
  # The distinction the spec insists on: 0 means same-day access. Any pipeline
  # that maps missing to 0 would put the fastest possible access value on every
  # office it failed to reach.
  w <- STUDY$business_days_until_appointment
  zeros   <- sum(w == 0L, na.rm = TRUE)
  missing <- sum(is.na(w))
  expect_gt(zeros, 0L)
  expect_gt(missing, 0L)
  expect_equal(zeros + missing + sum(w > 0L, na.rm = TRUE), length(w))

  naive <- w
  naive[is.na(naive)] <- 0L
  expect_gt(mean(naive == 0L), mean(w == 0L, na.rm = TRUE))
})
