#' Publication-Ready gt Table of Incidence Rate Ratios
#'
#' Formats a tibble of IRR estimates (typically the `$irr_table` slot from
#' [mysterycall_simple_poisson()]) into a publication-ready [gt::gt()] table
#' with a combined "IRR (95% CI)" column and optional significance stars.
#'
#' @param irr_data A data frame or tibble with at least the following columns
#'   (exact names are detected flexibly):
#'   * `term` **or** `level` — row label for each contrast.
#'   * `irr` — point estimate (incidence rate ratio).
#'   * `ci_lower` — lower bound of the confidence interval.
#'   * `ci_upper` — upper bound of the confidence interval.
#'   * `p_value` **or** `p_value_fmt` — numeric p-value **or** a
#'     pre-formatted character string. When both are present `p_value` is used
#'     for star assignment and `p_value_fmt` for display.
#' @param title Character scalar. Table title passed to [gt::tab_header()].
#'   Default `"Incidence Rate Ratios"`.
#' @param subtitle Character scalar or `NULL`. Optional subtitle passed to
#'   [gt::tab_header()].
#' @param outcome_label Character scalar. Column header for the combined
#'   estimate column. Default `"IRR (95% CI)"`.
#' @param digits Integer. Number of decimal places for rounding `irr`,
#'   `ci_lower`, and `ci_upper`. Default `2`.
#' @param add_significance_stars Logical. If `TRUE` (default), appends a
#'   `Stars` column using `***`/`**`/`*`/`""` thresholds.
#' @param footnote Character scalar. Source note appended via
#'   [gt::tab_source_note()]. Default explains the star notation.
#'
#' @return A `gt_tbl` object ready for rendering or export.
#'
#' @details
#' **Column detection** — the function looks for these column names in order:
#' * Label: `"term"`, then `"level"`.
#' * P-value (numeric, for stars): `"p_value"`, then attempts to parse
#'   `"p_value_fmt"`.
#' * P-value (display): `"p_value_fmt"` when present, otherwise the numeric
#'   `p_value` rounded to three decimal places.
#'
#' **Significance stars** — assigned from the numeric p-value:
#' | p | Stars |
#' |---|-------|
#' | < 0.001 | `***` |
#' | < 0.01  | `**`  |
#' | < 0.05  | `*`   |
#' | >= 0.05 | `""`  |
#'
#' **Bold rows** — rows where `p_value < 0.05` are styled with bold text via
#' [gt::tab_style()].
#'
#' @family outcomes
#' @seealso [mysterycall_simple_poisson()], [mysterycall_model_gt()]
#' @importFrom gt gt tab_header tab_source_note tab_style cell_text cells_body
#'   cols_label
#' @export
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'   set.seed(42)
#'   df <- data.frame(
#'     days      = rpois(90, 10),
#'     insurance = rep(c("BCBS", "Medicaid", "Medicare"), 30)
#'   )
#'   res <- mysterycall_simple_poisson(df, "days", "insurance",
#'                                     reference = "BCBS")
#'   tbl <- mysterycall_irr_table(res$irr_table)
#'   print(tbl)
#' }
mysterycall_irr_table <- function(irr_data,
                                   title                  = "Incidence Rate Ratios",
                                   subtitle               = NULL,
                                   outcome_label          = "IRR (95 95% CI)",
                                   digits                 = 2L,
                                   add_significance_stars = TRUE,
                                   footnote               = paste0(
                                     "IRR = Incidence Rate Ratio. ",
                                     "* p<0.05; ** p<0.01; *** p<0.001."
                                   )) {

  if (!requireNamespace("gt", quietly = TRUE))
    stop("Package 'gt' is required. Install with: install.packages('gt')",
         call. = FALSE)

  # ---- Input checks -----------------------------------------------------------
  if (!is.data.frame(irr_data))
    stop("`irr_data` must be a data frame or tibble.", call. = FALSE)

  nm <- names(irr_data)

  # Required numeric columns
  for (col in c("irr", "ci_lower", "ci_upper")) {
    if (!col %in% nm)
      stop(sprintf("Required column '%s' not found in `irr_data`.", col),
           call. = FALSE)
  }

  # ---- Detect label column ----------------------------------------------------
  label_col <- if ("term"  %in% nm) "term" else
               if ("level" %in% nm) "level" else
               stop("Column 'term' or 'level' not found in `irr_data`.",
                    call. = FALSE)

  # ---- Detect / build numeric p-value -----------------------------------------
  has_pval     <- "p_value"     %in% nm
  has_pval_fmt <- "p_value_fmt" %in% nm

  if (!has_pval && !has_pval_fmt)
    stop("Column 'p_value' or 'p_value_fmt' not found in `irr_data`.",
         call. = FALSE)

  if (has_pval) {
    p_num <- irr_data[["p_value"]]
    if (!is.numeric(p_num))
      stop("Column 'p_value' must be numeric.", call. = FALSE)
  } else {
    # Try to parse the formatted string
    p_num <- suppressWarnings(as.numeric(
      sub("^<\\s*", "", irr_data[["p_value_fmt"]])
    ))
  }

  # Display p-value string
  p_disp <- if (has_pval_fmt) {
    irr_data[["p_value_fmt"]]
  } else {
    ifelse(is.na(p_num), NA_character_,
           ifelse(p_num < 0.001, "< 0.001", sprintf("%.3f", p_num)))
  }

  # ---- Significance stars ------------------------------------------------------
  stars <- character(nrow(irr_data))
  if (add_significance_stars) {
    stars <- ifelse(is.na(p_num), "",
             ifelse(p_num < 0.001, "***",
             ifelse(p_num < 0.01,  "**",
             ifelse(p_num < 0.05,  "*", ""))))
  }

  # ---- Build combined IRR (95% CI) column -------------------------------------
  n_rows <- nrow(irr_data)
  if (n_rows == 0L) {
    irr_ci  <- character(0L)
    p_disp  <- character(0L)
    p_num   <- numeric(0L)
    stars   <- character(0L)
  } else {
    irr_ci <- paste0(
      round(irr_data[["irr"]],      digits), " (",
      round(irr_data[["ci_lower"]], digits), "–",
      round(irr_data[["ci_upper"]], digits), ")"
    )
  }

  # ---- Assemble display data frame --------------------------------------------
  display <- data.frame(
    Label  = irr_data[[label_col]],
    IRR_CI = irr_ci,
    P      = p_disp,
    stringsAsFactors = FALSE
  )

  if (add_significance_stars) {
    display[["Stars"]] <- stars
  }

  # ---- Build gt table ---------------------------------------------------------
  tbl <- gt::gt(display)

  # Header
  if (!is.null(subtitle)) {
    tbl <- gt::tab_header(tbl, title = title, subtitle = subtitle)
  } else {
    tbl <- gt::tab_header(tbl, title = title)
  }

  # Column labels
  tbl <- gt::cols_label(
    tbl,
    Label  = "Predictor",
    IRR_CI = outcome_label,
    P      = "p-value"
  )

  # Bold significant rows (p < 0.05)
  sig_rows <- which(!is.na(p_num) & p_num < 0.05)
  if (length(sig_rows) > 0L) {
    tbl <- gt::tab_style(
      tbl,
      style    = gt::cell_text(weight = "bold"),
      locations = gt::cells_body(rows = sig_rows)
    )
  }

  # Footnote
  if (!is.null(footnote) && nchar(footnote) > 0L) {
    tbl <- gt::tab_source_note(tbl, source_note = footnote)
  }

  tbl
}


#' Thin Wrapper: gt IRR Table from a Simple Poisson Result
#'
#' Extracts `$irr_table` from a `mysterycall_simple_poisson` object and passes
#' it to [mysterycall_irr_table()].
#'
#' @param poisson_result An object of class `mysterycall_simple_poisson`
#'   (returned by [mysterycall_simple_poisson()]).
#' @param ... Additional arguments passed to [mysterycall_irr_table()].
#'
#' @return A `gt_tbl` object.
#'
#' @family outcomes
#' @seealso [mysterycall_irr_table()], [mysterycall_simple_poisson()]
#' @export
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'   set.seed(7)
#'   df <- data.frame(
#'     days      = rpois(60, 14),
#'     insurance = rep(c("BCBS", "Medicaid"), 30)
#'   )
#'   res <- mysterycall_simple_poisson(df, "days", "insurance",
#'                                     reference = "BCBS")
#'   mysterycall_model_gt(res)
#' }
mysterycall_model_gt <- function(poisson_result, ...) {
  if (!inherits(poisson_result, "mysterycall_simple_poisson"))
    stop("`poisson_result` must be a 'mysterycall_simple_poisson' object.",
         call. = FALSE)
  mysterycall_irr_table(poisson_result$irr_table, ...)
}
