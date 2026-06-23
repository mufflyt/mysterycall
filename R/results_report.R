#' One-call manuscript results report
#'
#' @name results_report
NULL

#' Generate a complete manuscript results report from a fitted model
#'
#' Produces every component needed for the results section of a mystery-caller
#' manuscript in a single call: a combined IRR + absolute-days table, a
#' prose results paragraph, acceptance-rate summary (when `data` is supplied),
#' and an optional `.docx` export.
#'
#' This is intentionally a thin wrapper: each component can also be generated
#' individually via [mysterycall_combined_results_table()],
#' [mysterycall_write_results_paragraph()], [mysterycall_irr_to_days()],
#' [mysterycall_acceptance_rate()], and [mysterycall_export_results_docx()].
#'
#' @param model_result A `mysterycall_poisson_model` or `mysterycall_nb_model`
#'   object returned by [mysterycall_poisson_model()] or [mysterycall_nb_model()].
#' @param baseline_mean Numeric scalar. Observed mean wait days in the reference
#'   group (e.g. `mean(data$wait_days[data$insurance == "BCBS"])`). Used to
#'   convert IRRs to absolute day differences. Pass `NULL` to omit day columns.
#' @param exposure_col Character scalar. Name of the exposure variable in the
#'   model (e.g. `"insurance"`). Required for the prose paragraph and for
#'   filtering IRR-to-days output to a single predictor.
#' @param ref_group Character scalar. Label for the reference group, used in
#'   the prose paragraph and day-difference sentences (e.g. `"BCBS"`).
#' @param data Optional data frame. When supplied, `mysterycall_acceptance_rate()`
#'   is called to produce Panel A of the acceptance table. Must contain
#'   `accepted_col` and `group_col` columns.
#' @param accepted_col Character scalar. Name of the 0/1 (or logical) column
#'   indicating whether the office accepted the appointment. Default
#'   `"contact_office"`. Used only when `data` is not `NULL`.
#' @param group_col Character scalar. Column name for the grouping variable in
#'   the acceptance table (e.g. `"insurance"`). Used only when `data` is not
#'   `NULL`.
#' @param outcome_label Character scalar passed to
#'   [mysterycall_write_results_paragraph()]. Default
#'   `"appointment wait time"`.
#' @param digits Integer. Decimal places for IRR and CI in the table.
#'   Default `2L`.
#' @param include_intercept Logical. Include the intercept row? Default `FALSE`.
#' @param output_path Character scalar or `NULL`. When a `.docx` path is
#'   supplied (e.g. `"results/Table2.docx"`), [mysterycall_export_results_docx()]
#'   is called to write the combined table and paragraph to Word. Requires the
#'   `flextable` and `officer` packages.
#'
#' @return A list of class `mysterycall_results_report` with elements:
#' \describe{
#'   \item{`combined_table`}{Data frame from [mysterycall_combined_results_table()].
#'     Columns: `Term`, `IRR`, `IRR 95% CI`, `p-value`, `Days Diff`, `Days 95% CI`,
#'     `Significance`. Day columns are `NA` when `baseline_mean = NULL`.}
#'   \item{`irr_days`}{A `mysterycall_irr_days` object from
#'     [mysterycall_irr_to_days()], or `NULL` when `baseline_mean = NULL`.}
#'   \item{`paragraph`}{Character scalar. Prose results paragraph from
#'     [mysterycall_write_results_paragraph()].}
#'   \item{`day_sentences`}{Character vector. One day-difference sentence per
#'     exposure-level row, or `NULL` when `baseline_mean = NULL`.}
#'   \item{`acceptance`}{List from [mysterycall_acceptance_rate()], or `NULL`
#'     when `data = NULL`.}
#'   \item{`docx_path`}{Character scalar path to the exported `.docx` file,
#'     or `NULL` when `output_path = NULL`.}
#' }
#'
#' @family manuscript
#' @seealso
#'   [mysterycall_combined_results_table()],
#'   [mysterycall_irr_to_days()],
#'   [mysterycall_write_results_paragraph()],
#'   [mysterycall_acceptance_rate()],
#'   [mysterycall_export_results_docx()]
#' @export
#'
#' @examplesIf requireNamespace("lme4", quietly = TRUE)
#' set.seed(42)
#' df <- data.frame(
#'   wait    = rpois(60, 21),
#'   ins     = rep(c("Medicaid", "BCBS"), 30),
#'   phys    = rep(paste0("Dr", 1:10), each = 6),
#'   stringsAsFactors = FALSE
#' )
#' fit <- mysterycall_poisson_model(df, "wait", "ins", "phys")
#' report <- mysterycall_results_report(
#'   fit,
#'   baseline_mean = 21,
#'   exposure_col  = "ins",
#'   ref_group     = "BCBS"
#' )
#' print(report)
mysterycall_results_report <- function(model_result,
                                       baseline_mean    = NULL,
                                       exposure_col     = NULL,
                                       ref_group        = NULL,
                                       data             = NULL,
                                       accepted_col     = "contact_office",
                                       group_col        = NULL,
                                       outcome_label    = "appointment wait time",
                                       digits           = 2L,
                                       include_intercept = FALSE,
                                       output_path      = NULL) {

  if (!inherits(model_result, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    stop(
      "`model_result` must be a `mysterycall_poisson_model` or `mysterycall_nb_model`.",
      call. = FALSE
    )
  }
  if (!is.null(baseline_mean) &&
      (!is.numeric(baseline_mean) || length(baseline_mean) != 1L || baseline_mean <= 0)) {
    stop("`baseline_mean` must be a single positive number or NULL.", call. = FALSE)
  }
  if (!is.null(exposure_col) &&
      (!is.character(exposure_col) || length(exposure_col) != 1L)) {
    stop("`exposure_col` must be a single character string or NULL.", call. = FALSE)
  }
  if (!is.null(data) && !is.data.frame(data)) {
    stop("`data` must be a data frame or NULL.", call. = FALSE)
  }

  # -- combined IRR + days table ------------------------------------------------
  combined <- mysterycall_combined_results_table(
    model_result      = model_result,
    baseline_mean     = baseline_mean,
    exposure_col      = exposure_col,
    ref_group         = ref_group,
    digits            = digits,
    include_intercept = include_intercept
  )

  # -- IRR to days (full object, for sentences) ---------------------------------
  irr_days <- NULL
  day_sentences <- NULL
  if (!is.null(baseline_mean) && !is.null(exposure_col)) {
    irr_days <- tryCatch(
      mysterycall_irr_to_days(
        model_result  = model_result,
        baseline_mean = baseline_mean,
        exposure_col  = exposure_col,
        ref_group     = ref_group
      ),
      error = function(e) {
        warning("mysterycall_irr_to_days() failed: ", conditionMessage(e), call. = FALSE)
        NULL
      }
    )
    if (!is.null(irr_days)) day_sentences <- irr_days$sentences
  }

  # -- prose results paragraph --------------------------------------------------
  paragraph <- NULL
  if (!is.null(exposure_col) && !is.null(ref_group)) {
    paragraph <- tryCatch(
      mysterycall_write_results_paragraph(
        model_result  = model_result,
        ref_group     = ref_group,
        exposure_col  = exposure_col,
        outcome_label = outcome_label
      ),
      error = function(e) {
        warning("mysterycall_write_results_paragraph() failed: ",
                conditionMessage(e), call. = FALSE)
        NULL
      }
    )
  }

  # -- acceptance rates ---------------------------------------------------------
  acceptance <- NULL
  if (!is.null(data)) {
    if (!is.null(group_col) && !(group_col %in% names(data))) {
      warning("`group_col` '", group_col, "' not found in `data`; skipping acceptance table.",
              call. = FALSE)
      group_col <- NULL
    }
    acceptance <- tryCatch(
      mysterycall_acceptance_rate(
        data         = data,
        accepted_col = accepted_col,
        group_by     = group_col
      ),
      error = function(e) {
        warning("mysterycall_acceptance_rate() failed: ", conditionMessage(e), call. = FALSE)
        NULL
      }
    )
  }

  # -- Word export --------------------------------------------------------------
  docx_path <- NULL
  if (!is.null(output_path)) {
    docx_path <- tryCatch(
      mysterycall_export_results_docx(
        table       = combined,
        paragraph   = paragraph,
        title       = "Results",
        output_path = output_path
      ),
      error = function(e) {
        warning("mysterycall_export_results_docx() failed: ", conditionMessage(e),
                call. = FALSE)
        NULL
      }
    )
  }

  structure(
    list(
      combined_table = combined,
      irr_days       = irr_days,
      paragraph      = paragraph,
      day_sentences  = day_sentences,
      acceptance     = acceptance,
      docx_path      = docx_path
    ),
    class = "mysterycall_results_report"
  )
}


#' Print method for mysterycall_results_report
#'
#' @param x A `mysterycall_results_report` object.
#' @param ... Ignored.
#' @return `invisible(x)`.
#' @family manuscript
#' @export
print.mysterycall_results_report <- function(x, ...) {
  cat("=== Mystery-Caller Results Report ===\n\n")

  cat("-- Combined Results Table --\n")
  print(x$combined_table, row.names = FALSE)
  cat("\n")

  if (!is.null(x$paragraph)) {
    cat("-- Results Paragraph --\n")
    cat(strwrap(x$paragraph, width = 80), sep = "\n")
    cat("\n\n")
  }

  if (!is.null(x$day_sentences)) {
    cat("-- Absolute Day-Difference Sentences --\n")
    for (s in x$day_sentences) cat(" ", s, "\n")
    cat("\n")
  }

  if (!is.null(x$acceptance)) {
    cat("-- Appointment Acceptance Rates --\n")
    print(x$acceptance$summary)
    cat("\n")
  }

  if (!is.null(x$docx_path)) {
    cat("Word document written to:", x$docx_path, "\n\n")
  }

  invisible(x)
}
