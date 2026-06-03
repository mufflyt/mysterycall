#' City/state latitude and longitude reference data
#'
#' @description
#' Latitude/longitude lookup table assembled from a public GitHub gist for
#' aligning caller workbooks with geospatial tooling.
#'
#' @return A tibble mapping U.S. cities and states to their latitude and
#'   longitude coordinates.
#'
#' @format A tibble with four variables:
#' \describe{
#'   \item{city}{City name.}
#'   \item{state}{Two-letter postal state abbreviation.}
#'   \item{lat}{Latitude in decimal degrees.}
#'   \item{long}{Longitude in decimal degrees.}
#' }
#'
#' @source \url{https://gist.githubusercontent.com/steinbring/e5417af6d1bb95742555866c84e3f91d/raw/186b532887c9738687860aeae5de7a7b2a0ed233/cityStateToLatLong.csv}
#' @examples
#' data(city_state_to_lat_long)
#' head(city_state_to_lat_long)
#'
#' @family datasets
#' @name city_state_to_lat_long
#' @docType data
NULL
