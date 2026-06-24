#' Convert IRRs to absolute wait-time differences in days
#'
#' @name mysterycall_irr_to_days
NULL

#' Convert incidence rate ratios to absolute day differences
#'
#' Translates incidence rate ratios (IRRs) and their Wald confidence intervals
#' from a fitted mystery-caller model into clinically interpretable absolute
#' differences in wait days. Given a reference-group mean, the conversion is:
#'
#' \deqn{\text{days difference} = \mu_{\text{ref}} \times (\text{IRR} - 1)}
#' \deqn{\text{CI in days} = \mu_{\text{ref}} \times (\text{CI}_{\text{lower/upper}} - 1)}
#'
#' Positive values mean the comparison group waits *longer*; negative values
#' mean the comparison group waits *fewer* days than the reference group.
#'
#' @param model_result A `mysterycall_poisson_model` or `mysterycall_nb_model`
#'   object, or a data frame with columns `term`, `irr`, `ci_lower`,
#'   `ci_upper`, and (optionally) `p_value_fmt`.
#' @param baseline_mean Numeric scalar. The observed mean wait days in the
#'   reference group (e.g. the mean for BCBS callers). Obtain this from
#'   [mysterycall_wait_time_summary()] or `mean(data$wait_days[data$insurance == "BCBS"])`.
#' @param exposure_col Character scalar. Name of the exposure variable whose
#'   terms to report (e.g. `"insurance"`). Only rows whose `term` starts with
#'   this string are included. Pass `NULL` to include all non-intercept terms.
#' @param ref_group Character scalar. Label for the reference group used in the
#'   narrative sentences (e.g. `"BCBS"`). When `NULL`, sentences omit the
#'   "compared with X" clause.
#' @param digits Integer. Decimal places for days in the output table and
#'   sentences. Default `1L`.
#' @param irr_digits Integer. Decimal places for IRR in the sentences. Default `2L`.
#'
#' @return A list of class `mysterycall_irr_days` with elements:
#' \describe{
#'   \item{`table`}{Data frame with columns: `term`, `level` (group label
#'     stripped of the exposure prefix), `irr`, `days_mean` (reference-group
#'     mean x IRR), `days_diff` (days_mean - baseline_mean), `days_ci_lower`,
#'     `days_ci_upper`, `direction` (`"more"` or `"fewer"`), `p_value_fmt`.}
#'   \item{`sentences`}{Character vector. One manuscript-ready sentence per row.}
#'   \item{`paragraph`}{Character scalar. All sentences joined into a paragraph.}
#'   \item{`baseline_mean`}{Numeric. The baseline_mean supplied by the caller.}
#' }
#'
#' @section Example sentence:
#' *"Medicaid-insured callers waited a mean of 4.3 additional days compared
#'  with BCBS (95% CI 1.2 to 7.4 days; IRR 1.24, p = 0.003)."*
#'
#' @family reporting
#' @seealso [mysterycall_poisson_model()], [mysterycall_nb_model()],
#'   [mysterycall_write_results_paragraph()] for IRR-scale reporting;
#'   [mysterycall_irr_plot()] to visualise the same estimates.
#' @export
#'
#' @examples
#' irr_tbl <- data.frame(
#'   term        = c("(Intercept)", "insuranceMedicaid", "insuranceUninsured"),
#'   irr         = c(1.00, 1.28, 0.81),
#'   ci_lower    = c(NA,   1.05, 0.61),
#'   ci_upper    = c(NA,   1.56, 1.07),
#'   p_value_fmt = c(NA,   "0.014", "0.134"),
#'   stringsAsFactors = FALSE
#' )
#' result <- mysterycall_irr_to_days(
#'   irr_tbl,
#'   baseline_mean = 21,
#'   exposure_col  = "insurance",
#'   ref_group     = "BCBS"
#' )
#' result$table
#' cat(result$paragraph)
mysterycall_irr_to_days <- function(model_result,
                                     baseline_mean,
                                     exposure_col  = NULL,
                                     ref_group     = NULL,
                                     digits        = 1L,
                                     irr_digits    = 2L) {

  # -- validate baseline_mean ---------------------------------------------------
  if (!is.numeric(baseline_mean) || length(baseline_mean) != 1L || baseline_mean <= 0) {
    stop("`baseline_mean` must be a single positive number (the reference-group mean wait days).",
         call. = FALSE)
  }

  # -- extract irr_table --------------------------------------------------------
  if (inherits(model_result, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    if (is.null(model_result$irr_table)) {
      stop("model_result$irr_table is NULL.", call. = FALSE)
    }
    irr_tbl <- as.data.frame(model_result$irr_table)
  } else if (is.data.frame(model_result)) {
    irr_tbl <- model_result
  } else {
    stop(
      "`model_result` must be a mysterycall_poisson_model, mysterycall_nb_model, or a data frame.",
      call. = FALSE
    )
  }

  required <- c("term", "irr", "ci_lower", "ci_upper")
  missing_cols <- setdiff(required, names(irr_tbl))
  if (length(missing_cols)) {
    stop("irr_table is missing required columns: ",
         paste(missing_cols, collapse = ", "), ".", call. = FALSE)
  }

  digits     <- as.integer(digits)
  irr_digits <- as.integer(irr_digits)

  # -- filter to exposure of interest -------------------------------------------
  if (!is.null(exposure_col)) {
    if (!is.character(exposure_col) || length(exposure_col) != 1L) {
      stop("`exposure_col` must be a single character string or NULL.", call. = FALSE)
    }
    rows <- startsWith(as.character(irr_tbl$term), exposure_col)
  } else {
    rows <- !grepl("^\\(Intercept\\)$", irr_tbl$term)
  }

  irr_tbl <- irr_tbl[rows, , drop = FALSE]

  if (!nrow(irr_tbl)) {
    stop(
      if (!is.null(exposure_col))
        sprintf("No terms starting with '%s' found in irr_table.", exposure_col)
      else
        "No non-intercept terms found in irr_table.",
      call. = FALSE
    )
  }

  # -- strip exposure prefix from term to get level label -----------------------
  if (!is.null(exposure_col)) {
    level_label <- sub(paste0("^", exposure_col), "", as.character(irr_tbl$term))
  } else {
    level_label <- as.character(irr_tbl$term)
  }

  # -- compute absolute day differences -----------------------------------------
  irr_vals  <- as.numeric(irr_tbl$irr)
  ci_lo     <- as.numeric(irr_tbl$ci_lower)
  ci_hi     <- as.numeric(irr_tbl$ci_upper)

  days_mean      <- baseline_mean * irr_vals
  days_diff      <- baseline_mean * (irr_vals - 1)
  days_ci_lower  <- baseline_mean * (ci_lo - 1)
  days_ci_upper  <- baseline_mean * (ci_hi - 1)

  direction <- ifelse(days_diff >= 0, "more", "fewer")

  p_fmt <- if ("p_value_fmt" %in% names(irr_tbl)) {
    as.character(irr_tbl$p_value_fmt)
  } else if ("p_value" %in% names(irr_tbl)) {
    ifelse(
      is.na(irr_tbl$p_value), NA_character_,
      ifelse(irr_tbl$p_value < 0.001, "<0.001",
             sprintf("%.3f", as.numeric(irr_tbl$p_value)))
    )
  } else {
    rep(NA_character_, nrow(irr_tbl))
  }

  tbl <- data.frame(
    term          = as.character(irr_tbl$term),
    level         = level_label,
    irr           = irr_vals,
    days_mean     = days_mean,
    days_diff     = days_diff,
    days_ci_lower = days_ci_lower,
    days_ci_upper = days_ci_upper,
    direction     = direction,
    p_value_fmt   = p_fmt,
    stringsAsFactors = FALSE
  )

  # -- build sentences ----------------------------------------------------------
  ref_clause <- if (!is.null(ref_group)) {
    sprintf("compared with %s", ref_group)
  } else {
    "compared with the reference group"
  }

  sentences <- character(nrow(tbl))
  for (i in seq_len(nrow(tbl))) {
    r         <- tbl[i, ]
    abs_diff  <- abs(r$days_diff)
    abs_lo    <- abs(r$days_ci_lower)
    abs_hi    <- abs(r$days_ci_upper)
    irr_str   <- formatC(r$irr,      digits = irr_digits, format = "f")
    diff_str  <- formatC(abs_diff,   digits = digits,     format = "f")
    lo_str    <- formatC(abs_lo,     digits = digits,     format = "f")
    hi_str    <- formatC(abs_hi,     digits = digits,     format = "f")

    p_part <- if (!is.na(r$p_value_fmt)) sprintf("; p = %s", r$p_value_fmt) else ""

    sentences[i] <- sprintf(
      "%s-insured callers waited a mean of %s %s days %s (95%% CI %s to %s days; IRR %s%s).",
      r$level, diff_str, r$direction, ref_clause,
      lo_str, hi_str, irr_str, p_part
    )
  }

  structure(
    list(
      table         = tbl,
      sentences     = sentences,
      paragraph     = paste(sentences, collapse = " "),
      baseline_mean = baseline_mean
    ),
    class = "mysterycall_irr_days"
  )
}


#' Print method for mysterycall_irr_days
#'
#' @param x A `mysterycall_irr_days` object.
#' @param digits Integer. Decimal places for the table display. Default `1`.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family reporting
#' @export
print.mysterycall_irr_days <- function(x, digits = 1, ...) {
  cat(sprintf("Reference-group mean: %.1f days\n\n", x$baseline_mean))

  tbl <- x$table
  tbl$irr         <- round(tbl$irr,          digits + 1L)
  tbl$days_diff   <- round(tbl$days_diff,    digits)
  tbl$days_ci_lower <- round(tbl$days_ci_lower, digits)
  tbl$days_ci_upper <- round(tbl$days_ci_upper, digits)

  print(tbl[, c("level", "irr", "days_diff", "days_ci_lower", "days_ci_upper",
                "direction", "p_value_fmt")],
        row.names = FALSE)

  cat("\nManuscript sentences:\n")
  for (s in x$sentences) cat(" ", s, "\n")

  invisible(x)
}
