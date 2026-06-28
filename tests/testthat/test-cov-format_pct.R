library(testthat)
library(mysterycall)


# Tests for mysterycall_format_pct

test_that("mysterycall_format_pct formats single numeric value with default digits", {
  result <- suppressMessages(suppressWarnings(mysterycall_format_pct(0.12345)))
  expect_type(result, "character")
  expect_equal(result, "12.3%")
})

test_that("mysterycall_format_pct formats a vector with custom digits", {
  values <- c(0.12345, 0.6789, 0.54321)
  result <- suppressMessages(suppressWarnings(mysterycall_format_pct(values, digits = 2)))
  expect_length(result, 3L)
  expect_equal(result, c("12.35%", "67.89%", "54.32%"))
})

test_that("mysterycall_format_pct handles NA input by returning NA_character_", {
  result <- suppressMessages(suppressWarnings(mysterycall_format_pct(NA_real_)))
  expect_equal(result, NA_character_)

  # mixed vector: NA should propagate to the corresponding position only
  mixed <- suppressMessages(suppressWarnings(mysterycall_format_pct(c(0.5, NA_real_, 1.0))))
  expect_equal(mixed[[2L]], NA_character_)
  expect_equal(mixed[[1L]], "50.0%")
  expect_equal(mixed[[3L]], "100.0%")
})

test_that("mysterycall_format_pct handles zero and boundary values correctly", {
  expect_equal(suppressMessages(suppressWarnings(mysterycall_format_pct(0))), "0.0%")
  expect_equal(suppressMessages(suppressWarnings(mysterycall_format_pct(1))), "100.0%")
  expect_equal(suppressMessages(suppressWarnings(mysterycall_format_pct(0.5, digits = 0))), "50%")
})

test_that("mysterycall_format_pct errors on non-numeric input", {
  expect_error(suppressMessages(suppressWarnings(mysterycall_format_pct("abc"))))
})
