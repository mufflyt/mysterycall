#' Plot disparity metrics from a `mysterycall_disparities_table`
#'
#' Produces a publication-ready dot plot of acceptance rates, absolute
#' differences, or relative risks computed by [mysterycall_disparities_table()].
#' The function is the binary-outcome analogue of [mysterycall_irr_plot()]:
#' call `mysterycall_disparities_table()` first, then pipe the result here.
#'
#' @param x A `mysterycall_disparities_table` object returned by
#'   [mysterycall_disparities_table()], **or** a plain data frame with at least
#'   the columns required by the chosen `metric` (see Details).
#' @param metric Character scalar. Which disparity metric to display on the
#'   x-axis:
#'   \describe{
#'     \item{`"rate"` (default)}{Appointment-offered rate for each group with
#'       its CI. A vertical dashed reference line marks the reference group
#'       rate.}
#'     \item{`"abs_diff"`}{Absolute difference in percentage points versus the
#'       reference group. Reference line at 0.}
#'     \item{`"rel_risk"`}{Relative risk versus the reference group. Reference
#'       line at 1.}
#'   }
#' @param show_ref Logical. When `TRUE` (default) the reference group row is
#'   included in the plot, drawn with `color_ref` and a diamond shape.
#' @param show_p Logical. When `TRUE` (default) the formatted p-value is
#'   annotated to the right of each non-reference point.
#' @param color_sig Character. Color for groups whose `p_value < 0.05`.
#'   Default `"#C0392B"` (red).
#' @param color_ns Character. Color for non-significant groups (or when
#'   `p_value` is absent). Default `"#2C3E50"` (dark navy).
#' @param color_ref Character. Color for the reference group point.
#'   Default `"#2166AC"` (blue).
#' @param point_size Numeric. Diameter of the estimate point. Default `3`.
#' @param x_label Character or `NULL`. X-axis label. `NULL` (default) picks a
#'   label automatically from `metric`.
#' @param x_pct Logical. When `TRUE` (default for `"rate"` and `"abs_diff"`)
#'   the x-axis is formatted as a percentage. Ignored when `metric =
#'   "rel_risk"`.
#' @param title Character or `NULL`. Plot title. Default `NULL` (no title).
#'
#' @return A [`ggplot2::ggplot`] object. Print it to display or pass to
#'   [ggplot2::ggsave()] to save.
#'
#' @details
#' **Required columns by metric:**
#' \describe{
#'   \item{`"rate"`}{`group`, `rate`, `lower_ci`, `upper_ci`}
#'   \item{`"abs_diff"`}{`group`, `abs_diff`, `lower_ci`, `upper_ci`
#'     (CIs are re-centered automatically)}
#'   \item{`"rel_risk"`}{`group`, `rel_risk`, `rr_lower`, `rr_upper`}
#' }
#' When `x` is a `mysterycall_disparities_table` object the reference group
#' and significance attributes are read directly from the object's attributes.
#' When `x` is a plain data frame, a `p_value` column is used for significance
#' coloring if present, and the first row is treated as the reference group
#' when `show_ref = TRUE`.
#'
#' @family plotting
#' @seealso [mysterycall_disparities_table()], [mysterycall_irr_plot()]
#' @export
#'
#' @examples
#' set.seed(42)
#' df <- data.frame(
#'   insurance = sample(c("Medicaid", "Medicare", "Private", "Uninsured"),
#'                      300, replace = TRUE),
#'   accepted  = rbinom(300, 1, prob = rep(c(0.64, 0.84, 0.91, 0.54), 75))
#' )
#' tbl <- mysterycall_disparities_table(df, "accepted", "insurance",
#'                                       ref_group = "Private")
#' mysterycall_plot_disparities(tbl)
#' mysterycall_plot_disparities(tbl, metric = "abs_diff")
#' mysterycall_plot_disparities(tbl, metric = "rel_risk")
mysterycall_plot_disparities <- function(
    x,
    metric     = c("rate", "abs_diff", "rel_risk"),
    show_ref   = TRUE,
    show_p     = TRUE,
    color_sig  = "#C0392B",
    color_ns   = "#2C3E50",
    color_ref  = "#2166AC",
    point_size = 3,
    x_label    = NULL,
    x_pct      = NULL,
    title      = NULL
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required",
         call. = FALSE)
  }
  if (!requireNamespace("scales", quietly = TRUE)) {
    stop("Package 'scales' is required for mysterycall_plot_disparities().", call. = FALSE)
  }

  metric <- match.arg(metric)

  # ---- extract / validate data -----------------------------------------------
  is_disp <- inherits(x, "mysterycall_disparities_table")

  ref_group <- if (is_disp) attr(x, "ref_group") else x$group[[1L]]
  alpha_raw <- if (is_disp) attr(x, "alpha") else NULL
  alpha_val <- if (!is.null(alpha_raw)) alpha_raw else 0.05

  tbl <- as.data.frame(x)

  required_cols <- switch(metric,
    rate     = c("group", "rate", "lower_ci", "upper_ci"),
    abs_diff = c("group", "abs_diff", "lower_ci", "upper_ci"),
    rel_risk = c("group", "rel_risk", "rr_lower", "rr_upper")
  )
  missing_cols <- setdiff(required_cols, names(tbl))
  if (length(missing_cols)) {
    stop(sprintf(
      "Column(s) required for metric = '%s' not found: %s",
      metric, paste(missing_cols, collapse = ", ")
    ), call. = FALSE)
  }

  # ---- filter reference group ------------------------------------------------
  if (!show_ref) {
    tbl <- tbl[tbl$group != ref_group, , drop = FALSE]
  }

  if (!nrow(tbl)) {
    stop("No rows remain after filtering. Set `show_ref = TRUE`.", call. = FALSE)
  }

  # ---- build x / xmin / xmax columns ----------------------------------------
  if (metric == "rate") {
    tbl$.x    <- tbl$rate
    tbl$.xmin <- tbl$lower_ci
    tbl$.xmax <- tbl$upper_ci
    ref_line  <- if (ref_group %in% tbl$group) tbl$rate[tbl$group == ref_group] else NULL
    auto_label <- paste0("Appointment-offered rate\n(",
                         round((1 - alpha_val) * 100), " % CI)")
    auto_pct   <- TRUE
  } else if (metric == "abs_diff") {
    tbl$.x    <- tbl$abs_diff
    # CI half-width from the rate CI, re-centered on abs_diff
    hw        <- (tbl$upper_ci - tbl$lower_ci) / 2
    tbl$.xmin <- tbl$abs_diff - hw
    tbl$.xmax <- tbl$abs_diff + hw
    ref_line  <- 0
    auto_label <- paste0("Absolute difference (pp vs. ", ref_group, ")")
    auto_pct   <- TRUE
  } else {
    tbl$.x    <- tbl$rel_risk
    tbl$.xmin <- tbl$rr_lower
    tbl$.xmax <- tbl$rr_upper
    ref_line  <- 1
    auto_label <- paste0("Relative risk vs. ", ref_group)
    auto_pct   <- FALSE
  }

  if (is.null(x_label)) x_label <- auto_label
  if (is.null(x_pct))   x_pct   <- auto_pct

  # ---- significance coloring ------------------------------------------------
  is_ref_row <- tbl$group == ref_group

  if ("p_value" %in% names(tbl) && is.numeric(tbl$p_value)) {
    tbl$.color <- ifelse(
      is_ref_row, color_ref,
      ifelse(!is.na(tbl$p_value) & tbl$p_value < alpha_val, color_sig, color_ns)
    )
  } else {
    tbl$.color <- ifelse(is_ref_row, color_ref, color_ns)
  }
  tbl$.shape <- ifelse(is_ref_row, 18L, 16L)  # diamond for ref, circle for others

  # ---- group ordering: ref at top, others by descending x -------------------
  non_ref   <- tbl[!is_ref_row, , drop = FALSE]
  non_ref   <- non_ref[order(non_ref$.x), , drop = FALSE]
  ref_row   <- tbl[is_ref_row, , drop = FALSE]
  tbl_ord   <- rbind(ref_row, non_ref)
  tbl_ord$group <- factor(tbl_ord$group, levels = tbl_ord$group)

  # ---- p-value labels --------------------------------------------------------
  if (show_p && "p_value_fmt" %in% names(tbl_ord)) {
    tbl_ord$.p_label <- ifelse(is_ref_row[match(tbl_ord$group, tbl$group)],
                               "(ref)", tbl_ord$p_value_fmt)
  } else if (show_p && "p_value" %in% names(tbl_ord)) {
    fmt_p <- function(p) {
      ifelse(is.na(p), "(ref)",
             ifelse(p < 0.001, "p < 0.001",
                    paste0("p = ", formatC(p, digits = 3, format = "f"))))
    }
    tbl_ord$.p_label <- fmt_p(tbl_ord$p_value)
    tbl_ord$.p_label[is_ref_row[match(tbl_ord$group, tbl$group)]] <- "(ref)"
  } else {
    show_p <- FALSE
  }

  # ---- build plot ------------------------------------------------------------
  p <- ggplot2::ggplot(
    tbl_ord,
    ggplot2::aes(x = .x, y = group, xmin = .xmin, xmax = .xmax)
  )

  if (!is.null(ref_line)) {
    p <- p + ggplot2::geom_vline(
      xintercept = ref_line,
      linetype   = "dashed",
      color     = "grey55",
      linewidth  = 0.5
    )
  }

  p <- p +
    suppressWarnings(
      ggplot2::geom_errorbarh(
        ggplot2::aes(color = I(.color)),
        height    = 0.18,
        linewidth = 0.8
      )
    ) +
    ggplot2::geom_point(
      ggplot2::aes(color = I(.color), shape = I(.shape)),
      size = point_size
    )

  if (show_p) {
    x_expand_right <- (max(tbl_ord$.xmax, na.rm = TRUE) -
                         min(tbl_ord$.xmin, na.rm = TRUE)) * 0.06
    p <- p + ggplot2::geom_text(
      ggplot2::aes(x = .xmax + x_expand_right, label = .p_label),
      hjust  = 0,
      size   = 3,
      color = "grey35"
    )
  }

  if (x_pct && metric != "rel_risk") {
    if (requireNamespace("scales", quietly = TRUE)) {
      p <- p + ggplot2::scale_x_continuous(
        labels = scales::percent_format(accuracy = 1),
        expand = ggplot2::expansion(mult = c(0.04, if (show_p) 0.28 else 0.06))
      )
    }
  } else {
    p <- p + ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = c(0.04, if (show_p) 0.28 else 0.06))
    )
  }

  p <- p +
    ggplot2::labs(x = x_label, y = NULL, title = title) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),
      axis.text.y        = ggplot2::element_text(size = 10, face = "bold"),
      plot.title         = ggplot2::element_text(size = 12, face = "bold")
    )

  p
}
