library(testthat)
library(mysterycall)

# Tests for internal validation helpers in R/utils-validation.R.
# These functions are @keywords internal but accessed via ::: for coverage.

# ---------------------------------------------------------------------------
# validate_dataframe
# ---------------------------------------------------------------------------

test_that("validate_dataframe returns input invisibly on valid data frame", {
  df <- data.frame(x = 1:3, y = letters[1:3], stringsAsFactors = FALSE)
  result <- suppressMessages(suppressWarnings(
    mysterycall:::validate_dataframe(df, name = "df")
  ))
  expect_identical(result, df)
})

test_that("validate_dataframe errors when NULL is passed and allow_null = FALSE", {
  expect_error(
    mysterycall:::validate_dataframe(NULL, name = "mydata", allow_null = FALSE),
    regexp = "mydata"
  )
})

test_that("validate_dataframe accepts NULL silently when allow_null = TRUE", {
  result <- suppressMessages(suppressWarnings(
    mysterycall:::validate_dataframe(NULL, name = "mydata", allow_null = TRUE)
  ))
  expect_null(result)
})

test_that("validate_dataframe errors on non-data-frame input", {
  expect_error(
    mysterycall:::validate_dataframe(list(a = 1), name = "mylist"),
    regexp = "mylist"
  )
  expect_error(
    mysterycall:::validate_dataframe(42L, name = "x"),
    regexp = "x"
  )
})

test_that("validate_dataframe errors on zero-row data frame when allow_zero_rows = FALSE", {
  empty_df <- data.frame(x = integer(0), stringsAsFactors = FALSE)
  expect_error(
    mysterycall:::validate_dataframe(empty_df, name = "empty", allow_zero_rows = FALSE),
    regexp = "empty"
  )
})

test_that("validate_dataframe allows zero-row data frame when allow_zero_rows = TRUE (default)", {
  empty_df <- data.frame(x = integer(0), stringsAsFactors = FALSE)
  result <- suppressMessages(suppressWarnings(
    mysterycall:::validate_dataframe(empty_df, name = "empty", allow_zero_rows = TRUE)
  ))
  expect_identical(result, empty_df)
})

# ---------------------------------------------------------------------------
# validate_scalar_positive_numeric
# ---------------------------------------------------------------------------

test_that("validate_scalar_positive_numeric returns value invisibly for valid positive number", {
  result <- suppressMessages(suppressWarnings(
    mysterycall:::validate_scalar_positive_numeric(5.5, name = "threshold")
  ))
  expect_equal(result, 5.5)
})

test_that("validate_scalar_positive_numeric allows zero as a boundary value", {
  result <- suppressMessages(suppressWarnings(
    mysterycall:::validate_scalar_positive_numeric(0, name = "min_val")
  ))
  expect_equal(result, 0)
})

test_that("validate_scalar_positive_numeric accepts NULL when allow_null = TRUE (default)", {
  result <- suppressMessages(suppressWarnings(
    mysterycall:::validate_scalar_positive_numeric(NULL, name = "opt_param")
  ))
  expect_null(result)
})

test_that("validate_scalar_positive_numeric errors when NULL passed and allow_null = FALSE", {
  expect_error(
    mysterycall:::validate_scalar_positive_numeric(NULL, name = "req_param", allow_null = FALSE),
    regexp = "req_param"
  )
})

test_that("validate_scalar_positive_numeric errors on negative number", {
  expect_error(
    mysterycall:::validate_scalar_positive_numeric(-1, name = "neg_val")
  )
})

test_that("validate_scalar_positive_numeric errors on NA", {
  expect_error(
    mysterycall:::validate_scalar_positive_numeric(NA_real_, name = "na_val")
  )
})

# ---------------------------------------------------------------------------
# validate_required_columns
# ---------------------------------------------------------------------------

test_that("validate_required_columns returns data frame invisibly when all columns present", {
  df <- data.frame(npi = "1234567893", insurance = "Medicaid", stringsAsFactors = FALSE)
  result <- suppressMessages(suppressWarnings(
    mysterycall:::validate_required_columns(df, required = c("npi", "insurance"), name = "df")
  ))
  expect_identical(result, df)
})

test_that("validate_required_columns returns data frame when required is NULL or empty", {
  df <- data.frame(x = 1:2, stringsAsFactors = FALSE)
  result_null <- suppressMessages(suppressWarnings(
    mysterycall:::validate_required_columns(df, required = NULL, name = "df")
  ))
  result_empty <- suppressMessages(suppressWarnings(
    mysterycall:::validate_required_columns(df, required = character(0), name = "df")
  ))
  expect_identical(result_null, df)
  expect_identical(result_empty, df)
})

test_that("validate_required_columns errors with missing column names in message", {
  df <- data.frame(npi = "1234567893", stringsAsFactors = FALSE)
  expect_error(
    mysterycall:::validate_required_columns(df, required = c("npi", "insurance"), name = "audit"),
    regexp = "insurance"
  )
})

test_that("validate_required_columns suggests similar column names (edit distance <= 2)", {
  df <- data.frame(insuranse = "Medicaid", stringsAsFactors = FALSE)  # typo
  err <- tryCatch(
    mysterycall:::validate_required_columns(df, required = "insurance", name = "df"),
    error = function(e) conditionMessage(e)
  )
  # Should suggest the close match
  expect_match(err, "insuranse", fixed = TRUE)
})

test_that("validate_required_columns errors on completely missing columns from empty data frame", {
  df <- data.frame(stringsAsFactors = FALSE)[integer(0), ]
  # A zero-column data frame
  df2 <- as.data.frame(matrix(nrow = 1, ncol = 0))
  expect_error(
    mysterycall:::validate_required_columns(df2, required = "npi", name = "df2"),
    regexp = "npi"
  )
})
