# Tests for Preflight Check System
# Comprehensive tests for workflow validation and resource estimation

library(testthat)
library(mysterycall)

# ==============================================================================
# mysterycall_assess_data_quality()
# ==============================================================================

test_that("mysterycall_assess_data_quality calculates perfect score", {
  # Perfect data
  perfect_data <- data.frame(
    first = c("John", "Jane", "Bob"),
    last = c("Doe", "Smith", "Jones"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_assess_data_quality(perfect_data, required_columns = c("first", "last"))

  expect_equal(result$score, 1.0)
  expect_equal(length(result$issues), 0)
  expect_equal(result$penalties, 0)
})

test_that("mysterycall_assess_data_quality detects missing values", {
  # Data with high missing values
  data_with_na <- data.frame(
    first = c("John", NA, NA, NA, NA),
    last = c("Doe", "Smith", "Jones", "Brown", "Davis"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_assess_data_quality(data_with_na, required_columns = c("first", "last"))

  # Should have penalties for high NA rate (80%)
  expect_true(result$score < 1.0)
  expect_true(length(result$issues) > 0)
  expect_true(result$penalties > 0)

  # Check that issue was reported
  issue_messages <- vapply(result$issues, function(x) x$message, character(1))
  expect_true(any(grepl("missing values", issue_messages)))
})

test_that("mysterycall_assess_data_quality detects duplicates", {
  # Data with duplicates
  dup_data <- data.frame(
    first = c("John", "John", "John", "Jane"),
    last = c("Doe", "Doe", "Doe", "Smith"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_assess_data_quality(dup_data, required_columns = c("first", "last"))

  # Should detect duplicates (50% duplicate rate)
  expect_true(result$score < 1.0)
  expect_true(length(result$issues) > 0)

  issue_messages <- vapply(result$issues, function(x) x$message, character(1))
  expect_true(any(grepl("duplicate", issue_messages)))
})

test_that("mysterycall_assess_data_quality checks data types", {
  # Data with non-character columns
  bad_types <- data.frame(
    first = 1:5,  # Numeric instead of character
    last = c("Doe", "Smith", "Jones", "Brown", "Davis"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_assess_data_quality(bad_types, required_columns = c("first", "last"))

  expect_true(result$score < 1.0)
  issue_messages <- vapply(result$issues, function(x) x$message, character(1))
  expect_true(any(grepl("should be character", issue_messages)))
})

test_that("mysterycall_assess_data_quality handles multiple issues", {
  # Data with multiple problems
  messy_data <- data.frame(
    first = c("John", NA, "John", NA, 5),  # NAs + duplicates + wrong type
    last = c("Doe", "Doe", "Doe", "Smith", "Jones"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_assess_data_quality(messy_data, required_columns = c("first", "last"))

  # Should have multiple issues
  expect_true(length(result$issues) >= 2)
  expect_true(result$penalties > 1)
  expect_true(result$score <= 0.8)
})

test_that("mysterycall_assess_data_quality severity levels work", {
  # High missing rate (> 50%) should be error
  high_na_data <- data.frame(
    first = c(NA, NA, NA, NA, NA, "John"),
    last = c("Doe", "Smith", "Jones", "Brown", "Davis", "Wilson"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_assess_data_quality(high_na_data, required_columns = c("first", "last"))

  severities <- vapply(result$issues, function(x) x$severity, character(1))
  expect_true("error" %in% severities)
  expect_true(result$penalties >= 3)
})

# ==============================================================================
# mysterycall_estimate_resources()
# ==============================================================================

test_that("mysterycall_estimate_resources calculates runtime", {
  # Small dataset
  result_small <- mysterycall_estimate_resources(10)

  expect_true("runtime_seconds" %in% names(result_small))
  expect_true("runtime_hours" %in% names(result_small))
  expect_true("runtime_str" %in% names(result_small))

  expect_true(result_small$runtime_seconds > 0)
  expect_true(result_small$runtime_hours > 0)
})

test_that("mysterycall_estimate_resources calculates memory", {
  result <- mysterycall_estimate_resources(100)

  expect_true("memory_mb" %in% names(result))
  expect_true("memory_gb" %in% names(result))
  expect_true("memory_str" %in% names(result))

  expect_true(result$memory_mb > 0)
  expect_true(result$memory_gb > 0)
})

test_that("mysterycall_estimate_resources scales correctly", {
  result_10 <- mysterycall_estimate_resources(10)
  result_100 <- mysterycall_estimate_resources(100)

  # 10x rows = 10x runtime (linear scaling)
  expect_true(result_100$runtime_seconds > result_10$runtime_seconds * 8)
  # Memory has a fixed 500 MB base, so it scales sub-linearly for small row counts
  expect_true(result_100$memory_mb > result_10$memory_mb)
})

test_that("mysterycall_estimate_resources formats time strings", {
  # Short runtime (< 1 hour)
  result_short <- mysterycall_estimate_resources(10)
  expect_match(result_short$runtime_str, "minutes")

  # Long runtime (> 1 hour)
  result_long <- mysterycall_estimate_resources(1000)
  expect_match(result_long$runtime_str, "h")
})

test_that("mysterycall_estimate_resources formats memory strings", {
  # Small memory (< 1 GB)
  result_small <- mysterycall_estimate_resources(100)
  expect_match(result_small$memory_str, "MB")

  # Large memory (> 1 GB)
  result_large <- mysterycall_estimate_resources(1000)
  # May or may not be GB depending on estimates, just check format
  expect_true(grepl("MB|GB", result_large$memory_str))
})

test_that("mysterycall_estimate_resources handles edge cases", {
  # Zero rows
  result_zero <- mysterycall_estimate_resources(0)
  expect_equal(result_zero$runtime_seconds, 0)
  expect_true(result_zero$memory_mb > 0)  # Base memory

  # Very large dataset
  result_huge <- mysterycall_estimate_resources(100000)
  expect_true(result_huge$runtime_hours > 1)
  expect_true(result_huge$memory_gb > 1)
})

# ==============================================================================
# mysterycall_preflight_check() - Data Validation
# ==============================================================================

test_that("mysterycall_preflight_check validates data frame input", {
  test_data <- data.frame(
    first = c("John", "Jane"),
    last = c("Doe", "Smith"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  result <- mysterycall_preflight_check(
    input_data = test_data,
    output_dir = temp_dir,
    check_apis = FALSE,
    interactive = FALSE
  )

  expect_true(result$passed)
  expect_equal(result$n_rows, 2)
  expect_true(result$checks$data)

  unlink(temp_dir, recursive = TRUE)
})

test_that("mysterycall_preflight_check validates file input", {
  # Create temp file
  test_data <- data.frame(
    first = c("John", "Jane", "Bob"),
    last = c("Doe", "Smith", "Jones"),
    stringsAsFactors = FALSE
  )

  temp_file <- tempfile(fileext = ".csv")
  temp_dir <- tempfile()
  dir.create(temp_dir)

  write.csv(test_data, temp_file, row.names = FALSE)

  result <- mysterycall_preflight_check(
    input_data = temp_file,
    output_dir = temp_dir,
    check_apis = FALSE,
    interactive = FALSE
  )

  expect_true(result$passed)
  expect_equal(result$n_rows, 3)

  unlink(temp_file)
  unlink(temp_dir, recursive = TRUE)
})

test_that("mysterycall_preflight_check detects missing file", {
  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_error(
    mysterycall_preflight_check(
      input_data = "/path/to/nonexistent/file.csv",
      output_dir = temp_dir,
      check_apis = FALSE,
      interactive = FALSE
    ),
    "Preflight checks failed"
  )

  unlink(temp_dir, recursive = TRUE)
})

test_that("mysterycall_preflight_check detects missing columns", {
  # Data missing required columns
  bad_data <- data.frame(
    name = c("John Doe", "Jane Smith"),
    phone = c("555-1234", "555-5678"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_error(
    mysterycall_preflight_check(
      input_data = bad_data,
      output_dir = temp_dir,
      required_columns = c("first", "last"),
      check_apis = FALSE,
      interactive = FALSE
    ),
    "Preflight checks failed"
  )

  unlink(temp_dir, recursive = TRUE)
})

test_that("mysterycall_preflight_check handles invalid input type", {
  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_error(
    mysterycall_preflight_check(
      input_data = list(first = "John", last = "Doe"),
      output_dir = temp_dir,
      check_apis = FALSE,
      interactive = FALSE
    ),
    "Preflight checks failed"
  )

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# mysterycall_preflight_check() - Output Directory
# ==============================================================================

test_that("mysterycall_preflight_check creates output directory", {
  test_data <- data.frame(
    first = c("John"),
    last = c("Doe"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()

  result <- mysterycall_preflight_check(
    input_data = test_data,
    output_dir = temp_dir,
    check_apis = FALSE,
    interactive = FALSE
  )

  expect_true(dir.exists(temp_dir))
  expect_true(result$checks$output_dir)

  unlink(temp_dir, recursive = TRUE)
})

test_that("mysterycall_preflight_check validates existing directory is writable", {
  test_data <- data.frame(
    first = c("John"),
    last = c("Doe"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  result <- mysterycall_preflight_check(
    input_data = test_data,
    output_dir = temp_dir,
    check_apis = FALSE,
    interactive = FALSE
  )

  expect_true(result$checks$output_dir)

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# mysterycall_preflight_check() - Data Quality Integration
# ==============================================================================

test_that("mysterycall_preflight_check fails on poor data quality", {
  # Very poor quality data
  poor_data <- data.frame(
    first = c(NA, NA, NA, NA, NA),
    last = c(NA, NA, NA, NA, NA),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_error(
    mysterycall_preflight_check(
      input_data = poor_data,
      output_dir = temp_dir,
      check_apis = FALSE,
      interactive = FALSE
    ),
    "Preflight checks failed"
  )

  unlink(temp_dir, recursive = TRUE)
})

test_that("mysterycall_preflight_check warns on mediocre data quality", {
  # Mediocre quality (70-80%)
  mediocre_data <- data.frame(
    first = c("John", "Jane", NA, "Bob"),
    last = c("Doe", "Smith", "Jones", NA),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Should pass with warnings
  result <- mysterycall_preflight_check(
    input_data = mediocre_data,
    output_dir = temp_dir,
    check_apis = FALSE,
    interactive = FALSE
  )

  expect_true(result$passed)
  expect_true(length(result$warnings) > 0)

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# mysterycall_preflight_check() - Resource Estimation Integration
# ==============================================================================

test_that("mysterycall_preflight_check includes resource estimates", {
  test_data <- data.frame(
    first = rep("John", 100),
    last = rep("Doe", 100),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  result <- mysterycall_preflight_check(
    input_data = test_data,
    output_dir = temp_dir,
    check_apis = FALSE,
    estimate_resources = TRUE,
    interactive = FALSE
  )

  expect_true(!is.null(result$estimates))
  expect_true("runtime_str" %in% names(result$estimates))
  expect_true("memory_str" %in% names(result$estimates))

  unlink(temp_dir, recursive = TRUE)
})

test_that("mysterycall_preflight_check can skip resource estimation", {
  test_data <- data.frame(
    first = c("John"),
    last = c("Doe"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  result <- mysterycall_preflight_check(
    input_data = test_data,
    output_dir = temp_dir,
    check_apis = FALSE,
    estimate_resources = FALSE,
    interactive = FALSE
  )

  expect_true(is.null(result$estimates))

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# mysterycall_preflight_check() - API Keys
# ==============================================================================

test_that("mysterycall_preflight_check warns when API keys missing", {
  test_data <- data.frame(
    first = c("John"),
    last = c("Doe"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  result <- mysterycall_preflight_check(
    input_data = test_data,
    output_dir = temp_dir,
    google_maps_api_key = NULL,
    here_api_key = NULL,
    check_apis = FALSE,
    interactive = FALSE
  )

  # Should have warnings about missing API keys
  expect_true(length(result$warnings) >= 2)
  expect_true(any(grepl("Google", result$warnings)))
  expect_true(any(grepl("routing", result$warnings, ignore.case = TRUE)))

  unlink(temp_dir, recursive = TRUE)
})

test_that("mysterycall_preflight_check acknowledges provided API keys", {
  test_data <- data.frame(
    first = c("John"),
    last = c("Doe"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Provide dummy keys but skip actual testing
  result <- mysterycall_preflight_check(
    input_data = test_data,
    output_dir = temp_dir,
    google_maps_api_key = "dummy_google_key",
    here_api_key = "dummy_here_key",
    check_apis = FALSE,  # Skip actual API validation
    interactive = FALSE
  )

  expect_true(result$passed)

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# mysterycall_preflight_check() - Return Structure
# ==============================================================================

test_that("mysterycall_preflight_check returns expected structure", {
  test_data <- data.frame(
    first = c("John", "Jane"),
    last = c("Doe", "Smith"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  result <- mysterycall_preflight_check(
    input_data = test_data,
    output_dir = temp_dir,
    check_apis = FALSE,
    interactive = FALSE
  )

  # Check structure
  expect_true("passed" %in% names(result))
  expect_true("checks" %in% names(result))
  expect_true("errors" %in% names(result))
  expect_true("warnings" %in% names(result))
  expect_true("data" %in% names(result))
  expect_true("n_rows" %in% names(result))

  # Check types
  expect_type(result$passed, "logical")
  expect_type(result$checks, "list")
  expect_type(result$errors, "character")
  expect_type(result$warnings, "character")
  expect_true(is.data.frame(result$data))
  expect_type(result$n_rows, "integer")

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# Integration Tests
# ==============================================================================

test_that("Preflight check complete workflow", {
  # Create realistic test data
  test_data <- data.frame(
    first = c("John", "Jane", "Bob", "Alice", "Charlie"),
    last = c("Doe", "Smith", "Jones", "Williams", "Brown"),
    phone = c("555-1234", "555-5678", NA, "555-9012", "555-3456"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  result <- mysterycall_preflight_check(
    input_data = test_data,
    output_dir = temp_dir,
    google_maps_api_key = "dummy_key",
    here_api_key = "dummy_key",
    check_apis = FALSE,
    estimate_resources = TRUE,
    interactive = FALSE
  )

  # Should pass
  expect_true(result$passed)

  # Should have all checks
  expect_true(result$checks$data)
  expect_true(result$checks$output_dir)
  expect_true(result$checks$data_quality)
  expect_true(result$checks$resources)

  # Should return data
  expect_equal(nrow(result$data), 5)

  # Should have estimates
  expect_false(is.null(result$estimates))

  unlink(temp_dir, recursive = TRUE)
})

test_that("Preflight check handles edge cases", {
  # Single row
  single_row <- data.frame(
    first = "John",
    last = "Doe",
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  result <- mysterycall_preflight_check(
    input_data = single_row,
    output_dir = temp_dir,
    check_apis = FALSE,
    interactive = FALSE
  )

  expect_true(result$passed)
  expect_equal(result$n_rows, 1)

  unlink(temp_dir, recursive = TRUE)
})

test_that("Preflight check accumulates multiple errors", {
  # Data with multiple problems
  bad_data <- data.frame(
    wrong_col1 = c(NA, NA, NA),
    wrong_col2 = c(NA, NA, NA),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_preflight_check(
      input_data = bad_data,
      output_dir = "/invalid/path/that/cannot/be/created",
      required_columns = c("first", "last"),
      check_apis = FALSE,
      interactive = FALSE
    ),
    "Preflight checks failed"
  )
})

# ==============================================================================
# Performance Tests
# ==============================================================================

test_that("Preflight checks are performant", {
  # Large dataset
  large_data <- data.frame(
    first = rep(c("John", "Jane", "Bob"), 1000),
    last = rep(c("Doe", "Smith", "Jones"), 1000),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  start_time <- Sys.time()

  result <- mysterycall_preflight_check(
    input_data = large_data,
    output_dir = temp_dir,
    check_apis = FALSE,
    interactive = FALSE
  )

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # Should complete quickly (< 2 seconds for 3000 rows)
  expect_true(elapsed < 2.0)
  expect_true(result$passed)

  unlink(temp_dir, recursive = TRUE)
})

test_that("Resource estimation is fast", {
  start_time <- Sys.time()

  result <- mysterycall_estimate_resources(10000)

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # Should be nearly instantaneous
  expect_true(elapsed < 0.1)
  expect_true("runtime_str" %in% names(result))
})
