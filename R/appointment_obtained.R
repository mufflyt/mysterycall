#' Derive the appointment-obtained indicator and wait, with same-day = 0
#'
#' The two-part / hurdle / Heckman models
#' ([mysterycall_hurdle_wait()], selection models) need two derived columns from
#' the raw call and appointment dates: a binary **appointment-obtained**
#' indicator (the selection / hurdle outcome) and, among obtained appointments,
#' the **business-day wait**. Deriving these by hand is where a subtle but
#' consequential bug creeps in: computing the wait as `appt_date <= call_date`
#' -> `NA` sends *same-day* appointments to `NA`, which then reads as "no
#' appointment obtained" in the selection stage. That contradicts the study
#' convention that a same-day appointment is a 0-day wait, and drops the
#' strongest-access cases from the model.
#'
#' This function is the correct, reusable derivation. An appointment is
#' **obtained** whenever a valid appointment date is present and is not before
#' the call date - **same day counts as obtained, with a wait of 0**. The wait
#' is computed with [mysterycall_count_business_days()], so it inherits the one
#' canonical same-day = 0 / appointment-before-call = `NA` policy instead of a
#' hand-rolled counter.
#'
#' @param data A data frame, one row per call.
#' @param call_col Character scalar. Column holding the call date. Accepts
#'   `Date`, `POSIXct`, or `"YYYY-MM-DD"` strings. Default `"call_date"`.
#' @param appt_col Character scalar. Column holding the offered appointment
#'   date. An absent value (`NA` or empty string) means no appointment was
#'   offered. Default `"appointment_date"`.
#' @param obtained_col Character scalar. Name of the binary indicator column to
#'   add (`1` = appointment obtained, `0` = not obtained, `NA` = undetermined).
#'   Default `"appt_obtained"`.
#' @param wait_col Character scalar. Name of the business-day wait column to add
#'   when `add_wait = TRUE`. Default `"business_days_until_appointment"` -
#'   matches the outcome name used across the package.
#' @param add_wait Logical. When `TRUE` (default) also attach the business-day
#'   wait column. When `FALSE` only the obtained indicator is added.
#' @param calendar A `bizdays` calendar from
#'   [mysterycall_us_federal_calendar()]. Built automatically when `NULL`
#'   (default). Pass a pre-built calendar when calling this many times.
#'
#' @return `data` with `obtained_col` (integer 0/1/NA) appended, and - when
#'   `add_wait = TRUE` - `wait_col` (integer business days, `0` for same-day,
#'   `NA` where no appointment was obtained or dates are invalid). The wait is
#'   `NA` for every not-obtained row, matching the `wait | obtained` structure
#'   [mysterycall_hurdle_wait()] expects.
#'
#' @section Obtained / not-obtained / undetermined:
#' \describe{
#'   \item{obtained (`1`)}{Appointment date present and on/after the call date
#'     (includes same-day, wait `0`).}
#'   \item{not obtained (`0`)}{Call date present, appointment date absent.}
#'   \item{undetermined (`NA`)}{Appointment date present but *before* the call
#'     date (a data-entry error - also warned by
#'     [mysterycall_count_business_days()]), or the call date is missing.}
#' }
#'
#' @seealso [mysterycall_count_business_days()], [mysterycall_business_days()],
#'   [mysterycall_hurdle_wait()], [mysterycall_prepare_calls()]
#' @family business days
#' @export
#'
#' @examples
#' df <- data.frame(
#'   practice         = c("A", "B", "C", "D"),
#'   call_date        = as.Date(c("2026-02-02", "2026-02-02",
#'                                 "2026-02-02", "2026-02-02")),
#'   appointment_date = as.Date(c("2026-02-02",  # same day  -> obtained, wait 0
#'                                 "2026-02-06",  # 4 biz days -> obtained
#'                                 NA,            # none       -> not obtained
#'                                 "2026-01-30")) # before call-> undetermined
#' )
#' if (requireNamespace("bizdays", quietly = TRUE)) {
#'   mysterycall_appointment_obtained(df)
#' }
mysterycall_appointment_obtained <- function(
    data,
    call_col     = "call_date",
    appt_col     = "appointment_date",
    obtained_col = "appt_obtained",
    wait_col     = "business_days_until_appointment",
    add_wait     = TRUE,
    calendar     = NULL) {

  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
  validate_required_columns(data, c(call_col, appt_col), name = "data")
  for (nm in c("obtained_col", "wait_col")) {
    v <- get(nm)
    if (!is.character(v) || length(v) != 1L || !nzchar(v))
      stop(sprintf("`%s` must be a single non-empty string.", nm), call. = FALSE)
  }
  if (!is.logical(add_wait) || length(add_wait) != 1L || is.na(add_wait))
    stop("`add_wait` must be a single TRUE/FALSE.", call. = FALSE)

  call_raw <- data[[call_col]]
  appt_raw <- data[[appt_col]]

  call_d <- as.Date(call_raw)
  appt_d <- as.Date(appt_raw)

  # "Present" = non-NA and, for character input, non-empty after trimming.
  appt_present <- !is.na(appt_d)
  if (is.character(appt_raw)) appt_present <- appt_present & nzchar(trimws(appt_raw))
  call_present <- !is.na(call_d)
  if (is.character(call_raw)) call_present <- call_present & nzchar(trimws(call_raw))

  # Wait, via the one canonical counter: same-day = 0, appt < call = NA (+warn).
  wait <- mysterycall_count_business_days(call_d, appt_d, calendar = calendar)

  # Obtained: appointment present AND on/after the call (same-day included).
  obtained <- rep(NA_integer_, nrow(data))
  obtained[call_present & !appt_present] <- 0L
  obtained[call_present & appt_present & !is.na(wait)] <- 1L
  # appt present but wait is NA (appt before call) stays NA (undetermined).

  # A not-obtained row has no wait to model.
  wait[!(obtained %in% 1L)] <- NA_integer_

  data[[obtained_col]] <- obtained
  if (add_wait) data[[wait_col]] <- wait

  n_obt   <- sum(obtained %in% 1L)
  n_not   <- sum(obtained %in% 0L)
  n_undet <- sum(is.na(obtained))
  n_same  <- sum(obtained %in% 1L & wait %in% 0L)
  message(sprintf(
    paste0(
      "mysterycall_appointment_obtained: %d obtained (incl. %d same-day, wait 0), ",
      "%d not obtained, %d undetermined. Stored in '%s'%s."
    ),
    n_obt, n_same, n_not, n_undet, obtained_col,
    if (add_wait) sprintf(" and '%s'", wait_col) else ""
  ))

  data
}
