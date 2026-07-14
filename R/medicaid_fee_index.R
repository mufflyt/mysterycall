#' Retrieve State-Level Medicaid-to-Medicare Fee Index Ratios
#'
#' Looks up the Kaiser Family Foundation (KFF) Medicaid-to-Medicare fee index for
#' a vector of state abbreviations. The index is the ratio of what a state's
#' Medicaid program pays to what Medicare pays for the same services; a value
#' below 1 means Medicaid reimburses below Medicare. Values are read from the
#' packaged [medicaid_fee_index] dataset (2024, All Services; all 50 states + DC)
#' so the function and the data cannot drift apart.
#'
#' @param states Character vector of two-letter state abbreviations (e.g.
#'   `c("FL", "NJ", "CA")`). Case- and whitespace-insensitive.
#' @param fallback Numeric scalar used for states not present in the dataset
#'   (invalid codes, territories) and for Tennessee, whose 2024 index is `NA`
#'   (no comprehensive fee-for-service Medicaid fee schedule). Defaults to the
#'   national All-Services average (0.75). Pass `NA` to preserve genuine
#'   missingness instead of filling it.
#' @return A numeric vector, the same length and order as `states`, of fee index
#'   ratios (with `fallback` substituted as described).
#' @export
#' @seealso [medicaid_fee_index] for the underlying dataset.
#' @examples
#' mysterycall_medicaid_fee_index(c("FL", "NJ", "CA"))
#'
#' # Preserve NA for Tennessee / unknown states instead of the national average
#' mysterycall_medicaid_fee_index(c("TN", "CA", "ZZ"), fallback = NA)
mysterycall_medicaid_fee_index <- function(states, fallback = NULL) {
  if (!is.character(states)) {
    states <- as.character(states)
  }

  medicaid_fee_index <- NULL  # for R CMD check; populated by utils::data()
  utils::data("medicaid_fee_index", package = "mysterycall", envir = environment())

  if (is.null(fallback)) {
    fallback <- attr(medicaid_fee_index, "national_average")
    if (is.null(fallback)) fallback <- 0.75
  }
  if (length(fallback) != 1L || !(is.numeric(fallback) || is.na(fallback))) {
    stop("`fallback` must be a single numeric value or NA.", call. = FALSE)
  }

  lut <- stats::setNames(medicaid_fee_index$fee_index, medicaid_fee_index$state_abb)
  clean <- toupper(trimws(states))
  ratios <- unname(lut[clean])
  # Fill both unrecognised states and NA-valued states (Tennessee) with fallback.
  ratios[is.na(ratios)] <- fallback
  ratios
}
