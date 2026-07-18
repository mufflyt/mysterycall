#' Export a caller list in Google Sheets import format
#'
#' Writes a mystery-caller list to a CSV shaped for import into Google Sheets: a
#' study-title row (cell A1), a `name / phone / NPI / <stage_col>` header, then one
#' row per clinician with the stage-tracking column left blank for callers. Rows
#' are ordered by state with each matched pair kept adjacent (the `group_last`
#' arm placed second within a pair).
#'
#' The file is written with CRLF line endings and minimal quoting so it round-trips
#' cleanly through spreadsheet tools.
#'
#' @param src Path to the calling sheet CSV (one row per clinician). Must contain
#'   `name_col`, `phone_col`, `npi_col`, `state_col`, `pair_col`, and `group_col`.
#' @param out Path to write the Google Sheets-formatted CSV.
#' @param study_title Character string placed in the first row (cell A1).
#' @param stage_col Name of the blank tracking column callers fill, e.g.
#'   `"Stage 1 Calling"`.
#' @param name_col,phone_col,npi_col Input columns copied to the output, in this
#'   order. Their names are reused verbatim as the output header.
#' @param state_col,pair_col Columns used for ordering. `pair_col` is coerced to
#'   numeric so pairs sort naturally; each matched pair stays adjacent.
#' @param group_col,group_last Within a pair, the row whose `group_col` equals
#'   `group_last` is placed second (e.g. put `"PE"` after `"Non-PE"`).
#' @param backup Optional path for a one-time backup of an existing `out` file.
#'   The backup is written only if it does not already exist, preserving the
#'   original. `NULL` (default) skips backup.
#' @param verbose Emit progress messages.
#'
#' @return (Invisibly) the ordered data frame that was written.
#' @export
#' @examples
#' \dontrun{
#' mysterycall_export_gsheet_caller_list(
#'   src = "calling_sheet.csv",
#'   out = "caller_list_for_google_sheets.csv",
#'   study_title = "Mystery Caller Study")
#' }
mysterycall_export_gsheet_caller_list <- function(
    src,
    out,
    study_title = "Mystery Caller Study",
    stage_col   = "Stage 1 Calling",
    name_col    = "Provider Name",
    phone_col   = "Phone",
    npi_col     = "NPI",
    state_col   = "State",
    pair_col    = "Matched Pair ID",
    group_col   = "PE_or_Not",
    group_last  = "PE",
    backup      = NULL,
    verbose     = TRUE) {

  checkmate::assert_file_exists(src)
  checkmate::assert_string(out)
  checkmate::assert_string(study_title)
  checkmate::assert_string(stage_col)
  checkmate::assert_string(group_last)
  checkmate::assert_flag(verbose)
  if (!is.null(backup)) checkmate::assert_string(backup)

  # Read everything as character so NPI / phone are preserved verbatim.
  df <- readr::read_csv(src, col_types = readr::cols(.default = readr::col_character()))
  required <- c(name_col, phone_col, npi_col, state_col, pair_col, group_col)
  checkmate::assert_subset(required, colnames(df))

  # Order by state, then matched pair, then place `group_last` second within a pair.
  # method = "radix" gives C-locale byte ordering, stable and reproducible.
  last_arm <- as.integer(df[[group_col]] == group_last)
  pair_num <- suppressWarnings(as.numeric(df[[pair_col]]))
  df <- df[order(df[[state_col]], pair_num, last_arm, method = "radix"), , drop = FALSE]

  out_df <- data.frame(
    a = df[[name_col]], b = df[[phone_col]], c = df[[npi_col]],
    check.names = FALSE, stringsAsFactors = FALSE)
  colnames(out_df) <- c(name_col, phone_col, npi_col)
  out_df[[stage_col]] <- ""

  # One-time backup of any existing output file.
  if (!is.null(backup) && file.exists(out) && !file.exists(backup)) {
    file.copy(out, backup)
    if (verbose) message("Backed up existing file -> ", backup)
  }

  # Title row (CRLF), then header + data via readr (CRLF, minimal quoting).
  cat(paste0(study_title, ",,,\r\n"), file = out, sep = "")
  readr::write_csv(out_df, out, append = TRUE, col_names = TRUE, eol = "\r\n", na = "")

  if (verbose) {
    message(sprintf("Wrote %s: %d rows across %d states",
                    out, nrow(df), length(unique(df[[state_col]]))))
  }
  invisible(out_df)
}
