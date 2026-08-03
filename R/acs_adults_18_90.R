#' Get ACS Adult Population (Ages 18-90, Both Sexes) by Census Tract
#'
#' Downloads ACS B01001 (Sex by Age) data for adults aged 18-89 years,
#' separated by sex. Returns male, female, and total adult populations with
#' proper MOE propagation using the Census Bureau sum-of-squares formula:
#' \eqn{MOE_{sum} = \sqrt{\sum MOE_i^2}}.
#'
#' Age groups included: 18-19, 20, 21, 22-24, 25-29, 30-34, 35-39, 40-44,
#' 45-49, 50-54, 55-59, 60-61, 62-64, 65-66, 67-69, 70-74, 75-79, 80-84,
#' 85-89.
#'
#' @param year Integer. ACS 5-year survey year (2009-2023). Required - no
#'   default to ensure reproducibility.
#' @param states Character vector of two-letter state abbreviations, or
#'   \code{NULL} to download all states (slow, ~45 min). Default: \code{NULL}.
#' @param verbose Logical. Print progress messages. Default: \code{TRUE}.
#'
#' @return Tibble with columns:
#'   \describe{
#'     \item{GEOID}{Census tract ID (11-digit string).}
#'     \item{men_18_90}{Sum of male population aged 18-89.}
#'     \item{men_18_90_moe}{Margin of error for males (90% CI).}
#'     \item{women_18_90}{Sum of female population aged 18-89.}
#'     \item{women_18_90_moe}{Margin of error for females (90% CI).}
#'     \item{adults_18_90}{Total adult population (male + female).}
#'     \item{adults_18_90_moe}{Propagated total margin of error (90% CI).}
#'   }
#'
#' @note MOE propagation follows Census Bureau ACS Handbook Appendix 3.
#'   All MOE values are at 90% confidence level (Census standard).
#'   This function is more efficient than calling \code{mysterycall_get_acs_women_18_90()}
#'   separately as it makes a single Census API call.
#'
#' @examplesIf interactive()
#' co_adults <- mysterycall_get_acs_adults_18_90(year = 2022, states = "CO")
#' west_coast <- mysterycall_get_acs_adults_18_90(year = 2022, states = c("CA", "OR", "WA"))
#'
#' @importFrom dplyr filter mutate select across all_of pull
#' @importFrom stringr str_detect
#' @family census
#' @export
mysterycall_get_acs_adults_18_90 <- function(year = NULL, states = NULL, verbose = TRUE) {
  if (!requireNamespace("tidycensus", quietly = TRUE)) {
    stop("Package 'tidycensus' is required", call. = FALSE)
  }
  if (is.null(year)) {
    stop("year parameter is required for mysterycall_get_acs_adults_18_90().\n",
         "Specify the ACS year explicitly (e.g., year = 2022L).")
  }
  if (year < 2009 || year > 2023) {
    stop(sprintf("Invalid year: %d. ACS 5-year data available for 2009-2023.", year))
  }
  # This function always pulls tract-level data, which the 2020 Census redrew.
  .mc_check_acs_vintage(year, "tract", "mysterycall_get_acs_adults_18_90()")

  if (verbose) {
    message("")
    message("=========================================================")
    message("ACS ADULT POPULATION DATA DOWNLOAD (AGES 18-90, BOTH SEXES)")
    message("=========================================================")
    message(sprintf("Year:       ACS %d (5-year estimates)", year))
    message(sprintf("Geography:  Census tracts"))
    message(sprintf("States:     %s", ifelse(is.null(states), "All US (50 states + DC + PR)",
                                           paste(states, collapse = ", "))))
    message(sprintf("Variables:  B01001 (Sex by Age) - Male & Female 18-89 years"))
    message("")
  }

  if (verbose) message("Loading Census variable dictionary...")
  vars <- tryCatch(
    tidycensus::load_variables(year = year, dataset = "acs5", cache = TRUE),
    error = function(e) stop(sprintf(
      "Census API Error (variable dictionary):\n%s\n\nTroubleshooting:\n  Check CENSUS_API_KEY env var\n  Verify year %d has published ACS 5-year data",
      e$message, year
    ))
  )

  adult_vars <- dplyr::filter(vars,
    stringr::str_detect(name, "^B01001_"),
    stringr::str_detect(label, "(Male:|Female:)"),
    stringr::str_detect(label,
      paste0("(18 and 19 years|20 years|21 years|22 to 24 years|25 to 29 years|",
             "30 to 34 years|35 to 39 years|40 to 44 years|45 to 49 years|",
             "50 to 54 years|55 to 59 years|60 and 61 years|62 to 64 years|",
             "65 and 66 years|67 to 69 years|70 to 74 years|75 to 79 years|",
             "80 to 84 years|85 years)")),
    !stringr::str_detect(label, "(Under 5|5 to 9|10 to 14|15 to 17)")
  )
  var_ids <- adult_vars$name

  if (verbose) {
    message(sprintf("Identified %d age group variables (%d male + %d female)",
      length(var_ids),
      sum(stringr::str_detect(adult_vars$label, "Male")),
      sum(stringr::str_detect(adult_vars$label, "Female"))))
    message("Calling Census API (this may take a few minutes)...")
  }

  acs <- tryCatch(
    tidycensus::get_acs(
      geography  = "tract",
      variables  = var_ids,
      year       = year,
      survey     = "acs5",
      output     = "wide",
      cache_table = TRUE,
      state      = states
    ),
    error = function(e) stop(sprintf(
      "Census API Error:\n%s\n\nCheck CENSUS_API_KEY and internet connection.",
      e$message
    ))
  )

  male_var_ids   <- dplyr::pull(dplyr::filter(adult_vars, stringr::str_detect(label, "Male:")), name)
  female_var_ids <- dplyr::pull(dplyr::filter(adult_vars, stringr::str_detect(label, "Female:")), name)

  male_est_cols   <- paste0(male_var_ids, "E")
  male_moe_cols   <- paste0(male_var_ids, "M")
  female_est_cols <- paste0(female_var_ids, "E")
  female_moe_cols <- paste0(female_var_ids, "M")

  result <- dplyr::mutate(acs,
    men_18_90       = rowSums(dplyr::across(dplyr::all_of(male_est_cols)), na.rm = TRUE),
    men_18_90_moe   = sqrt(rowSums(dplyr::across(dplyr::all_of(male_moe_cols))^2, na.rm = TRUE)),
    women_18_90     = rowSums(dplyr::across(dplyr::all_of(female_est_cols)), na.rm = TRUE),
    women_18_90_moe = sqrt(rowSums(dplyr::across(dplyr::all_of(female_moe_cols))^2, na.rm = TRUE)),
    adults_18_90     = men_18_90 + women_18_90,
    adults_18_90_moe = sqrt(men_18_90_moe^2 + women_18_90_moe^2)
  )
  result <- dplyr::select(result,
    GEOID, men_18_90, men_18_90_moe, women_18_90, women_18_90_moe,
    adults_18_90, adults_18_90_moe
  )

  if (verbose) {
    message(sprintf("Tracts: %s | Total adults 18-90: %s",
      format(nrow(result), big.mark = ","),
      format(sum(result$adults_18_90, na.rm = TRUE), big.mark = ",")))
    message("Download complete.\n")
  }

  result
}

#' Deprecated version of mysterycall_get_acs_adults_18_90
#' @param ... Arguments passed to mysterycall_get_acs_adults_18_90
#' @return See mysterycall_get_acs_adults_18_90
#' @keywords internal
#' @name get_acs_adults_18_90
get_acs_adults_18_90 <- function(...) {
  .Deprecated("mysterycall_get_acs_adults_18_90")
  mysterycall_get_acs_adults_18_90(...)
}
