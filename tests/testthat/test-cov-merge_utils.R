library(testthat)
library(mysterycall)

# mysterycall_merge_with_prefix is @keywords internal (not exported).
# Access via ::: which is acceptable in package tests for internal helpers.

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------
REG <- data.frame(
  npi       = c("A", "B", "C"),
  state     = c("CO", "TX", "CA"),
  specialty = c("ENT", "ENT", "GYN"),
  stringsAsFactors = FALSE
)

CERT <- data.frame(
  npi  = c("A", "C", "D"),
  cert = c("Neurotology", "Reproductive", NA_character_),
  year = c(2010L, 2015L, 2018L),
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# 1. Happy path – default left join with default prefixes
# ---------------------------------------------------------------------------
test_that("mysterycall_merge_with_prefix performs a left join and prefixes columns", {
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_merge_with_prefix(REG, CERT, by = "npi")
  ))

  # Key column is unprefixed
  expect_true("npi" %in% names(result))

  # Non-key columns of x get "x_" prefix
  expect_true("x_state"     %in% names(result))
  expect_true("x_specialty" %in% names(result))

  # Non-key columns of y get "y_" prefix
  expect_true("y_cert" %in% names(result))
  expect_true("y_year" %in% names(result))

  # Left join: all rows from x are present
  expect_equal(nrow(result), nrow(REG))

  # "B" (in x, not in y) should have NA for y_ columns
  row_B <- result[result$npi == "B", , drop = FALSE]
  expect_true(is.na(row_B$y_cert))
})

# ---------------------------------------------------------------------------
# 2. Happy path – inner join drops unmatched rows from both sides
# ---------------------------------------------------------------------------
test_that("mysterycall_merge_with_prefix inner join keeps only matched rows", {
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_merge_with_prefix(
      REG, CERT, by = "npi", join_type = "inner"
    )
  ))

  # Only "A" and "C" appear in both tables
  expect_equal(sort(result$npi), c("A", "C"))
  expect_equal(nrow(result), 2L)
})

# ---------------------------------------------------------------------------
# 3. Happy path – custom prefix strings
# ---------------------------------------------------------------------------
test_that("mysterycall_merge_with_prefix respects custom prefix_x / prefix_y", {
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_merge_with_prefix(
      REG, CERT, by = "npi",
      prefix_x = "reg_", prefix_y = "cert_"
    )
  ))

  expect_true("reg_state"     %in% names(result))
  expect_true("reg_specialty" %in% names(result))
  expect_true("cert_cert"     %in% names(result))
  expect_true("cert_year"     %in% names(result))
})

# ---------------------------------------------------------------------------
# 4. Edge case – zero-row data frames (empty tables)
# ---------------------------------------------------------------------------
test_that("mysterycall_merge_with_prefix handles zero-row data frames", {
  empty_x <- REG[integer(0), ]
  empty_y <- CERT[integer(0), ]

  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_merge_with_prefix(empty_x, empty_y, by = "npi")
  ))

  expect_equal(nrow(result), 0L)
  expect_true("npi"       %in% names(result))
  expect_true("x_state"   %in% names(result))
  expect_true("y_cert"    %in% names(result))
})

# ---------------------------------------------------------------------------
# 5. Edge case – NA values in non-key columns are preserved
# ---------------------------------------------------------------------------
test_that("mysterycall_merge_with_prefix preserves NA in non-key columns", {
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_merge_with_prefix(REG, CERT, by = "npi")
  ))

  # "D" exists only in CERT; left join excludes it.
  # "C" matches and CERT$cert for "C" is "Reproductive" (not NA in this fixture).
  # The NA in CERT is for "D" which is not in x, so confirm "C" has cert value.
  row_C <- result[result$npi == "C", , drop = FALSE]
  expect_equal(row_C$y_cert, "Reproductive")

  # "B" is in x but not y → NA for y_ columns
  row_B <- result[result$npi == "B", , drop = FALSE]
  expect_true(is.na(row_B$y_cert))
  expect_true(is.na(row_B$y_year))
})

# ---------------------------------------------------------------------------
# 6. Bad input – x is not a data frame
# ---------------------------------------------------------------------------
test_that("mysterycall_merge_with_prefix errors when x is not a data frame", {
  expect_error(
    mysterycall:::mysterycall_merge_with_prefix(list(npi = "A"), CERT, by = "npi"),
    regexp = "must be a data frame"
  )
})

# ---------------------------------------------------------------------------
# 7. Bad input – y is not a data frame
# ---------------------------------------------------------------------------
test_that("mysterycall_merge_with_prefix errors when y is not a data frame", {
  expect_error(
    mysterycall:::mysterycall_merge_with_prefix(REG, "not_a_df", by = "npi"),
    regexp = "must be a data frame"
  )
})

# ---------------------------------------------------------------------------
# 8. Bad input – join key missing from x
# ---------------------------------------------------------------------------
test_that("mysterycall_merge_with_prefix errors when key column is absent from x", {
  expect_error(
    mysterycall:::mysterycall_merge_with_prefix(REG, CERT, by = "missing_col"),
    regexp = "Join key"
  )
})

# ---------------------------------------------------------------------------
# 9. Bad input – join key missing from y
# ---------------------------------------------------------------------------
test_that("mysterycall_merge_with_prefix errors when key column is absent from y", {
  expect_error(
    mysterycall:::mysterycall_merge_with_prefix(REG, CERT, by = "state"),
    regexp = "Join key"
  )
})
