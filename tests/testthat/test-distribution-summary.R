make_ins_df <- function() {
  data.frame(
    insurance = c("Medicaid","BCBS","Medicaid","Medicaid","BCBS","Aetna", NA),
    stringsAsFactors = FALSE
  )
}

test_that("distribution_summary: modal level is correct", {
  df  <- make_ins_df()
  res <- mysterycall_distribution_summary(df, "insurance")
  expect_equal(res$level, "Medicaid")
})

test_that("distribution_summary: count matches manual tabulation", {
  df  <- make_ins_df()
  res <- mysterycall_distribution_summary(df, "insurance")
  expect_equal(res$count, 3L)
})

test_that("distribution_summary: total excludes NAs", {
  df  <- make_ins_df()
  res <- mysterycall_distribution_summary(df, "insurance")
  # 6 non-NA rows
  expect_equal(res$total, 6L)
})

test_that("distribution_summary: percent is correct", {
  df  <- make_ins_df()
  res <- mysterycall_distribution_summary(df, "insurance")
  expect_equal(res$percent, round(3 / 6 * 100, 1))
})

test_that("distribution_summary: full_table percents sum to ~100", {
  df  <- make_ins_df()
  res <- mysterycall_distribution_summary(df, "insurance")
  expect_equal(round(sum(res$full_table$percent), 0), 100)
})

test_that("distribution_summary: full_table is a tibble with correct columns", {
  df  <- make_ins_df()
  res <- mysterycall_distribution_summary(df, "insurance")
  expect_s3_class(res$full_table, "tbl_df")
  expect_true(all(c("level","count","percent") %in% names(res$full_table)))
})

test_that("distribution_summary: full_table ordered descending by count", {
  df  <- make_ins_df()
  res <- mysterycall_distribution_summary(df, "insurance")
  expect_true(all(diff(res$full_table$count) <= 0))
})

test_that("distribution_summary: sentence contains modal level and counts", {
  df  <- make_ins_df()
  res <- mysterycall_distribution_summary(df, "insurance")
  expect_true(grepl("Medicaid", res$sentence))
  expect_true(grepl("n = 3",   res$sentence))
  expect_true(grepl("N = 6",   res$sentence))
})

test_that("distribution_summary: wrong column name errors with 'not found'", {
  df <- make_ins_df()
  expect_error(
    mysterycall_distribution_summary(df, "bad_col"),
    "missing"
  )
})

test_that("distribution_summary: all-NA column raises error", {
  df <- data.frame(x = c(NA_character_, NA_character_), stringsAsFactors = FALSE)
  expect_error(
    mysterycall_distribution_summary(df, "x"),
    regexp = "NA"
  )
})

test_that("distribution_summary: non-data-frame input errors", {
  expect_error(
    mysterycall_distribution_summary(list(x = "a"), "x"),
    "data.frame"
  )
})

test_that("distribution_summary: single non-NA row works", {
  df  <- data.frame(x = "BCBS", stringsAsFactors = FALSE)
  res <- mysterycall_distribution_summary(df, "x")
  expect_equal(res$level,   "BCBS")
  expect_equal(res$count,   1L)
  expect_equal(res$total,   1L)
  expect_equal(res$percent, 100)
})

test_that("distribution_summary: digit rounding of percent respected", {
  df  <- data.frame(x = c("A","A","B","C"), stringsAsFactors = FALSE)
  res <- mysterycall_distribution_summary(df, "x", digits = 2)
  expect_equal(res$percent, round(2/4 * 100, 2))
})

test_that("distribution_summary: sentence ends with percent sign and period", {
  df  <- make_ins_df()
  res <- mysterycall_distribution_summary(df, "insurance")
  expect_true(grepl("%\\)\\.", res$sentence))
})

test_that("distribution_summary: works with factor column", {
  df  <- data.frame(
    ins = factor(c("Medicaid","BCBS","Medicaid","Medicaid")),
    stringsAsFactors = FALSE
  )
  res <- mysterycall_distribution_summary(df, "ins")
  expect_equal(res$level, "Medicaid")
  expect_equal(res$count, 3L)
})

test_that("distribution_summary: semantic check with set.seed data", {
  set.seed(7)
  lvls <- c("Medicaid","BCBS","Aetna","UHC")
  x    <- sample(lvls, 100, replace = TRUE,
                 prob = c(0.45, 0.30, 0.15, 0.10))
  df   <- data.frame(plan = x, stringsAsFactors = FALSE)
  res  <- mysterycall_distribution_summary(df, "plan")
  # modal level should be the one with highest count in the table
  expect_equal(res$level, res$full_table$level[1])
  expect_equal(res$count, res$full_table$count[1])
})
