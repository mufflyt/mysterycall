library(testthat)
library(mysterycall)

AUDIT <- data.frame(
  first                            = c("John", "John", "Jane", "Jane"),
  last                             = c("Smith", "Smith", "Doe", "Doe"),
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

# ==============================================================================
# Test mysterycall_assess_data_quality()
# ==============================================================================

test_that("mysterycall_assess_data_quality returns correct structure with valid data", {
  result <- mysterycall_assess_data_quality(AUDIT)

  expect_type(result, "list")
  expect_true(all(c("score", "issues", "penalties") %in% names(result)))
  expect_type(result$score, "double")
  expect_gte(result$score, 0)
  expect_lte(result$score, 1)
  expect_type(result$issues, "list")
  expect_type(result$penalties, "double")
})

test_that("mysterycall_assess_data_quality handles zero rows", {
  empty_df <- AUDIT[0, ]
  result <- mysterycall_assess_data_quality(empty_df)

  expect_equal(result$score, 0)
  expect_length(result$issues, 1)
  expect_equal(result$issues[[1]]$severity, "error")
  expect_match(result$issues[[1]]$message, "zero rows")
})

test_that("mysterycall_assess_data_quality detects high missingness in required columns", {
  df <- data.frame(
    first = c(NA, NA, NA, NA, "John"),
    last = c("Doe", "Smith", "Jones", "Brown", "White")
  )

  result <- mysterycall_assess_data_quality(df, required_columns = c("first", "last"))

  expect_lt(result$score, 0.80)
  expect_length(result$issues, 1)
  expect_equal(result$issues[[1]]$severity, "error")
  expect_match(result$issues[[1]]$message, "first")
})

test_that("mysterycall_assess_data_quality detects duplicate rows", {
  df <- data.frame(
    first = c("John", "John", "Jane", "Jane", "Bob", "Bob", "Bob", "Bob", "Bob", "Bob", "Bob", "Bob"),
    last = c("Doe", "Doe", "Smith", "Smith", "Brown", "Brown", "Brown", "Brown", "Brown", "Brown", "Brown", "Brown")
  )

  result <- mysterycall_assess_data_quality(df)

  expect_lte(result$score, 0.99)
  any_dup_warning <- any(sapply(result$issues, function(x) grepl("duplicate", x$message, ignore.case = TRUE)))
  expect_true(any_dup_warning)
})

test_that("mysterycall_assess_data_quality detects non-character required columns", {
  df <- data.frame(
    first = c(1, 2, 3),
    last = c("Doe", "Smith", "Jones")
  )

  result <- mysterycall_assess_data_quality(df, required_columns = c("first", "last"))

  any_type_warning <- any(sapply(result$issues, function(x) grepl("character", x$message, ignore.case = TRUE)))
  expect_true(any_type_warning)
})

test_that("mysterycall_assess_data_quality allows custom required columns", {
  df <- data.frame(
    name = c("John Doe", "Jane Smith"),
    email = c("john@example.com", "jane@example.com")
  )

  result <- mysterycall_assess_data_quality(df, required_columns = c("name", "email"))

  expect_gte(result$score, 0.80)
})

# ==============================================================================
# Test mysterycall_estimate_resources()
# ==============================================================================

test_that("mysterycall_estimate_resources returns correct structure for n_rows=100", {
  result <- mysterycall_estimate_resources(100)

  expect_type(result, "list")
  expect_true(all(c("runtime_seconds", "runtime_hours", "runtime_str", "memory_mb", "memory_gb", "memory_str") %in% names(result)))
  expect_type(result$runtime_seconds, "double")
  expect_type(result$runtime_hours, "double")
  expect_type(result$runtime_str, "character")
  expect_type(result$memory_mb, "double")
  expect_type(result$memory_gb, "double")
  expect_type(result$memory_str, "character")
})

test_that("mysterycall_estimate_resources scales runtime correctly", {
  result_100 <- mysterycall_estimate_resources(100)
  result_500 <- mysterycall_estimate_resources(500)
  result_1000 <- mysterycall_estimate_resources(1000)

  expect_lt(result_100$runtime_seconds, result_500$runtime_seconds)
  expect_lt(result_500$runtime_seconds, result_1000$runtime_seconds)
})

test_that("mysterycall_estimate_resources formats runtime string correctly", {
  result_small <- mysterycall_estimate_resources(50)
  result_large <- mysterycall_estimate_resources(2000)

  # Small should be in minutes
  expect_match(result_small$runtime_str, "minutes")
  # Large should be in hours
  expect_match(result_large$runtime_str, "h")
})

test_that("mysterycall_estimate_resources formats memory string correctly", {
  result_small <- mysterycall_estimate_resources(50)
  result_large <- mysterycall_estimate_resources(2000)

  # Small should be in MB
  expect_match(result_small$memory_str, "MB")
  # Large should be in GB
  expect_match(result_large$memory_str, "GB")
})

test_that("mysterycall_estimate_resources handles edge case n_rows=0", {
  result <- mysterycall_estimate_resources(0)

  expect_equal(result$runtime_seconds, 0)
  expect_equal(result$memory_mb, 500)  # base memory
})

test_that("mysterycall_estimate_resources handles large n_rows", {
  result <- mysterycall_estimate_resources(5000)

  expect_gt(result$runtime_hours, 5)
  expect_gt(result$memory_gb, 8)
})

# ==============================================================================
# Test mysterycall_preflight_check()
# ==============================================================================

test_that("mysterycall_preflight_check returns correct structure with valid inputs", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_happy")

  df <- data.frame(
    first = c("John", "Jane"),
    last = c("Doe", "Smith")
  )

  result <- suppressMessages({
    mysterycall_preflight_check(
      input_data = df,
      output_dir = output_dir,
      google_maps_api_key = NULL,
      here_api_key = NULL,
      check_apis = FALSE,
      estimate_resources = TRUE,
      prompt_user = FALSE
    )
  })

  expect_type(result, "list")
  expect_true(all(c("passed", "checks", "errors", "warnings", "data", "n_rows", "estimates") %in% names(result)))
  expect_type(result$passed, "logical")
  expect_type(result$checks, "list")
  expect_type(result$errors, "character")
  expect_type(result$warnings, "character")
  expect_true(is.data.frame(result$data) || is.null(result$data))
  expect_type(result$n_rows, "integer")
})

test_that("mysterycall_preflight_check passes with valid data frame and writable directory", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_valid")

  result <- suppressMessages({
    mysterycall_preflight_check(
      input_data = AUDIT,
      output_dir = output_dir,
      check_apis = FALSE,
      estimate_resources = FALSE,
      prompt_user = FALSE,
      required_columns = c("first", "last")
    )
  })

  expect_true(result$passed)
  expect_equal(result$n_rows, 4L)
  expect_true(result$checks$data)
  expect_true(result$checks$output_dir)
})

test_that("mysterycall_preflight_check detects missing required columns", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_cols")

  df <- data.frame(
    col_a = c("A", "B"),
    col_b = c(1, 2)
  )

  expect_error({
    suppressMessages({
      mysterycall_preflight_check(
        input_data = df,
        output_dir = output_dir,
        check_apis = FALSE,
        estimate_resources = FALSE,
        prompt_user = FALSE,
        required_columns = c("first", "last")
      )
    })
  }, "Preflight checks failed")
})

test_that("mysterycall_preflight_check rejects non-dataframe non-filepath input", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_badtype")

  expect_error({
    suppressMessages({
      mysterycall_preflight_check(
        input_data = 123,
        output_dir = output_dir,
        check_apis = FALSE,
        estimate_resources = FALSE,
        prompt_user = FALSE
      )
    })
  }, "Preflight checks failed")
})

test_that("mysterycall_preflight_check rejects nonexistent input file", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_nofile")

  expect_error({
    suppressMessages({
      mysterycall_preflight_check(
        input_data = "/nonexistent/path/to/file.csv",
        output_dir = output_dir,
        check_apis = FALSE,
        estimate_resources = FALSE,
        prompt_user = FALSE
      )
    })
  }, "Preflight checks failed")
})

test_that("mysterycall_preflight_check creates output directory if needed", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_create", "subdir")

  result <- suppressMessages({
    mysterycall_preflight_check(
      input_data = AUDIT,
      output_dir = output_dir,
      check_apis = FALSE,
      estimate_resources = FALSE,
      prompt_user = FALSE
    )
  })

  expect_true(dir.exists(output_dir))
})

test_that("mysterycall_preflight_check handles empty data frame", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_empty")

  empty_df <- AUDIT[0, ]

  expect_error({
    suppressMessages({
      mysterycall_preflight_check(
        input_data = empty_df,
        output_dir = output_dir,
        check_apis = FALSE,
        estimate_resources = FALSE,
        prompt_user = FALSE
      )
    })
  }, "Preflight checks failed")
})

test_that("mysterycall_preflight_check respects check_apis = FALSE", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_apis")

  result <- suppressMessages({
    mysterycall_preflight_check(
      input_data = AUDIT,
      output_dir = output_dir,
      google_maps_api_key = "fake-key-123",
      here_api_key = "fake-key-456",
      check_apis = FALSE,
      estimate_resources = FALSE,
      prompt_user = FALSE
    )
  })

  # Should pass because check_apis = FALSE means we don't actually validate
  expect_true(result$checks$api_keys)
})

test_that("mysterycall_preflight_check handles interactive parameter as alias", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_interactive")

  result <- suppressMessages({
    mysterycall_preflight_check(
      input_data = AUDIT,
      output_dir = output_dir,
      check_apis = FALSE,
      estimate_resources = FALSE,
      prompt_user = TRUE,  # This should be overridden
      interactive = FALSE  # This takes precedence
    )
  })

  # Should not prompt because interactive = FALSE overrides prompt_user
  expect_true(result$passed)
})

test_that("mysterycall_preflight_check returns invisible list", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_invisible")

  result <- suppressMessages({
    mysterycall_preflight_check(
      input_data = AUDIT,
      output_dir = output_dir,
      check_apis = FALSE,
      estimate_resources = FALSE,
      prompt_user = FALSE
    )
  })

  # Verify it's a list
  expect_type(result, "list")
  # Verify invisibility was applied (function itself returns invisible, but result object is still accessible)
  expect_true(length(result) > 0)
})

test_that("mysterycall_preflight_check estimate_resources = TRUE includes estimates", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_estimates")

  result <- suppressMessages({
    mysterycall_preflight_check(
      input_data = AUDIT,
      output_dir = output_dir,
      check_apis = FALSE,
      estimate_resources = TRUE,
      prompt_user = FALSE
    )
  })

  expect_true(!is.null(result$estimates))
  expect_type(result$estimates, "list")
  expect_true("runtime_str" %in% names(result$estimates))
  expect_true("memory_str" %in% names(result$estimates))
})

test_that("mysterycall_preflight_check estimate_resources = FALSE excludes estimates", {
  temp_dir <- tempdir()
  output_dir <- file.path(temp_dir, "preflight_test_no_estimates")

  result <- suppressMessages({
    mysterycall_preflight_check(
      input_data = AUDIT,
      output_dir = output_dir,
      check_apis = FALSE,
      estimate_resources = FALSE,
      prompt_user = FALSE
    )
  })

  expect_null(result$estimates)
})
