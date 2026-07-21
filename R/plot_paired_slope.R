#' Within-cluster paired slope plot across scenarios
#'
#' The visual companion to [mysterycall_paired_wait_within_practice()] and
#' [mysterycall_paired_acceptance_mcnemar()]: one line per cluster (practice)
#' connecting its outcome across the scenarios it was called under, over the raw
#' points. It shows the within-cluster differencing that motivates the matched
#' design -- whether the *same* practice tends to schedule one persona sooner
#' than another -- rather than the between-practice comparison a boxplot implies.
#' Only clusters observed under at least two scenarios are drawn (a single point
#' has no slope to show). Returns a [ggplot2::ggplot()].
#'
#' @param data A long data frame: one row per cluster x scenario call.
#' @param value Character scalar naming the numeric outcome column.
#' @param group Character scalar naming the grouping / scenario column
#'   (the x axis).
#' @param id Character scalar naming the cluster / practice id column (lines are
#'   grouped by this).
#' @param title,x_lab,y_lab Character scalars for the title and axis labels.
#'   `title` defaults to `NULL`; `x_lab` to `NULL`; `y_lab` to `value`.
#' @param line_alpha Numeric opacity for the connecting lines. Default `0.5`.
#'
#' @return A [ggplot2::ggplot()] object.
#'
#' @family visualization
#' @seealso [mysterycall_paired_wait_within_practice()],
#'   [mysterycall_plot_raincloud()]
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   d <- data.frame(
#'     practice = rep(1:15, each = 2),
#'     scenario = rep(c("Commercial", "Medicaid"), 15),
#'     wait     = c(rbind(rpois(15, 10), rpois(15, 22)))
#'   )
#'   mysterycall_plot_paired_slope(d, "wait", "scenario", "practice")
#' }
#' @export
mysterycall_plot_paired_slope <- function(data, value, group, id,
                                         title = NULL, x_lab = NULL,
                                         y_lab = value, line_alpha = 0.5) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_choice(value, names(data))
  checkmate::assert_choice(group, names(data))
  checkmate::assert_choice(id, names(data))
  checkmate::assert_number(line_alpha, lower = 0, upper = 1)
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("mysterycall_plot_paired_slope() requires the ggplot2 package.\n",
         "Install it with: install.packages(\"ggplot2\")", call. = FALSE)
  }
  if (!is.numeric(data[[value]])) {
    stop(sprintf("`value` column '%s' must be numeric.", value), call. = FALSE)
  }

  df <- data[!is.na(data[[value]]) & !is.na(data[[group]]) & !is.na(data[[id]]),
             , drop = FALSE]
  # Keep only clusters seen under 2+ distinct scenarios.
  n_scen <- tapply(as.character(df[[group]]), df[[id]],
                   function(x) length(unique(x)))
  keep_ids <- names(n_scen)[n_scen >= 2L]
  df <- df[as.character(df[[id]]) %in% keep_ids, , drop = FALSE]
  if (nrow(df) < 1L) {
    stop("No cluster is observed under two or more scenarios; nothing to pair.",
         call. = FALSE)
  }

  ggplot2::ggplot(
    df, ggplot2::aes(x = .data[[group]], y = .data[[value]],
                     group = .data[[id]])
  ) +
    ggplot2::geom_line(colour = "grey75", linewidth = 0.5, alpha = line_alpha) +
    ggplot2::geom_point(ggplot2::aes(colour = .data[[group]]), size = 2.8,
                        alpha = 0.85) +
    ggplot2::labs(title = title, x = x_lab, y = y_lab) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      legend.position    = "none",
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank()
    )
}
