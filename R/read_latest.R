#' Read (or locate) the most recent file matching a pattern - loudly
#'
#' Mystery-caller pipelines routinely re-export the same REDCap instrument or
#' roster many times, leaving a directory full of dated files. The common
#' `latest()` idiom - "glob a folder, pick the newest, read it" - is a quiet
#' footgun: it returns `NA` (or nothing) when no file matches, never announces
#' *which* file it chose, and silently reads a stale export when a fresh one
#' failed to land. A wrong file then flows all the way to the results with no
#' warning.
#'
#' `mysterycall_read_latest()` is the loud replacement. It:
#' \itemize{
#'   \item **errors** (never returns `NA`) when zero files match, printing the
#'     directory and pattern that came up empty;
#'   \item **announces** the chosen file and its modification time, plus how
#'     many candidates it beat, so the selection is visible in the log;
#'   \item **warns on staleness** when the newest match is older than
#'     `max_age_days`, catching the "today's export never wrote" case;
#'   \item **warns on ties** when two files share the newest modification time,
#'     because "the newest" is then ambiguous.
#' }
#'
#' By default it reads the file via [mysterycall_read_table()] (CSV or Parquet)
#' and returns the data frame with the resolved path stored in the `"path"`
#' attribute. Set `read = FALSE` to return just the path - a drop-in for the
#' bare `latest()` calls that only needed a filename.
#'
#' @param dir Character scalar. Directory to search. Must exist.
#' @param pattern Character scalar or `NULL`. Regular expression matched against
#'   file names (as in [list.files()]). `NULL` (default) matches every file.
#'   To match a literal string containing regex metacharacters, wrap it in
#'   [fixed()]-style escaping yourself or pass an anchored pattern such as
#'   `"^redcap_export_.*\\.csv$"`.
#' @param format Optional character scalar passed to [mysterycall_read_table()]:
#'   `"csv"` or `"parquet"`. When `NULL` (default) the format is inferred from
#'   the chosen file's extension. Ignored when `read = FALSE`.
#' @param read Logical. When `TRUE` (default) the chosen file is read and its
#'   contents returned. When `FALSE` only the resolved file path (character
#'   scalar) is returned.
#' @param max_age_days Positive number or `NULL`. When supplied, a warning is
#'   emitted if the newest matching file is more than `max_age_days` days old.
#'   Default `NULL` (no staleness check).
#' @param recursive Logical. When `TRUE`, search `dir` recursively. Default
#'   `FALSE`.
#' @param ignore_case Logical. When `TRUE`, `pattern` matching is
#'   case-insensitive. Default `FALSE`.
#' @param quiet Logical. When `TRUE`, suppress the "chose <file>" announcement
#'   message. Warnings and errors are still raised. Default `FALSE`.
#' @param ... Additional arguments forwarded to [mysterycall_read_table()] when
#'   `read = TRUE`.
#'
#' @return When `read = TRUE`, a data frame (tibble) with the resolved absolute
#'   path attached as the `"path"` attribute. When `read = FALSE`, the resolved
#'   file path as a character scalar.
#'
#' @section Migrating from `latest()`:
#' ```r
#' # Before - silent, returns NA when nothing matches:
#' f  <- latest("data/redcap", "\\.csv$")
#' df <- read.csv(f)
#'
#' # After - announces its choice, errors instead of returning NA,
#' # warns if the newest export is more than a day old:
#' df <- mysterycall_read_latest("data/redcap", "\\.csv$", max_age_days = 1)
#' path <- attr(df, "path")   # which file it actually read
#' ```
#'
#' @seealso [mysterycall_read_table()] for the underlying reader;
#'   [mysterycall_resolve_path()] for constructing standard paths.
#' @family utilities
#' @export
#'
#' @examples
#' # Set up a directory with two dated exports
#' dir <- tempfile("redcap_")
#' dir.create(dir)
#' old_file <- file.path(dir, "export_2026-07-01.csv")
#' new_file <- file.path(dir, "export_2026-07-20.csv")
#' utils::write.csv(data.frame(x = 1), old_file, row.names = FALSE)
#' utils::write.csv(data.frame(x = 2), new_file, row.names = FALSE)
#' # Make the second file unambiguously newer
#' Sys.setFileTime(old_file, Sys.time() - 3600)
#'
#' # Return just the path to the newest match
#' mysterycall_read_latest(dir, "\\.csv$", read = FALSE)
mysterycall_read_latest <- function(dir,
                                    pattern      = NULL,
                                    format       = NULL,
                                    read         = TRUE,
                                    max_age_days = NULL,
                                    recursive    = FALSE,
                                    ignore_case  = FALSE,
                                    quiet        = FALSE,
                                    ...) {

  # ---- input validation -------------------------------------------------------
  checkmate::assert_string(dir, min.chars = 1L, .var.name = "dir")
  checkmate::assert_string(pattern, null.ok = TRUE, .var.name = "pattern")
  checkmate::assert_string(format, null.ok = TRUE, .var.name = "format")
  checkmate::assert_flag(read, .var.name = "read")
  checkmate::assert_flag(recursive, .var.name = "recursive")
  checkmate::assert_flag(ignore_case, .var.name = "ignore_case")
  checkmate::assert_flag(quiet, .var.name = "quiet")
  if (!is.null(max_age_days)) {
    checkmate::assert_number(max_age_days, lower = 0, finite = TRUE,
                             na.ok = FALSE, .var.name = "max_age_days")
  }

  if (!dir.exists(dir)) {
    stop(sprintf("`dir` does not exist or is not a directory: '%s'", dir),
         call. = FALSE)
  }

  # ---- collect candidates -----------------------------------------------------
  candidates <- list.files(
    path         = dir,
    pattern      = pattern,
    full.names   = TRUE,
    recursive    = recursive,
    ignore.case  = ignore_case,
    no..         = TRUE
  )

  # Drop directories; keep regular files only.
  if (length(candidates)) {
    info       <- file.info(candidates)
    candidates <- candidates[!info$isdir %in% TRUE]
  }

  if (!length(candidates)) {
    stop(sprintf(
      paste0(
        "No files match in '%s'%s.\n",
        "  mysterycall_read_latest() refuses to return NA on an empty match ",
        "(the stale/missing-file footgun). Check the directory and pattern."
      ),
      dir,
      if (is.null(pattern)) "" else sprintf(" (pattern '%s')", pattern)
    ), call. = FALSE)
  }

  # ---- pick the newest by modification time -----------------------------------
  info  <- file.info(candidates)
  mtime <- info$mtime
  winner_idx <- which.max(mtime)
  path       <- normalizePath(candidates[[winner_idx]], mustWork = FALSE)
  chosen_mtime <- mtime[[winner_idx]]

  # Tie detection: more than one file at the newest modification time.
  n_tied <- sum(mtime == chosen_mtime, na.rm = TRUE)
  if (n_tied > 1L) {
    tied_files <- basename(candidates[mtime == chosen_mtime & !is.na(mtime)])
    warning(sprintf(
      paste0(
        "mysterycall_read_latest: %d files share the newest modification time; ",
        "'%s' was chosen by list order and may not be the intended file. ",
        "Tied files: %s"
      ),
      n_tied, basename(path), paste(tied_files, collapse = ", ")
    ), call. = FALSE)
  }

  # ---- staleness check --------------------------------------------------------
  age_days <- as.numeric(difftime(Sys.time(), chosen_mtime, units = "days"))
  if (!is.null(max_age_days) && !is.na(age_days) && age_days > max_age_days) {
    warning(sprintf(
      paste0(
        "mysterycall_read_latest: newest match '%s' is %.1f days old ",
        "(> max_age_days = %g). Today's export may not have written."
      ),
      basename(path), age_days, max_age_days
    ), call. = FALSE)
  }

  # ---- announce ---------------------------------------------------------------
  if (!quiet) {
    message(sprintf(
      "mysterycall_read_latest: chose '%s' (modified %s, %.1f days ago); beat %d other candidate(s).",
      basename(path),
      format(chosen_mtime, "%Y-%m-%d %H:%M"),
      age_days,
      length(candidates) - 1L
    ))
  }

  # ---- return path or contents ------------------------------------------------
  if (!read) {
    return(path)
  }

  out <- mysterycall_read_table(path, format = format, ...)
  attr(out, "path") <- path
  out
}
