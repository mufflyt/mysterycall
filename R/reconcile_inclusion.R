#' Crosswalk between REDCap integer exclusion codes and label strings
#'
#' @name mysterycall_reconcile_inclusion
NULL

#' Canonical exclusion-code / label-string crosswalk
#'
#' The package contains two inclusion conventions that evolved independently:
#'
#' \itemize{
#'   \item the **integer-code path** ([mysterycall_prepare_calls()],
#'     [mysterycall_strobe_flow()]) derives samples from an integer
#'     `exclusions` column on the *raw* REDCap export; and
#'   \item the **label-string path** ([mysterycall_exclusion_summary()],
#'     [mysterycall_acceptance_rate_calc()],
#'     [mysterycall_insurance_acceptance_rates()], and the workflow runners)
#'     derives samples from a `reason_for_exclusions` string column on the
#'     *cleaned* export, treating `"Able to contact"` as the included set.
#' }
#'
#' The two paths do **not** define the same included set. This function returns
#' the mapping between them as data, so the divergence is inspectable rather
#' than implicit. It is the single source of truth used by
#' [mysterycall_reconcile_inclusion()].
#'
#' @section The key divergence:
#' The integer logistic set (`logistic_include_codes`, default
#' `c(0, 7, 9, 10)`) keeps codes 7 (referral required), 9 (not accepting new
#' patients), and 10 (must see midlevel first) as *included* calls with an
#' appointment-not-offered outcome. The label path classifies those same calls
#' as **exclusions** — they are never `"Able to contact"`. Rows where
#' `in_logistic` is `TRUE` but `label_included` is `FALSE` are exactly that gap.
#'
#' @param inclusion_value Character scalar. The `reason_for_exclusions` value
#'   the label path treats as included. Default `"Able to contact"`.
#' @param logistic_include_codes Integer vector. Exclusion codes the integer
#'   path includes in the logistic dataset. Default `c(0L, 7L, 9L, 10L)` -
#'   matches [mysterycall_prepare_calls()].
#'
#' @return A [tibble::tibble()], one row per known exclusion code, with columns:
#' \describe{
#'   \item{`code`}{Integer exclusion code (as used by
#'     [mysterycall_prepare_calls()]).}
#'   \item{`code_label`}{Human-readable label for the integer code.}
#'   \item{`label_category`}{Semantic key from
#'     [mysterycall_exclusion_summary()]'s `exclusion_categories`, or `NA` for
#'     codes with no label-path category (`included`, or codes the label path
#'     does not bucket).}
#'   \item{`label_string`}{Default `reason_for_exclusions` string the label
#'     path expects for this code, or `NA` where none exists.}
#'   \item{`reached`}{Logical. Was the office reached? (Distinguishes
#'     reached-but-excluded codes from unreachable ones.)}
#'   \item{`in_logistic`}{Logical. Integer path includes this code in the
#'     logistic (appointment-offered) dataset.}
#'   \item{`in_waittime`}{Logical. Integer path includes this code in the
#'     wait-time dataset (code 0 only).}
#'   \item{`label_included`}{Logical. Label path counts this code as included
#'     (`"Able to contact"`, i.e. code 0 only).}
#' }
#'
#' @seealso [mysterycall_reconcile_inclusion()],
#'   [mysterycall_prepare_calls()], [mysterycall_exclusion_summary()]
#' @family data-preparation
#' @export
#'
#' @examples
#' cw <- mysterycall_exclusion_crosswalk()
#' # The three codes where the two inclusion definitions disagree:
#' cw[cw$in_logistic & !cw$label_included, c("code", "code_label")]
mysterycall_exclusion_crosswalk <- function(
    inclusion_value        = "Able to contact",
    logistic_include_codes = c(0L, 7L, 9L, 10L)) {

  if (!is.character(inclusion_value) || length(inclusion_value) != 1L ||
      !nzchar(inclusion_value))
    stop("`inclusion_value` must be a single non-empty string.", call. = FALSE)
  logistic_include_codes <- as.integer(logistic_include_codes)
  if (anyNA(logistic_include_codes))
    stop("`logistic_include_codes` must be coercible to integer without NA.",
         call. = FALSE)

  cw <- data.frame(
    code       = c(0L, 1L, 2L, 3L, 5L, 6L, 7L, 8L, 9L, 10L),
    code_label = c(
      "Included",
      "Closed medical system",
      ">5 min on hold",
      "Wrong number/office",
      "Phone not answered/busy",
      "Physician's personal phone",
      "Referral required",
      "Voicemail",
      "Not accepting new patients",
      "Must see midlevel first"
    ),
    label_category = c(
      "included",
      NA_character_,
      "on_hold",
      "wrong_number",
      "phone_not_answered",
      NA_character_,
      "referral_required",
      "voicemail",
      "not_accepting",
      NA_character_
    ),
    label_string = c(
      inclusion_value,
      NA_character_,
      "Greater than 5 minutes on hold",
      "Number contacted did not correspond to expected office/specialty",
      "Phone not answered or busy signal on repeat calls",
      NA_character_,
      "Physician referral required before scheduling appointment",
      "Went to voicemail",
      "Not accepting new patients",
      NA_character_
    ),
    reached = c(
      TRUE,   # 0  included
      FALSE,  # 1  closed system
      TRUE,   # 2  on hold (reached, then excluded)
      FALSE,  # 3  wrong number
      FALSE,  # 5  no answer
      FALSE,  # 6  personal phone
      TRUE,   # 7  referral required (reached)
      FALSE,  # 8  voicemail
      TRUE,   # 9  not accepting (reached)
      TRUE    # 10 midlevel first (reached)
    ),
    stringsAsFactors = FALSE
  )

  cw$in_logistic    <- cw$code %in% logistic_include_codes
  cw$in_waittime    <- cw$code == 0L
  cw$label_included <- cw$code == 0L

  tibble::as_tibble(cw)
}


#' Reconcile the integer-code and label-string inclusion definitions
#'
#' Compares, record by record, whether the integer-code path and the
#' label-string path agree on inclusion, and surfaces exactly where they
#' disagree. This is a **diagnostic only** - it changes no data and picks no
#' winner. Use it to confirm (against real data) whether swapping the current
#' label-based scripts to [mysterycall_prepare_calls()] would change the
#' analytic sample, before committing to that consolidation.
#'
#' The data frame must carry **both** keys on the same rows: the integer
#' `exclusions` code (from the raw export) and the `reason_for_exclusions`
#' string (from the cleaned export). Reconciliation is the one scenario where
#' you have both.
#'
#' @param data A data frame containing both `code_col` and `label_col`.
#' @param code_col Character scalar. Integer exclusion-code column.
#'   Default `"exclusions"`.
#' @param label_col Character scalar. Label-string column.
#'   Default `"reason_for_exclusions"`.
#' @param id_col Character scalar or `NULL`. Record identifier carried into the
#'   discrepancy table for follow-up. Default `NULL`.
#' @param set Which inclusion set to reconcile. `"logistic"` (default) compares
#'   the integer logistic set (`logistic_include_codes`) against the label
#'   included set - this is where the paths diverge. `"waittime"` compares the
#'   integer wait-time set (code 0) against the label included set, which are
#'   expected to agree.
#' @param inclusion_value Character scalar. Label value treated as included.
#'   Default `"Able to contact"`.
#' @param logistic_include_codes Integer vector forwarded to
#'   [mysterycall_exclusion_crosswalk()]. Default `c(0L, 7L, 9L, 10L)`.
#' @param crosswalk A crosswalk tibble from
#'   [mysterycall_exclusion_crosswalk()]. Built from `inclusion_value` and
#'   `logistic_include_codes` when not supplied.
#'
#' @return A list of class `mysterycall_reconciliation` with elements:
#' \describe{
#'   \item{`set`}{The set reconciled (`"logistic"` or `"waittime"`).}
#'   \item{`n`}{Total rows compared.}
#'   \item{`n_agree`}{Rows where both paths agree (both include or both
#'     exclude).}
#'   \item{`n_disagree`}{Rows where the paths disagree.}
#'   \item{`agree_rate`}{`n_agree / n`.}
#'   \item{`discrepancies`}{Data frame of the disagreeing rows, with
#'     `disagreement_type` (`"code_only"` = integer path includes, label path
#'     excludes; `"label_only"` = the reverse), both keys, the code label, and
#'     `id_col` when supplied.}
#'   \item{`by_code`}{Data frame: for each integer code, how many rows the
#'     label path counted as included vs excluded, and whether that matches
#'     the crosswalk expectation.}
#'   \item{`label_mismatches`}{Data frame of rows whose `label_col` string is
#'     inconsistent with the crosswalk's expected string for their integer
#'     code (a data-entry integrity check independent of inclusion). `NULL`
#'     when none.}
#'   \item{`crosswalk`}{The crosswalk used.}
#' }
#'
#' @seealso [mysterycall_exclusion_crosswalk()],
#'   [mysterycall_prepare_calls()], [mysterycall_acceptance_rate_calc()]
#' @family data-preparation
#' @export
#'
#' @examples
#' df <- data.frame(
#'   id                    = 1:6,
#'   exclusions            = c(0L, 0L, 9L, 7L, 5L, 10L),
#'   reason_for_exclusions = c(
#'     "Able to contact", "Able to contact",
#'     "Not accepting new patients",
#'     "Physician referral required before scheduling appointment",
#'     "Phone not answered or busy signal on repeat calls",
#'     "Must see midlevel first"
#'   ),
#'   stringsAsFactors = FALSE
#' )
#' rec <- mysterycall_reconcile_inclusion(df, id_col = "id")
#' rec
#' # Codes 9, 7, 10 are the divergence: integer-logistic includes them,
#' # the label path does not.
#' rec$discrepancies
mysterycall_reconcile_inclusion <- function(
    data,
    code_col               = "exclusions",
    label_col              = "reason_for_exclusions",
    id_col                 = NULL,
    set                    = c("logistic", "waittime"),
    inclusion_value        = "Able to contact",
    logistic_include_codes = c(0L, 7L, 9L, 10L),
    crosswalk              = NULL) {

  # ---- validation -------------------------------------------------------------
  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  set <- match.arg(set)
  for (nm in c("code_col", "label_col")) {
    v <- get(nm)
    if (!is.character(v) || length(v) != 1L || !nzchar(v))
      stop(sprintf("`%s` must be a single non-empty string.", nm), call. = FALSE)
  }
  miss <- setdiff(c(code_col, label_col), names(data))
  if (length(miss))
    stop(sprintf("Column(s) not found in `data`: %s\nAvailable: %s",
                 paste(miss, collapse = ", "),
                 paste(names(data), collapse = ", ")), call. = FALSE)
  if (!is.null(id_col)) {
    if (!is.character(id_col) || length(id_col) != 1L || !nzchar(id_col))
      stop("`id_col` must be a single non-empty string or NULL.", call. = FALSE)
    if (!id_col %in% names(data))
      stop(sprintf("`id_col` '%s' not found in `data`.", id_col), call. = FALSE)
  }
  if (is.null(crosswalk))
    crosswalk <- mysterycall_exclusion_crosswalk(
      inclusion_value        = inclusion_value,
      logistic_include_codes = logistic_include_codes)

  # ---- derive the two inclusion decisions ------------------------------------
  code  <- suppressWarnings(as.integer(data[[code_col]]))
  label <- trimws(as.character(data[[label_col]]))

  n_bad_code <- sum(is.na(code) & !is.na(data[[code_col]]))
  if (n_bad_code > 0L)
    warning(sprintf(
      "%d value(s) in '%s' could not be coerced to integer and are treated as excluded.",
      n_bad_code, code_col), call. = FALSE)

  include_codes <- if (identical(set, "logistic")) {
    crosswalk$code[crosswalk$in_logistic]
  } else {
    crosswalk$code[crosswalk$in_waittime]
  }

  included_by_code  <- !is.na(code) & code %in% include_codes
  included_by_label <- !is.na(label) & label == inclusion_value

  agree     <- included_by_code == included_by_label
  disagree  <- !agree

  # ---- discrepancy table ------------------------------------------------------
  code_label_vec <- crosswalk$code_label[match(code, crosswalk$code)]
  disc_type <- ifelse(
    included_by_code & !included_by_label, "code_only",
    ifelse(!included_by_code & included_by_label, "label_only", NA_character_)
  )

  disc <- data.frame(
    stringsAsFactors = FALSE,
    disagreement_type = disc_type,
    code              = code,
    code_label        = code_label_vec,
    label             = label,
    included_by_code  = included_by_code,
    included_by_label = included_by_label
  )
  if (!is.null(id_col)) disc <- cbind(data[id_col], disc)
  discrepancies <- disc[disagree, , drop = FALSE]
  rownames(discrepancies) <- NULL

  # ---- per-code breakdown -----------------------------------------------------
  codes_present <- sort(unique(code[!is.na(code)]))
  by_code <- do.call(rbind, lapply(codes_present, function(cc) {
    rows <- !is.na(code) & code == cc
    cw_i <- match(cc, crosswalk$code)
    expected <- if (is.na(cw_i)) NA else crosswalk$label_included[cw_i]
    data.frame(
      stringsAsFactors = FALSE,
      code                 = cc,
      code_label           = if (is.na(cw_i)) NA_character_ else crosswalk$code_label[cw_i],
      n                    = sum(rows),
      n_label_included     = sum(rows & included_by_label),
      n_label_excluded     = sum(rows & !included_by_label),
      crosswalk_included   = expected
    )
  }))

  # ---- label-vs-code integrity check -----------------------------------------
  expected_string <- crosswalk$label_string[match(code, crosswalk$code)]
  mismatch <- !is.na(code) & !is.na(expected_string) &
    !is.na(label) & nzchar(label) & label != expected_string
  label_mismatches <- if (any(mismatch)) {
    lm <- data.frame(
      stringsAsFactors = FALSE,
      code             = code[mismatch],
      code_label       = code_label_vec[mismatch],
      expected_label   = expected_string[mismatch],
      actual_label     = label[mismatch]
    )
    if (!is.null(id_col)) lm <- cbind(data[id_col][mismatch, , drop = FALSE], lm)
    rownames(lm) <- NULL
    lm
  } else NULL

  n            <- nrow(data)
  n_disagree   <- sum(disagree)
  n_agree      <- n - n_disagree

  message(sprintf(
    "mysterycall_reconcile_inclusion [%s]: %d/%d rows agree (%.1f%%); %d disagree%s.",
    set, n_agree, n, if (n) n_agree / n * 100 else NA_real_, n_disagree,
    if (n_disagree > 0L) sprintf(
      " (%d code_only, %d label_only)",
      sum(disc_type == "code_only", na.rm = TRUE),
      sum(disc_type == "label_only", na.rm = TRUE)) else ""
  ))

  structure(
    list(
      set              = set,
      n                = n,
      n_agree          = n_agree,
      n_disagree       = n_disagree,
      agree_rate       = if (n) n_agree / n else NA_real_,
      discrepancies    = discrepancies,
      by_code          = by_code,
      label_mismatches = label_mismatches,
      crosswalk        = crosswalk
    ),
    class = "mysterycall_reconciliation"
  )
}


#' Print method for mysterycall_reconciliation objects
#'
#' @param x A `mysterycall_reconciliation` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family data-preparation
#' @export
print.mysterycall_reconciliation <- function(x, ...) {
  cat(sprintf("=== Inclusion Reconciliation [%s set] ===\n\n", x$set))
  cat(sprintf("Rows compared:  %d\n", x$n))
  cat(sprintf("Agree:          %d (%.1f%%)\n", x$n_agree,
              if (x$n) x$agree_rate * 100 else NA_real_))
  cat(sprintf("Disagree:       %d\n", x$n_disagree))

  if (x$n_disagree > 0L) {
    n_code  <- sum(x$discrepancies$disagreement_type == "code_only")
    n_label <- sum(x$discrepancies$disagreement_type == "label_only")
    cat(sprintf("  code_only  (integer includes, label excludes): %d\n", n_code))
    cat(sprintf("  label_only (label includes, integer excludes): %d\n", n_label))
    cat("\n-- Discrepancies (first 10) --\n")
    print(utils::head(x$discrepancies, 10L), row.names = FALSE)
  } else {
    cat("\nThe two inclusion definitions agree on every row.\n")
  }

  cat("\n-- Per-code label classification --\n")
  print(x$by_code, row.names = FALSE)

  if (!is.null(x$label_mismatches)) {
    cat(sprintf(
      "\nWARNING: %d row(s) have a label string inconsistent with their integer code.\n  Inspect `$label_mismatches`.\n",
      nrow(x$label_mismatches)))
  }

  invisible(x)
}
