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


test_that("Happy path: basic categorical variable proportions", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_table_proportion(AUDIT, insurance)
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_true("insurance" %in% names(result))
  expect_true("n" %in% names(result))
  expect_true("percent" %in% names(result))

  # Verify counts sum to total
  expect_equal(sum(result$n), 4L)

  # Verify percentages sum to 100
  expect_equal(sum(result$percent), 100, tolerance = 0.01)

  # Verify proportions are correct
  expect_equal(result$percent, c(50, 50), tolerance = 0.01)
})


test_that("Edge case: handling NA values in categorical variable", {
  df_with_na <- data.frame(
    category = c("A", "A", "B", NA, "B", NA, "C"),
    value = 1:7,
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_table_proportion(df_with_na, category)
  ))

  # Should only include non-NA rows (5 total)
  expect_equal(sum(result$n), 5L)
  expect_equal(nrow(result), 3L)

  # Verify percentages sum to 100
  expect_equal(sum(result$percent), 100, tolerance = 0.01)

  # Verify expected counts
  expect_equal(result$n, c(2, 2, 1))
})


test_that("Edge case: single category (all same value)", {
  df_single <- data.frame(
    category = rep("Only", 10),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_table_proportion(df_single, category)
  ))

  expect_equal(nrow(result), 1L)
  expect_equal(result$n, 10)
  expect_equal(result$percent, 100)
  expect_equal(result$category, "Only")
})


test_that("Edge case: numeric rounding to 2 decimal places", {
  set.seed(1)
  df_rounding <- data.frame(
    category = rep(c("X", "Y", "Z"), c(1, 2, 7)),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_table_proportion(df_rounding, category)
  ))

  # Verify rounding to 2 decimals
  expect_true(all(grepl("^\\d+(\\.\\d{0,2})?$", as.character(result$percent))))

  # Check specific values
  expect_equal(result$percent[1], 10)      # 1/10 = 10%
  expect_equal(result$percent[2], 20)      # 2/10 = 20%
  expect_equal(result$percent[3], 70)      # 7/10 = 70%
})


test_that("Edge case: all values are NA", {
  df_all_na <- data.frame(
    category = c(NA, NA, NA),
    value = 1:3,
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_table_proportion(df_all_na, category)
  ))

  # Should return empty data frame with correct structure
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
  expect_true("category" %in% names(result))
  expect_true("n" %in% names(result))
  expect_true("percent" %in% names(result))
})
