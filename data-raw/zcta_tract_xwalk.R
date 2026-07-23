## ZCTA <-> Census Tract crosswalk (area-weighted)
##
## A ZIP-to-tract crosswalk built from the Census Bureau's authoritative 2020
## ZCTA5-to-tract relationship file (free, no login), used in place of HUD's
## login-gated USPS ZIP crosswalk. ZCTA (ZIP Code Tabulation Area) is the Census
## stand-in for a mailing ZIP.
##
## The relationship file gives the Census-computed LAND AREA of every
## ZCTA x tract intersection (AREALAND_PART). Allocation ratios are therefore
## AREA-weighted, unlike HUD's ADDRESS-weighted res_ratio/bus_ratio. For
## population-based apportionment prefer HUD's file or a block-level build;
## area weights are a reasonable geographic approximation and are exact for
## "which tracts does this ZIP touch, and by how much land."
##
## Source: https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/
##         tab20_zcta520_tract20_natl.txt

suppressWarnings(suppressMessages({library(readr); library(dplyr)}))

URL <- paste0("https://www2.census.gov/geo/docs/maps-data/data/rel2020/",
              "zcta520/tab20_zcta520_tract20_natl.txt")

tmp <- tempfile(fileext = ".txt")
utils::download.file(URL, tmp, quiet = TRUE)

raw <- read_delim(tmp, delim = "|", show_col_types = FALSE,
                  col_types = cols(.default = col_character()))

zcta_tract_xwalk <- raw %>%
  filter(!is.na(GEOID_ZCTA5_20), GEOID_ZCTA5_20 != "",
         !is.na(GEOID_TRACT_20),  GEOID_TRACT_20  != "") %>%
  transmute(
    zcta          = GEOID_ZCTA5_20,
    tract         = GEOID_TRACT_20,          # 11-digit 2020 tract GEOID
    arealand_part = as.numeric(AREALAND_PART)
  ) %>%
  # Keep only intersections that share land: a ZCTA x tract pair with 0 shared
  # land is a water-boundary artifact, and all-water tracts would make the
  # ratios 0/0. Dropping them leaves both ratios well defined.
  filter(arealand_part > 0) %>%
  group_by(zcta) %>%
  mutate(zcta_to_tract = arealand_part / sum(arealand_part)) %>%   # sums to 1 per ZCTA
  group_by(tract) %>%
  mutate(tract_to_zcta = arealand_part / sum(arealand_part)) %>%   # sums to 1 per tract
  ungroup() %>%
  arrange(zcta, desc(zcta_to_tract)) %>%
  as.data.frame(stringsAsFactors = FALSE)

stopifnot(
  nrow(zcta_tract_xwalk) > 150000L,
  all(grepl("^[0-9]{5}$", zcta_tract_xwalk$zcta)),
  all(grepl("^[0-9]{11}$", zcta_tract_xwalk$tract)),
  !anyDuplicated(zcta_tract_xwalk[c("zcta", "tract")]),
  !anyNA(zcta_tract_xwalk$zcta_to_tract),
  !anyNA(zcta_tract_xwalk$tract_to_zcta),
  # per-ZCTA and per-tract ratios each sum to ~1
  all(abs(tapply(zcta_tract_xwalk$zcta_to_tract, zcta_tract_xwalk$zcta,  sum) - 1) < 1e-6),
  all(abs(tapply(zcta_tract_xwalk$tract_to_zcta, zcta_tract_xwalk$tract, sum) - 1) < 1e-6)
)

message(sprintf("zcta_tract_xwalk: %d rows | %d ZCTAs | %d tracts",
                nrow(zcta_tract_xwalk),
                dplyr::n_distinct(zcta_tract_xwalk$zcta),
                dplyr::n_distinct(zcta_tract_xwalk$tract)))

usethis::use_data(zcta_tract_xwalk, overwrite = TRUE, compress = "xz")
