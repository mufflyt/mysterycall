#' Visualize estimated marginal means for an interaction
#'
#' @name mysterycall_plot_emmeans_interaction
NULL

#' Dodge plot of estimated marginal means with 95% CI error bars
#'
#' Calls [emmeans::emmeans()] on a fitted model, then builds a dodged
#' point-and-error-bar ggplot2 figure. Suitable for displaying interactions
#' from Poisson or linear mixed models.
#'
#' @param model A fitted model accepted by [emmeans::emmeans()].
#' @param specs Character vector of marginal mean specifications passed to
#'   `emmeans`. Typically `c("exposure", "moderator")`. The first element
#'   maps to the x-axis; the second (if present) maps to the grouping/color
#'   aesthetic.
#' @param variable Character scalar. Y-axis label (typically the outcome
#'   variable name).
#' @param use_color Logical. If `TRUE` (default), groups are distinguished by
#'   color. If `FALSE`, a greyscale bar chart is drawn instead.
#'
#' @return A `ggplot` object.
#'
#' @family outcomes
#' @export
#'
#' @examplesIf interactive()
#' mysterycall_plot_emmeans_interaction(
#'   model    = fit,
#'   specs    = c("insurance", "gender"),
#'   variable = "Wait days"
#' )
mysterycall_plot_emmeans_interaction <- function(model,
                                                  specs,
                                                  variable,
                                                  use_color = TRUE) {
  if (!requireNamespace("emmeans", quietly = TRUE)) {
    stop(
      "This function requires the emmeans package.\n",
      "Install it with: install.packages(\"emmeans\")",
      call. = FALSE
    )
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop(
      "This function requires the ggplot2 package.\n",
      "Install it with: install.packages(\"ggplot2\")",
      call. = FALSE
    )
  }
  if (!is.character(specs) || length(specs) < 1L) {
    stop("`specs` must be a character vector with at least one element.", call. = FALSE)
  }

  em  <- emmeans::emmeans(model, specs = specs)
  df  <- as.data.frame(em)

  x_col   <- specs[[1L]]
  grp_col <- if (length(specs) >= 2L) specs[[2L]] else NULL

  if (!x_col %in% names(df)) {
    stop("First spec '", x_col, "' not found in emmeans output.", call. = FALSE)
  }
  if (!is.null(grp_col) && !grp_col %in% names(df)) {
    stop("Second spec '", grp_col, "' not found in emmeans output.", call. = FALSE)
  }

  dodge <- ggplot2::position_dodge(width = 0.4)

  if (use_color && !is.null(grp_col)) {
    p <- ggplot2::ggplot(
      df,
      ggplot2::aes(
        x     = .data[[x_col]],
        y     = .data[["emmean"]],
        ymin  = .data[["lower.CL"]],
        ymax  = .data[["upper.CL"]],
        color = .data[[grp_col]],
        group = .data[[grp_col]]
      )
    ) +
      ggplot2::geom_point(position = dodge, size = 3) +
      ggplot2::geom_errorbar(position = dodge, width = 0.2)
  } else if (!is.null(grp_col)) {
    p <- ggplot2::ggplot(
      df,
      ggplot2::aes(
        x    = .data[[x_col]],
        y    = .data[["emmean"]],
        ymin = .data[["lower.CL"]],
        ymax = .data[["upper.CL"]],
        fill = .data[[grp_col]],
        group = .data[[grp_col]]
      )
    ) +
      ggplot2::geom_col(position = dodge) +
      ggplot2::geom_errorbar(position = dodge, width = 0.2)
  } else {
    p <- ggplot2::ggplot(
      df,
      ggplot2::aes(
        x    = .data[[x_col]],
        y    = .data[["emmean"]],
        ymin = .data[["lower.CL"]],
        ymax = .data[["upper.CL"]]
      )
    ) +
      ggplot2::geom_point(size = 3) +
      ggplot2::geom_errorbar(width = 0.2)
  }

  p +
    ggplot2::labs(
      x     = x_col,
      y     = variable,
      color = grp_col,
      fill  = grp_col
    ) +
    ggplot2::theme_minimal()
}
