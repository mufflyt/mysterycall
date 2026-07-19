# Tests for mysterycall_cluster_id()

test_that("coalesces columns in order and gives unresolved rows singletons", {
  d <- data.frame(
    cbsa_code   = c("16980", "", NA, "31080"),
    county_fips = c("17031", "17097", "", "06037"),
    stringsAsFactors = FALSE
  )
  key <- mysterycall_cluster_id(d, c("cbsa_code", "county_fips"))
  expect_equal(key, c("16980", "17097", "solo_3", "31080"))
})

test_that("no row silently collapses: distinct unresolved rows get distinct keys", {
  d <- data.frame(a = c(NA, NA, "x"), b = c("", "", "y"), stringsAsFactors = FALSE)
  key <- mysterycall_cluster_id(d, c("a", "b"))
  expect_equal(key[3], "x")               # first non-missing across cols wins
  expect_false(key[1] == key[2])          # two blanks -> two singletons
  expect_true(grepl("^solo_", key[1]) && grepl("^solo_", key[2]))
})

test_that("first non-missing wins across more than two columns", {
  d <- data.frame(
    a = c(NA, NA, NA),
    b = c("", "B2", ""),
    c = c("C1", "C2", ""),
    stringsAsFactors = FALSE
  )
  key <- mysterycall_cluster_id(d, c("a", "b", "c"))
  expect_equal(key, c("C1", "B2", "solo_3"))
})

test_that("empty_as_missing = FALSE keeps empty strings as real keys", {
  d <- data.frame(a = c("", "x"), stringsAsFactors = FALSE)
  key <- mysterycall_cluster_id(d, "a", empty_as_missing = FALSE)
  expect_equal(key, c("", "x"))
})

test_that("solo_prefix = NA leaves unresolved rows NA with a warning", {
  d <- data.frame(a = c("x", NA), b = c("", ""), stringsAsFactors = FALSE)
  expect_warning(
    key <- mysterycall_cluster_id(d, c("a", "b"), solo_prefix = NA),
    "left NA"
  )
  expect_true(is.na(key[2]))
})

test_that("factor columns are handled", {
  d <- data.frame(a = factor(c("m", NA)), b = factor(c("p", "q")))
  key <- mysterycall_cluster_id(d, c("a", "b"))
  expect_equal(key, c("m", "q"))
})

test_that("a missing column errors", {
  d <- data.frame(a = "x")
  expect_error(mysterycall_cluster_id(d, c("a", "nope")), "subset")
})

test_that("output length always equals nrow", {
  d <- data.frame(a = c(NA, NA, NA, "z"), b = c(NA, "", " ", NA))
  expect_length(mysterycall_cluster_id(d, c("a", "b")), 4L)
})
