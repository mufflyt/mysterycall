#' Flag call dates that look like fat-finger entry errors
#'
#' In mystery-caller studies all calls in a wave are typically placed on the
#' same day (or within a narrow window). A single row with a date 30 days
#' outside the consensus is almost always a data-entry error - e.g., "June 17"
#' mis-keyed as "July 17". This function identifies those outliers.
#'
#' For each group (defined by `group_col`, or the whole data set if
#' `group_col = NULL`), the *modal date* (most-frequent date) is used as the
#' expected anchor. Any row whose date differs from that anchor by more than
#' `tolerance_days` is flagged.
#'
#' @param data A data frame.
#' @param date_col Character scalar. Name of the Date (or coercible-to-Date)
#'   column to check.
#' @param group_col Character scalar or `NULL`. Optional column that identifies
#'   the call wave or batch. When supplied, outlier detection is performed
#'   independently within each group. Default `NULL` (whole data set as one
#'   group).
#' @param tolerance_days Non-negative integer. Maximum absolute deviation (in
#'   calendar days) from the group modal date that is still considered
#'   acceptable. Default `7` (one week). Set to `0` to flag any date that
#'   differs from the exact mode.
#' @param min_group_size Positive integer. Groups with fewer rows than this are
#'   skipped (all flagged as `NA`). Useful when a wave genuinely has only 1-2
#'   calls. Default `3`.
#' @param flag_col Character scalar. Name of the logical flag column to add.
#'   Default `"date_flag"`.
#' @param expected_col Character scalar. Name of the column that records the
#'   group modal date. Default `"expected_date"`.
#'
#' @return `data` with two new columns appended:
#' \describe{
#'   \item{`<flag_col>`}{Logical. `TRUE` if the row's date is more than
#'     `tolerance_days` away from the group modal date; `FALSE` otherwise;
#'     `NA` if the group was too small to evaluate.}
#'   \item{`<expected_col>`}{Date. The modal date for the row's group (or
#'     `NA` for small groups).}
#' }
#'
#' @section Interpreting output:
#' ```r
#' out <- mysterycall_flag_date_outliers(df, "call_date", group_col = "wave")
#' out[out$date_flag %in% TRUE, c("wave", "call_date", "expected_date")]
#' ```
#' Rows where `date_flag == TRUE` should be reviewed against the original
#' call logs. Common causes: month transposition (06 vs 07), year rollover
#' (Dec vs Jan), or a genuine make-up call placed weeks later.
#'
#' @importFrom stats median
#' @family data-quality
#' @seealso [mysterycall_check_normality()], [mysterycall_preflight_check()]
#' @export
#'
#' @examples
#' df <- data.frame(
#'   wave      = c(rep("A", 10), rep("B", 10)),
#'   call_date = as.Date(c(
#'     rep("2025-06-17", 9), "2025-07-17",   # wave A: 9 correct, 1 fat-finger
#'     rep("2025-09-03", 10)                 # wave B: all correct
#'   )),
#'   stringsAsFactors = FALSE
#' )
#' out <- mysterycall_flag_date_outliers(df, "call_date", group_col = "wave")
#' out[, c("wave", "call_date", "expected_date", "date_flag")]
mysterycall_flag_date_outliers <- function(data,
                                           date_col,
                                           group_col      = NULL,
                                           tolerance_days = 7L,
                                           min_group_size = 3L,
                                           flag_col       = "date_flag",
                                           expected_col   = "expected_date") {

  # ---- input validation -------------------------------------------------------
  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (!is.character(date_col) || length(date_col) != 1L || !nzchar(date_col))
    stop("`date_col` must be a single non-empty string.", call. = FALSE)
  if (!date_col %in% names(data))
    stop(sprintf("Column '%s' not found in `data`.\nAvailable columns: %s",
                 date_col, paste(names(data), collapse = ", ")), call. = FALSE)
  if (!is.null(group_col)) {
    if (!is.character(group_col) || length(group_col) != 1L || !nzchar(group_col))
      stop("`group_col` must be a single non-empty string or NULL.", call. = FALSE)
    if (!group_col %in% names(data))
      stop(sprintf("Column '%s' not found in `data`.\nAvailable columns: %s",
                   group_col, paste(names(data), collapse = ", ")), call. = FALSE)
  }
  if (!is.numeric(tolerance_days) || length(tolerance_days) != 1L ||
      tolerance_days < 0 || is.na(tolerance_days))
    stop("`tolerance_days` must be a single non-negative number.", call. = FALSE)
  if (!is.numeric(min_group_size) || length(min_group_size) != 1L ||
      min_group_size < 1L || is.na(min_group_size))
    stop("`min_group_size` must be a single positive integer.", call. = FALSE)
  if (flag_col %in% names(data))
    warning(sprintf("Column '%s' already exists and will be overwritten.", flag_col),
            call. = FALSE)
  if (expected_col %in% names(data))
    warning(sprintf("Column '%s' already exists and will be overwritten.", expected_col),
            call. = FALSE)

  # ---- coerce date column -----------------------------------------------------
  raw <- data[[date_col]]
  dates <- tryCatch(
    as.Date(raw),
    error = function(e)
      stop(sprintf("Cannot coerce '%s' to Date: %s", date_col, e$message),
           call. = FALSE)
  )
  n_na_orig <- sum(is.na(raw))
  n_na_post <- sum(is.na(dates))
  if (n_na_post > n_na_orig)
    warning(sprintf(
      "%d value(s) in '%s' could not be parsed as a Date and were set to NA.",
      n_na_post - n_na_orig, date_col
    ), call. = FALSE)

  # ---- helper: modal date for a vector of dates -------------------------------
  .modal_date <- function(d) {
    d_valid <- d[!is.na(d)]
    if (!length(d_valid)) return(as.Date(NA))
    tbl <- sort(table(as.character(d_valid)), decreasing = TRUE)
    as.Date(names(tbl)[[1L]])
  }

  # ---- compute flags ----------------------------------------------------------
  flag_vec     <- rep(NA, nrow(data))
  expected_vec <- rep(as.Date(NA), nrow(data))

  groups <- if (is.null(group_col)) {
    list(seq_len(nrow(data)))
  } else {
    split(seq_len(nrow(data)), data[[group_col]], drop = TRUE)
  }

  for (idx in groups) {
    g_dates <- dates[idx]
    n_valid <- sum(!is.na(g_dates))

    if (length(idx) < min_group_size || n_valid < min_group_size) {
      next  # leave NA
    }

    modal_d <- .modal_date(g_dates)
    expected_vec[idx] <- modal_d

    deviation <- abs(as.numeric(g_dates - modal_d))  # NA stays NA
    flag_vec[idx] <- deviation > tolerance_days
  }

  # ---- attach columns ---------------------------------------------------------
  data[[flag_col]]     <- as.logical(flag_vec)
  data[[expected_col]] <- expected_vec

  # ---- summary message --------------------------------------------------------
  n_flagged <- sum(data[[flag_col]] %in% TRUE)
  n_skipped <- sum(is.na(data[[flag_col]]))

  if (n_flagged > 0L) {
    message(sprintf(
      paste0(
        "mysterycall_flag_date_outliers: %d row(s) flagged as date outliers ",
        "(>%d days from group modal date); %d row(s) skipped (group too small). ",
        "Review `$%s == TRUE`."
      ),
      n_flagged, tolerance_days, n_skipped, flag_col
    ))
  } else {
    message(sprintf(
      "mysterycall_flag_date_outliers: no date outliers detected (tolerance %d days). %d row(s) skipped.",
      tolerance_days, n_skipped
    ))
  }

  data
}
