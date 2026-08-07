library(testthat)
library(mysterycall)

# map_create_base() was relocated to the mysterymaps package; the shim errors with a pointer
# to its replacement. This needs no network -- it is a plain, offline stop().

test_that("map_create_base() errors and points to the mysterymaps replacement", {
  expect_error(
    mysterycall:::map_create_base(),
    "moved to the mysterymaps package"
  )
})
