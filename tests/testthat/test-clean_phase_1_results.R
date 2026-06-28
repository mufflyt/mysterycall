library(testthat)
testthat::skip_if_not_installed("dplyr")
testthat::skip_if_not_installed("janitor")
testthat::skip_if_not_installed("readr")
testthat::skip_if_not_installed("stringr")
testthat::skip_if_not_installed("humaniformat")
suppressWarnings(library(dplyr))
suppressWarnings(library(janitor))
suppressWarnings(library(readr))
suppressWarnings(library(stringr))
suppressWarnings(library(humaniformat))

test_that("mysterycall_clean_phase1 handles empty data frames correctly", {
  df_empty <- data.frame()
  expect_error(mysterycall_clean_phase1(df_empty, verbose = TRUE), "must contain at least one row")
})

test_that("mysterycall_clean_phase1 stops if required columns are missing", {
  df_missing_cols <- data.frame(names = c("John Doe", "Jane Doe"), stringsAsFactors = FALSE)
  expect_error(mysterycall_clean_phase1(df_missing_cols), "Required columns are missing")
})

test_that("mysterycall_clean_phase1 processes data correctly", {
  df_normal <- data.frame(
    names = c("John Doe", "Jane Doe"),
    practice_name = c("Univ Hospital", "Private Clinic"),
    phone_number = c("1234567890", "0987654321"),
    state_name = c("TX", "CA"),
    npi = c(123456, 654321),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_clean_phase1(df_normal)

  expect_equal(nrow(result), nrow(df_normal) * 2)
  expect_true(all(c("id", "for_redcap") %in% names(result)))
})

test_that("mysterycall_clean_phase1 adds insurance correctly", {
  df_with_insurance <- data.frame(
    names = c("John Doe", "Jane Doe"),
    practice_name = c("Univ Hospital", "Private Clinic"),
    phone_number = c("1234567890", "0987654321"),
    state_name = c("TX", "CA"),
    npi = c(123456, 654321),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_clean_phase1(df_with_insurance, duplicate_rows = FALSE, verbose = FALSE)
  expect_setequal(result$insurance, c("Blue Cross/Blue Shield", "Medicaid"))
})

test_that("mysterycall_clean_phase1 removes duplicates correctly", {
  df_dups <- data.frame(
    names = c("John Doe", "Jane Doe", "John Doe"),
    practice_name = c("Univ Hospital", "Private Clinic", "Univ Hospital"),
    phone_number = c("1234567890", "0987654321", "1234567890"),
    state_name = c("TX", "CA", "TX"),
    npi = c(123456, 654321, 123456),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_clean_phase1(df_dups, duplicate_rows = FALSE, verbose = FALSE)
  expect_equal(nrow(result), nrow(df_dups))
})

test_that("mysterycall_clean_phase1 random IDs are reproducible with a seed", {
  df_seed <- data.frame(
    names = "John Doe",
    practice_name = "Univ Hospital",
    phone_number = "1234567890",
    state_name = "TX",
    npi = NA,
    stringsAsFactors = FALSE
  )

  result_1 <- mysterycall_clean_phase1(df_seed, duplicate_rows = FALSE, verbose = FALSE, id_seed = 42)
  result_2 <- mysterycall_clean_phase1(df_seed, duplicate_rows = FALSE, verbose = FALSE, id_seed = 42)

  expect_equal(result_1$random_id, result_2$random_id)
})
