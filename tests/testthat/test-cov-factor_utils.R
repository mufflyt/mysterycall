library(testthat)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)

# ============================================================================
# Tests for mysterycall_reorder_by_freq
# ============================================================================

test_that("mysterycall_reorder_by_freq: happy path with character vector", {
  x <- c("B", "A", "A", "C", "B", "B", "C")
  result <- mysterycall_reorder_by_freq(x)

  expect_s3_class(result, "factor")
  expect_length(result, length(x))
  # B appears 3 times, A and C appear 2 times each
  expect_equal(levels(result)[1], "B")
  # Second and third levels are A and C (tied at 2), order by appearance
  expect_true(levels(result)[2] %in% c("A", "C"))
  expect_true(levels(result)[3] %in% c("A", "C"))
})

test_that("mysterycall_reorder_by_freq: with decreasing=TRUE (default)", {
  x <- c("A", "A", "A", "B", "B", "C")
  result <- mysterycall_reorder_by_freq(x, decreasing = TRUE)

  expect_s3_class(result, "factor")
  expect_equal(levels(result)[1], "A")  # 3 occurrences
  expect_equal(levels(result)[2], "B")  # 2 occurrences
  expect_equal(levels(result)[3], "C")  # 1 occurrence
})

test_that("mysterycall_reorder_by_freq: with decreasing=FALSE", {
  x <- c("A", "A", "A", "B", "B", "C")
  result <- mysterycall_reorder_by_freq(x, decreasing = FALSE)

  expect_s3_class(result, "factor")
  expect_equal(levels(result)[1], "C")  # 1 occurrence (least frequent)
  expect_equal(levels(result)[2], "B")  # 2 occurrences
  expect_equal(levels(result)[3], "A")  # 3 occurrences (most frequent)
})

test_that("mysterycall_reorder_by_freq: with NA values (na_level=NULL)", {
  x <- c("B", "A", "A", "C", "B", "B", "C", NA)
  result <- mysterycall_reorder_by_freq(x, na_level = NULL)

  expect_s3_class(result, "factor")
  # NA should be preserved as NA, not a level
  expect_true(any(is.na(result)))
  expect_true(!("NA" %in% levels(result)))
})

test_that("mysterycall_reorder_by_freq: with NA values and na_level specified", {
  x <- c("B", "A", "A", "C", "B", "B", "C", NA)
  result <- mysterycall_reorder_by_freq(x, na_level = "Missing")

  expect_s3_class(result, "factor")
  # NA should be converted to "Missing" and last level
  expect_true("Missing" %in% levels(result))
  expect_equal(levels(result)[length(levels(result))], "Missing")
  expect_false(any(is.na(result)))
})

test_that("mysterycall_reorder_by_freq: with factor input", {
  x <- factor(c("B", "A", "A", "C", "B", "B"), levels = c("A", "B", "C", "D"))
  result <- mysterycall_reorder_by_freq(x)

  expect_s3_class(result, "factor")
  expect_equal(levels(result)[1], "B")  # B is most frequent (3 times)
})

test_that("mysterycall_reorder_by_freq: with single value repeated", {
  x <- c("A", "A", "A", "A")
  result <- mysterycall_reorder_by_freq(x)

  expect_s3_class(result, "factor")
  expect_equal(length(levels(result)), 1)
  expect_equal(levels(result)[1], "A")
})

test_that("mysterycall_reorder_by_freq: with all unique values", {
  x <- c("A", "B", "C", "D")
  result <- mysterycall_reorder_by_freq(x)

  expect_s3_class(result, "factor")
  # All have frequency 1, so order by appearance
  expect_equal(length(levels(result)), 4)
})

test_that("mysterycall_reorder_by_freq: error on numeric input", {
  x <- c(1, 2, 3, 2, 1)

  expect_error(
    mysterycall_reorder_by_freq(x),
    "`x` must be a character or factor vector"
  )
})

test_that("mysterycall_reorder_by_freq: error on list input", {
  x <- list("A", "B", "C")

  expect_error(
    mysterycall_reorder_by_freq(x),
    "`x` must be a character or factor vector"
  )
})

test_that("mysterycall_reorder_by_freq: empty character vector", {
  x <- character(0)
  result <- mysterycall_reorder_by_freq(x)

  expect_s3_class(result, "factor")
  expect_length(result, 0)
})

test_that("mysterycall_reorder_by_freq: all values are NA with na_level specified", {
  x <- c("A", "B", "A", NA, NA)
  result <- mysterycall_reorder_by_freq(x, na_level = "NoData")

  expect_s3_class(result, "factor")
  # A is most frequent (2), B is 1, NoData is 2
  expect_true("NoData" %in% levels(result))
  expect_false(any(is.na(result)))
  expect_equal(levels(result)[length(levels(result))], "NoData")
})

test_that("mysterycall_reorder_by_freq: preserves factor values correctly", {
  x <- c("B", "A", "A", "C", "B", "B", "C")
  result <- mysterycall_reorder_by_freq(x)

  # Check that the factor preserves the original values
  expect_true(all(as.character(result) == x))
})
