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
# Three statuses, and the distinction between the last two is the point:
#
#   DERIVED     The code determines it. Requires evidence, because a DERIVED
#               claim without evidence is an assertion.
#
#   PER_STUDY   It legitimately differs between studies. "Earliest offered
#               versus booked", "practice versus named-physician acceptance"
#               and the clustering unit are not facts about this package; they
#               are choices a protocol makes. A single global answer would be
#               wrong for every study that chose differently. Requires an
#               enumerated allowed_values, so a study picks from a closed set
#               rather than inventing a value.
#
#   UNRESOLVED  Nobody has decided, and it is not per-study. This is a gap.
#
# A study supplies its own answers in inst/contract/studies/<id>.yml, validated
# against the schema. The package contract defines what may be chosen; the study
# contract records what WAS chosen, and carries its own hash.
#
# Usage:
#   Rscript tools/ci/check_scientific_contract.R            structure + hash
#   Rscript tools/ci/check_scientific_contract.R --release  also require readiness
#   Rscript tools/ci/check_scientific_contract.R --update-hash   re-record the hash
#   Rscript tools/ci/check_scientific_contract.R --study <id>    validate a study
# =============================================================================
args        <- commandArgs(trailingOnly = TRUE)
release     <- "--release" %in% args
update_hash <- "--update-hash" %in% args
study_id    <- if ("--study" %in% args) args[[which(args == "--study") + 1L]] else NULL

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
derived <- unresolved <- per_study <- character(0)
VALID_STATUS <- c("DERIVED", "PER_STUDY", "UNRESOLVED")
for (f in fields) {
  spec <- contract[[f]]
  if (!is.list(spec) || is.null(spec$status)) {
    bad(f, ": no status (must be one of ", paste(VALID_STATUS, collapse = ", "), ")"); next
  }
  st <- spec$status
  if (!st %in% VALID_STATUS) {
    bad(f, ": status '", st, "' is not one of ", paste(VALID_STATUS, collapse = ", ")); next
  }
  if (identical(st, "PER_STUDY")) {
    per_study <- c(per_study, f)
    vt <- if (is.null(spec$value_type)) "enumerated" else as.character(spec$value_type)[1]
    if (!vt %in% c("enumerated", "free_text"))
      bad(f, ": value_type '", vt, "' must be 'enumerated' or 'free_text'")
    if (identical(vt, "enumerated")) {
      av <- spec$allowed_values
      if (is.null(av) || !length(av))
        bad(f, ": PER_STUDY enumerated but lists no allowed_values -- a study ",
            "could then invent any value, which is not a contract")
    } else {
      # Free text still has to say what a valid answer looks like, or "per
      # study" becomes a licence to write nothing.
      if (is.null(spec$format) || !nzchar(as.character(spec$format)[1]))
        bad(f, ": PER_STUDY free_text but gives no `format` describing what a ",
            "valid answer must contain")
    }
    if (is.null(spec$why_per_study) || !nzchar(as.character(spec$why_per_study)[1]))
      bad(f, ": PER_STUDY but does not say why it cannot be global")
    next
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

cat(sprintf("contract fields: %d required, %d DERIVED, %d PER_STUDY, %d UNRESOLVED\n",
            length(REQUIRED), length(derived), length(per_study), length(unresolved)))

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


# ---- 4. study instance ------------------------------------------------------
# The package contract says what MAY be chosen. A study contract records what
# WAS chosen, and must resolve every PER_STUDY field from the enumerated set.
# Without this, "per-study" would be a licence to leave the estimand undefined.
if (!is.null(study_id)) {
  SDIR  <- "inst/contract/studies"
  SFILE <- file.path(SDIR, paste0(study_id, ".yml"))
  SHASH <- file.path(SDIR, paste0(study_id, ".sha256"))

  cat("\n--- study contract: ", study_id, " ---\n", sep = "")

  if (!file.exists(SFILE)) {
    bad("no study contract at ", SFILE,
        " -- a study cannot be analysed under a contract that does not exist")
  } else {
    study <- tryCatch(yaml::read_yaml(SFILE), error = function(e) NULL)
    if (is.null(study)) {
      bad(SFILE, ": not parseable YAML")
    } else {
      if (is.null(study$study_id) || !identical(as.character(study$study_id), study_id))
        bad(SFILE, ": study_id inside the file does not match its filename")

      missing_choice <- setdiff(per_study, names(study))
      if (length(missing_choice))
        bad(SFILE, ": leaves PER_STUDY field(s) unanswered: ",
            paste(missing_choice, collapse = ", "),
            ". Every per-study field must be chosen before the study has an estimand.")

      for (f in intersect(per_study, names(study))) {
        spec <- contract[[f]]
        vt <- if (is.null(spec$value_type)) "enumerated" else as.character(spec$value_type)[1]
        chosen <- as.character(study[[f]])[1]
        if (identical(vt, "enumerated")) {
          allowed <- as.character(spec$allowed_values)
          if (!chosen %in% allowed)
            bad(SFILE, ": ", f, " = '", chosen, "' is not one of the allowed values (",
                paste(allowed, collapse = " | "), "). A study may choose, but not invent.")
        } else if (!nzchar(trimws(chosen))) {
          bad(SFILE, ": ", f, " is free text but empty. Required format: ",
              gsub("\\s+", " ", trimws(as.character(spec$format)[1])))
        }
      }

      extra <- setdiff(names(study), c(per_study, "study_id", "description", "notes"))
      if (length(extra))
        cat("  note: study declares field(s) the schema does not mark PER_STUDY: ",
            paste(extra, collapse = ", "), "\n", sep = "")

      answered <- length(intersect(per_study, names(study)))
      cat("  resolved ", answered, " of ", length(per_study), " per-study field(s)\n", sep = "")

      ssha <- digest::digest(file = SFILE, algo = "sha256")
      cat("  study SHA-256: ", ssha, "\n", sep = "")
      if (update_hash) {
        writeLines(ssha, SHASH); cat("  recorded -> ", SHASH, "\n", sep = "")
      } else if (!file.exists(SHASH)) {
        bad("no recorded hash at ", SHASH, " -- run with --update-hash")
      } else if (!identical(trimws(readLines(SHASH, warn = FALSE))[1], ssha)) {
        bad("study contract SHA-256 does not match ", SHASH,
            ". The study's estimand changed; review the diff and re-record.")
      } else {
        cat("  study hash matches\n")
      }
    }
  }
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
