library(testthat)
testthat::skip_if_not_installed("arsenal")
library(arsenal)

# Define the test cases
test_that("errors are thrown for invalid inputs", {
  expect_error(mysterycall_write_arsenal_table(123, "filename"), "'object' must be a data frame, not numeric")
  expect_error(mysterycall_write_arsenal_table(data.frame(), 123), "'filename' must be a character string, not numeric")
})
