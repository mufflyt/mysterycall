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

# Happy path: valid input returns correct structure
test_that("mysterycall_distribution_summary: valid input returns list with correct structure", {
  result <- mysterycall_distribution_summary(AUDIT, "insurance")

  expect_type(result, "list")
  expect_named(result, c("level", "count", "total", "percent", "sentence", "full_table"))
  expect_type(result$level, "character")
  expect_type(result$count, "integer")
  expect_type(result$total, "integer")
  expect_type(result$percent, "double")
  expect_type(result$sentence, "character")
  expect_s3_class(result$full_table, "tbl_df")
})

# Happy path: correct computation of modal level
test_that("mysterycall_distribution_summary: computes modal level and counts correctly", {
  result <- mysterycall_distribution_summary(AUDIT, "insurance")

  # Both Medicaid and BCBS appear 2 times each
  expect_equal(result$count, 2L)
  expect_equal(result$total, 4L)
  expect_equal(result$percent, 50.0)
})

# Happy path: full_table has correct structure
test_that("mysterycall_distribution_summary: full_table ordered by descending count", {
  result <- mysterycall_distribution_summary(AUDIT, "insurance")

  expect_named(result$full_table, c("level", "count", "percent"))
  expect_equal(nrow(result$full_table), 2L)
  # First row should be modal level
  expect_equal(result$full_table$level[1], result$level)
  # Descending order check
  if (nrow(result$full_table) > 1) {
    expect_true(result$full_table$count[1] >= result$full_table$count[2])
  }
})

# Happy path: sentence format is correct
test_that("mysterycall_distribution_summary: sentence contains expected text", {
  result <- mysterycall_distribution_summary(AUDIT, "insurance")

  expect_match(result$sentence, "The most common insurance was")
  expect_match(result$sentence, "\\(n = 2/N = 4")
  expect_match(result$sentence, "50\\.0%\\)")
})

# Edge case: NA values are filtered
test_that("mysterycall_distribution_summary: NA values are excluded from computation", {
  df <- data.frame(
    category = c("A", "B", "A", NA, "B", NA, "A"),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_distribution_summary(df, "category")

  # A=3, B=2, both modal by count (A first)
  expect_equal(result$total, 5L)
  expect_equal(result$level, "A")
  expect_equal(result$count, 3L)
  expect_false(any(is.na(result$full_table$level)))
})

# Edge case: digits parameter controls rounding precision
test_that("mysterycall_distribution_summary: digits parameter controls decimal places", {
  df <- data.frame(
    cat = c(rep("X", 1), rep("Y", 3)),
    stringsAsFactors = FALSE
  )

  # Y appears 3 times out of 4 = 75%
  result_0 <- mysterycall_distribution_summary(df, "cat", digits = 0L)
  result_1 <- mysterycall_distribution_summary(df, "cat", digits = 1L)
  result_2 <- mysterycall_distribution_summary(df, "cat", digits = 2L)

  expect_equal(result_0$percent, 75)
  expect_equal(result_1$percent, 75.0)
  expect_equal(result_2$percent, 75.00)
})

# Edge case: all NA values
test_that("mysterycall_distribution_summary: all NA values throw error", {
  df <- data.frame(
    category = c(NA, NA, NA),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_distribution_summary(df, "category"),
    "contains only NA values"
  )
})

# Edge case: empty dataframe
test_that("mysterycall_distribution_summary: empty dataframe throws error", {
  df <- data.frame(
    category = character(0),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_distribution_summary(df, "category"),
    "contains only NA values"
  )
})

# Bad input: missing required argument
test_that("mysterycall_distribution_summary: missing column argument errors", {
  expect_error(
    mysterycall_distribution_summary(AUDIT),
    "missing"
  )
})

# Bad input: nonexistent column name
test_that("mysterycall_distribution_summary: nonexistent column errors", {
  expect_error(
    mysterycall_distribution_summary(AUDIT, "nonexistent_column"),
    "must.include"
  )
})

# Bad input: wrong data type for data argument
test_that("mysterycall_distribution_summary: non-dataframe input errors", {
  expect_error(
    mysterycall_distribution_summary("not a dataframe", "column"),
    "data.frame"
  )
})

# Additional: Works with COUNT_DF
test_that("mysterycall_distribution_summary: works with COUNT_DF insurance column", {
  result <- mysterycall_distribution_summary(COUNT_DF, "insurance")

  expect_equal(result$total, 80L)
  expect_true(result$count >= 1)
  expect_match(result$sentence, "The most common insurance")
  expect_equal(nrow(result$full_table), 2L)
})

# Additional: numeric columns coerced to character
test_that("mysterycall_distribution_summary: numeric columns handled correctly", {
  df <- data.frame(
    values = c(1, 2, 1, 3, 2, 1),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_distribution_summary(df, "values")

  # 1 appears 3 times - modal
  expect_equal(result$level, "1")
  expect_equal(result$count, 3L)
  expect_equal(result$total, 6L)
})

# Additional: factor columns handled correctly
test_that("mysterycall_distribution_summary: factor columns handled correctly", {
  df <- data.frame(
    category = factor(c("A", "B", "A", "A")),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_distribution_summary(df, "category")

  expect_equal(result$level, "A")
  expect_equal(result$count, 3L)
  expect_equal(result$total, 4L)
  expect_type(result$full_table$level, "character")
})
