test_that("assign_area_covariates: NA coordinates yield NA covariates, no error", {
  df <- data.frame(lat = c(NA_real_, NA_real_), long = c(NA_real_, NA_real_))
  out <- mysterycall_assign_area_covariates(df, verbose = FALSE)
  expect_true(all(is.na(out$zcta)))
  expect_true(all(is.na(out$adi)))
  expect_true(all(is.na(out$svi)))
  expect_true(all(is.na(out$hhi)))
  expect_equal(unname(attr(out, "coverage")[["adi"]]), 0L)
})

test_that("assign_area_covariates: validates inputs", {
  expect_error(
    mysterycall_assign_area_covariates(data.frame(x = 1), lat_col = "lat"),
    "lat"
  )
})

test_that("assign_area_covariates: `which` selects covariate columns", {
  df <- data.frame(lat = NA_real_, long = NA_real_)
  out <- mysterycall_assign_area_covariates(df, which = "adi", verbose = FALSE)
  expect_true("adi" %in% names(out))
  expect_false("svi" %in% names(out))
  expect_false("hhi" %in% names(out))
})

test_that("assign_area_covariates: attaches ADI/SVI/HHI for a real coordinate", {
  testthat::skip_on_cran()
  testthat::skip_if_offline("geocoding.geo.census.gov")

  lat  <- 39.7392
  long <- -104.9903                        # downtown Denver
  df   <- data.frame(lat = lat, long = long)

  # skip_if_offline() only proves the host resolves. The Census geocoder can
  # answer and still return nothing usable -- a rate limit, a transient 5xx, an
  # empty result -- which used to fail all four assertions below for reasons
  # that have nothing to do with this package. Retry first, since that is the
  # common case and costs one request.
  out <- NULL
  for (attempt in 1:3) {
    out <- mysterycall_assign_area_covariates(df, verbose = FALSE)
    if (!is.na(out$zcta)) break
    if (attempt < 3) Sys.sleep(2)
  }

  # Still nothing. Skipping unconditionally here would make this test unable to
  # fail: a broken geocoding path in the package produces an NA ZCTA too.
  # .mc_geocode_point()$ok reports only whether the request succeeded and the
  # JSON parsed, independent of ZCTA extraction, so it separates the two cases.
  # ok = FALSE, the service did not answer -> skip. ok = TRUE, the service
  # answered and we failed to use it -> fall through and let the assertions
  # fail, which is a real defect.
  if (is.na(out$zcta)) {
    probe <- mysterycall:::.mc_geocode_point(long, lat)
    testthat::skip_if_not(
      isTRUE(probe$ok),
      "Census geocoder did not return a parseable response after 3 attempts"
    )
  }

  expect_equal(out$zcta, "80202")
  expect_true(is.finite(out$adi))
  expect_true(out$svi >= 0 && out$svi <= 1)
  expect_true(is.finite(out$hhi))          # Denver is an MSA
})
