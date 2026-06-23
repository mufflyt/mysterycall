#' Choropleth map of appointment acceptance rates by US state
#'
#' @name mysterycall_map_acceptance_rate
NULL

#' Build State Abbreviation to Name Lookup
#'
#' @return Named character vector where names are 2-letter abbreviations and
#'   values are full state names.
#' @keywords internal
.abb_to_name <- function() {
  stats::setNames(datasets::state.name, datasets::state.abb)
}

#' Map appointment acceptance rates by US state (or HRR)
#'
#' Draws a choropleth map of appointment acceptance rates using base-R map
#' data (no external spatial packages required for state-level maps).
#'
#' @param data A data frame with at least two columns: `region_col` and
#'   `rate_col`.
#' @param region_col Character scalar. Name of the column that identifies
#'   regions. For `region_type = "state"` this can be full state names
#'   (e.g. `"Colorado"`) or standard two-letter abbreviations (e.g. `"CO"`).
#' @param rate_col Character scalar. Name of a numeric column with acceptance
#'   rates between 0 and 1. Values are multiplied by 100 for display.
#' @param region_type Character scalar. Either `"state"` (default) or `"hrr"`.
#'   `"hrr"` immediately raises an error with instructions to use the sf-based
#'   workflow.
#' @param palette Character scalar. Viridis color-scale option passed to
#'   [ggplot2::scale_fill_viridis_c()]. Default `"viridis"`.
#' @param title Character scalar. Plot title. Default
#'   `"Appointment Acceptance Rate (%)"`.
#' @param legend_title Character scalar. Legend title. Default
#'   `"Acceptance\\nRate (%)"`.
#' @param limits Numeric vector of length 2 or `NULL`. Explicit limits for
#'   the fill scale. `NULL` (default) lets ggplot2 choose.
#' @param na_color Character scalar. Fill color for states with no data.
#'   Default `"grey80"`.
#' @param save_path Character scalar or `NULL`. When not `NULL`, the plot is
#'   written to this path via [mysterycall_save_plot()].
#' @param width Numeric. Width in inches passed to [mysterycall_save_plot()].
#'   Default `10`.
#' @param height Numeric. Height in inches passed to [mysterycall_save_plot()].
#'   Default `7`.
#' @param dpi Integer. Resolution passed to [mysterycall_save_plot()].
#'   Default `300L`.
#'
#' @return A `ggplot` object of class `c("gg", "ggplot")`, returned invisibly.
#'   When `save_path` is not `NULL`, also writes the plot to disk via
#'   [mysterycall_save_plot()].
#'
#' @seealso [mysterycall_save_plot()] to write the result to disk;
#'   [mysterycall_hrr_maps()] for HRR-level choropleth maps.
#' @family mapping
#' @export
#'
#' @examplesIf requireNamespace("maps", quietly = TRUE)
#' set.seed(7)
#' df <- data.frame(
#'   state = c("Colorado", "California", "Texas", "New York", "Florida"),
#'   rate  = c(0.55, 0.72, 0.48, 0.63, 0.81)
#' )
#' mysterycall_map_acceptance_rate(df, region_col = "state", rate_col = "rate")
mysterycall_map_acceptance_rate <- function(data,
                                             region_col,
                                             rate_col,
                                             region_type  = c("state", "hrr"),
                                             palette      = "viridis",
                                             title        = "Appointment Acceptance Rate (%)",
                                             legend_title = "Acceptance\nRate (%)",
                                             limits       = NULL,
                                             na_color     = "grey80",
                                             save_path    = NULL,
                                             width        = 10,
                                             height       = 7,
                                             dpi          = 300L) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for mysterycall_map_acceptance_rate(). Install with: install.packages('ggplot2')", call. = FALSE)
  }
  region_type <- match.arg(region_type)

  if (!requireNamespace("maps", quietly = TRUE)) {
    stop("Package 'maps' is required for state choropleth maps.", call. = FALSE)
  }

  # ---- HRR guard -------------------------------------------------------------
  if (region_type == "hrr") {
    stop(
      "HRR maps require an sf object; use map_create_base() and join manually.",
      call. = FALSE
    )
  }

  # ---- Validate data ---------------------------------------------------------
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  if (!region_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", region_col), call. = FALSE)
  }
  if (!rate_col %in% names(data)) {
    stop(sprintf("Column '%s' not found in `data`.", rate_col), call. = FALSE)
  }

  # ---- Prepare working copy --------------------------------------------------
  work        <- data[, c(region_col, rate_col), drop = FALSE]
  names(work) <- c("region_raw", "rate_raw")

  # ---- Convert abbreviations to full names if needed -------------------------
  sample_region <- work$region_raw[!is.na(work$region_raw)][1L]
  if (is.character(sample_region) && nchar(sample_region) <= 2L) {
    lookup          <- .abb_to_name()
    work$region_raw <- lookup[work$region_raw]
  }

  # Lowercase for joining with map_data
  work$region_join <- tolower(as.character(work$region_raw))
  work$rate_pct    <- work$rate_raw * 100

  # ---- Fetch state map data --------------------------------------------------
  map_df <- ggplot2::map_data("state")

  # ---- Join ------------------------------------------------------------------
  merged <- merge(map_df, work,
                  by.x  = "region",
                  by.y  = "region_join",
                  all.x = TRUE)
  # Restore draw order after merge
  merged <- merged[order(merged$group, merged$order), ]

  # ---- Build plot ------------------------------------------------------------
  p <- ggplot2::ggplot(merged,
         ggplot2::aes(x = long, y = lat, group = group, fill = rate_pct)) +
    ggplot2::geom_polygon(color = "white", linewidth = 0.2) +
    ggplot2::coord_map("albers", lat0 = 39, lat1 = 45) +
    ggplot2::scale_fill_viridis_c(
      option   = palette,
      limits   = limits,
      na.value = na_color,
      name     = legend_title
    ) +
    ggplot2::theme_void() +
    ggplot2::labs(title = title)

  # ---- Optional save ---------------------------------------------------------
  if (!is.null(save_path)) {
    mysterycall_save_plot(p, save_path, width = width, height = height, dpi = dpi)
  }

  invisible(p)
}
