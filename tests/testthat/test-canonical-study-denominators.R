# Denominator invariants for the canonical synthetic study.
#
# The failure this guards against: an upstream change drops rows, the model
# still fits, the p-value still looks reasonable, and nothing announces that
# the analysis now rests on fewer observations. Freezing the denominators makes
# that change loud.
#
# Two kinds of assertion here, and the distinction matters.
#
#   Structural invariants hold by construction and would be bugs in any
#   fixture: the parts must sum to the whole, no excluded row may lack a
#   reason, no wait may be negative. These should never need updating.
#
#   Frozen counts are specific to this fixture. If one changes, either the
#   change is a defect or the fixture was edited deliberately -- in which case
#   canonical_study_expected.json is updated in the same commit, and reviewing
#   that diff is reviewing a change to the study's denominators.

skip_if_not_installed("jsonlite")

fixture_path  <- testthat::test_path("..", "fixtures", "canonical_study.R")
expected_path <- testthat::test_path("..", "fixtures", "canonical_study_expected.json")

skip_if_not(file.exists(fixture_path), "canonical study fixture not found")
source(fixture_path)

EXP <- jsonlite::fromJSON(expected_path, simplifyVector = TRUE)

# The expectations file documents itself with "_comment" keys. Iterating a
# block's names would otherwise treat the prose as a group label and compare a
# proportion against a sentence.
keys <- function(x) setdiff(names(x), grep("^_", names(x), value = TRUE))

S   <- mc_canonical_study()
STUDY     <- S$study
PROVIDERS <- S$providers
CONTACT   <- "Able to contact"

# ---------------------------------------------------------------------------
# Structural invariants: true by construction, never expected to change.
# ---------------------------------------------------------------------------

test_that("the parts sum to the whole", {
  n <- nrow(STUDY)

  contactable <- sum(STUDY$reason_for_exclusions == CONTACT)
  excluded    <- sum(STUDY$reason_for_exclusions != CONTACT)
  expect_equal(contactable + excluded, n)

  offered <- c(
    sum(STUDY$appointment_offered %in% TRUE),
    sum(STUDY$appointment_offered %in% FALSE),
    sum(is.na(STUDY$appointment_offered))
  )
  expect_equal(sum(offered), n)

  present <- sum(!is.na(STUDY$business_days_until_appointment))
  missing <- sum(is.na(STUDY$business_days_until_appointment))
  expect_equal(present + missing, n)
})

test_that("no row is excluded without a reason from the allowed vocabulary", {
  excluded <- STUDY$reason_for_exclusions[STUDY$reason_for_exclusions != CONTACT]
  expect_true(all(nzchar(excluded)))
  expect_true(all(!is.na(excluded)))
  expect_true(all(excluded %in% EXP$exclusions$allowed_vocabulary))
})

test_that("no wait is negative and every recorded wait is finite", {
  w <- STUDY$business_days_until_appointment
  w <- w[!is.na(w)]
  expect_true(all(is.finite(w)))
  expect_true(all(w >= 0))

  cal <- STUDY$calendar_days_until_appointment
  cal <- cal[!is.na(cal)]
  expect_true(all(is.finite(cal)))
  expect_true(all(cal >= 0))
})

test_that("an ambiguous outcome never collapses into a refusal", {
  # P11 was reached but the outcome could not be determined. Treating that as
  # "no appointment offered" would inflate the refusal count and bias the
  # acceptance rate downward.
  ambiguous <- STUDY[STUDY$archetype == "ambiguous_outcome", ]
  expect_gt(nrow(ambiguous), 0)
  expect_true(all(is.na(ambiguous$appointment_offered)))
  expect_true(all(ambiguous$reason_for_exclusions == CONTACT))
})

# ---------------------------------------------------------------------------
# Frozen denominators.
# ---------------------------------------------------------------------------

test_that("roster counts match the frozen expectations", {
  expect_equal(nrow(PROVIDERS), EXP$roster$providers)
  expect_equal(length(unique(stats::na.omit(PROVIDERS$npi))), EXP$roster$unique_npis)
  expect_equal(sum(duplicated(stats::na.omit(PROVIDERS$npi))), EXP$roster$duplicated_npis)
  expect_equal(sum(is.na(PROVIDERS$npi)), EXP$roster$missing_npi)
  expect_equal(sum(PROVIDERS$academic), EXP$roster$academic_providers)
})

test_that("call counts match the frozen expectations", {
  expect_equal(nrow(STUDY), EXP$calls$total)
  for (arm in keys(EXP$calls$by_arm)) {
    expect_equal(sum(STUDY$insurance == arm), EXP$calls$by_arm[[arm]],
                 info = paste("arm:", arm))
  }
  for (caller in keys(EXP$calls$by_caller)) {
    expect_equal(sum(STUDY$caller_id == caller), EXP$calls$by_caller[[caller]],
                 info = paste("caller:", caller))
  }
})

test_that("exclusion reconciliation matches the frozen expectations", {
  expect_equal(sum(STUDY$reason_for_exclusions == CONTACT), EXP$exclusions$contactable)
  expect_equal(sum(STUDY$reason_for_exclusions != CONTACT), EXP$exclusions$excluded)
  for (reason in keys(EXP$exclusions$by_reason)) {
    expect_equal(sum(STUDY$reason_for_exclusions == reason),
                 EXP$exclusions$by_reason[[reason]],
                 info = paste("reason:", reason))
  }
})

test_that("analytic denominators match the frozen expectations", {
  acc <- STUDY[STUDY$reason_for_exclusions == CONTACT &
                 !is.na(STUDY$appointment_offered), ]
  expect_equal(nrow(acc), EXP$denominators$acceptance_analytic_n)

  wait <- STUDY[STUDY$reason_for_exclusions == CONTACT &
                  !is.na(STUDY$business_days_until_appointment), ]
  expect_equal(nrow(wait), EXP$denominators$wait_time_analytic_n)

  for (arm in keys(EXP$denominators$wait_time_by_arm)) {
    expect_equal(sum(wait$insurance == arm),
                 EXP$denominators$wait_time_by_arm[[arm]],
                 info = paste("wait arm:", arm))
  }
})

# ---------------------------------------------------------------------------
# Independently recomputed statistics.
# ---------------------------------------------------------------------------

test_that("acceptance proportions match, recomputed from base R", {
  acc <- STUDY[STUDY$reason_for_exclusions == CONTACT &
                 !is.na(STUDY$appointment_offered), ]
  for (arm in keys(EXP$acceptance)) {
    got <- mean(acc$appointment_offered[acc$insurance == arm])
    expect_equal(round(got, 4), EXP$acceptance[[arm]], tolerance = 1e-6,
                 info = paste("acceptance arm:", arm))
  }
})

test_that("wait-time statistics match, recomputed from base R", {
  wait <- STUDY[STUDY$reason_for_exclusions == CONTACT &
                  !is.na(STUDY$business_days_until_appointment), ]
  for (arm in keys(EXP$wait_times$business_days)) {
    b <- wait$business_days_until_appointment[wait$insurance == arm]
    e <- EXP$wait_times$business_days[[arm]]
    expect_equal(length(b), e$n,      info = paste("business n:", arm))
    expect_equal(mean(b),   e$mean,   tolerance = 1e-6, info = paste("business mean:", arm))
    expect_equal(stats::median(b), e$median, tolerance = 1e-6,
                 info = paste("business median:", arm))
  }
  for (arm in keys(EXP$wait_times$calendar_days)) {
    cal <- wait$calendar_days_until_appointment[wait$insurance == arm]
    e   <- EXP$wait_times$calendar_days[[arm]]
    expect_equal(mean(cal), e$mean, tolerance = 1e-6, info = paste("calendar mean:", arm))
  }
})

# ---------------------------------------------------------------------------
# Qualitative directions. Reversing one of these changes the study's answer.
# ---------------------------------------------------------------------------

test_that("the primary and sensitivity outcomes are not swapped", {
  # A calendar-day wait can never be shorter than the business-day wait over
  # the same interval. If this ever fails, the two columns have been exchanged
  # somewhere upstream -- a change that leaves every model running and every
  # p-value plausible.
  both <- STUDY[!is.na(STUDY$business_days_until_appointment) &
                  !is.na(STUDY$calendar_days_until_appointment), ]
  expect_true(all(both$calendar_days_until_appointment >=
                    both$business_days_until_appointment))
  expect_true(EXP$directions$calendar_ge_business_every_row)
})

test_that("the expected qualitative directions hold", {
  wait <- STUDY[STUDY$reason_for_exclusions == CONTACT &
                  !is.na(STUDY$business_days_until_appointment), ]
  mcd  <- mean(wait$business_days_until_appointment[wait$insurance == "Medicaid"])
  bcbs <- mean(wait$business_days_until_appointment[
    wait$insurance == "Blue Cross/Blue Shield"])
  expect_true(mcd > bcbs)
  expect_true(EXP$directions$medicaid_wait_longer)

  acc <- STUDY[STUDY$reason_for_exclusions == CONTACT &
                 !is.na(STUDY$appointment_offered), ]
  a_mcd  <- mean(acc$appointment_offered[acc$insurance == "Medicaid"])
  a_bcbs <- mean(acc$appointment_offered[acc$insurance == "Blue Cross/Blue Shield"])
  expect_true(a_mcd < a_bcbs)
  expect_true(EXP$directions$medicaid_acceptance_lower)
})

# ---------------------------------------------------------------------------
# The fixture must stay deterministic.
# ---------------------------------------------------------------------------

test_that("the fixture is deterministic and does not consume RNG", {
  set.seed(1)
  a <- mc_canonical_study()$study
  s1 <- .Random.seed
  set.seed(1)
  b <- mc_canonical_study()$study
  s2 <- .Random.seed

  expect_identical(a, b)
  # Building the fixture must not advance the RNG stream, or the counts frozen
  # above would drift with any change to R's sampler.
  expect_identical(s1, s2)
})
