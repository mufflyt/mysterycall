#' Build a Manuscript-Ready Insurance Wait-Time Sentence
#'
#' Fits a Poisson GLM of wait time on insurance type (with Blue Cross/Blue
#' Shield as the reference), extracts the Incidence Rate Ratio (IRR),
#' confidence interval, and p-value for Medicaid, and assembles a
#' manuscript-ready sentence reporting the comparison.
#'
#' @param data A data frame.
#' @param outcome_col Character scalar. Numeric wait-time column. Default
#'   `"business_days_until_appointment"`.
#' @param insurance_col Character scalar. Insurance column. Default
#'   `"insurance"`.
#' @param medicaid_label Character scalar. Label used for Medicaid in
#'   `insurance_col`. Default `"Medicaid"`.
#' @param bcbs_label Character scalar. Label used for Blue Cross/Blue Shield
#'   (reference group). Default `"Blue Cross/Blue Shield"`.
#' @param digits_irr Integer. Decimal places for IRR and CI. Default `2`.
#' @param digits_pct Decimal places for percentage difference. Default `1`.
#' @param digits_median Integer. Rounding digits for medians. Default `0`.
#' @param filter_positive Logical. If `TRUE`, pre-filter rows where
#'   `outcome_col > 0`. Default `FALSE`.
#'
#' @return A named list:
#' \describe{
#'   \item{`sentence`}{Character scalar \u2014 the manuscript paragraph.}
#'   \item{`irr`}{Numeric IRR for Medicaid vs. BCBS.}
#'   \item{`ci_lower`}{Numeric lower 95% CI bound.}
#'   \item{`ci_upper`}{Numeric upper 95% CI bound.}
#'   \item{`p_value`}{Numeric p-value.}
#'   \item{`pct_diff`}{Numeric percentage difference `(irr - 1) * 100`.}
#'   \item{`medicaid_stats`}{Named list: `median`, `q1`, `q3` for Medicaid.}
#'   \item{`bcbs_stats`}{Named list: `median`, `q1`, `q3` for BCBS.}
#' }
#'
#' @family outcomes
#' @importFrom stats glm poisson relevel confint.default median quantile
#' @importFrom utils write.csv
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_flag assert_integerish
#' @export
#'
#' @examples
#' set.seed(42)
#' df <- data.frame(
#'   insurance = rep(c("Medicaid", "Blue Cross/Blue Shield"), each = 20),
#'   business_days_until_appointment = c(rpois(20, 21), rpois(20, 10)),
#'   stringsAsFactors = FALSE
#' )
#' res <- mysterycall_insurance_wait_sentence(df)
#' cat(res$sentence)
mysterycall_insurance_wait_sentence <- function(
    data,
    outcome_col    = "business_days_until_appointment",
    insurance_col  = "insurance",
    medicaid_label = "Medicaid",
    bcbs_label     = "Blue Cross/Blue Shield",
    digits_irr     = 2L,
    digits_pct     = 1L,
    digits_median  = 0L,
    filter_positive = FALSE) {

  checkmate::assert_data_frame(data, min.rows = 0)
  checkmate::assert_string(outcome_col)
  checkmate::assert_string(insurance_col)
  checkmate::assert_names(names(data), must.include = c(outcome_col, insurance_col))
  checkmate::assert_string(medicaid_label)
  checkmate::assert_string(bcbs_label)
  checkmate::assert_integerish(digits_irr,    lower = 0, len = 1)
  checkmate::assert_integerish(digits_pct,    lower = 0, len = 1)
  checkmate::assert_integerish(digits_median, lower = 0, len = 1)
  checkmate::assert_flag(filter_positive)

  df <- data
  if (isTRUE(filter_positive)) {
    df <- df[!is.na(df[[outcome_col]]) & df[[outcome_col]] > 0, , drop = FALSE]
  }

  # Validate that both labels exist in the data
  ins_vals <- unique(df[[insurance_col]])
  if (!bcbs_label %in% ins_vals) {
    stop(
      sprintf(
        "BCBS label '%s' not found in column '%s'. Found: %s.",
        bcbs_label, insurance_col,
        paste(ins_vals, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (!medicaid_label %in% ins_vals) {
    stop(
      sprintf(
        "Medicaid label '%s' not found in column '%s'. Found: %s.",
        medicaid_label, insurance_col,
        paste(ins_vals, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  # 1. Per-insurance median / IQR
  .grp_stats <- function(label) {
    y <- df[[outcome_col]][df[[insurance_col]] == label]
    y <- y[!is.na(y)]
    list(
      median = round(stats::median(y), digits = digits_median),
      q1     = round(stats::quantile(y, 0.25), digits = 0L),
      q3     = round(stats::quantile(y, 0.75), digits = 0L)
    )
  }
  medicaid_stats <- .grp_stats(medicaid_label)
  bcbs_stats     <- .grp_stats(bcbs_label)

  # 2. Fit Poisson GLM with BCBS as reference
  ins_factor <- stats::relevel(factor(df[[insurance_col]]), ref = bcbs_label)
  y_out      <- df[[outcome_col]]
  fit        <- stats::glm(y_out ~ ins_factor, family = stats::poisson(link = "log"))

  # 3. Extract IRR, CI, p-value for Medicaid term
  medicaid_term <- paste0("ins_factor", medicaid_label)
  coef_sum      <- summary(fit)$coefficients

  if (!medicaid_term %in% rownames(coef_sum)) {
    stop(
      sprintf(
        "Medicaid term '%s' not found in model coefficients. Terms found: %s.",
        medicaid_term, paste(rownames(coef_sum), collapse = ", ")
      ),
      call. = FALSE
    )
  }

  log_irr   <- coef_sum[medicaid_term, "Estimate"]
  irr       <- round(exp(log_irr), digits = digits_irr)

  ci_raw    <- suppressMessages(
    tryCatch(
      stats::confint.default(fit),
      error = function(e) {
        matrix(c(NA_real_, NA_real_), nrow = 1,
               dimnames = list(medicaid_term, c("2.5 %", "97.5 %")))
      }
    )
  )
  ci_lower  <- round(exp(ci_raw[medicaid_term, "2.5 %"]),  digits = digits_irr)
  ci_upper  <- round(exp(ci_raw[medicaid_term, "97.5 %"]), digits = digits_irr)

  p_value   <- coef_sum[medicaid_term, "Pr(>|z|)"]

  # 4. Percentage difference
  pct_diff  <- round((irr - 1) * 100, digits = digits_pct)
  direction <- if (irr > 1) "longer" else "shorter"

  # 5. Build sentence
  p_fmt <- if (p_value < 0.001) "< 0.001" else sprintf("%.*f", 3L, p_value)

  sentence <- sprintf(
    paste0(
      "%s patients experienced a %s%% %s wait compared to patients with %s ",
      "(Incidence Rate Ratio: %.*f; 95%% CI: %.*f\u2013%.*f; p %s) ",
      "with median wait times of %g business days (IQR: %g\u2013%g) ",
      "and %g business days (IQR: %g\u2013%g) respectively."
    ),
    medicaid_label,
    abs(pct_diff),
    direction,
    bcbs_label,
    digits_irr, irr,
    digits_irr, ci_lower,
    digits_irr, ci_upper,
    p_fmt,
    medicaid_stats$median, medicaid_stats$q1, medicaid_stats$q3,
    bcbs_stats$median,     bcbs_stats$q1,     bcbs_stats$q3
  )

  list(
    sentence       = sentence,
    irr            = irr,
    ci_lower       = ci_lower,
    ci_upper       = ci_upper,
    p_value        = p_value,
    pct_diff       = pct_diff,
    medicaid_stats = medicaid_stats,
    bcbs_stats     = bcbs_stats
  )
}
