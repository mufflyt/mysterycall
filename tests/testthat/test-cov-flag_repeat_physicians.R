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

test_that("mysterycall_flag_repeat_physicians returns flagged physicians with default columns", {
  df <- data.frame(
    id_number = c("A", "A", "A", "B", "B"),
    physician_information = c(rep("Dr A", 3), rep("Dr B", 2)),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_flag_repeat_physicians(df, threshold = 2, output_dir = NA)
  )

  expect_s3_class(result, "tbl_df")
  expect_true(nrow(result) > 0)
  expect_true(all(result$n_calls > 2))
  expect_true("id_number" %in% names(result))
  expect_true("n_calls" %in% names(result))
})

test_that("mysterycall_flag_repeat_physicians returns zero rows when no physicians exceed threshold", {
  result <- suppressMessages(
    mysterycall_flag_repeat_physicians(AUDIT, id_col = "npi", threshold = 2, output_dir = NA)
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("mysterycall_flag_repeat_physicians handles empty dataframe", {
  empty_df <- data.frame(
    npi = character(),
    physician_information = character(),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_flag_repeat_physicians(empty_df, id_col = "npi", output_dir = NA)
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0)
})

test_that("mysterycall_flag_repeat_physicians works with name_col=NULL", {
  df <- data.frame(
    npi = c("A", "A", "A", "B", "B"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_flag_repeat_physicians(df, id_col = "npi", name_col = NULL, threshold = 2, output_dir = NA)
  )

  expect_s3_class(result, "tbl_df")
  expect_true("npi" %in% names(result))
  expect_false("physician_information" %in% names(result))
})

test_that("mysterycall_flag_repeat_physicians errors when id_col is missing from data", {
  df <- data.frame(
    other_col = c("A", "B"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_flag_repeat_physicians(df, id_col = "id_number", output_dir = NA)
  )
})

test_that("mysterycall_flag_repeat_physicians errors with non-dataframe input", {
  expect_error(
    mysterycall_flag_repeat_physicians("not a dataframe", output_dir = NA)
  )
})

test_that("mysterycall_flag_repeat_physicians returns results sorted by n_calls descending", {
  df <- data.frame(
    id_number = c("A", "A", "A", "A", "B", "B", "B"),
    physician_information = c(rep("Dr A", 4), rep("Dr B", 3)),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_flag_repeat_physicians(df, threshold = 1, output_dir = NA)
  )

  expect_equal(result$n_calls, sort(result$n_calls, decreasing = TRUE))
})
