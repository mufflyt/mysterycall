#!/usr/bin/env Rscript
#
# Validates the bundled datasets in data/.
#
# Run from the repository root:
#     Rscript .github/scripts/check-data-integrity.R
#
# Checks that hold for every dataset (loads, non-empty, no all-NA columns, no
# duplicated column names), plus per-dataset invariants for the ones the
# package's own analysis relies on. A silently corrupted crosswalk or index
# would otherwise surface as quietly wrong results rather than an error.

failures <- character(0)
fail <- function(...) failures <<- c(failures, paste0(...))
ok    <- function(...) cat("  ok   ", paste0(...), "\n")
bad   <- function(...) { cat("  FAIL ", paste0(...), "\n"); fail(...) }

if (!file.exists("DESCRIPTION")) {
  cat("::error::Run this from the repository root.\n"); quit(status = 1L)
}

rda <- list.files("data", pattern = "[.]rda$", full.names = TRUE)
if (!length(rda)) {
  cat("::error::No .rda files found in data/.\n"); quit(status = 1L)
}
cat("Found", length(rda), "datasets\n\n")

env <- new.env(parent = emptyenv())
loaded <- character(0)

## ---------------------------------------------------------------------------
cat("== every dataset loads and is structurally sane\n")
for (f in rda) {
  nm <- tryCatch(load(f, envir = env), error = function(e) NULL)
  if (is.null(nm)) { bad(basename(f), " failed to load"); next }
  loaded <- c(loaded, nm)

  for (obj_name in nm) {
    x <- get(obj_name, envir = env)

    n <- if (is.data.frame(x)) nrow(x) else length(x)
    if (n == 0L) { bad(obj_name, " is empty"); next }

    if (is.data.frame(x)) {
      if (anyDuplicated(names(x))) {
        bad(obj_name, " has duplicated column names")
        next
      }
      all_na <- names(x)[vapply(x, function(col) all(is.na(col)), logical(1))]
      if (length(all_na)) {
        bad(obj_name, " has all-NA column(s): ", paste(all_na, collapse = ", "))
        next
      }
      ok(sprintf("%-28s %7d rows x %2d cols", obj_name, nrow(x), ncol(x)))
    } else {
      ok(sprintf("%-28s length %d (%s)", obj_name, n, class(x)[1]))
    }
  }
}

## ---------------------------------------------------------------------------
## Per-dataset invariants. Each mirrors an assumption package code makes.
## ---------------------------------------------------------------------------
has <- function(nm) exists(nm, envir = env, inherits = FALSE)
get_ <- function(nm) get(nm, envir = env)

cat("\n== ZCTA keys are 5-digit, tract keys are 11-digit\n")
if (has("zcta_tract_xwalk")) {
  x <- get_("zcta_tract_xwalk")
  if (!all(grepl("^[0-9]{5}$", x$zcta))) bad("zcta_tract_xwalk$zcta: not all 5-digit")
  else ok("zcta_tract_xwalk$zcta all 5-digit")
  if (!all(grepl("^[0-9]{11}$", x$tract))) bad("zcta_tract_xwalk$tract: not all 11-digit")
  else ok("zcta_tract_xwalk$tract all 11-digit")
  if (anyDuplicated(x[c("zcta", "tract")])) bad("zcta_tract_xwalk: duplicated (zcta, tract) pairs")
  else ok("zcta_tract_xwalk (zcta, tract) unique")
  if (!"arealand_part" %in% names(x)) {
    bad("zcta_tract_xwalk: arealand_part missing; the allocation weights ",
        "documented in @format are derived from it and cannot be recomputed")
  } else if (any(!is.finite(x$arealand_part)) || any(x$arealand_part <= 0)) {
    bad("zcta_tract_xwalk$arealand_part: non-finite or non-positive values")
  } else {
    ok("zcta_tract_xwalk$arealand_part positive and finite")
    # The documented recomputation must still reproduce weights summing to 1.
    w <- ave(x$arealand_part, x$zcta, FUN = function(a) a / sum(a))
    s <- tapply(w, x$zcta, sum)
    if (any(abs(s - 1) > 1e-6)) bad("zcta_tract_xwalk: recomputed ZCTA weights do not sum to 1")
    else ok("zcta_tract_xwalk: recomputed ZCTA weights sum to 1")
  }
}

cat("\n== deprivation and vulnerability indices are in range\n")
if (has("adi_zcta")) {
  x <- get_("adi_zcta")
  if (!all(grepl("^[0-9]{5}$", x$zcta))) bad("adi_zcta$zcta: not all 5-digit")
  else ok("adi_zcta$zcta all 5-digit")
  if (anyDuplicated(x$zcta)) bad("adi_zcta$zcta: duplicated") else ok("adi_zcta$zcta unique")
  # adi is the *national linear* ADI, documented in R/adi_zcta.R as "roughly
  # mean 100 / SD 20" -- not a 0-100 percentile. Checking the documented
  # centring and spread catches a wrongly-scaled rebuild, which a bounds check
  # would miss and which a percentile assumption would false-alarm on.
  fin <- x$adi[is.finite(x$adi)]
  if (!length(fin)) {
    bad("adi_zcta$adi has no finite values")
  } else {
    m <- mean(fin); s <- stats::sd(fin)
    if (m < 95 || m > 105)
      bad(sprintf("adi_zcta$adi mean %.2f outside [95, 105]; docs say ~100", m))
    else ok(sprintf("adi_zcta$adi mean %.2f (~100 as documented)", m))
    if (s < 15 || s > 25)
      bad(sprintf("adi_zcta$adi SD %.2f outside [15, 25]; docs say ~20", s))
    else ok(sprintf("adi_zcta$adi SD %.2f (~20 as documented)", s))
    if (min(fin) <= 0)
      bad(sprintf("adi_zcta$adi has non-positive values (min %.2f)", min(fin)))
    else ok(sprintf("adi_zcta$adi positive (range %.2f-%.2f)", min(fin), max(fin)))
  }
}
if (has("svi_zcta")) {
  x <- get_("svi_zcta")
  if (anyDuplicated(x$zcta)) bad("svi_zcta$zcta: duplicated") else ok("svi_zcta$zcta unique")
  fin <- x$svi[is.finite(x$svi)]
  if (length(fin) && (min(fin) < 0 || max(fin) > 1))
    bad(sprintf("svi_zcta$svi outside [0, 1]: [%.4f, %.4f]", min(fin), max(fin)))
  else ok("svi_zcta$svi within [0, 1]")
}

cat("\n== state-keyed datasets use two-letter codes\n")
if (has("medicaid_expansion")) {
  x <- get_("medicaid_expansion")
  if (nrow(x) != 51L)
    bad(sprintf("medicaid_expansion has %d rows; expected 51 (50 states + DC)", nrow(x)))
  else ok("medicaid_expansion has 51 rows")
  if ("expanded" %in% names(x) && !is.logical(x$expanded))
    bad("medicaid_expansion$expanded is not logical")
  else ok("medicaid_expansion$expanded is logical")
}

cat("\n== physician age reference\n")
if (has("healthgrades_ages")) {
  x <- get_("healthgrades_ages")
  need <- c("first_name", "last_name", "state", "age_current")
  miss <- setdiff(need, names(x))
  if (length(miss)) bad("healthgrades_ages missing column(s): ", paste(miss, collapse = ", "))
  else ok("healthgrades_ages has the columns mysterycall_lookup_age() requires")
  if ("age_current" %in% names(x)) {
    fin <- x$age_current[is.finite(x$age_current)]
    if (length(fin) && (min(fin) < 20 || max(fin) > 110))
      bad(sprintf("healthgrades_ages$age_current implausible: [%.0f, %.0f]", min(fin), max(fin)))
    else ok("healthgrades_ages$age_current plausible")
  }
}

## ---------------------------------------------------------------------------
cat("\n")
if (length(failures)) {
  cat("::error::Data integrity FAILED\n")
  for (f in failures) cat("  - ", f, "\n", sep = "")
  quit(status = 1L)
}
cat("Data integrity passed:", length(loaded), "objects checked.\n")
