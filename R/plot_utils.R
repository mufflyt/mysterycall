#' Save a ggplot2 figure with publication-quality defaults
#'
#' @name mysterycall_save_plot
NULL

#' Save a ggplot to disk with publication defaults
#'
#' A thin wrapper around [ggplot2::ggsave()] that:
#' \itemize{
#'   \item Defaults to 300 dpi, 8 x 6 inches, white background.
#'   \item Creates the output directory automatically if it does not exist.
#'   \item Returns the output path invisibly so calls can be piped.
#' }
#'
#' @param plot A `ggplot` object.
#' @param path Character scalar. Full path (including filename and extension)
#'   where the plot should be saved. Common extensions: `.png`, `.pdf`,
#'   `.svg`, `.tiff`.
#' @param width Numeric. Width in inches. Default `8`.
#' @param height Numeric. Height in inches. Default `6`.
#' @param dpi Integer. Dots per inch. Default `300` (publication quality).
#' @param bg Character scalar. Background color. Default `"white"`.
#' @param ... Additional arguments forwarded to [ggplot2::ggsave()].
#'
#' @return The output `path` (character scalar), invisibly. Assign the return
#'   value to capture the path for downstream use; printing is suppressed.
#'
#' @seealso [mysterycall_plot_stacked_bar()], [mysterycall_plot_scatter()],
#'   [mysterycall_plot_density()] for functions that produce plots to pass here.
#' @family manuscript
#' @export
#'
#' @examplesIf interactive()
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
#' mysterycall_save_plot(p, "figures/mpg_vs_weight.png")
mysterycall_save_plot <- function(plot,
                                   path,
                                   width  = 8,
                                   height = 6,
                                   dpi    = 300L,
                                   bg     = "white",
                                   ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required.", call. = FALSE)
  }
  if (!inherits(plot, "ggplot")) {
    stop("`plot` must be a ggplot object.", call. = FALSE)
  }
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    stop("`path` must be a non-empty character scalar.", call. = FALSE)
  }

  out_dir <- dirname(path)
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  }

  ggplot2::ggsave(
    filename = path,
    plot     = plot,
    width    = width,
    height   = height,
    dpi      = as.integer(dpi),
    bg       = bg,
    ...
  )

  invisible(path)
}
