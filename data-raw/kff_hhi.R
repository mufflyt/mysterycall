## KFF per-MSA hospital-market concentration (HHI), 2024
##
## Source: Kaiser Family Foundation (KFF) published metropolitan-area
## Herfindahl-Hirschman Index dataset, "KFF HHI Dataset .xlsx" (sheet
## "appendix"), obtained from the mufflyt/consolidation study repo
## (data/raw/). A verbatim copy of the source workbook lives at
## data-raw/kff_hhi/KFF_HHI_Dataset.xlsx for reproducibility.
##
## HHI ranges 0-10000 (sum of squared percent market shares). DOJ/FTC
## Horizontal Merger Guidelines: un-concentrated < 1000, moderate 1000-1800,
## highly concentrated > 1800.

library(dplyr)

raw <- readxl::read_excel(
  file.path("data-raw", "kff_hhi", "KFF_HHI_Dataset.xlsx"),
  sheet = "appendix"
)

pct_to_prop <- function(x) {
  x <- trimws(as.character(x))
  x[x %in% c("N/A", "NA", "")] <- NA_character_
  suppressWarnings(as.numeric(sub("%$", "", x)) / 100)
}

na_if_na <- function(x) {
  x <- trimws(as.character(x))
  x[x %in% c("N/A", "NA", "")] <- NA_character_
  x
}

kff_hhi <- tibble::tibble(
  msa                         = as.character(raw[["MSA"]]),
  residents_2024              = as.integer(round(raw[["Residents in 2024"]])),
  market_structure            = as.character(raw[["Number of health systems that control 100% of the market"]]),
  hhi                         = as.numeric(raw[["HHI in 2024"]]),
  largest_system              = na_if_na(raw[["Largest system"]]),
  largest_system_share        = pct_to_prop(raw[["Largest system market share"]]),
  second_largest_system       = na_if_na(raw[["Second largest system"]]),
  second_largest_system_share = pct_to_prop(raw[["Second largest system market share"]])
) |>
  mutate(
    # Two-letter state parsed from the "City, ST" (or "City, ST-ST") MSA label.
    state_abb = toupper(trimws(sub("-.*$", "",
                  trimws(sub("^.*,\\s*", "", .data$msa))))),
    # DOJ/FTC Horizontal Merger Guidelines concentration bands.
    hhi_cat = cut(.data$hhi, c(-Inf, 1000, 1800, Inf),
                  labels = c("un-concentrated", "moderate", "high"),
                  ordered_result = TRUE)
  ) |>
  relocate("state_abb", .after = "msa") |>
  arrange(.data$msa)

stopifnot(
  nrow(kff_hhi) == 387L,
  all(kff_hhi$hhi >= 0 & kff_hhi$hhi <= 10000),
  !anyNA(kff_hhi$msa),
  !anyNA(kff_hhi$hhi)
)

usethis::use_data(kff_hhi, overwrite = TRUE)
