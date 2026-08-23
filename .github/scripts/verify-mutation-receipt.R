#!/usr/bin/env Rscript
#
# Verify the adversarial campaign's receipt. Companion to
# check-scientific-mutations.R.
#
# Run from the repository root:
#     Rscript .github/scripts/verify-mutation-receipt.R
#
# WHY THIS EXISTS SEPARATELY FROM THE CAMPAIGN
#
# The aggregator can only see a job's result: success or failure. "Success" is
# compatible with a campaign that ran nothing. This repository has already been
# bitten twice by that exact shape -- url-check reported green having checked
# zero URLs, and check_scientific_contract.R was merged with no job invoking it.
#
# So the campaign records what it did as data, and this script asserts the three
# claims SEPARATELY. They are genuinely independent, and any one of them alone
# is worthless:
#
#   1. EXECUTED       the campaign ran a full declared suite and real assertions.
#                     Without this, 2 and 3 are claims about nothing.
#   2. CONTROL PASSED the UNPOISONED reference analysis passed. Without this,
#                     "the poisoned analysis failed" is not evidence of
#                     detection -- a suite broken enough to fail on everything
#                     would score a perfect campaign.
#   3. POISON FAILED  every poisoned analysis actually failed. A survivor means
#                     that scientific error could enter the pipeline with every
#                     test still green.
#
# The standard this serves: "how many ways can we manufacture a believable but
# scientifically false access disparity from these calls, and does mysterycall
# catch every one of them?"

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  cat("::error::receipt verification needs the 'jsonlite' package\n"); quit(status = 1L)
}
if (!file.exists("DESCRIPTION")) {
  cat("::error::run from the repository root\n"); quit(status = 1L)
}

RECEIPT <- "mutation-receipt.json"
if (!file.exists(RECEIPT)) {
  cat("::error::no ", RECEIPT, " -- the mutation campaign did not run to completion.\n", sep = "")
  cat("A missing receipt is a FAILURE, not a skip: it is indistinguishable from\n")
  cat("a campaign that never executed, which is the state this gate rules out.\n")
  quit(status = 1L)
}

r <- jsonlite::fromJSON(RECEIPT, simplifyVector = TRUE)
if (!identical(r$schema, "mysterycall/mutation-receipt/v1")) {
  cat("::error::unrecognised receipt schema: ", as.character(r$schema), "\n", sep = "")
  quit(status = 1L)
}

fails <- character(0)
bad <- function(...) fails <<- c(fails, paste0(...))
ok  <- function(...) cat("  ok    ", paste0(...), "\n")

# --- 1. EXECUTED --------------------------------------------------------------
cat("\n== 1. the adversarial test was actually executed\n")
ex <- r$executed
# A floor, not a mirror of the current numbers: this must fail when the campaign
# shrinks, without needing an edit every time a mutant is legitimately added.
MIN_TEST_FILES <- 6L
MIN_MUTANTS    <- 14L
MIN_ASSERTIONS <- 50L

if (is.null(ex$test_files_run) || ex$test_files_run < MIN_TEST_FILES) {
  bad("only ", ex$test_files_run, " test file(s) run; the campaign declares at least ",
      MIN_TEST_FILES, ". The evidence base shrank.")
} else ok("test files run: ", ex$test_files_run)

if (!identical(as.integer(ex$test_files_run), as.integer(ex$test_files_declared))) {
  bad("declared ", ex$test_files_declared, " test files but ran ", ex$test_files_run,
      " -- files went missing and were skipped rather than failing.")
} else ok("every declared test file ran")

if (is.null(ex$mutants_run) || ex$mutants_run < MIN_MUTANTS) {
  bad("only ", ex$mutants_run, " mutant(s) evaluated; expected at least ", MIN_MUTANTS, ".")
} else ok("mutants evaluated: ", ex$mutants_run)

if (!identical(as.integer(ex$mutants_run), as.integer(ex$mutants_declared))) {
  bad("declared ", ex$mutants_declared, " mutants but evaluated ", ex$mutants_run, ".")
} else ok("every declared mutant was evaluated")

if (is.null(ex$baseline_assertions) || ex$baseline_assertions < MIN_ASSERTIONS) {
  bad("baseline produced ", ex$baseline_assertions, " assertions; expected at least ",
      MIN_ASSERTIONS, ". Zero or few assertions means the suite did not really run.")
} else ok("baseline assertions: ", ex$baseline_assertions)

# --- 2. CONTROL PASSED --------------------------------------------------------
cat("\n== 2. the unpoisoned reference analysis passed\n")
cp <- r$control_passed
if (!isTRUE(cp$passed)) {
  bad("the UNPOISONED reference analysis did not pass (",
      cp$baseline_failures, " failure(s), ", cp$baseline_assertions,
      " assertion(s)). Every mutant would look killed for the wrong reason.")
} else ok("control: ", cp$baseline_assertions, " assertions, 0 failures")

if (isTRUE(cp$baseline_failures > 0))
  bad("control reported ", cp$baseline_failures, " failure(s).")

# --- 3. POISON FAILED ---------------------------------------------------------
cat("\n== 3. every poisoned analysis actually failed\n")
pf <- r$poison_failed
if (!isTRUE(pf$all_killed)) {
  bad(length(pf$survivors), " mutant(s) SURVIVED: ", paste(pf$survivors, collapse = ", "))
} else ok("all ", nrow(pf$mutants), " poisoned analyses failed as required")

# Per-mutant, not just the aggregate flag: a mutant marked killed must carry
# evidence of HOW. "killed" with no failing assertions and no error is a
# bookkeeping error, and would otherwise pass silently.
if (!is.null(pf$mutants) && nrow(pf$mutants) > 0) {
  m <- pf$mutants
  for (i in seq_len(nrow(m))) {
    if (isTRUE(m$killed[i])) {
      how <- m$how[i]
      if (!how %in% c("errored", "assertions_failed"))
        bad("mutant '", m$id[i], "' claims killed but records how='", how, "'")
      else if (identical(how, "assertions_failed") &&
               (is.na(m$failing_assertions[i]) || m$failing_assertions[i] <= 0))
        bad("mutant '", m$id[i], "' claims killed by assertions but records ",
            m$failing_assertions[i], " failing assertion(s)")
    }
  }
  ok("every kill carries evidence of how")
}

# --- verdict ------------------------------------------------------------------
cat("\n")
if (length(fails)) {
  cat("::error::the adversarial campaign is not proven.\n")
  for (f in fails) cat("  - ", f, "\n", sep = "")
  cat("\nA green mutation job is not evidence on its own. All three claims must\n")
  cat("hold independently: executed, control passed, poison failed.\n")
  quit(status = 1L)
}
cat("adversarial campaign PROVEN: executed, control passed, every poison caught.\n")
