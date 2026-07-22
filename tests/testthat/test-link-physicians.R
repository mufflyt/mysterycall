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
  # fastLink needs a realistically-sized frame; a handful of rows hits
  # degenerate EM/dedup paths inside the package.
  first_pool <- c("James", "Mary", "Robert", "Patricia", "John", "Jennifer",
                  "Michael", "Linda", "David", "Elizabeth", "William",
                  "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas",
                  "Sarah", "Charles", "Karen")
  last_pool  <- c("Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia",
                  "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez",
                  "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor",
                  "Moore", "Jackson", "Martin")
  a <- data.frame(first_name = first_pool, last_name = last_pool,
                  stringsAsFactors = FALSE)
  b <- a
  b$first_name[3]  <- "Bob"     # Robert -> Bob
  b$first_name[10] <- "Beth"    # Elizabeth -> Beth
  b$last_name[5]   <- "Jonez"   # Jones typo

  res <- suppressWarnings(suppressMessages(
    mysterycall_link_physicians(a, b, c("first_name", "last_name"),
                                threshold = 0.85)))
  expect_s3_class(res, "tbl_df")
  expect_true(all(c("index_a", "index_b", "first_name_a", "first_name_b",
                    "posterior") %in% names(res)))
  expect_gt(nrow(res), 0L)
  # posterior sorted descending
  expect_false(is.unsorted(rev(res$posterior)))
  # exact-name rows link to themselves (same index in A and B)
  exact <- res[res$index_a == res$index_b, ]
  expect_true(nrow(exact) > 0L)
})
