# Retrieve the bundled city/state -> lat/long lookup from the namespace, so the
# reference works under both an installed package and devtools::load_all().
.mc_city_coords <- function() {
  get("city_state_to_lat_long", envir = asNamespace("mysterycall"))
}

#' Look up latitude/longitude for city + state
#'
#' A lightweight geocoder for the common case where a provider roster carries a
#' city and a two-letter state but no coordinates. It joins against the package's
#' bundled `city_state_to_lat_long` table (roughly 32,000 US places), so it needs
#' no network and no API key -- enough to seed a distance caliper for matched
#' sampling or to QC how far apart matched practices sit. For rooftop-accurate
#' geocoding of full street addresses, use a dedicated geocoding service instead.
#'
#' @param city Character vector of city names (case/space-insensitive).
#' @param state Character vector of two-letter state abbreviations, the same
#'   length as `city`.
#' @param overrides Optional data frame of manual coordinates for places the
#'   bundled table misses (townships, renamed municipalities). Must have columns
#'   `city`, `state`, `lat`, `lon`; matched case-insensitively and applied on top
#'   of the table lookup.
#'
#' @return A tibble with columns `city`, `state` (both upper-cased/trimmed),
#'   `lat`, `lon`. Unmatched rows get `NA` coordinates.
#'
#' @examples
#' mysterycall_geocode_city_state(c("Denver", "Boston"), c("CO", "MA"))
#' @export
mysterycall_geocode_city_state <- function(city, state, overrides = NULL) {
  city  <- toupper(trimws(as.character(city)))
  state <- toupper(trimws(as.character(state)))
  if (length(state) != length(city)) {
    stop("`city` and `state` must have the same length.", call. = FALSE)
  }

  ref <- .mc_city_coords()
  ref_key <- paste(toupper(trimws(ref$city)), toupper(trimws(ref$state)),
                   sep = "\r")
  keep <- !duplicated(ref_key)
  ref <- ref[keep, , drop = FALSE]
  ref_key <- ref_key[keep]

  idx <- match(paste(city, state, sep = "\r"), ref_key)
  lat <- ref$lat[idx]
  lon <- ref$long[idx]

  if (!is.null(overrides)) {
    checkmate::assert_data_frame(overrides)
    checkmate::assert_subset(c("city", "state", "lat", "lon"), names(overrides))
    ok <- paste(toupper(trimws(overrides$city)), toupper(trimws(overrides$state)),
                sep = "\r")
    hit <- match(paste(city, state, sep = "\r"), ok)
    has <- !is.na(hit)
    lat[has] <- overrides$lat[hit[has]]
    lon[has] <- overrides$lon[hit[has]]
  }

  tibble::tibble(city = city, state = state, lat = lat, lon = lon)
}

# Vectorized haversine distance in miles from one point to many.
.mc_haversine_miles <- function(lat1, lon1, lat2, lon2) {
  r <- 3959  # Earth radius, miles
  if (is.na(lat1) || is.na(lon1)) return(rep(Inf, length(lat2)))
  p1 <- lat1 * pi / 180
  p2 <- lat2 * pi / 180
  dphi <- (lat2 - lat1) * pi / 180
  dlam <- (lon2 - lon1) * pi / 180
  a <- sin(dphi / 2)^2 + cos(p1) * cos(p2) * sin(dlam / 2)^2
  d <- r * 2 * atan2(sqrt(a), sqrt(1 - a))
  d[is.na(lat2) | is.na(lon2)] <- Inf
  d
}
