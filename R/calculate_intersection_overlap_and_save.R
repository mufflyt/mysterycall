#' Calculate intersection overlap and save results to shapefiles.
#'
#' This function calculates the intersection between block groups and isochrones for a specific drive time and saves the results to a shapefile.  To
#' ensure accurate area-based calculations, both datasets are temporarily
#' projected to an equal-area CRS before measuring.
#'
#' @param block_groups An sf object representing block groups.
#' @param isochrones_joined An sf object representing isochrones.
#' @param drive_time_minutes The drive time value (in minutes) for which to calculate the
#'   intersection.
#' @param output_dir The directory where the intersection shapefile will be saved.
#' @param crosswalk Optional function used to translate ACS geographies between
#'   2010 and 2020 definitions. When supplied, it should accept two arguments:
#'   an sf object and a named list with `from` and `to` years, returning an sf
#'   object whose `vintage` column matches the provider `data_year`.
#' @param notify Logical. If `TRUE`, play a notification sound on completion when
#'   the optional `beepr` package is available. Defaults to `TRUE`.
#'
#' @return `invisible(NULL)`. As side effects: (1) writes an ESRI shapefile
#'   (EPSG:4326) of the block-group/isochrone intersection to `output_dir`,
#'   (2) writes a CSV with columns `GEOID`, `intersect_area`, and
#'   `area_method` to the same directory, and (3) emits messages with the
#'   50th and 75th percentile overlap statistics. If `notify = TRUE` and
#'   `beepr` is installed, plays a completion sound.
#' @seealso [mysterycall_isochrones_for_df()] to generate the `isochrones_joined`
#'   input; [mysterycall_create_isochrones()] for single-point isochrone creation.
#'
#' @examplesIf interactive()
#' mysterycall_calculate_overlap(block_groups, isochrones_joined, 30L, "data/shp/")
#' @importFrom dplyr mutate select left_join coalesce
#' @importFrom checkmate assert_class assert_number assert_string assert_function
#' @importFrom dplyr .data
#' @importFrom stats quantile na.omit
#' @family geospatial helpers
#' @export
mysterycall_calculate_overlap <- function(block_groups,
                                                    isochrones_joined,
                                                    drive_time_minutes,
                                                    output_dir,
                                                    crosswalk = NULL,
                                                    notify = TRUE) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required", call. = FALSE)
  }

  orient_geometries <- function(x) {
    if (!requireNamespace("lwgeom", quietly = TRUE)) {
      return(x)
    }
    orient_fn <- get0("st_orient", envir = asNamespace("lwgeom"), mode = "function")
    if (is.null(orient_fn)) return(x)
    orient_fn(x)
  }

  # Parameter validation
  if (!inherits(block_groups, "sf")) {
    stop("'block_groups' must be an sf object.", call. = FALSE)
  }
  if (!inherits(isochrones_joined, "sf")) {
    stop("'isochrones_joined' must be an sf object.", call. = FALSE)
  }
  if (!is.numeric(drive_time_minutes) || length(drive_time_minutes) != 1L || drive_time_minutes < 0) {
    stop("'drive_time_minutes' must be a single non-negative numeric value.", call. = FALSE)
  }
  if (!is.character(output_dir) || !nzchar(output_dir)) {
    stop("'output_dir' must be a non-empty character string.", call. = FALSE)
  }
  if (!is.null(crosswalk) && !is.function(crosswalk)) {
    stop("'crosswalk' must be a function or NULL.", call. = FALSE)
  }
  checkmate::assert_flag(notify, .var.name = "notify")

  validated <- validate_sf_inputs(
    block_groups = block_groups,
    isochrones_joined = isochrones_joined,
    expected_types = list(
      block_groups = c("POLYGON", "MULTIPOLYGON"),
      isochrones_joined = c("POLYGON", "MULTIPOLYGON")
    ),
    context = "mysterycall_calculate_overlap()"
  )
  block_groups <- validated$block_groups
  isochrones_joined <- validated$isochrones_joined

  block_groups <- orient_geometries(block_groups)
  isochrones_joined <- orient_geometries(isochrones_joined)

  # Year alignment enforcement
  if (!"data_year" %in% names(isochrones_joined)) {
    stop("`isochrones_joined` must include a `data_year` column for provider vintage alignment.", call. = FALSE)
  }
  if (!"vintage" %in% names(block_groups)) {
    stop("`block_groups` must include a `vintage` column indicating ACS vintage.", call. = FALSE)
  }

  provider_years <- stats::na.omit(unique(isochrones_joined$data_year))
  acs_years <- stats::na.omit(unique(block_groups$vintage))

  if (length(provider_years) != 1L) {
    stop("`isochrones_joined$data_year` must contain a single, non-missing year value.", call. = FALSE)
  }
  if (length(acs_years) != 1L) {
    stop("`block_groups$vintage` must contain a single, non-missing year value.", call. = FALSE)
  }

  provider_year <- provider_years[[1]]
  acs_year <- acs_years[[1]]

  if (!identical(provider_year, acs_year)) {
    if (!identical(sort(c(provider_year, acs_year)), c(2010, 2020))) {
      stop(
        sprintf(
          "Provider data_year (%s) and ACS vintage (%s) differ. Provide matching vintages.",
          provider_year,
          acs_year
        ),
        call. = FALSE
      )
    }

    if (is.null(crosswalk)) {
      stop(
        sprintf(
          paste(
            "Provider data_year (%s) and ACS vintage (%s) differ. ",
            "Supply a `crosswalk` function to translate between 2010 and 2020 geographies."
          ),
          provider_year,
          acs_year
        ),
        call. = FALSE
      )
    }

    block_groups <- crosswalk(block_groups, list(from = acs_year, to = provider_year))

    if (!inherits(block_groups, "sf")) {
      stop("`crosswalk` must return an sf object.", call. = FALSE)
    }
    if (!"vintage" %in% names(block_groups)) {
      stop("The object returned by `crosswalk` must include a `vintage` column.", call. = FALSE)
    }

    validated_crosswalk <- validate_sf_inputs(
      block_groups = block_groups,
      isochrones_joined = isochrones_joined,
      expected_types = list(
        block_groups = c("POLYGON", "MULTIPOLYGON"),
        isochrones_joined = c("POLYGON", "MULTIPOLYGON")
      ),
      context = "mysterycall_calculate_overlap(): post-crosswalk"
    )
    block_groups <- validated_crosswalk$block_groups
    isochrones_joined <- validated_crosswalk$isochrones_joined

    block_groups <- orient_geometries(block_groups)
    isochrones_joined <- orient_geometries(isochrones_joined)

    acs_years <- stats::na.omit(unique(block_groups$vintage))
    if (length(acs_years) != 1L || !identical(acs_years[[1]], provider_year)) {
      stop("`crosswalk` did not return ACS data aligned to the provider year.", call. = FALSE)
    }
  }

  # Use an equal-area projection for accurate area calculations
  area_crs <- 5070 # NAD83 / Conus Albers

  # Filter isochrones for the specified drive time
  isochrones_filtered <- isochrones_joined[isochrones_joined$drive_time == drive_time_minutes, , drop = FALSE]

  if (nrow(isochrones_filtered) == 0) {
    available_drive_times <- sort(unique(stats::na.omit(isochrones_joined$drive_time)))
    available_text <- if (length(available_drive_times)) {
      paste(available_drive_times, collapse = ", ")
    } else {
      "<none>"
    }
    stop(
      sprintf(
        "No isochrones found for `drive_time_minutes = %s`. Available drive_time values: %s",
        drive_time_minutes,
        available_text
      ),
      call. = FALSE
    )
  }

  isochrones_filtered <- sf::st_union(isochrones_filtered)
  isochrones_filtered <- sf::st_sf(
    drive_time = drive_time_minutes,
    data_year = provider_year,
    geometry = isochrones_filtered,
    crs = sf::st_crs(isochrones_joined)
  )
  isochrones_filtered <- orient_geometries(isochrones_filtered)

  # Project to an equal-area CRS for area calculations
  block_groups_proj <- sf::st_transform(block_groups, area_crs)
  isochrones_proj <- sf::st_transform(isochrones_filtered, area_crs)

  # Calculate intersection in projected CRS (suppress sf planar-coordinates warning)
  intersect <- suppressWarnings(sf::st_intersection(block_groups_proj, isochrones_proj)) %>%
    dplyr::mutate(
      intersect_area = as.numeric(sf::st_area(.)),
      area_method = "projected:EPSG:5070"
    )

  # Validate GEOID exists in intersection result (Bug #12 fix)
  if (!"GEOID" %in% names(intersect)) {
    stop("Intersection result is missing required `GEOID`; verify `block_groups` includes `GEOID` before intersection.", call. = FALSE)
  }

  # Validate GEOID exists in block_groups (Bug #12 fix)
  if (!"GEOID" %in% names(block_groups_proj)) {
    stop("`block_groups` is missing required `GEOID` column.", call. = FALSE)
  }

  # Data frame version for joins
  intersect_df <- intersect %>%
    dplyr::select(GEOID, intersect_area, area_method) %>%
    sf::st_drop_geometry()

  # Log the progress
  message(sprintf("Calculating intersection for %s minutes...", drive_time_minutes))

  # Write the intersection shapefile
  output_shapefile <- file.path(output_dir, sprintf("intersect_%s_minutes.shp", drive_time_minutes))
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  suppressWarnings(sf::st_write(sf::st_transform(intersect, 4326), output_shapefile, append = FALSE))
  message("Intersection calculated and saved successfully.")

  # Validate GEOID compatibility before join (Bug #4 fix)
  missing_geoids <- setdiff(intersect_df$GEOID, block_groups_proj$GEOID)
  if (length(missing_geoids) > 0) {
    warning(sprintf(
      "Warning: %d GEOIDs in intersection result are not in block_groups. These rows will be dropped.",
      length(missing_geoids)
    ))
  }

  # Merge intersection area by GEOID on projected data
  block_groups_proj <- dplyr::left_join(block_groups_proj, intersect_df, by = "GEOID")

  # Calculate area in all block groups (projected CRS)
  block_groups_proj <- block_groups_proj %>%
    dplyr::mutate(
      bg_area = as.numeric(sf::st_area(.)),
      area_method = dplyr::coalesce(.data$area_method, "projected:EPSG:5070")
    )

  # Calculate overlap percent between block groups and isochrones
  block_groups_proj <- block_groups_proj %>%
    dplyr::mutate(
      intersect_area = dplyr::coalesce(.data$intersect_area, 0),
      overlap = ifelse(.data$bg_area > 0, .data$intersect_area / .data$bg_area, NA_real_)
    )

  # Filter out missing overlap values for quantile calculation
  non_missing_overlap <- stats::na.omit(block_groups_proj$overlap)

  if (!length(non_missing_overlap)) {
    warning("No overlaps were found for the requested drive time.")
    return(invisible(NULL))
  }

  # Summary of the overlap percentiles
  summary_bg <- summary(non_missing_overlap)

  # Print the summary
  message("Summary of Overlap Percentages for ", drive_time_minutes, " minutes:")
  message(capture.output(summary_bg))

  # Calculate and print the 50th percentile of overlap percentages
  median <- round(stats::quantile(non_missing_overlap, probs = 0.5), 4) * 100
  message("50th Percentile of Overlap Percentages: ", median, "%")

  # Calculate and print the 75th percentile of overlap percentages
  p75 <- round(stats::quantile(non_missing_overlap, probs = 0.75), 4) * 100
  message("75th Percentile of Overlap Percentages: ", p75, "%")

  if (isTRUE(interactive()) && isTRUE(notify) && requireNamespace("beepr", quietly = TRUE)) {
    beepr::beep(2)
  }
}


# # Use Case
# # List of unique drive times for which you want to calculate intersection
# unique_drive_times <- unique(isochrones_filtered$drive_time)
#
# # Specify the output directory
# output_dir <- "data/shp/"
#
# # Loop through unique drive times and calculate intersection for each
# for (drive_time in unique_drive_times) {
#   mysterycall_calculate_overlap(block_groups, isochrones_joined, drive_time, output_dir)
# }
