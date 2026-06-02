#' Create a Scatter Plot for Mystery Caller Studies with Optional Transformations, Jitter, and Custom Labels
#'
#' This function generates a scatter plot designed for mystery caller studies, allowing for the visualization of waiting times or similar outcomes across different categories, such as insurance types. The function supports transformations on the y-axis, custom jitter, and colors each category in the x-axis using the `viridis` color palette. The plot is automatically displayed and saved with a specified resolution.
#'
#' @param plot_data A dataframe containing the data to be plotted. Must contain the variables specified in `x_var` and `y_var`.
#' @param x_var A string representing the column name for the x-axis variable. This should be a categorical or factor variable (e.g., insurance type).
#' @param y_var A string representing the column name for the y-axis variable. This should be a numeric variable (e.g., waiting time in days).
#' @param y_transform A string specifying the transformation for the y-axis: "log" for log transformation (log1p), "sqrt" for square root transformation, or "none" for no transformation. Default is "none".
#' @param dpi An integer specifying the resolution of the saved plot in dots per inch (DPI). Default is 600 for print-ready outputs.
#' @param output_dir A string representing the directory where the plot files will be
#'   saved. Defaults to a session-specific folder inside [tempdir()].
#' @param file_prefix A string used as the prefix for the generated plot filenames. The filenames will have a timestamp appended to ensure uniqueness. Default is "scatter_plot".
#' @param jitter_width A numeric value specifying the width of the jitter along the x-axis. Default is 0.2.
#' @param jitter_height A numeric value specifying the height of the jitter along the y-axis. Default is 0.
#' @param point_alpha A numeric value specifying the transparency level of the points. Default is 0.6.
#' @param x_label A string specifying the label for the x-axis. Default is `NULL` (uses x_var).
#' @param y_label A string specifying the label for the y-axis. Default is `NULL` (uses y_var or transformed version).
#' @param plot_title A string specifying the title of the plot. Default is `NULL` (no title).
#' @param verbose A boolean indicating whether to print messages about the saved plot locations. Default is TRUE.
#'
#' @return A ggplot2 object (`c("gg", "ggplot")`), returned invisibly. As a
#'   side effect, writes a `.tiff` and a `.png` file to `output_dir` with
#'   filenames of the form `<file_prefix>_<timestamp>.tiff/.png`. Rows
#'   with zero, negative, or `NA` values in `y_var` are silently removed
#'   before plotting.
#'
#' @seealso [mysterycall_plot_density()] for distribution density plots;
#'   [mysterycall_plot_line()] for median-trend line plots.
#' @importFrom dplyr filter mutate %>%
#' @importFrom ggplot2 ggplot geom_jitter scale_y_log10 scale_y_sqrt labs theme_minimal element_rect element_blank ggsave
#' @importFrom rlang sym .data
#' @family mapping
#' @export
#' @examplesIf interactive()
#' example_data <- data.frame(
#'   insurance = rep(c("Medicaid", "Commercial", "Medicare"), each = 3),
#'   business_days_until_appointment = c(1.5, 2.0, 2.8, 1.9, 2.4, 2.6, 2.1, 2.7, 3.0)
#' )
#' mysterycall_plot_scatter(
#'   plot_data = example_data,
#'   x_var = "insurance",
#'   y_var = "business_days_until_appointment",
#'   y_transform = "none",
#'   dpi = 50,
#'   output_dir = tempdir(),
#'   file_prefix = "demo_scatter",
#'   x_label = "Insurance",
#'   y_label = "Waiting Times in Days",
#'   plot_title = "Example Scatter Plot",
#'   verbose = FALSE
#' )
mysterycall_plot_scatter <- function(plot_data,
                                x_var,
                                y_var,
                                y_transform = "none",
                                dpi = 600,
                                output_dir = NULL,
                                file_prefix = "scatter_plot",
                                jitter_width = 0.2,
                                jitter_height = 0,
                                point_alpha = 0.6,
                                x_label = NULL,
                                y_label = NULL,
                                plot_title = NULL,
                                verbose = TRUE) {

  y_transform <- match.arg(y_transform, c("none", "log", "sqrt"))

  # Filter out zero or negative values and NAs from the y_var column
  plot_data <- dplyr::filter(plot_data, .data[[y_var]] > 0, !is.na(.data[[y_var]]))

  # Handle transformations
  if (y_transform == "log") {
    plot_data <- dplyr::mutate(plot_data, !!y_var := log1p(.data[[y_var]]))
    y_label <- if (is.null(y_label)) paste("Log (", y_var, ")", sep = "") else y_label
  } else if (y_transform == "sqrt") {
    plot_data <- dplyr::mutate(plot_data, !!y_var := sqrt(.data[[y_var]]))
    y_label <- if (is.null(y_label)) paste("Sqrt (", y_var, ")", sep = "") else y_label
  } else {
    y_label <- if (is.null(y_label)) y_var else y_label
  }

  # Create the scatter plot with colored points by x_var
  scatter_plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = !!rlang::sym(x_var), y = !!rlang::sym(y_var), color = !!rlang::sym(x_var))) +
    ggplot2::geom_jitter(width = jitter_width, height = jitter_height, alpha = point_alpha, size = 2.5) +
    ggplot2::labs(
      x = if (is.null(x_label)) x_var else x_label,
      y = y_label,
      title = plot_title
    ) +
    ggplot2::scale_color_viridis_d(option = "viridis") +  # Use viridis color palette
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = "white"),
      plot.background = ggplot2::element_rect(fill = "white"),
      axis.title.x = ggplot2::element_blank(),
      legend.position = "bottom",
      legend.title = ggplot2::element_text(face = "bold"),
      axis.title = ggplot2::element_text(face = "bold"),
      plot.title = ggplot2::element_text(face = "bold", hjust = 0.5)
    )

  # Display the plot
  invisible(scatter_plot)

  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("scatter_plots", create = TRUE)
  } else if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Automatic Filename Generation
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  tiff_filename <- file.path(output_dir, paste0(file_prefix, "_", timestamp, ".tiff"))
  png_filename <- file.path(output_dir, paste0(file_prefix, "_", timestamp, ".png"))

  ggplot2::ggsave(filename = tiff_filename, plot = scatter_plot, dpi = dpi, height = 5, width = 7, units = "in", compression = "lzw")
  ggplot2::ggsave(filename = png_filename, plot = scatter_plot, dpi = dpi, height = 5, width = 7, units = "in")

  if (verbose) {
    cat("Plots saved to:", tiff_filename, "and", png_filename, "\n")
  }

  invisible(scatter_plot)
}
