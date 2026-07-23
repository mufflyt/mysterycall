## Area Deprivation Index (ADI) by ZCTA
##
## Computed from the American Community Survey (ACS) 5-year estimates with
## sociome::get_adi(), which reproduces the Singh Area Deprivation Index via the
## Kolak et al. three-factor decomposition. No Neighborhood Atlas login required.
##
## Geography is ZCTA (ZIP Code Tabulation Area, 5-digit) so the index links
## directly to a physician's practice ZIP with no tract crosswalk. The index is
## national and relative: higher ADI = more deprived. sociome scales the linear
## ADI to roughly mean 100 / SD 20 across the areas supplied (here, all US ZCTAs).
##
## Requires a Census API key in CENSUS_API_KEY (see tidycensus::census_api_key).
## The national pull takes a few minutes.

suppressWarnings(suppressMessages({library(sociome); library(dplyr)}))

YEAR <- 2022L  # ACS 2018-2022 5-year

raw <- sociome::get_adi(geography = "zcta", year = YEAR,
                        dataset = "acs5", seed = 1)

adi_zcta <- raw %>%
  transmute(
    zcta                   = as.character(GEOID),
    adi                    = as.numeric(ADI),
    adi_financial_strength = as.numeric(Financial_Strength),
    adi_economic_hardship  = as.numeric(Economic_Hardship_and_Inequality),
    adi_education          = as.numeric(Educational_Attainment),
    year                   = YEAR
  ) %>%
  arrange(zcta) %>%
  as.data.frame(stringsAsFactors = FALSE)

stopifnot(
  nrow(adi_zcta) > 30000L,
  !anyNA(adi_zcta$zcta),
  all(grepl("^[0-9]{5}$", adi_zcta$zcta)),
  !anyDuplicated(adi_zcta$zcta),
  is.numeric(adi_zcta$adi)
)

message(sprintf("adi_zcta: %d ZCTAs | ADI non-NA %d | range %.1f-%.1f",
                nrow(adi_zcta), sum(!is.na(adi_zcta$adi)),
                min(adi_zcta$adi, na.rm = TRUE), max(adi_zcta$adi, na.rm = TRUE)))

usethis::use_data(adi_zcta, overwrite = TRUE, compress = "xz")
