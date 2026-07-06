#' Retrieve State-Level Medicaid-to-Medicare Fee Index Ratios
#'
#' Returns the Kaiser Family Foundation (KFF) Medicaid-to-Medicare fee index ratio
#' for a vector of state abbreviations. The index represents the ratio of Medicaid
#' reimbursement to Medicare reimbursement for primary care and specialty services.
#'
#' @param states Character vector of two-letter state abbreviations (e.g. c("FL", "NJ", "PA")).
#' @return A numeric vector of fee index ratios. Missing or invalid states default to 0.65 (national average).
#' @export
#' @examples
#' mysterycall_medicaid_fee_index(c("FL", "NJ", "CA"))
mysterycall_medicaid_fee_index <- function(states) {
  # Dictionary mapping state abbreviations to KFF Medicaid-to-Medicare fee index ratios
  fee_map <- c(
    "AL" = 0.69, "AZ" = 0.78, "CA" = 0.51, "CO" = 0.68, "CT" = 0.65, "DC" = 0.90, "DE" = 0.75, 
    "FL" = 0.66, "GA" = 0.64, "IL" = 0.53, "IN" = 0.62, "MA" = 0.70, "MD" = 0.68, "MI" = 0.61, 
    "MN" = 0.60, "MO" = 0.66, "NC" = 0.70, "NJ" = 0.48, "NV" = 0.67, "NY" = 0.58, "OH" = 0.63, 
    "PA" = 0.65, "TN" = 0.68, "TX" = 0.72, "UT" = 0.71, "VA" = 0.64, "WI" = 0.58
  )
  
  clean_states <- toupper(trimws(states))
  ratios <- fee_map[clean_states]
  ratios[is.na(ratios)] <- 0.65 # Fallback to national mean
  names(ratios) <- states
  return(unname(ratios))
}
