#' Calculate drive-time isochrones for a location
#'
#' Computes drive-time isolines (isochrones) for a given point using the HERE
#' routing API via the `hereR` package.  Results are memoized in memory for the
#' duration of the R session so repeated calls with the same inputs are free.
#' Use [mysterycall_clear_isochrone_cache()] to release memory after a batch.
#'
#' @param location An `sf` point object representing the origin location.
#' @param range Numeric vector of drive-time thresholds in **seconds**
#'   (e.g. `c(1800, 3600)` for 30- and 60-minute isochrones).
#' @param posix_time A `POSIXct` scalar giving the departure time used by the
#'   routing engine.  Defaults to `"2023-10-20 08:00:00"` (a weekday morning).
#' @param api_key HERE API key.  Defaults to the `HERE_API_KEY` environment
#'   variable.  Obtain a free key at <https://www.here.com/developer>.
#'
#' @return A named `list`. On success: one element per value in `range`,
#'   named by the drive-time threshold in seconds (e.g., `"1800"`), each
#'   containing an `sf` POLYGON object with the isochrone geometry. On
#'   API failure: a `list` with a single `error` element (character scalar)
#'   containing the error message. Detect failures with
#'   `if (!is.null(result$error)) { ... }`.
#'
#' @seealso [mysterycall_clear_isochrone_cache()] to free session memory after
#'   batch processing; [mysterycall_geocode()] to produce the input coordinates.
#' @examplesIf interactive()
#' location <- sf::st_sfc(sf::st_point(c(-73.987, 40.757)), crs = 4326)
#' isolines <- mysterycall_create_isochrones(
#'   location = location,
#'   range    = c(1800, 3600)
#' )
#' mysterycall_clear_isochrone_cache()
#'
#' @family mapping
#' @export
#' @importFrom dplyr mutate row_number
mysterycall_create_isochrones <- function(location,
                              range,
                              posix_time = as.POSIXct("2023-10-20 08:00:00",
                                                      format = "%Y-%m-%d %H:%M:%S"),
                              api_key = Sys.getenv("HERE_API_KEY")) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required", call. = FALSE)
  }

  if (!requireNamespace("hereR", quietly = TRUE)) {
    stop("Package 'hereR' is required for mysterycall_create_isochrones()", call. = FALSE)
  }
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("Package 'sf' is required for mysterycall_create_isochrones()", call. = FALSE)
  }
  if (!requireNamespace("lwgeom", quietly = TRUE)) {
    stop("Package 'lwgeom' is required for mysterycall_create_isochrones()", call. = FALSE)
  }

  if (is.null(.isochrone_memo)) {
    .isochrone_worker(location, range, posix_time, api_key)
  } else {
    .isochrone_memo(location, range, posix_time, api_key)
  }
}

# Internal worker function (unmemoized)
.isochrone_worker <- function(location, range, posix_time, api_key) {
  if (is.na(api_key) || !nzchar(api_key)) {
    stop("routing API key is required via argument or HERE_API_KEY env var.", call. = FALSE)
  }

  hereR::set_freemium(ans = FALSE)
  hereR::set_key(api_key)
  hereR::set_verbose(TRUE)

  isolines_list <- list()

  out <- tryCatch({
    for (r in range) {
      temp <- hereR::isoline(
        poi = location,
        datetime = posix_time,
        routing_mode = "fast",
        range = r,
        range_type = "time",
        transport_mode = "car",
        url_only = FALSE,
        optimize = "balanced",
        traffic = TRUE,
        aggregate = FALSE
      )

      message("Isoline successfully produced for range: ", r, " seconds")

      temp <- temp %>%
        sf::st_make_valid() %>%
        dplyr::mutate(unique_id = dplyr::row_number())

      if (!all(sf::st_is_valid(temp))) {
        stop("drive-time routing service returned geometries that could not be validated.", call. = FALSE)
      }

      temp <- sf::st_transform(temp, 4326)
      temp <- lwgeom::st_force_polygon_cw(temp)

      isolines_list[[as.character(r)]] <- temp
    }

    return(isolines_list)
  }, error = function(e) {
    message("Error in mysterycall_create_isochrones: ", e$message)
    return(list(error = e$message))
  })

  out
}

# Internal memoized worker - stored in the package namespace so
# mysterycall_clear_isochrone_cache() can call memoise::forget() on it.
# If memoise is not installed, .isochrone_memo is NULL and mysterycall_create_isochrones()
# falls back to calling .isochrone_worker() directly.
.isochrone_memo <- if (requireNamespace("memoise", quietly = TRUE)) {
  memoise::memoise(.isochrone_worker)
} else {
  NULL
}

#' Clear the isochrone memoization cache
#'
#' [mysterycall_create_isochrones()] caches every result in memory for the
#' duration of the R session.  Call this after processing a large batch to
#' release that memory.  Has no effect if the `memoise` package is not
#' installed (memoization is skipped in that case).
#'
#' @return Invisibly `NULL`.
#' @seealso [mysterycall_create_isochrones()] which builds the memoized cache.
#' @family mapping
#' @examples
#' mysterycall_clear_isochrone_cache()
#' @export
mysterycall_clear_isochrone_cache <- function() {
  if (!is.null(.isochrone_memo) && requireNamespace("memoise", quietly = TRUE)) {
    memoise::forget(.isochrone_memo)
  }
  invisible(NULL)
}
