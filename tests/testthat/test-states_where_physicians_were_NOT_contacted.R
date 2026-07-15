library(testthat)
testthat::skip_if_not_installed("dplyr")
library(dplyr)

test_that("Function handles default all_states correctly", {
  # Test data
  filtered_data <- data.frame(state = c("California", "New York", "Texas"))

  # Expected result
  expected <- paste0(
    "A total of ",
    3,
    " unique physicians were identified in the dataset and were successfully contacted (i.e., with a recorded wait time for an appointment) in ",
    3,
    " states. The excluded states include ",
    paste(
      c("Alabama", "Alaska", "Arizona", "Arkansas", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii",
        "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts",
        "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey",
        "New Mexico", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
        "South Carolina", "South Dakota", "Tennessee", "Utah", "Vermont", "Virginia", "Washington", "West Virginia",
        "Wisconsin", "Wyoming"), collapse = ", "), " and District of Columbia."
  )


# Run test
result <- mysterycall_not_contacted_states(filtered_data)
expect_equal(result, expected)
})

test_that("Function handles no states correctly", {
  # Test data
  filtered_data <- data.frame(state = character())

  # Expected result
  expected <- paste0(
    "A total of ",
    0,
    " unique physicians were identified in the dataset and were successfully contacted (i.e., with a recorded wait time for an appointment) in ",
    0,
    " states. The excluded states include ",
    paste(c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia",
            "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland",
            "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
            "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania",
            "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington",
            "West Virginia", "Wisconsin", "Wyoming"), collapse = ", "), " and District of Columbia."
  )

  # Run test
  result <- mysterycall_not_contacted_states(filtered_data)
  expect_equal(result, expected)
})

# Regression (BUG 45): the "including the District of Columbia" clause must be
# gated on DC actually appearing among the contacted (included) states.
test_that("DC clause is omitted when DC is not among the included states", {
  filtered_data <- data.frame(state = c("California", "New York", "Texas"))
  result <- mysterycall_not_contacted_states(filtered_data)
  expect_false(grepl("including the District of Columbia", result))
})

test_that("DC clause is present when DC is among the included states", {
  filtered_data <- data.frame(state = c("California", "District of Columbia"))
  result <- mysterycall_not_contacted_states(
    filtered_data,
    all_states = c("California", "District of Columbia")
  )
  expect_true(grepl("including the District of Columbia", result))
})
