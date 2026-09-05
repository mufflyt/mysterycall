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

test_that("http_with_retry retries a transient error then succeeds", {
  calls <- 0L
  fn <- function() {
    calls <<- calls + 1L
    if (calls < 2L) stop("connection timeout")
    "OK"
  }
  testthat::local_mocked_bindings(status_code = function(...) 200L, .package = "httr")
  res <- mysterycall:::.mc_geocode_http_with_retry(fn, max_attempts = 3L,
                                                   initial_delay_ms = 1L)
  expect_equal(res, "OK")
  expect_equal(calls, 2L)
})

test_that("http_with_retry backs off on a 429 then returns the 200", {
  seq_status <- c(429L, 200L); i <- 0L
  testthat::local_mocked_bindings(
    status_code = function(...) { i <<- i + 1L; seq_status[i] }, .package = "httr")
  calls <- 0L
  fn <- function() { calls <<- calls + 1L; "resp" }
  res <- mysterycall:::.mc_geocode_http_with_retry(fn, max_attempts = 3L,
                                                   initial_delay_ms = 1L)
  expect_equal(res, "resp")
  expect_equal(calls, 2L)          # retried once, succeeded on the 2nd
})

test_that("http_with_retry gives up after max_attempts on persistent failure", {
  testthat::local_mocked_bindings(status_code = function(...) 503L, .package = "httr")
  calls <- 0L
  fn <- function() { calls <<- calls + 1L; "resp" }
  res <- mysterycall:::.mc_geocode_http_with_retry(fn, max_attempts = 2L,
                                                   initial_delay_ms = 1L)
  expect_equal(calls, 2L)          # tried twice, returns the last response
})

test_that("geocode_address maps batch results onto rows (offline, mocked)", {
  addr <- data.frame(
    street = c("1 A St", "2 B St", "9 Bad St"),
    city   = c("Denver", "Aurora", "Nowhere"),
    state  = c("CO", "CO", "ZZ"),
    zip    = c("80202", "80045", "00000")
  )
  testthat::local_mocked_bindings(
    .mc_census_batch = function(addresses, benchmark, vintage) {
      data.frame(
        id = 1:3,
        input_address = addr$street,
        match = c("Match", "Match", "No_Match"),
        match_type = c("Exact", "Exact", NA),
        matched_address = c("1 A ST", "2 B ST", NA),
        lon = c(-104.99, -104.84, NA), lat = c(39.74, 39.74, NA),
        census_tract = c("08031002000", "08001008100", NA),
        stringsAsFactors = FALSE
      )
    }
  )
  out <- mysterycall_geocode_address(addr, fallback = FALSE, verbose = FALSE)
  expect_equal(out$geo_lat, c(39.74, 39.74, NA))
  expect_equal(out$geo_source, c("census", "census", NA))
  expect_equal(out$geo_tract[2], "08001008100")
  expect_equal(out$geo_match[3], "No_Match")
})

test_that("geocode_address uses the fallback for Census misses (offline, mocked)", {
  addr <- data.frame(street = "9 Bad St", city = "Nowhere",
                     state = "CO", zip = "80999")
  testthat::local_mocked_bindings(
    .mc_census_batch = function(addresses, benchmark, vintage) {
      data.frame(id = 1L, input_address = "9 Bad St", match = "No_Match",
                 match_type = NA, matched_address = NA, lon = NA_real_,
                 lat = NA_real_, census_tract = NA_character_,
                 stringsAsFactors = FALSE)
    },
    .mc_geocode_one_fallback = function(addr, city, state, zip) {
      list(lon = -105.0, lat = 40.0, matched_address = "9 BAD ST",
           source = "nominatim")
    }
  )
  out <- mysterycall_geocode_address(addr, fallback = TRUE, verbose = FALSE)
  expect_equal(out$geo_lat, 40.0)
  expect_equal(out$geo_source, "nominatim")
  expect_equal(out$geo_match, "Match")
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

# ---------------------------------------------------------------------------
# Ragged Census batch responses (a No_Match row carries only three fields)
# ---------------------------------------------------------------------------

.mc_match_row   <- '2,"b",Match,Exact,"B ST","-104.9,39.7",x,L,08,031,004102,1000'
.mc_nomatch_row <- '1,"a",No_Match'

test_that("an all-unmatched batch parses to NA coordinates instead of erroring", {
  out <- mysterycall:::.mc_parse_census_batch_response(
    paste0(.mc_nomatch_row, "\n"), request_geographies = TRUE
  )
  expect_equal(nrow(out), 1L)
  expect_equal(out$match, "No_Match")
  expect_true(is.na(out$lat))
  expect_true(is.na(out$lon))
  expect_true(is.na(out$census_tract))
})

test_that("a matched address keeps its coordinates regardless of row order", {
  both  <- paste0(.mc_match_row, "\n", .mc_nomatch_row, "\n")
  flip  <- paste0(.mc_nomatch_row, "\n", .mc_match_row, "\n")

  a <- mysterycall:::.mc_parse_census_batch_response(both, request_geographies = TRUE)
  b <- mysterycall:::.mc_parse_census_batch_response(flip, request_geographies = TRUE)

  expect_equal(nrow(a), 2L)
  expect_equal(nrow(b), 2L)

  # The matched row is id 2 in both; readr used to size the frame from the
  # first row, so leading with No_Match discarded these coordinates entirely.
  ma <- a[a$id == 2L, ]
  mb <- b[b$id == 2L, ]
  expect_equal(ma$lat, 39.7)
  expect_equal(mb$lat, 39.7)
  expect_equal(ma$lon, -104.9)
  expect_equal(mb$lon, -104.9)
  expect_equal(ma$census_tract, "08031004102")
  expect_equal(mb$census_tract, "08031004102")

  # and the unmatched row stays unmatched in both orderings
  expect_true(is.na(a[a$id == 1L, ]$lat))
  expect_true(is.na(b[b$id == 1L, ]$lat))
})

test_that("a location-only response (no geographies) still parses", {
  out <- mysterycall:::.mc_parse_census_batch_response(
    '1,"a",Match,Exact,"A ST","-104.9,39.7",x,L\n', request_geographies = FALSE
  )
  expect_equal(nrow(out), 1L)
  expect_equal(out$lat, 39.7)
  expect_true(is.na(out$census_tract))
})

test_that("an empty response yields a zero-row frame with the right columns", {
  out <- mysterycall:::.mc_parse_census_batch_response("", request_geographies = TRUE)
  expect_equal(nrow(out), 0L)
  expect_true(all(c("id", "match", "lon", "lat", "census_tract") %in% names(out)))
})
