test_that("dedup_by_insurance: basic deduplication works", {
  df <- data.frame(
    phone                 = c("555-1234", "555-1234", "555-9999", "555-9999"),
    insurance             = c("Medicaid", "Medicaid", "BCBS", "BCBS"),
    physician_information = c("Dr A", "Dr A", "Dr B", "Dr B"),
    wait_days             = c(3, 3, 7, 8),
    stringsAsFactors      = FALSE
  )
  res <- suppressMessages(
    mysterycall_dedup_by_insurance(df, output_dir = NA)
  )
  # Two unique phone x insurance combos
  expect_equal(nrow(res), 2L)
})

test_that("dedup_by_insurance: returns tibble", {
  df <- data.frame(
    phone     = c("A", "A", "B"),
    insurance = c("X", "X", "Y"),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_dedup_by_insurance(df, name_col = NULL, output_dir = NA)
  )
  expect_s3_class(res, "tbl_df")
})

test_that("dedup_by_insurance: no duplicates means same row count returned", {
  df <- data.frame(
    phone     = c("A", "B", "C"),
    insurance = c("X", "Y", "Z"),
    physician_information = c("Dr A", "Dr B", "Dr C"),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_dedup_by_insurance(df, output_dir = NA)
  )
  expect_equal(nrow(res), 3L)
})

test_that("dedup_by_insurance: name_col = NULL deduplicates only on phone x insurance", {
  df <- data.frame(
    phone     = c("A", "A", "A"),
    insurance = c("X", "X", "X"),
    physician_information = c("Dr A", "Dr A-dup", "Dr A-dup2"),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_dedup_by_insurance(df, name_col = NULL, output_dir = NA)
  )
  expect_equal(nrow(res), 1L)
})

test_that("dedup_by_insurance: wrong phone_col name gives error with 'not found'", {
  df <- data.frame(phone = "A", insurance = "X", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_dedup_by_insurance(df, phone_col = "bad_col", output_dir = NA),
    "missing"
  )
})

test_that("dedup_by_insurance: wrong insurance_col name gives error with 'not found'", {
  df <- data.frame(phone = "A", insurance = "X", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_dedup_by_insurance(df, insurance_col = "bad_col", output_dir = NA),
    "missing"
  )
})

test_that("dedup_by_insurance: wrong name_col gives error with 'not found'", {
  df <- data.frame(phone = "A", insurance = "X", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_dedup_by_insurance(df, name_col = "bad_col", output_dir = NA),
    "missing"
  )
})

test_that("dedup_by_insurance: empty data frame returns zero rows", {
  df <- data.frame(
    phone     = character(0),
    insurance = character(0),
    physician_information = character(0),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_dedup_by_insurance(df, output_dir = NA)
  )
  expect_equal(nrow(res), 0L)
})

test_that("dedup_by_insurance: single-row data returns single row", {
  df <- data.frame(
    phone     = "555",
    insurance = "BCBS",
    physician_information = "Dr X",
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_dedup_by_insurance(df, output_dir = NA)
  )
  expect_equal(nrow(res), 1L)
})

test_that("dedup_by_insurance: keep_all = TRUE retains extra columns", {
  df <- data.frame(
    phone     = c("A", "A"),
    insurance = c("X", "X"),
    physician_information = c("Dr A", "Dr A"),
    extra_col = c(1, 2),
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_dedup_by_insurance(df, output_dir = NA)
  )
  expect_true("extra_col" %in% names(res))
})

test_that("dedup_by_insurance: non-data-frame input raises error", {
  expect_error(
    mysterycall_dedup_by_insurance(list(a = 1), output_dir = NA),
    "data.frame"
  )
})

test_that("dedup_by_insurance: semantic - correct unique phone x insurance count", {
  set.seed(1)
  phones    <- sample(c("P1","P2","P3"), 30, replace = TRUE)
  insurances <- sample(c("Medicaid","BCBS","Aetna"), 30, replace = TRUE)
  names_vec <- paste0("Dr ", seq_len(30))
  df <- data.frame(
    phone                 = phones,
    insurance             = insurances,
    physician_information = names_vec,
    stringsAsFactors      = FALSE
  )
  expected_n <- nrow(unique(df[, c("insurance", "phone", "physician_information")]))
  res <- suppressMessages(
    mysterycall_dedup_by_insurance(df, output_dir = NA)
  )
  expect_equal(nrow(res), expected_n)
})

test_that("dedup_by_insurance: message mentions removed rows", {
  df <- data.frame(
    phone     = c("A", "A", "B"),
    insurance = c("X", "X", "Y"),
    physician_information = c("Dr A", "Dr A", "Dr B"),
    stringsAsFactors = FALSE
  )
  msgs <- capture.output(
    res <- mysterycall_dedup_by_insurance(df, output_dir = NA),
    type = "message"
  )
  expect_true(any(grepl("Removed 1 duplicate", msgs)))
})

test_that("dedup_by_insurance: writes file when output_dir is specified", {
  df <- data.frame(
    phone     = c("A", "A"),
    insurance = c("X", "X"),
    physician_information = c("Dr A", "Dr A"),
    stringsAsFactors = FALSE
  )
  tmp <- tempfile()
  dir.create(tmp)
  suppressMessages(
    mysterycall_dedup_by_insurance(df, output_dir = tmp)
  )
  expect_true(file.exists(file.path(tmp, "deduped_by_insurance.csv")))
})
