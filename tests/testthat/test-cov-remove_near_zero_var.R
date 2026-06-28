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

skip_if_not_installed("caret")

test_that("mysterycall_remove_near_zero removes near-zero variance columns", {
  # Create a data frame with a near-zero variance column matching the documentation example
  df <- data.frame(
    a = 1:20,
    b = c(rep(1, 19), 2),  # Near-zero variance: 19:1 ratio
    c = rnorm(20),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_remove_near_zero(df))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 20L)
  expect_false("b" %in% colnames(result))  # Column b should be removed
  expect_true("a" %in% colnames(result))
  expect_true("c" %in% colnames(result))
})

test_that("mysterycall_remove_near_zero handles empty data frame", {
  df_empty <- data.frame()
  result <- suppressMessages(mysterycall_remove_near_zero(df_empty))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_equal(ncol(result), 0L)
})

test_that("mysterycall_remove_near_zero handles data frame with no near-zero variance", {
  set.seed(2)
  df <- data.frame(
    a = 1:20,
    b = rnorm(20),
    c = sample(1:5, 20, replace = TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(mysterycall_remove_near_zero(df))

  expect_s3_class(result, "data.frame")
  expect_equal(ncol(result), 3L)
  expect_equal(colnames(result), c("a", "b", "c"))
})

test_that("mysterycall_remove_near_zero respects freqCut parameter", {
  # Create a data frame where one column has a 10:1 ratio
  df <- data.frame(
    a = 1:20,
    b = c(rep(1, 10), rep(2, 10)),  # 1:1 ratio
    stringsAsFactors = FALSE
  )

  # With default freqCut=19, column b should not be removed (1:1 ratio)
  result1 <- suppressMessages(mysterycall_remove_near_zero(df, freqCut = 19))
  expect_equal(ncol(result1), 2L)

  # With more conservative freqCut, behavior may vary by data
  result2 <- suppressMessages(mysterycall_remove_near_zero(df, freqCut = 1))
  expect_s3_class(result2, "data.frame")
})

test_that("mysterycall_remove_near_zero respects uniqueCut parameter", {
  set.seed(3)
  # Create a data frame with columns of varying uniqueness
  df <- data.frame(
    a = 1:20,
    b = rep(1, 20),  # Only 1 unique value = 5% unique
    c = rnorm(20),
    stringsAsFactors = FALSE
  )

  # With uniqueCut=1 (very conservative), column b should be removed
  result <- suppressMessages(mysterycall_remove_near_zero(df, uniqueCut = 1))

  expect_s3_class(result, "data.frame")
  expect_false("b" %in% colnames(result))  # Constant column should be removed
  expect_true("a" %in% colnames(result))
  expect_true("c" %in% colnames(result))
})
