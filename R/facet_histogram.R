#' Faceted histogram of a numeric variable by group
#'
#' Produces a faceted histogram (one panel per level of `facet_col`) with an
#' optional density-curve overlay, per-group mean line, and per-facet
#' annotation of descriptive statistics.  Mirrors the source pattern from the
#' analysis Rmd (lines 1094-1150).
#'
#' @param data A data frame.
#' @param x_col Character scalar.  Name of the numeric column to plot on the
#'   x-axis.
#' @param facet_col Character scalar.  Name of the grouping column used for
#'   the facet panels.
#' @param binwidth Numeric.  Histogram bin width.  Default `1`.
#' @param fill Character.  Bar fill colour.  Default `"skyblue"`.
#' @param color Character.  Bar border colour.  Default `"black"`.
#' @param alpha Numeric.  Bar transparency \[0, 1\].  Default `0.7`.
#' @param show_mean_line Logical.  Add a vertical dashed red line at the
#'   group mean?  Default `TRUE`.
#' @param show_stats_text Logical.  Annotate each facet with Mean, SD,
#'   Median, 25th percentile, and 75th percentile?  Default `TRUE`.
#' @param x_label Character or `NULL`.  X-axis label.  Defaults to `x_col`.
#' @param y_label Character.  Y-axis label.  Default `"Count"`.
#' @param title Character or `NULL`.  Plot title.  Defaults to
#'   `"Distribution of [x_col] by [facet_col] (N = [n])"`.
#' @param dpi Integer.  Resolution for the saved PNG.  Default `150`.
#' @param output_dir Character, `NULL`, or `NA`.  Directory for PNG output.
#'   `NULL` (default) writes to a session temp directory via
#'   [mysterycall_tempdir()].  `NA` skips writing entirely.
#' @param filename Character.  Output file name.  Default
#'   `"facet_histogram.png"`.
#'
#' @return A `ggplot` object, returned invisibly.  As a side effect, writes
#'   a PNG to `output_dir` unless `output_dir` is `NA`.
#'
#' @importFrom ggplot2 ggplot aes geom_histogram geom_density facet_wrap
#'   ggtitle labs theme_light geom_vline geom_text after_stat ggsave
#' @importFrom dplyr group_by summarise
#' @importFrom rlang .data
#' @importFrom stats as.formula median sd quantile na.omit
#' @family descriptive helpers
#' @export
#'
#' @examples
#' set.seed(1)
#' df <- data.frame(
#'   days      = c(rpois(60, 5), rpois(60, 10)),
#'   insurance = rep(c("Medicaid", "BCBS"), each = 60)
#' )
#' mysterycall_facet_histogram(df, x_col = "days", facet_col = "insurance",
#'                              output_dir = NA)
mysterycall_facet_histogram <- function(
    data,
    x_col,
    facet_col,
    binwidth        = 1,
    fill            = "skyblue",
    color           = "black",
    alpha           = 0.7,
    show_mean_line  = TRUE,
    show_stats_text = TRUE,
    x_label         = NULL,
    y_label         = "Count",
    title           = NULL,
    dpi             = 150,
    output_dir      = NULL,
    filename        = "facet_histogram.png"
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

  # Resolve defaults
  x_label <- x_label %||% x_col
  total_n <- length(stats::na.omit(data[[x_col]]))
  title   <- title %||% paste0(
    "Distribution of ", x_col, " by ", facet_col,
    " (N = ", format(total_n, big.mark = ","), ")"
  )

  # Drop NA rows from x_col so ggplot2 never sees them and never warns
  n_na_x <- sum(is.na(data[[x_col]]))
  if (n_na_x > 0L) {
    message(sprintf("Removing %d NA row(s) from '%s' before plotting.", n_na_x, x_col))
    data <- data[!is.na(data[[x_col]]), , drop = FALSE]
  }

  # Base plot
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[x_col]])) +
    ggplot2::geom_histogram(
      binwidth = binwidth,
      fill     = fill,
      color    = color,
      alpha    = alpha
    ) +
    ggplot2::geom_density(
      ggplot2::aes(y = ggplot2::after_stat(count)),
      color     = "darkblue",
      linewidth = 0.6
    ) +
    ggplot2::facet_wrap(stats::as.formula(paste("~", facet_col))) +
    ggplot2::ggtitle(title) +
    ggplot2::labs(x = x_label, y = y_label) +
    ggplot2::theme_light()

  # Per-group stats (needed for mean line and/or text annotation)
  if (show_mean_line || show_stats_text) {
    clean <- data[!is.na(data[[x_col]]), , drop = FALSE]
    stats_df <- dplyr::summarise(
      dplyr::group_by(clean, .data[[facet_col]]),
      mean_val = mean(.data[[x_col]], na.rm = TRUE),
      sd_val   = stats::sd(.data[[x_col]], na.rm = TRUE),
      med_val  = stats::median(.data[[x_col]], na.rm = TRUE),
      q1_val   = stats::quantile(.data[[x_col]], 0.25, na.rm = TRUE),
      q3_val   = stats::quantile(.data[[x_col]], 0.75, na.rm = TRUE),
      .groups  = "drop"
    )
    # Ensure the grouping column keeps its original name (it should via .data)
    stats_df <- as.data.frame(stats_df)

    if (show_mean_line && nrow(stats_df) > 0) {
      p <- p + ggplot2::geom_vline(
        data      = stats_df,
        ggplot2::aes(xintercept = mean_val),
        linetype  = "dashed",
        color     = "red",
        linewidth = 0.8
      )
    }

    if (show_stats_text && nrow(stats_df) > 0) {
      stats_df$label <- sprintf(
        "Mean=%.1f\nSD=%.1f\nMedian=%.1f\n25%%=%.1f\n75%%=%.1f",
        stats_df$mean_val, stats_df$sd_val, stats_df$med_val,
        stats_df$q1_val, stats_df$q3_val
      )
      p <- p + ggplot2::geom_text(
        data        = stats_df,
        ggplot2::aes(x = Inf, y = Inf, label = label),
        hjust       = 1.05,
        vjust       = 1.05,
        size        = 3,
        inherit.aes = FALSE
      )
    }
  }

  # Save PNG
  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("facet_histograms", create = TRUE)
  }
  if (!isTRUE(is.na(output_dir))) {
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    }
    out_path <- file.path(output_dir, filename)
    ggplot2::ggsave(out_path, plot = p, dpi = dpi, width = 8, height = 5,
                    units = "in")
    message("Facet histogram saved to: ", out_path)
  }

  invisible(p)
}
