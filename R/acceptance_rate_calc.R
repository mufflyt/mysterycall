#' Rigorous Three-Part Acceptance Rate Calculator
#'
#' Implements the three-part formula used in orthopaedic sports medicine
#' mystery-caller audit studies:
#'
#' \strong{Numerator} -- distinct physicians (by `id_col`) who:
#' \enumerate{
#'   \item Are assigned to `insurance_groups` level X.
#'   \item Have `inclusion_col == inclusion_value` (successfully contacted).
#'   \item Have `wait_col > 0` (offered a real appointment), when `wait_col`
#'     is not `NULL`.
#'   \item Are not `NA` in `medicaid_accept_col`, when `medicaid_accept_col`
#'     is not `NULL` (explicitly recorded Medicaid acceptance status).
#' }
#'
#' \strong{Denominator} -- distinct physicians assigned to insurance X
#' (\code{total_assigned}) minus those who were unreachable
#' (\code{inclusion_col != inclusion_value}).
#'
#' \strong{Rate} -- Numerator / Denominator, with Wilson score confidence
#' intervals.
#'
#' @section Deduplication:
#' All counts deduplicate on `id_col` via `unique()`.  Each physician is
#' expected to appear at most once per insurance group; the deduplication step
#' is a safeguard against duplicate call rows.  A physician who has both a
#' reachable and an unreachable row for the same insurance group will be
#' counted in \emph{both} the total and the excluded sets, which may
#' undercount the denominator.  Clean data with one row per physician per
#' insurance group will not be affected.
#'
#' @param data data.frame containing at least the columns named by
#'   `insurance_col`, `inclusion_col`, and `id_col`.
#' @param insurance_col Character scalar.  Name of the column recording
#'   insurance type.  Default `"insurance"`.
#' @param insurance_groups Character vector of insurance levels to evaluate
#'   (e.g. `c("Medicaid", "Blue Cross/Blue Shield")`).  When `NULL`
#'   (default), all unique non-`NA` values found in `insurance_col` are
#'   used in alphabetical order.
#' @param inclusion_col Character scalar.  Name of the column that records
#'   contact / exclusion status.  Rows equal to `inclusion_value` are
#'   considered successfully contacted.  Default `"reason_for_exclusions"`.
#' @param inclusion_value Character scalar.  The exact string in
#'   `inclusion_col` that means "successfully contacted".
#'   Default `"Able to contact"`.
#' @param wait_col Character scalar or `NULL`.  Name of a numeric column
#'   holding days to appointment.  When non-`NULL`, only rows with
#'   `wait_col > 0` contribute to the numerator (rows with `wait_col == 0`
#'   or `NA` are excluded from the numerator but not from the denominator).
#'   Default `"business_days_until_appointment"`.
#' @param id_col Character scalar.  Column used to deduplicate physicians
#'   (e.g. phone number or NPI).  Default `"phone"`.
#' @param medicaid_accept_col Character scalar or `NULL`.  When non-`NULL`,
#'   rows with `NA` in this column are excluded from the numerator.  Useful
#'   when a "Did you accept Medicaid?" field is present.  Default `NULL`.
#' @param conf_level Numeric scalar in (0, 1).  Confidence level for Wilson
#'   score intervals.  Default `0.95`.
#'
#' @return A list of class `"mysterycall_acceptance_rate_calc"` with four
#'   elements:
#'   \describe{
#'     \item{`table`}{`data.frame` with one row per insurance group.
#'       Columns: `insurance`, `n_total` (distinct IDs assigned to group),
#'       `n_excluded` (unreachable, distinct), `n_numerator` (accepting,
#'       distinct), `n_denominator` (reachable = total - excluded),
#'       `rate_pct` (acceptance rate as percentage), `ci_lower_pct`,
#'       `ci_upper_pct` (Wilson CI bounds as percentages), `sentence`
#'       (formatted result string).}
#'     \item{`overall`}{`data.frame` with one row combining all specified
#'       insurance groups.  `NULL` when only one group is evaluated.
#'       Same columns as `table`.}
#'     \item{`sentences`}{Character vector, one entry per insurance group,
#'       e.g. `"Medicaid acceptance rate: 209/371 = 56.3% (95% CI:
#'       51.2%-61.4%)"`.}
#'     \item{`gap_sentence`}{Character scalar describing the spread.  When
#'       exactly two groups are evaluated:
#'       `"Physicians accepted Medicaid at 56.3% vs BCBS at 82.4%, a gap of
#'       26.1 percentage points."` When three or more groups are evaluated,
#'       the sentence reports the min-to-max range.  `NA_character_` when
#'       fewer than two valid rates exist.}
#'   }
#'
#' @examples
#' set.seed(42)
#' n <- 80
#' df <- data.frame(
#'   phone     = paste0("555-", formatC(seq_len(n), width = 4, flag = "0")),
#'   insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = n / 2L),
#'   reason_for_exclusions = sample(
#'     c("Able to contact", "No answer", "Line disconnected"),
#'     n, replace = TRUE, prob = c(0.75, 0.15, 0.10)
#'   ),
#'   business_days_until_appointment = ifelse(
#'     stats::runif(n) > 0.3,
#'     sample(1:30, n, replace = TRUE),
#'     0L
#'   ),
#'   stringsAsFactors = FALSE
#' )
#'
#' ## Two-group comparison (Medicaid vs BCBS)
#' res <- mysterycall_acceptance_rate_calc(
#'   data             = df,
#'   insurance_groups = c("Medicaid", "Blue Cross/Blue Shield")
#' )
#' print(res)
#' res$table
#'
#' ## Without wait-time filter
#' res2 <- mysterycall_acceptance_rate_calc(
#'   data      = df,
#'   wait_col  = NULL
#' )
#' res2$sentences
#'
#' @importFrom stats prop.test
#' @family outcomes
#' @seealso [mysterycall_acceptance_rate()], [mysterycall_disparities_table()]
#' @export
mysterycall_acceptance_rate_calc <- function(
    data,
    insurance_col       = "insurance",
    insurance_groups    = NULL,
    inclusion_col       = "reason_for_exclusions",
    inclusion_value     = "Able to contact",
    wait_col            = "business_days_until_appointment",
    id_col              = "phone",
    medicaid_accept_col = NULL,
    conf_level          = 0.95
) {

  # ---- input validation ------------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }
  if (nrow(data) == 0L) {
    stop("`data` must contain at least one row.", call. = FALSE)
  }
  if (!is.character(insurance_col) || length(insurance_col) != 1L) {
    stop("`insurance_col` must be a single character string.", call. = FALSE)
  }
  if (!insurance_col %in% names(data)) {
    stop(sprintf(
      "insurance_col '%s' not found in `data`.\nAvailable columns: %s",
      insurance_col, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  }
  if (!is.character(inclusion_col) || length(inclusion_col) != 1L) {
    stop("`inclusion_col` must be a single character string.", call. = FALSE)
  }
  if (!inclusion_col %in% names(data)) {
    stop(sprintf(
      "inclusion_col '%s' not found in `data`.\nAvailable columns: %s",
      inclusion_col, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  }
  if (!is.character(inclusion_value) || length(inclusion_value) != 1L ||
      !nzchar(inclusion_value)) {
    stop("`inclusion_value` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.null(wait_col)) {
    if (!is.character(wait_col) || length(wait_col) != 1L) {
      stop("`wait_col` must be a single character string or NULL.", call. = FALSE)
    }
    if (!wait_col %in% names(data)) {
      stop(sprintf(
        "wait_col '%s' not found in `data`.\nAvailable columns: %s",
        wait_col, paste(names(data), collapse = ", ")
      ), call. = FALSE)
    }
    if (!is.numeric(data[[wait_col]])) {
      stop(
        sprintf(
          "Column '%s' must be numeric (days to appointment). ",
          wait_col
        ),
        call. = FALSE
      )
    }
  }
  if (!is.character(id_col) || length(id_col) != 1L) {
    stop("`id_col` must be a single character string.", call. = FALSE)
  }
  if (!id_col %in% names(data)) {
    stop(sprintf(
      "id_col '%s' not found in `data`.\nAvailable columns: %s",
      id_col, paste(names(data), collapse = ", ")
    ), call. = FALSE)
  }
  if (!is.null(medicaid_accept_col)) {
    if (!is.character(medicaid_accept_col) || length(medicaid_accept_col) != 1L) {
      stop("`medicaid_accept_col` must be a single character string or NULL.", call. = FALSE)
    }
    if (!medicaid_accept_col %in% names(data)) {
      stop(sprintf(
        "medicaid_accept_col '%s' not found in `data`.\nAvailable columns: %s",
        medicaid_accept_col, paste(names(data), collapse = ", ")
      ), call. = FALSE)
    }
  }
  if (!is.numeric(conf_level) || length(conf_level) != 1L ||
      conf_level <= 0 || conf_level >= 1) {
    stop("`conf_level` must be a single number strictly between 0 and 1.", call. = FALSE)
  }

  # ---- resolve insurance groups ----------------------------------------------
  ins_chr <- as.character(data[[insurance_col]])

  if (is.null(insurance_groups)) {
    insurance_groups <- sort(unique(ins_chr[!is.na(ins_chr)]))
  } else {
    if (!is.character(insurance_groups) || length(insurance_groups) == 0L) {
      stop(
        "`insurance_groups` must be a non-empty character vector or NULL.",
        call. = FALSE
      )
    }
    missing_grps <- setdiff(insurance_groups, unique(ins_chr[!is.na(ins_chr)]))
    if (length(missing_grps) > 0L) {
      warning(
        sprintf(
          "These insurance_groups were not found in column '%s' and will be skipped: %s",
          insurance_col,
          paste(missing_grps, collapse = ", ")
        ),
        call. = FALSE
      )
      insurance_groups <- intersect(
        insurance_groups,
        unique(ins_chr[!is.na(ins_chr)])
      )
    }
    if (length(insurance_groups) == 0L) {
      stop("No valid insurance groups found.", call. = FALSE)
    }
  }

  # ---- pre-extract column vectors for speed ----------------------------------
  id_vec   <- data[[id_col]]
  incl_vec <- as.character(data[[inclusion_col]])
  wait_vec <- if (!is.null(wait_col)) data[[wait_col]] else NULL
  med_vec  <- if (!is.null(medicaid_accept_col)) data[[medicaid_accept_col]] else NULL

  # ---- Wilson CI helper ------------------------------------------------------
  .wci <- function(k, n) {
    if (n == 0L || is.na(n) || is.na(k)) return(c(NA_real_, NA_real_))
    as.numeric(suppressWarnings(
      stats::prop.test(k, n, conf.level = conf_level, correct = FALSE)$conf.int
    ))
  }

  ci_pct_label <- round(conf_level * 100L)

  # ---- core computation for any logical mask ---------------------------------
  .compute <- function(mask) {
    # mask: logical vector (TRUE = rows in this pool)

    # total assigned (distinct IDs)
    ids_pool  <- unique(id_vec[mask & !is.na(id_vec)])
    n_total   <- length(ids_pool)

    # excluded: reachability not confirmed
    excl_mask <- mask & !is.na(incl_vec) & incl_vec != inclusion_value
    ids_excl  <- unique(id_vec[excl_mask & !is.na(id_vec)])
    n_excluded <- length(ids_excl)

    # denominator
    n_denom <- n_total - n_excluded

    # numerator: reachable AND has appointment AND (optionally) has Medicaid field
    num_mask <- mask & !is.na(incl_vec) & incl_vec == inclusion_value

    if (!is.null(wait_vec)) {
      num_mask <- num_mask & !is.na(wait_vec) & wait_vec > 0
    }
    if (!is.null(med_vec)) {
      num_mask <- num_mask & !is.na(med_vec)
    }

    ids_num <- unique(id_vec[num_mask & !is.na(id_vec)])
    n_num   <- length(ids_num)

    list(
      n_total    = n_total,
      n_excluded = n_excluded,
      n_denom    = n_denom,
      n_num      = n_num
    )
  }

  # ---- build one summary row -------------------------------------------------
  .make_row <- function(grp_label, res) {
    k    <- res$n_num
    n    <- res$n_denom
    rate <- if (n > 0L) k / n else NA_real_
    ci   <- .wci(k, n)

    sentence <- if (is.na(rate)) {
      sprintf(
        "%s acceptance rate: %d/%d = NA (denominator is zero).",
        grp_label, k, n
      )
    } else {
      sprintf(
        "%s acceptance rate: %d/%d = %.1f%% (%d%% CI: %.1f%%-%.1f%%)",
        grp_label, k, n,
        rate * 100,
        ci_pct_label,
        ci[1L] * 100,
        ci[2L] * 100
      )
    }

    data.frame(
      insurance     = grp_label,
      n_total       = res$n_total,
      n_excluded    = res$n_excluded,
      n_numerator   = k,
      n_denominator = n,
      rate_pct      = if (is.na(rate)) NA_real_ else rate * 100,
      ci_lower_pct  = if (is.na(ci[1L])) NA_real_ else ci[1L] * 100,
      ci_upper_pct  = if (is.na(ci[2L])) NA_real_ else ci[2L] * 100,
      sentence      = sentence,
      stringsAsFactors = FALSE
    )
  }

  # ---- per-group rows --------------------------------------------------------
  row_list <- lapply(insurance_groups, function(grp) {
    mask <- !is.na(ins_chr) & ins_chr == grp
    res  <- .compute(mask)
    .make_row(grp, res)
  })

  tbl          <- do.call(rbind, row_list)
  rownames(tbl) <- NULL

  # ---- overall (2+ groups) ---------------------------------------------------
  overall <- NULL
  if (length(insurance_groups) >= 2L) {
    overall_mask <- !is.na(ins_chr) & ins_chr %in% insurance_groups
    ores         <- .compute(overall_mask)
    overall      <- .make_row("Overall", ores)
  }

  # ---- sentences vector ------------------------------------------------------
  sentences <- tbl[["sentence"]]

  # ---- gap sentence ----------------------------------------------------------
  rates        <- tbl[["rate_pct"]]
  ins_labels   <- tbl[["insurance"]]
  valid_idx    <- which(!is.na(rates))
  gap_sentence <- NA_character_

  if (length(insurance_groups) == 2L && length(valid_idx) == 2L) {
    r1 <- rates[1L];  g1 <- ins_labels[1L]
    r2 <- rates[2L];  g2 <- ins_labels[2L]
    gap <- abs(r1 - r2)
    if (r1 >= r2) {
      gap_sentence <- sprintf(
        "Physicians accepted %s at %.1f%% vs %s at %.1f%%, a gap of %.1f percentage points.",
        g1, r1, g2, r2, gap
      )
    } else {
      gap_sentence <- sprintf(
        "Physicians accepted %s at %.1f%% vs %s at %.1f%%, a gap of %.1f percentage points.",
        g2, r2, g1, r1, gap
      )
    }
  } else if (length(valid_idx) >= 2L) {
    imax <- valid_idx[which.max(rates[valid_idx])]
    imin <- valid_idx[which.min(rates[valid_idx])]
    gap_sentence <- sprintf(
      "Acceptance rates ranged from %.1f%% (%s) to %.1f%% (%s), a gap of %.1f percentage points.",
      rates[imin], ins_labels[imin],
      rates[imax], ins_labels[imax],
      rates[imax] - rates[imin]
    )
  }

  # ---- assemble and return ---------------------------------------------------
  out <- list(
    table        = tbl,
    overall      = overall,
    sentences    = sentences,
    gap_sentence = gap_sentence
  )
  class(out) <- c("mysterycall_acceptance_rate_calc", "list")
  out
}


#' Print a mysterycall_acceptance_rate_calc Object
#'
#' Prints the per-group acceptance rate sentences followed by the gap
#' sentence (when available).
#'
#' @param x A `"mysterycall_acceptance_rate_calc"` object returned by
#'   [mysterycall_acceptance_rate_calc()].
#' @param ... Ignored; present for S3 consistency.
#'
#' @return Invisibly returns `x`.
#' @family outcomes
#' @seealso [mysterycall_acceptance_rate_calc()]
#' @export
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   phone     = paste0("P", seq_len(40)),
#'   insurance = rep(c("Medicaid", "Private"), each = 20L),
#'   reason_for_exclusions             = sample(
#'     c("Able to contact", "No answer"), 40, replace = TRUE
#'   ),
#'   business_days_until_appointment   = sample(c(0L, 5L, 10L, 15L), 40,
#'                                               replace = TRUE),
#'   stringsAsFactors = FALSE
#' )
#' res <- mysterycall_acceptance_rate_calc(df)
#' print(res)
print.mysterycall_acceptance_rate_calc <- function(x, ...) {
  cat(paste(x$sentences, collapse = "\n"), "\n")
  if (!is.na(x$gap_sentence)) {
    cat(x$gap_sentence, "\n")
  }
  invisible(x)
}
