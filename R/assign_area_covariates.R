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

  # A vintage roll or layer rename produces geocoder responses that parse fine
  # but carry no ZCTA, which would otherwise surface as uniformly NA covariates
  # and read as ordinary geocoding loss. Distinguish the two: if every point the
  # geocoder answered for lacks a ZCTA, the layer is missing, not the data.
  n_ok <- sum(vapply(geo_u, function(g) isTRUE(g$ok), logical(1L)))
  if (n_ok > 0L && all(is.na(data[["zcta"]]))) {
    warning(
      sprintf(paste0(
        "Census geocoder returned %d response(s) at vintage '%s' but no ZIP Code ",
        "Tabulation Area layer, so ADI/SVI will be entirely NA. The layer was ",
        "most likely renamed by a vintage change; see .mc_geo_layer()."),
        n_ok, .MC_CENSUS_VINTAGE),
      call. = FALSE
    )
  }

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

#' Census geocoder benchmark and vintage used package-wide
#'
#' Pinned deliberately. \code{"Current_Current"} would track whatever the Census
#' Bureau currently serves, so a Bureau-side vintage roll would silently change
#' the geography behind every result while the bundled ZCTA-keyed datasets
#' (\code{\link{adi_zcta}}, \code{\link{svi_zcta}}, \code{\link{zcta_tract_xwalk}})
#' stayed on 2020 boundaries. Pinning keeps geocoded keys and bundled data on the
#' same vintage. Change these two constants together, and only alongside
#' regenerated 2030-vintage datasets.
#'
#' @format Character scalars.
#' @family data integrity
#' @keywords internal
#' @name mc-census-vintage
.MC_CENSUS_BENCHMARK <- "Public_AR_Current"

#' @rdname mc-census-vintage
.MC_CENSUS_VINTAGE <- "Census2020_Current"

#' Resolve a Census geography layer whose name varies by vintage
#'
#' The geocoder renames layers between vintages -- the ZCTA layer is
#' \code{"Zip Code Tabulation Areas"} under \code{Census2020_Current} but
#' \code{"2020 Census ZIP Code Tabulation Areas"} under \code{Current_Current}.
#' Matching an exact string therefore couples the parser to one vintage, and the
#' failure mode is a silent \code{NA} rather than an error. Match on a substring
#' instead so a rename degrades to nothing.
#'
#' @param g Parsed \code{result$geographies} list from the geocoder.
#' @param pattern Case-insensitive fixed substring identifying the layer.
#' @return The matching layer (a list), or \code{NULL} when absent.
#' @family data integrity
#' @keywords internal
.mc_geo_layer <- function(g, pattern) {
  hit <- grep(pattern, names(g), ignore.case = TRUE, fixed = FALSE)
  if (!length(hit)) return(NULL)
  g[[hit[1L]]]
}

#' Reverse-geocode one coordinate to ZCTA / tract / MSA
#'
#' Calls the US Census Bureau coordinate geocoder at the pinned vintage
#' (\code{.MC_CENSUS_VINTAGE}) and extracts the ZCTA, census tract, and
#' Metropolitan Statistical Area. Returns \code{NA} keys on any network error,
#' non-US point, or missing input.
#'
#' @param long,lat Longitude and latitude in decimal degrees.
#' @return A list with character scalars \code{zcta}, \code{tract}, \code{msa},
#'   plus logical \code{ok} recording whether the geocoder returned a parseable
#'   geography set. \code{ok = TRUE} with an \code{NA} key means the layer was
#'   missing or the point fell outside it -- distinguishable from a network
#'   failure, which yields \code{ok = FALSE}.
#' @family data integrity
#' @keywords internal
.mc_geocode_point <- function(long, lat) {
  na <- list(zcta = NA_character_, tract = NA_character_, msa = NA_character_,
             ok = FALSE)
  if (is.na(long) || is.na(lat)) return(na)
  resp <- tryCatch(
    httr::GET(
      "https://geocoding.geo.census.gov/geocoder/geographies/coordinates",
      query = list(x = long, y = lat, benchmark = .MC_CENSUS_BENCHMARK,
                   vintage = .MC_CENSUS_VINTAGE, format = "json",
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
  pick <- function(pattern, field) {
    r <- .mc_geo_layer(g, pattern)
    if (length(r) >= 1L && !is.null(r[[1L]][[field]])) as.character(r[[1L]][[field]])
    else NA_character_
  }
  list(
    zcta  = pick("zip code tabulation area", "GEOID"),
    tract = pick("census tract",             "GEOID"),
    msa   = pick("metropolitan statistical area", "BASENAME"),
    ok    = TRUE
  )
}

#' Warn when an ACS year predates the boundary vintage of the bundled datasets
#'
#' The 2020 Census redrew tracts, block groups, and ZCTAs. ACS releases moved
#' onto those boundaries over the 2021--2022 vintages, and the exact switch
#' differs by geography. The datasets bundled here (\code{\link{adi_zcta}},
#' \code{\link{svi_zcta}}, \code{\link{zcta_tract_xwalk}}) are built on the
#' 2018--2022 ACS and are therefore 2020-vintage throughout.
#'
#' Pulling an earlier ACS year at a boundary-sensitive geography and joining the
#' result to those datasets -- or to geocoded keys, which are also 2020-vintage
#' -- mismatches wherever a tract or ZCTA was split, merged, or renumbered. The
#' join does not error; it silently drops to \code{NA}. This warns instead.
#'
#' Silence with \code{options(mysterycall.quiet_vintage = TRUE)} when the
#' mismatch is intended (for example, a deliberately historical series).
#'
#' @param year Integer ACS end-year requested.
#' @param geography Character scalar geography passed to tidycensus.
#' @param fn Character scalar naming the calling function, for the message.
#' @return Invisibly \code{NULL}; called for the side effect.
#' @family data integrity
#' @keywords internal
.mc_check_acs_vintage <- function(year, geography, fn) {
  if (isTRUE(getOption("mysterycall.quiet_vintage", FALSE))) return(invisible(NULL))
  if (!is.numeric(year) || length(year) != 1L || is.na(year)) return(invisible(NULL))
  # Geographies the 2020 Census redrew. State/county/CBSA codes are stable and
  # need no warning.
  sensitive <- c("tract", "block group", "zcta",
                 "zip code tabulation area", "county subdivision")
  if (!tolower(geography) %in% sensitive) return(invisible(NULL))
  if (year >= 2022L) return(invisible(NULL))
  warning(
    sprintf(paste0(
      "%s: ACS year %d at geography '%s' may be on 2010-vintage boundaries, ",
      "while this package's bundled ZCTA datasets and geocoded keys are ",
      "2020-vintage (2018-2022 ACS). Joining across that boundary silently ",
      "yields NA for split, merged, or renumbered areas. Use year >= 2022, ",
      "join on a stable geography, or set ",
      "options(mysterycall.quiet_vintage = TRUE) if this is intended."),
      fn, as.integer(year), geography),
    call. = FALSE
  )
  invisible(NULL)
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
