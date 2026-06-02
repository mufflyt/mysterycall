#' Get ACS Female Population (Ages 18-90) by Census Tract
#'
#' Downloads ACS B01001 (Sex by Age) data for women aged 18-89 years.
#' Automatically sums across age groups and propagates margins of error
#' using the Census Bureau sum-of-squares formula:
#' \eqn{MOE_{sum} = \sqrt{\sum MOE_i^2}}.
#'
#' Age groups included: 18-19, 20, 21, 22-24, 25-29, 30-34, 35-39, 40-44,
#' 45-49, 50-54, 55-59, 60-61, 62-64, 65-66, 67-69, 70-74, 75-79, 80-84,
#' 85-89.
#'
#' @param year Integer. ACS 5-year survey year (2009-2023). Default: \code{2022}.
#' @param states Character vector of two-letter state abbreviations, or
#'   \code{NULL} to download all states (slow, ~30 min). Default: \code{NULL}.
#' @param verbose Logical. Print progress messages. Default: \code{TRUE}.
#'
#' @return Tibble with columns:
#'   \describe{
#'     \item{GEOID}{Census tract ID (11-digit string).}
#'     \item{women_18_90}{Sum of female population aged 18-89.}
#'     \item{women_18_90_moe}{Margin of error (90% CI, propagated via sum-of-squares).}
#'   }
#'
#' @note MOE propagation follows Census Bureau ACS Handbook Appendix 3.
#'   All MOE values are at 90% confidence level (Census standard).
#'   For both sexes in one call, use \code{\link{mysterycall_get_acs_adults_18_90}}.
#'
#' @examplesIf interactive()
#' co_women <- mysterycall_get_acs_women_18_90(year = 2022, states = "CO")
#' west_coast <- mysterycall_get_acs_women_18_90(year = 2022, states = c("CA", "OR", "WA"))
#'
#' @importFrom dplyr filter mutate select across all_of
#' @importFrom stringr str_detect
#' @family census
#' @export
mysterycall_get_acs_women_18_90 <- function(year = 2022, states = NULL, verbose = TRUE) {
  if (!requireNamespace("tidycensus", quietly = TRUE)) {
    stop("Package 'tidycensus' is required", call. = FALSE)
  }
  if (year < 2009 || year > 2023) {
    stop(sprintf("Invalid year: %d. ACS 5-year data available for 2009-2023.", year))
  }

  if (verbose) {
    message("")
    message("=========================================================")
    message("ACS FEMALE POPULATION DATA DOWNLOAD (AGES 18-90)")
    message("=========================================================")
    message(sprintf("Year:       ACS %d (5-year estimates)", year))
    message(sprintf("Geography:  Census tracts"))
    message(sprintf("States:     %s", ifelse(is.null(states), "All US (50 states + DC + PR)",
                                           paste(states, collapse = ", "))))
    message(sprintf("Variables:  B01001 (Sex by Age) - Female 18-89 years"))
    message("")
  }

  if (verbose) message("Loading Census variable dictionary...")
  vars <- tryCatch(
    tidycensus::load_variables(year = year, dataset = "acs5", cache = TRUE),
    error = function(e) stop(sprintf(
      "Census API Error (variable dictionary):\n%s\n\nCheck CENSUS_API_KEY env var.",
      e$message
    ))
  )

  female_vars <- dplyr::filter(vars,
    stringr::str_detect(name, "^B01001_"),
    stringr::str_detect(label, "Female:"),
    stringr::str_detect(label,
      paste0("(18 and 19 years|20 years|21 years|22 to 24 years|25 to 29 years|",
             "30 to 34 years|35 to 39 years|40 to 44 years|45 to 49 years|",
             "50 to 54 years|55 to 59 years|60 and 61 years|62 to 64 years|",
             "65 and 66 years|67 to 69 years|70 to 74 years|75 to 79 years|",
             "80 to 84 years|85 years)")),
    !stringr::str_detect(label, "(Under 5|5 to 9|10 to 14|15 to 17)")
  )
  var_ids <- female_vars$name

  if (verbose) {
    message(sprintf("Identified %d age group variables", length(var_ids)))
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

  est_cols <- grep("_[0-9]+E$", names(acs), value = TRUE)
  moe_cols <- grep("_[0-9]+M$", names(acs), value = TRUE)

  if (length(moe_cols) != length(est_cols)) {
    warning(sprintf(
      "MOE column count (%d) does not match estimate columns (%d). Proceeding with available data.",
      length(moe_cols), length(est_cols)
    ))
  }

  result <- dplyr::mutate(acs,
    women_18_90     = rowSums(dplyr::across(dplyr::all_of(est_cols)), na.rm = TRUE),
    women_18_90_moe = sqrt(rowSums(dplyr::across(dplyr::all_of(moe_cols))^2, na.rm = TRUE))
  )
  result <- dplyr::select(result, GEOID, women_18_90, women_18_90_moe)

  if (verbose) {
    nonzero <- result$women_18_90 > 0
    moe_pct <- if (any(nonzero, na.rm = TRUE)) {
      100 * mean(result$women_18_90_moe[nonzero] / result$women_18_90[nonzero], na.rm = TRUE)
    } else {
      NA_real_
    }
    message(sprintf("Tracts: %s | Total women 18-90: %s | Avg MOE: %.2f%%",
      format(nrow(result), big.mark = ","),
      format(sum(result$women_18_90, na.rm = TRUE), big.mark = ","),
      ifelse(is.na(moe_pct), 0, moe_pct)))
    message("Download complete.\n")
  }

  result
}

#' Deprecated version of mysterycall_get_acs_women_18_90
#' @param ... Arguments passed to mysterycall_get_acs_women_18_90
#' @return See mysterycall_get_acs_women_18_90
#' @keywords internal
#' @name get_acs_women_18_90
get_acs_women_18_90 <- function(...) {
  .Deprecated("mysterycall_get_acs_women_18_90")
  mysterycall_get_acs_women_18_90(...)
}
