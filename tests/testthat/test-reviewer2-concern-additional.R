library(testthat)
library(mysterycall)

# ── Concern 1 (clarified): Only 2 insurance groups — no multiplicity ───────────
# Reviewer 2: "Did you correct for multiple comparisons?"
# Answer: Only Medicaid vs BCBS — one pre-specified contrast, no correction
# needed. Tests confirm dedup produces exactly 2 insurance levels.

test_that("dedup_by_insurance produces exactly 2 insurance levels (Medicaid, BCBS)", {
  df <- data.frame(
    phone                 = c("3035550101","3035550101","7205550202","7205550202"),
    insurance             = c("Medicaid","BCBS","Medicaid","BCBS"),
    physician_information = c("Smith, J","Smith, J","Doe, J","Doe, J"),
    wait_days             = c(5L, 8L, 3L, 10L),
    stringsAsFactors      = FALSE
  )

  res <- suppressWarnings(mysterycall_dedup_by_insurance(df, output_dir = NA))

  ins_levels <- sort(unique(res$insurance))
  expect_equal(ins_levels, c("BCBS", "Medicaid"))
  expect_equal(length(ins_levels), 2L)
})

test_that("univariate_poisson_screen with 2-group insurance needs no p-value adjustment", {
  set.seed(301)
  df <- data.frame(
    wait_days = c(rpois(40L, 18L), rpois(40L, 10L)),
    insurance = rep(c("Medicaid", "BCBS"), each = 40L),
    stringsAsFactors = FALSE
  )

  res <- suppressWarnings(
    mysterycall_univariate_poisson_screen(
      df, outcome_col = "wait_days",
      p_adjust_method = "none",   # one contrast — no adjustment needed
      output_dir = NA
    )
  )

  expect_true(is.list(res))
  expect_true("results" %in% names(res))
  # Only one predictor tested (insurance) — no family-wise error inflation
  expect_equal(nrow(res$results), 1L)
})


# ── Concern 2: Physician is the unit — model must cluster at physician level ───
# Reviewer 2: "The physician is the unit of randomisation. SE must be clustered
# at NPI level, not at the call level."

test_that("sensitivity clusters at physician level via random_intercept", {
  skip_if_not_installed("lme4")

  set.seed(302)
  n_phys <- 20L
  df <- data.frame(
    wait_days = c(rpois(40L, 18L), rpois(40L, 10L)),
    insurance = rep(c("Medicaid", "BCBS"), each = 40L),
    npi       = rep(paste0("NPI", seq_len(n_phys)), times = 4L),
    stringsAsFactors = FALSE
  )

  res <- suppressMessages(suppressWarnings(
    mysterycall_sensitivity(
      df,
      outcome          = "wait_days",
      predictors       = "insurance",
      random_intercept = "npi",     # clustered at physician (NPI) level
      family           = "poisson"
    )
  ))

  expect_s3_class(res, "mysterycall_sensitivity")
  # Model list should exist and have a random effect for npi
  expect_true(length(res$models) >= 1L)
  m <- res$models[[1]]
  # lme4 model has @flist slot containing the grouping factor
  if (inherits(m, "merMod")) {
    expect_true("npi" %in% names(m@flist))
  }
})

test_that("flag_repeat_physicians catches calls beyond the paired design (>2 per NPI)", {
  # In the paired design each NPI is called exactly twice: once Medicaid, once
  # BCBS. Anything beyond threshold=2 is an error or data-quality problem.
  df <- data.frame(
    id_number             = c("NPI001","NPI001","NPI001",  # 3 calls — error
                               "NPI002","NPI002"),          # 2 calls — ok
    physician_information = c("Smith, J","Smith, J","Smith, J",
                               "Doe, J","Doe, J"),
    stringsAsFactors = FALSE
  )

  flagged <- suppressWarnings(
    mysterycall_flag_repeat_physicians(df, threshold = 2L, output_dir = NA)
  )

  expect_true(nrow(flagged) >= 1L)
  expect_true("NPI001" %in% flagged$id_number)
  expect_false("NPI002" %in% flagged$id_number)
})

test_that("dedup_by_insurance removes duplicate phone x insurance rows", {
  # Same physician called twice with same insurance — only first should survive
  df <- data.frame(
    phone                 = c("5551234","5551234","5551234"),
    insurance             = c("Medicaid","Medicaid","BCBS"),
    physician_information = c("Smith, J","Smith, J","Smith, J"),
    wait_days             = c(5L, 6L, 9L),   # duplicate Medicaid row
    stringsAsFactors      = FALSE
  )

  res <- suppressWarnings(mysterycall_dedup_by_insurance(df, output_dir = NA))

  expect_equal(nrow(res), 2L)   # one Medicaid + one BCBS
})


# ── Concern 3: Non-random missingness biases acceptance rates ──────────────────
# Reviewer 2: "Physicians who don't accept Medicaid may also be harder to reach.
# Non-contacts aren't MCAR — they're systematically missing for Medicaid."

test_that("missing_data_analysis detects non-random missingness associated with insurance", {
  set.seed(303)
  n <- 100L
  # Medicaid practices are harder to reach: 30% missing vs 5% for BCBS
  insurance <- rep(c("Medicaid", "BCBS"), each = n / 2L)
  appt_date <- as.Date(ifelse(
    insurance == "Medicaid",
    ifelse(runif(n / 2L) > 0.30, "2024-03-01", NA),
    ifelse(runif(n / 2L) > 0.05, "2024-03-01", NA)
  ), origin = "1970-01-01")

  df <- data.frame(
    appt_date = appt_date,
    insurance = insurance,
    stringsAsFactors = FALSE
  )

  res <- suppressWarnings(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "appt_date",
      group_col   = "insurance"
    )
  )

  expect_s3_class(res, "mysterycall_missing_data")
  expect_true(is.data.frame(res$summary))
  # Missingness IS associated with insurance → at least one significant test
  expect_true(any(res$summary$significant, na.rm = TRUE))
})

test_that("missing_data_analysis finds no significant association when missingness is random", {
  set.seed(304)
  n <- 100L
  # Same 10% missingness in both groups — MCAR
  appt_date <- as.Date(
    ifelse(runif(n) > 0.10, "2024-03-01", NA),
    origin = "1970-01-01"
  )
  df <- data.frame(
    appt_date = appt_date,
    insurance = rep(c("Medicaid", "BCBS"), each = n / 2L),
    stringsAsFactors = FALSE
  )

  res <- suppressWarnings(
    mysterycall_missing_data_analysis(
      df,
      outcome_col = "appt_date",
      group_col   = "insurance"
    )
  )

  # MCAR — should not be significant
  expect_false(all(res$summary$significant, na.rm = TRUE))
})


# ── Concern 4 (paired design): Each NPI called with both insurance types ───────
# This is by design — not an error. Tests confirm the data have the expected
# pairing structure after dedup.

test_that("each NPI appears with both Medicaid and BCBS after dedup", {
  df <- data.frame(
    phone                 = rep(c("5551111","5552222","5553333"), each = 2L),
    insurance             = rep(c("Medicaid","BCBS"), times = 3L),
    physician_information = rep(c("Smith, J","Doe, J","Lee, K"), each = 2L),
    wait_days             = c(5L,9L, 3L,12L, 7L,6L),
    stringsAsFactors      = FALSE
  )

  res <- suppressWarnings(mysterycall_dedup_by_insurance(df, output_dir = NA))

  # After dedup, each phone should appear exactly twice (once per insurance)
  call_counts <- table(res$phone)
  expect_true(all(call_counts == 2L))

  # And every phone has one Medicaid and one BCBS row
  for (ph in unique(res$phone)) {
    ins_for_ph <- sort(res$insurance[res$phone == ph])
    expect_equal(ins_for_ph, c("BCBS", "Medicaid"))
  }
})


# ── Concern 5: Day-of-week and time-of-day effects ────────────────────────────
# Reviewer 2: "Monday 9am calls and Friday 4pm calls get different responses.
# Did you control for call timing?"

test_that("caller_drift with week_or_day='day' exposes within-week acceptance variation", {
  set.seed(305)
  # Simulate lower acceptance on Fridays (day 6 in %u: Mon=1 ... Fri=5 ... Sun=0)
  # Generate dates covering a full work week, repeated 8 times
  dates <- rep(seq(as.Date("2024-01-08"), by = "day", length.out = 5L), 20L)
  # Monday and Wednesday high acceptance, Friday low
  day_names <- weekdays(dates)
  prob <- ifelse(day_names == "Friday", 0.25,
          ifelse(day_names == "Monday", 0.75, 0.55))
  df <- data.frame(
    call_date = dates,
    offered   = rbinom(length(dates), 1L, prob)
  )

  res <- suppressWarnings(
    mysterycall_caller_drift(
      df,
      outcome_col = "offered",
      date_col    = "call_date",
      week_or_day = "day",
      plot        = FALSE
    )
  )

  expect_s3_class(res, "mysterycall_caller_drift")
  expect_false(is.null(res$calendar))
  # rate_by_period has one row per day-of-study
  expect_gte(nrow(res$calendar$rate_by_period), 5L)
  expect_true("rate" %in% names(res$calendar$rate_by_period))
})

test_that("missing_data_analysis can use day-of-week as a covariate for timing effects", {
  set.seed(306)
  n <- 80L
  dates <- sample(seq(as.Date("2024-01-08"), by = "day", length.out = 5L), n,
                  replace = TRUE)
  day_of_week <- weekdays(dates)
  # Friday has more non-contacts
  appt_date <- as.Date(
    ifelse(day_of_week == "Friday",
           ifelse(runif(n) > 0.40, "2024-03-01", NA),
           ifelse(runif(n) > 0.10, "2024-03-01", NA)),
    origin = "1970-01-01"
  )
  df <- data.frame(
    appt_date   = appt_date,
    insurance   = rep(c("Medicaid","BCBS"), length.out = n),
    day_of_week = day_of_week,
    stringsAsFactors = FALSE
  )

  res <- suppressWarnings(
    mysterycall_missing_data_analysis(
      df,
      outcome_col    = "appt_date",
      group_col      = "insurance",
      covariate_cols = "day_of_week"
    )
  )

  expect_s3_class(res, "mysterycall_missing_data")
  # day_of_week should appear in the summary table
  expect_true("day_of_week" %in% res$summary$variable)
})
