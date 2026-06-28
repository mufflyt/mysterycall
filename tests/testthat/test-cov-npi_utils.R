library(testthat)
library(mysterycall)

# mysterycall_luhn_check is @keywords internal; access via ::: as shown in its
# own examples.  mysterycall_validate_npi (exported) exercises the same logic
# at the data-frame level.

# ---------------------------------------------------------------------------
# Happy path: known-valid and known-invalid NPIs
# ---------------------------------------------------------------------------
test_that("mysterycall_luhn_check returns TRUE for a valid NPI and FALSE for an invalid one", {
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_luhn_check(c("1234567893", "9999999999"))
  ))
  expect_type(result, "logical")
  expect_true(result[1L],  label = "1234567893 should pass CMS Luhn")
  expect_false(result[2L], label = "9999999999 should fail CMS Luhn")
})

# ---------------------------------------------------------------------------
# Edge cases: NA, empty string, wrong length
# ---------------------------------------------------------------------------
test_that("mysterycall_luhn_check returns FALSE for NA, empty string, and wrong-length strings", {
  inputs <- c(NA_character_, "", "123", "12345678901", "ABCDEFGHIJ")
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_luhn_check(inputs)
  ))
  expect_length(result, length(inputs))
  expect_true(all(!result), label = "all malformed inputs should return FALSE")
})

# ---------------------------------------------------------------------------
# Numeric input: coercion to character must preserve 10 digits
# ---------------------------------------------------------------------------
test_that("mysterycall_luhn_check accepts numeric NPI input", {
  # as.character(1234567893) -> "1234567893" (no scientific notation)
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_luhn_check(1234567893)
  ))
  expect_true(result, label = "numeric 1234567893 should pass CMS Luhn")
})

# ---------------------------------------------------------------------------
# Output shape: length-preservation and type
# ---------------------------------------------------------------------------
test_that("mysterycall_luhn_check returns a logical vector the same length as input", {
  npis <- c("1234567893", "0000000000", "9999999999", NA_character_, "short")
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_luhn_check(npis)
  ))
  expect_type(result, "logical")
  expect_length(result, length(npis))
})

# ---------------------------------------------------------------------------
# Exported wrapper: mysterycall_validate_npi filters to Luhn-valid rows
# ---------------------------------------------------------------------------
test_that("mysterycall_validate_npi keeps valid NPIs and drops invalid ones", {
  df <- data.frame(
    npi   = c("1234567893", "9999999999", "0000000000", NA_character_),
    value = 1:4,
    stringsAsFactors = FALSE
  )
  out <- suppressMessages(suppressWarnings(
    mysterycall_validate_npi(df)
  ))
  expect_s3_class(out, "data.frame")
  # Only the first NPI is Luhn-valid
  expect_equal(nrow(out), 1L)
  expect_equal(out$npi, "1234567893")
  expect_true(all(out$npi_is_valid))
})

# ---------------------------------------------------------------------------
# Bad input: missing `npi` column should error
# ---------------------------------------------------------------------------
test_that("mysterycall_validate_npi errors when `npi` column is absent", {
  bad_df <- data.frame(provider_id = "1234567893", stringsAsFactors = FALSE)
  expect_error(
    suppressMessages(suppressWarnings(mysterycall_validate_npi(bad_df))),
    regexp = "npi"
  )
})

# ---------------------------------------------------------------------------
# Bad input: wrong type (not a data frame or file path) should error
# ---------------------------------------------------------------------------
test_that("mysterycall_validate_npi errors on non-data-frame / non-path input", {
  expect_error(
    suppressMessages(suppressWarnings(mysterycall_validate_npi(42L))),
    regexp = "data frame"
  )
})
