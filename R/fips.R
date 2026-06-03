#' Data of FIPS codes
#'
#' This dataset maps state and county names to Federal Information Processing 
#' Standards (FIPS) codes, which are essential for merging spatial and census
#' data in healthcare access research.
#'
#' @format A tibble with 3142 rows and 10 variables containing Federal
#'   Information Processing Standards (FIPS) codes for states and counties:
#' \describe{
#'   \item{state}{Two-letter postal abbreviation.}
#'   \item{state_name}{Full state name.}
#'   \item{state_fips}{Two-digit state FIPS code.}
#'   \item{county_fips}{Three-digit county FIPS code.}
#'   \item{fips}{Combined five-digit state and county code.}
#'   \item{class}{Geography class indicator.}
#'   \item{county}{County name.}
#'   \item{county_ansi}{County ANSI code.}
#'   \item{county_short}{Simplified county name.}
#'   \item{state_ansi}{State ANSI code.}
#' }
#' @source \url{https://github.com/kjhealy/fips-codes/blob/master/state_and_county_fips_master.csv}
#' @examples
#' data(fips)
#' head(fips)
#'
#' @family datasets
#' @name fips
#' @docType data
NULL
