# Direct tests for mysterycall_calculate_spatial_density() and the coordinate
# domain gate it now enforces. Before these existed, a latitude of 500 was
# accepted and returned a plausible-looking count, and a point with a missing
# coordinate was reported as having a density of 0 -- indistinguishable from a
# genuinely isolated practice.

# Denver and Boston, decimal degrees (WGS84). Great-circle separation is
# ~1,754 miles, which is the independent anchor used below.
denver <- c(lat = 39.7392, lon = -104.9903)
boston <- c(lat = 42.3601, lon = -71.0589)

test_that("density counts neighbours inside the radius and excludes self", {
  # Three points: two within ~1 mile of each other, one far away.
  lats <- c(39.7392, 39.7492, 42.3601)
  lons <- c(-104.9903, -104.9903, -71.0589)

  out <- mysterycall_calculate_spatial_density(lats, lons, radius = 15)

  expect_type(out, "integer")
  expect_length(out, 3L)
  # Each of the two Denver points sees the other; neither counts itself.
  expect_equal(out, c(1L, 1L, 0L))
})

test_that("coincident points count each other without counting themselves", {
  lats <- rep(denver[["lat"]], 4L)
  lons <- rep(denver[["lon"]], 4L)

  out <- mysterycall_calculate_spatial_density(lats, lons, radius = 1)

  expect_equal(out, rep(3L, 4L))
})

test_that("an isolated point has zero neighbours", {
  out <- mysterycall_calculate_spatial_density(
    c(denver[["lat"]], boston[["lat"]]),
    c(denver[["lon"]], boston[["lon"]]),
    radius = 15
  )

  expect_equal(out, c(0L, 0L))
})

test_that("radius bounds the count at the documented separation", {
  lats <- c(denver[["lat"]], boston[["lat"]])
  lons <- c(denver[["lon"]], boston[["lon"]])

  # Denver-Boston is ~1,754 miles: inside 1800, outside 1700.
  expect_equal(
    mysterycall_calculate_spatial_density(lats, lons, radius = 1800),
    c(1L, 1L)
  )
  expect_equal(
    mysterycall_calculate_spatial_density(lats, lons, radius = 1700),
    c(0L, 0L)
  )
})

test_that("distances agree with an independent geodesic implementation", {
  skip_if_not_installed("sf")

  pts <- sf::st_as_sf(
    data.frame(
      lon = c(denver[["lon"]], boston[["lon"]]),
      lat = c(denver[["lat"]], boston[["lat"]])
    ),
    coords = c("lon", "lat"),
    crs = 4326
  )
  # sf uses the WGS84 ellipsoid; the package uses a spherical earth of radius
  # 3959 miles. The two differ by well under 0.5% over this distance, so the
  # tolerance is on the model difference, not on arithmetic error.
  ref_miles <- as.numeric(sf::st_distance(pts)[1, 2]) / 1609.344

  # Bracket the package's own cut-off against the sf reference: the neighbour
  # must appear just above ref_miles and vanish just below it.
  lats <- c(denver[["lat"]], boston[["lat"]])
  lons <- c(denver[["lon"]], boston[["lon"]])

  expect_equal(
    mysterycall_calculate_spatial_density(
      lats, lons, radius = ref_miles * 1.005
    ),
    c(1L, 1L)
  )
  expect_equal(
    mysterycall_calculate_spatial_density(
      lats, lons, radius = ref_miles * 0.995
    ),
    c(0L, 0L)
  )
})

test_that("a missing coordinate yields NA, not a density of zero", {
  lats <- c(39.7392, 39.7492, NA_real_)
  lons <- c(-104.9903, -104.9903, -104.9903)

  expect_message(
    out <- mysterycall_calculate_spatial_density(lats, lons, radius = 15),
    "missing coordinate"
  )

  expect_true(is.na(out[[3L]]))
  # The complete points still see each other and not the incomplete one.
  expect_equal(out[1:2], c(1L, 1L))
})

test_that("out-of-domain latitude is rejected rather than counted", {
  expect_error(
    mysterycall_calculate_spatial_density(c(500, 500.0001), c(-83, -83)),
    "must lie within"
  )
  expect_error(
    mysterycall_calculate_spatial_density(c(-91, 40), c(-83, -83)),
    "`lats`"
  )
})

test_that("out-of-domain longitude is rejected rather than counted", {
  expect_error(
    mysterycall_calculate_spatial_density(c(40, 40.0001), c(9999, 9999)),
    "must lie within"
  )
  expect_error(
    mysterycall_calculate_spatial_density(c(40, 40), c(-181, -83)),
    "`lons`"
  )
})

test_that("non-numeric, NaN and infinite coordinates error informatively", {
  expect_error(
    mysterycall_calculate_spatial_density(c("a", "b"), c("c", "d")),
    "must be a numeric vector"
  )
  expect_error(
    mysterycall_calculate_spatial_density(c(40, NaN), c(-83, -83)),
    "NaN"
  )
  expect_error(
    mysterycall_calculate_spatial_density(c(40, Inf), c(-83, -83)),
    "infinite"
  )
})

test_that("mismatched and zero-length inputs are handled", {
  expect_error(
    mysterycall_calculate_spatial_density(c(40, 41), -83),
    "same length"
  )
  expect_error(
    mysterycall_calculate_spatial_density(40, -83, c(40, 41), 41),
    "same length"
  )
  expect_length(
    mysterycall_calculate_spatial_density(numeric(0), numeric(0)),
    0L
  )
})

test_that("target coordinates are validated and counted separately", {
  lats <- c(39.7392, 42.3601)
  lons <- c(-104.9903, -71.0589)

  # Two targets near Denver; self-exclusion does not apply to a target set.
  out <- mysterycall_calculate_spatial_density(
    lats, lons,
    target_lats = c(39.7392, 39.7492),
    target_lons = c(-104.9903, -104.9903),
    radius = 15
  )
  expect_equal(out, c(2L, 0L))

  expect_error(
    mysterycall_calculate_spatial_density(
      lats, lons,
      target_lats = c(500, 500), target_lons = c(-104, -104)
    ),
    "`target_lats`"
  )
})

test_that("an invalid radius is rejected", {
  expect_error(
    mysterycall_calculate_spatial_density(c(40, 41), c(-83, -83), radius = -5),
    "radius"
  )
})

test_that("mysterycall_calculate_hq_distance validates its coordinates", {
  expect_error(
    mysterycall_calculate_hq_distance(
      lats = c(500, 40),
      lons = c(-104, -104),
      platforms = c("Kindbody", "Kindbody"),
      matched_pairs = c("p1", "p1")
    ),
    "must lie within"
  )
})

test_that("validate_coordinates can reject missing pairs on request", {
  expect_error(
    validate_coordinates(c(40, NA), c(-83, -83), allow_missing = FALSE),
    "must not contain missing coordinates"
  )
  expect_true(validate_coordinates(c(40, NA), c(-83, -83)))
})
