# Canonical synthetic mystery-caller study.
#
# A frozen, fully synthetic study used as the end-to-end fixture for nightly
# verification. Every row is written out explicitly rather than simulated:
# there is no RNG, so the denominators below are stable across R versions,
# platforms, and RNG-stream changes. A fixture whose counts move when R's
# sampler changes cannot anchor a denominator invariant.
#
# No real physician, practice, NPI, or phone number appears here. NPIs are in
# the 9999xxxxx range, which is not issued, and phone numbers use the 555
# exchange reserved for fiction.
#
# Design: a matched crossover. Each provider is called once as Medicaid and
# once as Blue Cross/Blue Shield, so arm balance is checkable, with deliberate
# exceptions covering the cases that break naive analyses.
#
# Load with:
#   source(testthat::test_path("..", "fixtures", "canonical_study.R"))
#   study <- mc_canonical_study()

# --- provider roster ---------------------------------------------------------
# archetype drives which call rows are generated for the provider, and is what
# a reader should scan to see the coverage. It is carried through to the call
# frame so tests can select a scenario without hard-coding row numbers.
mc_canonical_providers <- function() {
  data.frame(
    provider_id = c(
      "P01", "P02", "P03", "P04", "P05", "P06", "P07", "P08",
      "P09", "P10", "P11", "P12", "P13", "P14", "P15", "P16"
    ),
    npi = c(
      "9999000001", "9999000002", "9999000003", "9999000004",
      "9999000005", "9999000006", "9999000007", "9999000008",
      "9999000009", "9999000010", "9999000011", "9999000012",
      # P13 deliberately repeats P01's NPI: the same physician entered twice
      # under two roster IDs, which is the duplicate the dedup step must catch.
      "9999000001",
      "9999000014", "9999000015", NA_character_
    ),
    physician_information = c(
      "Alvarez, Maria",   "Bennett, Charles", "Chen, Wei",       "Dubois, Anne",
      "Egan, Patrick",    "Ferreira, Luis",   "Gupta, Priya",    "Hansen, Erik",
      "Ibrahim, Nadia",   "Jensen, Karl",     "Kowalski, Ewa",   "Lindqvist, Sven",
      "Alvarez, Maria",   "Novak, Petr",      "Okafor, Chidi",   "Park, Jisoo"
    ),
    practice_name = c(
      "Front Range OBGYN",     "Cascade Women's Health", "Harbor Medical Group",
      "Front Range OBGYN",     "Prairie Health Partners", "Summit Women's Care",
      "University Health",     "Lakeside Clinic",         "University Health",
      "Riverbend Associates",  "Summit Women's Care",     "Coastal Care",
      "Front Range OBGYN",     "Midtown Physicians",      "University Health",
      "Northgate Clinic"
    ),
    state = c(
      "CO", "WA", "CA", "CO", "NE", "CO", "CO", "MN",
      "CO", "OR", "CO", "CA", "CO", "NY", "CO", "TX"
    ),
    academic = c(
      FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE,
      TRUE,  FALSE, FALSE, FALSE, FALSE, FALSE, TRUE,  FALSE
    ),
    archetype = c(
      "standard_accepts",      # P01 both arms, appointment offered
      "standard_accepts",      # P02 both arms, appointment offered
      "medicaid_declined",     # P03 Medicaid refused, BCBS accepted
      "two_locations",         # P04 same provider, two phone numbers
      "unreachable",           # P05 never reached
      "wrong_number",          # P06 wrong number, excluded
      "standard_accepts",      # P07 academic
      "retired",               # P08 excluded, retired
      "standard_accepts",      # P09 academic
      "moved",                 # P10 excluded, moved
      "ambiguous_outcome",     # P11 outcome uncertain
      "missing_wait",          # P12 offered but wait not recorded
      "duplicate_of_P01",      # P13 same NPI as P01
      "single_arm_only",       # P14 Medicaid arm only
      "same_day",              # P15 zero-day wait
      "no_npi"                 # P16 missing NPI
    ),
    stringsAsFactors = FALSE
  )
}

# --- call log ----------------------------------------------------------------
# One row per call. Two callers alternate so caller-effect checks have signal.
mc_canonical_calls <- function() {
  ARM_MCD  <- "Medicaid"
  ARM_BCBS <- "Blue Cross/Blue Shield"
  CONTACT  <- "Able to contact"

  # id, phone, arm, caller, offered, business_days, calendar_days,
  # exclusion reason, medicaid answer
  rows <- list(
    # -- P01 standard, both arms; Medicaid waits longer -----------------------
    list("P01", "3035550101", ARM_MCD,  "C1", TRUE,  12L, 18L, CONTACT, "Yes they accept Medicaid"),
    list("P01", "3035550101", ARM_BCBS, "C2", TRUE,   5L,  7L, CONTACT, "NA as this was a Blue Cross/Blue Shield call."),

    # -- P02 standard, both arms ---------------------------------------------
    list("P02", "2065550102", ARM_MCD,  "C2", TRUE,   9L, 13L, CONTACT, "Yes they accept Medicaid"),
    list("P02", "2065550102", ARM_BCBS, "C1", TRUE,   4L,  6L, CONTACT, "NA as this was a Blue Cross/Blue Shield call."),

    # -- P03 Medicaid declined outright, BCBS offered -------------------------
    list("P03", "4155550103", ARM_MCD,  "C1", FALSE, NA_integer_, NA_integer_, CONTACT, "No"),
    list("P03", "4155550103", ARM_BCBS, "C2", TRUE,   6L,  8L, CONTACT, "NA as this was a Blue Cross/Blue Shield call."),

    # -- P04 two office locations, both reached -------------------------------
    list("P04", "3035550104", ARM_MCD,  "C2", TRUE,  15L, 21L, CONTACT, "Yes they accept Medicaid"),
    list("P04", "3035550104", ARM_BCBS, "C1", TRUE,   7L,  9L, CONTACT, "NA as this was a Blue Cross/Blue Shield call."),
    list("P04", "3035550204", ARM_MCD,  "C1", TRUE,  14L, 20L, CONTACT, "Yes they accept Medicaid"),
    list("P04", "3035550204", ARM_BCBS, "C2", TRUE,   8L, 10L, CONTACT, "NA as this was a Blue Cross/Blue Shield call."),

    # -- P05 unreachable in both arms ----------------------------------------
    list("P05", "4025550105", ARM_MCD,  "C1", FALSE, NA_integer_, NA_integer_, "Unable to contact office", NA_character_),
    list("P05", "4025550105", ARM_BCBS, "C2", FALSE, NA_integer_, NA_integer_, "Unable to contact office", NA_character_),

    # -- P06 wrong number -----------------------------------------------------
    list("P06", "3035550106", ARM_MCD,  "C2", FALSE, NA_integer_, NA_integer_, "Wrong number", NA_character_),
    list("P06", "3035550106", ARM_BCBS, "C1", FALSE, NA_integer_, NA_integer_, "Wrong number", NA_character_),

    # -- P07 academic, both arms ---------------------------------------------
    list("P07", "3035550107", ARM_MCD,  "C1", TRUE,  20L, 28L, CONTACT, "Yes they accept Medicaid"),
    list("P07", "3035550107", ARM_BCBS, "C2", TRUE,  11L, 15L, CONTACT, "NA as this was a Blue Cross/Blue Shield call."),

    # -- P08 retired, excluded ------------------------------------------------
    list("P08", "6125550108", ARM_MCD,  "C2", FALSE, NA_integer_, NA_integer_, "Physician retired", NA_character_),
    list("P08", "6125550108", ARM_BCBS, "C1", FALSE, NA_integer_, NA_integer_, "Physician retired", NA_character_),

    # -- P09 academic, both arms ---------------------------------------------
    list("P09", "3035550109", ARM_MCD,  "C1", TRUE,  18L, 25L, CONTACT, "Yes they accept Medicaid"),
    list("P09", "3035550109", ARM_BCBS, "C2", TRUE,  10L, 14L, CONTACT, "NA as this was a Blue Cross/Blue Shield call."),

    # -- P10 moved practice, excluded ----------------------------------------
    list("P10", "5035550110", ARM_MCD,  "C2", FALSE, NA_integer_, NA_integer_, "Physician moved practices", NA_character_),
    list("P10", "5035550110", ARM_BCBS, "C1", FALSE, NA_integer_, NA_integer_, "Physician moved practices", NA_character_),

    # -- P11 ambiguous: reached, outcome not determinable ---------------------
    list("P11", "3035550111", ARM_MCD,  "C1", NA,    NA_integer_, NA_integer_, CONTACT, "Unclear"),
    list("P11", "3035550111", ARM_BCBS, "C2", NA,    NA_integer_, NA_integer_, CONTACT, "Unclear"),

    # -- P12 appointment offered but wait never recorded ----------------------
    list("P12", "4155550112", ARM_MCD,  "C2", TRUE,  NA_integer_, NA_integer_, CONTACT, "Yes they accept Medicaid"),
    list("P12", "4155550112", ARM_BCBS, "C1", TRUE,  NA_integer_, NA_integer_, CONTACT, "NA as this was a Blue Cross/Blue Shield call."),

    # -- P13 duplicate physician (same NPI as P01) ----------------------------
    list("P13", "3035550101", ARM_MCD,  "C1", TRUE,  12L, 18L, CONTACT, "Yes they accept Medicaid"),
    list("P13", "3035550101", ARM_BCBS, "C2", TRUE,   5L,  7L, CONTACT, "NA as this was a Blue Cross/Blue Shield call."),

    # -- P14 Medicaid arm only; BCBS call never made --------------------------
    list("P14", "2125550114", ARM_MCD,  "C2", TRUE,  16L, 22L, CONTACT, "Yes they accept Medicaid"),

    # -- P15 same-day appointment (zero wait, a legitimate boundary) ----------
    list("P15", "3035550115", ARM_MCD,  "C1", TRUE,   0L,  0L, CONTACT, "Yes they accept Medicaid"),
    list("P15", "3035550115", ARM_BCBS, "C2", TRUE,   0L,  0L, CONTACT, "NA as this was a Blue Cross/Blue Shield call."),

    # -- P16 no NPI on the roster --------------------------------------------
    list("P16", "2145550116", ARM_MCD,  "C2", TRUE,  13L, 19L, CONTACT, "Yes they accept Medicaid"),
    list("P16", "2145550116", ARM_BCBS, "C1", TRUE,   6L,  8L, CONTACT, "NA as this was a Blue Cross/Blue Shield call.")
  )

  out <- data.frame(
    id_number  = vapply(rows, `[[`, character(1), 1L),
    phone      = vapply(rows, `[[`, character(1), 2L),
    insurance  = vapply(rows, `[[`, character(1), 3L),
    caller_id  = vapply(rows, `[[`, character(1), 4L),
    appointment_offered = vapply(rows, function(r) as.logical(r[[5L]]), logical(1)),
    business_days_until_appointment = vapply(rows, function(r) as.integer(r[[6L]]), integer(1)),
    calendar_days_until_appointment = vapply(rows, function(r) as.integer(r[[7L]]), integer(1)),
    reason_for_exclusions = vapply(rows, `[[`, character(1), 8L),
    does_the_physician_accept_medicaid = vapply(rows, function(r) as.character(r[[9L]]), character(1)),
    stringsAsFactors = FALSE
  )

  # Scenario alternates deterministically rather than randomly, so the split is
  # reproducible and the counts below are exact.
  out$scenario <- ifelse(seq_len(nrow(out)) %% 2L == 1L,
                         "HIP scenario", "SHOULDER scenario")
  out
}

# --- assembled study ---------------------------------------------------------
mc_canonical_study <- function() {
  providers <- mc_canonical_providers()
  calls     <- mc_canonical_calls()

  merged <- merge(
    calls,
    providers[, c("provider_id", "npi", "physician_information",
                  "practice_name", "state", "academic", "archetype")],
    by.x = "id_number", by.y = "provider_id",
    all.x = TRUE, sort = FALSE
  )

  # merge() does not promise input order; restore the authored order so row
  # positions in this fixture are stable and reviewable.
  key <- paste(calls$id_number, calls$phone, calls$insurance)
  merged <- merged[match(key, paste(merged$id_number, merged$phone, merged$insurance)), ]
  rownames(merged) <- NULL

  list(providers = providers, calls = calls, study = merged)
}

# --- the same study under the workflow's short column names ------------------
# mysterycall_run_workflow() renames phase-2 columns; this returns the study as
# it looks *after* that rename, so the phase-1 to phase-2 contract can be tested
# without running the whole workflow.
mc_canonical_study_workflow_names <- function() {
  s <- mc_canonical_study()$study
  renames <- c(
    physician_information = "physician_info",
    reason_for_exclusions = "exclusion_reasons"
  )
  for (long in names(renames)) {
    if (long %in% names(s)) names(s)[names(s) == long] <- renames[[long]]
  }
  s
}
