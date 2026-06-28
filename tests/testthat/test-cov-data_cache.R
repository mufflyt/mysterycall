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

test_that("data_cache helpers are internal and not exported", {
  skip("R/data_cache.R contains only internal helpers (mysterycall_cache_dir, ensure_hrr_shapefile); none are exported")
})

test_that("mysterycall_cache_dir returns a character path", {
  dir <- mysterycall:::mysterycall_cache_dir()
  expect_type(dir, "character")
  expect_length(dir, 1L)
  expect_true(nzchar(dir))
})

test_that("mysterycall_cache_dir accepts path components", {
  dir_with_sub <- mysterycall:::mysterycall_cache_dir("hrr")
  expect_type(dir_with_sub, "character")
  expect_true(grepl("hrr", dir_with_sub))
})
