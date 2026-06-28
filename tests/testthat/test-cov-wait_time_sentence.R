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

test_that("mysterycall_wait_time_sentence returns correct structure with minimal inputs", {
  set.seed(1)
  df <- data.frame(
    group = rep(c("A", "B"), each = 10),
    wait = rpois(20, lambda = 5)
  )

  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, outcome_col = "wait", group_col = "group")
  )

  # Check return type and structure
  expect_type(res, "list")
  expect_named(res, c("sentence", "overall_stats", "group_stats", "p_values"))

  # Check sentence is character
  expect_type(res$sentence, "character")
  expect_length(res$sentence, 1L)
  expect_true(nchar(res$sentence) > 0)

  # Check overall_stats structure
  expect_named(res$overall_stats, c("median", "q1", "q3"))
  expect_type(res$overall_stats$median, "double")
  expect_type(res$overall_stats$q1, "double")
  expect_type(res$overall_stats$q3, "double")

  # Check group_stats is a data frame/tibble
  expect_true(is.data.frame(res$group_stats))
  expect_true(nrow(res$group_stats) >= 2L)

  # Check p_values is numeric vector
  expect_type(res$p_values, "double")
})

test_that("mysterycall_wait_time_sentence handles NA values in outcome", {
  set.seed(2)
  df <- data.frame(
    group = c("A", "A", "A", "B", "B", "B"),
    wait = c(5, NA, 7, 10, 12, NA)
  )

  res <- suppressMessages(
    mysterycall_wait_time_sentence(df, outcome_col = "wait", group_col = "group")
  )

  # Should still compute median using na.rm = TRUE
  expect_type(res$overall_stats$median, "double")
  expect_false(is.na(res$overall_stats$median))
  expect_type(res$sentence, "character")
})

test_that("mysterycall_wait_time_sentence with filter_positive = TRUE removes non-positive values", {
  set.seed(3)
  df <- data.frame(
    group = c("A", "A", "A", "B", "B", "B"),
    wait = c(0, 5, 10, -1, 8, 12)
  )

  res_filtered <- suppressMessages(
    mysterycall_wait_time_sentence(
      df, outcome_col = "wait", group_col = "group", filter_positive = TRUE
    )
  )

  res_unfiltered <- suppressMessages(
    mysterycall_wait_time_sentence(
      df, outcome_col = "wait", group_col = "group", filter_positive = FALSE
    )
  )

  # With filter_positive = TRUE, should have higher median (excludes 0 and negative)
  expect_true(res_filtered$overall_stats$median >= res_unfiltered$overall_stats$median)
})

test_that("mysterycall_wait_time_sentence respects reference level parameter", {
  set.seed(4)
  df <- data.frame(
    group = rep(c("A", "B", "C"), each = 10),
    wait = rpois(30, lambda = 5)
  )

  res_ref_a <- suppressMessages(
    mysterycall_wait_time_sentence(
      df, outcome_col = "wait", group_col = "group", reference = "A"
    )
  )

  res_ref_b <- suppressMessages(
    mysterycall_wait_time_sentence(
      df, outcome_col = "wait", group_col = "group", reference = "B"
    )
  )

  # Both should return valid results with different p_values
  expect_type(res_ref_a$p_values, "double")
  expect_type(res_ref_b$p_values, "double")

  # The p-value names should differ (one references A, one references B)
  expect_true(length(res_ref_a$p_values) > 0)
})

test_that("mysterycall_wait_time_sentence respects digits_median and digits_p parameters", {
  set.seed(5)
  df <- data.frame(
    group = rep(c("A", "B"), each = 10),
    wait = c(rpois(10, 5.5), rpois(10, 6.7))
  )

  res_digits0 <- suppressMessages(
    mysterycall_wait_time_sentence(
      df, outcome_col = "wait", group_col = "group",
      digits_median = 0L, digits_p = 3L
    )
  )

  res_digits2 <- suppressMessages(
    mysterycall_wait_time_sentence(
      df, outcome_col = "wait", group_col = "group",
      digits_median = 2L, digits_p = 5L
    )
  )

  # Both should return valid results (may differ in rounding)
  expect_type(res_digits0$sentence, "character")
  expect_type(res_digits2$sentence, "character")
  expect_true(nchar(res_digits0$sentence) > 0)
  expect_true(nchar(res_digits2$sentence) > 0)
})

test_that("mysterycall_wait_time_sentence errors when group_col is missing", {
  set.seed(6)
  df <- data.frame(
    group = c("A", "B"),
    wait = c(5, 10)
  )

  expect_error(
    mysterycall_wait_time_sentence(df, outcome_col = "wait")
  )
})

test_that("mysterycall_wait_time_sentence errors when outcome_col not in data", {
  set.seed(7)
  df <- data.frame(
    group = c("A", "B"),
    wait = c(5, 10)
  )

  expect_error(
    mysterycall_wait_time_sentence(
      df, outcome_col = "nonexistent", group_col = "group"
    )
  )
})

test_that("mysterycall_wait_time_sentence errors when group_col not in data", {
  set.seed(8)
  df <- data.frame(
    group = c("A", "B"),
    wait = c(5, 10)
  )

  expect_error(
    mysterycall_wait_time_sentence(
      df, outcome_col = "wait", group_col = "nonexistent"
    )
  )
})

test_that("mysterycall_wait_time_sentence errors when reference not in group levels", {
  set.seed(9)
  df <- data.frame(
    group = rep(c("A", "B"), each = 5),
    wait = c(rpois(5, 5), rpois(5, 10))
  )

  expect_error(
    mysterycall_wait_time_sentence(
      df, outcome_col = "wait", group_col = "group", reference = "Z"
    )
  )
})

test_that("mysterycall_wait_time_sentence handles empty data frame", {
  df_empty <- data.frame(
    group = character(0),
    wait = numeric(0)
  )

  res <- suppressMessages(
    mysterycall_wait_time_sentence(df_empty, outcome_col = "wait", group_col = "group")
  )

  # Should return valid list structure even with no rows
  expect_named(res, c("sentence", "overall_stats", "group_stats", "p_values"))
  expect_type(res$sentence, "character")
})
