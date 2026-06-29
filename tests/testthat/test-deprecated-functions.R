library(testthat)

# Deprecated functions must:
#   1. Either stop (for functionality moved to the mysterymaps package), or
#   2. Emit a deprecation warning via .Deprecated() and delegate correctly.
# All behavior verified against source in R/deprecated.R.

# test_and_process_isochrones now stops outright — the isochrone workflow moved
# to the mysterymaps package (no warn-and-delegate). process_and_save_isochrones
# was removed entirely and is no longer shimmed here.

test_that("test_and_process_isochrones - stops, pointing to the mysterymaps package", {
  expect_error(
    test_and_process_isochrones(data.frame()),
    "moved to the mysterymaps package"
  )
})

test_that("test_and_process_isochrones - error message names the replacement function", {
  err <- tryCatch(
    test_and_process_isochrones(data.frame()),
    error = function(e) conditionMessage(e)
  )
  expect_true(grepl("mysterymaps_isochrones_for_df", err))
})

test_that("search_npi - emits deprecation warning when called", {
  skip_on_cran()
  # search_npi delegates to mysterycall_search_and_process_npi, which makes API calls.
  # Test only that the deprecation warning fires before any downstream work.
  df <- data.frame(first = "Jane", last = "Smith")
  # The deprecation warning fires immediately; the subsequent error (missing NPI
  # or network) is irrelevant — we just need the warning.
  expect_warning(
    tryCatch(search_npi(df), error = function(e) NULL),
    regexp = "deprecated|mysterycall_search_and_process_npi",
    ignore.case = TRUE
  )
})

test_that("search_npi - stops if input lacks first/last columns", {
  df <- data.frame(npi = "1234567890")   # missing first and last
  expect_error(
    suppressWarnings(search_npi(df)),
    "first|last"
  )
})

test_that("search_npi - stops on non-data-frame non-path input", {
  expect_error(
    suppressWarnings(search_npi(42L)),
    "data frame or a file path"
  )
})
