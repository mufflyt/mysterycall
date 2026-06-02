#' Full emmeans interaction plot with optional file save
#'
#' @name mysterycall_plot_emmeans_full
NULL

#' Compute and plot estimated marginal means with optional disk save
#'
#' Extends [mysterycall_plot_emmeans_interaction()] with three enhancements
#' drawn from the `plot_and_save_emmeans()` pattern in mystery-caller study
#' code:
#'
#' \enumerate{
#'   \item Uses `type = "response"` by default so Poisson models are plotted
#'     on the count scale (rates) rather than the log scale.
#'   \item Detects CI column names automatically -- handles both
#'     `asymp.LCL`/`asymp.UCL` (Poisson response scale) and
#'     `lower.CL`/`upper.CL` (Gaussian / identity scale).
#'   \item Accepts a `save_path` argument and calls
#'     [mysterycall_save_plot()] when supplied.
#' }
#'
#' @param model A fitted model accepted by [emmeans::emmeans()].
#' @param specs Character vector of marginal mean specifications. The first
#'   element is the x-axis variable; the second (if present) becomes the
#'   grouping variable for colour / shape.
#' @param variable Character scalar used as the x-axis label (underscores
#'   are replaced with spaces and the first letter is capitalised).
#' @param group_col Optional character scalar naming the grouping column.
#'   Overrides the second element of `specs` when supplied.
#' @param type Character scalar passed to [emmeans::emmeans()] as the
#'   `type` argument. Use `"response"` (default) for Poisson models so
#'   values are on the count/rate scale; use `"link"` for the log scale.
#' @param use_color Logical. `TRUE` (default) uses colour to distinguish
#'   groups; `FALSE` uses shapes and linetypes for greyscale output.
#' @param save_path Optional character scalar. Full file path (e.g.
#'   `"figures/emmeans_insurance.png"`). When non-`NULL`,
#'   [mysterycall_save_plot()] is called automatically.
#' @param width,height Numeric. Figure dimensions in inches passed to
#'   [mysterycall_save_plot()]. Defaults `10` x `6`.
#' @param dpi Integer. Resolution for saved figure. Default `300L`.
#'
#' @return Invisibly, a named list with elements:
#'   \describe{
#'     \item{`data`}{`data.frame` from [emmeans::emmeans()] with columns for
#'       the x-axis variable, `emmean` (or `rate` for Poisson link), `SE`,
#'       `df`, `lower.CL`/`upper.CL` (or `asymp.LCL`/`asymp.UCL` for large
#'       samples), and any grouping variable from `specs`. Exact column names
#'       depend on the model family.}
#'     \item{`plot`}{`ggplot` object. Print or pass to [ggplot2::ggsave()].}
#'   }
#'   Capture with `res <- mysterycall_plot_emmeans_full(...)` to access
#'   `res$data` and `res$plot`.
#'
#' @family outcomes
#' @export
#'
#' @examplesIf interactive()
#' res <- mysterycall_plot_emmeans_full(
#'   model    = fit,
#'   specs    = ~ insurance | gender,
#'   variable = "gender",
#'   use_color = TRUE,
#'   save_path = "figures/emmeans_gender.png"
#' )
#' res$plot
mysterycall_plot_emmeans_full <- function(model,
                                           specs,
                                           variable,
                                           group_col  = NULL,
                                           type       = "response",
                                           use_color  = TRUE,
                                           save_path  = NULL,
                                           width      = 10,
                                           height     = 6,
                                           dpi        = 300L) {
  if (!requireNamespace("emmeans", quietly = TRUE)) {
    stop("emmeans is required", call. = FALSE)
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required.", call. = FALSE)
  }
  if (!is.character(variable) || length(variable) != 1L) {
    stop("`variable` must be a single character string.", call. = FALSE)
  }

  # -- Compute emmeans ----------------------------------------------------------
  em <- emmeans::emmeans(model, specs = specs, type = type)
  df <- as.data.frame(em)

  # -- Determine column roles ---------------------------------------------------
  specs_chr <- if (is.character(specs)) specs else all.vars(stats::as.formula(specs))
  x_col   <- specs_chr[[1L]]
  grp_col <- if (!is.null(group_col)) {
    group_col
  } else if (length(specs_chr) >= 2L) {
    specs_chr[[2L]]
  } else {
    NULL
  }

  if (!x_col %in% names(df)) {
    stop("x-axis column '", x_col, "' not found in emmeans output.", call. = FALSE)
  }

  # CI column names differ by model family and emmeans type
  lcl_col <- intersect(c("asymp.LCL", "lower.CL", "lower.HPD"), names(df))
  ucl_col <- intersect(c("asymp.UCL", "upper.CL", "upper.HPD"), names(df))
  y_col   <- intersect(c("rate", "response", "emmean", "prob"),  names(df))

  if (length(lcl_col) == 0L || length(ucl_col) == 0L || length(y_col) == 0L) {
    stop("Could not detect y / CI columns in emmeans output. ",
         "Available: ", paste(names(df), collapse = ", "), call. = FALSE)
  }
  lcl_col <- lcl_col[[1L]]; ucl_col <- ucl_col[[1L]]; y_col <- y_col[[1L]]

  # -- Format label -------------------------------------------------------------
  label <- gsub("_", " ", variable)
  label <- paste0(toupper(substr(label, 1L, 1L)), substr(label, 2L, nchar(label)))

  # -- Build plot ---------------------------------------------------------------
  dodge <- ggplot2::position_dodge(width = 0.25)

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x    = .data[[x_col]],
    y    = .data[[y_col]],
    ymin = .data[[lcl_col]],
    ymax = .data[[ucl_col]]
  ))

  if (use_color && !is.null(grp_col)) {
    p <- p +
      ggplot2::geom_point(
        ggplot2::aes(color = .data[[grp_col]]),
        size = 3, position = dodge
      ) +
      ggplot2::geom_errorbar(
        ggplot2::aes(color = .data[[grp_col]]),
        width = 0.2, position = dodge
      )
  } else if (!is.null(grp_col)) {
    p <- p +
      ggplot2::geom_point(
        ggplot2::aes(shape = .data[[grp_col]]),
        size = 3, position = dodge, alpha = 0.7
      ) +
      ggplot2::geom_errorbar(
        ggplot2::aes(linetype = .data[[grp_col]]),
        width = 0.2, position = dodge, linewidth = 0.5
      )
  } else {
    p <- p +
      ggplot2::geom_point(size = 3, position = dodge) +
      ggplot2::geom_errorbar(width = 0.2, position = dodge)
  }

  p <- p +
    ggplot2::labs(
      title    = paste("Estimated Marginal Means\n", label),
      x        = label,
      y        = "Estimated Marginal Means\n(Mean +/- 95% CI)",
      color    = grp_col,
      shape    = grp_col,
      linetype = grp_col
    ) +
    ggplot2::theme_minimal(base_size = 14L) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title      = ggplot2::element_text(face = "bold", size = 16L),
      axis.title      = ggplot2::element_text(size = 14L),
      legend.title    = ggplot2::element_blank(),
      axis.text.x     = ggplot2::element_text(angle = 45, vjust = 1, hjust = 1)
    )

  # -- Optionally save ----------------------------------------------------------
  if (!is.null(save_path)) {
    mysterycall_save_plot(p, save_path, width = width, height = height, dpi = dpi)
  }

  invisible(list(data = df, plot = p))
}
