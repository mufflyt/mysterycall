# Tests for Sanity Check System
# Comprehensive tests for data validation and limit detection

library(testthat)

# ==============================================================================
# mysterycall:::mysterycall_check_no_limits()
# ==============================================================================

test_that("mysterycall_check_no_limits detects suspicious round numbers", {
  # Suspiciously round numbers should trigger warnings
  suspicious_data <- data.frame(x = 1:100)

  expect_warning(
    mysterycall:::mysterycall_check_no_limits(suspicious_data, "test_data"),
    "SUSPICIOUS"
  )
})

test_that("mysterycall_check_no_limits handles normal row counts", {
  # Non-round numbers should pass quietly
  normal_data <- data.frame(x = 1:97)

  expect_silent(
    mysterycall:::mysterycall_check_no_limits(normal_data, "normal_data")
  )
})

test_that("mysterycall_check_no_limits detects multiples of 1000", {
  # 1000 rows is in suspicious_counts and triggers a SUSPICIOUS warning
  thousand_data <- data.frame(x = 1:1000)

  expect_warning(
    mysterycall:::mysterycall_check_no_limits(thousand_data, "thousand_data"),
    "SUSPICIOUS"
  )
})

test_that("mysterycall_check_no_limits warns on zero rows", {
  # Zero rows indicates silent failure
  empty_data <- data.frame(x = numeric())

  expect_warning(
    mysterycall:::mysterycall_check_no_limits(empty_data, "empty_data"),
    "ZERO rows"
  )
})

test_that("mysterycall_check_no_limits validates input types", {
  # Should error on non-data frame
  expect_error(
    mysterycall:::mysterycall_check_no_limits(list(x = 1:10), "bad_input"),
    "must be a data frame"
  )
})

test_that("mysterycall_check_no_limits supports min/max expected", {
  test_data <- data.frame(x = 1:53)  # Use non-suspicious count

  # Below minimum
  expect_warning(
    mysterycall:::mysterycall_check_no_limits(test_data, "test", min_expected = 100),
    "expected at least 100"
  )

  # Above maximum
  expect_warning(
    mysterycall:::mysterycall_check_no_limits(test_data, "test", max_expected = 25),
    "expected at most 25"
  )

  # Within range
  expect_silent(
    mysterycall:::mysterycall_check_no_limits(test_data, "test", min_expected = 40, max_expected = 60)
  )
})

# ==============================================================================
# mysterycall:::mysterycall_scan_for_limits()
# ==============================================================================

test_that("mysterycall_scan_for_limits detects slice_head patterns", {
  # Create temporary directory and test file
  test_dir <- tempfile()
  dir.create(test_dir)
  test_file <- file.path(test_dir, "test_script.R")

  writeLines(c(
    "data <- read_csv('file.csv')",
    "limited <- data %>% slice_head(n = 100)",  # Pattern that will be detected
    "result <- process(limited)"
  ), test_file)

  result <- suppressWarnings(mysterycall:::mysterycall_scan_for_limits(test_dir, recursive = FALSE))

  expect_true(nrow(result) > 0)
  expect_true(any(grepl("slice_head", result$pattern)))

  unlink(test_dir, recursive = TRUE)
})

test_that("mysterycall_scan_for_limits ignores comments", {
  # Create temporary directory and test file with commented limit
  test_dir <- tempfile()
  dir.create(test_dir)
  test_file <- file.path(test_dir, "test_script.R")

  writeLines(c(
    "data <- read_csv('file.csv')",
    "# limited <- slice_head(data, n = 100)  # This is commented",
    "result <- process(data)"
  ), test_file)

  result <- mysterycall:::mysterycall_scan_for_limits(test_dir, recursive = FALSE)

  # Should not detect commented limits
  expect_equal(nrow(result), 0)

  unlink(test_dir, recursive = TRUE)
})

test_that("mysterycall_scan_for_limits handles clean code", {
  # Create temporary directory and test file without limits
  test_dir <- tempfile()
  dir.create(test_dir)
  test_file <- file.path(test_dir, "test_script.R")

  writeLines(c(
    "data <- read_csv('file.csv')",
    "result <- process_all(data)",  # No limits
    "write_csv(result, 'output.csv')"
  ), test_file)

  expect_message(
    mysterycall:::mysterycall_scan_for_limits(test_dir, recursive = FALSE),
    "No artificial data limits found"
  )

  unlink(test_dir, recursive = TRUE)
})

test_that("mysterycall_scan_for_limits detects multiple patterns", {
  # Create temporary directory and test file with multiple limits
  test_dir <- tempfile()
  dir.create(test_dir)
  test_file <- file.path(test_dir, "test_script.R")

  writeLines(c(
    "data1 <- read_csv('file.csv')",
    "data1_limited <- head(data1, 100)",
    "data2 <- sample_n(data1, 50)",
    "data3 <- read_csv('file2.csv', n_max = 1000)"
  ), test_file)

  result <- suppressWarnings(mysterycall:::mysterycall_scan_for_limits(test_dir, recursive = FALSE))

  expect_true(nrow(result) >= 3)  # Should find all three
  expect_true(any(grepl("head", result$pattern)))
  expect_true(any(grepl("sample_n", result$pattern)))
  expect_true(any(grepl("n_max", result$pattern)))

  unlink(test_dir, recursive = TRUE)
})

# ==============================================================================
# mysterycall:::mysterycall_check_api_response()
# ==============================================================================

test_that("mysterycall_check_api_response validates exact matches", {
  # Exact match should pass
  result <- data.frame(
    id = 1:100,
    value = rnorm(100)
  )

  expect_silent(
    mysterycall:::mysterycall_check_api_response(result, expected = 100, api_name = "Test API")
  )
})

test_that("mysterycall_check_api_response detects mismatches", {
  result <- data.frame(
    id = 1:75,
    value = rnorm(75)
  )

  expect_error(
    mysterycall:::mysterycall_check_api_response(result, expected = 100, api_name = "Test API"),
    "response count mismatch"
  )
})

test_that("mysterycall_check_api_response supports tolerance", {
  result <- data.frame(
    id = 1:95,
    value = rnorm(95)
  )

  # Within tolerance
  expect_message(
    mysterycall:::mysterycall_check_api_response(result, expected = 100, tolerance = 5),
    "95/100"
  )

  # Outside tolerance
  expect_error(
    mysterycall:::mysterycall_check_api_response(result, expected = 100, tolerance = 3)
  )
})

test_that("mysterycall_check_api_response validates data frame input", {
  # Non-data frame should error
  bad_result <- list(id = 1:100, value = rnorm(100))

  expect_error(
    mysterycall:::mysterycall_check_api_response(bad_result, expected = 100),
    "non-dataframe result"
  )
})

# ==============================================================================
# mysterycall:::mysterycall_check_no_data_loss()
# ==============================================================================

test_that("mysterycall_check_no_data_loss detects unexpected loss", {
  before <- data.frame(id = 1:100)
  after <- data.frame(id = 1:75)  # Lost 25 rows

  expect_error(
    mysterycall:::mysterycall_check_no_data_loss(before, after, "test operation"),
    "DATA LOSS detected"
  )
})

test_that("mysterycall_check_no_data_loss allows expected changes", {
  before <- data.frame(id = 1:100)
  after <- data.frame(id = 1:90)  # Expected to remove 10

  expect_silent(
    mysterycall:::mysterycall_check_no_data_loss(before, after, "deduplication",
                            expected_change = -10, tolerance = 0)
  )
})

test_that("mysterycall_check_no_data_loss warns on unexpected increases", {
  before <- data.frame(id = 1:100)
  after <- data.frame(id = 1:150)  # Unexpected increase

  expect_warning(
    mysterycall:::mysterycall_check_no_data_loss(before, after, "test operation"),
    "UNEXPECTED ROW INCREASE"
  )
})

test_that("mysterycall_check_no_data_loss handles row counts and data frames", {
  # Test with row counts (integers)
  expect_silent(
    mysterycall:::mysterycall_check_no_data_loss(100, 100, "no change")
  )

  # Test with data frames
  before_df <- data.frame(x = 1:100)
  after_df <- data.frame(x = 1:100)

  expect_silent(
    mysterycall:::mysterycall_check_no_data_loss(before_df, after_df, "no change")
  )
})

test_that("mysterycall_check_no_data_loss handles tolerance correctly", {
  before <- data.frame(id = 1:100)
  after <- data.frame(id = 1:95)  # Lost 5 rows

  # Within tolerance
  expect_silent(
    mysterycall:::mysterycall_check_no_data_loss(before, after, "operation",
                            expected_change = 0, tolerance = 5)
  )

  # Outside tolerance
  expect_error(
    mysterycall:::mysterycall_check_no_data_loss(before, after, "operation",
                            expected_change = 0, tolerance = 3)
  )
})

# ==============================================================================
# Integration Tests
# ==============================================================================

test_that("Sanity checks work together in workflow", {
  # Simulate a data pipeline with checks at each step
  set.seed(42)

  # Step 1: Load data
  data1 <- data.frame(id = 1:1000, value = rnorm(1000))
  suppressWarnings(mysterycall:::mysterycall_check_no_limits(data1, "initial load", min_expected = 500))

  # Step 2: Filter data (with seed 42: ~515 rows removed, allow wide tolerance)
  data2 <- data1[data1$value > 0, ]
  mysterycall:::mysterycall_check_no_data_loss(data1, data2, "filtering",
                          expected_change = -500, tolerance = 100)

  # Step 3: API call
  data3 <- data2[1:min(100, nrow(data2)), ]  # Simulate API result
  mysterycall:::mysterycall_check_api_response(data3, expected = 100, tolerance = 10)

  # All checks should pass
  expect_true(TRUE)
})

test_that("Sanity checks handle edge cases", {
  # Empty data frames
  empty_df <- data.frame()
  expect_warning(
    mysterycall:::mysterycall_check_no_limits(empty_df, "empty"),
    "ZERO rows"
  )

  # Very large data frames
  large_df <- data.frame(id = 1:1000000)
  expect_silent(
    mysterycall:::mysterycall_check_no_limits(large_df, "large")
  )

  # Single row
  single_df <- data.frame(id = 1)
  expect_silent(
    mysterycall:::mysterycall_check_no_limits(single_df, "single")
  )
})

test_that("Sanity checks provide actionable messages", {
  # Test that error messages are helpful
  test_data <- data.frame(id = 1:100)

  expect_error(
    mysterycall:::mysterycall_check_api_response(test_data, expected = 200),
    "Expected: 200"
  )

  expect_error(
    mysterycall:::mysterycall_check_api_response(test_data, expected = 200),
    "Actual: 100"
  )
})

# ==============================================================================
# Performance Tests
# ==============================================================================

test_that("Sanity checks are performant", {
  # Large data frame
  large_data <- data.frame(
    id = 1:100000,
    value = rnorm(100000)
  )

  # Should complete quickly (< 1 second)
  start_time <- Sys.time()
  suppressWarnings(mysterycall:::mysterycall_check_no_limits(large_data, "performance_test"))
  end_time <- Sys.time()

  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
  expect_true(elapsed < 1.0)
})

test_that("File scanning is reasonable", {
  # Create temporary directory with multiple files
  test_dir <- tempfile()
  dir.create(test_dir)

  for (i in 1:10) {
    test_file <- file.path(test_dir, sprintf("test%d.R", i))
    writeLines(c(
      "data <- read_csv('file.csv')",
      "result <- process(data)"
    ), test_file)
  }

  # Should complete quickly
  start_time <- Sys.time()
  mysterycall:::mysterycall_scan_for_limits(test_dir)
  end_time <- Sys.time()

  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
  expect_true(elapsed < 2.0)

  unlink(test_dir, recursive = TRUE)
})
