#' Area Deprivation Index (ADI) by ZCTA
#'
#' National Area Deprivation Index for every US ZIP Code Tabulation Area (ZCTA),
#' computed from American Community Survey (ACS) 5-year estimates with
#' \pkg{sociome} (\code{sociome::get_adi()}), which reproduces the Singh ADI via
#' the Kolak et al. three-factor decomposition. Because it is keyed on ZCTA
#' (which corresponds closely to a mailing ZIP), it joins to a physician's
#' practice ZIP directly, without a tract crosswalk.
#'
#' The index is national and relative: higher values indicate greater
#' neighbourhood socioeconomic deprivation. \pkg{sociome} scales the linear ADI
#' to approximately mean 100 / standard deviation 20 across the areas supplied
#' (here, all US ZCTAs). Roughly 3% of ZCTAs have \code{NA} ADI because the ACS
#' suppressed one or more input variables for that area.
#'
#' @format A data frame with about 33,800 rows and 6 columns:
#' \describe{
#'   \item{zcta}{Five-digit ZIP Code Tabulation Area, as a character string
#'     (leading zeros preserved).}
#'   \item{adi}{National linear Area Deprivation Index; higher = more deprived,
#'     roughly mean 100 / SD 20. \code{NA} where ACS inputs were suppressed.}
#'   \item{adi_financial_strength}{Financial Strength factor score (one of the
#'     three Kolak et al. ADI sub-domains).}
#'   \item{adi_economic_hardship}{Economic Hardship and Inequality factor
#'     score.}
#'   \item{adi_education}{Educational Attainment factor score.}
#'   \item{year}{ACS 5-year vintage end year (2022 = 2018-2022).}
#' }
#'
#' @details
#' Regenerate with \code{data-raw/adi_zcta.R} (requires a Census API key in
#' \code{CENSUS_API_KEY}). Advancing the ACS vintage or the ZCTA set will change
#' the relative scaling, so ADI values are comparable only within a single
#' build.
#'
#' @source American Community Survey 5-year estimates (US Census Bureau), summarised
#'   by the Area Deprivation Index of Singh (2003) as implemented in
#'   \pkg{sociome}: Kolak, Bhatt, Park, Padron & Molefe (2020),
#'   "Quantification of Neighborhood-Level Social Determinants of Health in the
#'   Continental United States," \emph{JAMA Network Open} 3(1):e1919928.
#'
#' @examples
#' data(adi_zcta)
#'
#' # Attach ADI to study physicians by practice ZIP (as a 5-digit character)
#' # study$zcta <- sprintf("%05s", study$practice_zip)
#' # study <- merge(study, adi_zcta[, c("zcta", "adi")], by = "zcta", all.x = TRUE)
#'
#' @seealso \code{\link{svi_zcta}} for the companion CDC Social Vulnerability
#'   Index at the same geography.
#' @keywords dataset
#' @family datasets
#' @name adi_zcta
#' @docType data
NULL
