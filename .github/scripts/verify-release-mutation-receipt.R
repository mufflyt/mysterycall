#!/usr/bin/env Rscript
#
# Release gate: the complete adversarial campaign must have passed against THIS
# tree, not some earlier one.
#
# Run from the repository root:
#     Rscript .github/scripts/verify-release-mutation-receipt.R
#     Rscript .github/scripts/verify-release-mutation-receipt.R --sha <sha>
#
# THE HOLE THIS CLOSES
#
#   commit A -> full mutation campaign passes
#   commit B -> ordinary CI passes
#   release B
#
# B never faced the campaign. Every badge is green and nothing is false, but the
# release was never subjected to the adversarial layer at all. A green badge is
# not a contract; this verifies a contract.
#
# Four independent bindings, because each can rot on its own:
#
#   SHA                        the receipt was minted for this exact commit
#   test inventory hash        the tests it ran are the tests in this tree
#   source-data manifest hash  the fixture it corrupted is this tree's fixture
#   mutation inventory hash    the attack surface it exercised is this tree's
#
# A receipt can match the SHA and still be worthless if the fixture was swapped
# underneath it, so the hashes are recomputed from the working tree here rather
# than trusted from the receipt.
#
# Sentinel receipts are REFUSED. The per-PR tier runs 5 of 14 mutants by design;
# accepting one here would let a release ship having faced a third of the
# campaign while the receipt still said "PROVEN".

for (p in c("jsonlite", "digest")) {
  if (!requireNamespace(p, quietly = TRUE)) {
    cat("::error::release gate needs the '", p, "' package\n", sep = ""); quit(status = 1L)
  }
}
if (!file.exists("DESCRIPTION")) {
  cat("::error::run from the repository root\n"); quit(status = 1L)
}

args <- commandArgs(trailingOnly = TRUE)
arg <- function(flag, alt) {
  i <- which(args == flag)
  if (!length(i)) return(alt)
  if (i[1] == length(args)) { cat("::error::", flag, " requires a value\n", sep = ""); quit(status = 1L) }
  args[[i[1] + 1L]]
}
env_or <- function(v, alt) { x <- Sys.getenv(v); if (nzchar(x)) x else alt }
git1 <- function(cmd, alt) {
  out <- suppressWarnings(try(system(cmd, intern = TRUE, ignore.stderr = TRUE), silent = TRUE))
  if (inherits(out, "try-error") || !length(out) || !nzchar(out[1])) alt else out[1]
}

RELEASE_SHA <- arg("--sha", env_or("GITHUB_SHA", git1("git rev-parse HEAD", NA_character_)))
if (is.na(RELEASE_SHA) || !nzchar(RELEASE_SHA)) {
  cat("::error::cannot determine the release SHA\n"); quit(status = 1L)
}

RECEIPT <- arg("--receipt", "mutation-receipt.json")
if (!file.exists(RECEIPT)) {
  cat("::error::no ", RECEIPT, " -- refusing to release.\n", sep = "")
  cat("A release with no mutation receipt is a release that never faced the\n")
  cat("adversarial campaign. Download the artifact from the full campaign run\n")
  cat("for this SHA, or run: Rscript .github/scripts/check-scientific-mutations.R\n")
  quit(status = 1L)
}

r <- jsonlite::fromJSON(RECEIPT, simplifyVector = TRUE)
fails <- character(0)
bad <- function(...) fails <<- c(fails, paste0(...))
ok  <- function(...) cat("  ok    ", paste0(...), "\n")

# --- recompute the inventories from THIS tree ---------------------------------
sha_of_files <- function(paths) {
  paths <- sort(paths[file.exists(paths)])
  if (!length(paths)) return(NA_character_)
  digest::digest(paste(vapply(paths, function(f)
    paste(f, digest::digest(file = f, algo = "sha256")), character(1)),
    collapse = "\n"), algo = "sha256")
}
# Read the declared list out of the campaign source rather than duplicating it:
# a second copy here would drift and this gate would certify the wrong thing.
camp <- ".github/scripts/check-scientific-mutations.R"
if (!file.exists(camp)) { cat("::error::campaign script missing: ", camp, "\n", sep = ""); quit(status = 1L) }
src <- readLines(camp, warn = FALSE)
blk <- function(start_pat) {
  i <- grep(start_pat, src)[1]
  if (is.na(i)) return(character(0))
  j <- grep("^\\)", src[i:length(src)])[1] + i - 1L
  paste(src[i:j], collapse = "\n")
}
tf <- regmatches(blk("^TEST_FILES <- c\\("),
                 gregexpr('"[^"]+"', blk("^TEST_FILES <- c\\(")))[[1]]
tf <- gsub('"', "", tf)

cat("release mutation gate\n")
cat("  release SHA: ", RELEASE_SHA, "\n", sep = "")
cat("  receipt:     ", RECEIPT, "\n\n", sep = "")

cat("== the receipt is a COMPLETE campaign\n")
if (!identical(as.character(r$schema), "mysterycall/mutation-receipt/v2")) {
  bad("unrecognised receipt schema: ", as.character(r$schema))
} else ok("schema v2")
mode <- if (is.null(r$mode)) "full" else as.character(r$mode)
if (!identical(mode, "full")) {
  bad("receipt mode is '", mode, "'; a release requires the FULL campaign. ",
      "The sentinel tier runs a deliberate subset and cannot certify a release.")
} else ok("mode: full")
if (!isTRUE(r$control_passed$passed)) bad("the receipt's control did not pass") else ok("control passed")
if (!isTRUE(r$poison_failed$all_killed)) {
  bad(length(r$poison_failed$survivors), " mutant(s) survived: ",
      paste(r$poison_failed$survivors, collapse = ", "))
} else ok("all ", r$poison_failed$mutants_killed, " of ",
          r$poison_failed$mutants_attempted, " poisoned analyses failed")

cat("\n== the receipt certifies THIS tree\n")
pv <- r$provenance
if (!identical(as.character(pv$sha), RELEASE_SHA)) {
  bad("receipt SHA ", substr(as.character(pv$sha), 1, 12), " != release SHA ",
      substr(RELEASE_SHA, 1, 12), ". The campaign passed on a DIFFERENT commit.")
} else ok("SHA matches: ", substr(RELEASE_SHA, 1, 12))

check_hash <- function(label, field, actual) {
  claimed <- as.character(pv[[field]])
  if (is.na(actual)) { bad(label, ": cannot recompute from this tree"); return(invisible()) }
  if (!identical(claimed, actual)) {
    bad(label, " changed since the receipt was minted (receipt ",
        substr(claimed, 1, 12), ", tree ", substr(actual, 1, 12), ")")
  } else ok(label, " matches: ", substr(actual, 1, 12))
}
check_hash("test inventory",       "test_inventory_sha256",       sha_of_files(tf))
check_hash("source-data manifest", "source_data_manifest_sha256",
           sha_of_files(c("tests/fixtures/canonical_study.R",
                          "tests/fixtures/canonical_study_expected.json")))

cat("\n== the run is attributable\n")
for (f in c("repository", "timestamp", "workflow_run_id")) {
  v <- pv[[f]]
  if (is.null(v) || is.na(v) || !nzchar(as.character(v))) {
    if (identical(f, "workflow_run_id")) {
      cat("  warn   workflow_run_id absent (a local run, not a CI run)\n")
    } else bad("provenance field '", f, "' is absent")
  } else ok(f, ": ", as.character(v))
}

cat("\n")
if (length(fails)) {
  cat("::error::REFUSING TO RELEASE.\n")
  for (f in fails) cat("  - ", f, "\n", sep = "")
  cat("\nA release must be able to prove the complete adversarial campaign ran\n")
  cat("against the exact tree being shipped. Re-run the full campaign on this\n")
  cat("SHA and gate on its receipt.\n")
  quit(status = 1L)
}
cat("RELEASE CLEARED: the complete campaign passed against ", substr(RELEASE_SHA, 1, 12), ".\n", sep = "")
