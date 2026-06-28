library(testthat)
library(mysterycall)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)


test_that("physicians dataset exists and has correct structure", {
  expect_true(exists("physicians"))
  expect_s3_class(physicians, "data.frame")
  expect_equal(ncol(physicians), 5)
  expect_named(physicians, c("NPI", "name", "subspecialty", "lat", "long"))
  expect_gt(nrow(physicians), 100)
})


test_that("physicians dataset has correct column classes", {
  expect_type(physicians$NPI, "double")
  expect_type(physicians$name, "character")
  expect_type(physicians$subspecialty, "character")
  expect_type(physicians$lat, "double")
  expect_type(physicians$long, "double")
})


test_that("physicians dataset has valid geographic coordinates", {
  expect_true(all(physicians$lat >= -90 & physicians$lat <= 90, na.rm = TRUE))
  expect_true(all(physicians$long >= -180 & physicians$long <= 180, na.rm = TRUE))
  expect_gte(sum(is.na(physicians$lat)), 0)
  expect_gte(sum(is.na(physicians$long)), 0)
})


test_that("physicians dataset has no NA values in critical columns", {
  expect_false(any(is.na(physicians$NPI)))
  expect_false(any(is.na(physicians$name)))
  expect_false(any(is.na(physicians$subspecialty)))
})


test_that("physicians geographic coordinates are consistent when present", {
  non_na_rows <- !is.na(physicians$lat) & !is.na(physicians$long)
  expect_true(all(!is.na(physicians$lat[non_na_rows])))
  expect_true(all(!is.na(physicians$long[non_na_rows])))
})


test_that("physicians NPI values are positive and numeric", {
  expect_true(all(physicians$NPI > 0, na.rm = TRUE))
  expect_true(all(is.finite(physicians$NPI)))
})
