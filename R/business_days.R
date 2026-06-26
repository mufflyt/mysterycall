#' Business-day utilities for mystery caller studies
#'
#' The primary outcome in mystery caller studies is
#' `business_days_until_appointment`: the number of Mon-Fri working days
#' (excluding US federal holidays) between the call date and the offered
#' appointment date. These helpers build a `bizdays` calendar from US
#' federal holidays and compute that column for a data frame.
#'
#' @name mysterycall_business_days
NULL

# -- Internal calendar helpers (no lubridate) ----------------------------------

#' Get Day of Week
#'
#' Returns 1=Sun, 2=Mon, ..., 7=Sat (same convention as lubridate::wday).
#'
#' @param d Date object or string.
#' @return Integer (1-7).
#' @keywords internal
.mc_wday <- function(d) as.integer(format(as.Date(d), "%w")) + 1L

#' Get nth Occurrence of a Weekday
#'
#' @param year Integer year.
#' @param month Integer month (1-12).
#' @param weekday Integer weekday (1=Sun, ..., 7=Sat).
#' @param n Integer occurrence (1st, 2nd, etc.).
#' @return Date object.
#' @keywords internal
.mc_nth_weekday <- function(year, month, weekday, n) {
  first     <- as.Date(paste(year, month, "01", sep = "-"))
  first_dow <- .mc_wday(first)
  offset    <- (weekday - first_dow) %% 7L
  first     + offset + (n - 1L) * 7L
}

#' Get Last Occurrence of a Weekday
#'
#' @param year Integer year.
#' @param month Integer month (1-12).
#' @param weekday Integer weekday (1=Sun, ..., 7=Sat).
#' @return Date object.
#' @keywords internal
.mc_last_weekday <- function(year, month, weekday) {
  last <- if (month == 12L) {
    as.Date(paste(year + 1L, "01", "01", sep = "-")) - 1L
  } else {
    as.Date(paste(year, month + 1L, "01", sep = "-")) - 1L
  }
  last_dow <- .mc_wday(last)
  last - (last_dow - weekday) %% 7L
}

#' Shift Holiday to Observed Weekday
#'
#' Shifts a fixed-date holiday to its observed weekday (Friday if Saturday,
#' Monday if Sunday).
#'
#' @param d Date object.
#' @return Date object (possibly shifted).
#' @keywords internal
.mc_observe <- function(d) {
  dow <- .mc_wday(d)
  if (dow == 7L) return(d - 1L)   # Saturday -> Friday
  if (dow == 1L) return(d + 1L)   # Sunday   -> Monday
  d
}


#' Build a US federal holiday calendar
#'
#' Creates a [bizdays::create.calendar()] object covering all 11 US federal
#' holidays for the requested year range. Fixed holidays are shifted to their
#' observed weekday (Friday if they fall on Saturday, Monday if Sunday).
#' Floating holidays (MLK Day, Presidents Day, Memorial Day, Labor Day,
#' Columbus Day, Thanksgiving) are computed exactly.
#'
#' The calendar is used internally by [mysterycall_business_days()] and
#' [mysterycall_count_business_days()]. You only need to call this directly
#' if you want to reuse the same calendar object across many calls for
#' performance, or if you need to inspect the holiday list.
#'
#' @param start_year First year to include. Defaults to five years before the
#'   current year, which covers retrospective data collection.
#' @param end_year Last year to include. Defaults to ten years after the
#'   current year.
#'
#' @return An S3 object of class `"calendar"` (from `bizdays`) named
#'   `"USFederal"`. Pass it to [bizdays::bizdays()] or [bizdays::is.bizday()]
#'   for date arithmetic. Contains one holiday entry per year from
#'   `start_year` to `end_year`, with fixed holidays observing the
#'   Saturday-to-Friday / Sunday-to-Monday shift rule.
#'
#' @seealso [mysterycall_business_days()], [mysterycall_count_business_days()]
#' @family business days
#' @export
#'
#' @examplesIf requireNamespace("bizdays", quietly = TRUE)
#' cal <- mysterycall_us_federal_calendar(2024, 2028)
#' bizdays::is.bizday(as.Date("2026-01-19"), cal)  # MLK Day -> FALSE
mysterycall_us_federal_calendar <- function(
    start_year = as.integer(format(Sys.Date(), "%Y")) - 5L,
    end_year   = as.integer(format(Sys.Date(), "%Y")) + 10L) {

  if (!requireNamespace("bizdays", quietly = TRUE)) {
    stop("Package 'bizdays' is required",
         call. = FALSE)
  }
  if (!is.numeric(start_year) || !is.numeric(end_year) ||
      length(start_year) != 1L || length(end_year) != 1L) {
    stop("`start_year` and `end_year` must each be a single number.", call. = FALSE)
  }
  if (end_year < start_year) {
    stop("`end_year` must be >= `start_year`.", call. = FALSE)
  }

  holidays <- vector("list", as.integer(end_year - start_year + 1L))

  for (i in seq_along(holidays)) {
    yr <- as.integer(start_year) + i - 1L

    fixed <- lapply(
      list(
        paste0(yr, "-01-01"),  # New Year's Day
        paste0(yr, "-06-19"),  # Juneteenth
        paste0(yr, "-07-04"),  # Independence Day
        paste0(yr, "-11-11"),  # Veterans Day
        paste0(yr, "-12-25")   # Christmas
      ),
      function(s) .mc_observe(as.Date(s))
    )

    floating <- list(
      .mc_nth_weekday(yr,  1L, 2L, 3L),   # MLK Day:       3rd Monday Jan
      .mc_nth_weekday(yr,  2L, 2L, 3L),   # Presidents Day: 3rd Monday Feb
      .mc_last_weekday(yr, 5L, 2L),        # Memorial Day:  last Monday May
      .mc_nth_weekday(yr,  9L, 2L, 1L),   # Labor Day:      1st Monday Sep
      .mc_nth_weekday(yr, 10L, 2L, 2L),   # Columbus Day:   2nd Monday Oct
      .mc_nth_weekday(yr, 11L, 5L, 4L)    # Thanksgiving:   4th Thursday Nov
    )

    holidays[[i]] <- do.call(c, c(fixed, floating))
  }

  all_holidays <- sort(unique(do.call(c, holidays)))

  bizdays::create.calendar(
    name      = "USFederal",
    holidays  = all_holidays,
    weekdays  = c("saturday", "sunday"),
    start.date = as.Date(paste0(start_year, "-01-01")),
    end.date   = as.Date(paste0(end_year,   "-12-31"))
  )
}


#' Count business days between two dates (vectorized)
#'
#' Returns the number of Mon-Fri working days, excluding US federal holidays,
#' between `start_date` (exclusive) and `end_date` (inclusive). This matches
#' the `business_days_until_appointment` convention used in mystery caller
#' studies: a call made on Monday for an appointment on Friday of the same
#' week returns 4.
#'
#' Pairs where `end_date < start_date` or either date is `NA` return `NA`.
#' Pairs where `end_date == start_date` return `0`.
#'
#' @param start_date Date of the mystery call. Accepts `Date`, `POSIXct`, or
#'   a character vector in `"YYYY-MM-DD"` format. Vectorised.
#' @param end_date Date of the offered appointment. Same types accepted.
#' @param calendar A `bizdays` calendar from [mysterycall_us_federal_calendar()].
#'   When `NULL` (default) a calendar covering `r (as.integer(format(Sys.Date(), "%Y"))-5)` -
#'   `r (as.integer(format(Sys.Date(), "%Y"))+10)` is built automatically.
#'
#' @return Integer vector the same length as `start_date`.
#'
#' @family business days
#' @seealso [mysterycall_business_days()], [mysterycall_us_federal_calendar()]
#' @export
#'
#' @examplesIf requireNamespace("bizdays", quietly = TRUE)
#' # Monday to Friday of the same week = 4 business days
#' mysterycall_count_business_days("2026-02-02", "2026-02-06")
#'
#' # Spans Presidents Day 2026 (Mon Feb 16) = 4, not 5
#' mysterycall_count_business_days("2026-02-13", "2026-02-20")
mysterycall_count_business_days <- function(start_date,
                                            end_date,
                                            calendar = NULL) {
  if (!requireNamespace("bizdays", quietly = TRUE)) {
    message("Package 'bizdays' is not installed; falling back to calendar days. Install with: install.packages('bizdays')")
    return(as.integer(as.Date(end_date) - as.Date(start_date)))
  }
  if (is.null(calendar)) calendar <- mysterycall_us_federal_calendar()

  start_date <- as.Date(start_date)
  end_date   <- as.Date(end_date)

  if (length(start_date) != length(end_date)) {
    if (length(start_date) == 1L) {
      start_date <- rep(start_date, length(end_date))
    } else if (length(end_date) == 1L) {
      end_date <- rep(end_date, length(start_date))
    } else {
      stop("`start_date` and `end_date` must have the same length (or one must be length 1).",
           call. = FALSE)
    }
  }

  result <- rep(NA_integer_, length(start_date))
  valid  <- !is.na(start_date) & !is.na(end_date) & (end_date >= start_date)

  if (any(valid)) {
    result[valid] <- as.integer(
      bizdays::bizdays(start_date[valid], end_date[valid], calendar)
    )
  }

  n_neg <- sum(!is.na(start_date) & !is.na(end_date) & end_date < start_date)
  if (n_neg > 0L) {
    warning(sprintf(
      "%d pair(s) have appointment_date < call_date and were set to NA. Check for data entry errors.",
      n_neg
    ), call. = FALSE)
  }

  result
}


#' Add a business-days column to a mystery caller data frame
#'
#' Computes [mysterycall_count_business_days()] for every row and stores the
#' result in a new column. This is the primary way to produce the
#' `business_days_until_appointment` outcome column needed for
#' [mysterycall_poisson_model()].
#'
#' @param data A data frame containing date columns for the call and the
#'   offered appointment.
#' @param call_col Name of the column holding the call date. Defaults to
#'   `"call_date"`.
#' @param appt_col Name of the column holding the appointment date. Defaults
#'   to `"appointment_date"`.
#' @param result_col Name of the new column to create. Defaults to
#'   `"business_days_until_appointment"`, which matches the outcome name used
#'   throughout the package.
#' @param calendar A `bizdays` calendar from [mysterycall_us_federal_calendar()].
#'   Built automatically when `NULL` (default). Pass a pre-built calendar when
#'   calling this function many times to avoid rebuilding it on each call.
#'
#' @return `data` with one additional integer column named `result_col`.
#'
#' @family business days
#' @seealso [mysterycall_count_business_days()], [mysterycall_poisson_model()]
#' @export
#'
#' @examples
#' df <- data.frame(
#'   physician        = c("Dr. Smith", "Dr. Jones"),
#'   call_date        = as.Date(c("2026-02-02", "2026-02-13")),
#'   appointment_date = as.Date(c("2026-02-10", "2026-02-20"))
#' )
#' if (requireNamespace("bizdays", quietly = TRUE)) {
#'   mysterycall_business_days(df)
#' }
mysterycall_business_days <- function(data,
                                      call_col   = "call_date",
                                      appt_col   = "appointment_date",
                                      result_col = "business_days_until_appointment",
                                      calendar   = NULL) {
  if (!requireNamespace("bizdays", quietly = TRUE)) {
    message("Package 'bizdays' is not installed; falling back to calendar days. Install with: install.packages('bizdays')")
    validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
    validate_required_columns(data, c(call_col, appt_col), name = "data")
    data[[result_col]] <- as.integer(as.Date(data[[appt_col]]) - as.Date(data[[call_col]]))
    return(data)
  }

  validate_dataframe(data, name = "data", allow_zero_rows = FALSE)
  validate_required_columns(data, c(call_col, appt_col), name = "data")

  if (!is.character(result_col) || length(result_col) != 1L || !nzchar(result_col)) {
    stop("`result_col` must be a non-empty character scalar.", call. = FALSE)
  }
  if (result_col %in% c(call_col, appt_col)) {
    stop(sprintf("`result_col` ('%s') cannot be the same as `call_col` or `appt_col`.",
                 result_col), call. = FALSE)
  }

  if (is.null(calendar)) calendar <- mysterycall_us_federal_calendar()

  start_dates <- as.Date(data[[call_col]])
  end_dates   <- as.Date(data[[appt_col]])

  n_missing_start <- sum(is.na(start_dates))
  n_missing_end   <- sum(is.na(end_dates))
  if (n_missing_start > 0L) {
    message(sprintf("%d row(s) have NA in `%s`; business days set to NA for those rows.",
                    n_missing_start, call_col))
  }
  if (n_missing_end > 0L) {
    message(sprintf("%d row(s) have NA in `%s`; business days set to NA for those rows.",
                    n_missing_end, appt_col))
  }

  data[[result_col]] <- mysterycall_count_business_days(start_dates, end_dates, calendar)

  n_computed <- sum(!is.na(data[[result_col]]))
  message(sprintf(
    "Business days computed for %d/%d row(s); stored in column '%s'.",
    n_computed, nrow(data), result_col
  ))

  data
}
