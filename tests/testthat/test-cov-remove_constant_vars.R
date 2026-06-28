library(testthat)
library(mysterycall)


# Tests for mysterycall_remove_constants

test_that("mysterycall_remove_constants removes constant columns and keeps varying ones", {
  df <- data.frame(
    a     = 1:4,
    b     = c(5, 5, 5, 5),          # constant numeric
    c     = c("x", "y", "x", "z"),  # varying character
    const = rep("same", 4L),         # constant character
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_remove_constants(df)
  ))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 4L)
  expect_true("a" %in% names(result))
  expect_true("c" %in% names(result))
  expect_false("b" %in% names(result))
  expect_false("const" %in% names(result))
})

test_that("mysterycall_remove_constants returns data frame unchanged when no columns are constant", {
  df <- data.frame(
    x = 1:3,
    y = c("a", "b", "c"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_remove_constants(df)
  ))
  expect_equal(names(result), names(df))
  expect_equal(nrow(result), 3L)
})

test_that("mysterycall_remove_constants returns empty data frame unchanged (zero rows)", {
  empty_df <- data.frame(a = integer(0), b = character(0), stringsAsFactors = FALSE)
  result <- suppressMessages(suppressWarnings(
    mysterycall_remove_constants(empty_df)
  ))
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_equal(names(result), names(empty_df))
})

test_that("mysterycall_remove_constants treats all-NA column as constant and removes it", {
  df <- data.frame(
    good  = c(1L, 2L, 3L),
    all_na = c(NA_real_, NA_real_, NA_real_),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_remove_constants(df)
  ))
  expect_true("good" %in% names(result))
  expect_false("all_na" %in% names(result))
})

test_that("mysterycall_remove_constants errors on non-data-frame input", {
  expect_error(
    suppressMessages(mysterycall_remove_constants(c(1, 2, 3))),
    regexp = NULL
  )
  expect_error(
    suppressMessages(mysterycall_remove_constants("text")),
    regexp = NULL
  )
  expect_error(
    suppressMessages(mysterycall_remove_constants(NULL)),
    regexp = NULL
  )
})
