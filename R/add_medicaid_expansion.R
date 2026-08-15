#' Join ACA Medicaid-expansion status onto study data (optionally as of the call date)
#'
#' Left-joins the packaged [medicaid_expansion] crosswalk onto a caller/office
#' data frame by state, adding each state's ACA Medicaid-expansion status. The
#' state column may hold either full state names (e.g. `"Texas"`) or two-letter
#' USPS abbreviations (e.g. `"TX"`); the format is auto-detected.
#'
#' When a date column is supplied via `date_col`, the function additionally
#' computes a **per-row, as-of-the-call-date** expansion flag
#' (`expanded_at_date`). This matters for states that adopted expansion *during*
#' a study window: North Carolina implemented on 2023-12-01 and South Dakota on
#' 2023-07-01, so calls placed to those states earlier in 2023 were made while
#' the state had **not yet** expanded and are correctly classified as
#' non-expansion at the call date. The static `expanded` column (current status)
#' would misclassify them. This logic is ported from the `consolidation`
#' study's `R/18_medicaid_expansion.R`.
#'
#' US territories (Puerto Rico, Guam, U.S. Virgin Islands, American Samoa,
#' Northern Mariana Islands) sit outside the ACA state-expansion decision -- they
#' receive capped Medicaid block grants rather than the state expansion choice --
#' so they never match the crosswalk and their added columns are `NA` (a warning
#' lists them).
#'
#' @param data A data frame with one row per call/office.
#' @param state_col Character scalar. Name of the column in `data` holding the
#'   state (full name or two-letter abbreviation). Default `"state"`.
#' @param date_col Character scalar or `NULL`. Name of a `Date` (or
#'   date-coercible) column holding the call date. When supplied, the
#'   as-of-date `expanded_at_date` flag is added. Default `NULL`.
#' @param prefix Character scalar prepended to the added column names to avoid
#'   collisions. Default `""` (no prefix).
#'
#' @return `data` with these columns added (each optionally prefixed):
#' \describe{
#'   \item{`expanded`}{Logical. Current ACA full-expansion status of the state.}
#'   \item{`expansion_date`}{Date the expansion took effect (`NA` for
#'     non-expansion states).}
#'   \item{`expansion_status`}{Character `"Expanded"` / `"Not Expanded"`.}
#'   \item{`expanded_at_date`}{Logical, **only when `date_col` is supplied**.
#'     `TRUE` iff the state had expanded *and* `expansion_date <= date_col` for
#'     that row. `NA` when the date is missing or the state did not match.}
#' }
#'   Rows whose state does not match the crosswalk (e.g. territories, typos)
#'   receive `NA` in every added column and trigger a warning.
#'
#' @seealso [medicaid_expansion] for the underlying dataset;
#'   [mysterycall_assign_region()] for ACOG-district groupings that pair well
#'   with expansion status in subgroup analyses.
#' @family census
#' @export
#'
#' @examples
#' calls <- data.frame(
#'   office    = c("A", "B", "C", "D"),
#'   state     = c("TX", "North Carolina", "CA", "SD"),
#'   call_date = as.Date(c("2023-05-01", "2023-05-01",
#'                         "2023-05-01", "2023-09-01")),
#'   stringsAsFactors = FALSE
#' )
#'
#' # Current (static) expansion status only
#' mysterycall_add_medicaid_expansion(calls)
#'
#' # As-of-call-date status: NC on 2023-05-01 had NOT yet expanded (impl.
#' # 2023-12-01); SD on 2023-09-01 HAD (impl. 2023-07-01).
#' mysterycall_add_medicaid_expansion(calls, date_col = "call_date")
mysterycall_add_medicaid_expansion <- function(data,
                                               state_col = "state",
                                               date_col  = NULL,
                                               prefix    = "") {

  if (!is.data.frame(data)) {
    stop(sprintf("`data` must be a data frame, not %s.", class(data)[1L]), call. = FALSE)
  }
  if (!is.character(state_col) || length(state_col) != 1L) {
    stop("`state_col` must be a single character string.", call. = FALSE)
  }
  if (!state_col %in% names(data)) {
    stop(sprintf("`state_col` '%s' not found in `data`.\nAvailable columns: %s",
                 state_col, paste(names(data), collapse = ", ")), call. = FALSE)
  }
  if (!is.null(date_col)) {
    if (!is.character(date_col) || length(date_col) != 1L) {
      stop("`date_col` must be a single character string or NULL.", call. = FALSE)
    }
    if (!date_col %in% names(data)) {
      stop(sprintf("`date_col` '%s' not found in `data`.\nAvailable columns: %s",
                   date_col, paste(names(data), collapse = ", ")), call. = FALSE)
    }
  }
  if (!is.character(prefix) || length(prefix) != 1L) {
    stop("`prefix` must be a single character string.", call. = FALSE)
  }

  # Load packaged crosswalk without attaching it.
  medicaid_expansion <- NULL  # for R CMD check
  utils::data("medicaid_expansion", package = "mysterycall", envir = environment())
  xwalk <- medicaid_expansion

  raw_state <- as.character(data[[state_col]])
  key <- trimws(raw_state)

  # Auto-detect: two-letter codes join on state_abb, everything else on name.
  is_abb <- nchar(key) == 2L & !is.na(key)
  match_idx <- rep(NA_integer_, length(key))
  match_idx[is_abb]  <- match(toupper(key[is_abb]),
                              toupper(xwalk$state_abb))
  match_idx[!is_abb] <- match(tolower(key[!is_abb]),
                              tolower(xwalk$state))

  unmatched <- unique(raw_state[is.na(match_idx) & !is.na(raw_state) & nzchar(key)])
  if (length(unmatched)) {
    warning(sprintf(
      "%d state value(s) did not match the Medicaid-expansion crosswalk (added columns set to NA): %s",
      length(unmatched), paste(unmatched, collapse = ", ")
    ), call. = FALSE)
  }

  expanded_col       <- xwalk$expanded[match_idx]
  expansion_date_col <- xwalk$expansion_date[match_idx]
  status_col         <- xwalk$status[match_idx]

  out <- data
  nm <- function(base) paste0(prefix, base)
  out[[nm("expanded")]]         <- expanded_col
  out[[nm("expansion_date")]]   <- expansion_date_col
  out[[nm("expansion_status")]] <- status_col

  if (!is.null(date_col)) {
    call_date <- data[[date_col]]
    if (!inherits(call_date, "Date")) {
      call_date <- suppressWarnings(as.Date(call_date))
    }
    # Expanded as of the call date: state expanded AND implementation on/before
    # the call date. NA propagates when either the flag or the date is missing.
    expanded_at_date <- expanded_col &
      !is.na(expansion_date_col) &
      !is.na(call_date) &
      call_date >= expansion_date_col
    # Keep NA (rather than FALSE) where the state itself did not match.
    expanded_at_date[is.na(expanded_col)] <- NA
    out[[nm("expanded_at_date")]] <- expanded_at_date
  }

  out
}

#' Deprecated alias for mysterycall_add_medicaid_expansion
#' @param ... Arguments passed to [mysterycall_add_medicaid_expansion()].
#' @return See [mysterycall_add_medicaid_expansion()].
#' @keywords internal
#' @name add_medicaid_expansion
add_medicaid_expansion <- function(...) {
  .Deprecated("mysterycall_add_medicaid_expansion")
  mysterycall_add_medicaid_expansion(...)
}
