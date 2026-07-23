#' Social Vulnerability Index (SVI) by ZCTA
#'
#' National CDC/ATSDR Social Vulnerability Index for every US ZIP Code
#' Tabulation Area (ZCTA), computed from American Community Survey (ACS) 5-year
#' estimates with \pkg{findSVI} (\code{findSVI::find_svi()}), which reproduces
#' the CDC/ATSDR SVI theme and overall percentile ranks. Keyed on ZCTA (which
#' corresponds closely to a mailing ZIP), it joins to a physician's practice ZIP
#' directly, without a tract crosswalk.
#'
#' Values are national percentile ranks in \code{[0, 1]}; higher = more socially
#' vulnerable. The overall index (\code{svi}) is the rank of the sum of the four
#' theme ranks. About 2% of ZCTAs have \code{NA} (ACS input suppressed or zero
#' population).
#'
#' @format A data frame with about 33,800 rows and 7 columns:
#' \describe{
#'   \item{zcta}{Five-digit ZIP Code Tabulation Area, as a character string
#'     (leading zeros preserved).}
#'   \item{svi}{Overall SVI percentile rank (CDC \code{RPL_themes}), 0-1;
#'     higher = more vulnerable.}
#'   \item{svi_socioeconomic}{Theme 1 -- Socioeconomic Status percentile rank
#'     (CDC \code{RPL_theme1}).}
#'   \item{svi_household}{Theme 2 -- Household Characteristics percentile rank
#'     (CDC \code{RPL_theme2}).}
#'   \item{svi_minority}{Theme 3 -- Racial and Ethnic Minority Status percentile
#'     rank (CDC \code{RPL_theme3}).}
#'   \item{svi_housing_transport}{Theme 4 -- Housing Type and Transportation
#'     percentile rank (CDC \code{RPL_theme4}).}
#'   \item{year}{ACS 5-year vintage end year (2022 = 2018-2022).}
#' }
#'
#' @details
#' Regenerate with \code{data-raw/svi_zcta.R} (requires a Census API key in
#' \code{CENSUS_API_KEY}). Ranks are national; because \pkg{findSVI} recomputes
#' them from ACS rather than downloading the CDC release, small differences from
#' the official CDC ZCTA tables are possible, chiefly at suppressed or
#' low-population areas.
#'
#' @source American Community Survey 5-year estimates (US Census Bureau),
#'   summarised by the CDC/ATSDR Social Vulnerability Index methodology as
#'   implemented in \pkg{findSVI}. See
#'   \url{https://www.atsdr.cdc.gov/placeandhealth/svi/} for the reference
#'   methodology.
#'
#' @examples
#' data(svi_zcta)
#'
#' # Attach SVI to study physicians by practice ZIP (as a 5-digit character)
#' # study$zcta <- sprintf("%05s", study$practice_zip)
#' # study <- merge(study, svi_zcta[, c("zcta", "svi")], by = "zcta", all.x = TRUE)
#'
#' @seealso \code{\link{adi_zcta}} for the companion Area Deprivation Index at
#'   the same geography.
#' @keywords dataset
#' @family datasets
#' @name svi_zcta
#' @docType data
NULL
