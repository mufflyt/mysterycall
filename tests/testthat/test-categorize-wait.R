# Tests for mysterycall_categorize_wait

test_that("over_threshold uses strict greater-than", {
  res <- mysterycall_categorize_wait(c(14, 15), threshold_days = 14)
  expect_equal(res$over_threshold, c(FALSE, TRUE))
})

test_that("weekly bins land in the right category", {
  res <- mysterycall_categorize_wait(c(3, 10, 15, 30))
  expect_equal(as.character(res$bin),
               c("0-7", "8-14", "15-21", "> 28"))
  expect_s3_class(res$bin, "ordered")
})

test_that("NA days give NA bin and NA flag", {
  res <- mysterycall_categorize_wait(c(5, NA))
  expect_true(is.na(res$bin[2]))
  expect_true(is.na(res$over_threshold[2]))
})

test_that("returns one row per input with the input echoed", {
  res <- mysterycall_categorize_wait(c(1, 2, 3))
  expect_equal(nrow(res), 3L)
  expect_equal(res$days, c(1, 2, 3))
})

test_that("custom bin_width / max_bin change the top bin label", {
  res <- mysterycall_categorize_wait(c(5, 40), bin_width = 10, max_bin = 30)
  expect_equal(as.character(res$bin), c("0-10", "> 30"))
})

test_that("non-numeric input errors", {
  expect_error(mysterycall_categorize_wait(c("a", "b")))
})
