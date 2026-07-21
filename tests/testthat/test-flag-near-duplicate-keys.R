# Tests for mysterycall_flag_near_duplicate_keys

test_that("flags a single-character typo pair", {
  keys <- c("Aurora Womens Health", "Aurora Women's Health",
            "Denver Fertility", "Boulder OBGYN")
  res <- mysterycall_flag_near_duplicate_keys(keys)
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 1L)
  expect_true(all(c("Aurora Womens Health", "Aurora Women's Health") %in%
                    c(res$key_a, res$key_b)))
  expect_equal(res$edit_distance, 1L)
})

test_that("distinct keys produce zero rows with the right columns", {
  res <- mysterycall_flag_near_duplicate_keys(c("Alpha Clinic", "Zephyr Group"))
  expect_equal(nrow(res), 0L)
  expect_named(res, c("key_a", "key_b", "edit_distance", "norm_distance"))
})

test_that("NA, empty, and duplicate entries are dropped before comparison", {
  keys <- c("Same Place", "Same Place", NA, "", "   ")
  res <- mysterycall_flag_near_duplicate_keys(keys)
  # after de-duping only one unique key remains -> no pairs
  expect_equal(nrow(res), 0L)
})

test_that("case-insensitive by default, case-sensitive on request", {
  keys <- c("clinic a", "CLINIC A")
  # ignore_case (default): normalized identical -> edit distance 0, flagged
  ci <- mysterycall_flag_near_duplicate_keys(keys, ignore_case = TRUE)
  expect_equal(nrow(ci), 1L)
  expect_equal(ci$edit_distance, 0L)
  # case-sensitive: every letter differs (distance 7 > max_edit 4) -> not flagged
  cs <- mysterycall_flag_near_duplicate_keys(keys, ignore_case = FALSE)
  expect_equal(nrow(cs), 0L)
})

test_that("max_edit threshold gates the flag", {
  keys <- c("abcdef", "abcXYZ")  # edit distance 3
  expect_equal(nrow(mysterycall_flag_near_duplicate_keys(
    keys, max_edit = 4L, max_norm = 0)), 1L)
  expect_equal(nrow(mysterycall_flag_near_duplicate_keys(
    keys, max_edit = 2L, max_norm = 0)), 0L)
})

test_that("single key returns empty result", {
  expect_equal(nrow(mysterycall_flag_near_duplicate_keys("only one")), 0L)
})
