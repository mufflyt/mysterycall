test_that("returns tibble with correct columns", {
  df <- data.frame(
    scenario = c("A", "A", "B", "B", "B"),
    business_days_until_appointment = c(3, 7, 14, 21, 28),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_wait_time_by_group(df, group_col = "scenario", output_dir = NA)
  )
  expect_s3_class(result, "data.frame")
  expect_true(all(c("scenario", "median_days", "q1", "q3", "n") %in% names(result)))
})

test_that("median matches manual calculation", {
  df <- data.frame(
    grp   = rep("X", 5),
    days  = c(1, 3, 5, 7, 9),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "grp", output_dir = NA)
  )
  expect_equal(result$median_days, round(median(c(1, 3, 5, 7, 9)), 1))
})

test_that("n counts non-NA values", {
  df <- data.frame(
    grp  = c("A", "A", "A", "B"),
    days = c(1, NA, 3, 5),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "grp", output_dir = NA)
  )
  a_row <- result[result$grp == "A", ]
  expect_equal(a_row$n, 2L)
})

test_that("q1 and q3 rounded to digits_q", {
  df <- data.frame(
    grp  = rep("G", 4),
    days = c(1, 2, 3, 4),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "grp", digits_q = 0,
                                   output_dir = NA)
  )
  expect_equal(result$q1, round(quantile(c(1, 2, 3, 4), 0.25), 0))
  expect_equal(result$q3, round(quantile(c(1, 2, 3, 4), 0.75), 0))
})

test_that("filter_positive removes zero and negative rows", {
  df <- data.frame(
    grp  = rep("A", 5),
    days = c(-1, 0, 5, 10, 15),
    stringsAsFactors = FALSE
  )
  result_all <- suppressMessages(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "grp", filter_positive = FALSE,
                                   output_dir = NA)
  )
  result_pos <- suppressMessages(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "grp", filter_positive = TRUE,
                                   output_dir = NA)
  )
  expect_equal(result_pos$n, 3L)
  expect_gt(result_pos$median_days, result_all$median_days)
})

test_that("error on missing outcome column", {
  df <- data.frame(grp = "A", wrong_col = 1, stringsAsFactors = FALSE)
  expect_error(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "grp", output_dir = NA),
    "not found"
  )
})

test_that("error on missing group column", {
  df <- data.frame(days = 1:5, stringsAsFactors = FALSE)
  expect_error(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "grp", output_dir = NA),
    "not found"
  )
})

test_that("all-NA outcome returns NA stats", {
  df <- data.frame(
    grp  = c("A", "A"),
    days = c(NA_real_, NA_real_),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "grp", output_dir = NA)
  )
  expect_true(is.na(result$median_days))
  expect_equal(result$n, 0L)
})

test_that("error on non-data-frame input", {
  expect_error(
    mysterycall_wait_time_by_group(list(a = 1), group_col = "a", output_dir = NA),
    "`data` must be a data frame"
  )
})

test_that("two-group output has two rows in correct order", {
  df <- data.frame(
    arm  = c(rep("BCBS", 3), rep("Medicaid", 3)),
    days = c(5, 10, 15, 20, 25, 30),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "arm", output_dir = NA)
  )
  expect_equal(nrow(result), 2L)
})

test_that("single row data returns single-group summary", {
  df <- data.frame(
    grp  = "Solo",
    days = 7,
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "grp", output_dir = NA)
  )
  expect_equal(nrow(result), 1L)
  expect_equal(result$median_days, 7)
  expect_equal(result$n, 1L)
})

test_that("writes CSV when output_dir is NULL (uses tempdir)", {
  df <- data.frame(
    grp  = rep("A", 3),
    days = c(1, 2, 3),
    stringsAsFactors = FALSE
  )
  expect_message(
    mysterycall_wait_time_by_group(df, outcome_col = "days",
                                   group_col = "grp", output_dir = NULL),
    "written to"
  )
})
