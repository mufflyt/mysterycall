library(testthat)
library(mysterycall)


# Tests for mysterycall_min_table
test_that("mysterycall_min_table returns single least-frequent level", {
  vec <- factor(c("A", "B", "A", "C", "B", "B"))
  # A=2, B=3, C=1 → minimum is C
  result <- suppressMessages(suppressWarnings(mysterycall_min_table(vec)))
  expect_equal(result, "C")
  expect_length(result, 1L)
  expect_type(result, "character")
})

test_that("mysterycall_min_table with mult=TRUE returns all tied minimums", {
  vec <- factor(c("X", "Y", "Z", "X"))
  # X=2, Y=1, Z=1 → tied minimum: Y and Z
  result <- suppressMessages(suppressWarnings(
    mysterycall_min_table(vec, mult = TRUE)
  ))
  expect_setequal(result, c("Y", "Z"))
  expect_length(result, 2L)
})

test_that("mysterycall_min_table coerces character input to factor", {
  char_vec <- c("Medicaid", "BCBS", "Medicaid", "Medicaid", "BCBS", "Self-pay")
  # BCBS=2, Medicaid=3, Self-pay=1 → minimum is Self-pay
  result <- suppressMessages(suppressWarnings(
    mysterycall_min_table(char_vec)
  ))
  expect_equal(result, "Self-pay")
})

test_that("mysterycall_min_table returns character(0) for zero-length input", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_min_table(character(0))
  ))
  expect_equal(result, character(0))
  expect_length(result, 0L)

  result_fac <- suppressMessages(suppressWarnings(
    mysterycall_min_table(factor(character(0)))
  ))
  expect_equal(result_fac, character(0))
})

test_that("mysterycall_min_table handles all-NA input silently returning NA", {
  # factor(c(NA, NA)) has 0 levels; tabulate returns 0 (1 bin, 0 counts);
  # the function then indexes levels(f)[1] which is NA for a 0-level factor
  result <- suppressMessages(suppressWarnings(
    mysterycall_min_table(c(NA_character_, NA_character_))
  ))
  expect_type(result, "character")
  expect_true(is.na(result))
})

test_that("mysterycall_min_table handles single unique level", {
  vec <- c("OB/GYN", "OB/GYN", "OB/GYN")
  result <- suppressMessages(suppressWarnings(mysterycall_min_table(vec)))
  expect_equal(result, "OB/GYN")
})
