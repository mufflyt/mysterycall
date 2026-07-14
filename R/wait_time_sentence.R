#' Build a Manuscript-Ready Wait-Time Sentence
#'
#' Computes overall and per-group median/IQR wait times, fits a Poisson GLM to
#' obtain p-values for each non-reference level versus the reference, and
#' assembles a manuscript-ready paragraph combining all pieces.
#'
#' @param data A data frame.
#' @param outcome_col Character scalar. Numeric wait-time column. Default
#'   `"business_days_until_appointment"`.
#' @param group_col Character scalar. Grouping variable (e.g. `"scenario"`).
#' @param reference Character scalar or `NULL`. Reference level for the Poisson
#'   model. `NULL` defaults to the first level alphabetically.
#' @param filter_positive Logical. If `TRUE`, pre-filter rows where
#'   `outcome_col > 0`. Default `FALSE`.
#' @param digits_median Integer. Rounding digits for medians. Default `0`.
#' @param digits_p Integer. Significant digits for p-values. Default `3`.
#'
#' @return A named list:
#' \describe{
#'   \item{`sentence`}{Character scalar -- the full manuscript paragraph.}
#'   \item{`overall_stats`}{Named list: `median`, `q1`, `q3` (across all rows).}
#'   \item{`group_stats`}{Tibble from [mysterycall_wait_time_by_group()].}
#'   \item{`p_values`}{Named numeric vector of formatted p-values (one per
#'     non-reference level).}
#' }
#'
#' @family outcomes
#' @importFrom dplyr mutate
#' @importFrom stats glm poisson relevel median quantile as.formula
#' @importFrom checkmate assert_data_frame assert_string assert_names assert_flag assert_integerish
#' @export
#'
#' @examples
#' df <- data.frame(
#'   scenario = rep(c("BCBS", "Medicaid", "Self-Pay"), each = 10),
#'   business_days_until_appointment = c(
#'     rpois(10, 7), rpois(10, 14), rpois(10, 21)
#'   )
#' )
#' res <- mysterycall_wait_time_sentence(df, group_col = "scenario")
#' cat(res$sentence)
mysterycall_wait_time_sentence <- function(
    data,
    outcome_col   = "business_days_until_appointment",
    group_col,
    reference     = NULL,
    filter_positive = FALSE,
    digits_median = 0L,
    digits_p      = 3L) {

  checkmate::assert_data_frame(data, min.rows = 0)
  checkmate::assert_string(outcome_col)
  checkmate::assert_string(group_col)
  checkmate::assert_names(names(data), must.include = c(outcome_col, group_col))
  checkmate::assert_integerish(digits_median, lower = 0, len = 1)
  checkmate::assert_integerish(digits_p,      lower = 0, len = 1)
  checkmate::assert_flag(filter_positive)

  df <- data
  if (isTRUE(filter_positive)) {
    df <- df[!is.na(df[[outcome_col]]) & df[[outcome_col]] > 0, , drop = FALSE]
  }

  # 1. Overall stats
  y_all     <- df[[outcome_col]]
  ov_median <- round(stats::median(y_all, na.rm = TRUE), digits = digits_median)
  ov_q1     <- round(stats::quantile(y_all, 0.25, na.rm = TRUE), digits = 0L)
  ov_q3     <- round(stats::quantile(y_all, 0.75, na.rm = TRUE), digits = 0L)
  overall_stats <- list(median = ov_median, q1 = ov_q1, q3 = ov_q3)

  # 2. Per-group stats
  group_stats <- mysterycall_wait_time_by_group(
    data          = df,
    outcome_col   = outcome_col,
    group_col     = group_col,
    digits_median = digits_median,
    digits_q      = 0L,
    filter_positive = FALSE,
    output_dir    = NA
  )

  # 3. Levels and reference
  grp_vec   <- df[[group_col]]
  all_levels <- if (is.factor(grp_vec)) levels(grp_vec) else sort(unique(grp_vec))

  if (is.null(reference)) {
    reference <- all_levels[1L]
  } else if (!reference %in% all_levels) {
    stop(sprintf(
      "Reference level '%s' not found in `%s`.\nAvailable levels: %s",
      reference, group_col, paste(all_levels, collapse = ", ")
    ), call. = FALSE)
  }

  non_ref_levels <- setdiff(all_levels, reference)
  p_values       <- setNames(numeric(0), character(0))

  # 4. Fit Poisson GLM if there are multiple levels
  if (length(non_ref_levels) >= 1L) {
    grp_factor   <- stats::relevel(factor(grp_vec), ref = reference)
    y_out        <- df[[outcome_col]]
    tryCatch({
      fit <- stats::glm(y_out ~ grp_factor, family = stats::poisson(link = "log"))
      coef_sum  <- summary(fit)$coefficients
      for (lvl in non_ref_levels) {
        term_name <- paste0("grp_factor", lvl)
        if (term_name %in% rownames(coef_sum)) {
          p_raw           <- coef_sum[term_name, "Pr(>|z|)"]
          p_values[lvl]   <- round(p_raw, digits = digits_p)
        }
      }
    }, error = function(e) {
      message("Poisson GLM failed: ", conditionMessage(e))
    })
  }

  # 5. Build sentence
  overall_clause <- sprintf(
    "The median wait time across all %s was %g business days (IQR: %g\u2013%g).",
    group_col,
    ov_median, ov_q1, ov_q3
  )

  per_group_parts <- character(nrow(group_stats))
  for (i in seq_len(nrow(group_stats))) {
    lvl   <- group_stats[[group_col]][i]
    med_i <- group_stats$median_days[i]
    q1_i  <- group_stats$q1[i]
    q3_i  <- group_stats$q3[i]
    per_group_parts[i] <- sprintf(
      "%g days (IQR: %g\u2013%g) for %s",
      med_i, q1_i, q3_i, lvl
    )
  }

  specific_clause <- if (length(per_group_parts) > 0L) {
    paste0(
      "Specifically, the median wait time was ",
      paste(per_group_parts, collapse = ", "),
      "."
    )
  } else {
    ""
  }

  pval_clauses <- character(length(p_values))
  pv_names     <- names(p_values)
  for (j in seq_along(p_values)) {
    pval_clauses[j] <- sprintf(
      "The p-value for %s vs %s was %s.",
      pv_names[j], reference, format(p_values[j], digits = digits_p)
    )
  }

  sentence <- paste(
    trimws(c(overall_clause, specific_clause, pval_clauses)),
    collapse = " "
  )
  sentence <- gsub("\\s{2,}", " ", sentence)

  list(
    sentence      = sentence,
    overall_stats = overall_stats,
    group_stats   = group_stats,
    p_values      = p_values
  )
}
