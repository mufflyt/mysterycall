## KFF Medicaid-to-Medicare Fee Index (All Services), 2024
##
## Source: Kaiser Family Foundation, "Medicaid-to-Medicare Fee Index"
## (All Services), 2024 vintage.
## https://www.kff.org/medicaid/state-indicator/medicaid-to-medicare-fee-index/
##
## The index is the ratio of what a state's Medicaid program pays to what
## Medicare pays for the same services; < 1 means Medicaid pays less than
## Medicare. Tennessee is N/A (no comprehensive fee-for-service Medicaid fee
## schedule to index). National average (All Services) = 0.75.

library(dplyr)

# state, two-letter abbreviation, 2024 All-Services fee index (NA = not reported)
raw <- tibble::tribble(
  ~state,                  ~state_abb, ~fee_index,
  "Alabama",               "AL",       0.92,
  "Alaska",                "AK",       1.30,
  "Arizona",               "AZ",       0.98,
  "Arkansas",              "AR",       0.76,
  "California",            "CA",       0.67,
  "Colorado",              "CO",       0.83,
  "Connecticut",           "CT",       0.79,
  "Delaware",              "DE",       0.96,
  "District of Columbia",  "DC",       0.81,
  "Florida",               "FL",       0.64,
  "Georgia",               "GA",       0.83,
  "Hawaii",                "HI",       0.84,
  "Idaho",                 "ID",       0.94,
  "Illinois",              "IL",       0.63,
  "Indiana",               "IN",       0.96,
  "Iowa",                  "IA",       0.77,
  "Kansas",                "KS",       0.69,
  "Kentucky",              "KY",       0.69,
  "Louisiana",             "LA",       0.64,
  "Maine",                 "ME",       0.78,
  "Maryland",              "MD",       0.95,
  "Massachusetts",         "MA",       0.74,
  "Michigan",              "MI",       0.76,
  "Minnesota",             "MN",       0.74,
  "Mississippi",           "MS",       0.93,
  "Missouri",              "MO",       0.86,
  "Montana",               "MT",       1.32,
  "Nebraska",              "NE",       1.01,
  "Nevada",                "NV",       0.90,
  "New Hampshire",         "NH",       0.73,
  "New Jersey",            "NJ",       0.61,
  "New Mexico",            "NM",       1.21,
  "New York",              "NY",       0.76,
  "North Carolina",        "NC",       0.82,
  "North Dakota",          "ND",       1.06,
  "Ohio",                  "OH",       0.63,
  "Oklahoma",              "OK",       0.94,
  "Oregon",                "OR",       0.88,
  "Pennsylvania",          "PA",       0.68,
  "Rhode Island",          "RI",       0.52,
  "South Carolina",        "SC",       0.89,
  "South Dakota",          "SD",       0.91,
  "Tennessee",             "TN",       NA,
  "Texas",                 "TX",       0.63,
  "Utah",                  "UT",       0.80,
  "Vermont",               "VT",       0.87,
  "Virginia",              "VA",       0.83,
  "Washington",            "WA",       0.64,
  "West Virginia",         "WV",       0.82,
  "Wisconsin",             "WI",       0.66,
  "Wyoming",               "WY",       1.00
)

medicaid_fee_index <- raw |>
  mutate(
    year = 2024L,
    # Medicaid pays at least as much as Medicare when the index >= 1.
    at_or_above_medicare = .data$fee_index >= 1
  ) |>
  arrange(.data$state)

# National All-Services average, stored as an attribute (not a state row).
attr(medicaid_fee_index, "national_average") <- 0.75

stopifnot(
  nrow(medicaid_fee_index) == 51L,
  sum(is.na(medicaid_fee_index$fee_index)) == 1L,             # Tennessee only
  is.na(medicaid_fee_index$fee_index[medicaid_fee_index$state_abb == "TN"]),
  !anyDuplicated(medicaid_fee_index$state_abb)
)

usethis::use_data(medicaid_fee_index, overwrite = TRUE)
