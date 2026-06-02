#' Create Individual Isochrone Maps and Shapefiles
#'
#' This function creates individual Leaflet maps and shapefiles for specified drive times
#' based on isochrone data.
#'
#' @param isochrones An sf object containing isochrone data.
#' @param drive_times A vector of unique drive times (in minutes) for which maps and shapefiles will be created.
#' @param output_dir Directory where HTML maps and shapefiles are saved.
#'   Defaults to a session-specific folder inside [tempdir()].
#' @return Called for its side effect of writing per-drive-time map HTML files and shapefiles to disk. Returns `NULL` invisibly.
#' @importFrom dplyr filter tibble
#' @importFrom grDevices rainbow
#' @examplesIf interactive()
#' # Load required libraries
#' library(sf)
#' library(leaflet)
#' library(mysterycall)
#'
#' # Load isochrone data
#' isochrones <- readRDS("path_to_isochrones.rds")
#'
#' # List of unique drive times for which you want to create plots and shapefiles
#' drive_times <- unique(isochrones$drive_time)
#'
#' # Create individual isochrone maps and shapefiles
#' mysterycall_plot_isochrones(isochrones, drive_times)
#'
#' @family mapping
#' @export
mysterycall_plot_isochrones <- function(isochrones, drive_times, output_dir = NULL) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required", call. = FALSE)
  }

  if (!requireNamespace("leaflet", quietly = TRUE)) {
    stop("Package 'leaflet' is required for mysterycall_plot_isochrones()", call. = FALSE)
  }
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    stop("Package 'htmlwidgets' is required for this function", call. = FALSE)
  }

  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("isochrone_plots", create = TRUE)
  } else {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  map_dir  <- file.path(output_dir, "isochrone_maps")
  shp_dir  <- file.path(output_dir, "shp")
  dir.create(map_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(shp_dir, recursive = TRUE, showWarnings = FALSE)

  message("Usage: load data with readRDS(), get drive times via unique(isochrones$drive_time), then call mysterycall_plot_isochrones(isochrones, drive_times).")

  message("Creating individual isochrone plots and shapefiles...")

  for (time in drive_times) {
    if (is.na(time)) {
      message("Skipping NA drive time.")
      next
    }
    message(paste("Processing isochrones for", time, "minutes..."))

    # Filter isochrones for the specified drive time
    isochrones_filtered <- dplyr::filter(isochrones, drive_time == time)

    # Combine isochrones using st_union
    isochrones_combined <- sf::st_union(isochrones_filtered)

    # Create an sf object with the combined isochrones
    isochrones_sf <- dplyr::tibble(iso_id = 1, geometry = isochrones_combined) %>%
      sf::st_sf()

    # Transform the sf object to an appropriate coordinate system (e.g., EPSG:4326)
    isochrones_sf <- sf::st_transform(isochrones_sf, crs = 4326)

    # Define unique colors for each drive time
    colors <- grDevices::rainbow(length(drive_times))

    # Get the index of the current drive time
    index <- match(time, drive_times)

    # Create a base map
    my_map <- mysterycall_map_base("")

    message(paste("Creating a Leaflet map of isochrones for", time, "minutes..."))

    # Create the Leaflet plot
    isochrone_map <- my_map %>%
      leaflet::addPolygons(
        data = isochrones_sf,
        fillColor = colors[index],
        fillOpacity = 1,
        weight = 0.5,
        smoothFactor = 0.2,
        stroke = TRUE,
        color = "black"
      )

    # Save the plot to an HTML file
    output_file <- file.path(map_dir, paste0("isochrone_map_", time, "_minutes.html"))
    htmlwidgets::saveWidget(isochrone_map, file = output_file)

    message(paste("Saved isochrone map for", time, "minutes as:", output_file))

    # Write the shapefile for the current drive time
    output_shapefile <- file.path(shp_dir, paste0("isochrones_", time, "_minutes.shp"))
    sf::st_write(isochrones_sf, output_shapefile, append = FALSE)

    message(paste("Saved shapefile for", time, "minutes as:", output_shapefile))

  message(paste("Processed isochrones for", time, "minutes."))
  }

  message("Individual isochrone plots and shapefiles creation completed.")
  if (isTRUE(interactive()) && requireNamespace("beepr", quietly = TRUE)) beepr::beep(2)
}
