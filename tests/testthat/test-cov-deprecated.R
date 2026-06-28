library(testthat)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)

test_that("format_pct() emits deprecation warning and forwards", {
  expect_warning(
    mysterycall:::format_pct(0.5),
    "format_pct.*deprecated.*mysterycall_format_pct"
  )
  result <- suppressWarnings(mysterycall:::format_pct(0.5))
  expect_true(is.character(result))
})

test_that("check_normality() emits deprecation warning and forwards", {
  expect_warning(
    mysterycall:::check_normality(data = COUNT_DF, variable = "days"),
    "check_normality.*deprecated.*mysterycall_check_normality"
  )
})

test_that("remove_constant_vars() emits deprecation warning and forwards", {
  test_df <- data.frame(x = c(1, 1, 1), y = c(1, 2, 3), stringsAsFactors = FALSE)
  expect_warning(
    mysterycall:::remove_constant_vars(test_df),
    "remove_constant_vars.*deprecated.*mysterycall_remove_constants"
  )
  result <- suppressWarnings(mysterycall:::remove_constant_vars(test_df))
  expect_true(is.data.frame(result))
})

test_that("search_npi() accepts data.frame with first and last columns", {
  npi_data <- data.frame(
    first = c("John", "Jane"),
    last = c("Smith", "Doe"),
    stringsAsFactors = FALSE
  )
  expect_warning(
    suppressMessages(mysterycall:::search_npi(npi_data)),
    "search_npi.*deprecated.*mysterycall_search_and_process_npi"
  )
})

test_that("search_npi() validates required first and last columns", {
  bad_data <- data.frame(x = c(1, 2), y = c(3, 4), stringsAsFactors = FALSE)
  expect_error(
    suppressWarnings(suppressMessages(mysterycall:::search_npi(bad_data))),
    "must contain columns"
  )
})

test_that("search_npi() rejects non-data.frame non-path input", {
  expect_error(
    suppressWarnings(suppressMessages(mysterycall:::search_npi(123))),
    "must be a data frame or a file path"
  )
})

test_that("search_npi() rejects character vector of length > 1", {
  expect_error(
    suppressWarnings(suppressMessages(mysterycall:::search_npi(c("path1.csv", "path2.csv")))),
    "must be a data frame or a file path"
  )
})

test_that("test_and_process_isochrones() throws removed error", {
  expect_error(
    mysterycall:::test_and_process_isochrones("dummy_file.csv"),
    "removed"
  )
})

test_that("process_and_save_isochrones() throws removed error", {
  expect_error(
    mysterycall:::process_and_save_isochrones("dummy_file.csv"),
    "removed"
  )
})

test_that("process_and_save_isochrones() chunk_size parameter included in signature", {
  expect_error(
    mysterycall:::process_and_save_isochrones("dummy_file.csv", chunk_size = 50),
    "removed"
  )
})

test_that("rename_columns_by_substring() emits deprecation warning", {
  test_df <- data.frame(old_name_1 = c(1, 2), old_name_2 = c(3, 4), stringsAsFactors = FALSE)
  expect_warning(
    suppressMessages(mysterycall:::rename_columns_by_substring(test_df, "old_", "new_")),
    "rename_columns_by_substring.*deprecated.*mysterycall_rename_columns"
  )
})

test_that("tyler_format_pct() emits deprecation warning (tyler prefix)", {
  expect_warning(
    mysterycall:::tyler_format_pct(0.5),
    "tyler_format_pct.*deprecated.*mysterycall_format_pct"
  )
})

test_that("tyler_check_normality() emits deprecation warning (tyler prefix)", {
  expect_warning(
    mysterycall:::tyler_check_normality(data = COUNT_DF, variable = "days"),
    "tyler_check_normality.*deprecated.*mysterycall_check_normality"
  )
})

test_that("tyler_remove_constants() emits deprecation warning", {
  test_df <- data.frame(x = c(1, 1, 1), y = c(1, 2, 3), stringsAsFactors = FALSE)
  expect_warning(
    mysterycall:::tyler_remove_constants(test_df),
    "tyler_remove_constants.*deprecated.*mysterycall_remove_constants"
  )
})

test_that("tyler_rename_columns() emits deprecation warning", {
  test_df <- data.frame(old_name_1 = c(1, 2), old_name_2 = c(3, 4), stringsAsFactors = FALSE)
  expect_warning(
    suppressMessages(mysterycall:::tyler_rename_columns(test_df, "old_", "new_")),
    "tyler_rename_columns.*deprecated.*mysterycall_rename_columns"
  )
})

