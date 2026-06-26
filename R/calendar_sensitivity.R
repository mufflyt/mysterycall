#' Calendar-days vs. business-days sensitivity analysis for wait-time models
#'
#' @name mysterycall_calendar_sensitivity
NULL

#' Compare calendar-day and business-day wait-time models side by side
#'
#' Fits the same linear mixed model ([mysterycall_lmm()]) on two wait-time
#' columns -- one in calendar days, one in business days (Mon-Fri, US federal
#' holidays excluded) -- and returns a side-by-side comparison table with a
#' ready-to-paste supplemental paragraph.
#'
#' This function fulfils the M&M promise of a supplemental table comparing
#' calendar vs. business days. Run it once data collection is complete and
#' paste `$paragraph` into the supplement.
#'
#' @param data A data frame. Must contain `calendar_col`, `business_col`,
#'   `predictors`, and `random_intercept`.
#' @param calendar_col Character scalar. Name of the calendar-days column
#'   (e.g. `"wait_days"`). Must be numeric.
#' @param business_col Character scalar. Name of the business-days column
#'   (e.g. `"business_days"`). Must be numeric.
#' @param predictors Character vector of fixed-effect predictor column names
#'   (e.g. `"scenario"`). Passed directly to [mysterycall_lmm()].
#' @param random_intercept Character scalar. Grouping column for the random
#'   intercept (e.g. `"practice_id"`). Passed to [mysterycall_lmm()].
#' @param conf_level Numeric. Confidence level for Wald CIs. Default `0.95`.
#' @param ref_label Character scalar. Human-readable label for the reference
#'   group used in the supplemental paragraph (e.g. `"Straight couple"`).
#'   Default `NULL` (omitted from prose).
#' @param supp_table_num Character scalar. Supplemental table number to
#'   embed in the paragraph (e.g. `"S2"`). Default `"[X]"`.
#' @param output_path Character scalar or `NULL`. When a path ending in
#'   `.docx` is supplied the comparison table is exported to Word via
#'   `flextable` and `officer`. Requires both packages.
#' @param ... Additional arguments forwarded to [mysterycall_lmm()].
#'
#' @return A list of class `mysterycall_calendar_sensitivity` with elements:
#' \describe{
#'   \item{`calendar_lmm`}{`mysterycall_lmm` object fit on `calendar_col`.}
#'   \item{`business_lmm`}{`mysterycall_lmm` object fit on `business_col`.}
#'   \item{`comparison_table`}{`data.frame`. One row per non-intercept
#'     fixed-effect term with columns: `term`, `cal_est`, `cal_ci_lo`,
#'     `cal_ci_hi`, `cal_p`, `biz_est`, `biz_ci_lo`, `biz_ci_hi`, `biz_p`,
#'     `direction_consistent` (logical), `magnitude_ratio` (business / calendar
#'     estimate).}
#'   \item{`summary_table`}{`data.frame`. Print-ready version with formatted
#'     strings: `Term`, `Calendar days`, `Business days`, `Consistent`.}
#'   \item{`n_calendar`}{Integer. Complete cases for the calendar model.}
#'   \item{`n_business`}{Integer. Complete cases for the business model.}
#'   \item{`all_consistent`}{Logical. `TRUE` when every term has consistent
#'     direction across both models.}
#'   \item{`paragraph`}{Character scalar. Supplemental paragraph ready to
#'     paste into the manuscript.}
#'   \item{`docx_path`}{Character path or `NULL`.}
#' }
#'
#' @section Interpreting direction_consistent:
#' `TRUE` means the point estimate for that term has the same sign in both
#' models (both negative = shorter wait, or both positive = longer wait). A
#' difference in magnitude is expected because business days are roughly 5/7
#' of calendar days; `magnitude_ratio` near 0.71 is unremarkable.
#'
#' @seealso [mysterycall_lmm()], [mysterycall_business_days()],
#'   [mysterycall_count_business_days()]
#' @family outcomes
#' @export
#'
#' @examplesIf requireNamespace("lme4", quietly = TRUE)
#' set.seed(42)
#' df <- data.frame(
#'   wait_days     = round(rnorm(60, 21, 8)),
#'   business_days = round(rnorm(60, 15, 6)),
#'   scenario      = rep(c("Straight", "Lesbian", "Single"), 20),
#'   practice      = rep(paste0("P", 1:20), each = 3),
#'   stringsAsFactors = FALSE
#' )
#' res <- mysterycall_calendar_sensitivity(
#'   df,
#'   calendar_col     = "wait_days",
#'   business_col     = "business_days",
#'   predictors       = "scenario",
#'   random_intercept = "practice",
#'   ref_label        = "Straight couple",
#'   supp_table_num   = "S2"
#' )
#' print(res)
mysterycall_calendar_sensitivity <- function(
    data,
    calendar_col,
    business_col,
    predictors,
    random_intercept,
    conf_level     = 0.95,
    ref_label      = NULL,
    supp_table_num = "[X]",
    output_path    = NULL,
    ...
) {

  # ---- input validation -------------------------------------------------------
  if (!is.data.frame(data))
    stop("`data` must be a data frame.", call. = FALSE)

  for (col in c(calendar_col, business_col, predictors, random_intercept)) {
    if (!col %in% names(data))
      stop(sprintf("Column '%s' not found in data.", col), call. = FALSE)
  }
  if (!is.numeric(data[[calendar_col]]))
    stop(sprintf("`calendar_col` '%s' must be numeric.", calendar_col), call. = FALSE)
  if (!is.numeric(data[[business_col]]))
    stop(sprintf("`business_col` '%s' must be numeric.", business_col), call. = FALSE)
  if (!is.character(supp_table_num) || length(supp_table_num) != 1L)
    stop("`supp_table_num` must be a single character string.", call. = FALSE)

  # ---- fit both LMMs ----------------------------------------------------------
  message("Fitting calendar-days model (", calendar_col, ")...")
  cal_fit <- suppressMessages(
    mysterycall_lmm(
      data             = data,
      outcome          = calendar_col,
      predictors       = predictors,
      random_intercept = random_intercept,
      conf_level       = conf_level,
      sensitivity_poisson = FALSE,   # don't nest sensitivity inside sensitivity
      ...
    )
  )

  message("Fitting business-days model (", business_col, ")...")
  biz_fit <- suppressMessages(
    mysterycall_lmm(
      data             = data,
      outcome          = business_col,
      predictors       = predictors,
      random_intercept = random_intercept,
      conf_level       = conf_level,
      sensitivity_poisson = FALSE,
      ...
    )
  )

  # ---- extract non-intercept rows ---------------------------------------------
  .strip <- function(ct) {
    ct[ct$term != "(Intercept)", , drop = FALSE]
  }
  cal_ct <- .strip(as.data.frame(cal_fit$coef_table))
  biz_ct <- .strip(as.data.frame(biz_fit$coef_table))

  # Align on term names (inner join -- only terms present in both)
  common_terms <- intersect(cal_ct$term, biz_ct$term)
  if (!length(common_terms))
    stop("No common non-intercept terms found between the two models.", call. = FALSE)

  cal_ct <- cal_ct[cal_ct$term %in% common_terms, , drop = FALSE]
  biz_ct <- biz_ct[biz_ct$term %in% common_terms, , drop = FALSE]
  # Ensure same order
  cal_ct <- cal_ct[order(match(cal_ct$term, common_terms)), , drop = FALSE]
  biz_ct <- biz_ct[order(match(biz_ct$term, common_terms)), , drop = FALSE]

  # ---- build comparison table -------------------------------------------------
  direction_consistent <- sign(cal_ct$estimate) == sign(biz_ct$estimate) |
    (abs(cal_ct$estimate) < 1e-10 & abs(biz_ct$estimate) < 1e-10)

  magnitude_ratio <- ifelse(
    abs(cal_ct$estimate) > 1e-10,
    biz_ct$estimate / cal_ct$estimate,
    NA_real_
  )

  comparison_table <- data.frame(
    term                 = cal_ct$term,
    cal_est              = cal_ct$estimate,
    cal_ci_lo            = cal_ct$ci_lower,
    cal_ci_hi            = cal_ct$ci_upper,
    cal_p                = cal_ct$p_value,
    biz_est              = biz_ct$estimate,
    biz_ci_lo            = biz_ct$ci_lower,
    biz_ci_hi            = biz_ct$ci_upper,
    biz_p                = biz_ct$p_value,
    direction_consistent = direction_consistent,
    magnitude_ratio      = magnitude_ratio,
    stringsAsFactors     = FALSE
  )

  # ---- print-ready summary table ----------------------------------------------
  .fmt_est_ci <- function(est, lo, hi, digits = 1) {
    sprintf("%s (%s to %s)",
            round(est, digits), round(lo, digits), round(hi, digits))
  }
  .fmt_p <- function(p) {
    ifelse(is.na(p), "NA",
           ifelse(p < 0.001, "< 0.001", sprintf("%.3f", p)))
  }

  summary_table <- data.frame(
    Term            = comparison_table$term,
    `Calendar days` = paste0(
      .fmt_est_ci(comparison_table$cal_est,
                  comparison_table$cal_ci_lo,
                  comparison_table$cal_ci_hi),
      ", p = ", .fmt_p(comparison_table$cal_p)
    ),
    `Business days` = paste0(
      .fmt_est_ci(comparison_table$biz_est,
                  comparison_table$biz_ci_lo,
                  comparison_table$biz_ci_hi),
      ", p = ", .fmt_p(comparison_table$biz_p)
    ),
    Consistent      = ifelse(comparison_table$direction_consistent, "Yes", "No"),
    stringsAsFactors = FALSE,
    check.names      = FALSE
  )

  all_consistent <- all(comparison_table$direction_consistent)

  # ---- supplemental paragraph -------------------------------------------------
  ref_phrase <- if (!is.null(ref_label)) {
    sprintf(" compared with %s (reference)", ref_label)
  } else ""

  consistency_phrase <- if (all_consistent) {
    "Results were directionally consistent across both metrics for all comparisons"
  } else {
    inconsistent <- comparison_table$term[!comparison_table$direction_consistent]
    sprintf(
      "Results were directionally consistent for most comparisons, with the exception of %s",
      paste(inconsistent, collapse = " and ")
    )
  }

  # Summarise magnitudes: business days are typically ~5/7 of calendar days
  med_ratio <- stats::median(magnitude_ratio, na.rm = TRUE)
  # Only report the ratio when it's physically meaningful: business-day estimates
  # should be 0-1.5x calendar-day estimates (the 5/7 weekday fraction ~= 0.71).
  # Negative or very large ratios signal that the two columns are inconsistent
  # (e.g., from independent random data in tests) and the note would be misleading.
  ratio_note <- if (!is.na(med_ratio) && med_ratio > 0 && med_ratio < 1.5) {
    sprintf(
      " Business-day estimates were on average %.0f%% of calendar-day estimates (median ratio = %.2f), consistent with the expected 5/7 weekday fraction.",
      med_ratio * 100, med_ratio
    )
  } else ""

  normality_note <- {
    cal_sw <- cal_fit$normality
    biz_sw <- biz_fit$normality
    parts  <- character(0)
    if (!is.na(cal_sw$p_value))
      parts <- c(parts, sprintf("calendar-day model: W = %.3f, p = %s",
                                cal_sw$statistic, .fmt_p(cal_sw$p_value)))
    if (!is.na(biz_sw$p_value))
      parts <- c(parts, sprintf("business-day model: W = %.3f, p = %s",
                                biz_sw$statistic, .fmt_p(biz_sw$p_value)))
    if (length(parts))
      paste0(" Shapiro-Wilk normality tests on model residuals: ",
             paste(parts, collapse = "; "), ".")
    else ""
  }

  paragraph <- sprintf(
    paste0(
      "As a pre-specified sensitivity analysis, we repeated the secondary wait-time ",
      "analysis substituting business days (Monday through Friday, excluding the ",
      "11 U.S. federal holidays) for calendar days. Business days were computed ",
      "using the R package \\emph{bizdays} with a US Federal holiday calendar. ",
      "The calendar-day model included %d observations with a recorded appointment ",
      "date; the business-day model included %d observations. ",
      "Both models used the same mixed-effects linear regression specification ",
      "(%s as fixed effect%s; physician practice as random intercept). ",
      "%s.%s%s ",
      "Full results are presented in Supplemental Table %s."
    ),
    cal_fit$n,
    biz_fit$n,
    paste(predictors, collapse = " and "),
    ref_phrase,
    consistency_phrase,
    ratio_note,
    normality_note,
    supp_table_num
  )

  # ---- optional Word export ---------------------------------------------------
  docx_path <- NULL
  if (!is.null(output_path)) {
    if (!requireNamespace("flextable", quietly = TRUE) ||
        !requireNamespace("officer",   quietly = TRUE)) {
      warning(
        "Packages 'flextable' and 'officer' are required for Word export. ",
        "Install with: install.packages(c('flextable','officer'))",
        call. = FALSE
      )
    } else {
      ft <- flextable::flextable(summary_table)
      ft <- flextable::set_header_labels(
        ft,
        Term            = "Term",
        `Calendar days` = sprintf("Calendar days\nEst. (95%% CI), p"),
        `Business days` = sprintf("Business days\nEst. (95%% CI), p"),
        Consistent      = "Direction\nconsistent?"
      )
      ft <- flextable::autofit(ft)
      ft <- flextable::theme_booktabs(ft)
      ft <- flextable::add_footer_lines(
        ft,
        values = paste0(
          "LMM = linear mixed model with random intercept for physician practice. ",
          "Business days exclude weekends and 11 U.S. federal holidays (bizdays package). ",
          "Estimates are mean difference vs. reference group in days. ",
          "CI = confidence interval."
        )
      )
      doc <- officer::read_docx()
      doc <- officer::body_add_par(
        doc,
        sprintf("Supplemental Table %s. Calendar- vs. Business-Day Wait-Time Sensitivity Analysis",
                supp_table_num),
        style = "heading 1"
      )
      doc <- flextable::body_add_flextable(doc, ft)
      doc <- officer::body_add_par(doc, paragraph, style = "Normal")
      print(doc, target = output_path)
      message("Sensitivity table written to: ", output_path)
      docx_path <- output_path
    }
  }

  structure(
    list(
      calendar_lmm     = cal_fit,
      business_lmm     = biz_fit,
      comparison_table = comparison_table,
      summary_table    = summary_table,
      n_calendar       = cal_fit$n,
      n_business       = biz_fit$n,
      all_consistent   = all_consistent,
      paragraph        = paragraph,
      docx_path        = docx_path
    ),
    class = "mysterycall_calendar_sensitivity"
  )
}


#' Print method for mysterycall_calendar_sensitivity
#'
#' @param x A `mysterycall_calendar_sensitivity` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family outcomes
#' @export
print.mysterycall_calendar_sensitivity <- function(x, ...) {
  cat(sprintf(
    "Calendar vs. Business Days Sensitivity Analysis\n  Calendar model: n = %d  |  Business model: n = %d\n",
    x$n_calendar, x$n_business
  ))
  cat(sprintf("  Direction consistent across all terms: %s\n\n",
              if (x$all_consistent) "YES" else "NO -- see Consistent column"))

  print(x$summary_table, row.names = FALSE)

  cat("\n-- Supplemental paragraph --\n")
  cat(strwrap(x$paragraph, width = 80), sep = "\n")

  invisible(x)
}
