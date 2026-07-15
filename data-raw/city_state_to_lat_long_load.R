# city_state_to_lat_long.R
#
# Builds data/city_state_to_lat_long.rda to match its documented schema:
# columns `city`, `state` (two-letter USPS abbreviation), `lat`, `long`.
# The source CSV ships full state names and `latitude`/`longitude` columns, so
# this script renames the coordinate columns and abbreviates the state names
# (previously it read the CSV verbatim, so `$lat`/`$long` were NULL and any
# two-letter-`state` join matched zero rows).

library(readr)
library(dplyr)

city_state_to_lat_long <- readr::read_csv(
  "data-raw/city_state_to_lat_long.csv",
  show_col_types = FALSE
)
city_state_to_lat_long <- readr::type_convert(city_state_to_lat_long)

# Full state names -> USPS two-letter abbreviations (50 states + DC + PR).
state_lookup <- c(
  stats::setNames(datasets::state.abb, datasets::state.name),
  "District of Columbia" = "DC",
  "Puerto Rico"          = "PR"
)

city_state_to_lat_long <- city_state_to_lat_long |>
  dplyr::rename(lat = latitude, long = longitude) |>
  dplyr::mutate(state = unname(state_lookup[state])) |>
  dplyr::select(city, state, lat, long)

# Fail loudly if any source state name did not map (guards against new
# territories / typos silently becoming NA).
stopifnot(!anyNA(city_state_to_lat_long$state))

usethis::use_data(city_state_to_lat_long, overwrite = TRUE)
