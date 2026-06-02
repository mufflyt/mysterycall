#' Create a Configurable Leaflet Base Map
#'
#' Build a Leaflet base map with sensible defaults for the mysterycall mapping
#' helpers. The map includes multiple tile providers, a scale bar, optional
#' title control, and centers on the continental United States by default.
#'
#' @param title Optional HTML string used for a title control in the upper
#'   left corner of the map. Supply `NULL` or an empty string to omit the
#'   control.
#' @param lat,lng Numeric latitude and longitude used to center the initial
#'   view. Defaults position the map over the continental United States.
#' @param zoom Numeric zoom level passed to [leaflet::setView()].
#'
#' @return A [leaflet::leaflet()] map object pre-configured with controls and
#'   basemap layers.
#'
#' @family mapping
#' @export
#' @examplesIf interactive()
#' mysterycall_map_base()
#' mysterycall_map_base("<strong>Custom title</strong>")
mysterycall_map_base <- function(title = NULL, lat = 39.8282, lng = -98.5795, zoom = 4) {
  if (!requireNamespace("leaflet", quietly = TRUE)) {
    stop("Package 'leaflet' is required for mysterycall_map_base()", call. = FALSE)
  }
  map <- leaflet::leaflet(options = leaflet::leafletOptions(zoomControl = TRUE)) %>%
    leaflet::addProviderTiles("CartoDB.Voyager", group = "CartoDB Voyager") %>%
    leaflet::addProviderTiles("Stadia.StamenTonerLite", group = "Toner Lite") %>%
    leaflet::addScaleBar(position = "bottomleft") %>%
    leaflet::addLayersControl(
      baseGroups = c("CartoDB Voyager", "Toner Lite"),
      options = leaflet::layersControlOptions(collapsed = FALSE)
    ) %>%
    leaflet::setView(lat = lat, lng = lng, zoom = zoom) %>%
    leaflet::addTiles(options = leaflet::tileOptions(useCache = TRUE, crossOrigin = TRUE))

  if (!is.null(title) && nzchar(title)) {
    if (!requireNamespace("htmltools", quietly = TRUE)) {
      stop("Package 'htmltools' is required for this function", call. = FALSE)
    }
    map <- leaflet::addControl(
      map,
      html = htmltools::tags$div(
        class = "mysterycall-map-title",
        htmltools::HTML(title)
      ),
      position = "topleft"
    )
  }

  map
}

#' Create and Save a Leaflet Dot Map of Physicians
#'
#' This function creates a Leaflet dot map of physicians using their longitude
#' and latitude coordinates. It also adds ACOG district boundaries to the map
#' and saves it as an HTML file with an accompanying PNG screenshot.
#'
#' @param physician_data An sf object containing physician data with `"long"`
#'   and `"lat"` columns.
#' @param jitter_range The range for adding jitter to latitude and longitude
#'   coordinates.
#' @param color_palette The color palette for ACOG district colors.
#' @param popup_var The variable to use for popup text.
#' @param output_dir Directory where the HTML map and PNG screenshot are saved.
#'   Defaults to a session-specific temporary folder.
#' @return Invisibly returns the Leaflet map object.
#'
#' @importFrom dplyr mutate
#'
#' @examplesIf interactive()
#' # Load required libraries
#' library(viridis)
#' library(leaflet)
#'
#' # Generate physician data (replace with your own data)
#' physician_data <- data.frame(
#'   long = c(-95.363271, -97.743061, -98.493628, -96.900115, -95.369803),
#'   lat = c(29.763283, 30.267153, 29.424349, 32.779167, 29.751808),
#'   name = c("Physician 1", "Physician 2", "Physician 3", "Physician 4", "Physician 5"),
#'   ACOG_District = c("District I", "District II", "District III", "District IV", "District V")
#' )
#'
#' # Create and save the dot map
#' mysterycall_map_physicians(physician_data)
#'
#' @family mapping
#' @export
mysterycall_map_physicians <- function(physician_data, jitter_range = 0.05, color_palette = "magma", popup_var = "name", output_dir = NULL) {
  if (!requireNamespace("leaflet", quietly = TRUE)) {
    stop("Package 'leaflet' is required for mysterycall_map_physicians()", call. = FALSE)
  }
  if (!requireNamespace("webshot", quietly = TRUE)) {
    stop("Package 'webshot' is required for mysterycall_map_physicians()", call. = FALSE)
  }
  if (!requireNamespace("viridis", quietly = TRUE)) {
    stop("Package 'viridis' is required for this function", call. = FALSE)
  }
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) {
    stop("Package 'htmlwidgets' is required for this function", call. = FALSE)
  }
  if (is.null(output_dir)) {
    output_dir <- mysterycall_tempdir("physician_maps", create = TRUE)
  } else {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  jittered_physician_data <- dplyr::mutate(
    physician_data,
    lat = lat + runif(n()) * jitter_range,
    long = long + runif(n()) * jitter_range
  )

  cat("Setting up the base map...\n")
  base_map <- mysterycall_map_base("Physician Dot Map")
  cat("Map setup complete.\n")

  cat("Generating the ACOG district boundaries...\n")
  acog_districts <- mysterycall_map_acog_districts()
  cat("ACOG district boundaries generated.\n")

  num_acog_districts <- dplyr::n_distinct(acog_districts$ACOG_District)
  district_colors <- viridis::viridis(num_acog_districts, option = color_palette)

  jittered_physician_data <- dplyr::mutate(
    jittered_physician_data,
    ACOG_District = factor(
      ACOG_District,
      levels = sort(unique(acog_districts$ACOG_District))
    )
  )

  dot_map <- leaflet::addCircleMarkers(
    base_map,
    data = jittered_physician_data,
    lng = ~long,
    lat = ~lat,
    radius = 3,
    stroke = TRUE,
    weight = 1,
    color = district_colors[as.numeric(jittered_physician_data$ACOG_District)],
    fillOpacity = 0.8,
    popup = as.formula(paste0("~", popup_var))
  ) %>%
    leaflet::addPolygons(
      data = acog_districts,
      color = "red",
      weight = 2,
      fill = FALSE,
      opacity = 0.8,
      popup = ~ACOG_District
    ) %>%
    leaflet::addLegend(
      position = "bottomright",
      colors = district_colors,
      labels = levels(jittered_physician_data$ACOG_District),
      title = "ACOG Districts"
    )

  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  html_file <- file.path(output_dir, paste0("dot_map_", timestamp, ".html"))
  png_file <- file.path(output_dir, paste0("dot_map_", timestamp, ".png"))

  htmlwidgets::saveWidget(widget = dot_map, file = html_file, selfcontained = TRUE)
  cat("Leaflet map saved as HTML:", html_file, "\n")

  webshot::webshot(html_file, file = png_file)
  cat("Screenshot saved as PNG:", png_file, "\n")

  invisible(dot_map)
}
