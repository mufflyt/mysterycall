#' Greene-journal-ready monochrome ggplot2 theme
#'
#' Returns a list of ggplot2 theme and scale calls suitable for adding to any
#' ggplot2 object with \code{+}. Produces a black-and-white figure compatible
#' with journals (e.g. Greene) that require greyscale submissions.
#'
#' @param base_size Numeric. Base font size in points. Default \code{12}.
#' @param title_rel Numeric. Title size as a multiple of \code{base_size}
#'   via \code{ggplot2::rel()}. Default \code{1.1}.
#'   (Tip from Rennie 2026 -- use \code{rel()} so resizing the chart only
#'   requires changing \code{base_size}.)
#'
#' @return A list of ggplot2 objects that can be added to a ggplot with \code{+}.
#'
#' @note Inspired by Nicola Rennie's blog posts on monochrome data
#'   visualisations (\url{https://nrennie.rbind.io/blog/monochrome-data-visualisations/})
#'   and five ggplot2 functions
#'   (\url{https://nrennie.rbind.io/blog/five-ggplot2-functions/}).
#'
#' @importFrom ggplot2 theme_bw theme element_text scale_fill_grey
#'   scale_colour_grey rel
#' @family visualization
#' @export
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   library(ggplot2)
#'   ggplot(mtcars, aes(x = mpg)) +
#'     geom_histogram(bins = 10) +
#'     mysterycall_bw_theme()
#' }
mysterycall_bw_theme <- function(base_size = 12, title_rel = 1.1) {
  list(
    ggplot2::theme_bw(base_size = base_size),
    ggplot2::theme(
      plot.title            = ggplot2::element_text(size = ggplot2::rel(title_rel),
                                                    face = "bold"),
      plot.title.position   = "plot",   # Rennie 2026: align title to full plot width
      plot.caption.position = "plot"
    ),
    ggplot2::scale_fill_grey(start = 0.2, end = 0.85),
    ggplot2::scale_colour_grey(start = 0.2, end = 0.85)
  )
}
