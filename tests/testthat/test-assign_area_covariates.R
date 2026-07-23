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
  df  <- data.frame(lat = 39.7392, long = -104.9903)  # downtown Denver
  out <- mysterycall_assign_area_covariates(df, verbose = FALSE)
  expect_equal(out$zcta, "80202")
  expect_true(is.finite(out$adi))
  expect_true(out$svi >= 0 && out$svi <= 1)
  expect_true(is.finite(out$hhi))          # Denver is an MSA
})
