#!/usr/bin/env Rscript
#
# Run only the test files whose names match a pattern, in one R session.
#
#   Rscript tools/run-test-subset.R 'format|checklist|sampl'
#   Rscript tools/run-test-subset.R geocode
#
# The full suite takes tens of minutes locally, because many files fit lme4 or
# glmmTMB models and testthat::test_file() reloads the package for each one.
# When a change touches a known set of files, running just those turns a
# twenty-minute wait into a couple of minutes, and catches the failure before
# it costs a CI cycle.
#
# Prints a one-line summary per file and a failing-test table at the end, so
# the output stays readable when dozens of files are selected.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L) {
  stop("Usage: Rscript tools/run-test-subset.R '<regex matched against test file names>'",
       call. = FALSE)
}
pattern <- args[[1L]]

suppressMessages(devtools::load_all(quiet = TRUE))

files <- list.files("tests/testthat", pattern = "^test-", full.names = TRUE)
sel   <- files[grepl(pattern, basename(files))]
if (length(sel) == 0L) {
  stop(sprintf("No test files match '%s'.", pattern), call. = FALSE)
}
cat(sprintf("Running %d of %d test files matching '%s'\n\n",
            length(sel), length(files), pattern))

rows <- list()
for (f in sel) {
  r <- tryCatch(testthat::test_file(f, reporter = "silent"),
                error = function(e) e)
  if (inherits(r, "error")) {
    rows[[f]] <- data.frame(file = basename(f), test = "<file failed to run>",
                            failed = 1L, error = TRUE)
    cat(sprintf("  %-52s ERROR: %s\n", basename(f), conditionMessage(r)))
    next
  }
  d <- as.data.frame(r)
  d$file <- basename(f)
  rows[[f]] <- d[, c("file", "test", "failed", "error")]
  cat(sprintf("  %-52s %4d passed  %2d failed\n",
              basename(f), sum(d$nb) - sum(d$failed), sum(d$failed)))
}

df  <- do.call(rbind, rows)
bad <- df[df$failed > 0 | df$error, ]

cat(sprintf("\n%d files, %d tests, %d failing\n",
            length(sel), nrow(df), nrow(bad)))
if (nrow(bad) > 0L) {
  cat("\nFailing:\n")
  print(bad, row.names = FALSE)
  quit(status = 1L)
}
cat("All green.\n")
