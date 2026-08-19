#!/usr/bin/env Rscript
#
# Repo hygiene checks. Run from the repository root:
#
#     Rscript .github/scripts/check-repo-hygiene.R
#
# Exits non-zero if any check fails. Each check guards a mistake that has
# actually happened in this repository, so the messages name the specific
# regression rather than a generic rule.

failures <- character(0)

fail <- function(...) failures <<- c(failures, paste0(...))

section <- function(title) cat("\n== ", title, "\n", sep = "")

tracked <- function() {
  out <- system2("git", c("ls-files"), stdout = TRUE, stderr = FALSE)
  if (!length(out)) character(0) else out
}

## ---------------------------------------------------------------------------
## 1. Generated output must never be tracked.
##
## .cache/ (2688 blobs) and docs/ (pkgdown output, rebuilt and deployed to
## gh-pages by pkgdown.yaml) were both tracked for a long time despite
## .gitignore intending to exclude them.
## ---------------------------------------------------------------------------
section("generated output is not tracked")

forbidden <- list(
  "docs/"     = "^docs/",
  ".cache/"   = "^\\.cache/",
  "doc/"      = "^doc/",
  "Meta/"     = "^Meta/",
  "*.tar.gz"  = "\\.tar\\.gz$",
  "*.Rcheck/" = "\\.Rcheck/",
  "Rplots.pdf" = "(^|/)Rplots\\.pdf$"
)

files <- tracked()
for (label in names(forbidden)) {
  hits <- grep(forbidden[[label]], files, value = TRUE)
  if (length(hits)) {
    fail(
      sprintf("%s is tracked again (%d files, e.g. %s). ", label, length(hits), hits[1]),
      "This is generated output; keep it out of the index."
    )
    cat(sprintf("  FAIL %-12s %d tracked\n", label, length(hits)))
  } else {
    cat(sprintf("  ok   %-12s untracked\n", label))
  }
}

## ---------------------------------------------------------------------------
## 2. .Rbuildignore must hold valid, non-duplicated regexes.
##
## It carried ^mysterycall\.Rproj$ twice.
## ---------------------------------------------------------------------------
section(".Rbuildignore is well formed")

if (!file.exists(".Rbuildignore")) {
  fail(".Rbuildignore is missing.")
} else {
  pat <- readLines(".Rbuildignore", warn = FALSE)
  pat <- pat[nzchar(trimws(pat)) & !grepl("^[[:space:]]*#", pat)]

  dupes <- unique(pat[duplicated(pat)])
  if (length(dupes)) {
    fail("Duplicated .Rbuildignore entries: ", paste(dupes, collapse = ", "))
    cat("  FAIL duplicates:", paste(dupes, collapse = ", "), "\n")
  } else {
    cat("  ok   no duplicates (", length(pat), " patterns )\n", sep = "")
  }

  bad <- pat[vapply(pat, function(p) {
    inherits(try(grepl(p, "probe", perl = TRUE), silent = TRUE), "try-error")
  }, logical(1))]
  if (length(bad)) {
    fail("Invalid regex in .Rbuildignore: ", paste(bad, collapse = ", "))
    cat("  FAIL invalid regex:", paste(bad, collapse = ", "), "\n")
  } else {
    cat("  ok   all patterns are valid regexes\n")
  }
}

## ---------------------------------------------------------------------------
## 3. .gitignore must not contain .Rbuildignore-style regexes.
##
## It held ^\\.secrets$, ^\\.cache$ and ^docs$ -- none of which are gitignore
## syntax, so .secrets was never actually ignored. Silent failures like that
## are worth a hard gate.
## ---------------------------------------------------------------------------
section(".gitignore uses gitignore syntax, not regex")

if (!file.exists(".gitignore")) {
  fail(".gitignore is missing.")
} else {
  lines <- readLines(".gitignore", warn = FALSE)
  lines <- lines[nzchar(trimws(lines)) & !grepl("^[[:space:]]*#", lines)]
  # A leading ^ or a trailing $ is regex, never a gitignore glob. Likewise the
  # doubled backslash that .Rbuildignore entries use.
  suspect <- grep("^\\^|\\$$|\\\\\\\\", lines, value = TRUE)
  if (length(suspect)) {
    fail(
      ".gitignore contains regex-style patterns that match nothing: ",
      paste(suspect, collapse = ", "),
      ". Use gitignore globs instead."
    )
    cat("  FAIL regex-style lines:", paste(suspect, collapse = ", "), "\n")
  } else {
    cat("  ok   no regex-style patterns\n")
  }
}

## ---------------------------------------------------------------------------
## 4. Version must agree across DESCRIPTION, CITATION.cff and codemeta.json.
##
## CITATION.cff and codemeta.json sat at 1.4.0 while DESCRIPTION was at
## 1.6.3.9000 -- two minor versions stale in the files citation managers and
## codemeta consumers read.
## ---------------------------------------------------------------------------
section("version metadata is in sync")

desc_ver <- unname(read.dcf("DESCRIPTION", fields = "Version")[1, "Version"])
cat("  DESCRIPTION  ", desc_ver, "\n")

cff_ver <- NA_character_
if (file.exists("CITATION.cff")) {
  cff <- readLines("CITATION.cff", warn = FALSE)
  hit <- grep('^version:[[:space:]]*', cff, value = TRUE)
  if (length(hit)) {
    cff_ver <- gsub('^version:[[:space:]]*"?([^"]*)"?[[:space:]]*$', "\\1", hit[1])
  }
}
cat("  CITATION.cff ", cff_ver, "\n")

cm_ver <- NA_character_
if (file.exists("codemeta.json")) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    cm <- jsonlite::fromJSON("codemeta.json", simplifyVector = FALSE)
    if (!is.null(cm$version)) cm_ver <- as.character(cm$version)
  } else {
    fail("jsonlite is unavailable, so codemeta.json version could not be checked.")
  }
}
cat("  codemeta.json", cm_ver, "\n")

if (!is.na(cff_ver) && !identical(cff_ver, desc_ver)) {
  fail(sprintf(
    "CITATION.cff version (%s) does not match DESCRIPTION (%s).", cff_ver, desc_ver
  ))
  cat("  FAIL CITATION.cff is out of sync\n")
}
if (!is.na(cm_ver) && !identical(cm_ver, desc_ver)) {
  fail(sprintf(
    "codemeta.json version (%s) does not match DESCRIPTION (%s).", cm_ver, desc_ver
  ))
  cat("  FAIL codemeta.json is out of sync\n")
}
if ((is.na(cff_ver) || identical(cff_ver, desc_ver)) &&
    (is.na(cm_ver) || identical(cm_ver, desc_ver))) {
  cat("  ok   all three agree\n")
}

## ---------------------------------------------------------------------------
## 5. Every export and every vignette must appear in the pkgdown index.
##
## pkgdown fails the build for an unindexed topic ("1 topic missing from index")
## and again for an unindexed article. Both have happened here, and both were
## only discovered after a full pkgdown run had already burned several minutes,
## because nothing cheaper looked. This check costs a second and reads the same
## two lists pkgdown reads.
##
## Re-exported operators are excluded: pkgdown documents them through the
## package that owns them, so requiring an index entry would be wrong.

section("pkgdown index covers every export and vignette")

if (!file.exists("_pkgdown.yml")) {
  cat("  skip  no _pkgdown.yml\n")
} else if (!requireNamespace("yaml", quietly = TRUE)) {
  cat("  skip  yaml package not available\n")
} else {
  y <- yaml::read_yaml("_pkgdown.yml")

  ref_idx <- unlist(lapply(y$reference, function(s) s$contents))
  art_idx <- unlist(lapply(y$articles,  function(s) s$contents))
  # selector helpers (starts_with(...) and friends) are not literal topic names
  ref_idx <- ref_idx[!grepl("^(starts_with|ends_with|matches|contains|has_keyword|everything)\\(", ref_idx)]

  ns <- tryCatch({
    if (requireNamespace("pkgload", quietly = TRUE)) {
      suppressMessages(pkgload::load_all(".", quiet = TRUE))
      getNamespaceExports("mysterycall")
    } else NULL
  }, error = function(e) NULL)

  if (is.null(ns)) {
    cat("  skip  package would not load; export index not checked\n")
  } else {
    # operators such as %>% are re-exports documented upstream
    exports <- ns[!grepl("^%.*%$", ns)]
    missing_topics <- setdiff(exports, ref_idx)
    if (length(missing_topics)) {
      fail("export(s) missing from the _pkgdown.yml reference index: ",
           paste(sort(missing_topics), collapse = ", "),
           ". pkgdown fails the build for these; add them beside their @family.")
    } else {
      cat("  ok   ", length(exports), " exports all indexed\n", sep = "")
    }
  }

  vigs <- sub("[.]Rmd$", "", list.files("vignettes", pattern = "[.]Rmd$"))
  missing_articles <- setdiff(vigs, art_idx)
  if (length(missing_articles)) {
    fail("vignette(s) missing from the _pkgdown.yml articles index: ",
         paste(sort(missing_articles), collapse = ", "),
         ". pkgdown fails the build for these the same way it does for topics.")
  } else {
    cat("  ok   ", length(vigs), " vignettes all indexed\n", sep = "")
  }

  orphan_articles <- setdiff(art_idx, vigs)
  if (length(orphan_articles)) {
    fail("articles index names vignette(s) that do not exist: ",
         paste(sort(orphan_articles), collapse = ", "))
  } else {
    cat("  ok   no orphaned article entries\n")
  }
}

## ---------------------------------------------------------------------------

cat("\n")
if (length(failures)) {
  cat("Repo hygiene FAILED:\n")
  for (f in failures) cat("  - ", f, "\n", sep = "")
  quit(status = 1L)
}
cat("Repo hygiene passed.\n")
