#' Three-circle Venn diagram for data-source overlap
#'
#' Visualizes how three data sources (A, B, C) cover a universe of providers,
#' labelling each region with its count and the center with the three-way
#' intersection count and percentage.  The result is a [ggplot2::ggplot()]
#' object, optionally written to disk.
#'
#' @param data_or_path A named list whose elements are character or numeric
#'   vectors of provider IDs, **or** a file path to an `.rds` file containing
#'   such a list.
#' @param A_col,B_col,C_col Character scalars naming the list elements that
#'   correspond to circles A, B, and C respectively.
#'   Defaults: `"nppes"`, `"pc"`, `"dac"`.
#' @param universe_col Character scalar naming the list element that contains
#'   the complete universe of provider IDs.  When `NULL` the universe is taken
#'   as `union(A, union(B, C))`.  Default `"npis"`.
#' @param source_short Character vector of length 3.  Short labels used inside
#'   the intersection region annotations (e.g. `"NPPES + PC"`).
#' @param source_long Character vector of length 3.  Full labels used in the
#'   bold header annotations above/below each circle.
#' @param fills Character vector of length 3.  Fill colors for circles A, B,
#'   C (hex or R color names).
#' @param border_colors Character vector of length 3.  Border and text colors
#'   matching each circle.
#' @param title,subtitle,caption Character scalars for plot text.  When
#'   `subtitle` or `caption` is `NULL` a sensible default is auto-generated
#'   from the counts.
#' @param output_path Optional file path.  When supplied the plot is saved with
#'   [ggplot2::ggsave()].  The file format is inferred from the extension
#'   (`.png`, `.pdf`, `.svg`, etc.).
#' @param width,height Numeric.  Plot dimensions in inches passed to
#'   [ggplot2::ggsave()].  Defaults `11` x `9`.
#' @param dpi Integer.  Resolution for raster output.  Default `300`.
#' @param bg Character scalar.  Background color passed to
#'   [ggplot2::ggsave()].  Default `"white"`.
#'
#' @return A [ggplot2::ggplot()] object. Returned visibly when `output_path`
#'   is `NULL` so it prints to the active graphics device. Returned
#'   `invisible()` when `output_path` is supplied (the save is the intended
#'   side effect); assign the return value to capture the object for further
#'   modification.
#'
#' @section Data format:
#'   The input list must have at minimum three named elements whose values are
#'   vectors of provider identifiers (typically NPI strings).  Example:
#'   ```r
#'   d <- list(
#'     npis  = c("A","B","C","D","E"),   # universe
#'     nppes = c("A","B","C"),
#'     pc    = c("B","C","D"),
#'     dac   = c("C","D","E")
#'   )
#'   mysterycall_plot_source_venn(d)
#'   ```
#'
#' @importFrom ggplot2 ggplot annotate coord_fixed theme_void theme element_text margin ggsave labs geom_polygon
#' @family plotting
#' @export
#'
#' @examplesIf interactive()
#' d <- list(
#'   npis  = as.character(1:100),
#'   nppes = as.character(1:70),
#'   pc    = as.character(30:90),
#'   dac   = as.character(50:100)
#' )
#' p <- mysterycall_plot_source_venn(d, title = "Demo Venn Diagram")
#' print(p)
mysterycall_plot_source_venn <- function(
    data_or_path,
    A_col         = "nppes",
    B_col         = "pc",
    C_col         = "dac",
    universe_col  = "npis",
    source_short  = c("NPPES", "PC", "DAC"),
    source_long   = c("NPPES", "Physician Compare", "DAC"),
    fills         = c("#2196F3", "#4CAF50", "#FF9800"),
    border_colors = c("#1565C0", "#2E7D32", "#E65100"),
    title         = "Gender Data Availability Across Sources",
    subtitle      = NULL,
    caption       = NULL,
    output_path   = NULL,
    width         = 11,
    height        = 9,
    dpi           = 300L,
    bg            = "white") {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required",
         call. = FALSE)
  }

  circle_path <- function(x0, y0, r, n = 200L) {
    theta <- seq(0, 2 * pi, length.out = n)
    data.frame(x = x0 + r * cos(theta), y = y0 + r * sin(theta))
  }

  # -- Load data --------------------------------------------------------------
  if (is.character(data_or_path) && length(data_or_path) == 1L) {
    if (!file.exists(data_or_path)) {
      stop(sprintf("File not found: %s", data_or_path), call. = FALSE)
    }
    d <- readRDS(data_or_path)
  } else if (is.list(data_or_path)) {
    d <- data_or_path
  } else {
    stop("`data_or_path` must be a named list or a path to an .rds file.",
         call. = FALSE)
  }

  for (col in c(A_col, B_col, C_col)) {
    if (!col %in% names(d)) {
      stop(sprintf("Key '%s' not found in data. Available keys: %s",
                   col, paste(names(d), collapse = ", ")), call. = FALSE)
    }
  }

  A <- d[[A_col]]
  B <- d[[B_col]]
  C <- d[[C_col]]

  universe <- if (!is.null(universe_col) && universe_col %in% names(d)) {
    d[[universe_col]]
  } else {
    union(A, union(B, C))
  }
  n_total <- length(universe)

  if (!is.character(source_short) || length(source_short) != 3L) {
    stop("`source_short` must be a character vector of length 3.", call. = FALSE)
  }
  if (!is.character(source_long) || length(source_long) != 3L) {
    stop("`source_long` must be a character vector of length 3.", call. = FALSE)
  }
  if (!is.character(fills) || length(fills) != 3L) {
    stop("`fills` must be a character vector of length 3.", call. = FALSE)
  }
  if (!is.character(border_colors) || length(border_colors) != 3L) {
    stop("`border_colors` must be a character vector of length 3.", call. = FALSE)
  }

  # -- Compute regions --------------------------------------------------------
  ABC    <- intersect(intersect(A, B), C)
  AB_only <- setdiff(intersect(A, B), C)
  AC_only <- setdiff(intersect(A, C), B)
  BC_only <- setdiff(intersect(B, C), A)
  A_only  <- setdiff(A, union(B, C))
  B_only  <- setdiff(B, union(A, C))
  C_only  <- setdiff(C, union(A, B))
  none    <- setdiff(universe, union(A, union(B, C)))

  fmt <- function(n) format(n, big.mark = ",")

  # -- Circle geometry (fixed layout) -----------------------------------------
  circles <- data.frame(
    x0 = c(-1.2, 1.2, 0),
    y0 = c(0.7,  0.7, -0.8),
    r  = c(2.5,  2.3,  2.2),
    stringsAsFactors = FALSE
  )

  # -- Auto-generate subtitle / caption ---------------------------------------
  if (is.null(subtitle)) {
    subtitle <- sprintf(
      "%s total  |  %s (%.1f%%) in no source  |  Cascade: %s > %s > %s",
      fmt(n_total),
      fmt(length(none)), 100 * length(none) / n_total,
      source_short[1], source_short[2], source_short[3]
    )
  }

  # -- Build plot -------------------------------------------------------------
  circle_A <- circle_path(circles$x0[1L], circles$y0[1L], circles$r[1L])
  circle_B <- circle_path(circles$x0[2L], circles$y0[2L], circles$r[2L])
  circle_C <- circle_path(circles$x0[3L], circles$y0[3L], circles$r[3L])

  p <- ggplot2::ggplot() +
    ggplot2::geom_polygon(
      data = circle_A, ggplot2::aes(x = .data$x, y = .data$y),
      fill = fills[1L], alpha = 0.2, color = border_colors[1L], linewidth = 0.8
    ) +
    ggplot2::geom_polygon(
      data = circle_B, ggplot2::aes(x = .data$x, y = .data$y),
      fill = fills[2L], alpha = 0.2, color = border_colors[2L], linewidth = 0.8
    ) +
    ggplot2::geom_polygon(
      data = circle_C, ggplot2::aes(x = .data$x, y = .data$y),
      fill = fills[3L], alpha = 0.2, color = border_colors[3L], linewidth = 0.8
    ) +

    # -- Region counts ------------------------------------------------------
    ggplot2::annotate("text", x = -2.8, y = 2.2,
                      label = sprintf("%s\nonly", fmt(length(A_only))),
                      size = 3.5, color = "gray30", lineheight = 0.9) +
    ggplot2::annotate("text", x = 2.8, y = 2.2,
                      label = sprintf("%s\nonly", fmt(length(B_only))),
                      size = 3.5, color = "gray30", lineheight = 0.9) +
    ggplot2::annotate("text", x = 0, y = -2.6,
                      label = sprintf("%s\nonly", fmt(length(C_only))),
                      size = 3.5, color = "gray30", lineheight = 0.9) +
    ggplot2::annotate("text", x = -0.1, y = 1.6,
                      label = sprintf("%s + %s\n%s",
                                      source_short[1], source_short[2],
                                      fmt(length(AB_only))),
                      size = 3.2, color = "gray30", lineheight = 0.9) +
    ggplot2::annotate("text", x = -1.5, y = -1.0,
                      label = sprintf("%s + %s\n%s",
                                      source_short[1], source_short[3],
                                      fmt(length(AC_only))),
                      size = 3.2, color = "gray30", lineheight = 0.9) +
    ggplot2::annotate("text", x = 1.3, y = -1.0,
                      label = sprintf("%s + %s\n%s",
                                      source_short[2], source_short[3],
                                      fmt(length(BC_only))),
                      size = 3.2, color = "gray30", lineheight = 0.9) +

    # -- Centre: all three -------------------------------------------------
    ggplot2::annotate("text", x = 0.05, y = 0.15,
                      label = sprintf("All three\n%s\n(%.0f%%)",
                                      fmt(length(ABC)),
                                      100 * length(ABC) / n_total),
                      size = 5, fontface = "bold", color = "gray10",
                      lineheight = 0.9) +

    # -- Source header labels -----------------------------------------------
    ggplot2::annotate("label", x = -2.6, y = 3.4,
                      label = sprintf("%s\nn = %s (%.1f%%)",
                                      source_long[1],
                                      fmt(length(A)), 100 * length(A) / n_total),
                      size = 3.8, fontface = "bold",
                      color = border_colors[1L], fill = "white", alpha = 0.9,
                      lineheight = 0.85) +
    ggplot2::annotate("label", x = 2.6, y = 3.4,
                      label = sprintf("%s\nn = %s (%.1f%%)",
                                      source_long[2],
                                      fmt(length(B)), 100 * length(B) / n_total),
                      size = 3.8, fontface = "bold",
                      color = border_colors[2L], fill = "white", alpha = 0.9,
                      lineheight = 0.85) +
    ggplot2::annotate("label", x = 0, y = -3.6,
                      label = sprintf("%s\nn = %s (%.1f%%)",
                                      source_long[3],
                                      fmt(length(C)), 100 * length(C) / n_total),
                      size = 3.8, fontface = "bold",
                      color = border_colors[3L], fill = "white", alpha = 0.9,
                      lineheight = 0.85) +

    ggplot2::labs(title = title, subtitle = subtitle, caption = caption) +
    ggplot2::coord_fixed(clip = "off") +
    ggplot2::theme_void(base_size = 13) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold", size = 16, hjust = 0.5,
                                            margin = ggplot2::margin(b = 4)),
      plot.subtitle = ggplot2::element_text(size = 10, hjust = 0.5, color = "gray40",
                                            margin = ggplot2::margin(b = 15)),
      plot.caption  = ggplot2::element_text(size = 8, hjust = 0.5, color = "gray50",
                                            lineheight = 1.2,
                                            margin = ggplot2::margin(t = 15)),
      plot.margin   = ggplot2::margin(15, 20, 15, 20)
    )

  # -- Optionally save --------------------------------------------------------
  if (!is.null(output_path)) {
    dir.create(dirname(output_path), showWarnings = FALSE, recursive = TRUE)
    ggplot2::ggsave(output_path, p, width = width, height = height,
                    dpi = dpi, bg = bg)
    message(sprintf("Saved: %s", output_path))
    return(invisible(p))
  }

  p
}
