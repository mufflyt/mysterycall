# city_state_to_lat_long.R

library(tidyverse)

city_state_to_lat_long <- readr::read_csv("data-raw/city_state_to_lat_long.csv")

# Add any tidying steps to this script if necessary
city_state_to_lat_long <- readr::type_convert(city_state_to_lat_long)

use_data(city_state_to_lat_long, overwrite = TRUE)
