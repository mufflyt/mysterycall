#' Create a Line Plot with Optional Transformations and Grouping
#'
#' This function creates a line plot using ggplot2 with options for transforming the y-axis, grouping lines, and saving the plot with a specified resolution. The plot can be saved in both TIFF and PNG formats with automatic filename generation.
#'
#' @param plot_data A dataframe containing the data to be plotted. Must contain the variables specified in `x_var` and `y_var`.
#' @param x_var A string representing the column name for the x-axis variable. This should be a categorical or factor variable.
#' @param y_var A string representing the column name for the y-axis variable. This should be a numeric variable.
#' @param y_transform A string specifying the transformation for the y-axis: "log" for log transformation (log1p), "sqrt" for square root transformation, or "none" for no transformation. Default is "none".
#' @param dpi An integer specifying the resolution of the saved plot in dots per inch (DPI). Default is 600 for print-ready outputs.
#' @param output_dir A string representing the directory where the plot files will be
#'   saved. Defaults to a session-specific folder inside [tempdir()].
#' @param file_prefix A string used as the prefix for the generated plot filenames. The filenames will have a timestamp appended to ensure uniqueness. Default is "line_plot".
#' @param use_geom_line A boolean indicating whether to include lines connecting points for grouped data. Default is FALSE.
#' @param geom_line_group A string representing the column name to group the lines by when `use_geom_line` is TRUE. This should be a categorical or factor variable.
#' @param point_color A string specifying the color of the points. Default is "viridis", which uses the viridis color palette.
#' @param line_color A string specifying the color of the summary line (median). Default is "viridis" to match the accessible palette.
#' @param verbose A boolean indicating whether to print messages about the saved plot locations. Default is TRUE.
#'
#' @return A ggplot2 object (`c("gg", "ggplot")`), returned invisibly. As a
#'   side effect, writes a `.tiff` and a `.png` file to `output_dir` with
#'   filenames of the form `<file_prefix>_<timestamp>.tiff/.png`. A
#'   `stat_summary` median line is always overlaid; individual points are
#'   shown via `geom_point`.
#'
#' @seealso [mysterycall_plot_scatter()] for jittered point plots;
#'   [mysterycall_plot_density()] for density distribution plots.
#' @importFrom dplyr filter mutate %>%
#' @importFrom rlang sym .data
#' @family mapping
#' @export
#' @examplesIf interactive()
#' example_data <- data.frame(
#'   insurance = rep(c("Medicaid", "Commercial", "Medicare"), each = 3),
#'   business_days_until_appointment = c(1.5, 2.1, 2.8, 1.7, 2.3, 2.5, 1.9, 2.6, 3.1)
#' )
#' mysterycall_plot_line(
#'   plot_data = example_data,
#'   x_var = "insurance",
#'   y_var = "business_days_until_appointment",
#'   y_transform = "none",
#'   dpi = 50,
#'   output_dir = tempdir(),
#'   file_prefix = "demo_line",
#'   verbose = FALSE
#' )
mysterycall_plot_line <- function(plot_data,
                             x_var,
                             y_var,
                             y_transform = "none",
                             dpi = 600,
                             output_dir = NULL,
                             file_prefix = "line_plot",
                             use_geom_line = FALSE,
                             geom_line_group = NULL,
                             point_color = "viridis",
                             line_color = "viridis",
                             verbose = TRUE) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for mysterycall_plot_line(). Install with: install.packages('ggplot2')", call. = FALSE)
  }
  y_transform <- match.arg(y_transform, c("none", "log", "sqrt"))

  # Remove NA values from the y_var column
  plot_data <- dplyr::filter(plot_data, !is.na(.data[[y_var]]))

  # Handle transformations
  if (y_transform == "log") {
    plot_data <- dplyr::mutate(plot_data, !!y_var := log1p(.data[[y_var]]))
    y_label <- paste("Log (", y_var, ")", sep = "")
  } else if (y_transform == "sqrt") {
    plot_data <- dplyr::mutate(plot_data, !!y_var := sqrt(.data[[y_var]]))
    y_label <- paste("Sqrt (", y_var, ")", sep = "")
  } else {
    y_label <- y_var
  }

  # Create the plot
  resolved_point_color <- if (point_color == "viridis") {
    if (requireNamespace("viridis", quietly = TRUE)) {
      viridis::viridis_pal(option = "viridis")(1)
    } else {
      "#440154"
    }
  } else {
    point_color
  }
  resolved_line_color <- if (line_color == "viridis") {
    if (requireNamespace("viridis", quietly = TRUE)) {
      viridis::viridis(1, option = "viridis")
    } else {
      "#440154"
    }
  } else {
    line_color
  }

  line_plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = !!rlang::sym(x_var), y = !!rlang::sym(y_var))) +
    ggplot2::geom_point(color = resolved_point_color, size = 2.5, alpha = 0.9)

  if (use_geom_line && !is.null(geom_line_group)) {
    line_plot <- line_plot +
      ggplot2::geom_line(ggplot2::aes(group = !!rlang::sym(geom_line_group)), color = "#9AA0A6", linewidth = 0.6)
  }

  line_plot <- line_plot +
    ggplot2::stat_summary(fun = median, geom = "line", color = resolved_line_color, alpha = 0.9, linewidth = 1, ggplot2::aes(group = 1)) +
    ggplot2::ylab(y_label) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = "white"),
      plot.background = ggplot2::element_rect(fill = "white"),
      axis.title.x = ggplot2::element_blank(),
      axis.title = ggplot2::element_text(face = "bold"),
      plot.title = ggplot2::element_text(face = "bold", hjust = 0.5)
    )

  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("line_plots", create = TRUE)
  } else if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Automatic Filename Generation
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  tiff_filename <- file.path(output_dir, paste0(file_prefix, "_", timestamp, ".tiff"))
  png_filename <- file.path(output_dir, paste0(file_prefix, "_", timestamp, ".png"))

  ggplot2::ggsave(filename = tiff_filename, plot = line_plot, dpi = dpi, height = 5, width = 7, units = "in", compression = "lzw")
  ggplot2::ggsave(filename = png_filename, plot = line_plot, dpi = dpi, height = 5, width = 7, units = "in")

  if (verbose) {
    message("Plots saved to: ", tiff_filename, " and ", png_filename)
  }

  invisible(line_plot)
}
