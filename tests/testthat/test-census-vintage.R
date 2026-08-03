test_that("census benchmark and vintage are pinned, not tracking 'Current'", {
  # The whole point of the pin: 'Current_Current' would follow Bureau-side
  # vintage rolls and desynchronise geocoded keys from the bundled 2020-vintage
  # ZCTA datasets. If someone relaxes this, the test should fail loudly.
  expect_identical(mysterycall:::.MC_CENSUS_VINTAGE, "Census2020_Current")
  expect_identical(mysterycall:::.MC_CENSUS_BENCHMARK, "Public_AR_Current")
})

test_that("geocode_address defaults to the pinned vintage", {
  fm <- formals(mysterycall::mysterycall_geocode_address)
  expect_identical(as.character(fm$vintage), ".MC_CENSUS_VINTAGE")
  expect_identical(as.character(fm$benchmark), ".MC_CENSUS_BENCHMARK")
})

test_that(".mc_geo_layer matches ZCTA layer names across vintages", {
  # Census2020_Current spells it one way, Current_Current another. Both must
  # resolve, because an exact-string match is what silently yields NA.
  v2020 <- list(`Zip Code Tabulation Areas` = list(list(GEOID = "80202")))
  vcurr <- list(`2020 Census ZIP Code Tabulation Areas` = list(list(GEOID = "80202")))
  pat <- "zip code tabulation area"
  expect_equal(mysterycall:::.mc_geo_layer(v2020, pat)[[1L]]$GEOID, "80202")
  expect_equal(mysterycall:::.mc_geo_layer(vcurr, pat)[[1L]]$GEOID, "80202")
})

test_that(".mc_geo_layer returns NULL rather than erroring on a missing layer", {
  expect_null(mysterycall:::.mc_geo_layer(list(Counties = list()), "census tract"))
})

test_that(".mc_geo_layer does not confuse metropolitan with micropolitan", {
  g <- list(`Combined Statistical Areas`     = list(list(BASENAME = "wrong")),
            `Metropolitan Statistical Areas` = list(list(BASENAME = "Denver")))
  expect_equal(
    mysterycall:::.mc_geo_layer(g, "metropolitan statistical area")[[1L]]$BASENAME,
    "Denver")
})

test_that(".mc_check_acs_vintage warns on pre-2022 boundary-sensitive pulls", {
  expect_warning(
    mysterycall:::.mc_check_acs_vintage(2015, "tract", "f()"),
    "2010-vintage boundaries")
  expect_warning(
    mysterycall:::.mc_check_acs_vintage(2019, "zcta", "f()"),
    "2010-vintage boundaries")
})

test_that(".mc_check_acs_vintage stays quiet when there is nothing to warn about", {
  # Recent year: on 2020 boundaries already.
  expect_silent(mysterycall:::.mc_check_acs_vintage(2022, "tract", "f()"))
  # Stable geography: county FIPS did not change with the 2020 Census.
  expect_silent(mysterycall:::.mc_check_acs_vintage(2015, "county", "f()"))
  expect_silent(mysterycall:::.mc_check_acs_vintage(2015, "state", "f()"))
})

test_that(".mc_check_acs_vintage is silenceable and tolerates bad input", {
  withr::with_options(list(mysterycall.quiet_vintage = TRUE), {
    expect_silent(mysterycall:::.mc_check_acs_vintage(2015, "tract", "f()"))
  })
  expect_silent(mysterycall:::.mc_check_acs_vintage(NA_integer_, "tract", "f()"))
  expect_silent(mysterycall:::.mc_check_acs_vintage(NULL, "tract", "f()"))
})
