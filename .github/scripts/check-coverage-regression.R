#!/usr/bin/env Rscript
#
# Coverage regression guard. Spec section 17.
#
# Run from the repository root:
#     Rscript .github/scripts/check-coverage-regression.R
#     Rscript .github/scripts/check-coverage-regression.R --update-baseline
#
# A single package-wide floor is a weak gate. It passes while a critical
# subsystem falls to zero, because the average is carried by everything else.
# Two things are checked instead:
#
#   1. an absolute floor, so coverage cannot collapse outright;
#   2. a regression guard against a committed baseline, so a slow slide is
#      caught even while the number is still above the floor.
#
# Coverage is also reported per subsystem, because "78% overall" tells you
# nothing about whether the exclusion logic or the wait-time calculation is
# tested at all -- and those are the modules where an untested change becomes a
# wrong number rather than a crash.

args     <- commandArgs(trailingOnly = TRUE)
update   <- "--update-baseline" %in% args
BASELINE <- ".github/coverage-baseline.json"

for (p in c("covr", "jsonlite")) if (!requireNamespace(p, quietly = TRUE))
  { cat("::error::coverage guard needs the '", p, "' package\n", sep = ""); quit(status = 1L) }

if (!file.exists("DESCRIPTION")) {
  cat("::error::run from the repository root\n"); quit(status = 1L)
}

FLOOR         <- 60      # absolute minimum, package-wide
MAX_DROP      <- 1.0     # percentage points the package total may fall
MODULE_DROP   <- 0.0     # critical modules may not fall at all

# Subsystems that turn an untested change into a wrong number rather than an
# error. Matched against file paths; a module with no matching file is reported
# rather than silently skipped.
CRITICAL <- list(
  exclusions      = c("reconcile_inclusion", "flag_exclusion", "flag_excluded"),
  wait_time       = c("business_days", "wait_time", "outcome_bounds", "categorize_wait"),
  acceptance      = c("acceptance_rate", "insurance_acceptance"),
  denominators    = c("run_analysis", "clean_phase"),
  join_safety     = c("join_safety"),
  identity        = c("lookup_age", "link_physicians", "flag_repeat", "check_duplicates"),
  models          = c("poisson_model", "nb_model", "logistic_model", "gee", "lmm", "icc"),
  provenance      = c("provenance", "session_snapshot")
)

cat("Measuring coverage (this is the slow part) ...\n")
cov <- covr::package_coverage(quiet = TRUE)
pct <- covr::percent_coverage(cov)
by_file <- covr::coverage_to_list(cov)$filecoverage

cat(sprintf("\npackage coverage: %.2f%%\n", pct))

module_pct <- function(pats) {
  hit <- by_file[Reduce(`|`, lapply(pats, function(p) grepl(p, names(by_file), fixed = TRUE)))]
  if (!length(hit)) return(NA_real_)
  mean(hit)
}

cat("\nby subsystem:\n")
mods <- vapply(CRITICAL, module_pct, numeric(1))
for (nm in names(mods)) {
  v <- mods[[nm]]
  cat(sprintf("  %-14s %s\n", nm,
              if (is.na(v)) "no matching file" else sprintf("%6.2f%%", v)))
}

worst <- utils::head(sort(by_file), 10)
cat("\nlowest-covered files:\n")
for (i in seq_along(worst))
  cat(sprintf("  %6.2f%%  %s\n", worst[[i]], names(worst)[i]))

current <- list(
  recorded_at    = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  package_total  = round(pct, 4),
  modules        = lapply(mods, function(v) if (is.na(v)) NULL else round(v, 4))
)

if (update) {
  dir.create(dirname(BASELINE), showWarnings = FALSE, recursive = TRUE)
  jsonlite::write_json(current, BASELINE, auto_unbox = TRUE, pretty = TRUE)
  cat("\nrecorded baseline -> ", BASELINE, "\n", sep = "")
  quit(status = 0L)
}

fails <- character(0)

# ---- absolute floor ---------------------------------------------------------
if (pct < FLOOR) {
  fails <- c(fails, sprintf("package coverage %.2f%% is below the %d%% floor", pct, FLOOR))
}

# ---- regression against the baseline ---------------------------------------
if (!file.exists(BASELINE)) {
  # Bootstrapping is a notice, not a pass-by-default: the run says plainly that
  # no regression check happened.
  cat("\n::warning::no coverage baseline at ", BASELINE,
      "; recording one requires --update-baseline. No regression check ran.\n", sep = "")
} else {
  base <- jsonlite::fromJSON(BASELINE, simplifyVector = TRUE)
  drop <- base$package_total - pct
  cat(sprintf("\nbaseline: %.2f%% (recorded %s)\n", base$package_total, base$recorded_at))
  cat(sprintf("change:   %+.2f pp\n", -drop))

  if (drop > MAX_DROP)
    fails <- c(fails, sprintf(
      "package coverage fell %.2f pp (%.2f%% -> %.2f%%), more than the %.1f pp allowance",
      drop, base$package_total, pct, MAX_DROP))

  for (nm in names(mods)) {
    now <- mods[[nm]]
    was <- base$modules[[nm]]
    if (is.na(now) || is.null(was)) next
    d <- was - now
    if (d > MODULE_DROP)
      fails <- c(fails, sprintf(
        "critical module '%s' fell %.2f pp (%.2f%% -> %.2f%%); critical modules may not regress",
        nm, d, was, now))
  }
}

if (length(fails)) {
  cat("\n::error::coverage regression\n")
  for (f in fails) cat("  - ", f, "\n", sep = "")
  cat("\n  If the drop is intentional, re-record with --update-baseline in the\n")
  cat("  same commit, so the decision is visible in the diff.\n")
  quit(status = 1L)
}

cat("\ncoverage OK\n")
