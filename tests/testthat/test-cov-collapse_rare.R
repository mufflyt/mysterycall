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

# Test 1: Character vector with rare values (happy path)
test_that("collapse_rare works with character vector and threshold", {
  x <- c(rep("Otolaryngology", 80), rep("Urology", 30), rep("Dermatology", 5))
  result <- mysterycall_collapse_rare(x, threshold = 10)

  expect_type(result, "character")
  expect_length(result, 115L)
  expect_equal(sum(result == "Dermatology"), 0L)
  expect_equal(sum(result == "Other"), 5L)
  expect_equal(sum(result == "Otolaryngology"), 80L)
})

# Test 2: Factor vector with rare values (happy path)
test_that("collapse_rare works with factor vector and preserves class", {
  x <- factor(c(rep("A", 60), rep("B", 25), rep("C", 10), rep("D", 5)))
  result <- mysterycall_collapse_rare(x, threshold = 20)

  expect_s3_class(result, "factor")
  expect_length(result, 100L)
  expect_equal(sum(result == "A"), 60L)
  expect_equal(sum(result == "B"), 25L)
  expect_equal(sum(result == "Other"), 15L)
  expect_false("C" %in% levels(result))
  expect_false("D" %in% levels(result))
})

# Test 3: No rare values (no collapsing needed)
test_that("collapse_rare preserves all levels when all above threshold", {
  x <- factor(c(rep("Red", 50), rep("Blue", 50), rep("Green", 50)))
  result <- mysterycall_collapse_rare(x, threshold = 40)

  expect_s3_class(result, "factor")
  expect_length(levels(result), 3L)
  expect_equal(levels(result), c("Red", "Blue", "Green"))
  expect_equal(sum(result == "Other"), 0L)
})

# Test 4: All values are rare (everything becomes "Other")
test_that("collapse_rare collapses to all 'Other' when threshold is high", {
  x <- c("A", "B", "C", "D", "E")
  result <- mysterycall_collapse_rare(x, threshold = 10)

  expect_type(result, "character")
  expect_length(result, 5L)
  expect_equal(sum(result == "Other"), 5L)
})

# Test 5: Custom other_label
test_that("collapse_rare uses custom other_label", {
  x <- c(rep("Frequent", 100), rep("Rare1", 5), rep("Rare2", 3))
  result <- mysterycall_collapse_rare(x, threshold = 10, other_label = "Uncommon")

  expect_equal(sum(result == "Uncommon"), 8L)
  expect_equal(sum(result == "Other"), 0L)
  expect_false("Uncommon" %in% c("Frequent", "Rare1", "Rare2"))
})

# Test 6: Factor level order is preserved
test_that("collapse_rare preserves relative order of retained levels", {
  x <- factor(c(rep("Z", 60), rep("A", 50), rep("M", 10), rep("B", 40)),
              levels = c("Z", "A", "M", "B"))
  result <- mysterycall_collapse_rare(x, threshold = 30)

  expect_s3_class(result, "factor")
  retained_levels <- levels(result)
  retained_levels_no_other <- retained_levels[retained_levels != "Other"]
  # Original order: Z, A, M, B; M is rare so removed; should be Z, A, B, Other
  expect_equal(retained_levels_no_other, c("Z", "A", "B"))
})

# Test 7: Character vector with NAs (edge case)
test_that("collapse_rare handles NAs in character vector", {
  x <- c(rep("Common", 60), rep("Rare", 5), NA, NA)
  result <- mysterycall_collapse_rare(x, threshold = 10)

  expect_type(result, "character")
  expect_equal(sum(is.na(result)), 2L)
  expect_equal(sum(result == "Other", na.rm = TRUE), 5L)
})

# Test 8: Factor vector with NAs (edge case)
test_that("collapse_rare handles NAs in factor vector", {
  x <- factor(c(rep("Common", 60), rep("Rare", 5), NA, NA))
  result <- mysterycall_collapse_rare(x, threshold = 10)

  expect_s3_class(result, "factor")
  expect_equal(sum(is.na(result)), 2L)
  expect_equal(sum(result == "Other", na.rm = TRUE), 5L)
})

# Test 9: Invalid input - numeric vector (bad input)
test_that("collapse_rare throws error for numeric input", {
  x <- c(1, 2, 3, 4, 5)
  expect_error(mysterycall_collapse_rare(x, threshold = 2),
               "`x` must be a character or factor vector")
})

# Test 10: Invalid threshold - negative value (bad input)
test_that("collapse_rare throws error for negative threshold", {
  x <- c("A", "B", "C")
  expect_error(mysterycall_collapse_rare(x, threshold = -1),
               "`threshold` must be a single positive number")
})

# Test 11: Invalid threshold - NA (bad input)
test_that("collapse_rare throws error for NA threshold", {
  x <- c("A", "B", "C")
  expect_error(mysterycall_collapse_rare(x, threshold = NA),
               "`threshold` must be a single positive number")
})

# Test 12: Invalid threshold - multiple values (bad input)
test_that("collapse_rare throws error for vector threshold", {
  x <- c("A", "B", "C")
  expect_error(mysterycall_collapse_rare(x, threshold = c(1, 2)),
               "`threshold` must be a single positive number")
})

# Test 13: Invalid other_label - numeric (bad input)
test_that("collapse_rare throws error for numeric other_label", {
  x <- c("A", "B", "C")
  expect_error(mysterycall_collapse_rare(x, other_label = 123),
               "`other_label` must be a single character string")
})

# Test 14: Invalid other_label - multiple values (bad input)
test_that("collapse_rare throws error for vector other_label", {
  x <- c("A", "B", "C")
  expect_error(mysterycall_collapse_rare(x, other_label = c("X", "Y")),
               "`other_label` must be a single character string")
})

# Test 15: Empty vector (edge case)
test_that("collapse_rare handles empty vectors", {
  x_char <- character(0)
  result_char <- mysterycall_collapse_rare(x_char, threshold = 5)
  expect_type(result_char, "character")
  expect_length(result_char, 0L)

  x_factor <- factor(character(0))
  result_factor <- mysterycall_collapse_rare(x_factor, threshold = 5)
  expect_s3_class(result_factor, "factor")
  expect_length(result_factor, 0L)
})

# Test 16: Single element vector (edge case)
test_that("collapse_rare works with single element vector", {
  x_char <- "OnlyOne"
  result_char <- mysterycall_collapse_rare(x_char, threshold = 2)
  expect_type(result_char, "character")
  expect_equal(result_char, "Other")

  x_factor <- factor("OnlyOne")
  result_factor <- mysterycall_collapse_rare(x_factor, threshold = 2)
  expect_s3_class(result_factor, "factor")
  expect_equal(as.character(result_factor), "Other")
})

# Test 17: Very low threshold (threshold = 1)
test_that("collapse_rare respects threshold of 1", {
  x <- c("A", "B", "B", "C", "C", "C")
  result <- mysterycall_collapse_rare(x, threshold = 1)

  expect_type(result, "character")
  expect_equal(result, x)  # All appear >= 1 time, so none rare
})

# Test 18: Case sensitivity
test_that("collapse_rare is case-sensitive", {
  x <- c(rep("apple", 60), rep("Apple", 5), rep("APPLE", 3))
  result <- mysterycall_collapse_rare(x, threshold = 10)

  expect_equal(sum(result == "apple"), 60L)
  expect_equal(sum(result == "Other"), 8L)
})
