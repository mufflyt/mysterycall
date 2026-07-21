# Tests for mysterycall_link_physicians

test_that("input validation fires before the fastLink requirement", {
  a <- data.frame(first_name = "A", last_name = "B")
  # a name column absent from df_b -> checkmate error regardless of fastLink
  expect_error(
    mysterycall_link_physicians(a, data.frame(x = 1),
                                c("first_name", "last_name")),
    class = "simpleError"
  )
})

test_that("links two keyless lists with fuzzy name variants", {
  skip_if_not_installed("fastLink")
  a <- data.frame(
    first_name = c("Katherine", "Robert", "Maria"),
    last_name  = c("Smith", "Jones", "Garcia"),
    stringsAsFactors = FALSE
  )
  b <- data.frame(
    first_name = c("Kathryn", "Bob", "Unrelated"),
    last_name  = c("Smith", "Jones", "Person"),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_link_physicians(a, b, c("first_name", "last_name"),
                                     threshold = 0.5)
  expect_s3_class(res, "tbl_df")
  expect_true(all(c("index_a", "index_b", "posterior") %in% names(res)))
  # posterior sorted descending
  expect_false(is.unsorted(rev(res$posterior)))
})
