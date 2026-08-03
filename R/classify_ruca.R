#' Classify RUCA codes into Urban / Suburban / Rural
#'
#' @name mysterycall_classify_ruca
NULL


#' Classify RUCA codes into Urban, Suburban, or Rural
#'
#' The Rural-Urban Commuting Area (RUCA) classification system assigns numeric
#' codes to ZIP codes based on commuting patterns and population density. This
#' function maps those numeric codes to three categories used in healthcare
#' access research:
#'
#' | RUCA code | Category |
#' |---|---|
#' | 1-3  | Urban    |
#' | 4-6  | Suburban |
#' | 7-10 | Rural    |
#'
#' The 2010-vintage RUCA codes are the standard crosswalk applied through 2023
#' in CMS and HRSA analyses. Although newer ACS-based updates exist, the 2010
#' vintage remains the most widely cited in peer-reviewed healthcare access
#' research.
#'
#' **No RUCA crosswalk is bundled with this package.** This function only recodes
#' a numeric `ruca_code` you supply; obtaining the crosswalk is up to you. ZIP-
#' and tract-level files are available from USDA ERS
#' (<https://www.ers.usda.gov/data-products/rural-urban-commuting-area-codes>).
#' Join your data to the crosswalk first, then pass the resulting `ruca_code`
#' column to this function.
#'
#' Mind the vintage when you do. The 2010 RUCA files are keyed to 2010 ZIP codes
#' and 2010 census tracts, whereas geographies produced by
#' [mysterycall_geocode_address()] and [mysterycall_assign_area_covariates()] are
#' 2020-vintage. Joining 2020 tract GEOIDs to a 2010 RUCA tract file silently
#' mismatches wherever tracts were split or merged between censuses. Either use a
#' 2020-vintage RUCA file, or join on ZIP rather than tract.
#'
#' @param ruca_code Numeric vector of RUCA codes (typically integer or decimal,
#'   e.g. 1, 2, 3.1, 10.6). `NA` values are returned as `na_label`.
#' @param urban_max Numeric. RUCA codes `<= urban_max` are classified as Urban.
#'   Default `3`.
#' @param suburban_max Numeric. RUCA codes `> urban_max` and `<= suburban_max`
#'   are classified as Suburban. Default `6`.
#' @param labels Character vector of length 3 giving the labels for Urban,
#'   Suburban, and Rural categories in that order.
#'   Default `c("Urban", "Suburban", "Rural")`.
#' @param na_label Character scalar returned for `NA` inputs.
#'   Default `"Unknown"`.
#' @param as_factor Logical. When `TRUE` the result is returned as an ordered
#'   factor with levels `c(labels, na_label)`. Default `FALSE`.
#'
#' @return Character vector the same length as `ruca_code` with values from
#'   `labels` (`"Urban"`, `"Suburban"`, `"Rural"` by default) or `na_label`
#'   (`"Unknown"` by default) for `NA` inputs.  When `as_factor = TRUE`,
#'   returns an ordered factor with levels `c(labels, na_label)`.
#'
#' @seealso [mysterycall_assign_region()], [mysterycall_classify_practice_setting()],
#'   [mysterycall_classify_medical_school()] for related provider characterizations.
#' @family provider characteristics
#' @export
#'
#' @examples
#' codes <- c(1, 2, 4, 5, 7, 10, NA)
#' mysterycall_classify_ruca(codes)
#' # [1] "Urban"   "Urban"   "Suburban" "Suburban" "Rural"  "Rural"  "Unknown"
#'
#' mysterycall_classify_ruca(codes, as_factor = TRUE)
mysterycall_classify_ruca <- function(ruca_code,
                                       urban_max    = 3,
                                       suburban_max = 6,
                                       labels       = c("Urban", "Suburban", "Rural"),
                                       na_label     = "Unknown",
                                       as_factor    = FALSE) {

  if (!is.numeric(ruca_code)) {
    stop("`ruca_code` must be a numeric vector.", call. = FALSE)
  }
  if (!is.numeric(urban_max)    || length(urban_max)    != 1L || is.na(urban_max)) {
    stop("`urban_max` must be a single number.", call. = FALSE)
  }
  if (!is.numeric(suburban_max) || length(suburban_max) != 1L || is.na(suburban_max)) {
    stop("`suburban_max` must be a single number.", call. = FALSE)
  }
  if (suburban_max <= urban_max) {
    stop("`suburban_max` must be greater than `urban_max`.", call. = FALSE)
  }
  if (!is.character(labels) || length(labels) != 3L) {
    stop("`labels` must be a character vector of length 3.", call. = FALSE)
  }
  if (!is.character(na_label) || length(na_label) != 1L) {
    stop("`na_label` must be a single character string.", call. = FALSE)
  }

  result <- ifelse(
    is.na(ruca_code), na_label,
    ifelse(ruca_code <= urban_max,    labels[[1L]],
    ifelse(ruca_code <= suburban_max, labels[[2L]],
                                      labels[[3L]]))
  )

  if (as_factor) {
    all_levels <- c(labels, na_label)
    result <- factor(result, levels = all_levels, ordered = TRUE)
  }

  result
}
