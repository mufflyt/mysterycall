#' Medicaid Expansion Status by State
#'
#' Adoption status of the Affordable Care Act (ACA) Medicaid expansion for all
#' 50 US states and the District of Columbia, including the date each state
#' expanded and edge-case notes for Wisconsin and Georgia.
#'
#' The ACA permitted states to expand Medicaid eligibility to adults with
#' incomes up to 138% of the Federal Poverty Level (FPL). Expansion is
#' voluntary; as of June 2025, 40 states plus DC have adopted full expansion.
#' Ten states have not: Alabama, Florida, Georgia, Kansas, Mississippi, South
#' Carolina, Tennessee, Texas, Wisconsin, and Wyoming.
#'
#' @format A data frame with 51 rows (50 states + DC) and 6 columns:
#' \describe{
#'   \item{state}{Full state name (character).}
#'   \item{state_abb}{Two-letter USPS abbreviation (character).}
#'   \item{expanded}{Logical. \code{TRUE} if the state adopted full ACA
#'     Medicaid expansion to 138\% FPL.}
#'   \item{expansion_date}{Date the expansion took effect, or \code{NA} for
#'     non-expansion states.}
#'   \item{status}{Character. \code{"Expanded"} or \code{"Not Expanded"}.}
#'   \item{notes}{Character. Edge-case clarifications for Wisconsin (BadgerCare
#'     waiver, 100\% FPL) and Georgia (Pathways partial expansion). \code{NA}
#'     for all other states.}
#' }
#'
#' @details
#' **Wisconsin** covers adults to 100\% FPL through the BadgerCare waiver
#' programme but did not adopt the ACA Medicaid expansion to 138\% FPL;
#' \code{expanded} is \code{FALSE}.
#'
#' **Georgia** launched "Georgia Pathways" in July 2023, a partial
#' work-requirement expansion programme, but did not adopt the full ACA
#' expansion; \code{expanded} is \code{FALSE}.
#'
#' @source Kaiser Family Foundation (KFF), "Status of State Medicaid Expansion
#'   Decisions: Interactive Map," verified June 2025.
#'   \url{https://www.kff.org/medicaid/issue-brief/status-of-state-medicaid-expansion-decisions-interactive-map/}
#'
#' @examples
#' data(medicaid_expansion)
#'
#' # Count expansion vs. non-expansion states
#' table(medicaid_expansion$status)
#'
#' # List non-expansion states
#' medicaid_expansion[!medicaid_expansion$expanded, c("state", "state_abb")]
#'
#' # Merge with study data by state abbreviation
#' # study_data <- merge(study_data, medicaid_expansion[, c("state_abb", "expanded", "status")],
#' #                     by = "state_abb", all.x = TRUE)
#'
#' @seealso \code{\link{acog_districts}} for ACOG regional groupings that can
#'   be combined with expansion status for subgroup analyses.
#' @keywords dataset
#' @family datasets
#' @name medicaid_expansion
#' @docType data
NULL
