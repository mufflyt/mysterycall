#!/usr/bin/env Rscript
#
# Provenance manifest and scientific headline numbers. Spec sections 81 and 83.
#
# Run from the repository root:
#     Rscript .github/scripts/emit-provenance.R [outfile]
#
# Section 83: no manuscript-ready table should exist without provenance. This
# emits the record that makes a result attributable -- what code, what
# contract, what fixture, what environment produced it -- alongside the
# headline numbers themselves, so section 81's diff has something to compare.
#
# The headline numbers are recomputed here from the fixture in plain base R
# rather than read back from any reporting function. A provenance manifest that
# recorded whatever the pipeline said would document the pipeline's opinion of
# itself.

args <- commandArgs(trailingOnly = TRUE)
OUT  <- if (length(args)) args[[1]] else "provenance.json"

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  cat("::error::provenance needs the 'jsonlite' package\n"); quit(status = 1L)
}
if (!file.exists("DESCRIPTION")) {
  cat("::error::run from the repository root\n"); quit(status = 1L)
}

sh <- function(...) {
  out <- suppressWarnings(system2(..., stdout = TRUE, stderr = FALSE))
  if (!length(out)) NA_character_ else trimws(out[[1]])
}
file_sha <- function(p) if (file.exists(p)) digest_or_na(p) else NA_character_
digest_or_na <- function(p) {
  if (requireNamespace("digest", quietly = TRUE))
    digest::digest(file = p, algo = "sha256") else NA_character_
}

# ---- environment ------------------------------------------------------------
dcf <- read.dcf("DESCRIPTION")
pkg_version <- trimws(unname(dcf[1, "Version"]))

deps <- c("bizdays", "lme4", "MASS", "geepack", "dplyr", "ggplot2", "httr",
          "jsonlite", "digest", "yaml", "testthat", "covr", "roxygen2")
dep_versions <- setNames(
  vapply(deps, function(p) {
    v <- tryCatch(as.character(utils::packageVersion(p)), error = function(e) NA_character_)
    if (is.na(v)) "not installed" else v
  }, character(1)),
  deps
)

# ---- inputs that determine the result ---------------------------------------
inputs <- c(
  scientific_contract = "inst/contract/scientific_contract.yml",
  canonical_fixture   = "tests/fixtures/canonical_study.R",
  frozen_expectations = "tests/fixtures/canonical_study_expected.json"
)
input_hashes <- lapply(inputs, file_sha)

# ---- headline numbers, recomputed ------------------------------------------
headline <- NULL
if (file.exists(inputs[["canonical_fixture"]])) {
  source(inputs[["canonical_fixture"]])
  s <- mc_canonical_study()
  d <- s$study
  CONTACT <- "Able to contact"

  acc  <- d[d$reason_for_exclusions == CONTACT & !is.na(d$appointment_offered), ]
  wait <- d[d$reason_for_exclusions == CONTACT &
              !is.na(d$business_days_until_appointment), ]
  arm  <- function(x, a) x[x$insurance == a, ]

  m_w <- arm(wait, "Medicaid")$business_days_until_appointment
  b_w <- arm(wait, "Blue Cross/Blue Shield")$business_days_until_appointment
  m_a <- arm(acc,  "Medicaid")$appointment_offered
  b_a <- arm(acc,  "Blue Cross/Blue Shield")$appointment_offered

  headline <- list(
    providers                 = nrow(s$providers),
    calls                     = nrow(d),
    contactable               = sum(d$reason_for_exclusions == CONTACT),
    excluded                  = sum(d$reason_for_exclusions != CONTACT),
    acceptance_denominator    = nrow(acc),
    wait_denominator          = nrow(wait),
    acceptance_medicaid       = round(mean(m_a), 6),
    acceptance_commercial     = round(mean(b_a), 6),
    wait_mean_medicaid        = round(mean(m_w), 6),
    wait_mean_commercial      = round(mean(b_w), 6),
    wait_median_medicaid      = round(stats::median(m_w), 6),
    wait_median_commercial    = round(stats::median(b_w), 6),
    irr_business_days         = round(mean(m_w) / mean(b_w), 6),
    direction_medicaid_longer = mean(m_w) > mean(b_w),
    direction_medicaid_lower_acceptance = mean(m_a) < mean(b_a)
  )
}

manifest <- list(
  generated_at     = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  git = list(
    sha    = sh("git", c("rev-parse", "HEAD")),
    branch = sh("git", c("rev-parse", "--abbrev-ref", "HEAD")),
    dirty  = length(suppressWarnings(system2("git", c("status", "--porcelain"),
                                             stdout = TRUE))) > 0L
  ),
  package = list(name = "mysterycall", version = pkg_version),
  r = list(
    version  = paste(R.version$major, R.version$minor, sep = "."),
    platform = R.version$platform
  ),
  dependencies = as.list(dep_versions),
  input_hashes = input_hashes,
  # Section 83 lists the random seed. The canonical fixture uses none by
  # construction, which is itself the fact worth recording.
  rng = list(fixture_uses_rng = FALSE,
             note = "canonical fixture is written out explicitly; no RNG"),
  headline = headline
)

jsonlite::write_json(manifest, OUT, auto_unbox = TRUE, pretty = TRUE, null = "null")

cat("provenance -> ", OUT, "\n", sep = "")
cat("  git       ", manifest$git$sha, if (isTRUE(manifest$git$dirty)) " (DIRTY)" else "", "\n", sep = "")
cat("  package   ", pkg_version, "\n", sep = "")
cat("  R         ", manifest$r$version, " ", manifest$r$platform, "\n", sep = "")
cat("  contract  ", substr(input_hashes[["scientific_contract"]], 1, 16), "...\n", sep = "")
if (!is.null(headline)) {
  cat("  headline  calls=", headline$calls,
      " acc_n=", headline$acceptance_denominator,
      " wait_n=", headline$wait_denominator,
      " IRR=", format(headline$irr_business_days, nsmall = 3), "\n", sep = "")
}

if (isTRUE(manifest$git$dirty))
  cat("::warning::working tree is dirty; this manifest does not describe a ",
      "reproducible commit\n", sep = "")
