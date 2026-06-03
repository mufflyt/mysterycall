# ── mysterycall:::mysterycall_luhn_check ────────────────────────────────────────────────────

test_that("luhn_check: known valid NPI → TRUE", {
  # NPI 1234567893 is a well-known test NPI that passes the CMS Luhn check
  expect_true(mysterycall:::mysterycall_luhn_check("1234567893"))
})

test_that("luhn_check: invalid NPI → FALSE", {
  expect_false(mysterycall:::mysterycall_luhn_check("1234567890"))
})

test_that("luhn_check: NA → FALSE", {
  expect_false(mysterycall:::mysterycall_luhn_check(NA_character_))
})

test_that("luhn_check: non-10-digit string → FALSE", {
  expect_false(mysterycall:::mysterycall_luhn_check("12345"))
  expect_false(mysterycall:::mysterycall_luhn_check("12345678901"))
})

test_that("luhn_check: non-digit characters → FALSE", {
  expect_false(mysterycall:::mysterycall_luhn_check("123456789X"))
})

test_that("luhn_check: numeric input coerced to character", {
  expect_false(mysterycall:::mysterycall_luhn_check(1234567890))
})

test_that("luhn_check: vectorized — returns logical vector same length", {
  npis <- c("1234567893", "9999999999", NA, "123")
  res  <- mysterycall:::mysterycall_luhn_check(npis)
  expect_type(res, "logical")
  expect_length(res, 4L)
  expect_true(res[[1L]])
  expect_false(res[[2L]])
  expect_false(res[[3L]])
  expect_false(res[[4L]])
})
