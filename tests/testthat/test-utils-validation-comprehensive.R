# Comprehensive tests for validation utilities
library(testthat)

test_that("validate_dataframe: Basic functionality", {
  # Valid data frame
  df <- data.frame(x = 1:3, y = letters[1:3])
  expect_identical(mysterycall:::validate_dataframe(df), df)
  expect_invisible(mysterycall:::validate_dataframe(df))

  # Empty data frame (allowed by default)
  empty_df <- data.frame()
  expect_identical(mysterycall:::validate_dataframe(empty_df), empty_df)

  # Zero rows but with columns
  zero_row_df <- data.frame(x = integer(0), y = character(0))
  expect_identical(mysterycall:::validate_dataframe(zero_row_df), zero_row_df)
})

test_that("validate_dataframe: NULL handling", {
  # NULL not allowed by default
  expect_error(
    mysterycall:::validate_dataframe(NULL),
    "`data` must be a data frame; received NULL.",
    fixed = TRUE
  )

  # NULL allowed when specified
  expect_null(mysterycall:::validate_dataframe(NULL, allow_null = TRUE))
})

test_that("validate_dataframe: Non-data.frame inputs", {
  expect_error(
    mysterycall:::validate_dataframe(list(x = 1, y = 2)),
    "`data` must be a data frame; received an object of class list",
    fixed = TRUE
  )

  expect_error(
    mysterycall:::validate_dataframe(matrix(1:6, nrow = 2)),
    "`data` must be a data frame; received an object of class matrix, array",
    fixed = TRUE
  )

  expect_error(
    mysterycall:::validate_dataframe(1:5),
    "`data` must be a data frame; received an object of class integer",
    fixed = TRUE
  )
})

test_that("validate_dataframe: Zero rows handling", {
  empty_df <- data.frame()

  # Zero rows allowed by default
  expect_identical(mysterycall:::validate_dataframe(empty_df, allow_zero_rows = TRUE), empty_df)

  # Zero rows not allowed when specified
  expect_error(
    mysterycall:::validate_dataframe(empty_df, allow_zero_rows = FALSE),
    "`data` must contain at least one row",
    fixed = TRUE
  )
})

test_that("validate_dataframe: Custom names", {
  expect_error(
    mysterycall:::validate_dataframe(NULL, name = "my_dataset"),
    "`my_dataset` must be a data frame; received NULL.",
    fixed = TRUE
  )

  expect_error(
    mysterycall:::validate_dataframe(1:5, name = "user_input"),
    "`user_input` must be a data frame; received an object of class integer",
    fixed = TRUE
  )
})

test_that("validate_dataframe: Edge cases", {
  # Tibbles should work
  if (requireNamespace("tibble", quietly = TRUE)) {
    tbl <- tibble::tibble(x = 1:3, y = letters[1:3])
    expect_identical(mysterycall:::validate_dataframe(tbl), tbl)
  }

  # Data tables should work if they inherit from data.frame
  if (requireNamespace("data.table", quietly = TRUE)) {
    dt <- data.table::data.table(x = 1:3, y = letters[1:3])
    expect_identical(mysterycall:::validate_dataframe(dt), dt)
  }
})

test_that("validate_dataframe: Performance with large data", {
  # Large data frame should validate quickly
  large_df <- data.frame(
    x = 1:10000,
    y = rep(letters[1:26], length.out = 10000)
  )

  start_time <- Sys.time()
  result <- mysterycall:::validate_dataframe(large_df)
  end_time <- Sys.time()

  expect_identical(result, large_df)
  expect_lt(as.numeric(end_time - start_time, units = "secs"), 0.1)
})

test_that("validate_dataframe: Column name preservation", {
  df <- data.frame(
    "strange column name" = 1:3,
    "another.weird.name" = letters[1:3],
    check.names = FALSE
  )

  result <- mysterycall:::validate_dataframe(df)
  expect_equal(names(result), names(df))
  expect_identical(result, df)
})

test_that("validate_dataframe: Attribute preservation", {
  df <- data.frame(x = 1:3, y = letters[1:3])
  attr(df, "custom_attr") <- "test_value"
  class(df) <- c("custom_class", "data.frame")

  result <- mysterycall:::validate_dataframe(df)
  expect_equal(attr(result, "custom_attr"), "test_value")
  expect_equal(class(result), c("custom_class", "data.frame"))
})

test_that("validate_dataframe: Property-based test for valid data frames", {
  # Generate random valid data frames
  for (i in 1:10) {
    n_rows <- sample(1:100, 1)
    n_cols <- sample(1:10, 1)

    df <- data.frame(
      matrix(runif(n_rows * n_cols), nrow = n_rows, ncol = n_cols)
    )

    expect_identical(mysterycall:::validate_dataframe(df), df)
    expect_silent(mysterycall:::validate_dataframe(df))
  }
})