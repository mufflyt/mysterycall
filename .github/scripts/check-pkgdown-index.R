#!/usr/bin/env Rscript
#
# Every documented topic must appear in the _pkgdown.yml reference index.
#
# pkgdown enforces this already, but it enforces it at the end of a full site
# build that takes about fifteen minutes. Adding an exported function and
# forgetting to list it therefore costs a quarter of an hour to discover, and
# it has cost exactly that at least once (mysterycall_format_ci and
# mysterycall_format_p, PR #263). This runs the same check against the same
# two files in about a second, so the mistake surfaces in repo-hygiene.
#
# Mirrors pkgdown::build_reference_index(): the unit is an .Rd topic, not a
# NAMESPACE export, and a topic counts as indexed when ANY of its \alias{}
# entries is listed, not just the one matching the filename. S3 methods
# documented under another topic via @rdname produce no .Rd of their own and
# so never come up. Topics marked \keyword{internal} are exempt, as in pkgdown.

rd_dir <- "man"
yml    <- "_pkgdown.yml"

if (!dir.exists(rd_dir)) stop("No man/ directory; run from the package root.")
if (!file.exists(yml))   stop("No _pkgdown.yml; run from the package root.")

rd_files <- list.files(rd_dir, pattern = "[.]Rd$", full.names = TRUE)
if (length(rd_files) == 0L) stop("No .Rd files found in man/.")

is_internal <- vapply(rd_files, function(f) {
  any(grepl("\\\\keyword\\{internal\\}", readLines(f, warn = FALSE)))
}, logical(1L))

# A topic is identified by all of its aliases; pkgdown accepts any one of them.
aliases <- lapply(rd_files[!is_internal], function(f) {
  ln <- readLines(f, warn = FALSE)
  a  <- ln[grepl("^\\\\alias[{]", ln)]
  unique(c(sub("[.]Rd$", "", basename(f)),
           gsub("^\\\\alias[{](.*)[}][[:space:]]*$", "\\1", a)))
})
names(aliases) <- sub("[.]Rd$", "", basename(rd_files[!is_internal]))

# Reference entries are list items under contents:, one topic per line.
yml_lines <- readLines(yml, warn = FALSE)
listed <- trimws(sub("^[[:space:]]*-[[:space:]]*", "",
                     yml_lines[grepl("^[[:space:]]*-[[:space:]]*[A-Za-z.`]", yml_lines)]))
listed <- gsub("[`\"']", "", listed)

covered <- vapply(aliases, function(a) any(a %in% listed), logical(1L))
missing <- names(aliases)[!covered]

cat(sprintf("Documented topics: %d (%d internal, exempt)\n",
            length(aliases), sum(is_internal)))

if (length(missing) > 0L) {
  cat(sprintf("\nFAIL: %d topic(s) documented but absent from %s:\n\n",
              length(missing), yml))
  cat(paste0("  - ", sort(missing), collapse = "\n"), "\n\n")
  cat("Add each under an appropriate `contents:` section of _pkgdown.yml.\n")
  cat("pkgdown would fail on these anyway, roughly fifteen minutes from now.\n")
  quit(status = 1L)
}

cat("OK: every documented topic is in the pkgdown reference index.\n")
