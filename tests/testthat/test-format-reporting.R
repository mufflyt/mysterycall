# Tests for mysterycall_format_ci() and mysterycall_format_p()

test_that("format_ci joins endpoints with 'to' by default", {
  expect_equal(mysterycall_format_ci(1.05, 1.57), "1.05 to 1.57")
  expect_equal(mysterycall_format_ci(1.0512, 1.5684, digits = 3L), "1.051 to 1.568")
})

test_that("format_ci keeps a negative interval unambiguous", {
  # the defect this exists to prevent: "-0.45--0.12"
  out <- mysterycall_format_ci(-0.45, -0.12)
  expect_equal(out, "-0.45 to -0.12")
  expect_false(grepl("--", out, fixed = TRUE))
})

test_that("format_ci is vectorised and NA-propagating", {
  expect_equal(
    mysterycall_format_ci(c(1.05, NA, 2.0), c(1.57, 2.0, NA)),
    c("1.05 to 1.57", NA, NA)
  )
  # scalar endpoints recycle against a vector
  expect_length(mysterycall_format_ci(1, c(2, 3, 4)), 3L)
  expect_equal(mysterycall_format_ci(numeric(0), numeric(0)), character(0))
})

test_that("format_ci separator is settable per call and per session", {
  expect_equal(mysterycall_format_ci(0.4, 0.9, digits = 1L, sep = " - "), "0.4 - 0.9")
  withr::with_options(
    list(mysterycall.ci_sep = " -- "),
    expect_equal(mysterycall_format_ci(1, 2, digits = 0L), "1 -- 2")
  )
  # and the option does not leak past the block
  expect_equal(mysterycall_format_ci(1, 2, digits = 0L), "1 to 2")
})

test_that("format_ci rejects bad input", {
  expect_error(mysterycall_format_ci("a", 1))
  expect_error(mysterycall_format_ci(1, 2, sep = c(" to ", " - ")))
})

test_that("format_p prints exact values and collapses only below threshold", {
  expect_equal(mysterycall_format_p(0.0431), "0.043")
  expect_equal(mysterycall_format_p(0.0004), "< 0.001")
  expect_equal(mysterycall_format_p(0.001), "0.001")   # at the threshold, not below
  expect_true(is.na(mysterycall_format_p(NA_real_)))
})

test_that("format_p never emits NS or an unspaced inequality", {
  out <- mysterycall_format_p(c(0.9, 0.0000001))
  expect_false(any(grepl("NS", out, fixed = TRUE)))
  expect_false(any(grepl("<0", out, fixed = TRUE)))
})

test_that("format_p prefixes for prose when name is given", {
  expect_equal(mysterycall_format_p(0.0431, name = "p"), "p = 0.043")
  expect_equal(mysterycall_format_p(0.0004, name = "p"), "p < 0.001")
  expect_equal(mysterycall_format_p(0.02, name = "P"), "P = 0.020")
})

test_that("format_p honours a non-default threshold", {
  expect_equal(mysterycall_format_p(0.03, threshold = 0.05), "< 0.05")
  expect_equal(mysterycall_format_p(0.06, threshold = 0.05), "0.060")
})

test_that("the internal spelling still behaves exactly as before", {
  expect_equal(
    mysterycall:::.mc_format_p(c(0.0431, 0.0004, NA)),
    c("0.043", "< 0.001", NA)
  )
  expect_equal(mysterycall:::.mc_format_p(0.12345, digits = 2L), "0.12")
})
