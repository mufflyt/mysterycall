# The Census request/response seams are network-free and unit-testable.

test_that("parse_census_batch_response parses matched + unmatched rows", {
  # Two geographies-endpoint rows: one Match with coords+tract, one No_Match.
  csv <- paste(
    '"1","12631 E 17TH AVE, AURORA, CO, 80045","Match","Exact","12631 E 17TH AVE, AURORA, CO, 80045","-104.84108,39.74358","639173252","R","08","001","008100","1028"',
    '"2","999 NOWHERE RD, NOWHERE, ZZ, 00000","No_Match",,,,,,,,,',
    sep = "\n"
  )
  out <- mysterycall:::.mc_parse_census_batch_response(csv, request_geographies = TRUE)
  expect_equal(nrow(out), 2L)
  expect_equal(out$match, c("Match", "No_Match"))
  expect_equal(round(out$lat[1], 4), 39.7436)
  expect_equal(round(out$lon[1], 4), -104.8411)
  expect_equal(out$census_tract[1], "08001008100")   # state+county+tract
  expect_true(is.na(out$lat[2]))
  expect_true(is.na(out$census_tract[2]))
})

test_that("parse_census_batch_response tolerates empty input", {
  out <- mysterycall:::.mc_parse_census_batch_response("", request_geographies = TRUE)
  expect_equal(nrow(out), 0L)
})

test_that("build_census_batch_request writes a headerless 5-column CSV", {
  addr <- data.frame(address = "12631 E 17th Ave", city = "Aurora",
                     state = "CO", zip = "80045-1234", stringsAsFactors = FALSE)
  req <- mysterycall:::.mc_build_census_batch_request(addr)
  on.exit(unlink(req$temp_file), add = TRUE)
  expect_true(grepl("addressbatch$", req$url))
  line <- readLines(req$temp_file, n = 1L)
  # id,street,city,state,zip -- ZIP trimmed to 5 digits, no header
  expect_match(line, "^1,")
  expect_match(line, ",80045$")
})

test_that("geocode_address validates inputs", {
  expect_error(
    mysterycall_geocode_address(data.frame(x = 1)),
    "street"
  )
})

test_that("geocode_address end-to-end against Census (live)", {
  testthat::skip_on_cran()
  testthat::skip_if_offline("geocoding.geo.census.gov")
  addr <- data.frame(street = "12631 E 17th Ave", city = "Aurora",
                     state = "CO", zip = "80045")
  out <- mysterycall_geocode_address(addr, fallback = FALSE, verbose = FALSE)
  expect_equal(out$geo_match, "Match")
  expect_true(abs(out$geo_lat - 39.7436) < 0.01)
  expect_equal(nchar(out$geo_tract), 11L)
})
