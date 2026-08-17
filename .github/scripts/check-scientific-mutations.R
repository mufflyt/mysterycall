#!/usr/bin/env Rscript
#
# Scientific mutation campaign. Spec sections 64-65.
#
# Run from the repository root:
#     Rscript .github/scripts/check-scientific-mutations.R
#
# Every other gate in this repository asserts that correct data passes. This
# one asserts the opposite and is therefore the only gate that can tell whether
# the others are load-bearing: it corrupts the canonical study in each of the
# specific ways a mystery-caller analysis goes wrong, reruns the study-integrity
# suite against the corrupted data, and requires the suite to FAIL.
#
# A mutant that survives is a hole. It means the corresponding scientific error
# could be introduced into the real pipeline and every test would still be
# green -- which is exactly the state a passing test suite is supposed to rule
# out.
#
# Each mutant below is drawn from spec section 65's mandatory list and is
# stated as the analytic mistake it represents, not as a code edit, because the
# point is the scientific consequence rather than the diff.

suppressWarnings(suppressMessages({
  ok <- requireNamespace("testthat", quietly = TRUE) &&
        requireNamespace("devtools", quietly = TRUE)
}))
if (!ok) { cat("::error::mutation campaign needs testthat and devtools\n"); quit(status = 1L) }

if (!file.exists("DESCRIPTION")) {
  cat("::error::run from the repository root\n"); quit(status = 1L)
}

FIXTURE <- "tests/fixtures/canonical_study.R"
if (!file.exists(FIXTURE)) {
  cat("::error::canonical fixture missing; the campaign has nothing to corrupt\n")
  quit(status = 1L)
}
# The suite exercises real package functions (the exclusion-discrepancy check
# among them), so the package must be attached before any test runs. Without
# this the baseline errors and every mutant would look killed for the wrong
# reason -- which the baseline guard below would catch, but only after wasting
# the whole campaign.
suppressMessages(devtools::load_all(".", quiet = TRUE))

source(FIXTURE)

CONTACT  <- "Able to contact"
ARM_MCD  <- "Medicaid"
ARM_BCBS <- "Blue Cross/Blue Shield"

BASE <- mc_canonical_study()$study

# ---------------------------------------------------------------------------
# The mutants. Each returns a corrupted copy of the study.
#
# `kills` names the assertion family that must notice. It is documentation for
# the reader; the campaign does not trust it, and instead requires that some
# assertion somewhere fails.
# ---------------------------------------------------------------------------
MUTANTS <- list(

  list(
    id = "unresolved_becomes_refusal",
    what = "Code every unresolved outcome as a refusal.",
    why = paste("An office that was reached but whose outcome was never",
                "determined is not an office that said no. This is the single",
                "most consequential miscoding in an access study: it converts",
                "ambiguity into evidence of denial."),
    kills = "outcome coding / acceptance denominator",
    f = function(d) { d$appointment_offered[is.na(d$appointment_offered)] <- FALSE; d }
  ),

  list(
    id = "unreached_becomes_refusal",
    what = "Fold offices that were never reached into the refusal count.",
    why = paste("Manufactures a disparity out of contact difficulty. If one arm",
                "is harder to reach, that arm acquires refusals it never made."),
    kills = "nonresponse vs refusal",
    f = function(d) {
      i <- d$reason_for_exclusions != CONTACT
      d$reason_for_exclusions[i] <- CONTACT
      d$appointment_offered[i] <- FALSE
      d
    }
  ),

  list(
    id = "missing_wait_becomes_zero",
    what = "Replace every missing wait with 0.",
    why = paste("Zero means same-day access. This assigns the fastest possible",
                "access to every office that was never reached, and does so",
                "disproportionately in whichever arm has more missingness."),
    kills = "zero vs missing",
    f = function(d) {
      d$business_days_until_appointment[is.na(d$business_days_until_appointment)] <- 0L
      d$calendar_days_until_appointment[is.na(d$calendar_days_until_appointment)] <- 0L
      d
    }
  ),

  list(
    id = "calendar_days_as_primary",
    what = "Report calendar days as the primary wait outcome.",
    why = paste("Every model still fits and every p-value stays plausible.",
                "Only the frozen denominators and the primary/sensitivity",
                "relationship reveal the substitution."),
    kills = "frozen wait statistics",
    f = function(d) {
      d$business_days_until_appointment <- d$calendar_days_until_appointment; d
    }
  ),

  list(
    id = "payer_labels_reversed",
    what = "Swap the two payer arm labels.",
    why = paste("Reverses the study's conclusion while leaving every count,",
                "every model and every table structurally identical."),
    kills = "direction guard",
    f = function(d) {
      d$insurance <- ifelse(d$insurance == ARM_MCD, ARM_BCBS, ARM_MCD); d
    }
  ),

  list(
    id = "payer_labels_reversed_one_caller",
    what = "Swap payer labels for a single caller only.",
    why = paste("The subtle version of the mutant above. A whole-study swap is",
                "obvious; a per-caller swap looks like caller heterogeneity and",
                "is the kind of error that survives review."),
    kills = "direction guard / caller balance",
    f = function(d) {
      i <- d$caller_id == "C1"
      d$insurance[i] <- ifelse(d$insurance[i] == ARM_MCD, ARM_BCBS, ARM_MCD); d
    }
  ),

  list(
    id = "drop_unreachable_from_denominator",
    what = "Delete every unreachable office from the data entirely.",
    why = paste("The acceptance rate rises because its denominator shrank, not",
                "because access improved. Nothing errors; the study simply",
                "answers a different question than the one asked."),
    kills = "exclusion reconciliation",
    f = function(d) d[d$reason_for_exclusions == CONTACT, ]
  ),

  list(
    id = "wrong_number_becomes_retired",
    what = "Reclassify wrong-number calls as retired physicians.",
    why = paste("A bad phone number is a property of the roster. A retirement",
                "is a property of the physician. Conflating them converts a",
                "data-quality problem into a workforce finding."),
    kills = "exclusion vocabulary / reconciliation",
    f = function(d) {
      d$reason_for_exclusions[d$reason_for_exclusions == "Wrong number"] <-
        "Physician retired"; d
    }
  ),

  list(
    id = "deduplication_removed",
    what = "Duplicate every Medicaid observation that has a wait.",
    why = paste("Inflates the analytic denominator with copies rather than",
                "observations, narrowing the confidence interval around an",
                "estimate that has gained no new information."),
    kills = "call identity / denominators",
    f = function(d) rbind(d, d[d$insurance == ARM_MCD &
                                 !is.na(d$business_days_until_appointment), ])
  ),

  list(
    id = "longest_waits_trimmed",
    what = "Drop the longest 5 percent of waits.",
    why = paste("Trimming the tail shortens the mean wait in whichever arm has",
                "the longer tail, which is the arm the study is about."),
    kills = "frozen denominators / wait statistics",
    f = function(d) {
      w <- d$business_days_until_appointment
      cut <- stats::quantile(w, 0.95, na.rm = TRUE)
      d[is.na(w) | w <= cut, ]
    }
  ),

  list(
    id = "ambiguous_becomes_offered",
    what = "Treat every uncertain outcome as an appointment offer.",
    why = "The mirror of the first mutant, biasing access upward instead of down.",
    kills = "outcome coding",
    f = function(d) { d$appointment_offered[is.na(d$appointment_offered)] <- TRUE; d }
  ),

  list(
    id = "wait_carried_forward_onto_excluded",
    what = "Carry each wait down onto the excluded rows that follow it.",
    why = paste("The defect that actually happened. A spreadsheet sorted so",
                "that each answered call is followed by the calls that were",
                "not, then filled down, gives every unreachable office the",
                "wait of the last office that answered. Nothing errors, every",
                "value is a plausible number of days, and the mean barely",
                "moves -- 23.8 against an honest 23.0. It is only visible if",
                "you ask which rows the numbers are attached to."),
    kills = "zero vs missing / exclusion reconciliation",
    f = function(d) {
      w <- d$business_days_until_appointment
      keep <- d$reason_for_exclusions == CONTACT
      last <- NA_real_
      for (i in seq_along(w)) {
        if (keep[i] && !is.na(w[i])) last <- w[i] else w[i] <- last
      }
      d$business_days_until_appointment <- w
      d
    }
  ),

  list(
    id = "banded_wait_substituted_for_numeric",
    what = "Replace the numeric wait with its categorical band.",
    why = paste("The same 2020 file carries both a numeric wait and a banded",
                "one ('1 to 10 business days'). Swapping them silently turns",
                "every arithmetic comparison into a string comparison, which",
                "does not error -- it just stops meaning what it used to."),
    kills = "schema contract / wait statistics",
    f = function(d) {
      w <- d$business_days_until_appointment
      d$business_days_until_appointment <- cut(
        w, breaks = c(-Inf, 10, 20, 30, Inf),
        labels = c("1 to 10 business days", "11 to 20 business days",
                   "21 to 30 business days", "over 30 business days"))
      d
    }
  ),

  list(
    id = "exclusion_applied_per_arm",
    what = "Exclude a provider on one arm only.",
    why = paste("Breaks the matched comparison silently: the provider",
                "contributes to one arm's denominator and not the other's,",
                "which is indistinguishable from a real access difference."),
    kills = "exclusion decided per provider",
    f = function(d) {
      i <- which(d$id_number == "P08" & d$insurance == ARM_MCD)
      if (length(i)) d$reason_for_exclusions[i[1]] <- CONTACT
      d
    }
  )
)

# ---------------------------------------------------------------------------
# Harness. A mutant is killed if, with the corrupted study in place, at least
# one study-integrity assertion fails.
#
# The fixture is swapped by writing a shim that returns the mutated frame, so
# the real test files run unmodified against corrupted data. Nothing edits the
# tests themselves, because a campaign that rewrote the assertions would be
# grading its own homework.
# ---------------------------------------------------------------------------
TEST_FILES <- c(
  "tests/testthat/test-canonical-study-denominators.R",
  "tests/testthat/test-study-schema.R",
  "tests/testthat/test-study-roster-identity.R",
  "tests/testthat/test-study-joins-and-arms.R",
  "tests/testthat/test-study-callers-exclusions.R",
  "tests/testthat/test-study-outcome-and-wait.R"
)
TEST_FILES <- TEST_FILES[file.exists(TEST_FILES)]

run_against <- function(mutated) {
  tmp <- tempfile(fileext = ".rds"); saveRDS(mutated, tmp)
  shim <- tempfile(fileext = ".R")
  writeLines(c(
    sprintf('.MC_MUTANT <- readRDS(%s)', shQuote(tmp)),
    sprintf('source(%s)', shQuote(normalizePath(FIXTURE))),
    'mc_canonical_study <- function() {',
    '  base <- list(providers = mc_canonical_providers(), calls = mc_canonical_calls())',
    '  list(providers = base$providers, calls = base$calls, study = .MC_MUTANT)',
    '}'
  ), shim)

  failures <- 0L; assertions <- 0L
  for (tf in TEST_FILES) {
    env <- new.env(parent = globalenv())
    sys.source(shim, envir = env)
    res <- try(suppressWarnings(suppressMessages(
      testthat::test_file(tf, reporter = "silent", env = env)
    )), silent = TRUE)
    if (inherits(res, "try-error")) { failures <- failures + 1L; next }
    df <- as.data.frame(res)
    failures   <- failures + sum(df$failed) + sum(df$error)
    assertions <- assertions + sum(df$passed)
  }
  list(failures = failures, assertions = assertions)
}

cat("Scientific mutation campaign\n")
cat("  fixture:    ", FIXTURE, "\n", sep = "")
cat("  test files: ", length(TEST_FILES), "\n", sep = "")
cat("  mutants:    ", length(MUTANTS), "\n\n", sep = "")

# Baseline: the uncorrupted study must pass, or "the tests failed" proves
# nothing about the mutant.
base_run <- run_against(BASE)
cat(sprintf("baseline (uncorrupted): %d assertions, %d failures\n\n",
            base_run$assertions, base_run$failures))
if (base_run$failures > 0L) {
  cat("::error::the uncorrupted fixture already fails; every mutant would look ",
      "killed for the wrong reason. Fix the suite before trusting this campaign.\n", sep = "")
  quit(status = 1L)
}

survivors <- character(0)
for (m in MUTANTS) {
  r <- try(run_against(m$f(BASE)), silent = TRUE)
  if (inherits(r, "try-error")) {
    # An error is a kill: the corrupted data could not even be processed.
    cat(sprintf("  KILLED   %-34s (errored)\n", m$id)); next
  }
  if (r$failures > 0L) {
    cat(sprintf("  KILLED   %-34s (%d failing assertion(s))\n", m$id, r$failures))
  } else {
    cat(sprintf("  SURVIVED %-34s\n", m$id))
    survivors <- c(survivors, m$id)
  }
}

score <- (length(MUTANTS) - length(survivors)) / length(MUTANTS) * 100
cat(sprintf("\nscientific-core mutation score: %.1f%% (%d of %d killed)\n",
            score, length(MUTANTS) - length(survivors), length(MUTANTS)))

if (length(survivors)) {
  cat("\n::error::", length(survivors), " scientific mutant(s) SURVIVED.\n", sep = "")
  for (id in survivors) {
    m <- Filter(function(x) identical(x$id, id), MUTANTS)[[1]]
    cat("\n  ", m$id, "\n", sep = "")
    cat("    mutation:    ", m$what, "\n", sep = "")
    cat("    consequence: ", gsub("\\s+", " ", m$why), "\n", sep = "")
    cat("    expected to be caught by: ", m$kills, "\n", sep = "")
  }
  cat("\n  A surviving mutant means this scientific error could be introduced\n")
  cat("  into the pipeline with every test still green. Section 104: no known\n")
  cat("  high-consequence mutant may survive, whatever the aggregate score.\n")
  quit(status = 1L)
}

cat("\nAll scientific mutants killed.\n")
