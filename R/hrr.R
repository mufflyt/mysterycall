#' Get Hospital Referral Region Shapefile
#'
#' Loads the Dartmouth Atlas Hospital Referral Region (HRR) shapefile,
#' transforming it to EPSG:4326 (WGS84) and optionally dropping Alaska and
#' Hawaii.  The shapefile (~8 MB) is downloaded on first use and cached in the
#' user's R cache directory for subsequent calls.
#'
#' @param remove_HI_AK Logical.  When `TRUE` (default), HRRs whose `hrrcity`
#'   starts with `"AK"` or `"HI"` are dropped from the returned object.
#'
#' @return An `sf` object with one row per HRR and columns:
#'   \describe{
#'     \item{`hrrcity`}{Character. HRR city identifier (e.g. `"CA-Sacramento"`).}
#'     \item{`hrrnum`}{Integer. Numeric HRR code from the Dartmouth Atlas.}
#'     \item{`geometry`}{sfc_MULTIPOLYGON in EPSG:4326 (WGS84).}
#'   }
#'   Additional columns from the raw shapefile may be present.
#' @seealso [ensure_hrr_shapefile()], [mysterycall_hrr_maps()], [mysterycall_map_base()]
#' @family geospatial helpers
#' @importFrom dplyr filter
#' @export
#' @examplesIf interactive()
#' mysterycall_hrr()
mysterycall_hrr <- function(remove_HI_AK = TRUE) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required", call. = FALSE)
  }

  message("Loading necessary packages...")

  # Load the hospital referral region shapefile
  message("Getting the hospital referral region shapefile...")
  hrr_path <- ensure_hrr_shapefile()
  mysterycall_hrr <- sf::read_sf(hrr_path)
  mysterycall_hrr <- sf::st_transform(mysterycall_hrr, 4326)

  # Optionally remove Hawaii and Alaska (all HRRs, not just the largest cities)
  if (remove_HI_AK) {
    mysterycall_hrr <- mysterycall_hrr %>%
      dplyr::filter(!stringr::str_detect(.data$hrrcity, "^(AK|HI)"))
  }

  # Provide information about the function's purpose
  message("Hospital Referral Region shapefile loaded.")
  message("This function creates an sf file of hospital referral regions.")
  message("For more information: https://data.dartmouthatlas.org/supplemental/")

  return(mysterycall_hrr)
}

#' Generate honeycomb hex maps for Hospital Referral Regions
#'
#' Joins physician point data to HRR polygons, computes per-HRR physician
#' counts, and renders a honeycomb choropleth of the contiguous US with
#' Alaska, Hawaii, and Puerto Rico as inset maps.  The figure is saved as
#' both `.tiff` and `.png` to `output_dir`.
#'
#' @param physician_sf An `sf` object with one row per physician.  Must have
#'   a `geometry` column of POINT geometries; CRS is auto-transformed to
#'   EPSG:4326 if needed.
#' @param trait_map Character scalar used as a label in the output filename
#'   (e.g. `"all"`, `"neurotology"`).  No validation; used as-is.
#' @param honey_map Character scalar used as a secondary label in the output
#'   filename (e.g. `"all"`).  No validation; used as-is.
#' @param output_dir Directory where generated figures are written. Defaults to a
#'   session-specific folder inside [tempdir()].
#' @param dpi Integer.  Raster resolution in DPI for the saved figure.  Default `600`.
#' @param width Numeric.  Figure width in inches.  Default `7`.
#' @param height Numeric.  Figure height in inches.  Default `5`.
#'
#' @return Invisibly returns a `grob` object (from
#'   `gridExtra::arrangeGrob`) containing the arranged multi-panel map.
#'   Side effects: writes two files to `output_dir` -
#'   `<trait_map>_<honey_map>_honey.tiff` and
#'   `<trait_map>_<honey_map>_honey.png`.
#' @seealso [mysterycall_hrr()] to obtain the HRR `sf` object;
#'   [mysterycall_map_base()], [mysterycall_map_block_group()]
#' @family mapping
#' @importFrom dplyr mutate group_by summarize filter n
#' @importFrom stringr str_detect
#' @importFrom scales pretty_breaks label_number squish
#' @export
#' @examplesIf interactive()
#' mysterycall_hrr_maps(physician_sf)
mysterycall_hrr_maps <- function(
    physician_sf,
    trait_map = "all",
    honey_map = "all",
    output_dir = NULL,
    dpi = 600,
    width = 7,
    height = 5
) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required", call. = FALSE)
  }
  if (!requireNamespace("scales", quietly = TRUE)) {
    stop("Package 'scales' is required for mysterycall_hrr_maps()", call. = FALSE)
  }

  if (!requireNamespace("ggspatial", quietly = TRUE)) {
    stop("Package 'ggspatial' is required for mysterycall_hrr_maps()", call. = FALSE)
  }
  if (!requireNamespace("rnaturalearth", quietly = TRUE)) {
    stop("Package 'rnaturalearth' is required for mysterycall_hrr_maps()", call. = FALSE)
  }
  if (!requireNamespace("gridExtra", quietly = TRUE)) {
    stop("Package 'gridExtra' is required for this function", call. = FALSE)
  }
  if (!requireNamespace("grid", quietly = TRUE)) {
    stop("Package 'grid' is required for this function", call. = FALSE)
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for mysterycall_hrr_maps(). Install with: install.packages('ggplot2')", call. = FALSE)
  }
  sf::sf_use_s2(FALSE)

  # Load USA shapefile
  message("Loading USA shapefile...")
  usa <- rnaturalearth::ne_countries(country = "United States of America", returnclass = "sf")
  usa <- sf::st_transform(usa, 4326)

  # Generate the HRR map (retain AK, HI, and PR for insets)
  hrr_map <- mysterycall_hrr(remove_HI_AK = FALSE)

  # Intersect honeycomb grid with physician data to get physician counts
  message("Intersecting honeycomb grid with physician data...")
  honeycomb_grid_sf <- sf::st_make_grid(usa, c(0.3, 0.3), what = "polygons", square = FALSE) %>%
    sf::st_sf() %>%
    dplyr::mutate(grid_id = dplyr::row_number()) %>%
    sf::st_intersection(sf::st_transform(usa, 4326))

  intersections <- sf::st_intersection(honeycomb_grid_sf, sf::st_transform(physician_sf, 4326)) %>%
    dplyr::filter(.data$grid_id > 9546L)  # Filter out Palmyra Atoll

  physician_count_per_honey <- intersections %>%
    dplyr::group_by(grid_id) %>%
    dplyr::summarize(physician_count = n(), .groups = 'drop') %>%
    dplyr::filter(.data$physician_count > 1)

  # Join honeycomb grid with physician count
  honeycomb_grid_with_physicians <- sf::st_join(honeycomb_grid_sf, physician_count_per_honey) %>%
    dplyr::filter(!is.na(.data$physician_count))

  fill_limits <- range(honeycomb_grid_with_physicians$physician_count, na.rm = TRUE)
  if (any(is.infinite(fill_limits))) {
    fill_limits <- c(0, 1)
  }

  pretty_breaks <- scales::pretty_breaks(n = 6)(fill_limits)

  # Split data for contiguous US and insets
  message("Preparing contiguous and inset geographies...")
  contiguous_hrr <- hrr_map %>%
    dplyr::filter(!stringr::str_detect(.data$hrrcity, "^(AK|HI|PR)-"))
  alaska_hrr <- hrr_map %>% dplyr::filter(stringr::str_detect(.data$hrrcity, "^AK-"))
  hawaii_hrr <- hrr_map %>% dplyr::filter(stringr::str_detect(.data$hrrcity, "^HI-"))
  puerto_rico_hrr <- hrr_map %>% dplyr::filter(stringr::str_detect(.data$hrrcity, "^PR-"))

  contiguous_honey <- sf::st_filter(honeycomb_grid_with_physicians, contiguous_hrr)
  alaska_honey <- sf::st_filter(honeycomb_grid_with_physicians, alaska_hrr)
  hawaii_honey <- sf::st_filter(honeycomb_grid_with_physicians, hawaii_hrr)
  puerto_rico_honey <- sf::st_filter(honeycomb_grid_with_physicians, puerto_rico_hrr)

  map_theme <- ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.title = ggplot2::element_text(face = "bold", hjust = 0.5),
      axis.title = ggplot2::element_text(face = "bold"),
      legend.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.margin = ggplot2::margin(t = 6)
    )

  build_region_plot <- function(hrr_data, honey_data, region_title, show_legend = FALSE, base_size = 10) {
    if (nrow(hrr_data) == 0) {
      return(
        ggplot2::ggplot() +
          ggplot2::theme_void() +
          ggplot2::annotate("text", x = 0.5, y = 0.5, label = paste("No data for", region_title), size = 3)
      )
    }

    ggplot2::ggplot() +
      ggplot2::geom_sf(data = hrr_data, fill = "#f5f5f5", color = "#4a4a4a", linewidth = 0.2) +
      ggplot2::geom_sf(
        data = honey_data,
        ggplot2::aes(fill = physician_count),
        color = NA,
        alpha = 0.95
      ) +
      ggplot2::scale_fill_viridis_c(
        option = "viridis",
        limits = fill_limits,
        oob = scales::squish,
        breaks = pretty_breaks,
        labels = scales::label_number(accuracy = 1),
        name = "Physician count"
      ) +
      ggplot2::labs(title = region_title) +
      ggplot2::theme_minimal(base_size = base_size) +
      ggplot2::theme(
        axis.title = ggplot2::element_blank(),
        axis.text = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank(),
        panel.grid = ggplot2::element_blank(),
        legend.position = if (show_legend) "bottom" else "none",
        plot.title = ggplot2::element_text(hjust = 0.5, face = "bold")
      )
  }

  message("Creating main map and insets...")
  main_map <- build_region_plot(contiguous_hrr, contiguous_honey, "Hospital Referral Regions", show_legend = TRUE, base_size = 12) +
    ggspatial::annotation_scale(location = "bl", width_hint = 0.25, bar_cols = c("black", "white")) +
    ggspatial::annotation_north_arrow(
      location = "br",
      which_north = "true",
      style = ggspatial::north_arrow_fancy_orienteering()
    ) +
    map_theme

  alaska_inset <- build_region_plot(alaska_hrr, alaska_honey, "Alaska")
  hawaii_inset <- build_region_plot(hawaii_hrr, hawaii_honey, "Hawaii")
  puerto_rico_inset <- build_region_plot(puerto_rico_hrr, puerto_rico_honey, "Puerto Rico")

  combined_insets <- gridExtra::arrangeGrob(alaska_inset, hawaii_inset, puerto_rico_inset, ncol = 3)
  combined_map <- gridExtra::arrangeGrob(main_map, combined_insets, heights = c(3, 1))

  # Print the plot
  grid::grid.newpage()
  grid::grid.draw(combined_map)

  # Ensure output directory exists
  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("hrr_maps", create = TRUE)
  } else if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  output_stub <- file.path(output_dir, paste0(trait_map, "_", honey_map, "_honey"))
  message("Saving the map for Obstetrics & Gynecology submission...")
  ggplot2::ggsave(paste0(output_stub, ".tiff"), plot = combined_map, width = width, height = height, dpi = dpi, units = "in", compression = "lzw")
  ggplot2::ggsave(paste0(output_stub, ".png"), plot = combined_map, width = width, height = height, dpi = dpi, units = "in")

  invisible(combined_map)
}
