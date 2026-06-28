library(testthat)
library(mysterycall)


# Tests for mysterycall_max_table
test_that("mysterycall_max_table returns the most frequent factor level", {
  vec <- factor(c("A", "B", "A", "C", "B", "B"))
  result <- suppressMessages(suppressWarnings(mysterycall_max_table(vec)))
  expect_equal(result, "B")
  expect_type(result, "character")
  expect_length(result, 1L)
})

test_that("mysterycall_max_table accepts a plain character vector and auto-converts", {
  vec <- c("Medicaid", "BCBS", "Medicaid", "Medicaid", "BCBS")
  result <- suppressMessages(suppressWarnings(mysterycall_max_table(vec)))
  expect_equal(result, "Medicaid")
  expect_type(result, "character")
})

test_that("mysterycall_max_table with mult=TRUE returns all tied-maximum levels", {
  # "A" and "B" each appear twice; "C" once — both should be returned
  vec <- factor(c("A", "B", "A", "B", "C"))
  result <- suppressMessages(suppressWarnings(mysterycall_max_table(vec, mult = TRUE)))
  expect_true(all(c("A", "B") %in% result))
  expect_false("C" %in% result)
})

test_that("mysterycall_max_table with mult=FALSE returns only one level even when tied", {
  vec <- factor(c("X", "Y", "X", "Y"))
  result <- suppressMessages(suppressWarnings(mysterycall_max_table(vec, mult = FALSE)))
  expect_length(result, 1L)
  expect_true(result %in% c("X", "Y"))
})

test_that("mysterycall_max_table returns character(0) for zero-length input", {
  result_factor <- suppressMessages(suppressWarnings(mysterycall_max_table(factor(character(0)))))
  expect_equal(result_factor, character(0))

  result_char <- suppressMessages(suppressWarnings(mysterycall_max_table(character(0))))
  expect_equal(result_char, character(0))
})

test_that("mysterycall_max_table handles NA values (NAs are not factor levels)", {
  # NAs do not form a level, so the non-NA mode should win
  vec <- c("Alpha", NA, "Alpha", NA, "Beta")
  result <- suppressMessages(suppressWarnings(mysterycall_max_table(vec)))
  expect_equal(result, "Alpha")
})

test_that("mysterycall_max_table errors on list input", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_max_table(list("A", "B", "A"))
    ))
  )
})
