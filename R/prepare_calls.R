#' Prepare and filter raw REDCap mystery-caller data for analysis
#'
#' @name prepare_calls
NULL

#' Prepare raw REDCap mystery-caller data for statistical analysis
#'
#' Applies the standard filtering pipeline for mystery-caller studies:
#' removes records without a call date, applies exclusion-code filtering,
#' resolves second-call contacts, standardizes caller names to title case,
#' and creates ready-to-model outcome columns for both the logistic model
#' (appointment offered: yes/no) and the wait-time model (calendar days).
#'
#' **Two inclusion sets are created (see Value):**
#' \describe{
#'   \item{`$logistic_data`}{All calls where the office was *reached* -
#'     whether or not an appointment was offered. Use with
#'     [mysterycall_logistic_model()]. Exclusion codes 7, 9, and 10 are
#'     included as "appointment not offered" (outcome = 0).}
#'   \item{`$waittime_data`}{Subset of `$logistic_data` where an appointment
#'     date was recorded. Use with [mysterycall_poisson_model()],
#'     [mysterycall_nb_model()], or [mysterycall_auto_model()].}
#' }
#'
#' **Standard REDCap column names assumed** (override via `col_*` arguments):
#' \itemize{
#'   \item `calldate1` - date of first call attempt
#'   \item `contacted1` - 1 = office reached, 0 = not reached (first call)
#'   \item `contacted2` - 1 = reached on second attempt, 0 = not, 99 = N/A
#'   \item `appdate` - date of appointment offered
#'   \item `exclusions` - integer exclusion code (0 = included)
#'   \item `initials` - caller identity (standardized to title case)
#'   \item `medicaid_status` - 1=accepts, 2=refuses, 3=BCBS call, 4=unknown
#' }
#'
#' @param data A data frame. The raw REDCap export.
#' @param col_calldate Character scalar. Column containing the date of the
#'   first call. Default `"calldate1"`.
#' @param col_contacted1 Character scalar. Binary column: office reached on
#'   first call (1 = yes, 0 = no). Default `"contacted1"`.
#' @param col_contacted2 Character scalar. Binary column: office reached on
#'   second call (1 = yes, 0 = no, 99 = N/A). Default `"contacted2"`.
#' @param col_appdate Character scalar. Appointment date column.
#'   Default `"appdate"`.
#' @param col_exclusions Character scalar. Integer exclusion-code column.
#'   Default `"exclusions"`.
#' @param col_initials Character scalar. Caller-identity column.
#'   Default `"initials"`.
#' @param logistic_include_codes Integer vector. Exclusion codes to include
#'   in the **logistic** dataset (appointment-offered model). Code 0 is
#'   always included. Codes 7, 9, and 10 represent "office reached but
#'   appointment refused/blocked" and default to inclusion (outcome = 0).
#'   Default `c(0L, 7L, 9L, 10L)`.
#' @param na_exclusions Character. How to handle `NA` exclusion codes.
#'   `"warn"` (default) keeps them but issues a warning and adds a flag
#'   column. `"drop"` removes them. `"include"` silently keeps them.
#' @param caller_col_out Character scalar. Name of the standardized caller
#'   column in the output. Default `"caller"`.
#' @param appt_offered_col Character scalar. Name of the binary outcome
#'   column added to `$logistic_data`. Default `"appt_offered"`.
#' @param calendar_days_col Character scalar. Name of the calendar-days
#'   column added to `$waittime_data`. Default `"calendar_days"`.
#'
#' @return A list of class `mysterycall_prepared` with elements:
#' \describe{
#'   \item{`logistic_data`}{Data frame ready for [mysterycall_logistic_model()].
#'     Adds columns: `caller` (title-cased), `appt_offered` (0/1),
#'     `reached` (logical), `exclusion_na` (logical flag).}
#'   \item{`waittime_data`}{Subset of `logistic_data` with `appdate`
#'     present. Adds `calendar_days` (numeric, days from call to appt).}
#'   \item{`waterfall`}{Data frame: one row per filter step showing
#'     `step`, `n_remaining`, `n_dropped`, and `reason`.}
#'   \item{`exclusion_summary`}{Data frame: counts by exclusion code with
#'     labels.}
#'   \item{`caller_summary`}{Data frame: standardized caller names and
#'     call counts.}
#'   \item{`na_exclusion_records`}{Data frame: rows where `exclusions` is
#'     `NA`, for manual review. `NULL` when none.}
#' }
#'
#' @family data-preparation
#' @seealso [mysterycall_logistic_model()], [mysterycall_nb_model()],
#'   [mysterycall_auto_model()]
#' @export
#'
#' @examples
#' df <- data.frame(
#'   calldate1   = c("2024-01-10", "2024-01-11", "2024-01-12", NA, "2024-01-14"),
#'   contacted1  = c(1, 1, 0, 1, 1),
#'   contacted2  = c(99, 99, 1, 99, 99),
#'   appdate     = c("2024-02-01", "", "2024-02-05", "2024-02-03", "2024-02-10"),
#'   exclusions  = c(0, 9, 0, 0, 7),
#'   initials    = c("lizeth", "MERILYN", "Lizeth", "jessica", "merilyn"),
#'   stringsAsFactors = FALSE
#' )
#' result <- mysterycall_prepare_calls(df)
#' print(result)
mysterycall_prepare_calls <- function(
    data,
    col_calldate           = "calldate1",
    col_contacted1         = "contacted1",
    col_contacted2         = "contacted2",
    col_appdate            = "appdate",
    col_exclusions         = "exclusions",
    col_initials           = "initials",
    logistic_include_codes = c(0L, 7L, 9L, 10L),
    na_exclusions          = c("warn", "drop", "include"),
    caller_col_out         = "caller",
    appt_offered_col       = "appt_offered",
    calendar_days_col      = "calendar_days"
) {

  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)

  na_exclusions <- match.arg(na_exclusions)
  logistic_include_codes <- as.integer(logistic_include_codes)
  if (!0L %in% logistic_include_codes)
    logistic_include_codes <- c(0L, logistic_include_codes)

  required_cols <- c(col_calldate, col_exclusions)
  missing <- setdiff(required_cols, names(data))
  if (length(missing))
    stop("Required columns not found: ", paste(missing, collapse = ", "), call. = FALSE)

  wf <- .wf_step(NULL, nrow(data), "Raw REDCap export")

  # ---- Step 1: calldate present -----------------------------------------------
  has_calldate <- !is.na(data[[col_calldate]]) & nzchar(trimws(data[[col_calldate]]))
  d <- data[has_calldate, , drop = FALSE]
  wf <- .wf_step(wf, nrow(d), "calldate1 present (call was placed)")

  # ---- Step 2: Standardize caller names ---------------------------------------
  if (col_initials %in% names(d)) {
    d[[caller_col_out]] <- tools::toTitleCase(tolower(trimws(d[[col_initials]])))
  } else {
    d[[caller_col_out]] <- NA_character_
    warning(sprintf("Column '%s' not found; `%s` set to NA.", col_initials, caller_col_out),
            call. = FALSE)
  }

  # ---- Step 3: Handle NA exclusions ------------------------------------------
  exc <- suppressWarnings(as.integer(d[[col_exclusions]]))
  is_na_exc <- is.na(exc)
  na_records <- if (any(is_na_exc)) d[is_na_exc, , drop = FALSE] else NULL
  d$exclusion_na <- is_na_exc

  if (any(is_na_exc)) {
    msg <- sprintf(
      "%d record(s) have NA exclusion codes. %s",
      sum(is_na_exc),
      switch(na_exclusions,
        warn    = "They are retained but flagged in `$na_exclusion_records` for review.",
        drop    = "They are dropped (na_exclusions = 'drop').",
        include = "They are included silently (na_exclusions = 'include')."
      )
    )
    if (na_exclusions == "warn")    warning(msg, call. = FALSE)
    else if (na_exclusions == "drop") message(msg)
    else                              message(msg)
  }

  if (na_exclusions == "drop") {
    d   <- d[!is_na_exc, , drop = FALSE]
    exc <- exc[!is_na_exc]
    wf  <- .wf_step(wf, nrow(d), "NA exclusion codes dropped")
  }

  d$exclusions_int <- exc

  # ---- Step 4: Resolve "reached" from first or second call -------------------
  reached <- rep(FALSE, nrow(d))
  if (col_contacted1 %in% names(d)) {
    c1 <- suppressWarnings(as.integer(d[[col_contacted1]]))
    reached <- !is.na(c1) & c1 == 1L
  }
  if (col_contacted2 %in% names(d)) {
    c2 <- suppressWarnings(as.integer(d[[col_contacted2]]))
    reached <- reached | (!is.na(c2) & c2 == 1L)
  }
  d$reached <- reached

  # ---- Step 5: Logistic dataset (reached + in logistic_include_codes) --------
  in_logistic <- (!is.na(exc) & exc %in% logistic_include_codes) |
                 (is_na_exc & na_exclusions %in% c("warn","include"))
  in_logistic <- in_logistic & reached
  if (!na_exclusions == "drop") in_logistic[is.na(in_logistic)] <- FALSE

  log_data <- d[in_logistic, , drop = FALSE]
  wf <- .wf_step(wf, nrow(log_data),
    sprintf("Logistic set: reached + exclusions in {%s}",
            paste(logistic_include_codes, collapse=",")))

  # Binary outcome: appointment offered?
  if (col_appdate %in% names(log_data)) {
    log_data[[appt_offered_col]] <- as.integer(
      !is.na(log_data[[col_appdate]]) & nzchar(trimws(log_data[[col_appdate]]))
    )
  } else {
    log_data[[appt_offered_col]] <- NA_integer_
    warning(sprintf("Column '%s' not found; `%s` set to NA.", col_appdate, appt_offered_col),
            call. = FALSE)
  }

  # ---- Step 6: Wait-time dataset (exclusion==0 + appdate present) ------------
  wt_data <- log_data[
    !is.na(log_data$exclusions_int) & log_data$exclusions_int == 0L &
    !is.na(log_data[[appt_offered_col]]) & log_data[[appt_offered_col]] == 1L,
    , drop = FALSE
  ]
  wf <- .wf_step(wf, nrow(wt_data),
    "Wait-time set: exclusion==0 + appointment date present")

  if (col_appdate %in% names(wt_data) && col_calldate %in% names(wt_data)) {
    call_d  <- as.Date(substr(trimws(wt_data[[col_calldate]]),  1, 10))
    appt_d  <- as.Date(substr(trimws(wt_data[[col_appdate]]), 1, 10))
    wt_data[[calendar_days_col]] <- as.numeric(appt_d - call_d)

    neg <- !is.na(wt_data[[calendar_days_col]]) & wt_data[[calendar_days_col]] < 0
    if (any(neg)) {
      warning(sprintf("%d record(s) have negative calendar days (appt before call). Inspect and correct.",
                      sum(neg)), call. = FALSE)
    }
  }

  # ---- Summaries --------------------------------------------------------------
  excl_labels <- c(
    "0"  = "Included",
    "1"  = "Closed medical system",
    "2"  = ">5 min on hold",
    "3"  = "Wrong number/office",
    "5"  = "Phone not answered/busy",
    "6"  = "Physician's personal phone",
    "7"  = "Referral required",
    "8"  = "Voicemail",
    "9"  = "Not accepting new patients",
    "10" = "Must see midlevel first"
  )
  exc_tbl <- as.data.frame(table(Code = d$exclusions_int, useNA = "ifany"))
  exc_tbl$Label <- excl_labels[as.character(exc_tbl$Code)]
  exc_tbl$Label[is.na(exc_tbl$Label)] <- "Unknown / not yet coded"
  exc_tbl <- exc_tbl[order(as.numeric(as.character(exc_tbl$Code)), na.last = TRUE), ]

  caller_tbl <- if (caller_col_out %in% names(d)) {
    as.data.frame(table(Caller = d[[caller_col_out]], useNA = "ifany"))
  } else NULL

  structure(
    list(
      logistic_data      = log_data,
      waittime_data      = wt_data,
      waterfall          = wf,
      exclusion_summary  = exc_tbl,
      caller_summary     = caller_tbl,
      na_exclusion_records = na_records
    ),
    class = "mysterycall_prepared"
  )
}


# ----- internal helpers -------------------------------------------------------

.wf_step <- function(wf, n, reason) {
  dropped <- if (is.null(wf)) 0L else n - wf$n_remaining[nrow(wf)]
  if (!is.null(wf) && dropped > 0) dropped <- wf$n_remaining[nrow(wf)] - n
  row <- data.frame(
    step        = if (is.null(wf)) 1L else nrow(wf) + 1L,
    n_remaining = n,
    n_dropped   = if (is.null(wf)) 0L else max(0L, wf$n_remaining[nrow(wf)] - n),
    reason      = reason,
    stringsAsFactors = FALSE
  )
  if (is.null(wf)) row else rbind(wf, row)
}


#' Print method for mysterycall_prepared objects
#'
#' @param x A `mysterycall_prepared` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family data-preparation
#' @export
print.mysterycall_prepared <- function(x, ...) {
  cat("=== Mystery-Caller Data Preparation ===\n\n")

  cat("-- Filtering Waterfall --\n")
  wf <- x$waterfall
  wf$pct_dropped <- ifelse(
    wf$n_dropped == 0, "",
    sprintf("(-%d)", wf$n_dropped)
  )
  print(wf[, c("step", "n_remaining", "n_dropped", "reason")], row.names = FALSE)

  cat(sprintf(
    "\nLogistic dataset (appt offered):  n = %d\n",
    nrow(x$logistic_data)
  ))
  if (!is.null(x$logistic_data[["appt_offered"]])) {
    cat(sprintf(
      "  Appointment offered: %d (%.1f%%)   Not offered: %d (%.1f%%)\n",
      sum(x$logistic_data$appt_offered == 1L, na.rm = TRUE),
      mean(x$logistic_data$appt_offered == 1L, na.rm = TRUE) * 100,
      sum(x$logistic_data$appt_offered == 0L, na.rm = TRUE),
      mean(x$logistic_data$appt_offered == 0L, na.rm = TRUE) * 100
    ))
  }

  cat(sprintf(
    "\nWait-time dataset (appt date present): n = %d\n",
    nrow(x$waittime_data)
  ))
  if ("calendar_days" %in% names(x$waittime_data)) {
    cd <- x$waittime_data$calendar_days
    cat(sprintf("  Calendar days: median=%.0f  mean=%.1f  range=%d-%d\n",
                stats::median(cd, na.rm = TRUE), mean(cd, na.rm = TRUE),
                min(cd, na.rm = TRUE), max(cd, na.rm = TRUE)))
  }

  if (!is.null(x$na_exclusion_records)) {
    cat(sprintf(
      "\n  WARNING: %d records have NA exclusion codes - review `$na_exclusion_records`\n",
      nrow(x$na_exclusion_records)
    ))
  }

  cat("\n-- Exclusion Code Summary --\n")
  print(x$exclusion_summary, row.names = FALSE)

  if (!is.null(x$caller_summary)) {
    cat("\n-- Caller Summary (standardized) --\n")
    print(x$caller_summary, row.names = FALSE)
  }

  invisible(x)
}
