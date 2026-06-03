# ── mysterycall:::mysterycall_extract_zip5 ──────────────────────────────────────────────────

test_that("extract_zip5: standard 5-digit ZIP", {
  expect_equal(mysterycall:::mysterycall_extract_zip5("80203"), "80203")
})

test_that("extract_zip5: ZIP+4 → 5 digits", {
  expect_equal(mysterycall:::mysterycall_extract_zip5("80203-1234"), "80203")
})

test_that("extract_zip5: leading/trailing whitespace trimmed", {
  expect_equal(mysterycall:::mysterycall_extract_zip5("  80203 "), "80203")
})

test_that("extract_zip5: 4-digit ZIP left-padded to 5", {
  expect_equal(mysterycall:::mysterycall_extract_zip5("8020"), "08020")
})

test_that("extract_zip5: all-alpha string → NA", {
  expect_true(is.na(mysterycall:::mysterycall_extract_zip5("abc")))
})

test_that("extract_zip5: NA → NA", {
  expect_true(is.na(mysterycall:::mysterycall_extract_zip5(NA_character_)))
})

test_that("extract_zip5: 2-digit string → NA (too short)", {
  expect_true(is.na(mysterycall:::mysterycall_extract_zip5("80")))
})

test_that("extract_zip5: vectorized", {
  res <- mysterycall:::mysterycall_extract_zip5(c("80203-1234", "8020", "abc", NA))
  expect_length(res, 4L)
  expect_equal(res[[1L]], "80203")
  expect_equal(res[[2L]], "08020")
  expect_true(is.na(res[[3L]]))
  expect_true(is.na(res[[4L]]))
})

test_that("extract_zip5: returns character vector", {
  expect_type(mysterycall:::mysterycall_extract_zip5("80203"), "character")
})
