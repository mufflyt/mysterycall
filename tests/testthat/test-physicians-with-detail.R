make_phys_df <- function() {
  data.frame(
    id_number                       = c("001", "002", "003", "004", "005"),
    physician_information           = c("Dr A", "Dr B", "Dr C", "Dr D", "Dr E"),
    reason_for_exclusions           = c("Able to contact", NA,
                                        "No appointment", "Able to contact",
                                        "Number disconnected"),
    insurance                       = c("Medicaid", "BCBS", "Medicaid",
                                        "BCBS", "Aetna"),
    business_days_until_appointment = c(5, NA, NA, 10, NA),
    extra_col                       = letters[1:5],
    stringsAsFactors                = FALSE
  )
}

test_that("physicians_with_detail: returns matching rows", {
  df  <- make_phys_df()
  res <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = c("001", "003"),
                                       output_dir = NA)
  )
  expect_equal(nrow(res), 2L)
})

test_that("physicians_with_detail: returns tibble", {
  df  <- make_phys_df()
  res <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = "002",
                                       output_dir = NA)
  )
  expect_s3_class(res, "tbl_df")
})

test_that("physicians_with_detail: returned IDs exactly match flagged_ids", {
  df  <- make_phys_df()
  ids <- c("001", "003", "005")
  res <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = ids, output_dir = NA)
  )
  expect_setequal(res$id_number, ids)
})

test_that("physicians_with_detail: vector of IDs not in data returns zero-row tibble", {
  df  <- make_phys_df()
  res <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = c("999", "888"),
                                       output_dir = NA)
  )
  expect_equal(nrow(res), 0L)
  expect_s3_class(res, "tbl_df")
})

test_that("physicians_with_detail: data frame as flagged_ids works", {
  df      <- make_phys_df()
  flagged <- data.frame(id_number = c("002", "004"), stringsAsFactors = FALSE)
  res <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = flagged,
                                       output_dir = NA)
  )
  expect_equal(nrow(res), 2L)
  expect_setequal(res$id_number, c("002", "004"))
})

test_that("physicians_with_detail: wrong id_col errors with 'not found'", {
  df <- make_phys_df()
  expect_error(
    mysterycall_physicians_with_detail(df, flagged_ids = "001",
                                       id_col = "bad_col",
                                       output_dir = NA),
    "missing"
  )
})

test_that("physicians_with_detail: id_col missing from flagged_ids df errors with 'not found'", {
  df      <- make_phys_df()
  flagged <- data.frame(wrong_col = "001", stringsAsFactors = FALSE)
  expect_error(
    mysterycall_physicians_with_detail(df, flagged_ids = flagged,
                                       output_dir = NA),
    "missing"
  )
})

test_that("physicians_with_detail: empty data frame returns zero rows", {
  df_empty <- data.frame(
    id_number                       = character(0),
    physician_information           = character(0),
    reason_for_exclusions           = character(0),
    insurance                       = character(0),
    business_days_until_appointment = numeric(0),
    stringsAsFactors                = FALSE
  )
  res <- suppressMessages(
    mysterycall_physicians_with_detail(df_empty, flagged_ids = "001",
                                       output_dir = NA)
  )
  expect_equal(nrow(res), 0L)
})

test_that("physicians_with_detail: single-row data works", {
  df <- data.frame(
    id_number             = "001",
    physician_information = "Dr A",
    reason_for_exclusions = "Able to contact",
    insurance             = "BCBS",
    business_days_until_appointment = 5L,
    stringsAsFactors = FALSE
  )
  res <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = "001",
                                       output_dir = NA)
  )
  expect_equal(nrow(res), 1L)
})

test_that("physicians_with_detail: select_cols that don't exist are silently dropped", {
  df  <- make_phys_df()
  res <- suppressMessages(
    mysterycall_physicians_with_detail(
      df,
      flagged_ids  = "001",
      select_cols  = c("id_number", "nonexistent_col", "insurance"),
      output_dir   = NA
    )
  )
  expect_false("nonexistent_col" %in% names(res))
  expect_true("insurance" %in% names(res))
})

test_that("physicians_with_detail: rows arranged ascending by id_col", {
  df  <- make_phys_df()
  res <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = c("005","001","003"),
                                       output_dir = NA)
  )
  expect_equal(res$id_number, sort(res$id_number))
})

test_that("physicians_with_detail: non-data-frame input raises error", {
  expect_error(
    mysterycall_physicians_with_detail(list(a = 1), flagged_ids = "001",
                                       output_dir = NA),
    "data.frame"
  )
})

test_that("physicians_with_detail: message reports correct counts", {
  df   <- make_phys_df()
  msgs <- capture.output(
    mysterycall_physicians_with_detail(df, flagged_ids = c("001", "002"),
                                       output_dir = NA),
    type = "message"
  )
  expect_true(any(grepl("Found 2 matching", msgs)))
})

test_that("physicians_with_detail: numeric IDs work via coercion", {
  df <- data.frame(
    id_number             = c(1L, 2L, 3L),
    physician_information = c("Dr A", "Dr B", "Dr C"),
    stringsAsFactors      = FALSE
  )
  res <- suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = c(1, 3),
                                       select_cols = c("id_number","physician_information"),
                                       output_dir = NA)
  )
  expect_equal(nrow(res), 2L)
})

test_that("physicians_with_detail: writes file when output_dir supplied", {
  df  <- make_phys_df()
  tmp <- tempfile()
  dir.create(tmp)
  suppressMessages(
    mysterycall_physicians_with_detail(df, flagged_ids = "001",
                                       output_dir = tmp)
  )
  expect_true(file.exists(file.path(tmp, "physicians_with_detail.csv")))
})
