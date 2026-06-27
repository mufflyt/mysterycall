#' Sensitivity analysis: physicians called under both insurance types
#'
#' @name mysterycall_sensitivity_both_insurance
NULL

#' Sensitivity analysis comparing wait times for physicians called under both insurance types
#'
#' Identifies physicians (by `phone_col`) who were called under both Medicaid
#' and Blue Cross/Blue Shield, then compares their wait times between insurance
#' types with summary statistics and a t-test. Mirrors the sensitivity analysis
#' in the mystery-caller study Rmd (lines 1469-1505).
#'
#' @param data A data frame of mystery-caller records. Must contain `phone_col`,
#'   `insurance_col`, and `outcome_col`.
#' @param phone_col Character scalar. Column that uniquely identifies each
#'   physician (e.g. phone number or NPI). Default `"phone"`.
#' @param insurance_col Character scalar. Name of the column recording insurance
#'   type. Default `"insurance"`.
#' @param outcome_col Character scalar. Name of the numeric column holding
#'   wait-time days. Default `"business_days_until_appointment"`.
#' @param medicaid_label Character scalar. Lowercase comparison value for
#'   Medicaid after `tolower(trimws(...))`. Default `"medicaid"`.
#' @param bcbs_label Character scalar. Lowercase comparison value for Blue Cross
#'   after normalization. Default `"blue cross/blue shield"`.
#' @param output_dir Character scalar or `NULL`. Directory for CSV output.
#'   `NULL` (default) writes to a session temp directory via
#'   [mysterycall_tempdir()]. Pass `NA` to skip writing.
#' @param filename Character scalar. CSV file name.
#'   Default `"sensitivity_both_insurance.csv"`.
#'
#' @return A named list with seven elements:
#' \describe{
#'   \item{`n_both`}{Integer. Number of physicians with records under both
#'     Medicaid and BCBS.}
#'   \item{`n_total`}{Integer. Total unique physicians (by `phone_col`).}
#'   \item{`both_data`}{[tibble::tibble()] of rows for physicians with both
#'     insurance types (insurance column is normalized to lowercase).}
#'   \item{`wait_comparison`}{[tibble::tibble()] with columns `insurance`,
#'     `mean_wait`, `sd_wait`, `median_wait`, `iqr_wait` for each insurance
#'     type. Empty tibble when `n_both == 0`.}
#'   \item{`t_test`}{Object returned by [stats::t.test()], or `NULL` when
#'     there are insufficient data.}
#'   \item{`sentence`}{Character scalar. Manuscript-ready descriptive sentence.}
#'   \item{`phone_ids`}{Character vector of phone numbers (or IDs) for
#'     physicians called under both insurance types.}
#' }
#'
#' @family descriptive helpers
#' @seealso [mysterycall_scenario_summary()]
#' @importFrom stats t.test median IQR sd
#' @importFrom tibble as_tibble
#' @importFrom utils write.csv
#' @export
#'
#' @examples
#' set.seed(42)
#' df <- data.frame(
#'   phone      = rep(paste0("P", 1:10), each = 2L),
#'   insurance  = rep(c("Medicaid", "Blue Cross/Blue Shield"), 10L),
#'   business_days_until_appointment = rpois(20L, 14),
#'   stringsAsFactors = FALSE
#' )
#' res <- mysterycall_sensitivity_both_insurance(df, output_dir = NA)
#' cat(res$sentence)
mysterycall_sensitivity_both_insurance <- function(
    data,
    phone_col      = "phone",
    insurance_col  = "insurance",
    outcome_col    = "business_days_until_appointment",
    medicaid_label = "medicaid",
    bcbs_label     = "blue cross/blue shield",
    output_dir     = NULL,
    filename       = "sensitivity_both_insurance.csv"
) {

  # ---- input validation -------------------------------------------------------
  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)
  if (!is.character(phone_col) || length(phone_col) != 1L)
    stop("`phone_col` must be a single character string.", call. = FALSE)
  if (!phone_col %in% names(data))
    stop(sprintf("Column '%s' not found in data.", phone_col), call. = FALSE)
  if (!is.character(insurance_col) || length(insurance_col) != 1L)
    stop("`insurance_col` must be a single character string.", call. = FALSE)
  if (!insurance_col %in% names(data))
    stop(sprintf("Column '%s' not found in data.", insurance_col), call. = FALSE)
  if (!is.character(outcome_col) || length(outcome_col) != 1L)
    stop("`outcome_col` must be a single character string.", call. = FALSE)
  if (!outcome_col %in% names(data))
    stop(sprintf("Column '%s' not found in data.", outcome_col), call. = FALSE)

  # ---- normalize insurance column (internal copy only) -----------------------
  df_norm <- data
  df_norm[[insurance_col]] <- tolower(trimws(as.character(df_norm[[insurance_col]])))

  # ---- identify physicians with BOTH insurance types -------------------------
  all_phones  <- unique(df_norm[[phone_col]])
  n_total     <- length(all_phones)

  phones_with_both <- all_phones[vapply(all_phones, function(ph) {
    ins <- df_norm[[insurance_col]][df_norm[[phone_col]] == ph]
    all(c(medicaid_label, bcbs_label) %in% ins)
  }, logical(1L))]

  n_both <- length(phones_with_both)

  # ---- filter to rows for physicians with both insurances --------------------
  both_data <- df_norm[df_norm[[phone_col]] %in% phones_with_both, , drop = FALSE]

  # ---- compute per-insurance summary statistics ------------------------------
  if (n_both > 0L) {
    wait_comparison <- do.call(rbind, lapply(
      c(medicaid_label, bcbs_label),
      function(ins_val) {
        vals <- both_data[[outcome_col]][
          both_data[[insurance_col]] == ins_val & !is.na(both_data[[outcome_col]])
        ]
        data.frame(
          insurance   = ins_val,
          mean_wait   = if (length(vals) > 0L) mean(vals)               else NA_real_,
          sd_wait     = if (length(vals) > 1L) stats::sd(vals)          else NA_real_,
          median_wait = if (length(vals) > 0L) stats::median(vals)      else NA_real_,
          iqr_wait    = if (length(vals) > 0L) stats::IQR(vals)         else NA_real_,
          stringsAsFactors = FALSE
        )
      }
    ))
  } else {
    wait_comparison <- data.frame(
      insurance   = character(0L),
      mean_wait   = numeric(0L),
      sd_wait     = numeric(0L),
      median_wait = numeric(0L),
      iqr_wait    = numeric(0L),
      stringsAsFactors = FALSE
    )
  }

  # ---- t-test ----------------------------------------------------------------
  t_test <- NULL
  if (n_both > 0L) {
    ttest_rows <- both_data[
      both_data[[insurance_col]] %in% c(medicaid_label, bcbs_label) &
        !is.na(both_data[[outcome_col]]),
      , drop = FALSE
    ]
    n_groups <- length(unique(ttest_rows[[insurance_col]]))
    if (nrow(ttest_rows) >= 2L && n_groups == 2L) {
      t_test <- tryCatch(
        stats::t.test(
          ttest_rows[[outcome_col]] ~ ttest_rows[[insurance_col]]
        ),
        error = function(e) NULL
      )
    }
  }

  # ---- informative message when no physicians qualify -----------------------
  pct_both <- if (n_total > 0L) round(n_both / n_total * 100, 1) else 0

  if (n_both == 0L) {
    message(sprintf(
      "No physicians were called under both %s and %s. ",
      medicaid_label, bcbs_label
    ))
  }

  # ---- build sentence --------------------------------------------------------
  sentence <- .build_sensitivity_sentence(
    n_total        = n_total,
    n_both         = n_both,
    pct_both       = pct_both,
    wait_comparison = wait_comparison,
    t_test         = t_test,
    medicaid_label = medicaid_label,
    bcbs_label     = bcbs_label
  )

  # ---- optional CSV output ---------------------------------------------------
  if (!isTRUE(is.na(output_dir))) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("sensitivity_both_insurance", create = TRUE)
    }
    if (!dir.exists(output_dir))
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    out_path <- file.path(output_dir, filename)
    utils::write.csv(wait_comparison, out_path, row.names = FALSE)
    message("Sensitivity analysis written to: ", out_path)
  }

  list(
    n_both          = n_both,
    n_total         = n_total,
    both_data       = tibble::as_tibble(both_data),
    wait_comparison = tibble::as_tibble(wait_comparison),
    t_test          = t_test,
    sentence        = sentence,
    phone_ids       = as.character(phones_with_both)
  )
}


# ---- internal sentence builder ----------------------------------------------
#' @noRd
.build_sensitivity_sentence <- function(
    n_total, n_both, pct_both, wait_comparison, t_test,
    medicaid_label, bcbs_label
) {
  if (n_both == 0L) {
    return(sprintf(
      "Of %d physician%s called, none were called under both Medicaid and Blue Cross/Blue Shield.",
      n_total, if (n_total == 1L) "" else "s"
    ))
  }

  # Extract wait stats
  med_row  <- wait_comparison[wait_comparison$insurance == medicaid_label, ]
  bcbs_row <- wait_comparison[wait_comparison$insurance == bcbs_label, ]

  have_stats <- nrow(med_row) > 0L && nrow(bcbs_row) > 0L &&
    !is.na(med_row$mean_wait) && !is.na(bcbs_row$mean_wait)

  base_sentence <- sprintf(
    "Of %d physician%s called, %d (%.1f%%) were called under both Medicaid and Blue Cross/Blue Shield.",
    n_total, if (n_total == 1L) "" else "s",
    n_both, pct_both
  )

  if (!have_stats || is.null(t_test)) {
    return(base_sentence)
  }

  p_val <- t_test$p.value
  p_fmt <- if (!is.na(p_val) && p_val < 0.001) {
    "< 0.001"
  } else if (!is.na(p_val)) {
    sprintf("%.3f", p_val)
  } else {
    "NA"
  }

  sprintf(
    paste0(
      "%s ",
      "Among these physicians, mean wait times were %.1f days (SD %.1f) for Medicaid ",
      "vs %.1f days (SD %.1f) for BCBS (t-test p = %s)."
    ),
    base_sentence,
    med_row$mean_wait,
    if (is.na(med_row$sd_wait)) 0 else med_row$sd_wait,
    bcbs_row$mean_wait,
    if (is.na(bcbs_row$sd_wait)) 0 else bcbs_row$sd_wait,
    p_fmt
  )
}
