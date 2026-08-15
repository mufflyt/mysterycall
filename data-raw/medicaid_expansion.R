## Medicaid Expansion Status by State
##
## Source: Kaiser Family Foundation (KFF) "Status of State Medicaid Expansion Decisions"
## https://www.kff.org/medicaid/status-of-state-medicaid-expansion-decisions/
## Verified: June 2025
##
## Covers all 50 US states + District of Columbia.
## "Expanded" = adopted full ACA Medicaid expansion to 138% FPL.
## Wisconsin covers adults to 100% FPL via BadgerCare waiver but did NOT adopt
## the ACA expansion; marked not_expanded with a note.
## Georgia launched "Georgia Pathways" (work-requirement partial expansion)
## July 2023; not considered full ACA expansion; marked not_expanded with a note.

medicaid_expansion <- data.frame(
  state = c(
    "Alabama", "Alaska", "Arizona", "Arkansas", "California",
    "Colorado", "Connecticut", "Delaware", "District of Columbia", "Florida",
    "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana",
    "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine",
    "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi",
    "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
    "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota",
    "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
    "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah",
    "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin",
    "Wyoming"
  ),
  state_abb = c(
    "AL", "AK", "AZ", "AR", "CA",
    "CO", "CT", "DE", "DC", "FL",
    "GA", "HI", "ID", "IL", "IN",
    "IA", "KS", "KY", "LA", "ME",
    "MD", "MA", "MI", "MN", "MS",
    "MO", "MT", "NE", "NV", "NH",
    "NJ", "NM", "NY", "NC", "ND",
    "OH", "OK", "OR", "PA", "RI",
    "SC", "SD", "TN", "TX", "UT",
    "VT", "VA", "WA", "WV", "WI",
    "WY"
  ),
  expanded = c(
    FALSE, TRUE,  TRUE,  TRUE,  TRUE,   # AL AK AZ AR CA
    TRUE,  TRUE,  TRUE,  TRUE,  FALSE,  # CO CT DE DC FL
    FALSE, TRUE,  TRUE,  TRUE,  TRUE,   # GA HI ID IL IN
    TRUE,  FALSE, TRUE,  TRUE,  TRUE,   # IA KS KY LA ME
    TRUE,  TRUE,  TRUE,  TRUE,  FALSE,  # MD MA MI MN MS
    TRUE,  TRUE,  TRUE,  TRUE,  TRUE,   # MO MT NE NV NH
    TRUE,  TRUE,  TRUE,  TRUE,  TRUE,   # NJ NM NY NC ND
    TRUE,  TRUE,  TRUE,  TRUE,  TRUE,   # OH OK OR PA RI
    FALSE, TRUE,  FALSE, FALSE, TRUE,   # SC SD TN TX UT
    TRUE,  TRUE,  TRUE,  TRUE,  FALSE,  # VT VA WA WV WI
    FALSE                               # WY
  ),
  expansion_date = as.Date(c(
    NA,           "2015-09-01", "2014-01-01", "2014-01-01", "2014-01-01",  # AL AK AZ AR CA
    "2014-01-01", "2014-01-01", "2014-01-01", "2014-01-01", NA,            # CO CT DE DC FL
    NA,           "2014-01-01", "2020-01-01", "2014-01-01", "2015-02-01",  # GA HI ID IL IN
    "2014-01-01", NA,           "2014-01-01", "2016-07-01", "2019-01-10",  # IA KS KY LA ME
    "2014-01-01", "2014-01-01", "2014-04-01", "2014-01-01", NA,            # MD MA MI MN MS
    "2021-10-01", "2016-01-01", "2020-10-01", "2014-01-01", "2014-08-15",  # MO MT NE NV NH
    "2014-01-01", "2014-01-01", "2014-01-01", "2023-12-01", "2014-01-01",  # NJ NM NY NC ND
    "2014-01-01", "2021-07-01", "2014-01-01", "2015-01-01", "2014-01-01",  # OH OK OR PA RI
    NA,           "2023-07-01", NA,           NA,           "2020-01-01",  # SC SD TN TX UT
    "2014-01-01", "2019-01-01", "2014-01-01", "2014-01-01", NA,            # VT VA WA WV WI
    NA                                                                       # WY
  )),
  status = c(
    "Not Expanded", "Expanded",     "Expanded",     "Expanded",     "Expanded",      # AL AK AZ AR CA
    "Expanded",     "Expanded",     "Expanded",     "Expanded",     "Not Expanded",  # CO CT DE DC FL
    "Not Expanded", "Expanded",     "Expanded",     "Expanded",     "Expanded",      # GA HI ID IL IN
    "Expanded",     "Not Expanded", "Expanded",     "Expanded",     "Expanded",      # IA KS KY LA ME
    "Expanded",     "Expanded",     "Expanded",     "Expanded",     "Not Expanded",  # MD MA MI MN MS
    "Expanded",     "Expanded",     "Expanded",     "Expanded",     "Expanded",      # MO MT NE NV NH
    "Expanded",     "Expanded",     "Expanded",     "Expanded",     "Expanded",      # NJ NM NY NC ND
    "Expanded",     "Expanded",     "Expanded",     "Expanded",     "Expanded",      # OH OK OR PA RI
    "Not Expanded", "Expanded",     "Not Expanded", "Not Expanded", "Expanded",      # SC SD TN TX UT
    "Expanded",     "Expanded",     "Expanded",     "Expanded",     "Not Expanded",  # VT VA WA WV WI
    "Not Expanded"                                                                    # WY
  ),
  notes = c(
    NA, NA, NA, NA, NA,
    NA, NA, NA, NA, NA,
    "Georgia Pathways (partial/work-requirement) launched July 2023; not full ACA expansion",
    NA, NA, NA, NA,         # HI ID IL IN
    NA, NA, NA, NA, NA,     # IA KS KY LA ME
    NA, NA, NA, NA, NA,     # MD MA MI MN MS
    NA, NA, NA, NA, NA,     # MO MT NE NV NH
    NA, NA, NA, NA, NA,     # NJ NM NY NC ND
    NA, NA, NA, NA, NA,     # OH OK OR PA RI
    NA, NA, NA, NA, NA,     # SC SD TN TX UT
    NA, NA, NA, NA,         # VT VA WA WV
    "Covers adults to 100% FPL via BadgerCare waiver; did not adopt ACA expansion to 138% FPL",  # WI
    NA                      # WY
  ),
  stringsAsFactors = FALSE
)

stopifnot(nrow(medicaid_expansion) == 51L)
stopifnot(sum(medicaid_expansion$expanded) == 41L)          # 40 states + DC
stopifnot(sum(!medicaid_expansion$expanded) == 10L)
stopifnot(!anyDuplicated(medicaid_expansion$state))
stopifnot(!anyDuplicated(medicaid_expansion$state_abb))

usethis::use_data(medicaid_expansion, overwrite = TRUE)
