## CDC/ATSDR Social Vulnerability Index (SVI) by ZCTA
##
## Computed from American Community Survey (ACS) 5-year estimates with
## findSVI::find_svi(), which reproduces the CDC/ATSDR SVI methodology (theme
## and overall percentile ranks). No CDC portal download required.
##
## Geography is ZCTA (ZIP Code Tabulation Area, 5-digit) and the ranks are
## national (state = "US"), so the index links directly to a physician's
## practice ZIP with no tract crosswalk. Higher percentile = more vulnerable.
##
## Requires a Census API key in CENSUS_API_KEY. The national pull takes ~2 min.

suppressWarnings(suppressMessages({library(findSVI); library(dplyr)}))

YEAR <- 2022L  # ACS 2018-2022 5-year

raw <- findSVI::find_svi(year = YEAR, state = "US", geography = "zcta",
                         key = Sys.getenv("CENSUS_API_KEY"))

svi_zcta <- raw %>%
  transmute(
    zcta                  = as.character(GEOID),
    svi                   = as.numeric(RPL_themes),  # overall percentile
    svi_socioeconomic     = as.numeric(RPL_theme1),
    svi_household         = as.numeric(RPL_theme2),
    svi_minority          = as.numeric(RPL_theme3),
    svi_housing_transport = as.numeric(RPL_theme4),
    year                  = YEAR
  ) %>%
  arrange(zcta) %>%
  as.data.frame(stringsAsFactors = FALSE)

stopifnot(
  nrow(svi_zcta) > 30000L,
  !anyNA(svi_zcta$zcta),
  all(grepl("^[0-9]{5}$", svi_zcta$zcta)),
  !anyDuplicated(svi_zcta$zcta),
  all(svi_zcta$svi >= 0 & svi_zcta$svi <= 1, na.rm = TRUE)
)

message(sprintf("svi_zcta: %d ZCTAs | overall SVI non-NA %d | range %.2f-%.2f",
                nrow(svi_zcta), sum(!is.na(svi_zcta$svi)),
                min(svi_zcta$svi, na.rm = TRUE), max(svi_zcta$svi, na.rm = TRUE)))

usethis::use_data(svi_zcta, overwrite = TRUE, compress = "xz")
