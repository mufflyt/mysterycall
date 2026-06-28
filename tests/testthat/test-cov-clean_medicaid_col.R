library(testthat)
library(mysterycall)

# ---------------------------------------------------------------------------
# Shared fixture
# ---------------------------------------------------------------------------
make_medicaid_df <- function() {
  data.frame(
    does_the_physician_accept_medicaid = c(
      "Yes they accept Medicaid",
      "No",
      "NA as this was a Blue Cross/Blue Shield call.",
      "No answer, unable to determine if they accept Medicaid.",
      "Yes they accept Medicaid"
    ),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# 1. Happy path — typical five-row input
# ---------------------------------------------------------------------------
test_that("mysterycall_clean_medicaid_col returns correct columns on happy path", {
  df  <- make_medicaid_df()
  out <- suppressMessages(mysterycall_clean_medicaid_col(df))

  cleaned_col <- "cleaned_does_the_physician_accept_medicaid"
  numeric_col <- "cleaned_does_the_physician_accept_medicaid_numeric"

  # Both new columns are present
  expect_true(cleaned_col %in% names(out))
  expect_true(numeric_col %in% names(out))

  # Original rows are preserved
  expect_equal(nrow(out), nrow(df))

  # Rows 3 and 4 (na_values) map to NA in the cleaned column
  expect_true(is.na(out[[cleaned_col]][3]))
  expect_true(is.na(out[[cleaned_col]][4]))

  # Rows 1 and 5 ("Yes they accept Medicaid") map to 1
  expect_equal(out[[numeric_col]][1], 1)
  expect_equal(out[[numeric_col]][5], 1)

  # Row 2 ("No") maps to 0
  expect_equal(out[[numeric_col]][2], 0)

  # NA rows produce NA in numeric column
  expect_true(is.na(out[[numeric_col]][3]))
  expect_true(is.na(out[[numeric_col]][4]))
})

# ---------------------------------------------------------------------------
# 2. Edge case — column contains only NA_character_ values
# ---------------------------------------------------------------------------
test_that("mysterycall_clean_medicaid_col handles all-NA column gracefully", {
  df <- data.frame(
    does_the_physician_accept_medicaid = NA_character_,
    stringsAsFactors = FALSE
  )
  out <- suppressMessages(mysterycall_clean_medicaid_col(df))

  numeric_col <- "cleaned_does_the_physician_accept_medicaid_numeric"
  expect_equal(nrow(out), 1L)
  # native NA in source does not match na_values strings → stays NA after ifelse
  expect_true(is.na(out[[numeric_col]][1]))
})

# ---------------------------------------------------------------------------
# 3. Edge case — zero-row data frame
# ---------------------------------------------------------------------------
test_that("mysterycall_clean_medicaid_col works on zero-row data frame", {
  df <- data.frame(
    does_the_physician_accept_medicaid = character(0),
    stringsAsFactors = FALSE
  )
  out <- suppressMessages(mysterycall_clean_medicaid_col(df))

  expect_equal(nrow(out), 0L)
  expect_true("cleaned_does_the_physician_accept_medicaid" %in% names(out))
  expect_true("cleaned_does_the_physician_accept_medicaid_numeric" %in% names(out))
})

# ---------------------------------------------------------------------------
# 4. Bad input — column name not present in data frame
# ---------------------------------------------------------------------------
test_that("mysterycall_clean_medicaid_col errors when col is absent from data", {
  df <- data.frame(x = 1:3)
  expect_error(
    suppressMessages(mysterycall_clean_medicaid_col(df, col = "does_the_physician_accept_medicaid")),
    regexp = NULL   # checkmate::assert_names raises an error
  )
})

# ---------------------------------------------------------------------------
# 5. Custom column names and duplicate-name guard
# ---------------------------------------------------------------------------
test_that("mysterycall_clean_medicaid_col respects custom out_col_* names", {
  df  <- make_medicaid_df()
  out <- suppressMessages(
    mysterycall_clean_medicaid_col(
      df,
      out_col_cleaned = "medicaid_clean",
      out_col_numeric = "medicaid_bin"
    )
  )
  expect_true("medicaid_clean" %in% names(out))
  expect_true("medicaid_bin"   %in% names(out))
})

test_that("mysterycall_clean_medicaid_col errors when out_col_cleaned == out_col_numeric", {
  df <- make_medicaid_df()
  expect_error(
    suppressMessages(
      mysterycall_clean_medicaid_col(
        df,
        out_col_cleaned = "same_name",
        out_col_numeric = "same_name"
      )
    ),
    regexp = "must be different"
  )
})

# ---------------------------------------------------------------------------
# 6. Pre-existing output column triggers a warning (not an error)
# ---------------------------------------------------------------------------
test_that("mysterycall_clean_medicaid_col warns when output columns already exist", {
  df <- make_medicaid_df()
  df[["cleaned_does_the_physician_accept_medicaid"]] <- "already_here"

  expect_warning(
    suppressMessages(mysterycall_clean_medicaid_col(df)),
    regexp = "already exist"
  )
})
