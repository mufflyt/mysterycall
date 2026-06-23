#' Combined IRR and absolute-days publication table
#'
#' @name combined_results_table
NULL

#' Merge IRR results and absolute day differences into one publication table
#'
#' Builds a single data frame suitable for a manuscript Table 2 by combining
#' incidence rate ratios (and their Wald CIs) with clinically interpretable
#' absolute day differences derived from [mysterycall_irr_to_days()].
#'
#' @param model_result A `mysterycall_poisson_model` or `mysterycall_nb_model`
#'   object, or a data frame with columns `term`, `irr`, `ci_lower`, `ci_upper`,
#'   and `p_value`.
#' @param baseline_mean Numeric scalar. Reference-group mean wait days used to
#'   convert IRRs to day differences. Pass `NULL` (default) to omit the day
#'   columns entirely.
#' @param exposure_col Character scalar. Name of the exposure variable (e.g.
#'   `"insurance"`). Passed to [mysterycall_irr_to_days()] to limit day rows.
#'   `NULL` includes all non-intercept terms.
#' @param ref_group Character scalar. Reference-group label for day sentences
#'   (e.g. `"BCBS"`). `NULL` omits the "compared with X" clause.
#' @param digits Integer. Decimal places for IRR and CI columns. Default `2L`.
#' @param include_intercept Logical. Include the intercept row? Default `FALSE`.
#'
#' @return A data frame with columns (in order):
#' \describe{
#'   \item{`Term`}{Model term name.}
#'   \item{`IRR`}{Formatted IRR string.}
#'   \item{`IRR 95% CI`}{en-dash separated CI string, e.g. `"1.05–1.56"`.}
#'   \item{`p-value`}{Formatted p-value string.}
#'   \item{`Days Diff`}{Signed absolute day difference (`"+4.3"`), or `NA`
#'     when `baseline_mean` is `NULL`.}
#'   \item{`Days 95% CI`}{`"lower to upper"` in days, or `NA`.}
#'   \item{`Significance`}{`"*"` when p < 0.05, `""` otherwise.}
#' }
#' The data frame carries two attributes:
#' \describe{
#'   \item{`significant_rows`}{Integer vector of row indices where p < 0.05.}
#'   \item{`has_days`}{Logical. `TRUE` when `baseline_mean` was supplied.}
#' }
#'
#' @family manuscript
#' @seealso [mysterycall_format_results_table()], [mysterycall_irr_to_days()],
#'   [mysterycall_export_results_docx()]
#' @export
#'
#' @examples
#' irr_df <- data.frame(
#'   term        = c("insuranceMedicaid", "insuranceUninsured"),
#'   irr         = c(1.28, 0.81),
#'   ci_lower    = c(1.05, 0.61),
#'   ci_upper    = c(1.56, 1.07),
#'   p_value     = c(0.014, 0.134),
#'   stringsAsFactors = FALSE
#' )
#' mysterycall_combined_results_table(irr_df, baseline_mean = 21,
#'                                    exposure_col = "insurance",
#'                                    ref_group    = "BCBS")
mysterycall_combined_results_table <- function(model_result,
                                               baseline_mean     = NULL,
                                               exposure_col      = NULL,
                                               ref_group         = NULL,
                                               digits            = 2L,
                                               include_intercept = FALSE) {

  if (!is.null(baseline_mean)) {
    if (!is.numeric(baseline_mean) || length(baseline_mean) != 1L ||
        is.na(baseline_mean) || baseline_mean <= 0) {
      stop("`baseline_mean` must be a single positive number.", call. = FALSE)
    }
  }

  # extract raw irr table
  if (inherits(model_result, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    raw <- as.data.frame(model_result$irr_table)
  } else if (is.data.frame(model_result)) {
    raw <- model_result
  } else {
    stop(
      "`model_result` must be a `mysterycall_poisson_model`, `mysterycall_nb_model`, or a data frame.",
      call. = FALSE
    )
  }

  required <- c("term", "irr", "ci_lower", "ci_upper", "p_value")
  missing_cols <- setdiff(required, names(raw))
  if (length(missing_cols)) {
    stop("irr_table is missing required columns: ",
         paste(missing_cols, collapse = ", "), ".", call. = FALSE)
  }

  digits <- as.integer(digits)

  if (!include_intercept) {
    raw <- raw[raw$term != "(Intercept)", , drop = FALSE]
  }
  if (nrow(raw) == 0L) stop("No rows remaining after filtering.", call. = FALSE)

  fmt      <- paste0("%.", digits, "f")
  irr_str  <- sprintf(fmt, as.numeric(raw$irr))
  ci_str   <- sprintf(paste0(fmt, "–", fmt),
                      as.numeric(raw$ci_lower),
                      as.numeric(raw$ci_upper))

  p_val    <- as.numeric(raw$p_value)
  p_str    <- ifelse(
    is.na(p_val), NA_character_,
    ifelse(p_val < 0.001, "< 0.001", sprintf("%.3f", p_val))
  )

  sig <- !is.na(p_val) & p_val < 0.05

  days_diff_str <- rep(NA_character_, nrow(raw))
  days_ci_str   <- rep(NA_character_, nrow(raw))

  if (!is.null(baseline_mean)) {
    days_result <- mysterycall_irr_to_days(
      model_result  = model_result,
      baseline_mean = baseline_mean,
      exposure_col  = exposure_col,
      ref_group     = ref_group,
      digits        = 1L
    )
    days_tbl <- days_result$table
    m        <- match(as.character(raw$term), as.character(days_tbl$term))
    has_m    <- !is.na(m)

    if (any(has_m)) {
      dd  <- as.numeric(days_tbl$days_diff[m[has_m]])
      dlo <- as.numeric(days_tbl$days_ci_lower[m[has_m]])
      dhi <- as.numeric(days_tbl$days_ci_upper[m[has_m]])

      days_diff_str[has_m] <- sprintf("%+.1f", dd)
      days_ci_str[has_m]   <- sprintf("%.1f to %.1f", dlo, dhi)
    }
  }

  out <- data.frame(
    Term          = as.character(raw$term),
    IRR           = irr_str,
    `IRR 95% CI`  = ci_str,
    `p-value`     = p_str,
    `Days Diff`   = days_diff_str,
    `Days 95% CI` = days_ci_str,
    Significance  = ifelse(sig, "*", ""),
    stringsAsFactors = FALSE,
    check.names  = FALSE
  )

  attr(out, "significant_rows") <- which(sig)
  attr(out, "has_days")         <- !is.null(baseline_mean)

  out
}
