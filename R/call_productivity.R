#' Compute per-caller productivity metrics
#'
#' Summarizes call volume, scheduling rates, and time metrics for each
#' caller in a mystery caller dataset.
#'
#' @param data A data frame with at least a caller column.
#' @param caller_col Character scalar: column identifying each caller.
#' @param date_col Character scalar or NULL. Column containing call dates.
#'   Accepts `Date`, `POSIXct`, or character (coerced via `as.Date()`).
#'   When `NULL`, `n_days` and `calls_per_day` are `NA` in the output.
#' @param outcome_col Character scalar or NULL. Binary (0/1) column indicating
#'   whether a call resulted in an accepted appointment.
#' @param hold_time_col Character scalar or NULL. Hold time in seconds
#'   (numeric) or "MM:SS" format (character).
#' @param call_time_col Character scalar or NULL. Total call time in seconds
#'   (numeric) or "MM:SS" format (character).
#'
#' @return A data frame with one row per caller, sorted by `n_calls`
#'   descending. Columns:
#' \describe{
#'   \item{`caller`}{Character. Caller identifier (values from `caller_col`).}
#'   \item{`n_calls`}{Integer. Total number of calls made.}
#'   \item{`n_days`}{Numeric. Count of unique call dates. `NA` when
#'     `date_col` is `NULL`.}
#'   \item{`calls_per_day`}{Numeric. `n_calls / n_days`. `NA` when
#'     `date_col` is `NULL`.}
#'   \item{`n_accepted`}{Numeric. Sum of `outcome_col`. `NA` when
#'     `outcome_col` is `NULL`.}
#'   \item{`acceptance_rate`}{Character. Formatted `"XX.X%"`. `NA` when
#'     `outcome_col` is `NULL`.}
#'   \item{`mean_hold_sec`}{Numeric. Mean hold time in seconds. `NA` when
#'     `hold_time_col` is `NULL`.}
#'   \item{`mean_call_sec`}{Numeric. Mean call time in seconds. `NA` when
#'     `call_time_col` is `NULL`.}
#' }
#' The attribute `total_calls_all` (integer) is set on the returned data
#' frame recording the grand total across all callers.
#'
#' @examples
#' df <- data.frame(
#'   caller  = c("Alice","Alice","Bob"),
#'   outcome = c(1, 0, 1)
#' )
#' mysterycall_call_productivity(df, "caller", outcome_col = "outcome")
#'
#' @seealso [mysterycall_caller_reliability()] for inter-rater reliability
#'   metrics; [mysterycall_compare_waves()] for cross-wave outcome comparisons.
#' @family workflow
#' @export
mysterycall_call_productivity <- function(
    data,
    caller_col,
    date_col      = NULL,
    outcome_col   = NULL,
    hold_time_col = NULL,
    call_time_col = NULL
) {
  # ---- input validation -------------------------------------------------------
  stopifnot(is.data.frame(data))
  stopifnot(is.character(caller_col), length(caller_col) == 1)
  if (!caller_col %in% names(data)) {
    stop(sprintf(
      "caller_col '%s' not found in `data`.\nAvailable columns: %s",
      caller_col, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  }
  n_unique_callers <- length(unique(data[[caller_col]]))
  if (n_unique_callers < 2) {
    stop("At least 2 unique callers are required; found ", n_unique_callers, ".")
  }
  .check_col <- function(col, label) {
    if (!is.null(col)) {
      stopifnot(is.character(col), length(col) == 1)
      if (!col %in% names(data)) stop(sprintf(
        "%s '%s' not found in `data`.\nAvailable columns: %s",
        label, col, paste(names(data), collapse = ", ")
      ), call. = FALSE)
    }
  }
  .check_col(date_col,      "date_col")
  .check_col(outcome_col,   "outcome_col")
  .check_col(hold_time_col, "hold_time_col")
  .check_col(call_time_col, "call_time_col")

  # ---- helper: convert "MM:SS" or numeric to seconds --------------------------
  .to_seconds <- function(x) {
    if (is.numeric(x)) return(x)
    x <- as.character(x)
    has_colon <- grepl("^[0-9]+:[0-5][0-9]$", trimws(x))
    result <- numeric(length(x))
    result[!has_colon] <- suppressWarnings(as.numeric(x[!has_colon]))
    if (any(has_colon)) {
      parts <- strsplit(x[has_colon], ":")
      result[has_colon] <- vapply(parts, function(p) {
        as.numeric(p[1]) * 60 + as.numeric(p[2])
      }, numeric(1))
    }
    result
  }

  # ---- helper: coerce date column ---------------------------------------------
  .to_date <- function(x) {
    if (inherits(x, "Date"))   return(x)
    if (inherits(x, "POSIXt")) return(as.Date(x))
    as.Date(as.character(x))
  }

  # ---- prepare columns --------------------------------------------------------
  callers    <- data[[caller_col]]
  dates      <- if (!is.null(date_col))      .to_date(data[[date_col]])    else NULL
  outcomes   <- if (!is.null(outcome_col))   as.numeric(data[[outcome_col]]) else NULL
  hold_secs  <- if (!is.null(hold_time_col)) .to_seconds(data[[hold_time_col]]) else NULL
  call_secs  <- if (!is.null(call_time_col)) .to_seconds(data[[call_time_col]]) else NULL

  # ---- compute per-caller metrics ---------------------------------------------
  unique_callers <- sort(unique(callers))

  rows <- lapply(unique_callers, function(cl) {
    idx <- callers == cl

    n_calls      <- sum(idx)

    n_days       <- if (!is.null(dates))     length(unique(dates[idx]))  else NA_real_
    calls_per_day <- if (!is.null(dates))    n_calls / n_days            else NA_real_

    n_accepted   <- if (!is.null(outcomes))  sum(outcomes[idx], na.rm = TRUE) else NA_real_
    accept_rate  <- if (!is.null(outcomes)) {
      # Denominator excludes NA-outcome rows so callers are not penalized for
      # calls whose outcome was never recorded (consistent with n_accepted).
      n_outcome <- sum(!is.na(outcomes[idx]))
      if (n_outcome > 0) sprintf("%.1f%%", n_accepted / n_outcome * 100) else NA_character_
    } else NA_character_

    m_hold <- if (!is.null(hold_secs)) mean(hold_secs[idx], na.rm = TRUE) else NA_real_
    m_call <- if (!is.null(call_secs)) mean(call_secs[idx], na.rm = TRUE) else NA_real_

    data.frame(
      caller          = cl,
      n_calls         = n_calls,
      n_days          = n_days,
      calls_per_day   = calls_per_day,
      n_accepted      = n_accepted,
      acceptance_rate = accept_rate,
      mean_hold_sec   = m_hold,
      mean_call_sec   = m_call,
      stringsAsFactors = FALSE
    )
  })

  result <- do.call(rbind, rows)
  result <- result[order(-result$n_calls), ]
  rownames(result) <- NULL

  attr(result, "total_calls_all") <- nrow(data)
  result
}
