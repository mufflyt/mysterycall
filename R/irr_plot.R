#' IRR forest plot for a Poisson GLMER result
#'
#' @name mysterycall_irr_plot
NULL


#' Plot incidence rate ratios from a fitted Poisson or negative binomial model
#'
#' Produces a publication-ready forest plot showing each fixed-effect term as
#' an incidence rate ratio (point) with its Wald confidence interval (horizontal
#' bar). The intercept row is excluded by default. A vertical reference line
#' marks IRR = 1 (no effect). Requires `ggplot2` (listed in Suggests).
#'
#' @param x A `mysterycall_poisson_model` object from
#'   [mysterycall_poisson_model()], a `mysterycall_nb_model` object from
#'   [mysterycall_nb_model()], **or** a data frame with columns `term`,
#'   `irr`, `ci_lower`, `ci_upper` (and optionally `p_value`).
#' @param include_intercept Logical. When `FALSE` (default) the `(Intercept)`
#'   row is dropped before plotting.
#' @param reference_line Numeric. X-axis position for the null-effect vertical
#'   line. Default `1` (IRR = 1).
#' @param point_size Numeric. Size of the IRR point. Default `3`.
#' @param color_sig Character. Color for terms with `p_value < 0.05`. Default
#'   `"#C0392B"` (red). Only applied when the `p_value` column is present.
#' @param color_ns Character. Color for non-significant terms (or when
#'   `p_value` is absent). Default `"#2C3E50"` (dark navy).
#' @param x_label Character. X-axis label. Default `"Incidence Rate Ratio (IRR)"`.
#' @param title Character. Plot title. `NULL` (default) produces no title.
#' @param x_log Logical. When `TRUE` the X axis is log-transformed so that
#'   equal-ratio distances look equal. Default `FALSE`.
#'
#' @return A `ggplot` object. Print it or save with [ggplot2::ggsave()].
#'
#' @family outcomes
#' @seealso [mysterycall_poisson_model()], [mysterycall_nb_model()]
#' @export
#'
#' @examples
#' if (requireNamespace("lme4", quietly = TRUE)) {
#'   set.seed(1978)
#'   df <- data.frame(
#'     wait_days = rpois(40, lambda = 18),
#'     insurance = rep(c("Medicaid", "BCBS"), each = 20),
#'     gender    = sample(c("Male", "Female"), 40, replace = TRUE),
#'     physician = rep(paste0("Dr_", 1:8), each = 5),
#'     stringsAsFactors = FALSE
#'   )
#'   result <- suppressWarnings(mysterycall_poisson_model(
#'     df, "wait_days", c("insurance", "gender"), "physician"
#'   ))
#'   mysterycall_irr_plot(result)
#' }
mysterycall_irr_plot <- function(x,
                                  include_intercept = FALSE,
                                  reference_line    = 1,
                                  point_size        = 3,
                                  color_sig         = "#C0392B",
                                  color_ns          = "#2C3E50",
                                  x_label           = "Incidence Rate Ratio (IRR)",
                                  title             = NULL,
                                  x_log             = FALSE) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for mysterycall_irr_plot(). Install with: install.packages('ggplot2')", call. = FALSE)
  }

  # -- Extract table ----------------------------------------------------------
  if (inherits(x, c("mysterycall_poisson_model", "mysterycall_nb_model"))) {
    tbl <- x$irr_table
  } else if (is.data.frame(x)) {
    required <- c("term", "irr", "ci_lower", "ci_upper")
    missing_cols <- setdiff(required, names(x))
    if (length(missing_cols)) {
      stop(sprintf("Data frame is missing required columns: %s",
                   paste(missing_cols, collapse = ", ")), call. = FALSE)
    }
    tbl <- x
  } else {
    stop("`x` must be a `mysterycall_poisson_model`, `mysterycall_nb_model`, or a data frame.",
         call. = FALSE)
  }

  if (!include_intercept) {
    tbl <- tbl[tbl$term != "(Intercept)", , drop = FALSE]
  }

  if (!nrow(tbl)) {
    stop("No rows remain after filtering. Set `include_intercept = TRUE` if only the intercept was present.",
         call. = FALSE)
  }

  # -- Significance coloring -------------------------------------------------
  if ("p_value" %in% names(tbl) && is.numeric(tbl$p_value)) {
    tbl$.sig <- ifelse(!is.na(tbl$p_value) & tbl$p_value < 0.05,
                       color_sig, color_ns)
  } else {
    tbl$.sig <- color_ns
  }

  # -- Term ordering: bottom-to-top matches table reading order --------------
  tbl$term <- factor(tbl$term, levels = rev(tbl$term))

  # -- Build plot -------------------------------------------------------------
  # geom_errorbarh() is deprecated in ggplot2 >= 4.0.0; suppress the lifecycle
  # warning here and use geom_errorbar() with orientation = "horizontal" once
  # ggplot2 >= 4.0.0 is required.
  errorbarh_layer <- suppressWarnings(
    ggplot2::geom_errorbarh(
      ggplot2::aes(xmin = ci_lower, xmax = ci_upper),
      height    = 0.25,
      color     = tbl$.sig[order(as.integer(tbl$term))],
      linewidth = 0.7
    )
  )

  p <- ggplot2::ggplot(tbl, ggplot2::aes(x = irr, y = term)) +
    ggplot2::geom_vline(xintercept = reference_line,
                        linetype = "dashed", color = "grey60", linewidth = 0.5) +
    errorbarh_layer +
    ggplot2::geom_point(
      size   = point_size,
      color = tbl$.sig[order(as.integer(tbl$term))],
      shape  = 18
    ) +
    ggplot2::labs(
      x     = x_label,
      y     = NULL,
      title = title
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),
      axis.text.y        = ggplot2::element_text(size = 10),
      plot.title         = ggplot2::element_text(size = 12, face = "bold")
    )

  if (x_log) {
    p <- p + ggplot2::scale_x_log10()
  }

  p
}
