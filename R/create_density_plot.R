#' Create a Density Plot for Mystery Caller Studies with Optional Transformations
#'
#' This function generates a density plot designed for mystery caller studies, allowing for the visualization of waiting times or similar outcomes across different categories, such as insurance types. The function supports transformations on the x-axis and custom labels.
#'
#' @param data A dataframe containing the data to be plotted. Must contain the variables specified in `x_var` and `fill_var`.
#' @param x_var A string representing the column name for the x-axis variable. This should be a numeric variable (e.g., waiting time in days).
#' @param fill_var A string representing the column name for the fill variable. This should be a categorical or factor variable (e.g., insurance type).
#' @param x_transform A string specifying the transformation for the x-axis: "log" for log transformation (log1p), "sqrt" for square root transformation, or "none" for no transformation. Default is "none".
#' @param dpi An integer specifying the resolution of the saved plot in dots per inch (DPI). Default is 600 for print-ready outputs.
#' @param output_dir A string representing the directory where the plot files will be
#'   saved. Defaults to a session-specific folder inside [tempdir()].
#' @param file_prefix A string used as the prefix for the generated plot filenames. The filenames will have a timestamp appended to ensure uniqueness. Default is "density_plot".
#' @param x_label A string specifying the label for the x-axis. Default is `NULL` (uses x_var).
#' @param y_label A string specifying the label for the y-axis. Default is "Density".
#' @param plot_title A string specifying the title of the plot. Default is `NULL` (no title).
#' @param verbose A boolean indicating whether to print messages about the saved plot locations. Default is TRUE.
#'
#' @return A ggplot2 object (`c("gg", "ggplot")`), returned invisibly. As a
#'   side effect, writes a `.tiff` and a `.png` file to `output_dir` with
#'   filenames of the form `<file_prefix>_<timestamp>.tiff/.png`.
#'
#' @seealso [mysterycall_plot_scatter()] for jittered point plots;
#'   [mysterycall_plot_line()] for median-trend line plots;
#'   [mysterycall_save_green_journal_figure()] to export at journal resolution.
#' @importFrom dplyr filter mutate %>%
#' @importFrom ggplot2 ggplot geom_density scale_x_log10 scale_x_sqrt labs theme_light theme ggsave
#' @importFrom rlang sym .data
#' @family mapping
#' @export
#' @examplesIf interactive()
#' example_data <- data.frame(
#'   insurance = rep(c("Medicaid", "Commercial"), each = 3),
#'   business_days_until_appointment = c(1.5, 2.2, 3.1, 1.8, 2.5, 2.9)
#' )
#' mysterycall_plot_density(
#'   data = example_data,
#'   x_var = "business_days_until_appointment",
#'   fill_var = "insurance",
#'   x_transform = "none",
#'   dpi = 50,
#'   output_dir = tempdir(),
#'   file_prefix = "demo_density",
#'   x_label = "Waiting Times in Days",
#'   y_label = "Density",
#'   plot_title = "Example Density Plot",
#'   verbose = FALSE
#' )

mysterycall_plot_density <- function(data,
                                x_var,
                                fill_var,
                                x_transform = "none",
                                dpi = 600,
                                output_dir = NULL,
                                file_prefix = "density_plot",
                                x_label = NULL,
                                y_label = "Density",
                                plot_title = NULL,
                                verbose = TRUE) {

  x_transform <- match.arg(x_transform, c("none", "log", "sqrt"))

  # Filter out zero or negative values and NAs from the x_var column
  data <- dplyr::filter(data, .data[[x_var]] > 0, !is.na(.data[[x_var]]))

  # Handle transformations
  if (x_transform == "log") {
    data <- dplyr::mutate(data, !!x_var := log1p(.data[[x_var]]))
    x_label <- if (is.null(x_label)) paste("Log (", x_var, ")", sep = "") else x_label
  } else if (x_transform == "sqrt") {
    data <- dplyr::mutate(data, !!x_var := sqrt(.data[[x_var]]))
    x_label <- if (is.null(x_label)) paste("Sqrt (", x_var, ")", sep = "") else x_label
  } else {
    x_label <- if (is.null(x_label)) x_var else x_label
  }

  # Create the density plot
  density_plot <- ggplot2::ggplot(data, ggplot2::aes(x = !!rlang::sym(x_var), fill = !!rlang::sym(fill_var))) +
    ggplot2::geom_density(alpha = 0.7, linewidth = 0.3, color = NA) +
    ggplot2::labs(
      x = x_label,
      y = y_label,
      title = plot_title
    ) +
    ggplot2::scale_fill_viridis_d(option = "viridis") +  # Use viridis color palette
    ggplot2::theme_light(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      legend.title = ggplot2::element_text(face = "bold"),
      axis.title = ggplot2::element_text(face = "bold"),
      plot.title = ggplot2::element_text(face = "bold", hjust = 0.5)
    )

  # Display the plot
  invisible(density_plot)

  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("density_plots", create = TRUE)
  } else if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Automatic Filename Generation
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  tiff_filename <- file.path(output_dir, paste0(file_prefix, "_", timestamp, ".tiff"))
  png_filename <- file.path(output_dir, paste0(file_prefix, "_", timestamp, ".png"))

  ggplot2::ggsave(filename = tiff_filename, plot = density_plot, dpi = dpi, height = 5, width = 7, units = "in", compression = "lzw")
  ggplot2::ggsave(filename = png_filename, plot = density_plot, dpi = dpi, height = 5, width = 7, units = "in")

  if (verbose) {
    message("Plots saved to: ", tiff_filename, " and ", png_filename)
  }

  invisible(density_plot)
}
