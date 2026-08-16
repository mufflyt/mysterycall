# Jobs 27-31: caller integrity, inter-caller reliability, exclusion vocabulary,
# exclusion reconciliation, denominator invariants.
#
# The reconciliation tests are the strongest gate here. Every stage of the
# funnel must account for the records it drops, because a stage that loses rows
# without a reason is indistinguishable from a stage that is working, right up
# until the denominator is reported.

fixture_path <- testthat::test_path("..", "fixtures", "canonical_study.R")
skip_if_not(file.exists(fixture_path), "canonical study fixture not found")
source(fixture_path)

S         <- mc_canonical_study()
STUDY     <- S$study
PROVIDERS <- S$providers

CONTACT  <- "Able to contact"
ARM_MCD  <- "Medicaid"
ARM_BCBS <- "Blue Cross/Blue Shield"

ALLOWED_EXCLUSIONS <- c(
  CONTACT, "Unable to contact office", "Wrong number",
  "Physician retired", "Physician moved practices"
)

# ---------------------------------------------------------------------------
# Job 27: caller integrity
# ---------------------------------------------------------------------------

test_that("every call has a caller and the roster of callers is closed", {
  expect_false(any(is.na(STUDY$caller_id)))
  expect_true(all(nzchar(STUDY$caller_id)))
  expect_setequal(unique(STUDY$caller_id), c("C1", "C2"))
})

test_that("caller workload is recorded and roughly balanced", {
  tab <- table(STUDY$caller_id)
  expect_equal(unname(tab[["C1"]]), 16L)
  expect_equal(unname(tab[["C2"]]), 17L)

  # Gross imbalance would confound caller with exposure. One call of difference
  # is the most this fixture permits.
  expect_lte(abs(tab[["C1"]] - tab[["C2"]]), 1L)
})

test_that("no provider-location-arm cell is worked by two callers", {
  # The same call must not appear under two callers, which would double-count
  # the observation while looking like independent data.
  key <- paste(STUDY$id_number, STUDY$phone, STUDY$insurance, sep = "|")
  by_key <- tapply(STUDY$caller_id, key, function(x) length(unique(x)))
  expect_true(all(by_key == 1L))
})

test_that("both callers appear in both arms", {
  tab <- table(STUDY$caller_id, STUDY$insurance)
  expect_true(all(tab > 0L))
})

# ---------------------------------------------------------------------------
# Job 28: inter-caller reliability
# ---------------------------------------------------------------------------

test_that("perfect agreement is reported as perfect", {
  d <- data.frame(
    caller  = rep(c("A", "B"), each = 6L),
    pair    = rep(paste0("case", 1:6), times = 2L),
    outcome = rep(c(1, 0, 1, 1, 0, 1), times = 2L),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_caller_reliability(
    d, caller_col = "caller", outcome_col = "outcome",
    pair_col = "pair", type = "percent_agreement"
  )
  expect_true(is.list(res) || is.data.frame(res))
  txt <- paste(utils::capture.output(print(res)), collapse = " ")
  expect_true(grepl("100|1\\.0", txt),
              info = paste("expected perfect agreement in:", txt))
})

test_that("complete disagreement is not reported as agreement", {
  d <- data.frame(
    caller  = rep(c("A", "B"), each = 6L),
    pair    = rep(paste0("case", 1:6), times = 2L),
    outcome = c(1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_caller_reliability(
    d, caller_col = "caller", outcome_col = "outcome",
    pair_col = "pair", type = "percent_agreement"
  )
  txt <- paste(utils::capture.output(print(res)), collapse = " ")
  expect_false(grepl("100(\\.0)?%", txt),
               info = paste("complete disagreement reported as perfect:", txt))
})

test_that("a single rater does not crash the reliability path", {
  d <- data.frame(
    caller  = rep("A", 5L),
    pair    = paste0("case", 1:5),
    outcome = c(1, 0, 1, 0, 1),
    stringsAsFactors = FALSE
  )
  res <- try(
    mysterycall_caller_reliability(d, caller_col = "caller",
                                   outcome_col = "outcome", pair_col = "pair",
                                   type = "percent_agreement"),
    silent = TRUE
  )
  # Either a clean result or a clear error is acceptable; a segfault or a
  # silently wrong agreement statistic is not.
  if (inherits(res, "try-error")) {
    expect_true(nzchar(as.character(res)))
  } else {
    expect_true(is.list(res) || is.data.frame(res))
  }
})

# ---------------------------------------------------------------------------
# Job 29: exclusion vocabulary
# ---------------------------------------------------------------------------

test_that("every exclusion reason comes from the allowed vocabulary", {
  observed <- unique(STUDY$reason_for_exclusions)
  unexpected <- setdiff(observed, ALLOWED_EXCLUSIONS)
  expect_equal(unexpected, character(0),
               info = paste("unrecognised reasons:",
                            paste(unexpected, collapse = " | ")))
})

test_that("no exclusion reason is blank or missing", {
  expect_false(any(is.na(STUDY$reason_for_exclusions)))
  expect_true(all(nzchar(STUDY$reason_for_exclusions)))
})

test_that("the vocabulary has no case-only or whitespace duplicates", {
  observed <- unique(STUDY$reason_for_exclusions)
  # "Wrong number" and "wrong number" would be two categories in every table.
  expect_equal(length(unique(tolower(trimws(observed)))), length(observed))
  expect_true(all(observed == trimws(observed)))
})

test_that("an excluded row never carries an appointment wait", {
  excluded <- STUDY[STUDY$reason_for_exclusions != CONTACT, ]
  expect_gt(nrow(excluded), 0L)
  expect_true(all(is.na(excluded$business_days_until_appointment)))
  expect_true(all(is.na(excluded$calendar_days_until_appointment)))
})

# ---------------------------------------------------------------------------
# Job 30: exclusion reconciliation
# ---------------------------------------------------------------------------

test_that("contactable plus excluded equals the starting roster of calls", {
  contactable <- sum(STUDY$reason_for_exclusions == CONTACT)
  excluded    <- sum(STUDY$reason_for_exclusions != CONTACT)
  expect_equal(contactable + excluded, nrow(STUDY))
  expect_equal(contactable, 25L)
  expect_equal(excluded, 8L)
})

test_that("the exclusion transition table loses no record without a reason", {
  # Each stage is a strict subset of the one above it, and the difference
  # between consecutive stages is fully explained.
  n_calls       <- nrow(STUDY)
  n_reached     <- sum(STUDY$reason_for_exclusions == CONTACT)
  n_resolved    <- sum(STUDY$reason_for_exclusions == CONTACT &
                         !is.na(STUDY$appointment_offered))
  n_offered     <- sum(STUDY$reason_for_exclusions == CONTACT &
                         STUDY$appointment_offered %in% TRUE)
  n_wait_known  <- sum(STUDY$reason_for_exclusions == CONTACT &
                         !is.na(STUDY$business_days_until_appointment))

  expect_gte(n_calls, n_reached)
  expect_gte(n_reached, n_resolved)
  expect_gte(n_resolved, n_offered)
  expect_gte(n_offered, n_wait_known)

  # Every drop is accounted for by a named cause.
  expect_equal(n_calls - n_reached, 8L)    # excluded, four reasons
  expect_equal(n_reached - n_resolved, 2L) # P11, outcome never resolved
  expect_equal(n_resolved - n_offered, 1L) # P03, Medicaid refused
  expect_equal(n_offered - n_wait_known, 2L) # P12, offered but wait unrecorded
})

test_that("each exclusion reason accounts for the expected number of calls", {
  tab <- table(STUDY$reason_for_exclusions[STUDY$reason_for_exclusions != CONTACT])
  expect_equal(unname(tab[["Unable to contact office"]]), 2L)
  expect_equal(unname(tab[["Wrong number"]]), 2L)
  expect_equal(unname(tab[["Physician retired"]]), 2L)
  expect_equal(unname(tab[["Physician moved practices"]]), 2L)
  expect_equal(sum(tab), 8L)
})

test_that("exclusion is decided per provider, not per arm", {
  # A provider excluded for being retired must be excluded on both calls.
  # An exclusion that applies to one arm only would bias the comparison.
  excluded_ids <- unique(STUDY$id_number[STUDY$reason_for_exclusions != CONTACT])
  for (id in excluded_ids) {
    rows <- STUDY[STUDY$id_number == id, ]
    expect_equal(length(unique(rows$reason_for_exclusions)), 1L,
                 info = paste("provider", id, "has mixed exclusion status"))
  }
})

# ---------------------------------------------------------------------------
# Job 31: denominator invariants
# ---------------------------------------------------------------------------

test_that("each headline denominator is explicit and frozen", {
  acceptance <- STUDY[STUDY$reason_for_exclusions == CONTACT &
                        !is.na(STUDY$appointment_offered), ]
  wait <- STUDY[STUDY$reason_for_exclusions == CONTACT &
                  !is.na(STUDY$business_days_until_appointment), ]

  expect_equal(nrow(acceptance), 23L)
  expect_equal(nrow(wait), 20L)
  expect_equal(sum(acceptance$insurance == ARM_MCD), 12L)
  expect_equal(sum(acceptance$insurance == ARM_BCBS), 11L)
  expect_equal(sum(wait$insurance == ARM_MCD), 10L)
  expect_equal(sum(wait$insurance == ARM_BCBS), 10L)
})

test_that("the wait denominator is a strict subset of the acceptance one", {
  acc_key <- paste(STUDY$id_number, STUDY$phone, STUDY$insurance)[
    STUDY$reason_for_exclusions == CONTACT & !is.na(STUDY$appointment_offered)]
  wait_key <- paste(STUDY$id_number, STUDY$phone, STUDY$insurance)[
    STUDY$reason_for_exclusions == CONTACT &
      !is.na(STUDY$business_days_until_appointment)]

  expect_true(all(wait_key %in% acc_key))
  expect_lt(length(wait_key), length(acc_key))
})

test_that("complete-case accounting adds up for the wait-time model", {
  # input = modelled + excluded, with every exclusion attributable.
  input <- nrow(STUDY)
  excluded_not_reached <- sum(STUDY$reason_for_exclusions != CONTACT)
  excluded_no_outcome  <- sum(STUDY$reason_for_exclusions == CONTACT &
                                is.na(STUDY$business_days_until_appointment))
  modelled <- sum(STUDY$reason_for_exclusions == CONTACT &
                    !is.na(STUDY$business_days_until_appointment))

  expect_equal(input, modelled + excluded_not_reached + excluded_no_outcome)
  expect_equal(modelled, 20L)
})
