#' Stacked bar chart of appointment acceptance by group
#'
#' @name mysterycall_plot_stacked_bar
NULL

#' Null Coalesce
#'
#' @param a Object to check if null.
#' @param b Default object.
#'
#' @return `a` if not null, else `b`.
#' @keywords internal
.null_coalesce <- function(a, b) if (!is.null(a)) a else b

#' Convert snake_case to Title Case
#'
#' @param x Character vector.
#'
#' @return Character vector in Title Case.
#' @keywords internal
.to_title <- function(x) {
  x <- gsub("_", " ", x, fixed = TRUE)
  # capitalize each word
  gsub("(^|\\s)(\\S)", "\\1\\U\\2", x, perl = TRUE)
}

#' Plot a horizontal stacked bar chart of binary outcome proportions
#'
#' Summarizes a binary 0/1 outcome column by a grouping variable and draws a
#' 100-percent stacked bar chart using `ggplot2`. Groups are laid out
#' horizontally (via [ggplot2::coord_flip()]) with the "accepted" bar segment
#' always on the right so high-acceptance groups stand out.
#'
#' @param data A data frame containing at least `outcome_col` and `group_col`.
#' @param outcome_col Character scalar. Name of a column with binary values
#'   `0` (not accepted) or `1` (accepted). `NA` values are excluded silently.
#' @param group_col Character scalar. Name of the x-axis grouping column
#'   (e.g. insurance type, specialty).
#' @param fill_labels Character vector of length 2. Display labels for the two
#'   bar segments. First element = 0-outcome label, second = 1-outcome label.
#'   Default `c("Not Accepted", "Accepted")`.
#' @param colors Character vector of length >= 2. Fill colors mapped to
#'   `fill_labels` in order. Default `c("#E05C6A", "#4A9F70")`.
#' @param title Character scalar. Plot title. `NULL` (default) produces no
#'   title.
#' @param x_label Character scalar. X-axis label (the grouping axis after
#'   coord_flip). `NULL` (default) derives a label from `group_col` by
#'   replacing underscores with spaces and converting to title case.
#' @param y_label Character scalar. Y-axis label (proportion axis).
#'   Default `"Proportion of Calls (%)"`.
#' @param show_n Logical. When `TRUE` (default) sample counts are overlaid
#'   inside each bar segment.
#' @param order_by_rate Logical. When `TRUE` (default) groups are sorted by
#'   descending acceptance rate so the highest-acceptance group appears at the
#'   top of the flipped chart.
#'
#' @return A `ggplot` object of class `c("gg", "ggplot")`. Pass to
#'   [mysterycall_save_plot()] or [ggplot2::ggsave()] to write to disk.
#'
#' @seealso [mysterycall_save_plot()] to write the returned plot to disk;
#'   [mysterycall_plot_scatter()] and [mysterycall_plot_density()] for
#'   continuous-outcome visualizations.
#' @family outcomes
#' @export
#'
#' @examples
#' set.seed(42)
#' df <- data.frame(
#'   insurance = sample(c("Medicaid", "BCBS", "Medicare"), 120, replace = TRUE),
#'   accepted  = sample(0:1, 120, replace = TRUE)
#' )
#' mysterycall_plot_stacked_bar(df, outcome_col = "accepted",
#'                               group_col  = "insurance")
mysterycall_plot_stacked_bar <- function(data,
                                          outcome_col,
                                          group_col,
                                          fill_labels    = c("Not Accepted", "Accepted"),
                                          colors         = c("#E05C6A", "#4A9F70"),
                                          title          = NULL,
                                          x_label        = NULL,
                                          y_label        = "Proportion of Calls (%)",
                                          show_n         = TRUE,
                                          order_by_rate  = TRUE) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for mysterycall_plot_stacked_bar(). Install with: install.packages('ggplot2')", call. = FALSE)
  }
  # ---- Validate inputs -------------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!outcome_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", outcome_col), call. = FALSE)
  }
  if (!group_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", group_col), call. = FALSE)
  }
  if (length(colors) < 2L) {
    stop("`colors` must have at least 2 elements.", call. = FALSE)
  }

  # Check outcome values are binary {0, 1, NA}
  outcome_vals <- data[[outcome_col]]
  bad_vals <- setdiff(unique(outcome_vals[!is.na(outcome_vals)]), c(0L, 1L, 0, 1))
  if (length(bad_vals) > 0L) {
    stop(sprintf(
      "Column '%s' must contain only 0, 1, or NA. Found: %s",
      outcome_col, paste(bad_vals, collapse = ", ")
    ), call. = FALSE)
  }

  # ---- Remove NA outcomes ----------------------------------------------------
  keep <- !is.na(data[[outcome_col]])
  data <- data[keep, , drop = FALSE]

  if (nrow(data) == 0L) {
    stop("No non-NA rows remain in `data` after filtering.", call. = FALSE)
  }

  # ---- Summarize per group ---------------------------------------------------
  groups        <- as.character(data[[group_col]])
  outcomes      <- as.integer(data[[outcome_col]])
  unique_groups <- sort(unique(groups))

  summary_rows <- lapply(unique_groups, function(g) {
    mask          <- groups == g
    n_total       <- sum(mask)
    n_accepted    <- sum(outcomes[mask] == 1L)
    n_not_accepted <- n_total - n_accepted
    pct_accepted     <- 100 * n_accepted    / n_total
    pct_not_accepted <- 100 * n_not_accepted / n_total
    list(
      group            = g,
      n_total          = n_total,
      n_accepted       = n_accepted,
      n_not_accepted   = n_not_accepted,
      pct_accepted     = pct_accepted,
      pct_not_accepted = pct_not_accepted
    )
  })

  smry <- data.frame(
    group            = vapply(summary_rows, `[[`, character(1L), "group"),
    n_total          = vapply(summary_rows, `[[`, integer(1L),   "n_total"),
    n_accepted       = vapply(summary_rows, `[[`, integer(1L),   "n_accepted"),
    n_not_accepted   = vapply(summary_rows, `[[`, integer(1L),   "n_not_accepted"),
    pct_accepted     = vapply(summary_rows, `[[`, double(1L),    "pct_accepted"),
    pct_not_accepted = vapply(summary_rows, `[[`, double(1L),    "pct_not_accepted"),
    stringsAsFactors = FALSE
  )

  # ---- Optional ordering -----------------------------------------------------
  if (order_by_rate) {
    smry <- smry[order(smry$pct_accepted, decreasing = FALSE), ]
  }
  group_levels <- smry$group   # order for factor

  # ---- Build long data frame -------------------------------------------------
  # ggplot2 stacks in reverse factor order: Accepted (level 2) lands on the
  # left (0 -> pct_accepted), Not Accepted (level 1) on the right
  # (pct_accepted -> 100).  Midpoints must match that layout.
  not_acc_df <- data.frame(
    group  = smry$group,
    status = fill_labels[1L],
    pct    = smry$pct_not_accepted,
    n      = smry$n_not_accepted,
    y_mid  = smry$pct_accepted + smry$pct_not_accepted / 2,
    stringsAsFactors = FALSE
  )
  acc_df <- data.frame(
    group  = smry$group,
    status = fill_labels[2L],
    pct    = smry$pct_accepted,
    n      = smry$n_accepted,
    y_mid  = smry$pct_accepted / 2,
    stringsAsFactors = FALSE
  )
  long_df <- rbind(not_acc_df, acc_df)
  long_df$group  <- factor(long_df$group,  levels = group_levels)
  long_df$status <- factor(long_df$status, levels = fill_labels)

  # ---- X-axis label ----------------------------------------------------------
  x_lab <- .null_coalesce(x_label, .to_title(group_col))

  # ---- Build plot ------------------------------------------------------------
  p <- ggplot2::ggplot(
      long_df,
      ggplot2::aes(x = .data[["group"]], y = .data[["pct"]],
                   fill = .data[["status"]])
    ) +
    ggplot2::geom_col(position = "stack", width = 0.7) +
    ggplot2::scale_fill_manual(
      values = stats::setNames(colors[seq_along(fill_labels)], fill_labels),
      labels = fill_labels,
      name   = NULL
    ) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = title,
      x     = x_lab,
      y     = y_label
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom")

  # ---- Optional N labels -----------------------------------------------------
  if (show_n) {
    p <- p +
      ggplot2::geom_text(
        ggplot2::aes(label = .data[["n"]], y = .data[["y_mid"]]),
        color   = "white",
        fontface = "bold",
        size     = 3.5
      )
  }

  p
}
