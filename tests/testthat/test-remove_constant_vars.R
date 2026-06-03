library(testthat)
testthat::skip_if_not_installed("dplyr")
library(dplyr)

# Test Case 1: Remove constant variables from a data frame
test_that("Constant variables are removed correctly", {
  # Create a sample data frame with constant and non-constant variables
  data_frame <- data.frame(
    constant_col = rep(1, 5),
    varying_col1 = 1:5,
    varying_col2 = c("a", "b", "a", "b", "c")
  )

  # Run the function
  result <- mysterycall:::mysterycall_remove_constants(data_frame)

  # Check that the constant column is removed
  expect_false("constant_col" %in% names(result))
  # Check that non-constant columns are still present
  expect_true(all(c("varying_col1", "varying_col2") %in% names(result)))
})

# Test Case 2: Handle data frame with no constant variables
test_that("No constant variables are unchanged", {
  # Create a sample data frame with no constant variables
  data_frame <- data.frame(
    varying_col1 = 1:5,
    varying_col2 = c("a", "b", "a", "b", "c")
  )

  # Run the function
  result <- mysterycall:::mysterycall_remove_constants(data_frame)

  # Check that no columns are removed
  expect_equal(ncol(result), ncol(data_frame))
})

# Test Case 3: Handle empty data frame
test_that("Empty data frame is handled correctly", {
  # Create an empty data frame
  data_frame <- data.frame()

  # Run the function
  result <- mysterycall:::mysterycall_remove_constants(data_frame)

  # Check that the result is also an empty data frame
  expect_equal(ncol(result), 0)
  expect_equal(nrow(result), 0)
})

# Test Case 4: Data frame with all constant variables
test_that("Data frame with all constant variables is empty afterwards", {
  # Create a sample data frame where all columns are constant
  data_frame <- data.frame(
    constant_col1 = rep(1, 5),
    constant_col2 = rep("a", 5)
  )

  # Run the function
  result <- mysterycall:::mysterycall_remove_constants(data_frame)

  # Check that all columns are removed
  expect_equal(ncol(result), 0)
})

