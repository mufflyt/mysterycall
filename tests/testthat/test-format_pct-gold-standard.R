# test-mysterycall_format_pct-gold-standard.R
#
# Tests mysterycall_format_pct() against manually-computed gold-standard values.
# This is a pure function with no external dependencies or API calls.
#
# Testing tenets satisfied:
#   - Gold-standard manually-verified values (every expected output is hand-computed)
#   - Test for silent failures (mutation test documentation)
#   - Domain invariants (output always ends with %, length matches input)
#   - Idempotency (reformatting a parsed result gives same string)
#   - Boundary conditions (0, 1, 0.001, rounding at 0.9999)

library(testthat)

# ---------------------------------------------------------------------------
# 1-4. Core gold-standard values (manually verified)
# ---------------------------------------------------------------------------

test_that("mysterycall_format_pct(0.123, 1) == '12.3%' [gold standard]", {
  # 0.123 * 100 = 12.3, formatted to 1 decimal place → '12.3%'
  expect_equal(mysterycall_format_pct(0.123, 1), "12.3%")
})

test_that("mysterycall_format_pct(0, 1) == '0.0%' [gold standard boundary: zero]", {
  # Zero input must still format to 1 decimal place
  expect_equal(mysterycall_format_pct(0, 1), "0.0%")
})

test_that("mysterycall_format_pct(1, 1) == '100.0%' [gold standard boundary: one]", {
  # Maximum probability → 100.0%
  expect_equal(mysterycall_format_pct(1, 1), "100.0%")
})

test_that("mysterycall_format_pct(0.5, 0) == '50%' [gold standard: zero decimal places]", {
  # 0.5 * 100 = 50, no decimal → '50%'
  expect_equal(mysterycall_format_pct(0.5, 0), "50%")
})

# ---------------------------------------------------------------------------
# 5. Rounding boundary
# ---------------------------------------------------------------------------

test_that("mysterycall_format_pct(0.9999, 1) == '100.0%' [rounding up at boundary]", {
  # 0.9999 * 100 = 99.99, rounds to 100.0 at 1 decimal place
  expect_equal(mysterycall_format_pct(0.9999, 1), "100.0%")
})

# ---------------------------------------------------------------------------
# 6. Vectorization
# ---------------------------------------------------------------------------

test_that("mysterycall_format_pct(c(0.1, 0.2), 1) == c('10.0%', '20.0%') [vectorized]", {
  result <- mysterycall_format_pct(c(0.1, 0.2), 1)
  expect_equal(result, c("10.0%", "20.0%"))
})

# ---------------------------------------------------------------------------
# 7. Property: all outputs end with '%'
# ---------------------------------------------------------------------------

test_that("mysterycall_format_pct output always ends with '%'", {
  test_values <- c(0, 0.001, 0.123, 0.5, 0.9999, 1)
  for (x in test_values) {
    result <- mysterycall_format_pct(x, 1)
    expect_true(grepl("%$", result),
                label = paste("mysterycall_format_pct(", x, ", 1) =", result))
  }
})

test_that("mysterycall_format_pct with zero digits always ends with '%'", {
  test_values <- c(0, 0.5, 1)
  for (x in test_values) {
    result <- mysterycall_format_pct(x, 0)
    expect_true(grepl("%$", result),
                label = paste("mysterycall_format_pct(", x, ", 0) =", result))
  }
})

# ---------------------------------------------------------------------------
# 8. Property: output length equals input length
# ---------------------------------------------------------------------------

test_that("mysterycall_format_pct output length equals input vector length", {
  inputs <- c(0.1, 0.2, 0.3, 0.4, 0.5)
  expect_length(mysterycall_format_pct(inputs, 1), length(inputs))
})

test_that("mysterycall_format_pct of scalar returns length-1 character vector", {
  expect_length(mysterycall_format_pct(0.5, 1), 1L)
  expect_type(mysterycall_format_pct(0.5, 1), "character")
})

# ---------------------------------------------------------------------------
# 9. Idempotency: parse → re-format gives same result
# ---------------------------------------------------------------------------

test_that("formatting is idempotent: parse back and reformat gives same string", {
  # If mysterycall_format_pct(0.123, 1) == '12.3%', then
  # parse '12.3%' → 0.123, then mysterycall_format_pct(0.123, 1) should give '12.3%' again
  original_values <- c(0.1, 0.25, 0.5, 0.75, 0.999)
  for (v in original_values) {
    formatted   <- mysterycall_format_pct(v, 1)
    pct_stripped <- sub("%$", "", formatted)
    reparsed    <- as.numeric(pct_stripped) / 100
    reformatted <- mysterycall_format_pct(reparsed, 1)
    expect_equal(reformatted, formatted,
                 label = paste("Idempotency failed for v =", v))
  }
})

# ---------------------------------------------------------------------------
# 10. Boundary: small value with high precision
# ---------------------------------------------------------------------------

test_that("mysterycall_format_pct(0.001, 3) == '0.100%' [small value, 3 decimal places]", {
  # 0.001 * 100 = 0.1, formatted to 3 decimal places → '0.100%'
  expect_equal(mysterycall_format_pct(0.001, 3), "0.100%")
})

test_that("mysterycall_format_pct(0.001, 1) == '0.1%' [small value, 1 decimal place]", {
  # 0.001 * 100 = 0.1, formatted to 1 decimal place → '0.1%'
  expect_equal(mysterycall_format_pct(0.001, 1), "0.1%")
})

# ---------------------------------------------------------------------------
# 11. Mutation test (documented)
#
# If someone changes `100 * x` to just `x` in the implementation, then
# mysterycall_format_pct(0.123, 1) would return "0.1%" instead of "12.3%".
# Test #1 (mysterycall_format_pct(0.123, 1) == "12.3%") would catch this immediately.
# Similarly mysterycall_format_pct(0, 1) == "0.0%" would STILL pass under that mutation
# (because 0 * 100 == 0 == 0). But mysterycall_format_pct(0.5, 0) == "50%" catches it
# because 0.5 → "1%" under the mutation (wrong) vs "50%" (correct).
# ---------------------------------------------------------------------------

test_that("multiplication-by-100 is actually happening [mutation test]", {
  # If `100 * x` were replaced by `x`, this would return "0.1%" not "12.3%"
  expect_equal(mysterycall_format_pct(0.123, 1), "12.3%")
  # Belt-and-suspenders: also verify the value is clearly greater than 10%
  numeric_part <- as.numeric(sub("%", "", mysterycall_format_pct(0.123, 1)))
  expect_gt(numeric_part, 10,
            label = "Numeric part of mysterycall_format_pct(0.123,1) should be > 10")
})

# ---------------------------------------------------------------------------
# Additional: various digit counts
# ---------------------------------------------------------------------------

test_that("mysterycall_format_pct(0.12345, 2) gives correct 2-decimal rounding", {
  # 0.12345 * 100 = 12.345, rounds to 12.35 at 2 dp
  result <- mysterycall_format_pct(0.12345, 2)
  expect_equal(result, "12.35%")
})

test_that("mysterycall_format_pct default my_digits is 1", {
  # Calling without second argument should behave like my_digits=1
  expect_equal(mysterycall_format_pct(0.123), mysterycall_format_pct(0.123, 1))
})
