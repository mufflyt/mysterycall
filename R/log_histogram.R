#' Log-scale faceted histogram of a numeric variable by group
#'
#' A thin wrapper around a self-contained histogram builder that applies a
#' log-scale transformation to the x-axis.  Values `<= 0` are silently
#' removed before plotting (log of zero is `-Inf`).  Mirrors the source
#' pattern from the analysis Rmd (lines 1152-1165).
#'
#' @param data A data frame.
#' @param x_col Character scalar.  Name of the numeric column to plot on the
#'   x-axis.
#' @param facet_col Character scalar.  Name of the grouping column used for
#'   the facet panels.
#' @param binwidth Numeric or `NULL`.  Histogram bin width on the log scale.
#'   `NULL` (default) lets ggplot2 choose; a fixed `binwidth` can be
#'   misleading on log scales.
#' @param fill Character.  Bar fill colour.  Default `"skyblue"`.
#' @param color Character.  Bar border colour.  Default `"black"`.
#' @param alpha Numeric.  Bar transparency \[0, 1\].  Default `0.7`.
#' @param x_label Character or `NULL`.  X-axis label.  Defaults to
#'   `paste0("log10(", x_col, ")")`.
#' @param y_label Character.  Y-axis label.  Default `"Count"`.
#' @param title Character or `NULL`.  Plot title.  Defaults to
#'   `paste0("Distribution of log(", x_col, ") by ", facet_col)`.
#' @param base Numeric.  Log base.  Must be `10` (uses [ggplot2::scale_x_log10()])
#'   or `2` (uses `scale_x_continuous(trans = "log2")`).  Default `10`.
#' @param dpi Integer.  Resolution for the saved PNG.  Default `150`.
#' @param output_dir Character, `NULL`, or `NA`.  Directory for PNG output.
#'   `NULL` (default) writes to a session temp directory via
#'   [mysterycall_tempdir()].  `NA` skips writing entirely.
#' @param filename Character.  Output file name.  Default
#'   `"log_histogram.png"`.
#'
#' @return A `ggplot` object, returned invisibly.  As a side effect, writes
#'   a PNG to `output_dir` unless `output_dir` is `NA`.
#'
#' @importFrom ggplot2 ggplot aes geom_histogram facet_wrap ggtitle labs
#'   theme_light scale_x_log10 scale_x_continuous ggsave
#' @importFrom stats as.formula
#' @family descriptive helpers
#' @export
#'
#' @examples
#' set.seed(2)
#' df <- data.frame(
#'   days      = c(rpois(60, 5) + 1L, rpois(60, 10) + 1L),
#'   insurance = rep(c("Medicaid", "BCBS"), each = 60)
#' )
#' mysterycall_log_histogram(df, x_col = "days", facet_col = "insurance",
#'                            output_dir = NA)
mysterycall_log_histogram <- function(
    data,
    x_col,
    facet_col,
    binwidth   = NULL,
    fill       = "skyblue",
    color      = "black",
    alpha      = 0.7,
    x_label    = NULL,
    y_label    = "Count",
    title      = NULL,
    base       = 10,
    dpi        = 150,
    output_dir = NULL,
    filename   = "log_histogram.png"
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop(
      "Package 'ggplot2' is required. Install with: install.packages('ggplot2')",
      call. = FALSE
    )
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!is.character(x_col) || length(x_col) != 1L || !nzchar(x_col)) {
    stop("`x_col` must be a single non-empty character string.", call. = FALSE)
  }
  if (!is.character(facet_col) || length(facet_col) != 1L || !nzchar(facet_col)) {
    stop("`facet_col` must be a single non-empty character string.", call. = FALSE)
  }
  if (!x_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", x_col), call. = FALSE)
  }
  if (!facet_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", facet_col), call. = FALSE)
  }
  if (!base %in% c(2, 10)) {
    stop("`base` must be 2 or 10; got ", base, ".", call. = FALSE)
  }

  # Remove non-positive values (log of 0 or negatives is undefined)
  n_nonpos <- sum(!is.na(data[[x_col]]) & data[[x_col]] <= 0)
  if (n_nonpos > 0) {
    message(
      sprintf(
        "%d row(s) with %s <= 0 removed before log transformation.",
        n_nonpos, x_col
      )
    )
    data <- data[is.na(data[[x_col]]) | data[[x_col]] > 0, , drop = FALSE]
  }

  # After filtering, require at least one positive finite value
  remaining <- sum(!is.na(data[[x_col]]) & is.finite(data[[x_col]]) & data[[x_col]] > 0)
  if (remaining == 0L) {
    stop(
      sprintf(
        "No positive values remain in '%s' after removing zeros and NAs. Cannot create log histogram.",
        x_col
      ),
      call. = FALSE
    )
  }

  # Resolve defaults
  x_label <- x_label %||% paste0("log", base, "(", x_col, ")")
  title   <- title %||% paste0(
    "Distribution of log(", x_col, ") by ", facet_col
  )

  # Build histogram (with or without fixed binwidth)
  hist_args <- list(
    fill  = fill,
    color = color,
    alpha = alpha
  )
  if (!is.null(binwidth)) {
    hist_args$binwidth <- binwidth
  }

  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[x_col]])) +
    do.call(ggplot2::geom_histogram, hist_args) +
    ggplot2::facet_wrap(stats::as.formula(paste("~", facet_col))) +
    ggplot2::ggtitle(title) +
    ggplot2::labs(x = x_label, y = y_label) +
    ggplot2::theme_light()

  # Apply log scale
  if (base == 10) {
    p <- p + ggplot2::scale_x_log10()
  } else {
    p <- p + ggplot2::scale_x_continuous(trans = "log2")
  }

  # Save PNG
  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("log_histograms", create = TRUE)
  }
  if (!isTRUE(is.na(output_dir))) {
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    }
    out_path <- file.path(output_dir, filename)
    ggplot2::ggsave(out_path, plot = p, dpi = dpi, width = 8, height = 5,
                    units = "in")
    message("Log histogram saved to: ", out_path)
  }

  invisible(p)
}
