#' Safe join wrappers with coverage validation
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name join_safety
NULL

# -- Internal helpers ----------------------------------------------------------

#' Safe Division
#'
#' Avoids division-by-zero; returns `default` when denominator is 0 or NA.
#'
#' @param numerator Numeric vector.
#' @param denominator Numeric vector.
#' @param default Numeric scalar to return if denominator is 0 or NA.
#'
#' @return Numeric vector.
#' @keywords internal
.safe_divide <- function(numerator, denominator, default = NA_real_) {
  if (is.na(denominator) || denominator == 0) default else numerator / denominator
}

#' Resolve Join Keys
#'
#' Resolves `by` to a list(left = char, right = char) for both named and
#' unnamed character vectors and dplyr::join_by() objects.
#'
#' @param by Character vector or dplyr::join_by object.
#'
#' @return A named list with "left" and "right" character vectors.
#' @keywords internal
.resolve_by <- function(by) {
  if (inherits(by, "dplyr_join_by")) {
    return(list(left = by$x, right = by$y))
  }
  if (is.null(names(by)) || !any(nzchar(names(by)))) {
    return(list(left = unname(by), right = unname(by)))
  }
  left_cols  <- names(by)
  right_cols <- unname(by)
  unnamed    <- !nzchar(left_cols)
  left_cols[unnamed]  <- right_cols[unnamed]
  list(left = left_cols, right = right_cols)
}

#' Format Join Keys for Messages
#'
#' Formats `by` as a human-readable string for messages.
#'
#' @param by Character vector or dplyr::join_by object.
#'
#' @return Character scalar.
#' @keywords internal
.format_by <- function(by) {
  if (is.null(by) || (is.character(by) && length(by) == 0L)) return("<none specified>")
  cols <- .resolve_by(by)
  parts <- vapply(seq_along(cols$left), function(i) {
    if (cols$left[[i]] == cols$right[[i]]) cols$left[[i]]
    else paste0(cols$left[[i]], "=", cols$right[[i]])
  }, character(1L))
  paste(parts, collapse = ", ")
}

#' Harmonize Key Column Types
#'
#' Coerces mismatched key column types to character on both sides to prevent
#' silent 0-match joins after RDS/Parquet round-trips (e.g. integer -> double).
#'
#' @param left Data frame.
#' @param right Data frame.
#' @param by Join keys.
#' @param label_left Label for left table.
#' @param label_right Label for right table.
#'
#' @return A named list with "left" and "right" data frames.
#' @keywords internal
.harmonize_key_types <- function(left, right, by,
                                  label_left = "left", label_right = "right") {
  cols <- .resolve_by(by)
  for (i in seq_along(cols$left)) {
    lc <- cols$left[[i]];  rc <- cols$right[[i]]
    if (!lc %in% names(left) || !rc %in% names(right)) next
    l_cls <- class(left[[lc]])[[1L]];  r_cls <- class(right[[rc]])[[1L]]
    if (l_cls != r_cls) {
      message(sprintf(
        "[safe_join] key type mismatch: %s$%s (%s) vs %s$%s (%s) -- coercing both to character",
        label_left, lc, l_cls, label_right, rc, r_cls
      ))
      left[[lc]]  <- as.character(left[[lc]])
      right[[rc]] <- as.character(right[[rc]])
    }
  }
  list(left = left, right = right)
}

#' Write Join Audit Report
#'
#' Writes a one-row CSV audit record; atomic (write to .tmp, then rename).
#'
#' @param metrics Data frame with join metrics.
#' @param report_prefix Character scalar for filename.
#'
#' @return `invisible(NULL)`.
#' @keywords internal
.write_join_report <- function(metrics, report_prefix) {
  report_dir <- Sys.getenv("JOIN_REPORT_DIR", unset = "")
  if (!nzchar(report_dir)) {
    report_dir <- getOption("mysterycall.join_report_dir", tempdir())
  }
  dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
  ts   <- format(Sys.time(), "%Y%m%d_%H%M%OS3")
  path <- file.path(report_dir, sprintf("%s_%s.csv", report_prefix, ts))
  tmp  <- paste0(path, ".tmp")
  utils::write.csv(metrics, tmp, row.names = FALSE, na = "")
  file.rename(tmp, path)
  message("Join report: ", path)
}

#' Enforce Join Coverage Thresholds
#'
#' Enforces coverage >= min_coverage and output rows <= left_n (no fan-out).
#'
#' @param left_n Number of rows in left table.
#' @param matched_n Number of rows that found a match.
#' @param label_left Label for left table.
#' @param label_right Label for right table.
#' @param min_coverage Minimum allowed coverage (0-1).
#' @param by Join keys.
#'
#' @return `invisible(TRUE)` on success; stops on failure.
#' @keywords internal
.check_coverage <- function(left_n, matched_n, label_left, label_right,
                             min_coverage, by) {
  if (left_n == 0L) {
    message(sprintf("Join coverage: %s has 0 rows", label_left))
    return(invisible(TRUE))
  }
  cov <- .safe_divide(matched_n, left_n)
  message(sprintf("Join coverage: %s %s/%s matched (%.1f%%)",
                  label_left, format(matched_n, big.mark = ","),
                  format(left_n, big.mark = ","), cov * 100))
  if (!is.na(cov) && cov > 1.0) {
    stop(sprintf(
      "Join produced more rows than input (%.1f%% > 100%%) -- duplicate keys in right table. %s -> %s on %s.",
      cov * 100, label_left, label_right, .format_by(by)
    ), call. = FALSE)
  }
  if (!is.na(cov) && cov < min_coverage) {
    stop(sprintf(
      "Join coverage %.1f%% below %.1f%% threshold -- lost %s rows. %s -> %s on %s.",
      cov * 100, min_coverage * 100,
      format(left_n - matched_n, big.mark = ","),
      label_left, label_right, .format_by(by)
    ), call. = FALSE)
  }
  invisible(TRUE)
}

# -- Public API ----------------------------------------------------------------

#' Assert that join key columns are unique
#'
#' Checks that the specified key columns form a unique key in `.data`.
#' When duplicates are found, either errors with sample duplicate values or
#' silently deduplicates (keeping the first row per key), depending on
#' `dedupe`.
#'
#' @param .data A data frame to check.
#' @param key_cols Character vector of column names that together form the key.
#' @param label Character scalar used in error/message text. Default `"table"`.
#' @param dedupe Logical. When `TRUE` duplicates are silently removed (first
#'   row per key is kept) and the deduplicated data frame is returned
#'   invisibly.  When `FALSE` (default) any duplicates raise an error with
#'   sample duplicate values to help locate the problem.
#'
#' @return `.data` invisibly (possibly deduplicated). Errors when duplicates
#'   exist and `dedupe = FALSE`.
#'
#' @examples
#' df <- data.frame(npi = c("A", "B", "A"), value = 1:3)
#'
#' # Deduplicate silently
#' clean <- mysterycall_assert_unique_keys(df, "npi", dedupe = TRUE)
#' nrow(clean)  # 2
#'
#' @family safe-joins
#' @importFrom dplyr count across all_of filter distinct
#' @export
mysterycall_assert_unique_keys <- function(.data, key_cols,
                                           label  = "table",
                                           dedupe = FALSE) {
  if (!is.data.frame(.data)) stop("`.data` must be a data frame.", call. = FALSE)
  if (!is.character(key_cols) || length(key_cols) == 0L)
    stop("`key_cols` must be a non-empty character vector.", call. = FALSE)
  missing_cols <- setdiff(key_cols, names(.data))
  if (length(missing_cols))
    stop(sprintf("Key column(s) not found in `%s`: %s",
                 label, paste(missing_cols, collapse = ", ")), call. = FALSE)

  n    <- nrow(.data)
  dups <- .data |>
    dplyr::count(dplyr::across(dplyr::all_of(key_cols)), name = ".n") |>
    dplyr::filter(.n > 1L)

  if (!nrow(dups)) return(invisible(.data))

  if (dedupe) {
    out <- dplyr::distinct(.data, dplyr::across(dplyr::all_of(key_cols)), .keep_all = TRUE)
    message(sprintf("assert_unique_keys: removed %d duplicate row(s) from %s",
                    n - nrow(out), label))
    return(out)
  }

  total_dup_rows <- sum(dups$.n)
  sample_str <- apply(head(dups[key_cols], 3L), 1L, function(r) {
    paste(key_cols, "=", r, collapse = ", ")
  })
  stop(sprintf(
    "%s: expected unique key(s) [%s] but found %d duplicate group(s) affecting %d row(s). Samples: %s",
    label, paste(key_cols, collapse = ", "), nrow(dups), total_dup_rows,
    paste(sample_str, collapse = "; ")
  ), call. = FALSE)
}

#' Safe left join with coverage validation
#'
#' Wraps [dplyr::left_join()] with:
#' \itemize{
#'   \item Key-type harmonization (prevents silent 0-match joins after type
#'     coercion from RDS or Parquet round-trips).
#'   \item Right-side uniqueness assertion (blocks accidental many-to-many
#'     fan-outs).
#'   \item Coverage threshold enforcement -- stops if fewer than
#'     `min_coverage` of left rows find a match.
#'   \item Optional CSV audit report written to `JOIN_REPORT_DIR` env var or
#'     `getOption("mysterycall.join_report_dir", tempdir())`.
#' }
#'
#' Coverage defaults and env-var overrides:
#' \itemize{
#'   \item `min_coverage` default `0.98`; override with `JOIN_MIN_COVERAGE`.
#'   \item `max_duplication` default `1.02`; override with `JOIN_MAX_DUPLICATION`.
#' }
#'
#' @param left A data frame. All rows are preserved.
#' @param right A data frame. The lookup / enrichment table.
#' @param by Character vector or [dplyr::join_by()] specifying join keys.
#'   Required; use named vector for cross-column mapping
#'   (`c("npi" = "provider_npi")`).
#' @param expect_unique_right Logical. When `TRUE` (default) right-side keys
#'   must be unique; stops if duplicates are detected.
#' @param label_left,label_right Character scalars used in messages and
#'   the audit report.
#' @param min_coverage Numeric in `[0, 1]`. Minimum fraction of left rows that
#'   must find a match. Default `0.98` (reads `JOIN_MIN_COVERAGE` env var).
#' @param max_duplication Numeric >= 0. Maximum allowed output/input row ratio.
#'   Default `1.02` (reads `JOIN_MAX_DUPLICATION` env var).
#' @param suffix Character vector of length 2. Suffixes for conflicting column
#'   names. Default `c(".x", ".y")`.
#' @param write_report Logical. Write a one-row CSV audit record. Default
#'   `FALSE`.
#' @param report_prefix Character scalar. Filename prefix for the audit CSV.
#'
#' @return A data frame containing all rows of `left` joined to matching rows
#'   of `right`. Columns from both tables are included; name conflicts gain the
#'   `suffix` extensions. Stops with an informative error when: `left` or
#'   `right` is not a data frame; `by` columns are absent; coverage falls below
#'   `min_coverage`; or output rows exceed `max_duplication` times input rows.
#'   When `write_report = TRUE`, a one-row CSV audit record is written to the
#'   working directory using `report_prefix` as the filename stem.
#'
#' @examples
#' physicians <- data.frame(
#'   npi       = c("1", "2", "3"),
#'   specialty = c("OB", "GYN", "RE"),
#'   stringsAsFactors = FALSE
#' )
#' demographics <- data.frame(
#'   npi  = c("1", "2"),
#'   state = c("CO", "TX"),
#'   stringsAsFactors = FALSE
#' )
#'
#' result <- mysterycall_safe_left_join(
#'   left         = physicians,
#'   right        = demographics,
#'   by           = "npi",
#'   label_left   = "physicians",
#'   label_right  = "demographics",
#'   min_coverage = 0.50,
#'   write_report = FALSE
#' )
#'
#' @seealso [mysterycall_safe_inner_join()], [mysterycall_safe_semi_join()],
#'   [mysterycall_safe_anti_join()], [mysterycall_assert_unique_keys()]
#' @family safe-joins
#' @importFrom dplyr left_join anti_join
#' @importFrom tibble tibble
#' @importFrom readr write_csv
#' @export
mysterycall_safe_left_join <- function(left, right, by,
                                       expect_unique_right = TRUE,
                                       label_left    = "left",
                                       label_right   = "right",
                                       min_coverage  = NULL,
                                       max_duplication = NULL,
                                       suffix        = c(".x", ".y"),
                                       write_report  = FALSE,
                                       report_prefix = "join_left") {
  if (!is.data.frame(left))  stop("`left` must be a data frame.",  call. = FALSE)
  if (!is.data.frame(right)) stop("`right` must be a data frame.", call. = FALSE)
  if (is.null(by) || (is.character(by) && !length(by)))
    stop("`by` is required. Specify join column(s) or use dplyr::join_by().", call. = FALSE)
  if (!is.character(label_left)  || length(label_left)  != 1L) stop("`label_left` must be a string.",  call. = FALSE)
  if (!is.character(label_right) || length(label_right) != 1L) stop("`label_right` must be a string.", call. = FALSE)
  if (!is.character(suffix) || length(suffix) != 2L) stop("`suffix` must be a character vector of length 2.", call. = FALSE)

  # Resolve min_coverage and max_duplication (parameter > env var > default).
  # When expect_unique_right = FALSE the caller has acknowledged duplicates, so
  # max_duplication defaults to Inf (disabled) unless explicitly supplied.
  min_coverage <- .resolve_coverage_param(min_coverage, "JOIN_MIN_COVERAGE", 0.98)
  dup_default <- if (isTRUE(expect_unique_right)) 1.02 else Inf
  max_duplication <- .resolve_dup_param(max_duplication, "JOIN_MAX_DUPLICATION", dup_default)

  # Harmonize key types to prevent silent 0-match joins.
  h     <- .harmonize_key_types(left, right, by, label_left, label_right)
  left  <- h$left;  right <- h$right

  # Assert right-side uniqueness.
  if (expect_unique_right) {
    right_cols <- .resolve_by(by)$right
    mysterycall_assert_unique_keys(right, right_cols,
                                   label = paste(label_right, "(right)"))
  }

  left_n      <- nrow(left)
  unmatched_n <- nrow(dplyr::anti_join(left, right, by = by, na_matches = "never"))
  matched_n   <- left_n - unmatched_n

  out <- dplyr::left_join(left, right, by = by, suffix = suffix,
                          relationship = if (expect_unique_right) "many-to-one" else NULL,
                          na_matches = "never")

  .check_coverage(left_n, matched_n, label_left, label_right, min_coverage, by)

  dup_factor <- .safe_divide(nrow(out), left_n, default = 0)
  if (left_n > 0L && dup_factor > max_duplication) {
    stop(sprintf(
      "Left join row duplication %.2fx exceeds max_duplication=%.2f. Output %d rows from %d input. %s -> %s.",
      dup_factor, max_duplication, nrow(out), left_n, label_left, label_right
    ), call. = FALSE)
  }

  if (write_report) {
    .write_join_report(tibble::tibble(
      join_type    = "left",   label_left = label_left, label_right = label_right,
      left_rows    = left_n,   matched_rows = matched_n, output_rows = nrow(out),
      coverage     = .safe_divide(matched_n, left_n),
      unmatched_rows = unmatched_n, by_columns = .format_by(by)
    ), report_prefix)
  }

  out
}

#' Safe inner join with cardinality checking
#'
#' Wraps [dplyr::inner_join()] with key-type harmonization, optional
#' uniqueness assertion on both tables, coverage enforcement, and an optional
#' CSV audit record.
#'
#' Coverage is measured as `nrow(semi_join(left, right)) / nrow(left)` to
#' avoid double-counting from many-to-many multiplication.
#'
#' @inheritParams mysterycall_safe_left_join
#' @param expect_unique_both Logical. When `TRUE` (default) keys must be
#'   unique on **both** sides.
#' @param min_coverage Numeric in `[0, 1]`. Default `0.90`.
#'
#' @return A data frame: the inner-join result.
#'
#' @examples
#' physicians <- data.frame(npi = c("1", "2", "3"), specialty = c("OB", "GYN", "RE"),
#'                          stringsAsFactors = FALSE)
#' claims     <- data.frame(npi = c("1", "2"), year = c(2020L, 2020L),
#'                          stringsAsFactors = FALSE)
#'
#' result <- mysterycall_safe_inner_join(
#'   left         = physicians,
#'   right        = claims,
#'   by           = "npi",
#'   label_left   = "physicians",
#'   label_right  = "claims",
#'   min_coverage = 0.50,
#'   write_report = FALSE
#' )
#'
#' @seealso [mysterycall_safe_left_join()], [mysterycall_safe_semi_join()],
#'   [mysterycall_safe_anti_join()], [mysterycall_assert_unique_keys()]
#' @family safe-joins
#' @importFrom dplyr inner_join semi_join
#' @importFrom tibble tibble
#' @importFrom readr write_csv
#' @export
mysterycall_safe_inner_join <- function(left, right, by,
                                        expect_unique_both = TRUE,
                                        label_left    = "left",
                                        label_right   = "right",
                                        min_coverage  = NULL,
                                        max_duplication = NULL,
                                        suffix        = c(".x", ".y"),
                                        write_report  = FALSE,
                                        report_prefix = "join_inner") {
  if (!is.data.frame(left))  stop("`left` must be a data frame.",  call. = FALSE)
  if (!is.data.frame(right)) stop("`right` must be a data frame.", call. = FALSE)
  if (is.null(by) || (is.character(by) && !length(by)))
    stop("`by` is required.", call. = FALSE)
  if (!is.character(label_left)  || length(label_left)  != 1L) stop("`label_left` must be a string.",  call. = FALSE)
  if (!is.character(label_right) || length(label_right) != 1L) stop("`label_right` must be a string.", call. = FALSE)

  # Validate that key columns exist before anything else.
  cols <- .resolve_by(by)
  .assert_cols_exist(left,  cols$left,  label_left,  "left")
  .assert_cols_exist(right, cols$right, label_right, "right")

  min_coverage    <- .resolve_coverage_param(min_coverage,    "JOIN_MIN_COVERAGE",    0.90)
  max_duplication <- .resolve_dup_param(max_duplication, "JOIN_MAX_DUPLICATION", NULL)

  h     <- .harmonize_key_types(left, right, by, label_left, label_right)
  left  <- h$left;  right <- h$right

  if (!nrow(left))  warning(sprintf("`%s` has 0 rows -- inner join result will be empty.", label_left),  call. = FALSE)
  if (!nrow(right)) warning(sprintf("`%s` has 0 rows -- inner join result will be empty.", label_right), call. = FALSE)

  if (expect_unique_both) {
    mysterycall_assert_unique_keys(left,  cols$left,  label = paste(label_left,  "(left)"))
    mysterycall_assert_unique_keys(right, cols$right, label = paste(label_right, "(right)"))
  }

  left_n <- nrow(left)
  out    <- dplyr::inner_join(left, right, by = by, suffix = suffix,
                              na_matches = "never",
                              relationship = if (expect_unique_both) "one-to-one" else NULL)

  matched_n <- nrow(dplyr::semi_join(left, right, by = by, na_matches = "never"))
  .check_coverage(left_n, matched_n, label_left, label_right, min_coverage, by)

  if (!is.null(max_duplication) && left_n > 0L) {
    dup_factor <- .safe_divide(nrow(out), left_n, default = 0)
    if (dup_factor > max_duplication) {
      stop(sprintf(
        "Inner join row duplication %.2fx exceeds max_duplication=%.2f. %s -> %s.",
        dup_factor, max_duplication, label_left, label_right
      ), call. = FALSE)
    }
  }

  if (write_report) {
    .write_join_report(tibble::tibble(
      join_type  = "inner",  label_left = label_left,  label_right = label_right,
      left_rows  = left_n,   matched_rows = matched_n, output_rows = nrow(out),
      coverage   = .safe_divide(matched_n, left_n),    by_columns  = .format_by(by)
    ), report_prefix)
  }

  out
}

#' Safe semi join with keep-rate enforcement
#'
#' Wraps [dplyr::semi_join()] (filter left to matching rows, no right columns
#' added) with key validation, type harmonization, and a minimum keep-rate
#' threshold.
#'
#' Default `min_coverage = 0.50` intentionally differs from `safe_left_join`
#' (0.98) because semi joins are often used for intentional subsetting.
#'
#' @inheritParams mysterycall_safe_left_join
#' @param min_coverage Numeric in `[0, 1]`. Default `0.50`.
#'
#' @return A data frame: the filtered subset of `left`.
#'
#' @examples
#' physicians    <- data.frame(npi = c("1","2","3","4"), stringsAsFactors = FALSE)
#' has_isochrone <- data.frame(npi = c("1","3"),         stringsAsFactors = FALSE)
#'
#' result <- mysterycall_safe_semi_join(
#'   left         = physicians,
#'   right        = has_isochrone,
#'   by           = "npi",
#'   min_coverage = 0.25,
#'   write_report = FALSE
#' )
#'
#' @seealso [mysterycall_safe_left_join()], [mysterycall_safe_inner_join()],
#'   [mysterycall_safe_anti_join()], [mysterycall_assert_unique_keys()]
#' @family safe-joins
#' @importFrom dplyr semi_join
#' @importFrom tibble tibble
#' @importFrom readr write_csv
#' @export
mysterycall_safe_semi_join <- function(left, right, by,
                                       label_left    = "left",
                                       label_right   = "right",
                                       min_coverage  = NULL,
                                       write_report  = FALSE,
                                       report_prefix = "join_semi") {
  if (!is.data.frame(left))  stop("`left` must be a data frame.",  call. = FALSE)
  if (!is.data.frame(right)) stop("`right` must be a data frame.", call. = FALSE)
  if (is.null(by) || (is.character(by) && !length(by)))
    stop("`by` is required.", call. = FALSE)

  cols <- .resolve_by(by)
  .assert_cols_exist(left,  cols$left,  label_left,  "left")
  .assert_cols_exist(right, cols$right, label_right, "right")

  min_coverage <- .resolve_coverage_param(min_coverage, "JOIN_MIN_COVERAGE", 0.50)

  h     <- .harmonize_key_types(left, right, by, label_left, label_right)
  left  <- h$left;  right <- h$right

  if (!nrow(left))  warning("Semi join: left table has 0 rows.",  call. = FALSE)
  if (!nrow(right)) warning("Semi join: right table has 0 rows.", call. = FALSE)

  left_n <- nrow(left)
  out    <- dplyr::semi_join(left, right, by = by, na_matches = "never")

  if (left_n > 0L) {
    cov <- .safe_divide(nrow(out), left_n)
    message(sprintf("Semi join: %s kept %s/%s (%.1f%%)",
                    label_left, format(nrow(out), big.mark = ","),
                    format(left_n, big.mark = ","), cov * 100))
    if (!is.na(cov) && cov < min_coverage) {
      stop(sprintf(
        "Semi join kept %.1f%% of %s rows -- below %.1f%% threshold. %s -> %s on %s.",
        cov * 100, format(left_n, big.mark = ","), min_coverage * 100,
        label_left, label_right, .format_by(by)
      ), call. = FALSE)
    }
  }

  if (write_report) {
    .write_join_report(tibble::tibble(
      join_type  = "semi",  label_left = label_left,  label_right = label_right,
      left_rows  = left_n,  matched_rows = nrow(out),  output_rows = nrow(out),
      coverage   = .safe_divide(nrow(out), left_n),    by_columns  = .format_by(by)
    ), report_prefix)
  }

  out
}

#' Safe anti join with over-exclusion guard
#'
#' Wraps [dplyr::anti_join()] (return left rows with **no** match in right)
#' with key validation, type harmonization, and an optional cap on how many
#' rows may be matched away.
#'
#' `max_matched` is the maximum fraction of left rows that may be excluded.
#' Default `1.0` (no limit); reads `JOIN_MAX_MATCHED` env var.
#'
#' @inheritParams mysterycall_safe_left_join
#' @param max_matched Numeric in `[0, 1]`. Maximum fraction of left rows that
#'   may be matched (and thus excluded). Default `NULL` -> reads
#'   `JOIN_MAX_MATCHED` env var or `1.0`.
#'
#' @return A data frame: the unmatched subset of `left`.
#'
#' @examples
#' all_physicians <- data.frame(npi = c("1","2","3","4"), stringsAsFactors = FALSE)
#' retired        <- data.frame(npi = c("2","4"),         stringsAsFactors = FALSE)
#'
#' active <- mysterycall_safe_anti_join(
#'   left         = all_physicians,
#'   right        = retired,
#'   by           = "npi",
#'   label_left   = "all_physicians",
#'   label_right  = "retired_list",
#'   max_matched  = 0.60,
#'   write_report = FALSE
#' )
#'
#' @seealso [mysterycall_safe_left_join()], [mysterycall_safe_inner_join()],
#'   [mysterycall_safe_semi_join()], [mysterycall_assert_unique_keys()]
#' @family safe-joins
#' @importFrom dplyr anti_join
#' @importFrom tibble tibble
#' @importFrom readr write_csv
#' @export
mysterycall_safe_anti_join <- function(left, right, by,
                                       label_left    = "left",
                                       label_right   = "right",
                                       max_matched   = NULL,
                                       write_report  = FALSE,
                                       report_prefix = "join_anti") {
  if (!is.data.frame(left))  stop("`left` must be a data frame.",  call. = FALSE)
  if (!is.data.frame(right)) stop("`right` must be a data frame.", call. = FALSE)
  if (is.null(by) || (is.character(by) && !length(by)))
    stop("`by` is required.", call. = FALSE)

  cols <- .resolve_by(by)
  .assert_cols_exist(left,  cols$left,  label_left,  "left")
  .assert_cols_exist(right, cols$right, label_right, "right")

  if (is.null(max_matched)) {
    env_mm    <- Sys.getenv("JOIN_MAX_MATCHED", unset = "")
    max_matched <- if (nzchar(env_mm)) suppressWarnings(as.numeric(env_mm)) else 1.0
    if (is.na(max_matched)) {
      warning(sprintf("Invalid JOIN_MAX_MATCHED value '%s'; using 1.0.", env_mm), call. = FALSE)
      max_matched <- 1.0
    }
  }
  if (!is.numeric(max_matched) || length(max_matched) != 1L ||
      is.na(max_matched) || max_matched < 0 || max_matched > 1) {
    stop("`max_matched` must be a single number in [0, 1].", call. = FALSE)
  }

  h     <- .harmonize_key_types(left, right, by, label_left, label_right)
  left  <- h$left;  right <- h$right

  if (!nrow(left))  warning("Anti join: left table has 0 rows.",  call. = FALSE)
  if (!nrow(right)) warning("Anti join: right table has 0 rows.", call. = FALSE)

  left_n <- nrow(left)
  out    <- dplyr::anti_join(left, right, by = by, na_matches = "never")

  if (left_n > 0L) {
    excluded_n   <- left_n - nrow(out)
    matched_rate <- .safe_divide(excluded_n, left_n)
    message(sprintf("Anti join: %s kept %s/%s (excluded %.1f%%)",
                    label_left, format(nrow(out), big.mark = ","),
                    format(left_n, big.mark = ","), matched_rate * 100))
    if (!is.na(matched_rate) && matched_rate > max_matched) {
      stop(sprintf(
        "Anti join excluded %.1f%% of %s rows -- exceeds max_matched=%.1f%%. %s -> %s on %s.",
        matched_rate * 100, format(left_n, big.mark = ","), max_matched * 100,
        label_left, label_right, .format_by(by)
      ), call. = FALSE)
    }
  }

  if (write_report) {
    excluded_n <- left_n - nrow(out)
    .write_join_report(tibble::tibble(
      join_type  = "anti",  label_left = label_left,   label_right = label_right,
      left_rows  = left_n,  matched_rows = excluded_n,  output_rows = nrow(out),
      coverage   = .safe_divide(excluded_n, left_n),    by_columns  = .format_by(by)
    ), report_prefix)
  }

  out
}

# -- Private parameter-resolution helpers -------------------------------------

.resolve_coverage_param <- function(val, env_var, default) {
  if (!is.null(val)) {
    if (!is.numeric(val) || length(val) != 1L || is.na(val) || val < 0 || val > 1)
      stop(sprintf("`%s` must be a single number in [0, 1].",
                   deparse(substitute(val))), call. = FALSE)
    return(val)
  }
  env_str <- Sys.getenv(env_var, unset = "")
  if (nzchar(env_str)) {
    parsed <- suppressWarnings(as.numeric(env_str))
    if (is.na(parsed) || parsed < 0 || parsed > 1) {
      warning(sprintf("Invalid %s='%s'; using default %.2f.", env_var, env_str, default),
              call. = FALSE)
      return(default)
    }
    return(parsed)
  }
  default
}

.resolve_dup_param <- function(val, env_var, default) {
  if (!is.null(val)) {
    if (!is.numeric(val) || length(val) != 1L || is.na(val) || val < 0)
      stop("`max_duplication` must be a single non-negative number.", call. = FALSE)
    return(val)
  }
  env_str <- Sys.getenv(env_var, unset = "")
  if (nzchar(env_str)) {
    parsed <- suppressWarnings(as.numeric(env_str))
    if (is.na(parsed) || parsed < 0) {
      warning(sprintf("Invalid %s='%s'; using default.", env_var, env_str), call. = FALSE)
      return(default)
    }
    return(parsed)
  }
  default
}

.assert_cols_exist <- function(df, cols, label, side) {
  missing <- setdiff(cols, names(df))
  if (length(missing)) {
    stop(sprintf(
      "Join key(s) not found in %s (%s): %s. Available: %s",
      side, label, paste(missing, collapse = ", "),
      paste(head(names(df), 20L), collapse = ", ")
    ), call. = FALSE)
  }
}
