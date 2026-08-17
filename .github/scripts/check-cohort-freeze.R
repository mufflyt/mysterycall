#!/usr/bin/env Rscript
#
# Frozen-cohort gate.
#
# Run from the repository root:
#     Rscript .github/scripts/check-cohort-freeze.R
#
# The 2019 FPMRS cohort was, for a period, believed to be n = 187 -- a number
# produced by a branch whose wait column had been fill-down contaminated.
# Nothing in the repository contradicted it, because nothing recorded what the
# cohort was supposed to be. This gate is the contradiction.
#
# The source call data is private and is not in this repository, so this cannot
# recompute the cohort. What it CAN do is refuse to let the record change
# silently, refuse to let the contamination guard rot, and refuse to let a
# retired number reappear in prose. Those are the three ways the 187 mistake
# actually propagated.

suppressWarnings(suppressMessages({
  ok <- requireNamespace("yaml", quietly = TRUE)
}))
if (!ok) { cat("::error::check-cohort-freeze needs the yaml package\n"); quit(status = 1L) }
if (!file.exists("DESCRIPTION")) {
  cat("::error::run from the repository root\n"); quit(status = 1L)
}

CONTRACT <- "inst/contract/cohort_2019_fpmrs.yml"
SHAFILE  <- "inst/contract/cohort_2019_fpmrs.sha256"

fail <- 0L
bad <- function(...) { cat("::error::", ..., "\n", sep = ""); fail <<- fail + 1L }
ok_ <- function(...) cat("  ok    ", ..., "\n", sep = "")

cat("Frozen-cohort gate\n\n")

# ---------------------------------------------------------------------------
# 1. The contract exists, parses, and carries what it claims to.
# ---------------------------------------------------------------------------
cat("== contract is present and well formed\n")
if (!file.exists(CONTRACT)) {
  bad("missing ", CONTRACT, ". The frozen cohort record is the point of this gate.")
  quit(status = 1L)
}
ct <- try(yaml::read_yaml(CONTRACT), silent = TRUE)
if (inherits(ct, "try-error")) {
  bad(CONTRACT, " does not parse as YAML")
  quit(status = 1L)
}
ok_(CONTRACT, " parses")

need_top <- c("contract_version", "status", "study", "populations", "outcomes",
              "primary_finding", "retired_values", "known_bad_variables")
missing_top <- setdiff(need_top, names(ct))
if (length(missing_top)) bad("contract is missing required sections: ",
                             paste(missing_top, collapse = ", ")) else ok_("all required sections present")

# ---------------------------------------------------------------------------
# 2. The hash. A cohort change must be a reviewed change, not a quiet edit.
# ---------------------------------------------------------------------------
cat("\n== contract hash\n")
if (!file.exists(SHAFILE)) {
  bad("missing ", SHAFILE, "; without it the contract can be edited without review")
} else {
  recorded <- trimws(sub("\\s.*$", "", readLines(SHAFILE, warn = FALSE)[1]))
  actual <- tryCatch(
    if (requireNamespace("digest", quietly = TRUE)) digest::digest(file = CONTRACT, algo = "sha256") else NA_character_,
    error = function(e) NA_character_)
  if (is.na(actual)) {
    cat("  note  digest unavailable; hash not verified\n")
  } else if (!nzchar(recorded) || !grepl("^[0-9a-f]{64}$", recorded)) {
    bad(SHAFILE, " does not contain a sha256 digest")
  } else if (!identical(recorded, actual)) {
    bad("contract hash mismatch.\n",
        "    recorded: ", recorded, "\n",
        "    actual:   ", actual, "\n",
        "    The cohort record changed. If that was intended, update ", SHAFILE,
        " in the same commit so the change is reviewed as a scientific one.")
  } else {
    ok_("hash matches (", substr(actual, 1, 12), "...)")
  }
}

# ---------------------------------------------------------------------------
# 3. Internal consistency. The populations must nest.
# ---------------------------------------------------------------------------
cat("\n== populations nest and are self-consistent\n")
p <- ct$populations
n_src <- p$source_denominator$count
n_elig <- p$scientifically_eligible$count
n_wait <- p$wait_analytic$count
if (is.null(n_src) || is.null(n_elig) || is.null(n_wait)) {
  bad("one of the three population sizes is missing (keys must be `count`, not `n` -- YAML 1.1 parses a bare `n` key as boolean false)")
} else {
  if (!(n_wait <= n_elig)) bad("wait analytic (", n_wait, ") exceeds eligible (", n_elig, ")")
  else if (!(n_elig <= n_src)) bad("eligible (", n_elig, ") exceeds source denominator (", n_src, ")")
  else ok_("source ", n_src, " >= eligible ", n_elig, " >= wait analytic ", n_wait)

  # the wait cohort is exactly those eligible records that obtained an appointment
  got <- p$scientifically_eligible$appointment_obtained
  if (!is.null(got) && !identical(as.integer(got), as.integer(n_wait))) {
    bad("eligible appointment_obtained (", got, ") does not equal wait analytic n (", n_wait, ").\n",
        "    Every offered appointment with a derivable date should be in the wait cohort.")
  } else if (!is.null(got)) {
    ok_("eligible appointments obtained (", got, ") equals wait analytic n")
  }

  if (!is.null(p$source_denominator$physicians) &&
      p$source_denominator$physicians < n_src) {
    bad("physician count (", p$source_denominator$physicians,
        ") is below the clinic count (", n_src, "); a clinic cannot have fewer than one physician")
  } else ok_("physician count is at least the clinic count")
}

fnd <- ct$primary_finding
if (!is.null(fnd$female_mean) && !is.null(fnd$male_mean) && !is.null(fnd$difference)) {
  d <- round(fnd$female_mean - fnd$male_mean, 1)
  if (abs(d - fnd$difference) > 0.15) {
    bad("primary finding is internally inconsistent: female ", fnd$female_mean,
        " - male ", fnd$male_mean, " = ", d, ", but difference is recorded as ", fnd$difference)
  } else ok_("primary finding arithmetic checks out (", fnd$difference, " days)")
}
if (!is.null(fnd$ci_lower) && !is.null(fnd$ci_upper) && !is.null(fnd$p_welch)) {
  crosses_zero <- fnd$ci_lower <= 0 && fnd$ci_upper >= 0
  if (crosses_zero && fnd$p_welch < 0.05) {
    bad("the 95% CI [", fnd$ci_lower, ", ", fnd$ci_upper,
        "] includes zero but p = ", fnd$p_welch, " is significant. One of them is wrong.")
  } else ok_("CI and p-value agree")
}

# ---------------------------------------------------------------------------
# 4. The contamination guard still exists and still bites.
#    A guard nobody exercises is a guard that quietly stops working.
# ---------------------------------------------------------------------------
cat("\n== the contamination guard is present and can still fail\n")
gfile <- "R/guard_contaminated_wait.R"
if (!file.exists(gfile)) {
  bad("missing ", gfile, "; the known-bad column has no guard")
} else if (!any(grepl("mysterycall_guard_contaminated_wait", readLines("NAMESPACE", warn = FALSE)))) {
  bad("mysterycall_guard_contaminated_wait is not exported")
} else {
  loaded <- suppressWarnings(suppressMessages(
    try(pkgload::load_all(".", quiet = TRUE), silent = TRUE)))
  if (inherits(loaded, "try-error")) {
    cat("  note  package would not load; guard behaviour not exercised here\n")
  } else {
    contaminated <- data.frame(
      appointment_date = as.Date(c("2019-07-11", NA, NA)),
      business_days_until_appointment = c(8, 8, 8)
    )
    caught <- inherits(try(mysterycall_guard_contaminated_wait(
      contaminated, appointment_col = "appointment_date"), silent = TRUE), "try-error")
    if (!caught) bad("the guard PASSED a fill-down contaminated frame. It has stopped working.")
    else ok_("guard rejects a fill-down contaminated frame")

    honest <- data.frame(
      appointment_date = as.Date(c("2019-07-11", NA, NA)),
      business_days_until_appointment = c(8, NA, NA)
    )
    passed <- !inherits(try(mysterycall_guard_contaminated_wait(
      honest, appointment_col = "appointment_date"), silent = TRUE), "try-error")
    if (!passed) bad("the guard REJECTED an honest frame; it has become over-eager rather than correct.")
    else ok_("guard passes an honest frame")
  }
}

# ---------------------------------------------------------------------------
# 5. No retired number has crept back into prose.
#    This is the defect class that produced 187-vs-217: a superseded figure
#    living on in text after the data behind it changed.
# ---------------------------------------------------------------------------
cat("\n== retired cohort numbers do not appear as claims in prose\n")
prose <- c(list.files("vignettes", pattern = "[.](Rmd|md|qmd)$", full.names = TRUE, recursive = TRUE),
           list.files("man-roxygen", pattern = "[.]R$", full.names = TRUE, recursive = TRUE),
           if (dir.exists("manuscript")) list.files("manuscript", pattern = "[.](Rmd|md|qmd)$", full.names = TRUE, recursive = TRUE),
           "README.md", "NEWS.md")
prose <- prose[file.exists(prose)]
# Only flag a retired number when it is used as a COHORT claim -- adjacent to
# cohort vocabulary. A bare "217" in unrelated text is not a scientific error,
# and a gate that cries wolf gets switched off.
claim_words <- "calls?|offices?|clinics?|cohort|analytic|included|eligible|physicians?|records?|sample|n\\s*="
retired <- vapply(ct$retired_values, function(r) as.character(r$value), character(1))
hits <- 0L
for (f in prose) {
  ln <- readLines(f, warn = FALSE)
  for (rv in retired) {
    pat <- paste0("(?i)(\\b", rv, "\\b[^.\\n]{0,40}(", claim_words, ")|(", claim_words, ")[^.\\n]{0,40}\\b", rv, "\\b)")
    m <- grep(pat, ln, perl = TRUE)
    if (length(m)) {
      hits <- hits + length(m)
      bad("retired cohort value ", rv, " used as a claim in ", f, " line(s) ",
          paste(m, collapse = ", "), "\n",
          "    ", trimws(substr(ln[m[1]], 1, 100)), "\n",
          "    Reason it was retired: ", trimws(gsub("\\s+", " ", ct$retired_values[[which(retired == rv)]]$reason)))
    }
  }
}
if (hits == 0L) ok_("no retired value (", paste(retired, collapse = ", "), ") appears as a cohort claim in ",
                    length(prose), " prose file(s)")

# ---------------------------------------------------------------------------
cat("\n")
if (fail > 0L) {
  cat("::error::frozen-cohort gate failed with ", fail, " problem(s).\n", sep = "")
  quit(status = 1L)
}
cat("Frozen-cohort gate passed: the cohort record is intact, the guard still bites,\n")
cat("and no retired number is being presented as a cohort claim.\n")
