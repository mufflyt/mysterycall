#' Refuse to Analyse a Carry-Forward-Contaminated Wait-Time Variable
#'
#' A hard guard, not a report. Where
#' [mysterycall_flag_exclusion_discrepancy()] returns the offending rows so a
#' human can adjudicate them, this stops the analysis outright. It exists
#' because a wait-time column that has been fill-down contaminated does not look
#' broken: every value is a plausible number of business days, models fit, and
#' the resulting mean is close enough to the honest one to pass a smell test.
#' The damage only shows up when you ask which rows the numbers are attached to.
#'
#' @param data A data frame of mystery-caller records.
#' @param wait_col Character scalar. Name of the wait-time column to audit.
#'   Default `"business_days_until_appointment"`.
#' @param appointment_col Character scalar or `NULL`. Name of the appointment
#'   date column. When supplied this is the strongest available evidence: a wait
#'   time on a row with no appointment date cannot have been measured.
#' @param exclusion_col Character scalar or `NULL`. Name of the exclusion-reason
#'   column. When supplied, rows whose value is not `contact_value` are treated
#'   as calls that never produced an appointment.
#' @param contact_value Character scalar. The value in `exclusion_col` meaning
#'   the call succeeded. Default `"Able to contact"`.
#' @param action One of `"error"` (default) or `"warn"`. `"warn"` exists for
#'   auditing a historical file on purpose; it is not a way to keep going.
#'
#' @return Invisibly, `TRUE` when the column is clean. Otherwise raises a
#'   condition of class `mysterycall_contaminated_wait`, carrying the offending
#'   row indices in `$rows` and the per-test counts in `$counts`.
#'
#' @section What this detects:
#' Three signatures, in decreasing order of certainty.
#'
#' 1. **Wait without an appointment.** `wait_col` is non-missing where
#'    `appointment_col` is missing. An office that never gave a date cannot have
#'    a measured wait.
#' 2. **Wait on an excluded call.** `wait_col` is non-missing where
#'    `exclusion_col` is not `contact_value`.
#' 3. **Carry-forward runs.** Consecutive identical `wait_col` values where the
#'    second and later rows have no appointment of their own. This is the
#'    fingerprint of a fill-down (last-observation-carried-forward) operation,
#'    which is how the contamination is usually introduced: a spreadsheet sorted
#'    so that each answered call is followed by the calls that were not.
#'
#' @section The historical defect this was written for:
#' The 2020 NPI-enrichment branch of the 2019 FPMRS mystery-caller study
#' (`_mystery_caller_data_uploaded_4_9_mutate_90.csv`) carries a numeric
#' `Business_days_until_appointment` that is non-missing on all 352 rows,
#' including all 165 excluded ones. Those 165 rows hold zero appointment dates
#' and 116 were never contacted at all, yet 127 of them (77 percent) repeat the
#' wait of the nearest preceding included row. Analysing it assigns real
#' appointment waits to offices that never answered the phone. The column is
#' kept rather than deleted or repaired, because a defect that has been quietly
#' removed is a defect that gets reintroduced; this guard is what makes keeping
#' it safe.
#'
#' @family quality control
#' @seealso [mysterycall_flag_exclusion_discrepancy()], which reports the same
#'   class of discrepancy as a table instead of stopping.
#' @importFrom checkmate assert_data_frame assert_string assert_names
#' @export
#'
#' @examples
#' # A fill-down contaminated frame: rows 2 and 3 inherit row 1's wait.
#' bad <- data.frame(
#'   appointment_date                = as.Date(c("2019-07-11", NA, NA)),
#'   business_days_until_appointment = c(10, 10, 10)
#' )
#' res <- try(
#'   mysterycall_guard_contaminated_wait(bad, appointment_col = "appointment_date"),
#'   silent = TRUE
#' )
#' inherits(res, "try-error")
#'
#' # The honest version: no wait where there is no appointment.
#' good <- data.frame(
#'   appointment_date                = as.Date(c("2019-07-11", NA, NA)),
#'   business_days_until_appointment = c(10, NA, NA)
#' )
#' mysterycall_guard_contaminated_wait(good, appointment_col = "appointment_date")
mysterycall_guard_contaminated_wait <- function(
    data,
    wait_col        = "business_days_until_appointment",
    appointment_col = NULL,
    exclusion_col   = NULL,
    contact_value   = "Able to contact",
    action          = c("error", "warn")) {

  action <- match.arg(action)
  checkmate::assert_data_frame(data, min.rows = 0)
  checkmate::assert_string(wait_col)
  checkmate::assert_names(names(data), must.include = wait_col)
  checkmate::assert_string(appointment_col, null.ok = TRUE)
  checkmate::assert_string(exclusion_col, null.ok = TRUE)
  checkmate::assert_string(contact_value)
  if (!is.null(appointment_col)) {
    checkmate::assert_names(names(data), must.include = appointment_col)
  }
  if (!is.null(exclusion_col)) {
    checkmate::assert_names(names(data), must.include = exclusion_col)
  }

  wait <- data[[wait_col]]
  if (!is.numeric(wait)) {
    # A banded/categorical wait cannot be fill-down contaminated in the way this
    # guard detects, and silently passing a column it never examined would be
    # exactly the false assurance this function exists to prevent.
    stop(sprintf(
      "`%s` is %s, not numeric. This guard audits a numeric wait time; it has not checked this column.",
      wait_col, class(wait)[1]
    ), call. = FALSE)
  }
  has_wait <- !is.na(wait)

  # (1) wait present, appointment absent
  rows_no_appt <- integer(0)
  if (!is.null(appointment_col)) {
    appt <- data[[appointment_col]]
    no_appt <- if (is.character(appt)) is.na(appt) | !nzchar(trimws(appt)) else is.na(appt)
    rows_no_appt <- which(has_wait & no_appt)
  }

  # (2) wait present on a call coded as excluded
  rows_excluded <- integer(0)
  if (!is.null(exclusion_col)) {
    excl <- as.character(data[[exclusion_col]])
    rows_excluded <- which(has_wait & !is.na(excl) & excl != contact_value)
  }

  # (3) carry-forward runs: identical to the previous row's wait, with no
  #     appointment of its own to justify it
  rows_carry <- integer(0)
  if (nrow(data) > 1L) {
    prev <- c(NA_real_, utils::head(as.numeric(wait), -1L))
    same_as_prev <- has_wait & !is.na(prev) & as.numeric(wait) == prev
    unjustified <- if (!is.null(appointment_col)) {
      appt <- data[[appointment_col]]
      if (is.character(appt)) is.na(appt) | !nzchar(trimws(appt)) else is.na(appt)
    } else if (!is.null(exclusion_col)) {
      excl <- as.character(data[[exclusion_col]])
      !is.na(excl) & excl != contact_value
    } else {
      rep(FALSE, nrow(data))
    }
    rows_carry <- which(same_as_prev & unjustified)
  }

  offending <- sort(unique(c(rows_no_appt, rows_excluded, rows_carry)))
  counts <- c(
    wait_without_appointment = length(rows_no_appt),
    wait_on_excluded_call    = length(rows_excluded),
    carry_forward_runs       = length(rows_carry)
  )

  if (length(offending) == 0L) {
    return(invisible(TRUE))
  }

  msg <- paste0(
    sprintf("`%s` is contaminated and must not be analysed as a wait time.\n", wait_col),
    sprintf("  %d of %d rows are implicated.\n", length(offending), nrow(data)),
    sprintf("  wait recorded with no appointment date : %d\n", counts[["wait_without_appointment"]]),
    sprintf("  wait recorded on an excluded call      : %d\n", counts[["wait_on_excluded_call"]]),
    sprintf("  carried forward from the previous row  : %d\n", counts[["carry_forward_runs"]]),
    "  Derive the wait from the call and appointment dates instead, and keep\n",
    "  this column only as a labelled historical artefact."
  )

  cond <- structure(
    class = c("mysterycall_contaminated_wait",
              if (action == "error") c("error", "condition") else c("warning", "condition")),
    list(message = msg, call = NULL, rows = offending, counts = counts)
  )
  if (action == "error") stop(cond) else warning(cond)
  invisible(FALSE)
}
