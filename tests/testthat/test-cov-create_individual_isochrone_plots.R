library(testthat)
library(mysterycall)

# create_individual_isochrone_plots() was relocated to the mysterymaps package; the shim errors with a pointer
# to its replacement. This needs no network -- it is a plain, offline stop().

test_that("create_individual_isochrone_plots() errors and points to the mysterymaps replacement", {
  expect_error(
    mysterycall:::create_individual_isochrone_plots(),
    "moved to the mysterymaps package"
  )
})
