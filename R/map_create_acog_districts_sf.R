#' Create `sf` Polygons for ACOG Districts
#'
#' This helper reads the packaged ACOG district lookup table and joins it with
#' state geometries from Natural Earth to construct polygons for each district.
#' The resulting object can be used to add district boundaries to Leaflet maps
#' or for further spatial analysis.
#'
#' @param acog_districts_file Optional path to a CSV containing the mapping of
#'   states to ACOG districts. Defaults to the packaged
#'   `inst/extdata/acog_districts.csv`.
#'
#' @return An `sf` object with one row per ACOG district and columns:
#'   \describe{
#'     \item{`ACOG_District`}{Character. ACOG district identifier (e.g.
#'       `"District I"`).}
#'     \item{`Subregion`}{Character. Regional grouping of states.}
#'     \item{`States`}{Character. Comma-separated state names in the district.}
#'     \item{`State_Abbreviations`}{Character. Comma-separated 2-letter postal
#'       codes.}
#'     \item{`geometry`}{sfc_MULTIPOLYGON. District boundaries in EPSG:4326.}
#'   }
#'
#' @family mapping
#' @export
#' @examplesIf interactive()
#' mysterycall_map_acog_districts()
#' mysterycall_map_acog_districts("inst/extdata/acog_districts.csv")
mysterycall_map_acog_districts <- function(acog_districts_file = NULL) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required", call. = FALSE)
  }
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("Package 'readr' is required for mysterycall_map_acog_districts().", call. = FALSE)
  }

  if (is.null(acog_districts_file)) {
    acog_districts_file <- system.file("extdata", "acog_districts.csv", package = "mysterycall")
  }

  if (!nzchar(acog_districts_file) || !file.exists(acog_districts_file)) {
    stop("Could not locate the ACOG districts file at '", acog_districts_file, "'.", call. = FALSE)
  }

  districts <- readr::read_csv(acog_districts_file, show_col_types = FALSE, progress = FALSE)

  names(districts) <- gsub("^\\ufeff", "", names(districts))
  names(districts) <- gsub("[^\\x00-\\x7F]", "", names(districts), perl = TRUE)
  bom_state_col <- grep("^\\.+State$", names(districts), value = TRUE)
  if (length(bom_state_col) && !("State" %in% names(districts))) {
    districts <- dplyr::rename(districts, State = dplyr::all_of(bom_state_col[[1]]))
  }

  if (!"State" %in% names(districts)) {
    stop("The ACOG districts file must contain a 'State' column.", call. = FALSE)
  }

  districts <- dplyr::mutate(
    districts,
    State = stringr::str_trim(.data$State),
    ACOG_District = stringr::str_trim(.data$ACOG_District),
    Subregion = dplyr::coalesce(stringr::str_trim(.data$Subregion), .data$ACOG_District)
  )

  if (!requireNamespace("rnaturalearth", quietly = TRUE)) {
    stop("Package 'rnaturalearth' is required for mysterycall_map_acog_districts()", call. = FALSE)
  }
  states_sf <- rnaturalearth::ne_states(country = "united states of america", returnclass = "sf")
  states_sf <- dplyr::transmute(
    states_sf,
    State = stringr::str_trim(name),
    postal,
    geometry
  )

  states_sf <- dplyr::filter(states_sf, .data$State %in% districts$State)

  states_with_districts <- dplyr::left_join(states_sf, districts, by = "State")
  states_with_districts <- dplyr::filter(states_with_districts, !is.na(.data$ACOG_District))

  if (!nrow(states_with_districts)) {
    stop("No matching states were found when joining Natural Earth geometries to the district table.", call. = FALSE)
  }

  states_with_districts <- dplyr::mutate(
    states_with_districts,
    State_Abbreviations = dplyr::coalesce(.data$State_Abbreviations, .data$postal)
  )

  districts_sf <- states_with_districts %>%
    dplyr::group_by(.data$ACOG_District, .data$Subregion) %>%
    dplyr::summarize(
      States = paste(sort(unique(.data$State)), collapse = ", "),
      State_Abbreviations = paste(sort(unique(.data$State_Abbreviations)), collapse = ", "),
      geometry = sf::st_union(.data$geometry),
      .groups = "drop"
    ) %>%
    dplyr::arrange(.data$ACOG_District)

  sf::st_as_sf(districts_sf)
}

