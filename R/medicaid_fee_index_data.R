#' KFF Medicaid-to-Medicare Fee Index (All Services), 2024
#'
#' State-level Kaiser Family Foundation (KFF) Medicaid-to-Medicare Fee Index for
#' 2024 (All Services) covering all 50 states plus the District of Columbia. The
#' index is the ratio of what a state's Medicaid program pays to what Medicare
#' pays for the same set of services: a value below 1 means Medicaid reimburses
#' below Medicare, and above 1 means it reimburses more. Because low Medicaid
#' reimbursement is a leading reason clinicians decline Medicaid patients, this
#' index is a natural state-level covariate for insurance-based access
#' disparities in mystery-caller studies.
#'
#' This is a newer, complete single-vintage source (2024, all 51 jurisdictions)
#' that supersedes the partial hard-coded values inside
#' [mysterycall_medicaid_fee_index()].
#'
#' @format A data frame with 51 rows (50 states + DC) and 5 columns:
#' \describe{
#'   \item{state}{Character. Full state (or DC) name.}
#'   \item{state_abb}{Character. Two-letter USPS abbreviation.}
#'   \item{fee_index}{Numeric. 2024 All-Services Medicaid-to-Medicare fee index.
#'     `NA` for Tennessee, which has no comprehensive fee-for-service Medicaid
#'     fee schedule to index.}
#'   \item{year}{Integer. Vintage of the estimate (2024).}
#'   \item{at_or_above_medicare}{Logical. `TRUE` when `fee_index >= 1` (Medicaid
#'     pays at least as much as Medicare); `NA` for Tennessee.}
#' }
#' The national All-Services average (0.75) is stored on the object as
#' `attr(medicaid_fee_index, "national_average")`.
#'
#' @source Kaiser Family Foundation, "Medicaid-to-Medicare Fee Index" (All
#'   Services), 2024.
#'   \url{https://www.kff.org/medicaid/state-indicator/medicaid-to-medicare-fee-index/}
#'
#' @examples
#' data(medicaid_fee_index)
#'
#' # States reimbursing at or above Medicare
#' medicaid_fee_index[which(medicaid_fee_index$at_or_above_medicare),
#'                    c("state", "fee_index")]
#'
#' # Merge onto study data by state abbreviation
#' # study <- merge(study, medicaid_fee_index[, c("state_abb", "fee_index")],
#' #                by = "state_abb", all.x = TRUE)
#'
#' attr(medicaid_fee_index, "national_average")
#'
#' @seealso [mysterycall_medicaid_fee_index()] for the lookup-function form;
#'   [medicaid_expansion] and [kff_hhi] for other state/market policy
#'   covariates.
#' @keywords dataset
#' @family datasets
#' @name medicaid_fee_index
#' @docType data
NULL
