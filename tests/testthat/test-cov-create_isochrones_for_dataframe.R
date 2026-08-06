library(testthat)
library(mysterycall)

# create_isochrones_for_dataframe() was relocated to the mysterymaps package; the shim errors with a pointer
# to its replacement. This needs no network -- it is a plain, offline stop().

test_that("create_isochrones_for_dataframe() errors and points to the mysterymaps replacement", {
  expect_error(
    mysterycall:::create_isochrones_for_dataframe(),
    "moved to the mysterymaps package"
  )
})
