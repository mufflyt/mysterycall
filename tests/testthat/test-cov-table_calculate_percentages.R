library(testthat)
library(mysterycall)

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


test_that("Happy path: single most frequent level", {
  df <- data.frame(category = c("A", "B", "A", "C", "A", "B", "B", "A"))
  result <- mysterycall_table_percentages(df, "category")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$category, "A")
  expect_equal(result$n, 4L)
  expect_equal(result$percent, 50.0)
})


test_that("Happy path: three-way tie returns all tied levels", {
  df <- data.frame(category = c("A", "B", "A", "B", "C", "C", "C", "A", "B"))
  result <- mysterycall_table_percentages(df, "category")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3L)
  expect_equal(sort(result$category), c("A", "B", "C"))
  expect_true(all(result$n == 3L))
  expect_true(all(result$percent == (100 * 3 / 9)))
})


test_that("Edge case: NA values are counted as their own level", {
  df <- data.frame(category = c("A", NA, "A", "C", "A", "B", "B", NA))
  result <- mysterycall_table_percentages(df, "category")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_equal(result$category, "A")
  expect_equal(result$n, 3L)
  expect_equal(result$percent, 100 * 3 / 8)  # 8 total rows including NAs
})


test_that("Edge case: all NA values", {
  df <- data.frame(category = c(NA, NA, NA))
  result <- mysterycall_table_percentages(df, "category")

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_true(is.na(result$category))
  expect_equal(result$n, 3L)
  expect_equal(result$percent, 100.0)
})


test_that("Error path: variable name does not exist", {
  df <- data.frame(category = c("A", "B", "A"))
  expect_error(mysterycall_table_percentages(df, "nonexistent"))
})


test_that("Error path: missing required arguments", {
  df <- data.frame(category = c("A", "B", "A"))
  expect_error(mysterycall_table_percentages(df))
  expect_error(mysterycall_table_percentages(variable = "category"))
})
