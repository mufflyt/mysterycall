#' KFF Hospital-Market Concentration (HHI) by Metropolitan Area, 2024
#'
#' Kaiser Family Foundation (KFF) published Herfindahl-Hirschman Index (HHI) of
#' hospital-system market concentration for 387 U.S. metropolitan statistical
#' areas (MSAs) in 2024, together with the systems controlling each market. Use
#' it as a ready-made market-concentration covariate for insurance-access
#' analyses: in a highly concentrated market a dominant system has more latitude
#' to steer scheduling by payer.
#'
#' HHI ranges 0-10000 (sum of squared percent market shares). The Department of
#' Justice / Federal Trade Commission Horizontal Merger Guidelines classify
#' markets as un-concentrated (< 1000), moderately concentrated (1000-1800), and
#' highly concentrated (> 1800); those cut-points define `hhi_cat`.
#'
#' @format A data frame with 387 rows (one per MSA) and 10 columns:
#' \describe{
#'   \item{msa}{Character. MSA name in `"City, ST"` form (state suffix may be
#'     multi-state, e.g. `"New York, NY-NJ-PA"`).}
#'   \item{state_abb}{Character. Two-letter USPS abbreviation of the MSA's first
#'     principal state, parsed from `msa`.}
#'   \item{residents_2024}{Integer. MSA population in 2024.}
#'   \item{market_structure}{Character. KFF's summary of how many systems control
#'     the market, e.g. `"1 system has 100% market share"`,
#'     `"4+ systems have 100% market share"`.}
#'   \item{hhi}{Numeric. Herfindahl-Hirschman Index in 2024 (0-10000).}
#'   \item{largest_system}{Character. Name of the largest health system.}
#'   \item{largest_system_share}{Numeric. Largest system's market share as a
#'     proportion (0-1).}
#'   \item{second_largest_system}{Character. Name of the second-largest system,
#'     or `NA` when a single system holds 100%.}
#'   \item{second_largest_system_share}{Numeric. Second-largest system's market
#'     share (0-1), or `NA`.}
#'   \item{hhi_cat}{Ordered factor: `"un-concentrated"` < `"moderate"` <
#'     `"high"` (DOJ/FTC 1000/1800 thresholds).}
#' }
#'
#' @source Kaiser Family Foundation, "KFF HHI Dataset" (per-MSA HHI, 2024),
#'   via the `mufflyt/consolidation` study repository. See the KFF hospital-
#'   consolidation analyses at \url{https://www.kff.org/}.
#'
#' @examples
#' data(kff_hhi)
#'
#' # Concentration mix across metros
#' table(kff_hhi$hhi_cat)
#'
#' # Most concentrated large metros
#' big <- kff_hhi[kff_hhi$residents_2024 > 1e6, ]
#' head(big[order(-big$hhi), c("msa", "hhi", "largest_system")])
#'
#' # Attach onto office data with a CBSA crosswalk via mysterycall_add_hhi();
#' # kff_hhi is the packaged equivalent of mysterycall_read_kff_hhi()'s output.
#'
#' @seealso [mysterycall_add_hhi()] to join HHI onto office data and derive
#'   `hhi_k` / `hhi_cat`; [mysterycall_read_kff_hhi()] to read/crosswalk the raw
#'   KFF workbook; [medicaid_expansion] for another state-policy covariate.
#' @keywords dataset
#' @family datasets
#' @name kff_hhi
#' @docType data
NULL
