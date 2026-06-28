make_medicaid_df <- function(n = 10) {
  data.frame(
    does_the_physician_accept_medicaid = c(
      "Yes they accept Medicaid",
      "No",
      "NA as this was a Blue Cross/Blue Shield call.",
      "No answer, unable to determine if they accept Medicaid.",
      "Yes they accept Medicaid",
      "No",
      "Yes they accept Medicaid",
      "NA as this was a Blue Cross/Blue Shield call.",
      "No",
      "Yes they accept Medicaid"
    )[seq_len(n)],
    stringsAsFactors = FALSE
  )
}

test_that("clean_medicaid_col errors when data is not a data frame", {
  expect_error(mysterycall_clean_medicaid_col(list(a = 1)), "data.frame")
  expect_error(mysterycall_clean_medicaid_col("string"), "data.frame")
})

test_that("clean_medicaid_col errors when col is missing from data", {
  df <- data.frame(x = 1:3)
  expect_error(
    mysterycall_clean_medicaid_col(df, col = "does_the_physician_accept_medicaid"),
    "missing"
  )
})

test_that("clean_medicaid_col returns data frame with two new columns", {
  df <- make_medicaid_df()
  result <- suppressMessages(mysterycall_clean_medicaid_col(df))
  expect_true("cleaned_does_the_physician_accept_medicaid" %in% names(result))
  expect_true("cleaned_does_the_physician_accept_medicaid_numeric" %in% names(result))
})

test_that("clean_medicaid_col numeric column has only 0, 1, or NA", {
  df <- make_medicaid_df()
  result <- suppressMessages(mysterycall_clean_medicaid_col(df))
  num_col <- result$cleaned_does_the_physician_accept_medicaid_numeric
  valid_vals <- na.omit(num_col)
  expect_true(all(valid_vals %in% c(0, 1)))
})

test_that("clean_medicaid_col yes_value maps to 1, not-yes maps to 0, na_values map to NA", {
  df <- make_medicaid_df()
  result <- suppressMessages(mysterycall_clean_medicaid_col(df))
  raw <- df$does_the_physician_accept_medicaid
  num <- result$cleaned_does_the_physician_accept_medicaid_numeric
  na_vals <- c("NA as this was a Blue Cross/Blue Shield call.",
                "No answer, unable to determine if they accept Medicaid.")
  # na_values → NA
  expect_true(all(is.na(num[raw %in% na_vals])))
  # yes_value → 1
  expect_true(all(num[raw == "Yes they accept Medicaid"] == 1L, na.rm = TRUE))
  # other non-NA → 0
  expect_true(all(num[raw == "No"] == 0L, na.rm = TRUE))
})

test_that("clean_medicaid_col emits informative message with counts", {
  df <- make_medicaid_df()
  expect_message(
    mysterycall_clean_medicaid_col(df),
    "Recoded"
  )
})

test_that("clean_medicaid_col all-NA input gives all-NA numeric column", {
  df <- data.frame(
    does_the_physician_accept_medicaid = c(
      "NA as this was a Blue Cross/Blue Shield call.",
      "No answer, unable to determine if they accept Medicaid."
    ),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_clean_medicaid_col(df))
  expect_true(all(is.na(result$cleaned_does_the_physician_accept_medicaid_numeric)))
})

test_that("clean_medicaid_col na_values not in data: 0 recoded, message says so", {
  df <- data.frame(
    does_the_physician_accept_medicaid = c("Yes they accept Medicaid", "No"),
    stringsAsFactors = FALSE
  )
  expect_message(
    mysterycall_clean_medicaid_col(df),
    "Recoded 0 values to NA"
  )
})

test_that("clean_medicaid_col custom out_col names are used", {
  df <- make_medicaid_df(5)
  result <- suppressMessages(
    mysterycall_clean_medicaid_col(
      df,
      out_col_cleaned = "medicaid_clean",
      out_col_numeric = "medicaid_01"
    )
  )
  expect_true("medicaid_clean" %in% names(result))
  expect_true("medicaid_01" %in% names(result))
})

test_that("clean_medicaid_col single row works", {
  df <- data.frame(
    does_the_physician_accept_medicaid = "Yes they accept Medicaid",
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_clean_medicaid_col(df))
  expect_equal(result$cleaned_does_the_physician_accept_medicaid_numeric, 1)
})

test_that("clean_medicaid_col empty data frame returns empty with new columns", {
  df <- data.frame(
    does_the_physician_accept_medicaid = character(0),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_clean_medicaid_col(df))
  expect_true("cleaned_does_the_physician_accept_medicaid" %in% names(result))
  expect_equal(nrow(result), 0L)
})

test_that("clean_medicaid_col custom na_values work correctly", {
  df <- data.frame(
    does_the_physician_accept_medicaid = c("Yes they accept Medicaid", "Unknown", "No"),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(
    mysterycall_clean_medicaid_col(df, na_values = "Unknown")
  )
  num <- result$cleaned_does_the_physician_accept_medicaid_numeric
  expect_true(is.na(num[2]))
  expect_equal(num[1], 1)
  expect_equal(num[3], 0)
})

test_that("clean_medicaid_col warns when output columns already exist", {
  df <- make_medicaid_df(5)
  df$cleaned_does_the_physician_accept_medicaid <- "existing"
  expect_warning(
    suppressMessages(mysterycall_clean_medicaid_col(df)),
    "overwritten"
  )
})

test_that("clean_medicaid_col errors if out_col_cleaned == out_col_numeric", {
  df <- make_medicaid_df(5)
  expect_error(
    mysterycall_clean_medicaid_col(df,
      out_col_cleaned = "same_name",
      out_col_numeric = "same_name"
    ),
    "different column names"
  )
})
