#!/usr/bin/env Rscript
#
# Dependency-declaration consistency between DESCRIPTION, NAMESPACE, and the
# actual code.
#
# Run from the repository root:
#     Rscript .github/scripts/check-dependencies.R
#
# The specific failure this exists to prevent: an @importFrom for a package
# listed only in Suggests. It produces a NAMESPACE entry that R CMD check
# rejects, and it is easy to introduce because roxygen writes the entry
# without consulting DESCRIPTION. That happened once with jsonlite.

failures <- character(0)
fail <- function(...) failures <<- c(failures, paste0(...))
section <- function(x) cat("\n== ", x, "\n", sep = "")

if (!file.exists("DESCRIPTION") || !file.exists("NAMESPACE")) {
  cat("::error::Run this from the repository root.\n"); quit(status = 1L)
}

dcf <- read.dcf("DESCRIPTION")
# unname(): read.dcf() carries the column name through, and identical() is
# strict about attributes, so a bare comparison reports two equal strings as
# different.
field <- function(nm) {
  if (!nm %in% colnames(dcf)) return(NA_character_)
  trimws(unname(dcf[1, nm]))
}

split_deps <- function(x) {
  if (is.na(x)) return(character(0))
  parts <- trimws(strsplit(x, ",")[[1]])
  parts <- sub("\\s*\\(.*\\)$", "", parts)   # drop version constraints
  parts[nzchar(parts)]
}

imports  <- split_deps(field("Imports"))
suggests <- split_deps(field("Suggests"))
depends  <- setdiff(split_deps(field("Depends")), "R")

cat("Imports:", length(imports), " Suggests:", length(suggests),
    " Depends:", length(depends), "\n")

## ---------------------------------------------------------------------------
section("no package appears in more than one dependency field")
dupes <- intersect(imports, suggests)
if (length(dupes)) fail("In both Imports and Suggests: ", paste(dupes, collapse = ", "))
d2 <- intersect(depends, imports)
if (length(d2)) fail("In both Depends and Imports: ", paste(d2, collapse = ", "))
if (!length(dupes) && !length(d2)) cat("  ok\n") else cat("  FAIL\n")

## ---------------------------------------------------------------------------
section("NAMESPACE imports only from Imports/Depends, never Suggests")
ns <- readLines("NAMESPACE", warn = FALSE)
imported_from <- unique(c(
  sub("^importFrom\\(([^,]+),.*$", "\\1", grep("^importFrom\\(", ns, value = TRUE)),
  sub("^import\\(([^,)]+).*$",    "\\1", grep("^import\\(",     ns, value = TRUE))
))
imported_from <- gsub("[\"']", "", imported_from)
imported_from <- setdiff(imported_from, "")

from_suggests <- intersect(imported_from, suggests)
if (length(from_suggests)) {
  cat("  FAIL NAMESPACE imports from Suggests-only package(s): ",
      paste(from_suggests, collapse = ", "), "\n", sep = "")
  fail("NAMESPACE imports from Suggests-only: ", paste(from_suggests, collapse = ", "),
       ". Either move the package to Imports, or drop the @importFrom and call it ",
       "with :: behind a requireNamespace() guard.")
} else {
  cat("  ok   ", length(imported_from), " package(s) imported, all declared\n", sep = "")
}

undeclared <- setdiff(imported_from, c(imports, depends, "base", "methods", "utils", "stats"))
if (length(undeclared)) {
  cat("  FAIL imported but not declared: ", paste(undeclared, collapse = ", "), "\n", sep = "")
  fail("NAMESPACE imports undeclared package(s): ", paste(undeclared, collapse = ", "))
}

## ---------------------------------------------------------------------------
section("Suggests are used conditionally")
r_files <- list.files("R", pattern = "[.]R$", full.names = TRUE)
src <- unlist(lapply(r_files, readLines, warn = FALSE))
src <- src[!grepl("^\\s*#", src)]          # ignore comments

guarded <- unique(unlist(regmatches(
  src, gregexpr("(?<=requireNamespace\\([\"'])[A-Za-z0-9.]+", src, perl = TRUE)
)))

unguarded <- character(0)
for (p in suggests) {
  used <- any(grepl(paste0("\\b", gsub("\\.", "\\\\.", p), "::"), src))
  if (used && !(p %in% guarded)) unguarded <- c(unguarded, p)
}
if (length(unguarded)) {
  cat("  WARN used via :: with no requireNamespace() guard: ",
      paste(unguarded, collapse = ", "), "\n", sep = "")
  cat("::warning::CRAN expects Suggests to be used conditionally. Unguarded: ",
      paste(unguarded, collapse = ", "), "\n", sep = "")
} else {
  cat("  ok   every Suggests package used via :: is guarded\n")
}

## ---------------------------------------------------------------------------
section("Imports are actually used")
unused <- character(0)
for (p in imports) {
  pat <- paste0("\\b", gsub("\\.", "\\\\.", p), "::")
  if (!any(grepl(pat, src)) && !(p %in% imported_from)) unused <- c(unused, p)
}
if (length(unused)) {
  cat("  WARN declared in Imports but never used via :: or importFrom: ",
      paste(unused, collapse = ", "), "\n", sep = "")
  cat("::warning::Unused Imports inflate the install footprint: ",
      paste(unused, collapse = ", "), "\n", sep = "")
} else {
  cat("  ok   every Imports package is referenced\n")
}

## ---------------------------------------------------------------------------
section("version metadata agrees")
ver <- field("Version")
cat("  DESCRIPTION  ", ver, "\n")
if (file.exists("CITATION.cff")) {
  cff <- grep("^version:", readLines("CITATION.cff", warn = FALSE), value = TRUE)
  if (length(cff)) {
    cv <- trimws(gsub("^version:\\s*\"?([^\"]*)\"?\\s*$", "\\1", cff[1]))
    cat("  CITATION.cff ", cv, "\n")
    if (!identical(cv, ver)) fail("CITATION.cff version ", cv, " != DESCRIPTION ", ver)
  }
}
if (file.exists("codemeta.json") && requireNamespace("jsonlite", quietly = TRUE)) {
  cm <- jsonlite::fromJSON("codemeta.json", simplifyVector = FALSE)$version
  if (!is.null(cm)) {
    cat("  codemeta.json", as.character(cm), "\n")
    if (!identical(as.character(cm), ver))
      fail("codemeta.json version ", cm, " != DESCRIPTION ", ver)
  }
}

## ---------------------------------------------------------------------------
cat("\n")
if (length(failures)) {
  cat("::error::Dependency checks FAILED\n")
  for (f in failures) cat("  - ", f, "\n", sep = "")
  quit(status = 1L)
}
cat("Dependency checks passed.\n")
