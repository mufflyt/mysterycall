#!/usr/bin/env Rscript
#
# Source portability checks that R CMD check does not perform, or performs
# only on the parsed code where comments have already been stripped.
#
# Run from the repository root:
#     Rscript .github/scripts/check-portability.R

failures <- character(0)
fail <- function(...) failures <<- c(failures, paste0(...))
section <- function(x) cat("\n== ", x, "\n", sep = "")

if (!file.exists("DESCRIPTION")) {
  cat("::error::Run this from the repository root.\n"); quit(status = 1L)
}

r_files <- list.files("R", pattern = "[.]R$", full.names = TRUE)
all_src <- c(
  r_files,
  list.files("tests", pattern = "[.]R$", full.names = TRUE, recursive = TRUE),
  list.files("data-raw", pattern = "[.]R$", full.names = TRUE),
  list.files(".github/scripts", pattern = "[.]R$", full.names = TRUE)
)

## ---------------------------------------------------------------------------
## 1. Non-ASCII in R code. R CMD check inspects parsed code, so it sees only
##    string literals; comments are stripped before it looks. This checks the
##    bytes on disk, and reports the two cases separately because they have
##    different fixes: \uXXXX escapes for literals, plain ASCII for comments.
## ---------------------------------------------------------------------------
section("non-ASCII in R sources")
code_hits <- character(0)
cmnt_hits <- character(0)
for (f in r_files) {
  lines <- readLines(f, warn = FALSE)
  idx <- which(vapply(lines, function(l) any(utf8ToInt(l) > 127L), logical(1),
                      USE.NAMES = FALSE))
  for (i in idx) {
    entry <- sprintf("%s:%d", f, i)
    if (grepl("^\\s*#", lines[i])) cmnt_hits <- c(cmnt_hits, entry)
    else code_hits <- c(code_hits, entry)
  }
}
if (length(code_hits)) {
  cat("  FAIL non-ASCII in code (string literals):\n")
  cat(paste0("    ", utils::head(code_hits, 20), collapse = "\n"), "\n")
  fail("Non-ASCII in R code at: ", paste(utils::head(code_hits, 10), collapse = ", "),
       ". Use \\uXXXX escapes so rendered output is unchanged.")
} else {
  cat("  ok   none in code\n")
}
if (length(cmnt_hits)) {
  cat("  FAIL non-ASCII in comments/roxygen:\n")
  cat(paste0("    ", utils::head(cmnt_hits, 20), collapse = "\n"), "\n")
  fail("Non-ASCII in comments at: ", paste(utils::head(cmnt_hits, 10), collapse = ", "),
       ". Escapes are not interpreted in comments; use ASCII.")
} else {
  cat("  ok   none in comments\n")
}

## ---------------------------------------------------------------------------
## 2. Line endings and byte-order marks.
## ---------------------------------------------------------------------------
section("line endings and BOMs")
crlf <- character(0); boms <- character(0)
for (f in all_src) {
  raw <- readBin(f, "raw", file.size(f))
  if (length(raw) >= 3 && identical(raw[1:3], as.raw(c(0xEF, 0xBB, 0xBF))))
    boms <- c(boms, f)
  if (any(raw == as.raw(0x0D))) crlf <- c(crlf, f)
}
if (length(crlf)) {
  cat("  FAIL CRLF line endings:\n"); cat(paste0("    ", crlf, collapse = "\n"), "\n")
  fail("CRLF line endings in: ", paste(utils::head(crlf, 10), collapse = ", "))
} else cat("  ok   all LF\n")
if (length(boms)) {
  cat("  FAIL byte-order mark:\n"); cat(paste0("    ", boms, collapse = "\n"), "\n")
  fail("UTF-8 BOM in: ", paste(boms, collapse = ", "))
} else cat("  ok   no BOMs\n")

## ---------------------------------------------------------------------------
## 3. Every R source parses. Cheaper than waiting for R CMD check to say so.
## ---------------------------------------------------------------------------
section("R sources parse")
unparsed <- all_src[vapply(all_src, function(f) {
  inherits(try(parse(f), silent = TRUE), "try-error")
}, logical(1))]
if (length(unparsed)) {
  cat("  FAIL parse errors:\n"); cat(paste0("    ", unparsed, collapse = "\n"), "\n")
  fail("Parse errors in: ", paste(unparsed, collapse = ", "))
} else {
  cat("  ok   all", length(all_src), "files parse\n")
}

## ---------------------------------------------------------------------------
## 4. Filenames that break on case-insensitive or restrictive filesystems.
## ---------------------------------------------------------------------------
section("filename portability")
tracked <- system2("git", c("ls-files"), stdout = TRUE)
lower <- tolower(tracked)
clash <- unique(lower[duplicated(lower)])
if (length(clash)) {
  cat("  FAIL names differing only by case:\n")
  cat(paste0("    ", clash, collapse = "\n"), "\n")
  fail("Case-only filename collisions: ", paste(clash, collapse = ", "))
} else cat("  ok   no case-only collisions\n")

oddly <- tracked[grepl("[^A-Za-z0-9._/-]", tracked)]
if (length(oddly)) {
  cat("  WARN unusual characters in paths:\n")
  cat(paste0("    ", utils::head(oddly, 10), collapse = "\n"), "\n")
  cat("::warning::Paths with unusual characters may not survive all filesystems.\n")
} else cat("  ok   plain filenames\n")

## ---------------------------------------------------------------------------
## 5. Placeholder / scratch filenames that should not ship.
## ---------------------------------------------------------------------------
section("no scratch filenames in R/")
# Deliberately narrow. Substrings like "temp" or "bar" match legitimate names
# (utils-tempdir.R, plot_stacked_bar.R), and a warning that cries wolf gets
# ignored -- which is worse than not having it.
scratch_pat <- paste(
  "this_one", "works_?\\d*\\.R$", "untitled", "scratch", "draft",
  "\\basdf\\b", "^copy[_-]", "[_-]copy\\.R$", "^new[_-]", "^old[_-]",
  "[_-]old\\.R$", "[_-]bak\\.R$", "\\bfinal\\d*\\.R$", "^test\\d+\\.R$",
  "^tmp[_-]", "[_-]tmp\\.R$",
  sep = "|"
)
scratchy <- grep(scratch_pat, basename(r_files), ignore.case = TRUE, value = TRUE)
if (length(scratchy)) {
  cat("  WARN placeholder-looking filenames:\n")
  cat(paste0("    R/", scratchy, collapse = "\n"), "\n")
  cat("::warning::These ship inside the installed package under these names.\n")
} else cat("  ok   none\n")

## ---------------------------------------------------------------------------
cat("\n")
if (length(failures)) {
  cat("::error::Portability FAILED\n")
  for (f in failures) cat("  - ", f, "\n", sep = "")
  quit(status = 1L)
}
cat("Portability passed.\n")
