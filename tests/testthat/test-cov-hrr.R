library(testthat)
library(mysterycall)

# hrr() was relocated to the mysterymaps package; the shim errors with a pointer
# to its replacement. This needs no network -- it is a plain, offline stop().

test_that("hrr() errors and points to the mysterymaps replacement", {
  expect_error(
    mysterycall:::hrr(),
    "moved to the mysterymaps package"
  )
})
