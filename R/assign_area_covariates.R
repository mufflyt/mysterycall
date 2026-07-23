#' Assign area-level covariates (ADI, SVI, HHI) from physician coordinates
#'
#' Attaches neighbourhood and market context to physicians from their practice
#' latitude/longitude, maximising coverage of the three area-level covariates
#' used as sensitivity adjustments in mystery-caller access studies:
#' \itemize{
#'   \item \strong{ADI} -- Area Deprivation Index (\code{\link{adi_zcta}}),
#'   \item \strong{SVI} -- Social Vulnerability Index (\code{\link{svi_zcta}}),
#'   \item \strong{HHI} -- hospital-market Herfindahl-Hirschman Index
#'     (\code{\link{kff_hhi}}).
#' }
#'
#' Each coordinate is resolved once through the US Census Bureau geocoder
#' (\url{https://geocoding.geo.census.gov}; no key required) to its 2020 ZIP Code
#' Tabulation Area, census tract, and Metropolitan Statistical Area. ADI and SVI
#' then join on ZCTA -- which covers essentially every populated location, so
#' their coverage is limited only by whether a coordinate is present and falls in
#' a ZCTA. HHI joins on MSA and therefore remains **structurally metro-only**:
#' KFF publishes HHI for 387 metropolitan markets, so physicians outside any MSA
#' (rural/micropolitan) get \code{NA} HHI by construction, not by a matching
#' failure.
#'
#' @param data A data frame of physicians with latitude and longitude columns.
#' @param lat_col,long_col Column names holding latitude and longitude in
#'   decimal degrees (WGS84). Defaults \code{"lat"} / \code{"long"}.
#' @param which Character vector naming which covariates to attach; any of
#'   \code{"adi"}, \code{"svi"}, \code{"hhi"}. Default all three.
#' @param verbose Logical; print a per-covariate coverage summary. Default
#'   \code{TRUE}.
#'
#' @return \code{data} with geocoded keys (\code{zcta}, \code{tract},
#'   \code{msa}) and the requested covariate columns appended: \code{adi},
#'   \code{svi}, \code{hhi} (and \code{hhi_cat}). A \code{"coverage"} attribute
#'   holds the non-missing count for each covariate.
#'
#' @details
#' Geocoding is one network call per unique coordinate (duplicates are resolved
#' once and reused). Failed or out-of-US coordinates yield \code{NA} keys and
#' therefore \code{NA} covariates.
#'
#' @family data integrity
#' @seealso \code{\link{adi_zcta}}, \code{\link{svi_zcta}}, \code{\link{kff_hhi}}.
#' @examples
#' \donttest{
#' df <- data.frame(lat = 39.7392, long = -104.9903)  # Denver
#' mysterycall_assign_area_covariates(df)
#' }
#' @export
mysterycall_assign_area_covariates <- function(data,
                                               lat_col  = "lat",
                                               long_col = "long",
                                               which    = c("adi", "svi", "hhi"),
                                               verbose  = TRUE) {
  checkmate::assert_data_frame(data, min.rows = 1L)
  checkmate::assert_subset(c(lat_col, long_col), names(data))
  which <- match.arg(which, c("adi", "svi", "hhi"), several.ok = TRUE)

  lat  <- as.numeric(data[[lat_col]])
  long <- as.numeric(data[[long_col]])

  # Geocode each *unique* coordinate once, then map back to all rows.
  key   <- paste(round(long, 6), round(lat, 6), sep = "_")
  uniq  <- !duplicated(key) & !is.na(lat) & !is.na(long)
  geo_u <- Map(.mc_geocode_point, long[uniq], lat[uniq])
  names(geo_u) <- key[uniq]

  pull <- function(field) {
    out <- vapply(key, function(k) {
      g <- geo_u[[k]]
      if (is.null(g)) NA_character_ else g[[field]]
    }, character(1L), USE.NAMES = FALSE)
    out
  }
  data[["zcta"]]  <- pull("zcta")
  data[["tract"]] <- pull("tract")
  data[["msa"]]   <- pull("msa")

  cov <- integer(0L)

  if ("adi" %in% which) {
    adi_zcta <- .mc_data("adi_zcta")
    data[["adi"]] <- adi_zcta$adi[match(data[["zcta"]], adi_zcta$zcta)]
    cov[["adi"]] <- sum(!is.na(data[["adi"]]))
  }
  if ("svi" %in% which) {
    svi_zcta <- .mc_data("svi_zcta")
    data[["svi"]] <- svi_zcta$svi[match(data[["zcta"]], svi_zcta$zcta)]
    cov[["svi"]] <- sum(!is.na(data[["svi"]]))
  }
  if ("hhi" %in% which) {
    kff <- .mc_data("kff_hhi")
    mkt <- .hhi_market_key(kff$msa)
    idx <- match(.hhi_market_key(data[["msa"]]), mkt)
    data[["hhi"]]     <- kff$hhi[idx]
    data[["hhi_cat"]] <- kff$hhi_cat[idx]
    cov[["hhi"]] <- sum(!is.na(data[["hhi"]]))
  }

  attr(data, "coverage") <- cov
  if (verbose) {
    n <- nrow(data)
    for (nm in names(cov)) {
      message(sprintf("%s coverage: %d/%d (%.0f%%)",
                      toupper(nm), cov[[nm]], n, 100 * cov[[nm]] / n))
    }
  }
  data
}

#' Reverse-geocode one coordinate to ZCTA / tract / MSA
#'
#' Calls the US Census Bureau coordinate geocoder and extracts the 2020 ZCTA,
#' census tract, and Metropolitan Statistical Area. Returns \code{NA} keys on
#' any network error, non-US point, or missing input.
#'
#' @param long,lat Longitude and latitude in decimal degrees.
#' @return A list with character scalars \code{zcta}, \code{tract}, \code{msa}.
#' @family data integrity
#' @keywords internal
.mc_geocode_point <- function(long, lat) {
  na <- list(zcta = NA_character_, tract = NA_character_, msa = NA_character_)
  if (is.na(long) || is.na(lat)) return(na)
  resp <- tryCatch(
    httr::GET(
      "https://geocoding.geo.census.gov/geocoder/geographies/coordinates",
      query = list(x = long, y = lat, benchmark = "Public_AR_Current",
                   vintage = "Census2020_Current", format = "json",
                   layers = "all"),
      httr::timeout(30)
    ),
    error = function(e) NULL
  )
  if (is.null(resp) || httr::http_error(resp)) return(na)
  g <- tryCatch(
    httr::content(resp, as = "parsed", type = "application/json")$result$geographies,
    error = function(e) NULL
  )
  if (is.null(g)) return(na)
  pick <- function(layer, field) {
    r <- g[[layer]]
    if (length(r) >= 1L && !is.null(r[[1L]][[field]])) as.character(r[[1L]][[field]])
    else NA_character_
  }
  list(
    zcta  = pick("Zip Code Tabulation Areas", "GEOID"),
    tract = pick("Census Tracts", "GEOID"),
    msa   = pick("Metropolitan Statistical Areas", "BASENAME")
  )
}

#' Load a bundled package dataset by name
#'
#' @param name Dataset name, e.g. \code{"adi_zcta"}.
#' @return The dataset object.
#' @family data integrity
#' @keywords internal
.mc_data <- function(name) {
  e <- new.env()
  utils::data(list = name, package = "mysterycall", envir = e)
  get(name, envir = e)
}
