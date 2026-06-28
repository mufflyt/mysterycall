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


# =============================================================================
# mysterycall_check_no_limits tests
# =============================================================================

test_that("mysterycall_check_no_limits passes with normal data", {
  result <- suppressWarnings(
    mysterycall_check_no_limits(AUDIT, context = "test_data")
  )
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_no_limits warns on suspicious counts (100)", {
  df_100 <- data.frame(x = 1:100)
  expect_warning(
    mysterycall_check_no_limits(df_100, context = "test"),
    "exactly 100 rows"
  )
})

test_that("mysterycall_check_no_limits warns on 1200 (NPI API cap)", {
  df_1200 <- data.frame(x = 1:1200)
  expect_warning(
    mysterycall_check_no_limits(df_1200, context = "npi_results"),
    "NPI registry API hard cap"
  )
})

test_that("mysterycall_check_no_limits warns on min_expected violation", {
  expect_warning(
    mysterycall_check_no_limits(AUDIT, context = "test", min_expected = 100),
    "only 4 rows but expected at least 100"
  )
})

test_that("mysterycall_check_no_limits warns on max_expected violation", {
  expect_warning(
    mysterycall_check_no_limits(AUDIT, context = "test", max_expected = 2),
    "4 rows but expected at most 2"
  )
})

test_that("mysterycall_check_no_limits warns on zero rows", {
  df_empty <- AUDIT[0, ]
  expect_warning(
    mysterycall_check_no_limits(df_empty, context = "empty"),
    "ZERO rows"
  )
})

test_that("mysterycall_check_no_limits messages on 1000x multiple", {
  df_2000 <- data.frame(x = 1:2000)
  expect_message(
    mysterycall_check_no_limits(df_2000, context = "test"),
    "exact multiple of 1000"
  )
})

test_that("mysterycall_check_no_limits errors on non-dataframe input", {
  expect_error(
    mysterycall_check_no_limits(list(x = 1), context = "bad"),
    "must be a data frame"
  )
})

test_that("mysterycall_check_no_limits errors on vector input", {
  expect_error(
    mysterycall_check_no_limits(c(1, 2, 3)),
    "must be a data frame"
  )
})

test_that("mysterycall_check_no_limits errors on matrix input", {
  expect_error(
    mysterycall_check_no_limits(matrix(1:4, nrow = 2)),
    "must be a data frame"
  )
})


# =============================================================================
# mysterycall_check_api_response tests
# =============================================================================

test_that("mysterycall_check_api_response passes with exact count match", {
  result <- suppressMessages(
    mysterycall_check_api_response(AUDIT, expected = 4, api_name = "Test API")
  )
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_api_response messages on partial success within tolerance", {
  expect_message(
    mysterycall_check_api_response(AUDIT, expected = 5, api_name = "Test API", tolerance = 1),
    "4/5 rows returned"
  )
})

test_that("mysterycall_check_api_response errors on mismatch without tolerance", {
  expect_error(
    mysterycall_check_api_response(AUDIT, expected = 10, api_name = "Test API"),
    "response count mismatch"
  )
})

test_that("mysterycall_check_api_response errors on large difference even with tolerance", {
  df_small <- AUDIT[1:2, ]
  expect_error(
    mysterycall_check_api_response(df_small, expected = 10, api_name = "Test API", tolerance = 1),
    "response count mismatch"
  )
})

test_that("mysterycall_check_api_response errors on non-dataframe result", {
  expect_error(
    mysterycall_check_api_response(list(x = 1), expected = 1, api_name = "Test API"),
    "non-dataframe result"
  )
})

test_that("mysterycall_check_api_response errors on empty result when expecting data", {
  df_empty <- AUDIT[0, ]
  expect_error(
    mysterycall_check_api_response(df_empty, expected = 4, api_name = "API"),
    "response count mismatch"
  )
})

test_that("mysterycall_check_api_response handles zero expected with tolerance", {
  df_empty <- AUDIT[0, ]
  result <- suppressMessages(
    mysterycall_check_api_response(df_empty, expected = 0, api_name = "API", tolerance = 0)
  )
  expect_true(isTRUE(result))
})


# =============================================================================
# mysterycall_check_no_data_loss tests
# =============================================================================

test_that("mysterycall_check_no_data_loss passes with no change (numeric)", {
  result <- mysterycall_check_no_data_loss(4, 4, "test operation")
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_no_data_loss accepts dataframes as input", {
  result <- mysterycall_check_no_data_loss(AUDIT, AUDIT, "copy operation")
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_no_data_loss errors on data loss", {
  expect_error(
    mysterycall_check_no_data_loss(10, 5, "bad operation"),
    "DATA LOSS detected"
  )
})

test_that("mysterycall_check_no_data_loss accepts expected_change parameter", {
  result <- mysterycall_check_no_data_loss(4, 6, "join operation", expected_change = 2)
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_no_data_loss warns on unexpected row increase", {
  expect_warning(
    mysterycall_check_no_data_loss(4, 8, "bad join", expected_change = 0),
    "UNEXPECTED ROW INCREASE"
  )
})

test_that("mysterycall_check_no_data_loss respects tolerance parameter", {
  result <- mysterycall_check_no_data_loss(10, 9, "operation", expected_change = 0, tolerance = 1)
  expect_true(isTRUE(result))
})

test_that("mysterycall_check_no_data_loss errors when loss exceeds tolerance", {
  expect_error(
    mysterycall_check_no_data_loss(10, 5, "operation", expected_change = 0, tolerance = 3),
    "DATA LOSS detected"
  )
})

test_that("mysterycall_check_no_data_loss handles zero row cases", {
  result <- mysterycall_check_no_data_loss(0, 0, "empty operation")
  expect_true(isTRUE(result))
})


# =============================================================================
# mysterycall_scan_for_limits tests
# =============================================================================

test_that("mysterycall_scan_for_limits errors on nonexistent directory", {
  expect_error(
    mysterycall_scan_for_limits("/nonexistent/path/xyz123"),
    "does not exist"
  )
})

test_that("mysterycall_scan_for_limits returns dataframe with correct structure", {
  tmpdir <- tempdir()
  test_file <- file.path(tmpdir, paste0("test_clean_", Sys.time(), ".R"))
  writeLines("# Just comments\nx <- 1", test_file)

  result <- suppressMessages(
    suppressWarnings(
      mysterycall_scan_for_limits(tmpdir, recursive = FALSE)
    )
  )

  expect_s3_class(result, "data.frame")
  expect_equal(ncol(result), 5)
  expect_equal(names(result), c("file", "line", "severity", "pattern", "code"))
  expect_true(is.character(result$file))
  expect_true(is.integer(result$line))
  expect_true(is.character(result$severity))
  expect_true(is.character(result$pattern))
  expect_true(is.character(result$code))

  unlink(test_file)
})

test_that("mysterycall_scan_for_limits detects head() anti-pattern", {
  tmpdir <- tempdir()
  test_file <- file.path(tmpdir, paste0("test_head_", Sys.time(), ".R"))
  writeLines("result <- head(data, 100)", test_file)

  result <- suppressWarnings(
    suppressMessages(
      mysterycall_scan_for_limits(tmpdir, recursive = FALSE)
    )
  )

  expect_true(nrow(result) > 0)
  expect_true(any(grepl("head", result$pattern, ignore.case = TRUE)))

  unlink(test_file)
})

test_that("mysterycall_scan_for_limits detects slice_head() anti-pattern", {
  tmpdir <- tempdir()
  test_file <- file.path(tmpdir, paste0("test_slice_", Sys.time(), ".R"))
  writeLines("df <- slice_head(n = 50)", test_file)

  result <- suppressWarnings(
    suppressMessages(
      mysterycall_scan_for_limits(tmpdir, recursive = FALSE)
    )
  )

  expect_true(nrow(result) > 0)
  expect_true(any(grepl("slice_head", result$pattern)))

  unlink(test_file)
})

test_that("mysterycall_scan_for_limits respects exclude_pattern", {
  tmpdir <- tempdir()
  test_file <- file.path(tmpdir, paste0("test_exclude_", Sys.time(), ".R"))
  writeLines("x <- head(data, 100)", test_file)

  result <- suppressMessages(
    mysterycall_scan_for_limits(tmpdir, recursive = FALSE, exclude_pattern = "exclude")
  )

  expect_equal(nrow(result), 0)

  unlink(test_file)
})

test_that("mysterycall_scan_for_limits detects n_max anti-pattern", {
  tmpdir <- tempdir()
  test_file <- file.path(tmpdir, paste0("test_nmax_", Sys.time(), ".R"))
  writeLines("data <- read.csv('file.csv', n_max = 1000)", test_file)

  result <- suppressWarnings(
    suppressMessages(
      mysterycall_scan_for_limits(tmpdir, recursive = FALSE)
    )
  )

  expect_true(nrow(result) > 0)
  expect_true(any(grepl("n_max", result$pattern)))

  unlink(test_file)
})

test_that("mysterycall_scan_for_limits assigns correct severity levels", {
  tmpdir <- tempdir()
  test_file <- file.path(tmpdir, paste0("test_severity_", Sys.time(), ".R"))
  writeLines("x <- head(data, 100)", test_file)

  result <- suppressWarnings(
    suppressMessages(
      mysterycall_scan_for_limits(tmpdir, recursive = FALSE)
    )
  )

  expect_true(nrow(result) > 0)
  expect_true(all(result$severity %in% c("CRITICAL", "HIGH", "MEDIUM", "LOW")))

  unlink(test_file)
})
