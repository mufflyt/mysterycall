# =============================================================================
# Independent wait-time reference  --  spec sections 24, 25, 28, 43, 62
# =============================================================================
# Section 43: "The reference implementation must not call the production
# function being tested." Section 24: "Wait time deserves an independent
# implementation ... a simple reference function that does not use production
# helpers."
#
# So nothing below calls mysterycall_count_business_days(), and nothing below
# uses bizdays. The holiday table is written out as LITERAL observed dates
# rather than recomputed, because recomputing them with the same nth-weekday
# and observed-shift logic would reproduce a production bug rather than catch
# it. The point is a second opinion, not a second copy.
#
# The contract this checks (inst/contract/scientific_contract.yml, DERIVED):
#   primary_outcome       business_days_until_appointment
#   wait_time_definition  Mon-Fri working days, excluding US federal holidays,
#                         between the call date and the offered appointment date
#
# CONVENTION, reverse-engineered from production and pinned below:
#
#     wait = max(0, <business days in the CLOSED interval [call, appt]> - 1)
#
# bizdays adjusts the start forward and the end backward onto business days
# before counting, which is what this identity captures. Verified against 400
# random date pairs, not just hand-picked ones.
#
# This was documented nowhere. R/business_days.R says only "between the call
# date and the offered appointment date", which does not distinguish the
# candidate conventions. They agree whenever BOTH endpoints are working days --
# which is why the ambiguity is easy to miss, and why the first two versions of
# this reference were wrong in opposite directions. They diverge only when a
# call or an appointment lands on a weekend or holiday.
#
# One consequence is asserted explicitly below: a SATURDAY call seen the
# following Monday scores 0 business days, identical to a same-day appointment.
# Whether that is right is a SCIENTIFIC CHOICE, and the contract field
# `wait_time_endpoint_inclusivity` is still UNRESOLVED. These tests pin current
# behaviour so that changing it can never be silent.

# --- literal US federal holidays, observed dates -----------------------------
.ref_holidays <- as.Date(c(
  # 2024
  "2024-01-01","2024-01-15","2024-02-19","2024-05-27","2024-06-19","2024-07-04",
  "2024-09-02","2024-10-14","2024-11-11","2024-11-28","2024-12-25",
  # 2025
  "2025-01-01","2025-01-20","2025-02-17","2025-05-26","2025-06-19","2025-07-04",
  "2025-09-01","2025-10-13","2025-11-11","2025-11-27","2025-12-25",
  # 2026 -- Jul 4 falls Saturday, observed Friday Jul 3
  "2026-01-01","2026-01-19","2026-02-16","2026-05-25","2026-06-19","2026-07-03",
  "2026-09-07","2026-10-12","2026-11-11","2026-11-26","2026-12-25",
  # 2027 -- Jun 19 Sat -> Fri 18; Jul 4 Sun -> Mon 5; Dec 25 Sat -> Fri 24
  "2027-01-01","2027-01-18","2027-02-15","2027-05-31","2027-06-18","2027-07-05",
  "2027-09-06","2027-10-11","2027-11-11","2027-11-25","2027-12-24"
))

# --- the reference implementation: base R, deliberately obvious --------------
.ref_business_days <- function(call_date, appt_date) {
  call_date <- as.Date(call_date); appt_date <- as.Date(appt_date)
  n <- max(length(call_date), length(appt_date))
  call_date <- rep_len(call_date, n); appt_date <- rep_len(appt_date, n)
  out <- rep(NA_integer_, n)
  for (i in seq_len(n)) {
    a <- call_date[i]; b <- appt_date[i]
    if (is.na(a) || is.na(b) || b < a) next          # unresolved stays unresolved
    days <- seq(a, b, by = "day")                    # CLOSED interval [a, b]
    wd   <- as.integer(format(days, "%w"))           # 0 = Sunday, 6 = Saturday
    nbiz <- sum(wd >= 1L & wd <= 5L & !(days %in% .ref_holidays))
    out[i] <- max(0L, nbiz - 1L)
  }
  out
}

# How many business days sit in the closed interval -- used by the mutants below.
.ref_nbiz_closed <- function(a, b) {
  d <- seq(as.Date(a), as.Date(b), by = "day"); w <- as.integer(format(d, "%w"))
  sum(w >= 1L & w <= 5L & !(d %in% .ref_holidays))
}

prod_bd <- function(a, b) suppressWarnings(
  mysterycall_count_business_days(a, b, mysterycall_us_federal_calendar(2024, 2027))
)

# --- the holiday calendar itself (section 24) --------------------------------
test_that("production's holiday calendar matches an independently written list", {
  cal <- mysterycall_us_federal_calendar(2024, 2027)
  got <- sort(as.Date(cal$holidays))
  got <- got[got >= as.Date("2024-01-01") & got <= as.Date("2027-12-31")]
  expect_identical(got, sort(.ref_holidays))
  # Eleven federal holidays a year, every year. A calendar that quietly loses
  # one shortens every wait that spans it.
  expect_true(all(table(format(got, "%Y")) == 11L))
})

# --- section 24 edge cases ---------------------------------------------------
test_that("wait time reproduces under an independent implementation at the edges", {
  cases <- list(
    list("2026-03-02", "2026-03-02", 0L,  "same-day appointment is zero"),
    list("2026-03-02", "2026-03-03", 1L,  "next day"),
    list("2026-03-06", "2026-03-09", 1L,  "Friday to Monday skips the weekend"),
    list("2026-12-24", "2026-12-28", 1L,  "spans Christmas"),
    list("2026-03-07", "2026-03-09", 0L,  "Saturday call, Monday appointment -- see the header note"),
    list("2026-12-30", "2027-01-04", 2L,  "spans the year boundary and New Year"),
    list("2024-02-28", "2024-03-01", 2L,  "leap day is a working day"),
    list("2026-07-02", "2026-07-06", 1L,  "Jul 4 Saturday, observed Friday Jul 3"),
    list("2026-01-30", "2026-02-02", 1L,  "month boundary"),
    list("2026-11-25", "2026-11-30", 2L,  "spans Thanksgiving")
  )
  for (cs in cases) {
    ref  <- .ref_business_days(cs[[1]], cs[[2]])
    prod <- prod_bd(cs[[1]], cs[[2]])
    expect_identical(ref, cs[[3]], info = paste("reference disagrees:", cs[[4]]))
    expect_identical(prod, cs[[3]], info = paste("production disagrees:", cs[[4]]))
  }
})

test_that("reference and production agree across a dense grid of date pairs", {
  set.seed(20260815)
  starts <- as.Date("2024-01-01") + sample.int(1000, 400, replace = TRUE)
  ends   <- starts + sample(0:120, 400, replace = TRUE)
  expect_identical(.ref_business_days(starts, ends), prod_bd(starts, ends))
})

# --- section 28: zero, missing and impossible must stay distinct -------------
test_that("zero, missing and impossible waits remain three different things", {
  same_day  <- prod_bd("2026-03-02", "2026-03-02")
  missing   <- prod_bd("2026-03-02", NA)
  backwards <- prod_bd("2026-03-03", "2026-03-02")

  expect_identical(same_day, 0L)      # a real, fast appointment
  expect_true(is.na(missing))         # unknown -- must NOT be 0
  expect_true(is.na(backwards))       # impossible -- must NOT be 0 or negative
  expect_false(isTRUE(missing == 0L))
  expect_true(all(.ref_business_days(
    c("2026-03-02","2026-03-02","2026-03-03"),
    c("2026-03-02",  NA,          "2026-03-02")) %in% c(0L, NA_integer_)))
})

test_that("no wait is ever negative", {
  set.seed(1L)
  a <- as.Date("2025-01-01") + sample.int(400, 200, replace = TRUE)
  b <- a + sample(-30:90, 200, replace = TRUE)
  w <- .ref_business_days(a, b)
  expect_true(all(is.na(w) | w >= 0L))
  expect_true(all(is.na(prod_bd(a, b)) | prod_bd(a, b) >= 0L))
})

# --- section 25: every listed mutation must be detectable --------------------
# Each mutant is a plausible wrong implementation. The assertion is that it
# DIFFERS from the reference somewhere in this grid, i.e. that the suite above
# would catch it. A mutant that cannot be distinguished is an untested
# behaviour, whatever the coverage report says.
test_that("each business-day mutation from section 25 is detectable", {
  set.seed(4242)
  a <- as.Date("2025-01-01") + sample.int(700, 300, replace = TRUE)
  b <- a + sample(0:90, 300, replace = TRUE)
  truth <- .ref_business_days(a, b)

  mutants <- list(
    "calendar days instead of business days" =
      as.integer(b - a),
    # The off-by-one that the "- 1" exists to prevent: counting both endpoints.
    "both endpoints inclusive (no minus one)" =
      vapply(seq_along(a), function(i) .ref_nbiz_closed(a[i], b[i]), integer(1)),
    "subtract one twice" =
      vapply(seq_along(a), function(i)
        max(0L, .ref_nbiz_closed(a[i], b[i]) - 2L), integer(1)),
    "treat Saturday as a business day" =
      vapply(seq_along(a), function(i) {
        d <- seq(a[i], b[i], by = "day"); w <- as.integer(format(d, "%w"))
        max(0L, sum(w >= 1L & w <= 6L & !(d %in% .ref_holidays)) - 1L)
      }, integer(1)),
    "ignore federal holidays" =
      vapply(seq_along(a), function(i) {
        d <- seq(a[i], b[i], by = "day"); w <- as.integer(format(d, "%w"))
        max(0L, sum(w >= 1L & w <= 5L) - 1L)
      }, integer(1)),
    "subtract one universally from the correct answer" =
      pmax(truth - 1L, 0L)
  )

  for (nm in names(mutants)) {
    expect_false(identical(mutants[[nm]], truth),
                 info = paste0("SURVIVING MUTANT -- indistinguishable from the ",
                               "correct wait: ", nm))
  }
})

test_that("the calendar-day comparator is always >= the business-day outcome", {
  # The fixture freezes both precisely so a silent swap cannot pass. This is the
  # relationship that makes such a swap visible.
  set.seed(7L)
  a <- as.Date("2025-03-01") + sample.int(500, 250, replace = TRUE)
  b <- a + sample(0:60, 250, replace = TRUE)
  business <- .ref_business_days(a, b)
  calendar <- as.integer(b - a)
  ok <- !is.na(business)
  expect_true(all(calendar[ok] >= business[ok]))
})
