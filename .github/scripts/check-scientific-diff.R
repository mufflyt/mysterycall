#!/usr/bin/env Rscript
#
# Scientific diff. Spec sections 81 and 82.
#
# Run from the repository root:
#     Rscript .github/scripts/check-scientific-diff.R
#     Rscript .github/scripts/check-scientific-diff.R --update-baseline
#
# Compares tonight's headline numbers against the accepted baseline and fails
# on any unexplained change. This is the gate that notices when a refactor
# quietly moved a denominator: the tests can all pass, the models can all
# converge, and the study can still be answering a different question than it
# answered yesterday.
#
# Counts must match exactly -- a denominator is not a measurement with
# tolerance. Continuous statistics get a tight tolerance because floating-point
# summation order is not guaranteed. Directions may not change at all, since a
# reversed direction is a different scientific conclusion rather than a
# different number.

args   <- commandArgs(trailingOnly = TRUE)
update <- "--update-baseline" %in% args
BASE   <- ".github/scientific-baseline.json"
CUR    <- tempfile(fileext = ".json")

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  cat("::error::scientific diff needs 'jsonlite'\n"); quit(status = 1L)
}
if (!file.exists("DESCRIPTION")) {
  cat("::error::run from the repository root\n"); quit(status = 1L)
}

emit <- ".github/scripts/emit-provenance.R"
if (!file.exists(emit)) {
  cat("::error::missing ", emit, "; the diff has nothing to compare\n", sep = "")
  quit(status = 1L)
}

st <- system2("Rscript", c(emit, CUR), stdout = TRUE, stderr = TRUE)
if (!file.exists(CUR)) {
  cat("::error::provenance emitter produced no manifest\n")
  cat(paste0("  ", st, collapse = "\n"), "\n")
  quit(status = 1L)
}

cur <- jsonlite::fromJSON(CUR, simplifyVector = TRUE)
if (is.null(cur$headline)) {
  cat("::error::manifest carries no headline numbers; the fixture is missing\n")
  quit(status = 1L)
}

if (update) {
  jsonlite::write_json(cur$headline, BASE, auto_unbox = TRUE, pretty = TRUE)
  cat("recorded scientific baseline -> ", BASE, "\n", sep = "")
  quit(status = 0L)
}

if (!file.exists(BASE)) {
  cat("::warning::no scientific baseline at ", BASE,
      "; no diff was performed. Record one with --update-baseline.\n", sep = "")
  quit(status = 0L)
}

old <- jsonlite::fromJSON(BASE, simplifyVector = TRUE)
new <- cur$headline

EXACT <- c("providers", "calls", "contactable", "excluded",
           "acceptance_denominator", "wait_denominator")
DIRECTION <- c("direction_medicaid_longer", "direction_medicaid_lower_acceptance")
TOL <- 1e-6

changes <- list()
note <- function(field, was, now, kind) {
  changes[[length(changes) + 1L]] <<- list(field = field, was = was, now = now, kind = kind)
}

for (f in union(names(old), names(new))) {
  was <- old[[f]]; now <- new[[f]]
  if (is.null(was)) { note(f, "absent", now, "new field"); next }
  if (is.null(now)) { note(f, was, "absent", "field disappeared"); next }

  if (f %in% EXACT) {
    if (!identical(as.numeric(was), as.numeric(now)))
      note(f, was, now, "COUNT")
  } else if (f %in% DIRECTION) {
    if (!identical(as.logical(was), as.logical(now)))
      note(f, was, now, "DIRECTION")
  } else {
    if (abs(as.numeric(was) - as.numeric(now)) > TOL)
      note(f, was, now, "statistic")
  }
}

cat("Scientific diff against ", BASE, "\n\n", sep = "")
w <- max(nchar(union(names(old), names(new))))
for (f in names(new)) {
  was <- old[[f]]; now <- new[[f]]
  same <- !is.null(was) && !is.null(now) &&
    isTRUE(all.equal(as.character(was), as.character(now)))
  cat(sprintf("  %-*s %s%s\n", w, f, format(now),
              if (same) "" else sprintf("   <- was %s", format(was))))
}

if (!length(changes)) {
  cat("\nno change from the accepted baseline\n")
  quit(status = 0L)
}

cat("\n::error::", length(changes), " headline value(s) changed\n", sep = "")
for (ch in changes)
  cat("  [", ch$kind, "] ", ch$field, ": ", format(ch$was), " -> ", format(ch$now), "\n", sep = "")

if (any(vapply(changes, function(c) identical(c$kind, "DIRECTION"), logical(1))))
  cat("\n  A DIRECTION change is a different scientific conclusion, not a different\n",
      "  number. Do not re-record the baseline until that is understood.\n", sep = "")
if (any(vapply(changes, function(c) identical(c$kind, "COUNT"), logical(1))))
  cat("\n  A COUNT change means the denominator moved. Every reported proportion\n",
      "  rests on it, so this is the change most worth explaining at the\n",
      "  individual-record level (section 81).\n", sep = "")

cat("\n  If the change is intended, re-record with --update-baseline in the same\n")
cat("  commit so the decision is visible in the diff.\n")
quit(status = 1L)
