library(testthat)
library(mysterycall)

# mysterycall_get_acs_women_18_90() pulls ACS 5-year female-population counts.
# The live fetch needs tidycensus + a Census API key, but its input guards run
# offline: an out-of-range year is rejected before any network call.

test_that("mysterycall_get_acs_women_18_90 is available", {
  expect_true(is.function(mysterycall_get_acs_women_18_90))
})

test_that("mysterycall_get_acs_women_18_90 rejects an out-of-range year", {
  # Errors whether or not tidycensus is installed (dependency guard or the
  # "ACS 5-year data available for 2009-2023" year guard fires first).
  expect_error(mysterycall_get_acs_women_18_90(year = 1800))
  expect_error(mysterycall_get_acs_women_18_90(year = 2100))
})
