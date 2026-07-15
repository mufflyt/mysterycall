#' State-level FIPS codes
#'
#' This dataset maps U.S. states (plus the District of Columbia) to their
#' Federal Information Processing Standards (FIPS) state codes, which are
#' essential for merging state-level spatial and census data in healthcare
#' access research. The object is **state-level only**; it does not contain
#' county rows, so county-level merges are not supported by this object.
#'
#' @format A data frame with 51 rows (50 states plus the District of Columbia)
#'   and 3 variables:
#' \describe{
#'   \item{state}{Two-letter postal abbreviation (e.g. `"AL"`).}
#'   \item{state_code}{Two-digit state FIPS code, stored as character so
#'     leading zeros are preserved (e.g. `"01"`).}
#'   \item{state_name}{Full state name (e.g. `"Alabama"`).}
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
