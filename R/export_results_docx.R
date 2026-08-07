#' Export results table to a styled Word document
#'
#' @name export_results_docx
NULL

#' Write a styled manuscript results table to a .docx file
#'
#' Converts a results data frame (typically from
#' [mysterycall_combined_results_table()]) into a formatted Word document using
#' `flextable` and `officer`. Significant rows (p < 0.05) are bold when
#' `attr(table, "significant_rows")` is set.
#'
#' @param table A data frame to render as a table. Typically the output of
#'   [mysterycall_combined_results_table()].
#' @param paragraph Character scalar. Optional results paragraph to insert
#'   before the table. Default `NULL` (omit).
#' @param title Character scalar. Document heading. Default `"Results"`.
#'   Pass `NULL` to omit the heading.
#' @param output_path Character scalar. Path to the output `.docx` file.
#'   Default `"results.docx"`.
#' @param author Character scalar. Optional author line inserted after the
#'   heading. Default `NULL`.
#' @param bold_significant Logical. Whether to bold rows where p < 0.05
#'   (determined from `attr(table, "significant_rows")`). Default `TRUE`.
#'
#' @return `output_path`, returned invisibly after writing the file.
#'
#' @note Both `flextable` and `officer` are in the package Suggests field.
#'   Install them with `install.packages(c("flextable", "officer"))`.
#'
#' @family manuscript
#' @seealso [mysterycall_combined_results_table()] to build the input table;
#'   [mysterycall_results_report()] for a one-call wrapper.
#' @export
#'
#' @examplesIf interactive()
#' tbl <- data.frame(
#'   Term = c("Medicaid", "Uninsured"),
#'   IRR  = c("1.28", "0.81"),
#'   `p-value` = c("0.014", "0.134"),
#'   check.names = FALSE
#' )
#' attr(tbl, "significant_rows") <- 1L
#' mysterycall_export_results_docx(tbl, title = "Table 2",
#'                                 output_path = tempfile(fileext = ".docx"))
mysterycall_export_results_docx <- function(table,
                                            paragraph        = NULL,
                                            title            = "Results",
                                            output_path      = "results.docx",
                                            author           = NULL,
                                            bold_significant = TRUE) {

  if (!is.data.frame(table)) {
    stop("`table` must be a data frame.", call. = FALSE)
  }
  if (!requireNamespace("flextable", quietly = TRUE)) {
    stop(
      "Package 'flextable' is required. Install with: install.packages('flextable')",
      call. = FALSE
    )
  }
  if (!requireNamespace("officer", quietly = TRUE)) {
    stop(
      "Package 'officer' is required. Install with: install.packages('officer')",
      call. = FALSE
    )
  }
  if (!grepl("\\.docx$", output_path, ignore.case = TRUE)) {
    warning("`output_path` does not end in '.docx'.", call. = FALSE)
  }

  doc <- officer::read_docx()

  if (!is.null(title)) {
    doc <- officer::body_add_par(doc, as.character(title), style = "heading 1")
  }
  if (!is.null(author)) {
    doc <- officer::body_add_par(doc, as.character(author), style = "Normal")
  }
  if (!is.null(paragraph)) {
    doc <- officer::body_add_par(doc, as.character(paragraph), style = "Normal")
    doc <- officer::body_add_par(doc, "", style = "Normal")
  }

  ft <- flextable::flextable(table)
  ft <- flextable::theme_booktabs(ft)
  ft <- flextable::autofit(ft)

  if (isTRUE(bold_significant)) {
    sig_rows <- attr(table, "significant_rows")
    if (!is.null(sig_rows) && length(sig_rows) > 0L) {
      ft <- flextable::bold(ft, i = sig_rows, part = "body")
    }
  }

  doc <- flextable::body_add_flextable(doc, ft)

  out_dir <- dirname(output_path)
  if (nzchar(out_dir) && !dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  }
  print(doc, target = output_path)

  message("Results written to: ", output_path)
  invisible(output_path)
}
