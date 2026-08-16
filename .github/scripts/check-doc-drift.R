#!/usr/bin/env Rscript
#
# Fails if regenerating roxygen changes anything tracked.
#
# Run from the repository root:
#     Rscript .github/scripts/check-doc-drift.R
#
# Why this earns a job of its own. While man/ was stale relative to R/, three
# separate real defects were invisible:
#
#   * print.mysterycall_lmm had no documentation at all, because a helper had
#     been inserted between its roxygen block and the function.
#   * as.data.frame.mysterycall_table1 published under another function's
#     title, and carried \keyword{internal} despite @export.
#   * an @importFrom for a Suggests-only package sat unnoticed in a source
#     file, and would have produced a NAMESPACE entry that fails R CMD check.
#
# Each surfaced only when docs were regenerated. Keeping man/ and NAMESPACE
# provably in step with R/ is what makes those failures loud instead of latent.

`%||%` <- function(a, b) if (is.null(a)) b else a

fail <- function(...) {
  cat("::error::", paste0(...), "\n", sep = "")
  quit(status = 1L)
}

if (!file.exists("DESCRIPTION")) fail("Run this from the repository root.")

declared <- tryCatch(
  read.dcf("DESCRIPTION", fields = "Config/roxygen2/version")[1, 1],
  error = function(e) NA_character_
)
installed <- as.character(utils::packageVersion("roxygen2"))
cat("roxygen2 installed:", installed, " declared:", declared %||% "none", "\n")

if (!is.na(declared) && declared != installed) {
  # Hard failure, not a warning. A version mismatch produces formatting-only
  # churn that is indistinguishable from real drift in the diff, so continuing
  # would report a drift failure whose cause is the toolchain rather than the
  # repository -- and send whoever reads it looking for a doc bug that is not
  # there.
  fail("roxygen2 version mismatch: DESCRIPTION declares ", declared,
       " but ", installed, " is installed.\n",
       "      Any diff produced now reflects the version difference, not drift.\n",
       "      Pin the CI install to ", declared, ", or update ",
       "Config/roxygen2/version and regenerate in the same commit.")
}

before <- system2("git", c("status", "--porcelain"), stdout = TRUE)
if (length(before)) {
  cat("Working tree was already dirty before regeneration:\n")
  cat(paste0("  ", before, collapse = "\n"), "\n")
  fail("Refusing to run: a dirty tree makes the diff meaningless.")
}

cat("\nRegenerating with roclets rd + namespace ...\n")
roxygen2::roxygenise(".", roclets = c("rd", "namespace"))

after <- system2("git", c("status", "--porcelain"), stdout = TRUE)
if (!length(after)) {
  cat("\nNo drift: man/ and NAMESPACE are in step with R/.\n")
  quit(status = 0L)
}

cat("\nRegeneration changed", length(after), "path(s):\n")
cat(paste0("  ", after, collapse = "\n"), "\n\n")

diff <- system2("git", c("diff", "--stat"), stdout = TRUE)
if (length(diff)) cat(paste0(diff, collapse = "\n"), "\n\n")

untracked <- grep("^\\?\\?", after, value = TRUE)
if (length(untracked)) {
  cat("New files roxygen produced that are not committed:\n")
  cat(paste0("  ", sub("^\\?\\? ", "", untracked), collapse = "\n"), "\n\n")
}

fail("man/ or NAMESPACE is out of step with R/. Run ",
     "roxygen2::roxygenise() locally and commit the result.")
