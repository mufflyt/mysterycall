#' Summarise call-level exclusions into a manuscript-ready paragraph
#'
#' @name mysterycall_exclusion_summary
NULL

#' Summarise call-level exclusions into a manuscript-ready paragraph
#'
#' Automates the computation and prose formatting of an exclusion paragraph
#' from a mystery-caller dataset that contains a column recording the outcome
#' (included vs. a reason for exclusion) for each call attempt. The function
#' mirrors the manual paragraph construction used in ortho sports-medicine
#' mystery-caller Rmd reports (lines 1033-1081) and generalises it for any
#' study design.
#'
#' **Semantic grouping of the six built-in exclusion keys:**
#' \itemize{
#'   \item *Unsuccessful connections* (could not reach anyone):
#'     `phone_not_answered`, `voicemail`, `wrong_number`.
#'   \item *Reached but excluded*:
#'     `referral_required`, `not_accepting`, `on_hold`.
#' }
#' Calls that match `inclusion_value` are counted as *included*. Any row
#' that does not match `inclusion_value` or any value in
#' `exclusion_categories` is silently classified as unrecognised and
#' contributes to the denominator but not to any named exclusion bucket.
#'
#' @param data data.frame. The **full** dataset including all excluded rows.
#'   Must have at least one column whose name matches `exclusion_col`.
#' @param exclusion_col Character scalar. Name of the column that holds the
#'   outcome or reason-for-exclusion value for each call.
#'   Default `"reason_for_exclusions"`.
#' @param inclusion_value Character scalar. The value in `exclusion_col` that
#'   identifies a call that was successfully completed and is included in the
#'   analysis. Default `"Able to contact"`.
#' @param exclusion_categories Named character vector mapping semantic group
#'   names to the exact string values found in `exclusion_col`. The vector
#'   must contain **all six** of the following keys (values may be overridden):
#'   \describe{
#'     \item{`phone_not_answered`}{Unsuccessful: phone not answered / busy signal.}
#'     \item{`voicemail`}{Unsuccessful: call went to voicemail.}
#'     \item{`wrong_number`}{Unsuccessful: number did not reach the expected office.}
#'     \item{`referral_required`}{Reached but excluded: physician referral required.}
#'     \item{`not_accepting`}{Reached but excluded: office not accepting new patients.}
#'     \item{`on_hold`}{Reached but excluded: caller placed on hold > 5 minutes.}
#'   }
#' @param id_col Character scalar or `NULL`. When non-`NULL`, `data` is
#'   deduplicated by this column before all counting so that repeated call
#'   attempts to the same provider collapse to one record.
#'   Default `NULL` (no deduplication).
#'
#' @return A list of class `mysterycall_exclusion_summary` containing:
#'   \describe{
#'     \item{`total`}{Integer. Total calls (or unique IDs when `id_col` is
#'       non-`NULL`).}
#'     \item{`n_reached`}{Integer. Calls successfully connected (not in the
#'       unreachable group).}
#'     \item{`n_unreachable`}{Integer. Calls in the unreachable group
#'       (phone not answered + voicemail + wrong number).}
#'     \item{`pct_reached`}{Numeric. `n_reached / total * 100`, or `NA` when
#'       `total` is zero.}
#'     \item{`n_included`}{Integer. Calls included in the final analysis
#'       (`n_reached` minus reached-but-excluded calls).}
#'     \item{`counts`}{Named integer vector. Count for each of the six
#'       canonical exclusion-category keys.}
#'     \item{`percentages`}{Named numeric vector. `counts / total * 100`, or
#'       `NA` for each element when `total` is zero.}
#'     \item{`paragraph`}{Character scalar. Full exclusion paragraph ready to
#'       paste into a manuscript Methods or Results section.}
#'     \item{`table`}{data.frame. Tabyl-style summary with columns
#'       `category` (key name), `label` (human-readable value), `n` (integer
#'       count), and `pct` (numeric percentage of total).}
#'   }
#'
#' @family reporting
#' @seealso [mysterycall_strobe_flow()], [mysterycall_flag_date_outliers()]
#' @export
#'
#' @examples
#' ## --- minimal runnable example (base R only) -------------------------------
#' reasons <- c(
#'   "Able to contact",
#'   "Phone not answered or busy signal on repeat calls",
#'   "Went to voicemail",
#'   "Number contacted did not correspond to expected office/specialty",
#'   "Physician referral required before scheduling appointment",
#'   "Not accepting new patients",
#'   "Greater than 5 minutes on hold"
#' )
#' n_each <- c(120L, 40L, 30L, 10L, 15L, 20L, 5L)
#'
#' df <- data.frame(
#'   call_id               = seq_len(sum(n_each)),
#'   reason_for_exclusions = rep(reasons, n_each),
#'   stringsAsFactors      = FALSE
#' )
#'
#' result <- mysterycall_exclusion_summary(df)
#' print(result)       # prints the prose paragraph
#' result$table        # tabyl-style counts
#'
#' ## --- custom exclusion values (different study coding scheme) --------------
#' df2 <- df
#' names(df2)[2] <- "call_outcome"
#' result2 <- mysterycall_exclusion_summary(
#'   data          = df2,
#'   exclusion_col = "call_outcome",
#'   inclusion_value = "Able to contact",
#'   exclusion_categories = c(
#'     phone_not_answered = "Phone not answered or busy signal on repeat calls",
#'     voicemail          = "Went to voicemail",
#'     wrong_number       = "Number contacted did not correspond to expected office/specialty",
#'     referral_required  = "Physician referral required before scheduling appointment",
#'     not_accepting      = "Not accepting new patients",
#'     on_hold            = "Greater than 5 minutes on hold"
#'   )
#' )
#' cat(result2$paragraph)
#'
#' ## --- deduplicate by provider before counting ------------------------------
#' df3 <- df
#' df3$npi <- c(
#'   seq_len(120L),                  # included (unique)
#'   rep(121L, 40L),                 # one provider, 40 no-answer attempts
#'   122L + seq_len(sum(n_each[-c(1L, 2L)]) - 1L)  # remaining
#' )
#' # id_col collapses repeated dials to the same NPI
#' result3 <- mysterycall_exclusion_summary(df3, id_col = "npi")
#' result3$total   # unique providers, not raw call rows
mysterycall_exclusion_summary <- function(
    data,
    exclusion_col        = "reason_for_exclusions",
    inclusion_value      = "Able to contact",
    exclusion_categories = c(
      phone_not_answered = "Phone not answered or busy signal on repeat calls",
      voicemail          = "Went to voicemail",
      wrong_number       = "Number contacted did not correspond to expected office/specialty",
      referral_required  = "Physician referral required before scheduling appointment",
      not_accepting      = "Not accepting new patients",
      on_hold            = "Greater than 5 minutes on hold"
    ),
    id_col = NULL
) {
  ## --------------------------------------------------------------------------
  ## 1. Input validation
  ## --------------------------------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!is.character(exclusion_col) ||
      length(exclusion_col) != 1L  ||
      !nzchar(exclusion_col)) {
    stop("`exclusion_col` must be a single non-empty character string.",
         call. = FALSE)
  }
  if (!exclusion_col %in% names(data)) {
    stop(
      sprintf(
        "Column '%s' not found in `data`. Available columns: %s",
        exclusion_col,
        paste(names(data), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (!is.character(inclusion_value) || length(inclusion_value) != 1L) {
    stop("`inclusion_value` must be a single character string.", call. = FALSE)
  }
  if (!is.character(exclusion_categories) ||
      is.null(names(exclusion_categories)) ||
      any(!nzchar(names(exclusion_categories)))) {
    stop("`exclusion_categories` must be a named character vector with non-empty names.",
         call. = FALSE)
  }

  required_keys <- c(
    "phone_not_answered", "voicemail", "wrong_number",
    "referral_required",  "not_accepting", "on_hold"
  )
  missing_keys <- setdiff(required_keys, names(exclusion_categories))
  if (length(missing_keys) > 0L) {
    stop(
      sprintf(
        "`exclusion_categories` is missing required key(s): %s",
        paste(missing_keys, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  if (!is.null(id_col)) {
    if (!is.character(id_col) || length(id_col) != 1L || !nzchar(id_col)) {
      stop("`id_col` must be a single non-empty character string or NULL.",
           call. = FALSE)
    }
    if (!id_col %in% names(data)) {
      stop(
        sprintf("Column '%s' (id_col) not found in `data`.", id_col),
        call. = FALSE
      )
    }
  }

  ## --------------------------------------------------------------------------
  ## 2. Optional deduplication
  ## --------------------------------------------------------------------------
  if (!is.null(id_col)) {
    data <- data[!duplicated(data[[id_col]]), , drop = FALSE]
  }

  total   <- nrow(data)
  col_vec <- as.character(data[[exclusion_col]])

  if (total == 0L) {
    warning("`data` has zero rows after deduplication.", call. = FALSE)
  }

  ## --------------------------------------------------------------------------
  ## 3. Count each exclusion category
  ## --------------------------------------------------------------------------
  counts <- vapply(
    required_keys,
    FUN       = function(k) sum(col_vec == exclusion_categories[[k]], na.rm = TRUE),
    FUN.VALUE = integer(1L)
  )
  names(counts) <- required_keys

  ## --------------------------------------------------------------------------
  ## 4. Derive summary statistics
  ## --------------------------------------------------------------------------
  unreachable_keys     <- c("phone_not_answered", "voicemail", "wrong_number")
  reached_excl_keys    <- c("referral_required", "not_accepting", "on_hold")

  n_unreachable            <- sum(counts[unreachable_keys])
  n_reached                <- total - n_unreachable
  n_excluded_among_reached <- sum(counts[reached_excl_keys])
  n_included               <- n_reached - n_excluded_among_reached

  pct_reached <- if (total > 0L) n_reached  / total * 100 else NA_real_
  percentages <- if (total > 0L) {
    counts / total * 100
  } else {
    stats::setNames(rep(NA_real_, length(counts)), required_keys)
  }

  ## --------------------------------------------------------------------------
  ## 5. Prose paragraph
  ## --------------------------------------------------------------------------
  paragraph <- .build_exclusion_paragraph(
    total                    = total,
    n_unreachable            = n_unreachable,
    n_reached                = n_reached,
    n_included               = n_included,
    counts                   = counts,
    pct_reached              = pct_reached
  )

  ## --------------------------------------------------------------------------
  ## 6. Tabyl-style table  (included row + each exclusion category)
  ## --------------------------------------------------------------------------
  all_keys   <- c("included", required_keys)
  all_labels <- c(
    "Included in analysis",
    unname(exclusion_categories[required_keys])
  )
  all_counts <- c(as.integer(n_included), counts)

  tbl <- data.frame(
    category = all_keys,
    label    = all_labels,
    n        = as.integer(all_counts),
    pct      = if (total > 0L) {
      as.numeric(all_counts) / total * 100
    } else {
      rep(NA_real_, length(all_keys))
    },
    stringsAsFactors = FALSE,
    row.names        = NULL
  )

  ## --------------------------------------------------------------------------
  ## 7. Return
  ## --------------------------------------------------------------------------
  structure(
    list(
      total         = as.integer(total),
      n_reached     = as.integer(n_reached),
      n_unreachable = as.integer(n_unreachable),
      pct_reached   = pct_reached,
      n_included    = as.integer(n_included),
      counts        = counts,
      percentages   = percentages,
      paragraph     = paragraph,
      table         = tbl
    ),
    class = "mysterycall_exclusion_summary"
  )
}


## ---------------------------------------------------------------------------
## Internal helper: build the prose paragraph
## ---------------------------------------------------------------------------
.build_exclusion_paragraph <- function(total,
                                       n_unreachable,
                                       n_reached,
                                       n_included,
                                       counts,
                                       pct_reached) {
  fmt_n   <- function(x) formatC(as.integer(x), format = "d", big.mark = ",")
  fmt_pct <- function(x) {
    if (is.na(x)) return("NA")
    formatC(as.numeric(x), format = "f", digits = 1)
  }

  pct_unreachable <- if (total > 0L) n_unreachable / total * 100 else NA_real_
  pct_included    <- if (total > 0L) n_included    / total * 100 else NA_real_

  sprintf(
    paste0(
      "A total of %s phone calls were made. ",
      "Of these, %s (%s%%) calls were unsuccessful connections, ",
      "including calls in which the phone was not answered or the caller received ",
      "a busy signal (n = %s), calls that went to voicemail (n = %s), ",
      "and calls for which the number reached did not correspond to the expected ",
      "office or specialty (n = %s). ",
      "The remaining %s (%s%%) calls resulted in a successful connection with ",
      "office staff. ",
      "Among successfully connected calls, %s offices required a physician referral ",
      "before an appointment could be scheduled, %s offices were not accepting new ",
      "patients, and %s calls were placed on hold for more than 5 minutes. ",
      "After applying all exclusion criteria, %s (%s%%) calls were included in the ",
      "final analysis."
    ),
    fmt_n(total),
    fmt_n(n_unreachable),              fmt_pct(pct_unreachable),
    fmt_n(counts[["phone_not_answered"]]),
    fmt_n(counts[["voicemail"]]),
    fmt_n(counts[["wrong_number"]]),
    fmt_n(n_reached),                  fmt_pct(pct_reached),
    fmt_n(counts[["referral_required"]]),
    fmt_n(counts[["not_accepting"]]),
    fmt_n(counts[["on_hold"]]),
    fmt_n(n_included),                 fmt_pct(pct_included)
  )
}


#' @export
print.mysterycall_exclusion_summary <- function(x, ...) {
  cat(x$paragraph, "\n")
  invisible(x)
}
