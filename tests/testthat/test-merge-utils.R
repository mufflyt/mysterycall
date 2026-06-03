# ── mysterycall:::mysterycall_merge_with_prefix ─────────────────────────────────────────────

make_x <- function() data.frame(npi="A", state="CO", specialty="ENT", stringsAsFactors=FALSE)
make_y <- function() data.frame(npi="A", cert="Neurotology", stringsAsFactors=FALSE)

test_that("merge_with_prefix: returns data frame", {
  res <- mysterycall:::mysterycall_merge_with_prefix(make_x(), make_y(), by = "npi")
  expect_s3_class(res, "data.frame")
})

test_that("merge_with_prefix: key column not prefixed", {
  res <- mysterycall:::mysterycall_merge_with_prefix(make_x(), make_y(), by = "npi")
  expect_true("npi" %in% names(res))
})

test_that("merge_with_prefix: non-key columns from x have prefix_x", {
  res <- mysterycall:::mysterycall_merge_with_prefix(make_x(), make_y(), by = "npi",
                                        prefix_x = "reg_", prefix_y = "ab_")
  expect_true("reg_state"    %in% names(res))
  expect_true("reg_specialty" %in% names(res))
})

test_that("merge_with_prefix: non-key columns from y have prefix_y", {
  res <- mysterycall:::mysterycall_merge_with_prefix(make_x(), make_y(), by = "npi",
                                        prefix_x = "reg_", prefix_y = "ab_")
  expect_true("ab_cert" %in% names(res))
})

test_that("merge_with_prefix: left join preserves all x rows", {
  x <- data.frame(npi = c("A","B"), val = 1:2, stringsAsFactors = FALSE)
  y <- data.frame(npi = "A", extra = "yes", stringsAsFactors = FALSE)
  res <- mysterycall:::mysterycall_merge_with_prefix(x, y, by = "npi")
  expect_equal(nrow(res), 2L)
})

test_that("merge_with_prefix: inner join drops unmatched rows", {
  x <- data.frame(npi = c("A","B"), val = 1:2, stringsAsFactors = FALSE)
  y <- data.frame(npi = "A", extra = "yes", stringsAsFactors = FALSE)
  res <- mysterycall:::mysterycall_merge_with_prefix(x, y, by = "npi", join_type = "inner")
  expect_equal(nrow(res), 1L)
})

test_that("merge_with_prefix: missing by col in x errors", {
  expect_error(
    mysterycall:::mysterycall_merge_with_prefix(make_x(), make_y(), by = "nonexistent"),
    "Join key"
  )
})

test_that("merge_with_prefix: non-data-frame x errors", {
  expect_error(
    mysterycall:::mysterycall_merge_with_prefix(list(), make_y(), by = "npi"),
    "data frame"
  )
})
