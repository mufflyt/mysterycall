# Green Journal (Obstetrics & Gynecology) ggplot2 themes, palette, and helpers
#
# Implements the figure specifications from the Green Journal (Obstetrics &
# Gynecology, Wolters Kluwer) 2024 Author Guidelines:
#   - Single column 3.5 in / double column 7.0 in
#   - Arial/sans, 8-12 pt, minimum 6 pt
#   - TIFF (LZW) primary; PDF vector companion
#   - Okabe-Ito colorblind-safe palette (Wong, Nature Methods 2011)
#   - No gray panel background; black axes with ticks; bottom legend


# -- Figure dimension constants -------------------------------------------------
.GJ <- list(
  single_width = 3.5,
  double_width = 7.0,
  max_height   = 9.0,
  dpi          = 300L
)


# =============================================================================
# THEMES
# =============================================================================

#' Green Journal ggplot2 theme
#'
#' Publication-quality theme conforming to *Obstetrics & Gynecology*
#' (Green Journal, Wolters Kluwer) 2024 author guidelines: white background,
#' Arial/sans font, black axes with tick marks, minimal gridlines, bottom
#' legend. Pair with [mysterycall_palette_green_journal()] and
#' [mysterycall_save_green_journal_figure()] for a complete submission workflow.
#'
#' @param base_size Numeric. Base font size in points (default 10; Green
#'   Journal range 8-12 pt, minimum 6 pt for labels).
#' @param base_family Character. Font family. Defaults to `"Arial"` with
#'   automatic fallback to `"sans"` when Arial is unavailable.
#' @return A [ggplot2::theme()] object.
#' @export
#' @family green-journal-themes
#' @seealso [mysterycall_theme_green_journal_map()], [mysterycall_theme_green_journal_faceted()],
#'   [mysterycall_save_green_journal_figure()]
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   mysterycall:::mysterycall_theme_green_journal()
mysterycall_theme_green_journal <- function(base_size = 10, base_family = "Arial") {
  if (!base_family %in% c("sans", "serif", "mono")) {
    avail <- tryCatch(base_family %in% names(grDevices::pdfFonts()),
                     error = function(e) FALSE)
    if (!avail) base_family <- "sans"
  }

  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold", size = ggplot2::rel(1.2),
                                            hjust = 0, margin = ggplot2::margin(b = 8)),
      plot.subtitle = ggplot2::element_text(size = ggplot2::rel(0.95), color = "gray30",
                                            hjust = 0, margin = ggplot2::margin(b = 8)),
      plot.caption  = ggplot2::element_text(size = ggplot2::rel(0.8), color = "gray50",
                                            hjust = 0),
      axis.line        = ggplot2::element_line(color = "black", linewidth = 0.4),
      axis.ticks       = ggplot2::element_line(color = "black", linewidth = 0.3),
      axis.ticks.length = ggplot2::unit(0.15, "cm"),
      axis.title   = ggplot2::element_text(face = "bold", size = ggplot2::rel(1.0)),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 6)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 6)),
      axis.text    = ggplot2::element_text(color = "black", size = ggplot2::rel(0.9)),
      panel.grid.major  = ggplot2::element_line(color = "gray92", linewidth = 0.2),
      panel.grid.minor  = ggplot2::element_blank(),
      panel.background  = ggplot2::element_rect(fill = "white", color = NA),
      panel.border      = ggplot2::element_blank(),
      plot.background   = ggplot2::element_rect(fill = "white", color = NA),
      legend.position   = "bottom",
      legend.direction  = "horizontal",
      legend.title      = ggplot2::element_text(face = "bold", size = ggplot2::rel(0.9)),
      legend.text       = ggplot2::element_text(size = ggplot2::rel(0.85)),
      legend.background = ggplot2::element_rect(fill = "white", color = NA),
      legend.key        = ggplot2::element_rect(fill = "white", color = NA),
      legend.key.size   = ggplot2::unit(0.4, "cm"),
      legend.margin     = ggplot2::margin(t = 4, b = 0),
      strip.background  = ggplot2::element_rect(fill = "gray95", color = "gray80"),
      strip.text        = ggplot2::element_text(face = "bold", size = ggplot2::rel(0.9)),
      plot.margin       = ggplot2::margin(8, 8, 8, 8)
    )
}


#' Green Journal map theme
#'
#' Variant of [mysterycall_theme_green_journal()] for choropleth maps, isochrone
#' coverage maps, and other spatial figures. Removes all axis elements,
#' centers the title, and adds a framed legend. Use with
#' [ggplot2::coord_sf()] and [mysterycall_crs_albers_conus()] for equal-area projection.
#'
#' @param base_size Numeric. Base font size (default 10).
#' @param legend_position Character. Legend position (default `"right"`; use
#'   `"bottom"` for narrow single-column maps).
#' @return A [ggplot2::theme()] object.
#' @export
#' @family green-journal-themes
#' @seealso [mysterycall_crs_albers_conus()], [mysterycall_compose_map_density()]
#' @examplesIf interactive()
#' library(ggplot2)
#' ggplot(counties_sf) +
#'   geom_sf(aes(fill = rate)) +
#'   coord_sf(crs = mysterycall_crs_albers_conus()) +
#'   mysterycall_theme_green_journal_map()
mysterycall_theme_green_journal_map <- function(base_size = 10, legend_position = "right") {
  mysterycall_theme_green_journal(base_size = base_size) +
    ggplot2::theme(
      axis.text    = ggplot2::element_blank(),
      axis.title   = ggplot2::element_blank(),
      axis.line    = ggplot2::element_blank(),
      axis.ticks   = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.border     = ggplot2::element_blank(),
      plot.title    = ggplot2::element_text(face = "bold", hjust = 0.5,
                                            size = ggplot2::rel(1.2)),
      plot.subtitle = ggplot2::element_text(hjust = 0.5, size = ggplot2::rel(0.9),
                                            color = "gray30",
                                            margin = ggplot2::margin(b = 8)),
      legend.position   = legend_position,
      legend.background = ggplot2::element_rect(fill = "white", color = "gray80",
                                                linewidth = 0.3),
      legend.key        = ggplot2::element_rect(fill = "white", color = NA),
      legend.title      = ggplot2::element_text(face = "bold", size = ggplot2::rel(0.9)),
      legend.text       = ggplot2::element_text(size = ggplot2::rel(0.8)),
      plot.margin       = ggplot2::margin(6, 6, 6, 6)
    )
}


#' Green Journal faceted map theme
#'
#' Variant of [mysterycall_theme_green_journal_map()] for small-multiple map panels
#' (e.g., maps by year or drive-time threshold). Uses negative panel spacing
#' to eliminate white gaps between tightly tiled map panels.
#'
#' @param base_size Numeric. Base font size (default 9, smaller for panels).
#' @return A [ggplot2::theme()] object.
#' @seealso [mysterycall_theme_green_journal_map()] for single-panel maps;
#'   [mysterycall_theme_green_journal()] for non-spatial plots.
#' @export
#' @family green-journal-themes
#' @examplesIf interactive()
#' library(ggplot2)
#' ggplot(tracts_sf) +
#'   geom_sf(aes(fill = rate)) +
#'   facet_wrap(~year) +
#'   mysterycall_theme_green_journal_faceted()
mysterycall_theme_green_journal_faceted <- function(base_size = 9) {
  mysterycall_theme_green_journal_map(base_size = base_size, legend_position = "bottom") +
    ggplot2::theme(
      strip.text        = ggplot2::element_text(face = "bold", size = ggplot2::rel(0.9)),
      strip.background  = ggplot2::element_rect(fill = "gray95", color = "gray80"),
      panel.spacing.x   = ggplot2::unit(-2, "lines"),
      panel.spacing.y   = ggplot2::unit(-0.5, "lines"),
      plot.margin       = ggplot2::margin(4, 4, 4, 4)
    )
}


# =============================================================================
# PALETTE AND SCALES
# =============================================================================

#' Colorblind-safe publication palette (Okabe-Ito)
#'
#' Returns the Okabe-Ito / Wong palette safe for deuteranopia, protanopia,
#' and tritanopia, and distinguishable in grayscale. Required by Green Journal
#' author guidelines.
#'
#' @param n Integer. Number of colors (max 8 for qualitative). `NULL` returns
#'   all 8. Warns if `n > 8` and recycles.
#' @param type Character. One of `"qualitative"` (default, Okabe-Ito),
#'   `"sequential"` (blue ramp), or `"diverging"` (blue-orange).
#' @return Character vector of hex color codes.
#' @export
#' @family green-journal-colors
#' @seealso [mysterycall_scale_color_green_journal()], [mysterycall_scale_fill_green_journal()]
#' @references
#'   Wong B (2011). Color blindness. \emph{Nature Methods}, 8(6), 441.
#'   \doi{10.1038/nmeth.1618}
#' @examples
#' mysterycall:::mysterycall_palette_green_journal(5)
#' mysterycall:::mysterycall_palette_green_journal(10, type = "sequential")
mysterycall_palette_green_journal <- function(n = NULL, type = c("qualitative", "sequential", "diverging")) {
  type <- match.arg(type)

  if (type == "sequential") {
    n_seq <- if (is.null(n)) 7L else as.integer(n)
    return(grDevices::colorRampPalette(c("#DEEBF7", "#08519C"))(n_seq))
  }

  if (type == "diverging") {
    n_div <- if (is.null(n)) 9L else as.integer(n)
    return(grDevices::colorRampPalette(
      c("#CA0020", "#F4A582", "#F7F7F7", "#92C5DE", "#0571B0"))(n_div))
  }

  # qualitative -- Okabe-Ito / Wong (2011)
  pal <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
           "#0072B2", "#D55E00", "#CC79A7", "#999999")

  if (is.null(n)) return(pal)
  n <- as.integer(n)
  if (n > length(pal)) {
    warning(sprintf("Requested %d colors; Okabe-Ito has %d. Recycling.", n, length(pal)))
  }
  pal[seq_len(min(n, length(pal)))]
}


#' Green Journal discrete color scale
#'
#' Convenience wrapper for [ggplot2::scale_color_manual()] using the
#' Okabe-Ito palette from [mysterycall_palette_green_journal()]. Handles up to 8 groups.
#'
#' @param ... Arguments passed to [ggplot2::scale_color_manual()].
#' @return A ggplot2 [ggplot2::Scale] object.
#' @seealso [mysterycall_scale_fill_green_journal()] for fill aesthetics;
#'   [mysterycall_palette_green_journal()] for the underlying color values.
#' @export
#' @family green-journal-colors
#' @examples
#' library(ggplot2)
#' ggplot(iris, aes(Sepal.Length, Sepal.Width, color = Species)) +
#'   geom_point() +
#'   mysterycall:::mysterycall_scale_color_green_journal()
mysterycall_scale_color_green_journal <- function(...) {
  ggplot2::scale_color_manual(values = mysterycall_palette_green_journal(), ...)
}


#' Green Journal discrete fill scale
#'
#' Convenience wrapper for [ggplot2::scale_fill_manual()] using the
#' Okabe-Ito palette from [mysterycall_palette_green_journal()].
#'
#' @param ... Arguments passed to [ggplot2::scale_fill_manual()].
#' @return A ggplot2 [ggplot2::Scale] object.
#' @seealso [mysterycall_scale_color_green_journal()] for color aesthetics;
#'   [mysterycall_palette_green_journal()] for the underlying color values.
#' @export
#' @family green-journal-colors
#' @examples
#' library(ggplot2)
#' ggplot(mpg, aes(class, fill = drv)) +
#'   geom_bar() +
#'   mysterycall:::mysterycall_scale_fill_green_journal()
mysterycall_scale_fill_green_journal <- function(...) {
  ggplot2::scale_fill_manual(values = mysterycall_palette_green_journal(), ...)
}


# =============================================================================
# FIGURE SAVE HELPER
# =============================================================================

#' Save a figure in Green Journal submission format
#'
#' Exports a ggplot in all formats needed for journal submission:
#' \itemize{
#'   \item **TIFF** (300 DPI, LZW compression) -- primary submission format
#'   \item **PDF** (cairo, font-embedded) -- vector companion for review
#'   \item **PNG** (300 DPI) -- web / presentation companion
#'   \item **CSV** -- underlying data for peer-review transparency
#' }
#'
#' Geometry columns (`sfc`) are automatically dropped from the CSV export.
#' Output directories are created recursively as needed.
#'
#' @param plot A `ggplot` object.
#' @param path_stem Character. Path without extension
#'   (e.g., `"figures/figure1"`). Extensions are added automatically.
#' @param layout Character. `"single_column"` (3.5 in) or
#'   `"double_column"` (7.0 in). Controls width per Green Journal specs.
#' @param height Numeric. Height in inches. Default: `width * 0.7`, capped
#'   at 9.0 in (Green Journal maximum).
#' @param plot_data Optional data frame for CSV export. `NULL` extracts
#'   `plot$data`.
#' @param csv Logical. Export CSV (default `TRUE`).
#' @return Invisible character vector of file paths written (PNG, PDF, and/or
#'   CSV depending on arguments).
#' @seealso [mysterycall_theme_green_journal()], [mysterycall_theme_green_journal_map()] for themes
#'   to apply before saving; [mysterycall_palette_green_journal()] for the color palette.
#' @export
#' @family green-journal-output
#' @examplesIf interactive()
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + mysterycall_theme_green_journal()
#' mysterycall_save_green_journal_figure(p, "figures/fig1", layout = "double_column")
#' # Creates: figures/fig1.tiff  figures/fig1.pdf  figures/fig1.png
#' #          figures/fig1_data.csv
mysterycall_save_green_journal_figure <- function(plot,
                                      path_stem,
                                      layout    = c("double_column", "single_column"),
                                      height    = NULL,
                                      plot_data = NULL,
                                      csv       = TRUE) {
  stopifnot(inherits(plot, "ggplot"))
  stopifnot(is.character(path_stem), nzchar(path_stem))
  layout <- match.arg(layout)

  fig_width  <- if (layout == "single_column") .GJ$single_width else .GJ$double_width
  fig_height <- if (!is.null(height)) {
    min(height, .GJ$max_height)
  } else {
    min(fig_width * 0.7, .GJ$max_height)
  }
  dpi <- .GJ$dpi

  dir.create(dirname(path_stem), recursive = TRUE, showWarnings = FALSE)
  paths_written <- character(0L)

  # 1. TIFF (primary)
  tiff_path <- paste0(path_stem, ".tiff")
  ggplot2::ggsave(tiff_path, plot = plot, width = fig_width, height = fig_height,
                  dpi = dpi, device = "tiff", compression = "lzw")
  if (file.exists(tiff_path) && file.info(tiff_path)$size > 100L) {
    paths_written <- c(paths_written, tiff_path)
    message(sprintf("[Green Journal] TIFF: %s (%.1f MB, %d x %d px @ %d DPI)",
                    basename(tiff_path), file.info(tiff_path)$size / 1e6,
                    round(fig_width * dpi), round(fig_height * dpi), dpi))
  }

  # 2. PDF (vector companion)
  pdf_path <- paste0(path_stem, ".pdf")
  tryCatch({
    ggplot2::ggsave(pdf_path, plot = plot, width = fig_width, height = fig_height,
                   device = grDevices::cairo_pdf)
    if (file.exists(pdf_path) && file.info(pdf_path)$size > 100L) {
      paths_written <- c(paths_written, pdf_path)
      message(sprintf("[Green Journal] PDF:  %s (%.1f KB)",
                      basename(pdf_path), file.info(pdf_path)$size / 1024))
    }
  }, error = function(e) warning(sprintf("[Green Journal] PDF failed: %s", e$message)))

  # 3. PNG (web companion)
  png_path <- paste0(path_stem, ".png")
  ggplot2::ggsave(png_path, plot = plot, width = fig_width, height = fig_height, dpi = dpi)
  if (file.exists(png_path) && file.info(png_path)$size > 100L) {
    paths_written <- c(paths_written, png_path)
    message(sprintf("[Green Journal] PNG:  %s (%.1f KB)",
                    basename(png_path), file.info(png_path)$size / 1024))
  }

  # 4. CSV (peer-review transparency)
  if (csv) {
    if (is.null(plot_data)) plot_data <- tryCatch(plot$data, error = function(e) NULL)
    if (!is.null(plot_data) && is.data.frame(plot_data) && nrow(plot_data) > 0L) {
      sfc_cols  <- vapply(plot_data, inherits, logical(1L), "sfc")
      plot_data <- plot_data[, !sfc_cols, drop = FALSE]
      csv_path  <- paste0(path_stem, "_data.csv")
      utils::write.csv(plot_data, csv_path, row.names = FALSE)
      paths_written <- c(paths_written, csv_path)
      message(sprintf("[Green Journal] CSV:  %s (%d rows x %d cols)",
                      basename(csv_path), nrow(plot_data), ncol(plot_data)))
    }
  }

  invisible(paths_written)
}


# =============================================================================
# SPATIAL HELPERS
# =============================================================================

#' Albers Equal-Area CRS for the continental United States
#'
#' Returns EPSG:5070 (NAD83 / Conus Albers), the standard equal-area
#' projection used by USGS and the US Census Bureau. Use with
#' `coord_sf(crs = mysterycall_crs_albers_conus())` to avoid the area distortion of the
#' default plate carree projection on national choropleths.
#'
#' @return An `sf::st_crs` object (EPSG:5070).
#' @export
#' @family green-journal-spatial
#' @seealso [mysterycall_theme_green_journal_map()]
#' @examplesIf interactive()
#' library(ggplot2)
#' ggplot(counties_sf) +
#'   geom_sf(aes(fill = rate)) +
#'   coord_sf(crs = mysterycall_crs_albers_conus()) +
#'   mysterycall_theme_green_journal_map()
mysterycall_crs_albers_conus <- function() {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required for crs_albers_conus()",
         call. = FALSE)
  }
  sf::st_crs(5070)
}

#' Deprecated version of mysterycall_crs_albers_conus
#' @param ... Arguments passed to mysterycall_crs_albers_conus
#' @return See mysterycall_crs_albers_conus
#' @keywords internal
#' @name crs_albers_conus
crs_albers_conus <- function(...) { .Deprecated("mysterycall_crs_albers_conus"); mysterycall_crs_albers_conus(...) }


#' Winsorize extreme values
#'
#' Clips values to specified quantile bounds. Useful for access-score maps
#' where a handful of rural tracts with extreme values (0% or 100% coverage)
#' dominate the color scale and obscure variation in the interior of the
#' distribution.
#'
#' @param x Numeric vector to winsorize.
#' @param lower Numeric. Lower quantile bound (default 0.005 = 0.5th
#'   percentile).
#' @param upper Numeric. Upper quantile bound (default 0.995 = 99.5th
#'   percentile).
#' @param na.rm Logical. Remove NAs before computing quantiles (default `TRUE`).
#' @return Numeric vector, same length as `x`.
#' @export
#' @family green-journal-spatial
#' @seealso [mysterycall_truncate_for_viz()]
#' @examples
#' x <- c(0, 5, 10, 50, 90, 95, 100)
#' mysterycall:::mysterycall_winsorize(x, lower = 0.1, upper = 0.9)
mysterycall_winsorize <- function(x, lower = 0.005, upper = 0.995, na.rm = TRUE) {
  stopifnot(is.numeric(x), lower >= 0, upper <= 1, lower < upper)
  bounds      <- stats::quantile(x, probs = c(lower, upper), na.rm = na.rm)
  x[x < bounds[1L]] <- bounds[1L]
  x[x > bounds[2L]] <- bounds[2L]
  x
}

#' Deprecated version of mysterycall_winsorize
#' @param ... Arguments passed to mysterycall_winsorize
#' @return See mysterycall_winsorize
#' @keywords internal
#' @name winsorize
winsorize <- function(...) { .Deprecated("mysterycall_winsorize"); mysterycall_winsorize(...) }


#' Truncate values to fixed bounds
#'
#' Hard floor/ceiling clipping for visualization. Unlike [mysterycall_winsorize()], which
#' uses data-driven quantiles, this forces exact bounds for clean legend breaks
#' (e.g., 0-100% for coverage maps). Use when the legend must show round
#' numbers regardless of the data range.
#'
#' @param x Numeric vector.
#' @param floor Numeric. Minimum value (default 0).
#' @param ceiling Numeric. Maximum value (default 100).
#' @return Numeric vector clipped to `[floor, ceiling]`.
#' @export
#' @family green-journal-spatial
#' @seealso [mysterycall_winsorize()]
#' @examples
#' mysterycall:::mysterycall_truncate_for_viz(c(-5, 0, 50, 105), floor = 0, ceiling = 100)
mysterycall_truncate_for_viz <- function(x, floor = 0, ceiling = 100) {
  pmin(pmax(x, floor, na.rm = TRUE), ceiling, na.rm = TRUE)
}

#' Deprecated version of mysterycall_truncate_for_viz
#' @param ... Arguments passed to mysterycall_truncate_for_viz
#' @return See mysterycall_truncate_for_viz
#' @keywords internal
#' @name truncate_for_viz
truncate_for_viz <- function(...) { .Deprecated("mysterycall_truncate_for_viz"); mysterycall_truncate_for_viz(...) }


#' Composite map + density figure
#'
#' Arranges a choropleth map above a marginal density/histogram plot in a
#' 7:2 height ratio. Returns a grob suitable for [ggplot2::ggsave()] or
#' [mysterycall_save_green_journal_figure()].
#'
#' @param map_plot A `ggplot` object. The choropleth / spatial map (upper panel).
#' @param density_plot A `ggplot` object. The density or histogram (lower panel).
#' @param map_weight Integer. Relative height for the map panel (default 7).
#' @param density_weight Integer. Relative height for the density panel
#'   (default 2).
#' @return A `gridExtra` grob (gtable). Pass to `ggsave(plot = result)` or
#'   [mysterycall_save_green_journal_figure()].
#' @export
#' @family green-journal-spatial
#' @seealso [mysterycall_save_green_journal_figure()], [mysterycall_theme_green_journal_map()]
#' @examplesIf interactive()
#' library(ggplot2)
#' p_map <- ggplot(tracts) + geom_sf(aes(fill = access)) +
#'   mysterycall_theme_green_journal_map()
#' p_den <- ggplot(tracts, aes(access)) +
#'   geom_density(fill = "#56B4E9", alpha = 0.6) +
#'   mysterycall_theme_green_journal()
#' composite <- mysterycall_compose_map_density(p_map, p_den)
#' mysterycall_save_green_journal_figure(composite, "figures/fig3")
mysterycall_compose_map_density <- function(map_plot, density_plot,
                                map_weight = 7L, density_weight = 2L) {
  stopifnot(inherits(map_plot, "ggplot"), inherits(density_plot, "ggplot"))
  if (!requireNamespace("gridExtra", quietly = TRUE)) {
    stop("Package 'gridExtra' is required for compose_map_density(). ",
         "", call. = FALSE)
  }
  layout <- matrix(c(rep(1L, map_weight), rep(2L, density_weight)), ncol = 1L)
  gridExtra::arrangeGrob(map_plot, density_plot, layout_matrix = layout)
}

#' Deprecated version of mysterycall_compose_map_density
#' @param ... Arguments passed to mysterycall_compose_map_density
#' @return See mysterycall_compose_map_density
#' @keywords internal
#' @name compose_map_density
compose_map_density <- function(...) { .Deprecated("mysterycall_compose_map_density"); mysterycall_compose_map_density(...) }


# =============================================================================
# BACKWARD-COMPATIBILITY ALIASES
# =============================================================================

#' @rdname mysterycall_theme_green_journal
#' @keywords internal
mysterycall_theme_publication <- mysterycall_theme_green_journal

#' @rdname mysterycall_theme_green_journal_map
#' @keywords internal
mysterycall_theme_publication_map <- mysterycall_theme_green_journal_map

#' @rdname mysterycall_theme_green_journal_faceted
#' @keywords internal
mysterycall_theme_publication_faceted <- mysterycall_theme_green_journal_faceted

#' @rdname mysterycall_palette_green_journal
#' @keywords internal
mysterycall_palette_publication <- mysterycall_palette_green_journal

#' @rdname mysterycall_save_green_journal_figure
#' @keywords internal
mysterycall_save_publication_figure <- mysterycall_save_green_journal_figure
