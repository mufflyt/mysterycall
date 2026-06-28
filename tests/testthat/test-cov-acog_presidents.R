library(testthat)
library(mysterycall)

# -------------------------------------------------------------------------
# Tests for the acog_presidents dataset
# The source file (R/acog_presidents.R) documents this dataset; it is a
# tibble with 71 rows and 6 columns loaded via data(acog_presidents).
# -------------------------------------------------------------------------

test_that("acog_presidents loads and has correct dimensions", {
  suppressMessages(suppressWarnings(data(acog_presidents, package = "mysterycall")))
  expect_s3_class(acog_presidents, "data.frame")
  expect_equal(nrow(acog_presidents), 71L)
  expect_equal(ncol(acog_presidents), 6L)
})

test_that("acog_presidents has expected column names and types", {
  suppressMessages(suppressWarnings(data(acog_presidents, package = "mysterycall")))
  expected_cols <- c("first", "last", "middle", "President", "honorrific", "Presidency")
  expect_true(all(expected_cols %in% names(acog_presidents)))

  # Character columns
  expect_type(acog_presidents$first,      "character")
  expect_type(acog_presidents$last,       "character")
  expect_type(acog_presidents$President,  "character")
  expect_type(acog_presidents$honorrific, "character")

  # Numeric presidency year
  expect_type(acog_presidents$Presidency, "double")
})

test_that("acog_presidents Presidency years are in a plausible historical range", {
  suppressMessages(suppressWarnings(data(acog_presidents, package = "mysterycall")))
  years <- acog_presidents$Presidency
  expect_true(all(!is.na(years)), info = "Presidency column must have no NAs")
  expect_true(all(years >= 1951L), info = "Earliest presidency on record is 1951")
  expect_true(all(years <= as.integer(format(Sys.Date(), "%Y")) + 1L),
              info = "No future presidency years")
})

test_that("acog_presidents first and last name columns have no NAs", {
  suppressMessages(suppressWarnings(data(acog_presidents, package = "mysterycall")))
  expect_false(anyNA(acog_presidents$first),
               label = "first column should have no NAs")
  expect_false(anyNA(acog_presidents$last),
               label = "last column should have no NAs")
  expect_false(anyNA(acog_presidents$President),
               label = "President column should have no NAs")
  # Middle name is legitimately missing for some presidents
  expect_true(anyNA(acog_presidents$middle),
              label = "middle column is expected to have at least one NA")
})

test_that("acog_presidents raises an error when a non-existent column is accessed", {
  suppressMessages(suppressWarnings(data(acog_presidents, package = "mysterycall")))
  # Accessing a column that does not exist returns NULL (not an error) from `$`,
  # but using [[]] with an out-of-bounds integer errors; this tests the data
  # object's standard R behaviour.
  expect_null(suppressWarnings(acog_presidents$nonexistent_column))
  expect_error(acog_presidents[[999L]], regexp = NULL)
})
