#!/usr/bin/env Rscript
# =============================================================================
# Scientific contract gate. Spec sections 3, 83, 84, 103.
# =============================================================================
# Three separate jobs, deliberately not collapsed:
#
#   1. STRUCTURE  Every section-3 field is present and well formed, and every
#                 DERIVED field cites the evidence that pins it. A DERIVED claim
#                 without evidence is an assertion, not a derivation.
#
#   2. HASH       The contract's SHA-256 matches the recorded one. This is what
#                 forces a contract change to be a reviewed scientific event
#                 rather than an incidental diff. Updating the contract without
#                 updating the hash file in the same commit fails here.
#
#   3. READINESS  No release-blocking field is UNRESOLVED. This is the gate that
#                 says the study is ready to produce a scientific claim at all.
#
# Usage:
#   Rscript tools/ci/check_scientific_contract.R            structure + hash
#   Rscript tools/ci/check_scientific_contract.R --release  also require readiness
#   Rscript tools/ci/check_scientific_contract.R --update-hash   re-record the hash
# =============================================================================
args        <- commandArgs(trailingOnly = TRUE)
release     <- "--release" %in% args
update_hash <- "--update-hash" %in% args

for (p in c("yaml", "digest")) if (!requireNamespace(p, quietly = TRUE))
  stop("check_scientific_contract.R needs the '", p, "' package", call. = FALSE)

CONTRACT <- "inst/contract/scientific_contract.yml"
HASHFILE <- "inst/contract/scientific_contract.sha256"

if (!file.exists(CONTRACT)) {
  message("FAIL: no scientific contract at ", CONTRACT,
          "\n  Section 3: the CI cannot validate a study whose outcome definition can change silently.")
  quit(status = 1L, save = "no")
}

# Section 3 field list. Absence of a field is itself a failure -- a contract that
# simply omits "callback_policy" is not a contract that permits any callback rule.
REQUIRED <- c(
  "target_provider_population", "target_practice_population", "sampling_frame",
  "sampling_date", "inclusion_criteria", "exclusion_criteria_prespecified",
  "unit_of_sampling", "unit_of_calling", "unit_of_analysis",
  "experimental_arms", "randomization_unit", "primary_outcome",
  "secondary_outcomes", "call_attempt_policy", "callback_policy",
  "voicemail_policy", "appointment_definition", "payer_acceptance_definition",
  "provider_active_definition", "listed_location_definition",
  "wait_time_definition", "business_or_calendar_day_convention",
  "denominator_rules", "missingness_states", "clustering_unit",
  "analysis_population", "confidence_interval_method", "weighting_rules",
  "sensitivity_analyses"
)

contract <- tryCatch(yaml::read_yaml(CONTRACT), error = function(e) {
  message("FAIL: contract is not parseable YAML: ", conditionMessage(e)); quit(status = 1L, save = "no")
})

fails <- character(0)
bad   <- function(...) fails <<- c(fails, paste0(...))

# ---- 1. structure -----------------------------------------------------------
missing <- setdiff(REQUIRED, names(contract))
if (length(missing))
  bad("contract omits required section-3 field(s): ", paste(missing, collapse = ", "))

fields  <- intersect(REQUIRED, names(contract))
derived <- unresolved <- character(0)
for (f in fields) {
  spec <- contract[[f]]
  if (!is.list(spec) || is.null(spec$status)) {
    bad(f, ": no status (must be DERIVED or UNRESOLVED)"); next
  }
  st <- spec$status
  if (!st %in% c("DERIVED", "UNRESOLVED")) {
    bad(f, ": status '", st, "' is not DERIVED or UNRESOLVED"); next
  }
  if (identical(st, "DERIVED")) {
    derived <- c(derived, f)
    if (is.null(spec$evidence) || !nzchar(as.character(spec$evidence)[1]))
      bad(f, ": DERIVED but cites no evidence -- that is an assertion, not a derivation")
    if (is.null(spec$value))
      bad(f, ": DERIVED but carries no value")
  } else {
    unresolved <- c(unresolved, f)
    if (is.null(spec$question) || !nzchar(as.character(spec$question)[1]))
      bad(f, ": UNRESOLVED but states no question, so nobody can resolve it")
  }
}

cat(sprintf("contract fields: %d required, %d DERIVED, %d UNRESOLVED\n",
            length(REQUIRED), length(derived), length(unresolved)))

# ---- 2. hash ----------------------------------------------------------------
sha <- digest::digest(file = CONTRACT, algo = "sha256")
cat("contract SHA-256: ", sha, "\n", sep = "")

if (update_hash) {
  writeLines(sha, HASHFILE)
  cat("recorded hash -> ", HASHFILE, "\n", sep = "")
} else if (!file.exists(HASHFILE)) {
  bad("no recorded hash at ", HASHFILE,
      " -- run with --update-hash and commit it alongside the contract")
} else {
  recorded <- trimws(readLines(HASHFILE, warn = FALSE))[1]
  if (!identical(recorded, sha)) {
    bad("contract SHA-256 does not match the recorded hash.\n",
        "      recorded: ", recorded, "\n",
        "      actual:   ", sha, "\n",
        "      The contract changed. That is a SCIENTIFIC change, not a refactor:\n",
        "      review the diff, then re-record with --update-hash in the same commit.")
  } else {
    cat("hash matches the recorded contract\n")
  }
}

# ---- 3. readiness -----------------------------------------------------------
blocking_unresolved <- Filter(function(f) {
  spec <- contract[[f]]
  isTRUE(spec$release_blocking) && identical(spec$status, "UNRESOLVED")
}, fields)

if (length(blocking_unresolved)) {
  cat("\nrelease-blocking fields still UNRESOLVED (", length(blocking_unresolved), "):\n", sep = "")
  for (f in blocking_unresolved) {
    q <- contract[[f]]$question
    cat("  - ", f, "\n      ", gsub("\\s+", " ", trimws(as.character(q)[1])), "\n", sep = "")
  }
  if (release)
    bad(length(blocking_unresolved), " release-blocking field(s) UNRESOLVED; ",
        "a scientific release is prohibited until each is decided (section 103)")
}

if (length(fails)) {
  message("\nFAIL: scientific contract gate\n", paste0("  - ", fails, collapse = "\n"))
  quit(status = 1L, save = "no")
}

if (length(blocking_unresolved)) {
  cat("\nstructure and hash OK; contract is a DRAFT and not release-ready\n")
} else {
  cat("\nscientific contract OK\n")
}
