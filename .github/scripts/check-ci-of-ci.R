#!/usr/bin/env Rscript
#
# CI of CI. Spec section 100.
#
# Run from the repository root:
#     Rscript .github/scripts/check-ci-of-ci.R
#
# A green GitHub job is not evidence that anything was checked. A job whose
# script is missing, whose fixture was deleted, or whose test files were never
# discovered can exit 0 and render a green tick. This script asserts the
# machinery exists and is wired, so "the suite passed" cannot mean "the suite
# did not run".
#
# The failure this exists to prevent happened twice in this repository's own
# history, which is why it is not hypothetical:
#
#   url-check reported green having checked ZERO URLs, because a missing pandoc
#   was swallowed by continue-on-error.
#
#   check_scientific_contract.R was merged with no job invoking it, so the
#   contract hash gate existed and validated nothing.

fails <- character(0)
warns <- character(0)
bad  <- function(...) fails <<- c(fails, paste0(...))
warn <- function(...) warns <<- c(warns, paste0(...))
ok   <- function(...) cat("  ok   ", paste0(...), "\n")

if (!file.exists("DESCRIPTION")) {
  cat("::error::run from the repository root\n"); quit(status = 1L)
}

section <- function(x) cat("\n== ", x, "\n", sep = "")

# ---------------------------------------------------------------------------
section("every gate script exists")
SCRIPTS <- c(
  ".github/scripts/check-repo-hygiene.R",
  ".github/scripts/check-doc-drift.R",
  ".github/scripts/check-data-integrity.R",
  ".github/scripts/check-portability.R",
  ".github/scripts/check-dependencies.R",
  ".github/scripts/check-scientific-mutations.R",
  ".github/scripts/verify-mutation-receipt.R",
  ".github/scripts/check-scientific-semantics.R",
  ".github/scripts/check-coverage-regression.R",
  ".github/scripts/emit-provenance.R",
  ".github/scripts/check-scientific-diff.R",
  ".github/scripts/check-cohort-freeze.R",
  "tools/ci/check_scientific_contract.R"
)
for (s in SCRIPTS) {
  if (!file.exists(s)) bad("gate script missing: ", s)
  else if (file.size(s) < 200) bad("gate script suspiciously small: ", s)
  else ok(s)
}

# ---------------------------------------------------------------------------
section("every gate script is actually invoked by a workflow")
wf <- list.files(".github/workflows", pattern = "[.]ya?ml$", full.names = TRUE)
wf_text <- paste(unlist(lapply(wf, readLines, warn = FALSE)), collapse = "\n")
for (s in SCRIPTS) {
  base <- basename(s)
  if (!grepl(base, wf_text, fixed = TRUE))
    bad("gate script is never invoked by any workflow: ", s,
        " -- a gate nothing runs is decorative")
  else ok("invoked: ", base)
}

# ---------------------------------------------------------------------------
section("scientific fixtures exist and are non-trivial")
FIX <- c("tests/fixtures/canonical_study.R",
         "tests/fixtures/canonical_study_expected.json",
         "inst/contract/scientific_contract.yml",
         "inst/contract/scientific_contract.sha256")
for (f in FIX) {
  if (!file.exists(f)) { bad("scientific fixture missing: ", f); next }
  if (grepl("[.]sha256$", f)) {
    # A hash file is legitimately 65 bytes. Judging it by a stub-size threshold
    # would fail it for being exactly what it should be; check the shape instead.
    h <- trimws(readLines(f, warn = FALSE))[1]
    if (is.na(h) || !grepl("^[0-9a-f]{64}$", h))
      bad("hash file does not contain a SHA-256: ", f)
    else ok(f, " (sha256)")
    next
  }
  if (file.size(f) < 100) bad("scientific fixture is a stub: ", f)
  else ok(f, " (", file.size(f), " bytes)")
}

# ---------------------------------------------------------------------------
section("the study-integrity suite is discoverable and non-empty")
STUDY_TESTS <- list.files("tests/testthat",
                          pattern = "^test-(study|canonical|phase|scientific)-.*[.]R$",
                          full.names = TRUE)
# Pinned to the actual count, not a loose floor. A threshold set below the
# real number tolerates exactly the loss it exists to catch: with ten files and
# a floor of eight, two could vanish and this would still report ok.
EXPECTED_STUDY_TESTS <- 11L
if (length(STUDY_TESTS) < EXPECTED_STUDY_TESTS) {
  bad("only ", length(STUDY_TESTS), " study-integrity test file(s) found; ",
      "expected ", EXPECTED_STUDY_TESTS, ". A renamed or deleted file would ",
      "otherwise reduce coverage silently while every remaining test passed. ",
      "If a file was added or removed on purpose, update EXPECTED_STUDY_TESTS ",
      "in the same commit.")
} else {
  ok(length(STUDY_TESTS), " study-integrity test files")
}

empty <- STUDY_TESTS[vapply(STUDY_TESTS, function(f) {
  length(grep("test_that\\(", readLines(f, warn = FALSE))) == 0L
}, logical(1))]
if (length(empty)) {
  bad("test file(s) containing no test_that() block: ", paste(empty, collapse = ", "))
} else {
  ok("every study-integrity file contains assertions")
}

# ---------------------------------------------------------------------------
section("no scientific job uses continue-on-error")
# A scientific gate that cannot fail is worse than no gate: it reports
# confidence it has not earned.
for (f in wf) {
  txt <- readLines(f, warn = FALSE)
  hits <- grep("continue-on-error:\\s*true", txt)
  if (length(hits))
    bad(basename(f), ": continue-on-error at line(s) ",
        paste(hits, collapse = ", "), " -- this makes a gate unable to fail")
}
if (!length(fails) || !any(grepl("continue-on-error", fails)))
  ok("no workflow swallows a failure")

# ---------------------------------------------------------------------------
section("the nightly suite wires every scientific job into its summary")
nf <- ".github/workflows/nightly.yaml"
if (!file.exists(nf)) {
  bad("nightly workflow missing")
} else {
  ntxt <- paste(readLines(nf, warn = FALSE), collapse = "\n")
  REQUIRED_JOBS <- c("scientific-contract", "scientific-mutations",
                     "scientific-semantics",
                     "study-integrity", "doc-drift", "data-integrity",
                     "cohort-freeze")
  for (j in REQUIRED_JOBS) {
    declared <- grepl(paste0("\n  ", j, ":"), ntxt, fixed = TRUE)
    summarised <- grepl(paste0("needs['", j, "']"), ntxt, fixed = TRUE)
    if (!declared) bad("nightly does not declare job: ", j)
    else if (!summarised)
      bad("nightly declares '", j, "' but never reports it in the summary, ",
          "so its failure would not reach the issue")
    else ok("wired: ", j)
  }
  # A job with no timeout can hang and burn the window while the summary says
  # nothing. This is not hypothetical: url-check and R-CMD-check each sat on
  # r-lib/actions/setup-r for 77 minutes on a pull request, blocking the merge,
  # and would have kept sitting there until GitHub's 6-hour default. Every
  # workflow is checked, not just the nightly, because the ones that hung were
  # the ones nothing was checking.
  wf_files <- list.files(".github/workflows", pattern = "[.]ya?ml$", full.names = TRUE)
  untimed <- character(0)
  for (wf in wf_files) {
    nl      <- readLines(wf, warn = FALSE)
    jobs_at <- which(grepl("^jobs:\\s*$", nl))[1]
    if (is.na(jobs_at)) next
    keys    <- which(grepl("^  [a-z][a-z0-9_-]*:\\s*$", nl))
    n_jobs  <- sum(keys > jobs_at)
    n_tmo   <- sum(grepl("^\\s*timeout-minutes:", nl))
    if (n_tmo < n_jobs)
      untimed <- c(untimed, sprintf("%s (%d job(s), %d timeout(s))",
                                    basename(wf), n_jobs, n_tmo))
  }
  if (length(untimed))
    bad("workflow(s) with untimed jobs: ", paste(untimed, collapse = "; "),
        ". A job with no timeout-minutes hangs for six hours by default.")
  else ok("every job in every workflow declares a timeout (",
          length(wf_files), " workflow file(s))")
}

# ---------------------------------------------------------------------------
cat("\n")
for (w in warns) cat("::warning::", w, "\n", sep = "")

if (length(fails)) {
  cat("::error::CI-of-CI FAILED -- the scientific suite cannot be trusted to have run\n")
  for (f in fails) cat("  - ", f, "\n", sep = "")
  quit(status = 1L)
}
cat("CI-of-CI passed: the scientific machinery exists, is wired, and can fail.\n")
