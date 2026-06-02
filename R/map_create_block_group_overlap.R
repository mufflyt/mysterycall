#' Function to create and export a map showing block group overlap with isochrones
#'
#' This function creates a map that displays block groups and their overlap with isochrones.
#' The map is exported as an HTML file and a PNG image.
#' @param bg_data A SpatialPolygonsDataFrame representing block group data.
#' @param isochrones_data A SpatialPolygonsDataFrame representing isochrone data.
#' @param output_dir Directory path for exporting the map files. Default is "figures/".
#'
#' @return `invisible(NULL)`. Side effects: writes the block group overlap map
#'   as an HTML file and a PNG image to `output_dir`.
#'
#' @examplesIf interactive()
#' # Create and export the map with the default output directory
#' mysterycall_map_block_group(block_groups, isochrones_joined_map)
#'
#' # Create and export the map with a custom output directory
#' mysterycall_map_block_group(block_groups, isochrones_joined_map, "custom_output/")
#' @family mapping
#' @export
mysterycall_map_block_group <- function(bg_data, isochrones_data, output_dir = "figures/") {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required", call. = FALSE)
  }

  if (!requireNamespace("leaflet", quietly = TRUE)) {
    stop("Package 'leaflet' is required for mysterycall_map_block_group()", call. = FALSE)
  }
  if (!requireNamespace("lwgeom", quietly = TRUE)) {
    stop("Package 'lwgeom' is required for mysterycall_map_block_group()", call. = FALSE)
  }
  if (!requireNamespace("webshot", quietly = TRUE)) {
    stop("Package 'webshot' is required for mysterycall_map_block_group()", call. = FALSE)
  }
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    stop("Package 'htmlwidgets' is required for this function", call. = FALSE)
  }
  checkmate::assert_string(output_dir, min.chars = 1, .var.name = "output_dir")
  if (!inherits(bg_data, "sf")) {
    stop("`bg_data` must be an sf object with polygon geometries.", call. = FALSE)
  }
  if (!inherits(isochrones_data, "sf")) {
    stop("`isochrones_data` must be an sf object with polygon geometries.", call. = FALSE)
  }
  if (!"drive_time" %in% names(isochrones_data)) {
    stop("`isochrones_data` must include a `drive_time` column in minutes.", call. = FALSE)
  }
  if (!is.numeric(isochrones_data$drive_time)) {
    stop("`isochrones_data$drive_time` must be a numeric column.", call. = FALSE)
  }
  if (!"overlap" %in% names(bg_data)) {
    stop("`bg_data` must include an `overlap` column (proportion 0-1). Run mysterycall_calculate_overlap() first.", call. = FALSE)
  }
  if (any(!is.na(bg_data$overlap) & (bg_data$overlap < 0 | bg_data$overlap > 1))) {
    stop("`bg_data$overlap` values must be between 0 and 1.", call. = FALSE)
  }

  validated <- validate_sf_inputs(
    bg_data = bg_data,
    isochrones_data = isochrones_data,
    expected_types = list(
      bg_data = c("POLYGON", "MULTIPOLYGON"),
      isochrones_data = c("POLYGON", "MULTIPOLYGON")
    ),
    target_crs = 4326,
    context = "mysterycall_map_block_group()"
  )
  bg_data <- validated$bg_data
  isochrones_data <- validated$isochrones_data

  bg_data <- lwgeom::st_force_polygon_cw(bg_data)
  isochrones_data <- lwgeom::st_force_polygon_cw(isochrones_data)

  palette <- c(
    "180" = "#ff0000",
    "120" = "#ffd700",
    "60" = "#228b22",
    "30" = "#1f77b4"
  )

  draw_order <- c(180, 120, 60, 30)

  isochrones_ordered <- isochrones_data
  isochrones_ordered[["drive_time"]] <- as.numeric(isochrones_ordered[["drive_time"]])
  isochrones_ordered <- isochrones_ordered[order(match(isochrones_ordered[["drive_time"]], draw_order)), , drop = FALSE]

  pal <- leaflet::colorNumeric("Purples", domain = bg_data$overlap)

  # Create the base map
  base_map <- mysterycall_map_base("<h1>Block Group Overlap Map</h1>")

  # Create the map
  map <- base_map %>%
    leaflet::addPolygons(
      data = bg_data,
      fillColor = ~pal(bg_data$overlap),
      fillOpacity = 1,
      weight = 0.5,
      smoothFactor = 0.2,
      stroke = TRUE,
      color = "black",
      popup = ~paste("Block Group GEOID name and number:", "\n", bg_data$NAMELSAD, "\n", bg_data$GEOID)
    ) %>%
    leaflet::addLegend(
      pal = pal,
      values = bg_data$overlap,
      position = "bottomright",
      title = "Intersection with isochrones",
      opacity = 1
    )

  invisible(lapply(draw_order, function(dt) {
    subset <- isochrones_ordered[isochrones_ordered$drive_time == dt, , drop = FALSE]
    if (!nrow(subset)) {
      return(NULL)
    }

    union_geom <- sf::st_union(subset)
    union_sf <- sf::st_sf(drive_time = dt, geometry = union_geom, crs = 4326)
    union_sf <- lwgeom::st_force_polygon_cw(union_sf)

    map <<- map %>%
      leaflet::addPolygons(
        data = union_sf,
        fill = TRUE,
        stroke = TRUE,
        fillColor = palette[as.character(dt)],
        fillOpacity = 0.35,
        color = palette[as.character(dt)],
        weight = 1.5,
        group = paste0(dt, " minutes")
      )
  }))

  # Generate a timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

  # Define file names with timestamps
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  html_file <- file.path(output_dir, paste0("overlap_bg_map_", timestamp, ".html"))
  png_file <- file.path(output_dir, paste0("overlap_bg_map_", timestamp, ".png"))

  # Export the map to HTML
  htmlwidgets::saveWidget(widget = map, file = html_file, selfcontained = FALSE)
  message("Map saved as HTML: ", html_file)

  # Export the map as a PNG image
  webshot::webshot(html_file, file = png_file)
  message("Map saved as PNG: ", png_file)
}
