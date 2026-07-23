#' Geocode full street addresses (US Census batch, with fallbacks)
#'
#' Geocodes complete practice addresses (street, city, state, ZIP) to
#' coordinates and 2020 census geography using the US Census Bureau **batch**
#' geocoder (\url{https://geocoding.geo.census.gov}; free, no key). Addresses the
#' Census cannot match optionally fall back to Nominatim (OpenStreetMap) and then
#' ArcGIS, one address at a time.
#'
#' This is more precise than [mysterycall_geocode_city_state()], which resolves
#' only to a city centroid: a street match places the physician in the correct
#' census tract and ZCTA, which matters for area-level covariates
#' ([mysterycall_assign_area_covariates()]). The HTTP request/response machinery
#' is ported from the `isochrones` project's geocoding seams so it is unit
#' testable without a network (see the internal `.mc_build_*` / `.mc_parse_*`
#' seams).
#'
#' @param data A data frame of addresses.
#' @param street_col,city_col,state_col,zip_col Column names holding the street
#'   line, city, state, and ZIP. Defaults `"street"`, `"city"`, `"state"`,
#'   `"zip"`.
#' @param batch_size Addresses per Census request (1-10000). Default 1000.
#' @param fallback Logical. When `TRUE` (default) unmatched addresses are retried
#'   one at a time via Nominatim then ArcGIS. Nominatim asks callers to stay
#'   under ~1 request/second, so this is slow for large unmatched sets.
#' @param benchmark,vintage Census geocoder benchmark and vintage.
#' @param verbose Logical; print per-batch progress. Default `TRUE`.
#'
#' @return `data` with six columns appended: `geo_lat`, `geo_long`,
#'   `geo_match` (`"Match"`/`"No_Match"`/`"Tie"`), `geo_matched_address`,
#'   `geo_tract` (11-digit 2020 GEOID, Census matches only), and `geo_source`
#'   (`"census"`, `"nominatim"`, `"arcgis"`, or `NA`). Feed `geo_lat`/`geo_long`
#'   to [mysterycall_assign_area_covariates()] for ADI/SVI/HHI.
#'
#' @family npi
#' @seealso [mysterycall_geocode_city_state()] for the coarser city-centroid
#'   geocoder; [mysterycall_assign_area_covariates()] to attach area covariates.
#' @examplesIf interactive()
#' addr <- data.frame(street = "12631 E 17th Ave", city = "Aurora",
#'                    state = "CO", zip = "80045")
#' mysterycall_geocode_address(addr)
#' @export
mysterycall_geocode_address <- function(data,
                                        street_col = "street",
                                        city_col   = "city",
                                        state_col  = "state",
                                        zip_col    = "zip",
                                        batch_size = 1000L,
                                        fallback   = TRUE,
                                        benchmark  = "Public_AR_Current",
                                        vintage    = "Current_Current",
                                        verbose    = TRUE) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_subset(c(street_col, city_col, state_col, zip_col), names(data))
  checkmate::assert_int(batch_size, lower = 1L, upper = 10000L)
  checkmate::assert_flag(fallback)
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("Package 'httr' is required for mysterycall_geocode_address().", call. = FALSE)
  }

  n  <- nrow(data)
  addr <- data.frame(
    address = as.character(data[[street_col]]),
    city    = as.character(data[[city_col]]),
    state   = as.character(data[[state_col]]),
    zip     = as.character(data[[zip_col]]),
    stringsAsFactors = FALSE
  )

  lat <- rep(NA_real_, n); long <- rep(NA_real_, n)
  matchv <- rep(NA_character_, n); matched <- rep(NA_character_, n)
  tract <- rep(NA_character_, n); source <- rep(NA_character_, n)

  batch <- ((seq_len(n) - 1L) %/% batch_size) + 1L
  for (b in sort(unique(batch))) {
    rows <- which(batch == b)
    res  <- .mc_census_batch(addr[rows, , drop = FALSE], benchmark, vintage)
    if (!is.null(res)) {
      m <- match(seq_along(rows), res$id)
      long[rows]    <- res$lon[m]
      lat[rows]     <- res$lat[m]
      matchv[rows]  <- res$match[m]
      matched[rows] <- res$matched_address[m]
      tract[rows]   <- res$census_tract[m]
      source[rows]  <- ifelse(!is.na(res$lat[m]), "census", NA_character_)
    }
    if (verbose) {
      message(sprintf("Census batch %d/%d: %d/%d matched",
                      b, max(batch), sum(!is.na(lat[rows])), length(rows)))
    }
  }

  if (fallback) {
    todo <- which(is.na(lat))
    if (length(todo) && verbose) {
      message(sprintf("Fallback (Nominatim/ArcGIS) for %d unmatched...", length(todo)))
    }
    for (i in todo) {
      fb <- .mc_geocode_one_fallback(addr$address[i], addr$city[i],
                                     addr$state[i], addr$zip[i])
      if (!is.na(fb$lat)) {
        lat[i] <- fb$lat; long[i] <- fb$lon
        matchv[i] <- "Match"; matched[i] <- fb$matched_address
        source[i] <- fb$source
      }
    }
  }

  data[["geo_lat"]]             <- lat
  data[["geo_long"]]            <- long
  data[["geo_match"]]           <- matchv
  data[["geo_matched_address"]] <- matched
  data[["geo_tract"]]           <- tract
  data[["geo_source"]]          <- source
  data
}

# ---------------------------------------------------------------------------
# HTTP request/response seams, ported from the isochrones project
# (R/geocoding_http_seams.R). Kept as isolated, network-free seams so the
# builders and parsers can be unit tested with fixture data.
# ---------------------------------------------------------------------------

#' Run one Census batch: build -> POST (with retry) -> parse
#' @param addresses Data frame with `address`,`city`,`state`,`zip`.
#' @param benchmark,vintage Census parameters.
#' @return Parsed result data frame, or `NULL` on request failure.
#' @family npi
#' @keywords internal
.mc_census_batch <- function(addresses, benchmark, vintage) {
  req <- .mc_build_census_batch_request(addresses, benchmark = benchmark,
                                        vintage = vintage)
  on.exit(unlink(req$temp_file), add = TRUE)
  resp <- tryCatch(
    .mc_geocode_http_with_retry(function() {
      .mc_geocode_http_post(
        req$url,
        body = list(addressFile = httr::upload_file(req$temp_file),
                    benchmark = req$benchmark, vintage = req$vintage)
      )
    }),
    error = function(e) NULL
  )
  if (is.null(resp) || httr::http_error(resp)) return(NULL)
  txt <- httr::content(resp, as = "text", encoding = "UTF-8")
  .mc_parse_census_batch_response(txt, request_geographies = TRUE)
}

#' Build a Census batch geocoding request (writes the upload CSV)
#' @param addresses Data frame with `address`,`city`,`state`,`zip`.
#' @param benchmark,vintage Census parameters.
#' @param request_geographies Request tract/block geographies (12-col response).
#' @return List with `url`, `temp_file`, `benchmark`, `vintage`.
#' @family npi
#' @keywords internal
.mc_build_census_batch_request <- function(addresses,
                                           benchmark = "Public_AR_Current",
                                           vintage = "Current_Current",
                                           request_geographies = TRUE) {
  stopifnot(is.data.frame(addresses), nrow(addresses) > 0)
  batch_data <- data.frame(
    id     = seq_len(nrow(addresses)),
    street = addresses[["address"]],
    city   = addresses[["city"]],
    state  = addresses[["state"]],
    zip    = stringr::str_extract(as.character(addresses[["zip"]]), "\\d{5}"),
    stringsAsFactors = FALSE
  )
  temp_file <- tempfile(fileext = ".csv")
  readr::write_csv(batch_data, temp_file, col_names = FALSE, na = "")
  endpoint <- if (request_geographies) {
    "https://geocoding.geo.census.gov/geocoder/geographies/addressbatch"
  } else {
    "https://geocoding.geo.census.gov/geocoder/locations/addressbatch"
  }
  list(url = endpoint, temp_file = temp_file, benchmark = benchmark,
       vintage = vintage, request_geographies = request_geographies)
}

#' Parse a Census batch geocoding CSV response
#' @param content_text Raw CSV text from the API.
#' @param request_geographies Whether geographies were requested (column count).
#' @return Data frame: `id`, `input_address`, `match`, `match_type`,
#'   `matched_address`, `lon`, `lat`, `census_tract`.
#' @family npi
#' @keywords internal
.mc_parse_census_batch_response <- function(content_text, request_geographies = TRUE) {
  cols_geo <- c("id", "input_address", "match", "match_type", "matched_address",
                "lon_lat", "tiger_line_id", "tiger_side", "state_fips",
                "county_fips", "tract", "block")
  cols_loc <- c("id", "input_address", "match", "match_type", "matched_address",
                "lon_lat", "tiger_line_id", "tiger_side")
  col_names <- if (request_geographies) cols_geo else cols_loc

  result <- tryCatch(
    readr::read_csv(I(content_text), col_names = col_names,
                    col_types = readr::cols(.default = readr::col_character())),
    error = function(e) {
      warning(sprintf("Failed to parse Census batch CSV: %s", conditionMessage(e)),
              call. = FALSE)
      NULL
    }
  )
  if (is.null(result) || !nrow(result)) {
    return(data.frame(id = integer(0), input_address = character(0),
                      match = character(0), match_type = character(0),
                      matched_address = character(0), lon = numeric(0),
                      lat = numeric(0), census_tract = character(0),
                      stringsAsFactors = FALSE))
  }

  valid <- grepl("^-?[0-9.]+,-?[0-9.]+$", result$lon_lat)
  parts <- stringr::str_split_fixed(dplyr::coalesce(result$lon_lat, ""), ",", 2)
  result$lon <- dplyr::if_else(valid, suppressWarnings(as.numeric(parts[, 1])), NA_real_)
  result$lat <- dplyr::if_else(valid, suppressWarnings(as.numeric(parts[, 2])), NA_real_)

  if (request_geographies && all(c("state_fips", "county_fips", "tract") %in% names(result))) {
    result$census_tract <- dplyr::if_else(
      !is.na(result$state_fips) & !is.na(result$county_fips) & !is.na(result$tract) &
        result$state_fips != "" & result$county_fips != "" & result$tract != "",
      paste0(result$state_fips, result$county_fips, result$tract), NA_character_
    )
  } else {
    result$census_tract <- NA_character_
  }
  result$id <- suppressWarnings(as.integer(result$id))
  result[, c("id", "input_address", "match", "match_type", "matched_address",
             "lon", "lat", "census_tract")]
}

#' Fall back to Nominatim then ArcGIS for one address
#' @param addr,city,state,zip Address parts.
#' @return List with `lon`, `lat`, `matched_address`, `source`.
#' @family npi
#' @keywords internal
.mc_geocode_one_fallback <- function(addr, city, state, zip) {
  none <- list(lon = NA_real_, lat = NA_real_, matched_address = NA_character_,
               source = NA_character_)
  # Nominatim (usage policy: <=1 request/second)
  nom <- tryCatch({
    Sys.sleep(1)
    q <- paste(stats::na.omit(c(addr, city, state, zip)), collapse = ", ")
    resp <- .mc_geocode_http_get("https://nominatim.openstreetmap.org/search",
                                 params = list(q = q, format = "json", limit = 1,
                                               countrycodes = "us"))
    if (httr::http_error(resp)) stop("http error")
    j <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    if (length(j) == 0) NULL else
      list(lon = as.numeric(j$lon[1]), lat = as.numeric(j$lat[1]),
           matched_address = j$display_name[1], source = "nominatim")
  }, error = function(e) NULL)
  if (!is.null(nom) && !is.na(nom$lat)) return(nom)

  nz <- function(x) if (is.null(x) || is.na(x)) "" else as.character(x)
  arc <- tryCatch({
    sl <- sprintf("%s, %s, %s %s", nz(addr), nz(city), nz(state), nz(zip))
    resp <- .mc_geocode_http_get(
      "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates",
      params = list(singleLine = sl, f = "json", outFields = "Match_addr,Addr_type"))
    if (httr::http_error(resp)) stop("http error")
    j <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
    cand <- j$candidates
    if (is.null(cand) || !length(cand) || !nrow(cand)) NULL else
      list(lon = cand$location$x[1], lat = cand$location$y[1],
           matched_address = cand$attributes$Match_addr[1], source = "arcgis")
  }, error = function(e) NULL)
  if (!is.null(arc) && !is.na(arc$lat)) return(arc)
  none
}

#' HTTP GET seam for geocoding (single mock point)
#' @param url,params,timeout,user_agent Request parameters.
#' @return httr response object.
#' @family npi
#' @keywords internal
.mc_geocode_http_get <- function(url, params = list(), timeout = 10,
                                 user_agent = "mysterycall-geocoder") {
  httr::GET(url, query = params, httr::user_agent(user_agent), httr::timeout(timeout))
}

#' HTTP POST seam for geocoding (single mock point)
#' @param url,body,encode,timeout,user_agent Request parameters.
#' @return httr response object.
#' @family npi
#' @keywords internal
.mc_geocode_http_post <- function(url, body = NULL, encode = "multipart",
                                  timeout = 120, user_agent = "mysterycall-geocoder") {
  httr::POST(url, body = body, encode = encode,
             httr::user_agent(user_agent), httr::timeout(timeout))
}

#' HTTP request with retry and exponential backoff
#' @param request_fn Function returning an httr response.
#' @param max_attempts,initial_delay_ms,max_delay_ms,jitter_factor Retry params.
#' @return httr response object, or the last error is re-thrown.
#' @family npi
#' @keywords internal
.mc_geocode_http_with_retry <- function(request_fn, max_attempts = 3,
                                        initial_delay_ms = 1000,
                                        max_delay_ms = 30000,
                                        jitter_factor = 0.25) {
  retry_codes <- c(429, 500, 502, 503, 504)
  attempt <- 1L; delay_ms <- initial_delay_ms
  backoff <- function() {
    jitter <- stats::runif(1, 1 - jitter_factor, 1 + jitter_factor)
    Sys.sleep(min(delay_ms * jitter, max_delay_ms) / 1000)
    delay_ms <<- delay_ms * 2; attempt <<- attempt + 1L
  }
  while (attempt <= max_attempts) {
    # tryCatch only wraps the request: on a transient error return a retry
    # sentinel; loop control (next/return) stays in the while body so it can
    # never short-circuit the whole function.
    response <- tryCatch(request_fn(), error = function(e) {
      transient <- grepl("(timeout|timed out|connection|reset|refused|temporarily)",
                         conditionMessage(e), ignore.case = TRUE)
      if (transient && attempt < max_attempts) structure(list(), class = "mc_retry")
      else stop(e)
    })
    if (inherits(response, "mc_retry")) { backoff(); next }

    status <- httr::status_code(response)
    if (status %in% retry_codes && attempt < max_attempts) { backoff(); next }
    return(response)
  }
  stop("Max retry attempts exceeded")
}
