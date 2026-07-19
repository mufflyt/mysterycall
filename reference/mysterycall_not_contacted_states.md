# Summarize States Where Physicians Were NOT Contacted

This function summarizes the demographic details by identifying the
states where physicians were not successfully contacted and those that
were included. It also reports how many unique physicians were
successfully reached by filtering to rows with affirmative contact
indicators (e.g., "Yes" values in `contact_office` or
`included_in_study`).

## Usage

``` r
mysterycall_not_contacted_states(filtered_data, all_states = NULL)
```

## Arguments

- filtered_data:

  A data frame containing filtered data of contacted physicians.

- all_states:

  A character vector of all possible states including Washington, DC. If
  not provided, a default set of states will be used.

## Value

A length-1 character string summarizing the states not contacted and the
number of unique physicians successfully reached.

## Details

If `contact_office` and/or `included_in_study` exist, they are
interpreted as contact indicators and used to restrict the denominator
to successfully contacted rows. Accepted affirmative values include
logical `TRUE`, non-zero numerics, and character values such as `"yes"`,
`"y"`, `"true"`, and `"1"`.

The physician count is derived from the first available identifier among
`npi`, `name`, `physician_info`, and `physician_information`.

## See also

[`mysterycall_summarize_census()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_summarize_census.md),
[`mysterycall_get_clinician_data()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_get_clinician_data.md),
[`mysterycall_clean_phase1()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_clean_phase1.md)

Other data quality:
[`mysterycall_remove_constants()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_remove_constants.md),
[`mysterycall_remove_near_zero()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_remove_near_zero.md),
[`mysterycall_validate_phone()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_validate_phone.md)

## Examples

``` r
# Example with provided all_states
filtered_data <- data.frame(state = c("California", "New York", "Texas"))
all_states <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
                 "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho",
                 "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana",
                 "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
                 "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada",
                 "New Hampshire", "New Jersey", "New Mexico", "New York",
                 "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon",
                 "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota",
                 "Tennessee", "Texas", "Utah", "Vermont", "Virginia",
                 "Washington", "West Virginia", "Wisconsin", "Wyoming",
                 "District of Columbia")
mysterycall_not_contacted_states(filtered_data, all_states)
#> [1] "A total of 3 unique physicians were identified in the dataset and were successfully contacted (i.e., with a recorded wait time for an appointment) in 3 states. The excluded states include Alabama, Alaska, Arizona, Arkansas, Colorado, Connecticut, Delaware, Florida, Georgia, Hawaii, Idaho, Illinois, Indiana, Iowa, Kansas, Kentucky, Louisiana, Maine, Maryland, Massachusetts, Michigan, Minnesota, Mississippi, Missouri, Montana, Nebraska, Nevada, New Hampshire, New Jersey, New Mexico, North Carolina, North Dakota, Ohio, Oklahoma, Oregon, Pennsylvania, Rhode Island, South Carolina, South Dakota, Tennessee, Utah, Vermont, Virginia, Washington, West Virginia, Wisconsin, Wyoming and District of Columbia."

# Example with default all_states
filtered_data <- data.frame(state = c("California", "New York", "Texas", "Nevada"))
mysterycall_not_contacted_states(filtered_data)
#> [1] "A total of 4 unique physicians were identified in the dataset and were successfully contacted (i.e., with a recorded wait time for an appointment) in 4 states. The excluded states include Alabama, Alaska, Arizona, Arkansas, Colorado, Connecticut, Delaware, Florida, Georgia, Hawaii, Idaho, Illinois, Indiana, Iowa, Kansas, Kentucky, Louisiana, Maine, Maryland, Massachusetts, Michigan, Minnesota, Mississippi, Missouri, Montana, Nebraska, New Hampshire, New Jersey, New Mexico, North Carolina, North Dakota, Ohio, Oklahoma, Oregon, Pennsylvania, Rhode Island, South Carolina, South Dakota, Tennessee, Utah, Vermont, Virginia, Washington, West Virginia, Wisconsin, Wyoming and District of Columbia."
```
