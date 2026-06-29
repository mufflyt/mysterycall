library(testthat)
testthat::skip_if_not_installed("arsenal")
library(arsenal)

# Define the test cases
test_that("errors are thrown for invalid inputs", {
  expect_error(mysterycall_write_arsenal_table(123, "filename"))
  expect_error(mysterycall_write_arsenal_table(data.frame(), 123))
})
