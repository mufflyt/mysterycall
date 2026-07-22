#' Calculate Medicaid and BCBS Acceptance Rates (deprecated)
#'
#' @description
#' **Deprecated.** This is the hardcoded two-group
#' (Medicaid + Blue Cross/Blue Shield) special case of the generalized
#' [mysterycall_acceptance_rate_calc()], which handles any number of insurance
#' groups and adds Wilson confidence intervals. Prefer
#' `mysterycall_acceptance_rate_calc()`; pass
#' `medicaid_screen_group = "Medicaid"` there to reproduce this function's
#' asymmetric Medicaid-only NA-screen. Retained for its exact manuscript
#' paragraph wording.
#'
#' Replicates the multi-step acceptance-rate calculation from the mystery-caller
#' Rmd analysis: distinct-phone numerator (accepted + appointment), distinct-phone
#' denominator (total minus excluded), and a manuscript-ready paragraph.
#'
#' @details
#' **Numerator** (per insurance type): physicians who (a) match the insurance
#' label, (b) are coded as `contact_value` in `exclusion_col`, and (c) have
#' `business_days_until_appointment > 0`; counted by distinct `phone_col`. The
#' Medicaid numerator additionally requires a non-`NA` value in
#' `medicaid_accept_col`; the BCBS numerator does **not** apply that
#' Medicaid-only screen (doing so previously biased the BCBS rate, or forced it
#' to 0% when the Medicaid field was `NA` on BCBS rows).
#'
#' **Denominator**: total distinct phones with that insurance minus distinct
#' phones that were excluded (not `contact_value`).
#'
#' **Rate**: `round(numerator / denominator * 100, digits)`.
#'
#' @param data A data frame of mystery-caller records.
#' @param insurance_col Character scalar. Default `"insurance"`.
#' @param exclusion_col Character scalar. Default `"reason_for_exclusions"`.
#' @param days_col Character scalar. Default `"business_days_until_appointment"`.
#' @param medicaid_accept_col Character scalar. Column used to screen for NA
#'   before counting acceptances. Default `"does_the_physician_accept_medicaid"`.
#' @param phone_col Character scalar. Distinct unit for counting.
#'   Default `"phone"`.
#' @param contact_value Character scalar. Default `"Able to contact"`.
#' @param reached_declined_values Character vector of `exclusion_col` strings for
#'   offices reached but declined; these are kept in the denominator (every
#'   other non-contact reason is excluded as unreachable). Default
#'   [mysterycall_reached_declined_reasons()].
#' @param medicaid_label Character scalar. Default `"Medicaid"`.
#' @param bcbs_label Character scalar. Default `"Blue Cross/Blue Shield"`.
#' @param digits Integer. Decimal places for rates. Default `1`.
#' @param output_dir Character scalar or `NULL`. `NULL` → session temp dir.
#'   `NA` → skip writing.
#' @param filename Character scalar. Output CSV file name.
#'
#' @return A named list:
#' \describe{
#'   \item{`count_accepts_medicaid`}{Numerator: Medicaid physicians who
#'     accepted and gave an appointment.}
#'   \item{`count_medicaid_excluded`}{Distinct excluded Medicaid phones.}
#'   \item{`total_count_medicaid`}{Total distinct Medicaid phones.}
#'   \item{`count_medicaid_denom`}{Effective denominator (total minus
#'     excluded).}
#'   \item{`medicaid_acceptance_rate`}{Rounded percentage.}
#'   \item{`count_accepts_bcbs`}{Numerator: BCBS.}
#'   \item{`count_bcbs_excluded`}{Distinct excluded BCBS phones.}
#'   \item{`total_count_bcbs`}{Total distinct BCBS phones.}
#'   \item{`count_bcbs_denom`}{Effective denominator: BCBS.}
#'   \item{`bcbs_acceptance_rate`}{Rounded percentage.}
#'   \item{`paragraph`}{Full manuscript paragraph with both rates.}
#'   \item{`summary_sentence`}{Shorter inline sentence for embedding.}
#' }
#'
#' @family outcomes
#' @seealso [mysterycall_sample_demographics()] for overall sample counts;
#'   [mysterycall_acceptance_rate_calc()] for a simpler rate helper.
#' @importFrom dplyr filter distinct n
#' @importFrom utils write.csv
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_integerish
#' @export
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   phone                           = paste0("555-", seq_len(100)),
#'   insurance                       = rep(c("Medicaid", "Blue Cross/Blue Shield"), 50),
#'   reason_for_exclusions           = sample(c("Able to contact", "Not available"),
#'                                            100, replace = TRUE, prob = c(0.7, 0.3)),
#'   business_days_until_appointment = sample(c(NA, 1:20), 100, replace = TRUE),
#'   does_the_physician_accept_medicaid = sample(c("Yes", "No", NA), 100,
#'                                               replace = TRUE),
#'   stringsAsFactors = FALSE
#' )
#' rates <- mysterycall_insurance_acceptance_rates(df, output_dir = NA)
#' cat(rates$paragraph)
mysterycall_insurance_acceptance_rates <- function(
    data,
    insurance_col       = "insurance",
    exclusion_col       = "reason_for_exclusions",
    days_col            = "business_days_until_appointment",
    medicaid_accept_col = "does_the_physician_accept_medicaid",
    phone_col           = "phone",
    contact_value       = "Able to contact",
    reached_declined_values = mysterycall_reached_declined_reasons(),
    medicaid_label      = "Medicaid",
    bcbs_label          = "Blue Cross/Blue Shield",
    digits              = 1L,
    output_dir          = NULL,
    filename            = "insurance_acceptance_rates.csv") {

  .Deprecated("mysterycall_acceptance_rate_calc", package = "mysterycall",
              msg = paste0(
                "mysterycall_insurance_acceptance_rates() is deprecated. Use ",
                "mysterycall_acceptance_rate_calc(medicaid_screen_group = ",
                "\"Medicaid\") instead."))

  # -- Validate inputs ----------------------------------------------------------
  checkmate::assert_data_frame(data, min.rows = 0)
  checkmate::assert_string(insurance_col)
  checkmate::assert_string(exclusion_col)
  checkmate::assert_string(days_col)
  checkmate::assert_string(phone_col)
  checkmate::assert_names(names(data), must.include = c(insurance_col, exclusion_col, days_col, phone_col))
  checkmate::assert_integerish(digits, lower = 0, len = 1)
  if (!medicaid_accept_col %in% names(data)) {
    message(sprintf(
      "Column '%s' not found; NA-filtering step will be skipped for both groups.",
      medicaid_accept_col
    ))
    medicaid_accept_col <- NULL
  }

  # -- Helper: count distinct phones meeting criteria --------------------------
  count_distinct <- function(df, ...) {
    conditions <- list(...)
    for (expr in conditions) df <- dplyr::filter(df, !!expr)
    nrow(dplyr::distinct(df, .data[[phone_col]]))
  }

  # -- Medicaid -----------------------------------------------------------------
  med_base <- if (!is.null(medicaid_accept_col)) {
    dplyr::filter(data, !is.na(.data[[medicaid_accept_col]]))
  } else {
    data
  }

  count_accepts_medicaid <- med_base |>
    dplyr::filter(.data[[insurance_col]] == medicaid_label) |>
    dplyr::filter(.data[[exclusion_col]] == contact_value) |>
    dplyr::filter(.data[[days_col]] > 0) |>
    dplyr::distinct(.data[[phone_col]]) |>
    nrow()

  count_medicaid_excluded <- data |>
    dplyr::filter(!is.na(.data[[insurance_col]])) |>
    dplyr::filter(.data[[insurance_col]] == medicaid_label) |>
    dplyr::filter(.data[[exclusion_col]] != contact_value,
                  !(.data[[exclusion_col]] %in% reached_declined_values)) |>
    dplyr::distinct(.data[[phone_col]]) |>
    nrow()

  total_count_medicaid <- data |>
    dplyr::filter(!is.na(.data[[insurance_col]])) |>
    dplyr::filter(.data[[insurance_col]] == medicaid_label) |>
    dplyr::distinct(.data[[phone_col]]) |>
    nrow()

  count_medicaid_denom     <- total_count_medicaid - count_medicaid_excluded
  medicaid_acceptance_rate <- round(
    count_accepts_medicaid / count_medicaid_denom * 100, digits
  )

  # -- BCBS ---------------------------------------------------------------------
  # BCBS acceptance must not be screened by the Medicaid-only accept field;
  # use the full data frame so numerator and denominator share one frame.
  bcbs_base <- data

  count_accepts_bcbs <- bcbs_base |>
    dplyr::filter(.data[[insurance_col]] == bcbs_label) |>
    dplyr::filter(.data[[exclusion_col]] == contact_value) |>
    dplyr::filter(.data[[days_col]] > 0) |>
    dplyr::distinct(.data[[phone_col]]) |>
    nrow()

  count_bcbs_excluded <- data |>
    dplyr::filter(!is.na(.data[[insurance_col]])) |>
    dplyr::filter(.data[[insurance_col]] == bcbs_label) |>
    dplyr::filter(.data[[exclusion_col]] != contact_value,
                  !(.data[[exclusion_col]] %in% reached_declined_values)) |>
    dplyr::distinct(.data[[phone_col]]) |>
    nrow()

  total_count_bcbs <- data |>
    dplyr::filter(!is.na(.data[[insurance_col]])) |>
    dplyr::filter(.data[[insurance_col]] == bcbs_label) |>
    dplyr::distinct(.data[[phone_col]]) |>
    nrow()

  count_bcbs_denom     <- total_count_bcbs - count_bcbs_excluded
  bcbs_acceptance_rate <- round(
    count_accepts_bcbs / count_bcbs_denom * 100, digits
  )

  # -- Text output --------------------------------------------------------------
  paragraph <- sprintf(
    paste0(
      "Medicaid Acceptance Rate: Out of the total number of physicians assigned ",
      "Medicaid insurance (%d), %d physicians accepted Medicaid and provided an ",
      "appointment, resulting in an acceptance rate of %s%%. ",
      "Blue Cross/Blue Shield Acceptance Rate: Among the physicians assigned ",
      "Blue Cross/Blue Shield insurance (%d), %d accepted this insurance and ",
      "provided an appointment, yielding an acceptance rate of %s%%."
    ),
    total_count_medicaid, count_accepts_medicaid,
    format(medicaid_acceptance_rate, nsmall = digits),
    total_count_bcbs, count_accepts_bcbs,
    format(bcbs_acceptance_rate, nsmall = digits)
  )

  summary_sentence <- sprintf(
    paste0(
      "We made calls to %d unique physicians that accepted Blue Cross/Blue Shield. ",
      "%d physician offices accepted Medicaid, giving a %s%% Medicaid acceptance ",
      "rate (n = %d/N = %d). ",
      "Physicians offices accepted Blue Cross/Blue Shield at a rate of %s%% ",
      "(n = %d/N = %d)."
    ),
    total_count_bcbs,
    count_accepts_medicaid,
    format(medicaid_acceptance_rate, nsmall = digits),
    count_accepts_medicaid, count_medicaid_denom,
    format(bcbs_acceptance_rate, nsmall = digits),
    count_accepts_bcbs, count_bcbs_denom
  )

  message(paragraph)

  # -- Write CSV ----------------------------------------------------------------
  if (!isTRUE(is.na(output_dir))) {
    if (is.null(output_dir)) {
      output_dir <- mysterycall_tempdir("acceptance_rates", create = TRUE)
    }
    if (!dir.exists(output_dir))
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

    out_df <- data.frame(
      insurance        = c(medicaid_label, bcbs_label),
      n_accepted       = c(count_accepts_medicaid, count_accepts_bcbs),
      n_total          = c(total_count_medicaid,   total_count_bcbs),
      n_denominator    = c(count_medicaid_denom,   count_bcbs_denom),
      acceptance_rate  = c(medicaid_acceptance_rate, bcbs_acceptance_rate),
      stringsAsFactors = FALSE
    )
    out_path <- file.path(output_dir, filename)
    utils::write.csv(out_df, out_path, row.names = FALSE)
    message(sprintf("Acceptance rates written to: %s", out_path))
  }

  list(
    count_accepts_medicaid   = count_accepts_medicaid,
    count_medicaid_excluded  = count_medicaid_excluded,
    total_count_medicaid     = total_count_medicaid,
    count_medicaid_denom     = count_medicaid_denom,
    medicaid_acceptance_rate = medicaid_acceptance_rate,
    count_accepts_bcbs       = count_accepts_bcbs,
    count_bcbs_excluded      = count_bcbs_excluded,
    total_count_bcbs         = total_count_bcbs,
    count_bcbs_denom         = count_bcbs_denom,
    bcbs_acceptance_rate     = bcbs_acceptance_rate,
    paragraph                = paragraph,
    summary_sentence         = summary_sentence
  )
}
