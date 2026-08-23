#!/usr/bin/env Rscript
# =============================================================================
# Fast scientific semantics gate.
# =============================================================================
# This is a source-level guard for high-consequence statistical/reporting
# regressions that are easy to reintroduce and hard to notice in an ordinary
# green test suite. It deliberately has no package dependencies: it runs before
# the full package install, scans only the files that encode manuscript-facing
# scientific semantics, and fails on known-bad idioms.
#
# Usage:
#   Rscript .github/scripts/check-scientific-semantics.R
#   Rscript .github/scripts/check-scientific-semantics.R --root /path/to/repo
# =============================================================================

args <- commandArgs(trailingOnly = TRUE)
root <- if ("--root" %in% args) {
  i <- which(args == "--root")
  if (i == length(args)) stop("--root requires a path", call. = FALSE)
  args[[i + 1L]]
} else {
  "."
}

path <- function(...) file.path(root, ...)
read_text <- function(...) {
  f <- path(...)
  if (!file.exists(f)) {
    fail("missing required source file: ", f)
    return("")
  }
  paste(readLines(f, warn = FALSE), collapse = "\n")
}

fails <- character(0)
pass  <- character(0)
fail <- function(...) fails <<- c(fails, paste0(...))
ok   <- function(...) pass  <<- c(pass,  paste0(...))

must_contain <- function(label, txt, pattern, explain) {
  if (grepl(pattern, txt, perl = TRUE)) ok(label) else fail(label, ": ", explain)
}

must_not_contain <- function(label, txt, pattern, explain) {
  if (grepl(pattern, txt, perl = TRUE)) fail(label, ": ", explain) else ok(label)
}

if (!file.exists(path("DESCRIPTION"))) {
  stop("run from the repository root, or pass --root", call. = FALSE)
}

irr_days <- read_text("R", "irr_to_days.R")
wait_sentence <- read_text("R", "wait_time_sentence.R")
paired_sens <- read_text("R", "sensitivity_both_insurance.R")
density <- read_text("R", "create_density_plot.R")
scatter <- read_text("R", "create_scatter_plot.R")
pr_gate <- read_text(".github", "workflows", "scientific-pr-gate.yaml")
nightly <- read_text(".github", "workflows", "nightly.yaml")

# 1. Signed day CIs must stay signed. The historical bug applied abs() to day
# CI bounds and converted a zero-crossing/null effect into a positive bounded
# effect in manuscript prose.
must_not_contain(
  "IRR-to-days prose keeps signed CI bounds",
  irr_days,
  "abs\\s*\\(\\s*(r\\$)?days_ci_(lower|upper)|abs_lo|abs_hi",
  "do not take abs() of day-CI bounds; signed CIs preserve protective and null effects"
)
must_contain(
  "IRR-to-days prose marks zero-crossing CIs as not significant",
  irr_days,
  "days_ci_lower\\s*<\\s*0\\s*&&\\s*r\\$days_ci_upper\\s*>\\s*0",
  "expected an explicit zero-crossing check for day-difference CIs"
)

# 2. P-values must be stored raw and formatted late, with a <0.001 guard. The
# historical bug rounded p-values early and printed literal p = 0.
must_not_contain(
  "wait-time sentence never rounds raw p-values before storage",
  wait_sentence,
  "round\\s*\\(\\s*p_raw",
  "store raw p-values; early rounding can render p = 0"
)
must_contain(
  "wait-time sentence stores raw p-values",
  wait_sentence,
  "p_values\\s*\\[\\s*lvl\\s*\\]\\s*<-\\s*p_raw",
  "expected p_values[lvl] <- p_raw before display formatting"
)
must_contain(
  "wait-time sentence formats tiny p-values as less-than threshold",
  wait_sentence,
  "p_values\\s*\\[\\s*j\\s*\\]\\s*<\\s*0\\.001[\\s\\S]{0,120}\"< 0\\.001\"",
  "expected p < 0.001 guard in manuscript-facing p-value prose"
)

# 3. The both-insurance sensitivity analysis is a paired design. A formula
# t-test ignores within-physician pairing and understates precision.
must_not_contain(
  "both-insurance sensitivity does not use an unpaired formula t-test",
  paired_sens,
  "t\\.test\\s*\\([^\\n)]*~",
  "use paired per-physician differences, not t.test(outcome ~ insurance)"
)
must_contain(
  "both-insurance sensitivity uses paired t-test",
  paired_sens,
  "t\\.test\\s*\\(\\s*per_phys\\s*\\[\\s*,\\s*\"medicaid\"\\s*\\]\\s*,\\s*per_phys\\s*\\[\\s*,\\s*\"bcbs\"\\s*\\]\\s*,\\s*paired\\s*=\\s*TRUE",
  "expected a paired t-test on one Medicaid and one BCBS mean per physician"
)

# 4. Same-day appointments are real zero-day waits. Visualization helpers may
# filter >0 only for log/sqrt transforms, never for the untransformed display.
must_contain(
  "density plot keeps zero-day waits when untransformed",
  density,
  "x_transform\\s*==\\s*\"none\"[\\s\\S]{0,180}filter\\s*\\(\\s*data\\s*,\\s*!is\\.na\\s*\\(\\.data\\[\\[x_var\\]\\]\\)",
  "expected x_transform == 'none' branch to drop only NA values"
)
must_contain(
  "density plot restricts positive values only for transformed scales",
  density,
  "else\\s*\\{[\\s\\S]{0,180}filter\\s*\\(\\s*data\\s*,\\s*\\.data\\[\\[x_var\\]\\]\\s*>\\s*0",
  "expected >0 filtering to be confined to transformed scales"
)
must_contain(
  "scatter plot keeps zero-day waits when untransformed",
  scatter,
  "y_transform\\s*==\\s*\"none\"[\\s\\S]{0,200}filter\\s*\\(\\s*plot_data\\s*,\\s*!is\\.na\\s*\\(\\.data\\[\\[y_var\\]\\]\\)",
  "expected y_transform == 'none' branch to drop only NA values"
)
must_contain(
  "scatter plot restricts positive values only for transformed scales",
  scatter,
  "else\\s*\\{[\\s\\S]{0,200}filter\\s*\\(\\s*plot_data\\s*,\\s*\\.data\\[\\[y_var\\]\\]\\s*>\\s*0",
  "expected >0 filtering to be confined to transformed scales"
)

# 5. The gate must itself be wired in both the PR scientific gate and nightly.
# Otherwise it is documentation, not CI.
must_contain(
  "scientific PR gate invokes scientific semantics checker",
  pr_gate,
  "check-scientific-semantics\\.R",
  "wire this checker into .github/workflows/scientific-pr-gate.yaml"
)
must_contain(
  "nightly invokes scientific semantics checker",
  nightly,
  "check-scientific-semantics\\.R",
  "wire this checker into .github/workflows/nightly.yaml"
)

cat("scientific semantics checks:\n")
for (x in pass) cat("  OK  ", x, "\n", sep = "")

if (length(fails)) {
  cat("\n::error::scientific semantics gate found ", length(fails),
      " problem(s)\n", sep = "")
  for (x in fails) cat("  - ", x, "\n", sep = "")
  quit(status = 1L, save = "no")
}

cat("\nscientific semantics OK\n")
