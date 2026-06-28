#' Waffle chart of insurance acceptance rates
#'
#' Produces a side-by-side waffle chart comparing appointment acceptance rates
#' for two insurance groups (e.g. Medicaid vs. Blue Cross Blue Shield).
#' Each square represents one call; shading encodes Accepted vs. Declined.
#'
#' Inspired by Nicola Rennie (2024), "Five Charts You Can Make with the
#' waffle Package", \url{https://nrennie.rbind.io/}.
#'
#' @param acceptance_result A data frame with at least columns
#'   `insurance_type`, `outcome` (values `"Accepted"` / `"Declined"`), and
#'   `n`.  Typically the output of `table(df$insurance_type, df$outcome)` or a
#'   `dplyr::count()` summary.
#' @param medicaid_label Character scalar.  Label for the Medicaid panel.
#'   Default `"Medicaid"`.
#' @param bcbs_label Character scalar.  Label for the BCBS panel.
#'   Default `"Blue Cross / Blue Shield"`.
#' @param colors Named character vector.  Colours for each outcome level.
#'   Default `c(Accepted = "grey20", Declined = "grey85")`.
#' @param rows Integer.  Number of rows in each waffle grid.  Default `10L`.
#' @param title Character or `NULL`.  Main chart title added via
#'   \pkg{patchwork}.  `NULL` produces no title.
#' @param flip Logical.  If `TRUE`, flip the waffle orientation (columns
#'   become rows).  Default `FALSE`.
#' @param monochrome Logical.  If `TRUE` (default), apply
#'   [mysterycall_bw_theme()] to each panel for Greene-journal compatibility.
#' @param dpi Integer.  Resolution for the saved PNG.  Default `150L`.
#' @param output_dir Character scalar or `NA`.  Directory for PNG output.
#'   `NA` skips writing.  Defaults to a session temp directory.
#' @param filename Character scalar.  Output file name.
#'   Default `"acceptance_waffle.png"`.
#'
#' @return A `patchwork` / `ggplot` object, returned invisibly.
#'
#' @note Requires the \pkg{waffle} package (GitHub-only -- not on CRAN) and
#'   \pkg{patchwork}.  Install with:
#'   `remotes::install_github("hrbrmstr/waffle")` and
#'   `install.packages("patchwork")`.
#'
#' @importFrom ggplot2 ggsave
#' @family visualization
#' @export
#'
#' @examples
#' \dontrun{
#' acc <- data.frame(
#'   insurance_type = c("Medicaid", "Medicaid", "BCBS", "BCBS"),
#'   outcome        = c("Accepted", "Declined", "Accepted", "Declined"),
#'   n              = c(47L, 53L, 72L, 28L),
#'   stringsAsFactors = FALSE
#' )
#' mysterycall_acceptance_waffle(acc, output_dir = NA)
#' }
mysterycall_acceptance_waffle <- function(
    acceptance_result,
    medicaid_label = "Medicaid",
    bcbs_label     = "Blue Cross / Blue Shield",
    colors         = c(Accepted = "grey20", Declined = "grey85"),
    rows           = 10L,
    title          = NULL,
    flip           = FALSE,
    monochrome     = TRUE,
    dpi            = 150L,
    output_dir     = NULL,
    filename       = "acceptance_waffle.png"
) {
  waffle_ns <- tryCatch(
    loadNamespace("waffle"),
    error = function(e) NULL
  )
  if (is.null(waffle_ns)) {
    stop(
      "Package 'waffle' is required but not installed.\n",
      "Install with: remotes::install_github(\"hrbrmstr/waffle\")",
      call. = FALSE
    )
  }
  if (!requireNamespace("patchwork", quietly = TRUE)) {
    stop("Package 'patchwork' is required. Install with: install.packages('patchwork')",
         call. = FALSE)
  }

  checkmate::assert_data_frame(acceptance_result, min.rows = 1L)
  checkmate::assert_names(names(acceptance_result),
                          must.include = c("insurance_type", "outcome", "n"))
  checkmate::assert_string(medicaid_label)
  checkmate::assert_string(bcbs_label)
  checkmate::assert_integerish(rows, lower = 1L, len = 1L)
  checkmate::assert_flag(flip)
  checkmate::assert_flag(monochrome)

  waffle_fn <- get("waffle", envir = waffle_ns)

  .make_panel <- function(ins_label, display_label) {
    sub <- acceptance_result[acceptance_result$insurance_type == ins_label, , drop = FALSE]
    if (nrow(sub) == 0L) {
      stop(sprintf("No rows found for insurance_type == '%s'", ins_label), call. = FALSE)
    }
    vals <- stats::setNames(as.integer(sub$n), sub$outcome)

    p <- waffle_fn(
      parts = vals,
      rows  = rows,
      flip  = flip,
      colors = colors[names(vals)],
      title  = display_label,
      pad    = 0
    )

    if (isTRUE(monochrome)) {
      p <- p + mysterycall_bw_theme()
    }
    p
  }

  p_medicaid <- .make_panel(medicaid_label, medicaid_label)
  p_bcbs     <- .make_panel(bcbs_label,     bcbs_label)

  wrap_plots_fn <- get("wrap_plots", envir = loadNamespace("patchwork"))
  combined <- wrap_plots_fn(p_medicaid, p_bcbs, ncol = 2L)

  if (!is.null(title)) {
    plot_annotation_fn <- get("plot_annotation", envir = loadNamespace("patchwork"))
    combined <- combined + plot_annotation_fn(title = title)
  }

  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("acceptance_waffle", create = TRUE)
  }
  if (!isTRUE(is.na(output_dir))) {
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    }
    out_path <- file.path(output_dir, filename)
    ggplot2::ggsave(out_path, plot = combined, dpi = dpi,
                    width = 10, height = 5, units = "in", bg = "white")
    message("Acceptance waffle chart saved to: ", out_path)
  }

  invisible(combined)
}
