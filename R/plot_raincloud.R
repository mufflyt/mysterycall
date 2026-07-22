#' Raincloud plot of a numeric outcome by group
#'
#' A raincloud layers a violin (the distribution), a boxplot (IQR and median),
#' and the jittered raw points (every observation) in one figure -- the
#' canonical way to show a right-skewed audit outcome such as wait time across
#' caller scenarios without hiding the sample size or the spread. Returns a
#' [ggplot2::ggplot()] you can theme, facet, or save.
#'
#' @param data A data frame.
#' @param value Character scalar naming the numeric outcome column (e.g. wait
#'   days).
#' @param group Character scalar naming the grouping / scenario column.
#' @param add_median_labels Logical; annotate each group with its median. Default
#'   `TRUE`.
#' @param title,x_lab,y_lab Character scalars for the plot title and axis labels.
#'   `title` defaults to `NULL` (none); `x_lab` defaults to `NULL`; `y_lab`
#'   defaults to `value`.
#' @param point_alpha Numeric opacity for the jittered points. Default `0.6`.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @family visualization
#' @seealso [mysterycall_plot_paired_slope()], [mysterycall_plot_distribution()]
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   d <- data.frame(
#'     wait     = c(rpois(40, 10), rpois(40, 25)),
#'     scenario = rep(c("Commercial", "Medicaid"), each = 40)
#'   )
#'   mysterycall_plot_raincloud(d, "wait", "scenario")
#' }
#' @export
mysterycall_plot_raincloud <- function(data, value, group,
                                      add_median_labels = TRUE,
                                      title = NULL, x_lab = NULL,
                                      y_lab = value, point_alpha = 0.6) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_choice(value, names(data))
  checkmate::assert_choice(group, names(data))
  checkmate::assert_flag(add_median_labels)
  checkmate::assert_number(point_alpha, lower = 0, upper = 1)
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("mysterycall_plot_raincloud() requires the ggplot2 package.\n",
         "Install it with: install.packages(\"ggplot2\")", call. = FALSE)
  }
  if (!is.numeric(data[[value]])) {
    stop(sprintf("`value` column '%s' must be numeric.", value), call. = FALSE)
  }

  df <- data[!is.na(data[[value]]) & !is.na(data[[group]]), , drop = FALSE]
  if (nrow(df) < 1L) stop("No non-missing rows to plot.", call. = FALSE)

  p <- ggplot2::ggplot(
    df, ggplot2::aes(x = .data[[group]], y = .data[[value]],
                     fill = .data[[group]], colour = .data[[group]])
  ) +
    ggplot2::geom_violin(alpha = 0.25, linewidth = 0.4, width = 0.9,
                         trim = FALSE) +
    ggplot2::geom_boxplot(width = 0.18, alpha = 0.6, outlier.shape = NA,
                          linewidth = 0.5, colour = "grey30", fill = "white") +
    ggplot2::geom_jitter(width = 0.08, height = 0, size = 1.8,
                         alpha = point_alpha, shape = 21, stroke = 0.3,
                         colour = "white") +
    ggplot2::labs(title = title, x = x_lab, y = y_lab) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      legend.position    = "none",
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank()
    )

  if (add_median_labels) {
    meds <- stats::aggregate(df[[value]], list(grp = df[[group]]), stats::median,
                             na.rm = TRUE)
    names(meds) <- c(group, value)
    p <- p + ggplot2::geom_text(
      data = meds,
      ggplot2::aes(x = .data[[group]], y = .data[[value]],
                   label = paste0("Mdn=", round(.data[[value]], 0))),
      vjust = -0.7, hjust = -0.05, size = 3, colour = "grey30",
      inherit.aes = FALSE
    )
  }

  p
}
