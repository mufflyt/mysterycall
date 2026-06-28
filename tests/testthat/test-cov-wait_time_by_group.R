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

test_that("mysterycall_wait_time_by_group returns tibble with correct structure", {
  result <- suppressMessages(
    mysterycall_wait_time_by_group(
      data = AUDIT,
      group_col = "insurance",
      output_dir = NA
    )
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2L)
  expect_equal(
    names(result),
    c("insurance", "median_days", "q1", "q3", "n")
  )
  expect_type(result$median_days, "double")
  expect_type(result$q1, "double")
  expect_type(result$q3, "double")
  expect_type(result$n, "integer")
})

test_that("mysterycall_wait_time_by_group respects digits_median and digits_q parameters", {
  result <- suppressMessages(
    mysterycall_wait_time_by_group(
      data = AUDIT,
      group_col = "insurance",
      digits_median = 2L,
      digits_q = 1L,
      output_dir = NA
    )
  )

  expect_equal(nrow(result), 2L)
  expect_true(all(!is.na(result$median_days)))
  expect_true(all(!is.na(result$q1)))
  expect_true(all(!is.na(result$q3)))
})

test_that("mysterycall_wait_time_by_group reorders by median when reorder=TRUE", {
  # Create test data with clearly different medians
  test_data <- data.frame(
    group = c("Low", "Low", "Low", "High", "High", "High"),
    days = c(2, 3, 4, 20, 25, 30),
    stringsAsFactors = FALSE
  )

  result_ordered <- suppressMessages(
    mysterycall_wait_time_by_group(
      data = test_data,
      outcome_col = "days",
      group_col = "group",
      reorder = TRUE,
      output_dir = NA
    )
  )

  # When reordered, the first row should have the highest median
  expect_equal(result_ordered$group[1], "High")
  expect_equal(result_ordered$group[2], "Low")
  expect_true(result_ordered$median_days[1] > result_ordered$median_days[2])
})

test_that("mysterycall_wait_time_by_group filters positive values when filter_positive=TRUE", {
  # Create data with zero and negative values
  test_data <- data.frame(
    group = c("A", "A", "A", "B", "B"),
    days = c(5, 0, -1, 10, 15),
    stringsAsFactors = FALSE
  )

  result_filtered <- suppressMessages(
    mysterycall_wait_time_by_group(
      data = test_data,
      outcome_col = "days",
      group_col = "group",
      filter_positive = TRUE,
      output_dir = NA
    )
  )

  result_unfiltered <- suppressMessages(
    mysterycall_wait_time_by_group(
      data = test_data,
      outcome_col = "days",
      group_col = "group",
      filter_positive = FALSE,
      output_dir = NA
    )
  )

  # Filtered should have fewer or equal rows for group A due to filtering
  expect_equal(nrow(result_filtered), 2L)
  expect_equal(nrow(result_unfiltered), 2L)
  # With filtering, group A should only have count of 1 (just the 5)
  expect_equal(result_filtered$n[result_filtered$group == "A"], 1L)
  # Without filtering, group A should have count of 3
  expect_equal(result_unfiltered$n[result_unfiltered$group == "A"], 3L)
})

test_that("mysterycall_wait_time_by_group handles NA values correctly", {
  test_data <- data.frame(
    group = c("A", "A", "A", "B", "B", "B"),
    days = c(5, NA, 10, 15, NA, 20),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_wait_time_by_group(
      data = test_data,
      outcome_col = "days",
      group_col = "group",
      output_dir = NA
    )
  )

  # Count should only include non-NA values
  expect_equal(result$n[result$group == "A"], 2L)
  expect_equal(result$n[result$group == "B"], 2L)
  # Medians should be computed from non-NA values
  expect_equal(result$median_days[result$group == "A"], 7.5)
  expect_equal(result$median_days[result$group == "B"], 17.5)
})

test_that("mysterycall_wait_time_by_group errors on missing group_col argument", {
  expect_error(
    mysterycall_wait_time_by_group(
      data = AUDIT,
      output_dir = NA
    )
  )
})

test_that("mysterycall_wait_time_by_group errors when group_col not in data", {
  expect_error(
    mysterycall_wait_time_by_group(
      data = AUDIT,
      group_col = "nonexistent_column",
      output_dir = NA
    )
  )
})

test_that("mysterycall_wait_time_by_group errors when outcome_col not in data", {
  expect_error(
    mysterycall_wait_time_by_group(
      data = AUDIT,
      outcome_col = "nonexistent_outcome",
      group_col = "insurance",
      output_dir = NA
    )
  )
})

test_that("mysterycall_wait_time_by_group errors on non-data.frame input", {
  expect_error(
    mysterycall_wait_time_by_group(
      data = list(group = c("A", "B"), days = c(5, 10)),
      group_col = "group",
      output_dir = NA
    )
  )
})

test_that("mysterycall_wait_time_by_group handles empty data frame", {
  empty_df <- data.frame(
    group = character(),
    days = numeric(),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_wait_time_by_group(
      data = empty_df,
      outcome_col = "days",
      group_col = "group",
      output_dir = NA
    )
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
  expect_equal(
    names(result),
    c("group", "median_days", "q1", "q3", "n")
  )
})

test_that("mysterycall_wait_time_by_group works with COUNT_DF fixture", {
  result <- suppressMessages(
    mysterycall_wait_time_by_group(
      data = COUNT_DF,
      outcome_col = "days",
      group_col = "insurance",
      output_dir = NA
    )
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 2L)
  expect_true(all(result$n == 40L))
  expect_true(result$median_days[result$insurance == "Medicaid"] <
              result$median_days[result$insurance == "BCBS"])
})

test_that("mysterycall_wait_time_by_group errors on invalid digits parameters", {
  expect_error(
    mysterycall_wait_time_by_group(
      data = AUDIT,
      group_col = "insurance",
      digits_median = -1L,
      output_dir = NA
    )
  )
  expect_error(
    mysterycall_wait_time_by_group(
      data = AUDIT,
      group_col = "insurance",
      digits_q = -1L,
      output_dir = NA
    )
  )
})

test_that("mysterycall_wait_time_by_group errors on non-logical filter_positive", {
  expect_error(
    mysterycall_wait_time_by_group(
      data = AUDIT,
      group_col = "insurance",
      filter_positive = "TRUE",
      output_dir = NA
    )
  )
})
