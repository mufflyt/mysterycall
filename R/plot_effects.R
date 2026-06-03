#' Marginal effect plots for fitted models
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @name plot_effects
NULL

#' Plot marginal effects for a single model term
#'
#' Calls [effects::effect()] on a fitted model and returns a ggplot2 ribbon
#' plot of the marginal predicted values with 95% confidence bands. Works
#' with any model class supported by the **effects** package (lm, glm,
#' glmerMod, lmerMod, ...).
#'
#' @param model A fitted model object.
#' @param term Character scalar. The term to visualize (must match a fixed
#'   effect in the model, e.g. `"insurance"`, `"age"`, or
#'   `"insurance:gender"` for an interaction).
#' @param type Character scalar. `"response"` (default) plots on the
#'   response scale (exponentiating for Poisson/logistic); `"link"` plots
#'   on the linear predictor scale.
#' @param x_label Character scalar. X-axis label. Defaults to `term`.
#' @param y_label Character scalar. Y-axis label. Defaults to
#'   `"Predicted response"` or `"Linear predictor"`.
#'
#' @return A `ggplot` object.
#'
#' @family outcomes
#' @export
#'
#' @examplesIf interactive()
#' m <- glm(mpg ~ wt + hp, data = mtcars, family = gaussian())
#' mysterycall_plot_effect(m, "wt")
mysterycall_plot_effect <- function(model,
                                     term,
                                     type    = c("response", "link"),
                                     x_label = NULL,
                                     y_label = NULL) {
  type <- match.arg(type)
  if (!requireNamespace("effects", quietly = TRUE)) {
    stop("effects is required", call. = FALSE)
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required", call. = FALSE)
  }
  if (!is.character(term) || length(term) != 1L) {
    stop("`term` must be a single character string.", call. = FALSE)
  }

  eff <- tryCatch(
    effects::effect(term, model),
    error = function(e) stop("effects::effect() failed: ", conditionMessage(e), call. = FALSE)
  )
  df <- as.data.frame(eff)

  x_col <- intersect(term, names(df))
  if (length(x_col) == 0L) x_col <- names(df)[[1L]]

  xl <- if (!is.null(x_label)) x_label else term
  yl <- if (!is.null(y_label)) y_label else
          if (type == "response") "Predicted response" else "Linear predictor"

  ggplot2::ggplot(df, ggplot2::aes(
    x    = .data[[x_col]],
    y    = .data[["fit"]],
    ymin = .data[["lower"]],
    ymax = .data[["upper"]]
  )) +
    ggplot2::geom_ribbon(alpha = 0.2, fill = "#2C3E50") +
    ggplot2::geom_line(color = "#2C3E50", linewidth = 1) +
    ggplot2::labs(x = xl, y = yl) +
    ggplot2::theme_minimal()
}


#' Interaction visualization via sjPlot
#'
#' Thin wrapper around [sjPlot::plot_model()] with `type = "int"`. Returns a
#' ggplot object that can be further customised with standard ggplot2 layers.
#'
#' @param model A fitted model accepted by `sjPlot::plot_model()`.
#' @param terms Character vector of terms to include in the interaction plot
#'   (passed to `sjPlot::plot_model(terms = ...)`).
#' @param title Optional character scalar plot title.
#' @param ... Additional arguments forwarded to `sjPlot::plot_model()`.
#'
#' @return A `ggplot` object.
#'
#' @family outcomes
#' @export
#'
#' @examplesIf interactive()
#' mysterycall_plot_sjplot_interaction(fit,
#'   terms = c("insurance", "gender"),
#'   title = "Insurance x Gender interaction"
#' )
mysterycall_plot_sjplot_interaction <- function(model, terms, title = NULL, ...) {
  if (!requireNamespace("sjPlot", quietly = TRUE)) {
    stop("sjPlot is required", call. = FALSE)
  }
  if (!is.character(terms) || length(terms) < 1L) {
    stop("`terms` must be a non-empty character vector.", call. = FALSE)
  }
  sjPlot::plot_model(model, type = "int", terms = terms, title = title, ...)
}
