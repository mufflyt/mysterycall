library(testthat)
library(mysterycall)

# mysterycall_geocode_city_state() joins city/state against the bundled
# `city_state_to_lat_long` table, so it needs no network and no API key. These
# tests exercise the real offline lookup and its length guard.

test_that("mysterycall_geocode_city_state requires matching city/state lengths", {
  expect_error(
    mysterycall_geocode_city_state(c("Denver", "Boston"), "CO"),
    "same length"
  )
})

test_that("mysterycall_geocode_city_state returns one tidy row per input", {
  res <- mysterycall_geocode_city_state(c("Denver", "Boston"), c("CO", "MA"))
  expect_true(tibble::is_tibble(res))
  expect_equal(nrow(res), 2L)
  expect_named(res, c("city", "state", "lat", "lon"))
  # inputs are upper-cased/trimmed regardless of table hits
  expect_equal(res$city, c("DENVER", "BOSTON"))
  expect_equal(res$state, c("CO", "MA"))
})
