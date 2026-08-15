#' Total female population denominators from the Census ACS
#'
#' @name census_female_population
#' @keywords internal
NULL

#' Fetch total female population by year (denominator for density figures)
#'
#' Downloads the **total female population** (ACS table B01001, variable
#' `B01001_026E`, "Estimate!!Total!!Female") for one geography across a range of
#' years, returning a denominator ready to pass to the `population` argument of
#' [mysterycall_subspecialist_trend()] or
#' [mysterycall_subspecialist_infographic()]. Wraps [tidycensus::get_acs()], so
#' a Census API key (env var `CENSUS_API_KEY`) and an internet connection are
#' required.
#'
#' The ACS 1-year table was **not released for 2020**; `fill_2020` controls how
#' that year is handled when `survey = "acs1"`.
#'
#' @param years Integer vector of survey years. Default `2013:2023`.
#' @param survey `"acs1"` (1-year, default) or `"acs5"` (5-year, smoother and
#'   available for every year including 2020).
#' @param geography Census geography passed to [tidycensus::get_acs()]. Default
#'   `"us"` (one national total per year).
#' @param variable ACS variable for total female population. Default
#'   `"B01001_026E"`.
#' @param fill_2020 How to handle 2020 when `survey = "acs1"`: `"acs5"` (default;
#'   substitute the ACS 5-year value and message), `"skip"` (return `NA` for
#'   2020), or `"error"` (stop).
#' @param as `"vector"` (default) returns a year-named numeric vector;
#'   `"data.frame"` returns a `data.frame(year, population)`. Both forms are
#'   accepted directly by the density functions' `population` argument.
#' @param verbose Logical. Message substitutions/progress. Default `TRUE`.
#'
#' @return A year-named numeric vector, or a `data.frame(year, population)`.
#'
#' @family census
#' @seealso [mysterycall_subspecialist_trend()],
#'   [mysterycall_subspecialist_infographic()]
#' @export
#'
#' @examplesIf interactive()
#' # Requires CENSUS_API_KEY and internet.
#' fem_pop <- mysterycall_census_female_population(2013:2023, survey = "acs5")
#' # feed straight into the trend figure:
#' # mysterycall_subspecialist_trend(counts, population = fem_pop)
mysterycall_census_female_population <- function(
    years     = 2013:2023,
    survey    = c("acs1", "acs5"),
    geography = "us",
    variable  = "B01001_026E",
    fill_2020 = c("acs5", "skip", "error"),
    as        = c("vector", "data.frame"),
    verbose   = TRUE) {

  survey    <- match.arg(survey)
  fill_2020 <- match.arg(fill_2020)
  as        <- match.arg(as)
  years     <- as.integer(years)
  if (any(is.na(years)))
    stop("`years` must be coercible to integers.", call. = FALSE)

  vals <- vapply(years, function(y) {
    srv <- survey
    if (y == 2020L && survey == "acs1") {
      if (fill_2020 == "error")
        stop("The ACS 1-year 2020 table was not released. Set `survey = \"acs5\"` ",
             "or `fill_2020` to \"acs5\" or \"skip\".", call. = FALSE)
      if (fill_2020 == "skip") return(NA_real_)
      srv <- "acs5"
      if (verbose)
        message("2020: ACS 1-year not released; using ACS 5-year total female population.")
    }
    tryCatch(
      .census_acs_total(variable, y, srv, geography),
      error = function(e)
        stop(sprintf("Census fetch for %d (%s) failed: %s",
                     y, srv, conditionMessage(e)), call. = FALSE)
    )
  }, numeric(1))

  names(vals) <- years
  if (as == "data.frame")
    return(data.frame(year = years, population = unname(vals)))
  vals
}


# ---- package-internal helper -------------------------------------------------

# Single ACS total for a (variable, year, survey, geography). Isolated so the
# assembly/2020 logic above can be unit-tested by stubbing this out, and so the
# tidycensus dependency is only touched on the real fetch path.
.census_acs_total <- function(variable, year, survey, geography) {
  if (!requireNamespace("tidycensus", quietly = TRUE))
    stop("Package 'tidycensus' is required. Install it and set CENSUS_API_KEY.",
         call. = FALSE)
  d <- tidycensus::get_acs(geography = geography, variables = variable,
                           year = year, survey = survey)
  sum(d$estimate, na.rm = TRUE)
}
