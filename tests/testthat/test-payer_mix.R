library(testthat)

test_that("mysterycall_get_payer_mix validates arguments before any API call", {
  skip_if_not_installed("tidycensus")
  expect_error(mysterycall_get_payer_mix(year = NULL), "required")
  expect_error(mysterycall_get_payer_mix(year = 1999), "2012-2023")
  expect_error(mysterycall_get_payer_mix(year = 2030), "2012-2023")
  expect_error(mysterycall_get_payer_mix(year = 2022, geography = c("county", "tract")),
               "single character")
})

test_that("mysterycall_get_payer_mix errors without tidycensus", {
  local_mocked_bindings(
    requireNamespace = function(pkg, ...) if (pkg == "tidycensus") FALSE else TRUE,
    .package = "base"
  )
  expect_error(mysterycall_get_payer_mix(year = 2022), "tidycensus")
})
