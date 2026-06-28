library(testthat)
library(mysterycall)

# Tests for the `fips` dataset
# fips is a lazy-loaded data.frame: 51 rows x 3 cols
# (state, state_code, state_name) — one row per U.S. state/territory

test_that("fips dataset loads and has expected shape", {
  suppressMessages(suppressWarnings(data("fips", package = "mysterycall")))
  expect_s3_class(fips, "data.frame")
  expect_equal(nrow(fips), 51L)
  expect_equal(ncol(fips), 3L)
  expect_named(fips, c("state", "state_code", "state_name"), ignore.order = FALSE)
})

test_that("fips columns contain no missing values and are correctly formatted", {
  suppressMessages(suppressWarnings(data("fips", package = "mysterycall")))
  expect_equal(sum(is.na(fips$state)),      0L)
  expect_equal(sum(is.na(fips$state_code)), 0L)
  expect_equal(sum(is.na(fips$state_name)), 0L)
  # All state abbreviations are exactly 2 characters
  expect_true(all(nchar(fips$state) == 2L))
  # All state FIPS codes are exactly 2 characters (zero-padded strings)
  expect_true(all(nchar(fips$state_code) == 2L))
  # state_code values must look like zero-padded numbers "01"–"99"
  expect_true(all(grepl("^[0-9]{2}$", fips$state_code)))
})

test_that("fips dataset has no duplicate states or state codes", {
  suppressMessages(suppressWarnings(data("fips", package = "mysterycall")))
  expect_false(any(duplicated(fips$state)))
  expect_false(any(duplicated(fips$state_code)))
})

test_that("fips contains known FIPS code values for specific states", {
  suppressMessages(suppressWarnings(data("fips", package = "mysterycall")))
  get_code <- function(abbr) fips$state_code[fips$state == abbr]
  expect_equal(get_code("AL"), "01")
  expect_equal(get_code("AK"), "02")
  expect_equal(get_code("WY"), "56")
  # Colorado is FIPS 08
  expect_equal(get_code("CO"), "08")
  # Confirm a lookup for a non-existent abbreviation returns character(0)
  expect_length(get_code("XX"), 0L)
})

test_that("subsetting fips with a bad column name behaves as expected", {
  suppressMessages(suppressWarnings(data("fips", package = "mysterycall")))
  # Accessing a nonexistent column via $ silently returns NULL
  expect_null(fips$nonexistent_column_xyz)
  # Accessing via [[ also returns NULL for a missing column
  expect_null(fips[["nonexistent_column_xyz"]])
  # subset() with a non-existent column name throws an error
  expect_error(
    subset(fips, select = "totally_bogus_col"),
    "undefined columns selected"
  )
})
