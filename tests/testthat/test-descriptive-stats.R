test_that("descriptive_stats: basic correct computation", {
  df  <- data.frame(x = c(1, 3, 5, 7, 9), stringsAsFactors = FALSE)
  res <- mysterycall_descriptive_stats(df, "x")
  expect_equal(res$median,    5)
  expect_equal(res$q25,       round(unname(quantile(c(1,3,5,7,9), 0.25)), 0))
  expect_equal(res$q75,       round(unname(quantile(c(1,3,5,7,9), 0.75)), 0))
  expect_equal(res$n,         5L)
  expect_equal(res$n_missing, 0L)
})

test_that("descriptive_stats: ignores NA in calculation", {
  df  <- data.frame(x = c(1, 3, NA, 7, NA), stringsAsFactors = FALSE)
  res <- mysterycall_descriptive_stats(df, "x")
  expect_equal(res$n,         3L)
  expect_equal(res$n_missing, 2L)
  expect_equal(res$median,    round(median(c(1,3,7), na.rm = TRUE), 2))
})

test_that("descriptive_stats: digits argument respected for median", {
  df  <- data.frame(x = c(1.1111, 2.2222, 3.3333), stringsAsFactors = FALSE)
  res <- mysterycall_descriptive_stats(df, "x", digits = 1)
  expect_equal(res$median, round(median(c(1.1111, 2.2222, 3.3333)), 1))
})

test_that("descriptive_stats: digits_q argument respected for quartiles", {
  df  <- data.frame(x = c(1, 3, 5, 7, 9), stringsAsFactors = FALSE)
  res <- mysterycall_descriptive_stats(df, "x", digits_q = 2)
  expect_equal(res$q25, round(unname(quantile(c(1,3,5,7,9), 0.25)), 2))
  expect_equal(res$q75, round(unname(quantile(c(1,3,5,7,9), 0.75)), 2))
})

test_that("descriptive_stats: sentence contains correct values", {
  set.seed(42)
  x   <- rpois(50, lambda = 10)
  df  <- data.frame(wait = x, stringsAsFactors = FALSE)
  res <- mysterycall_descriptive_stats(df, "wait")
  expect_true(grepl(as.character(res$median), res$sentence))
  expect_true(grepl("IQR", res$sentence))
  expect_true(grepl("wait", res$sentence))
})

test_that("descriptive_stats: all-NA column returns n_missing = n and NA stats", {
  df  <- data.frame(x = c(NA_real_, NA_real_, NA_real_))
  res <- mysterycall_descriptive_stats(df, "x")
  expect_equal(res$n_missing, 3L)
  expect_equal(res$n,         0L)
  expect_true(is.na(res$median))
  expect_true(is.na(res$q25))
  expect_true(is.na(res$q75))
})

test_that("descriptive_stats: wrong column name errors with 'not found'", {
  df <- data.frame(x = 1:3)
  expect_error(
    mysterycall_descriptive_stats(df, "bad_col"),
    "not found"
  )
})

test_that("descriptive_stats: non-numeric column errors with informative message", {
  df <- data.frame(x = c("a", "b", "c"), stringsAsFactors = FALSE)
  expect_error(
    mysterycall_descriptive_stats(df, "x"),
    "numeric"
  )
})

test_that("descriptive_stats: non-data-frame input errors", {
  expect_error(
    mysterycall_descriptive_stats(list(x = 1:3), "x"),
    "data frame"
  )
})

test_that("descriptive_stats: single row works", {
  df  <- data.frame(x = 42)
  res <- mysterycall_descriptive_stats(df, "x")
  expect_equal(res$median, 42)
  expect_equal(res$n,      1L)
})

test_that("descriptive_stats: semantic check against manual calculation", {
  set.seed(99)
  x   <- rnorm(100, mean = 20, sd = 5)
  df  <- data.frame(value = x, stringsAsFactors = FALSE)
  res <- mysterycall_descriptive_stats(df, "value", digits = 2, digits_q = 1)
  expect_equal(res$median, round(median(x), 2))
  expect_equal(res$q25,    round(unname(quantile(x, 0.25)), 1))
  expect_equal(res$q75,    round(unname(quantile(x, 0.75)), 1))
})

test_that("descriptive_stats: sentence ends with a period", {
  df  <- data.frame(wait = c(1, 2, 3))
  res <- mysterycall_descriptive_stats(df, "wait")
  expect_true(endsWith(res$sentence, "."))
})

test_that("descriptive_stats: returned list has all required names", {
  df  <- data.frame(x = 1:5)
  res <- mysterycall_descriptive_stats(df, "x")
  expect_true(all(c("median","q25","q75","n","n_missing","sentence") %in% names(res)))
})
