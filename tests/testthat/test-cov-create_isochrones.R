library(testthat)
library(mysterycall)

# create_isochrones() was relocated to the mysterymaps package; the shim errors with a pointer
# to its replacement. This needs no network -- it is a plain, offline stop().

test_that("create_isochrones() errors and points to the mysterymaps replacement", {
  expect_error(
    mysterycall:::create_isochrones(),
    "moved to the mysterymaps package"
  )
})
