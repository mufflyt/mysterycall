#' Write a reproducibility snapshot at analysis end
#'
#' Records the R session state -- timestamp, R version, loaded package versions,
#' any named seeds used during the analysis, and optional free-text notes -- to a
#' structured plain-text file.  Call this once at the very end of a script to
#' capture everything needed to reproduce the run.
#'
#' Seeds are often buried inside individual functions; this function provides a
#' single top-level call that collects them all in one place.
#'
#' @param file Character scalar.  Output file path.
#'   Default `"session_snapshot.txt"`.
#' @param seeds Named integer vector or `NULL`.  Any seeds used during the
#'   analysis, e.g. `c(bootstrap = 42L, imputation = 123L)`.  Unnamed elements
#'   are labelled `seed_1`, `seed_2`, etc.  Default `NULL`.
#' @param notes Character vector or `NULL`.  Free-text notes appended verbatim
#'   under the `=== NOTES ===` section.  Each element is written on its own
#'   line.  Default `NULL`.
#' @param append Logical scalar.  If `TRUE` *and* `file` already exists,
#'   content is appended rather than overwriting.  Default `FALSE`.
#' @param quiet Logical scalar.  If `FALSE` (default), emits a
#'   [base::message()] reporting the output path on success.
#'
#' @return `invisible(file)` -- the output path -- with S3 class
#'   `"mysterycall_snapshot"`.  When the return value is printed explicitly,
#'   the file path and first 20 lines of the snapshot are displayed.
#'
#' @section Output file structure:
#' ```
#' === REPRODUCIBILITY SNAPSHOT ===
#' Date/Time: <timestamp>
#' R Version: <version>
#' Platform:  <platform>
#'
#' === SEEDS ===
#' <name>: <value>
#'
#' === LOADED PACKAGES ===
#' <pkg>  <version>
#'
#' === FULL SESSION INFO ===
#' <capture.output(sessionInfo())>
#'
#' === NOTES ===
#' <notes>
#' ```
#'
#' @family reporting
#' @export
#'
#' @examples
#' snap <- tempfile(fileext = ".txt")
#'
#' # Basic usage -- seeds and notes
#' mysterycall_session_snapshot(
#'   file  = snap,
#'   seeds = c(bootstrap = 42L, imputation = 123L),
#'   notes = "Primary sensitivity analysis.",
#'   quiet = TRUE
#' )
#'
#' # Inspect what was written
#' out <- mysterycall_session_snapshot(file = snap, append = TRUE, quiet = TRUE)
#' print(out)
mysterycall_session_snapshot <- function(
    file   = "session_snapshot.txt",
    seeds  = NULL,
    notes  = NULL,
    append = FALSE,
    quiet  = FALSE
) {
  # ---- Input validation -------------------------------------------------------
  if (!is.character(file) || length(file) != 1L || !nzchar(file)) {
    stop("`file` must be a non-empty character scalar.", call. = FALSE)
  }
  if (!is.null(seeds)) {
    if (!is.numeric(seeds) && !is.integer(seeds)) {
      stop("`seeds` must be a numeric/integer vector or NULL.", call. = FALSE)
    }
  }
  if (!is.null(notes)) {
    if (!is.character(notes)) {
      stop("`notes` must be a character vector or NULL.", call. = FALSE)
    }
  }
  if (!is.logical(append) || length(append) != 1L || is.na(append)) {
    stop("`append` must be a non-NA logical scalar.", call. = FALSE)
  }
  if (!is.logical(quiet) || length(quiet) != 1L || is.na(quiet)) {
    stop("`quiet` must be a non-NA logical scalar.", call. = FALSE)
  }

  # ---- Collect session information -------------------------------------------
  now <- Sys.time()
  si  <- sessionInfo()

  r_version <- R.version$version.string
  platform  <- R.version$platform

  # ---- Seeds section ---------------------------------------------------------
  if (!is.null(seeds) && length(seeds) > 0L) {
    seed_names <- names(seeds)
    if (is.null(seed_names) || any(!nzchar(seed_names))) {
      seed_names <- ifelse(
        !is.null(names(seeds)) & nzchar(names(seeds)),
        names(seeds),
        paste0("seed_", seq_along(seeds))
      )
    }
    seeds_lines <- vapply(seq_along(seeds), function(i) {
      sprintf("%-30s %d", seed_names[i], as.integer(seeds[i]))
    }, character(1L))
  } else {
    seeds_lines <- "(none supplied)"
  }

  # ---- Loaded packages section -----------------------------------------------
  other_pkgs <- si$otherPkgs
  if (is.null(other_pkgs) || length(other_pkgs) == 0L) {
    pkg_lines <- "(no non-base packages loaded)"
  } else {
    pkg_names <- sort(names(other_pkgs))
    pkg_lines <- vapply(pkg_names, function(p) {
      v <- tryCatch(
        as.character(other_pkgs[[p]]$Version),
        error = function(e) "unknown"
      )
      sprintf("%-30s %s", p, v)
    }, character(1L))
  }

  # ---- Full sessionInfo() output ---------------------------------------------
  si_lines <- utils::capture.output(sessionInfo())

  # ---- Notes section ---------------------------------------------------------
  notes_lines <- if (!is.null(notes) && length(notes) > 0L && any(nzchar(notes))) {
    notes
  } else {
    "(none)"
  }

  # ---- Assemble output -------------------------------------------------------
  sep <- strrep("=", 60)
  lines <- c(
    sep,
    "=== REPRODUCIBILITY SNAPSHOT ===",
    sep,
    sprintf("Date/Time: %s", format(now, "%Y-%m-%d %H:%M:%S %Z")),
    sprintf("R Version: %s", r_version),
    sprintf("Platform:  %s", platform),
    "",
    "=== SEEDS ===",
    seeds_lines,
    "",
    "=== LOADED PACKAGES ===",
    pkg_lines,
    "",
    "=== FULL SESSION INFO ===",
    si_lines,
    "",
    "=== NOTES ===",
    notes_lines,
    ""
  )

  # ---- Write file ------------------------------------------------------------
  parent_dir <- dirname(file)
  if (!identical(parent_dir, ".") && !dir.exists(parent_dir)) {
    dir.create(parent_dir, showWarnings = FALSE, recursive = TRUE)
  }

  con <- file(file, open = if (isTRUE(append) && file.exists(file)) "at" else "wt")
  on.exit(close(con), add = TRUE)
  writeLines(lines, con = con)

  # ---- Report ----------------------------------------------------------------
  if (!quiet) {
    message("Session snapshot written to: ", file)
  }

  invisible(structure(file, class = "mysterycall_snapshot"))
}


#' Print a mysterycall_snapshot object
#'
#' Shows the output file path and the first 20 lines of the snapshot.
#'
#' @param x A `mysterycall_snapshot` object returned by
#'   [mysterycall_session_snapshot()].
#' @param n Integer scalar.  Number of lines to preview.  Default `20L`.
#' @param ... Currently unused; present for S3 method compatibility.
#'
#' @return `invisible(x)`.
#' @family reporting
#' @export
#'
#' @examples
#' snap <- tempfile(fileext = ".txt")
#' out  <- mysterycall_session_snapshot(file = snap, quiet = TRUE)
#' print(out)
print.mysterycall_snapshot <- function(x, n = 20L, ...) {
  cat(sprintf("Session snapshot: %s\n", x))
  if (!file.exists(x)) {
    cat("(file not found)\n")
    return(invisible(x))
  }
  preview <- readLines(x, n = n, warn = FALSE)
  cat(paste(preview, collapse = "\n"), "\n", sep = "")
  total <- length(readLines(x, warn = FALSE))
  if (total > n) {
    cat(sprintf("... (%d more lines not shown)\n", total - n))
  }
  invisible(x)
}
