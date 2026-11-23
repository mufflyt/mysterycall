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

# A topic is identified by its aliases, and pkgdown accepts any one of them.
# The .Rd FILENAME is deliberately not treated as an alias: @rdname names the
# file after the shared topic ("coef.mysterycall.Rd") while \name{} and
# \alias{} carry the method names, and pkgdown::build_reference_index()
# resolves by name/alias only. Accepting the filename here let
# "- coef.mysterycall" satisfy this check and then fail the real site build
# seven minutes later, which is the failure this script exists to prevent.
aliases <- lapply(rd_files[!is_internal], function(f) {
  ln <- readLines(f, warn = FALSE)
  a  <- ln[grepl("^\\\\alias[{]", ln)]
  unique(gsub("^\\\\alias[{](.*)[}][[:space:]]*$", "\\1", a))
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

# The reverse direction: every plain topic listed must resolve to a real
# alias. The forward check above cannot catch a typo or a stale entry, and
# pkgdown aborts on one with "not a known topic name or alias".
#
# pkgdown's selector functions -- starts_with(), matches(), has_keyword() and
# friends -- and exclusions beginning with "-" are passed through untouched,
# as are article names, which live in a different index.
all_aliases <- unique(unlist(lapply(rd_files, function(f) {
  ln <- readLines(f, warn = FALSE)
  a  <- ln[grepl("^\\\\alias[{]", ln)]
  gsub("^\\\\alias[{](.*)[}][[:space:]]*$", "\\1", a)
})))

articles <- sub("[.][Rq]md$", "", basename(Sys.glob("vignettes/*.Rmd")))

# Only entries inside a `contents:` block are topics. The forward check
# above can afford a loose line scan -- extra strings only make matching
# more permissive -- but this direction would otherwise flag navbar items
# and "- title:" mappings as unknown topics. Tracked by indentation so the
# script keeps its zero-dependency, sub-second behaviour.
contents_entries <- character(0)
in_contents <- FALSE
contents_indent <- -1L
indent_of <- function(x) nchar(sub("[^[:space:]].*$", "", x))

for (ln in yml_lines) {
  if (grepl("^[[:space:]]*contents:[[:space:]]*$", ln)) {
    in_contents <- TRUE
    contents_indent <- indent_of(ln)
    next
  }
  if (!in_contents || !nzchar(trimws(ln))) next

  is_item <- grepl("^[[:space:]]*-[[:space:]]", ln)
  if (!is_item && indent_of(ln) <= contents_indent) {
    in_contents <- FALSE
    next
  }
  if (!is_item) next

  item <- trimws(sub("^[[:space:]]*-[[:space:]]*", "", ln))
  item <- gsub("[`\"']", "", item)
  # "- title: x" and friends are mappings, not topics.
  if (grepl(":", item)) next
  contents_entries <- c(contents_entries, item)
}

plain <- unique(contents_entries[
  !grepl("[()]", contents_entries) &
    !startsWith(contents_entries, "-") &
    nzchar(contents_entries)
])
unknown <- setdiff(plain, c(all_aliases, articles))

if (length(unknown) > 0L) {
  cat(sprintf("\nFAIL: %d entry(ies) in %s match no topic alias:\n\n",
              length(unknown), yml))
  cat(paste0("  - ", sort(unknown), collapse = "\n"), "\n\n")
  cat("pkgdown::build_reference_index() aborts on these with\n")
  cat("\"not a known topic name or alias\". An @rdname names the .Rd file,\n")
  cat("not the topic: list the \\name{} or an \\alias{} instead.\n")
  quit(status = 1L)
}

cat(sprintf("Reference entries checked: %d plain topic(s), all resolve.\n",
            length(plain)))
cat("OK: every documented topic is in the pkgdown reference index.\n")
