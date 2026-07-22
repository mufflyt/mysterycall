library(testthat)

# ─────────────────────────────────────────────────────────────────────────────
# Clean-bug fixes: the ZIP normalizers agree on a dropped leading zero, and the
# two NPI validators agree on punctuation/whitespace.
# ─────────────────────────────────────────────────────────────────────────────

test_that("normalize_zip5 zero-pads character input (was NA before)", {
  skip_if_not_installed("stringr")
  # "7001" is an NJ 07001 whose leading zero was dropped and re-stored as text.
  expect_equal(mysterycall:::mysterycall_normalize_zip5("7001"), "07001")
  expect_equal(mysterycall:::mysterycall_normalize_zip5(7001), "07001")   # numeric too
  expect_equal(mysterycall:::mysterycall_normalize_zip5("80111-1234"), "80111")
  expect_equal(mysterycall:::mysterycall_normalize_zip5("90210"), "90210")
  expect_true(is.na(mysterycall:::mysterycall_normalize_zip5("no digits here")))
})

test_that("the ZIP normalizers agree on a dropped leading zero", {
  skip_if_not_installed("stringr")
  z <- "7001"
  expect_equal(mysterycall:::mysterycall_normalize_zip5(z), mysterycall_clean_zip(z))
  expect_equal(mysterycall_clean_zip(z), mysterycall:::mysterycall_extract_zip5(z))
  # all three -> "07001"
  expect_equal(mysterycall_clean_zip(z), "07001")
})

test_that("normalize_zip5 stays vectorized", {
  skip_if_not_installed("stringr")
  out <- mysterycall:::mysterycall_normalize_zip5(c("7001", "90210", NA, "abc"))
  expect_equal(out, c("07001", "90210", NA, NA))
})

# ── NPI ────────────────────────────────────────────────────────────────────

test_that("luhn_check accepts a valid NPI carrying punctuation/whitespace", {
  # 1234567893 is a valid NPI (passes the CMS Luhn check).
  expect_true(mysterycall:::mysterycall_luhn_check("1234567893"))
  expect_true(mysterycall:::mysterycall_luhn_check("123-456-7893"))  # dashes
  expect_true(mysterycall:::mysterycall_luhn_check("1234567893 "))   # trailing space
})

test_that("luhn_check still rejects a bad checksum and NA", {
  expect_false(mysterycall:::mysterycall_luhn_check("1234567890"))   # bad checksum
  expect_false(mysterycall:::mysterycall_luhn_check(NA))
  expect_false(mysterycall:::mysterycall_luhn_check("12345"))        # too short
  expect_false(mysterycall:::mysterycall_luhn_check("123-456-7890")) # punctuated but bad checksum
})
