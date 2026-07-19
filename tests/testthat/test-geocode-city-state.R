# Tests for mysterycall_geocode_city_state()

test_that("known cities resolve to plausible coordinates", {
  g <- mysterycall_geocode_city_state(c("Denver", "Boston"), c("CO", "MA"))
  expect_s3_class(g, "tbl_df")
  expect_equal(nrow(g), 2L)
  # Denver ~ (39.7, -105.0)
  expect_true(abs(g$lat[1] - 39.7) < 1 && abs(g$lon[1] + 105) < 1)
  # Boston ~ (42.4, -71.1)
  expect_true(abs(g$lat[2] - 42.4) < 1 && abs(g$lon[2] + 71.1) < 1)
})

test_that("lookup is case- and whitespace-insensitive", {
  a <- mysterycall_geocode_city_state("denver", "co")
  b <- mysterycall_geocode_city_state("  DENVER ", " CO ")
  expect_equal(a$lat, b$lat)
  expect_equal(a$lon, b$lon)
})

test_that("unmatched places return NA coordinates", {
  g <- mysterycall_geocode_city_state("Nowheresville", "ZZ")
  expect_true(is.na(g$lat) && is.na(g$lon))
})

test_that("overrides fill in missing places", {
  ov <- data.frame(city = "Commerce Twp", state = "MI",
                   lat = 42.5906, lon = -83.4913)
  g <- mysterycall_geocode_city_state("Commerce Twp", "MI", overrides = ov)
  expect_equal(g$lat, 42.5906)
  expect_equal(g$lon, -83.4913)
})

test_that("overrides win over the bundled table", {
  ov <- data.frame(city = "Denver", state = "CO", lat = 0, lon = 0)
  g <- mysterycall_geocode_city_state("Denver", "CO", overrides = ov)
  expect_equal(g$lat, 0)
})

test_that("mismatched lengths error", {
  expect_error(mysterycall_geocode_city_state(c("Denver", "Boston"), "CO"),
               "same length")
})

test_that("output is vectorized and length-stable", {
  g <- mysterycall_geocode_city_state(c("Denver", "Nowhere", "Boston"),
                                      c("CO", "ZZ", "MA"))
  expect_equal(nrow(g), 3L)
  expect_true(is.na(g$lat[2]))
})
