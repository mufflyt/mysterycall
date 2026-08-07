library(testthat)
library(mysterycall)

# mysterycall_get_acs_adults_18_90() pulls ACS 5-year adult-population counts.
# The live fetch needs tidycensus + a Census API key; its input guards are
# offline: a missing or out-of-range year is rejected before any network call.

test_that("mysterycall_get_acs_adults_18_90 is available", {
  expect_true(is.function(mysterycall_get_acs_adults_18_90))
})

test_that("mysterycall_get_acs_adults_18_90 rejects a missing/out-of-range year", {
  # Errors whether or not tidycensus is installed (dependency guard, the
  # "year is required" guard, or the 2009-2023 year guard fires first).
  expect_error(mysterycall_get_acs_adults_18_90())
  expect_error(mysterycall_get_acs_adults_18_90(year = 1800))
})
