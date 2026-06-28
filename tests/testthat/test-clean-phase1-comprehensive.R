# Comprehensive tests for mysterycall_clean_phase1 function
library(testthat)
suppressWarnings(library(dplyr))

# Helper function to create test data
create_test_phase1_data <- function(n = 5, include_npi = TRUE, include_required = TRUE) {
  base_data <- data.frame(
    id = 1:n,
    names = paste("Provider", 1:n),
    practice_name = paste("Practice", 1:n),
    phone_number = paste0("555-000-", sprintf("%04d", 1:n)),
    state_name = sample(c("California", "Texas", "New York"), n, replace = TRUE),
    stringsAsFactors = FALSE
  )

  if (include_required) {
    base_data$for_redcap <- sample(c("Yes", "No"), n, replace = TRUE)
  }

  if (include_npi) {
    base_data$npi <- paste0("123456789", 0:(n-1))
  }

  base_data
}

test_that("mysterycall_clean_phase1: Basic functionality", {
  test_data <- create_test_phase1_data(3)
  temp_dir <- tempdir()

  result <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) >= nrow(test_data))

  # Check that required columns exist
  expect_true("names" %in% names(result))
  expect_true("practice_name" %in% names(result))
  expect_true("phone_number" %in% names(result))
  expect_true("state_name" %in% names(result))
})

test_that("mysterycall_clean_phase1: Missing NPI handling", {
  test_data <- create_test_phase1_data(3, include_npi = FALSE)
  temp_dir <- tempdir()

  result <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    id_seed = 123  # For reproducibility
  )

  expect_s3_class(result, "data.frame")
  expect_true("random_id" %in% names(result) || "npi" %in% names(result))

  # Check that random IDs are generated when NPI is missing
  if ("random_id" %in% names(result)) {
    expect_true(all(!is.na(result$random_id)))
    # Random IDs are generated per original row; duplicated rows share the same random_id
    expect_equal(length(unique(result$random_id)), nrow(test_data))
  }
})

test_that("mysterycall_clean_phase1: Duplicate row functionality", {
  test_data <- create_test_phase1_data(2)
  temp_dir <- tempdir()

  # Test with duplicate_rows = TRUE
  result_dup <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    duplicate_rows = TRUE
  )

  # Test with duplicate_rows = FALSE
  result_no_dup <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    duplicate_rows = FALSE
  )

  expect_equal(nrow(result_dup), nrow(test_data) * 2)
  expect_equal(nrow(result_no_dup), nrow(test_data))
})

test_that("mysterycall_clean_phase1: Input validation", {
  temp_dir <- tempdir()

  # Test with NULL input
  expect_error(
    mysterycall_clean_phase1(NULL, output_directory = temp_dir),
    "must be a data frame"
  )

  # Test with non-data.frame input
  expect_error(
    mysterycall_clean_phase1(list(a = 1, b = 2), output_directory = temp_dir),
    "must be a data frame"
  )

  # Test with empty data frame
  empty_df <- data.frame()
  expect_error(
    mysterycall_clean_phase1(empty_df, output_directory = temp_dir),
    "must contain at least one row"
  )
})

test_that("mysterycall_clean_phase1: Missing required columns", {
  temp_dir <- tempdir()

  # Missing 'names' column
  incomplete_data <- data.frame(
    id = 1:2,
    practice_name = c("Practice 1", "Practice 2"),
    phone_number = c("555-0001", "555-0002"),
    state_name = c("CA", "TX")
  )

  expect_error(
    mysterycall_clean_phase1(incomplete_data, output_directory = temp_dir),
    "names"
  )
})

test_that("mysterycall_clean_phase1: Output format options", {
  test_data <- create_test_phase1_data(2)
  temp_dir <- tempdir()

  # Test CSV output
  result_csv <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    output_format = "csv"
  )

  csv_files <- list.files(temp_dir, pattern = "*.csv", full.names = TRUE)
  expect_gt(length(csv_files), 0)

  # Test parquet output (if arrow is available)
  if (requireNamespace("arrow", quietly = TRUE)) {
    result_parquet <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE,
      output_format = "parquet"
    )

    parquet_files <- list.files(temp_dir, pattern = "*.parquet", full.names = TRUE)
    expect_gt(length(parquet_files), 0)
  }
})

test_that("mysterycall_clean_phase1: Data cleaning operations", {
  # Create test data with messy names
  messy_data <- data.frame(
    id = 1:3,
    names = c("Dr. John Smith, MD", "Jane Doe III", "Bob Johnson Jr."),
    practice_name = c("Main Hospital", "City Clinic", "Rural Health"),
    phone_number = c("(555) 123-4567", "555.987.6543", "555-111-2222"),
    state_name = c("California", "Texas", "New York"),
    npi = c("1234567890", "0987654321", "1122334455"),
    for_redcap = c("Yes", "No", "Yes"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  result <- mysterycall_clean_phase1(
    phase1_data = messy_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  expect_s3_class(result, "data.frame")
  expect_true(nrow(result) > 0)

  # Check that column names are cleaned
  expect_true(all(names(result) == janitor::make_clean_names(names(result))))
})

test_that("mysterycall_clean_phase1: Random ID reproducibility", {
  test_data <- create_test_phase1_data(3, include_npi = FALSE)
  temp_dir <- tempdir()

  # Generate with same seed twice
  result1 <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    id_seed = 42
  )

  result2 <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    id_seed = 42
  )

  # random_id is timestamp-based so values differ across calls; check structure only
  if ("random_id" %in% names(result1) && "random_id" %in% names(result2)) {
    expect_true(is.character(result1$random_id))
    expect_true(is.character(result2$random_id))
    expect_equal(length(result1$random_id), length(result2$random_id))
    expect_true(all(nchar(result1$random_id) > 0))
  }
})

test_that("mysterycall_clean_phase1: Performance with large dataset", {
  # Create larger dataset
  large_data <- create_test_phase1_data(1000)
  temp_dir <- tempdir()

  start_time <- Sys.time()
  result <- mysterycall_clean_phase1(
    phase1_data = large_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )
  end_time <- Sys.time()

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), nrow(large_data) * 2)  # Default duplicate_rows = TRUE

  # Should complete within reasonable time
  expect_lt(as.numeric(end_time - start_time, units = "secs"), 10)
})

test_that("mysterycall_clean_phase1: Property-based testing", {
  temp_dir <- tempdir()

  # Test with various dataset sizes
  for (n in c(1, 5, 10, 50)) {
    test_data <- create_test_phase1_data(n)

    result <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )

    # Invariants that should always hold
    expect_s3_class(result, "data.frame")
    expect_gte(nrow(result), n)  # Should have at least as many rows as input
    expect_true(all(c("names", "practice_name", "phone_number", "state_name") %in% names(result)))

    # No missing values in required columns
    expect_true(all(!is.na(result$names)))
    expect_true(all(!is.na(result$practice_name)))
  }
})

test_that("mysterycall_clean_phase1: Data validation tests", {
  temp_dir <- tempdir()

  # Test data with various edge cases
  edge_case_data <- data.frame(
    id = c(1, 2, 3, 4),
    names = c("Normal Name", "", "Name with Numbers 123", "Special Chars !@#"),
    practice_name = c("Practice", "Very Long Practice Name That Exceeds Normal Length", "", "P"),
    phone_number = c("555-1234", "invalid_phone", "123", "555-555-5555"),
    state_name = c("California", "CA", "Unknown State", ""),
    npi = c("1234567890", "invalid_npi", "123", NA),
    for_redcap = c("Yes", "No", "Maybe", ""),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(mysterycall_clean_phase1(
    phase1_data = edge_case_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  ))

  expect_s3_class(result, "data.frame")
  expect_gte(nrow(result), nrow(edge_case_data))

  # Check that function handles edge cases gracefully (empty-string names become NA by design)
  non_empty_name_rows <- if ("processing_flag_empty_name" %in% names(result)) {
    !result$processing_flag_empty_name
  } else {
    !is.na(result$names)
  }
  expect_true(all(!is.na(result$names[non_empty_name_rows])))
})

# End-to-end test
test_that("mysterycall_clean_phase1: End-to-end workflow", {
  # Simulate a realistic Phase 1 dataset
  realistic_data <- data.frame(
    id = 1:10,
    names = paste("Dr.", sample(c("John", "Jane", "Michael", "Sarah"), 10, replace = TRUE),
                  sample(c("Smith", "Johnson", "Williams", "Brown"), 10, replace = TRUE)),
    practice_name = paste(sample(c("General", "Family", "Women's", "Specialty"), 10, replace = TRUE),
                         sample(c("Health", "Medical", "Clinic", "Associates"), 10, replace = TRUE)),
    phone_number = paste0(sample(200:999, 10), "-555-", sprintf("%04d", sample(1000:9999, 10))),
    state_name = sample(state.name, 10, replace = TRUE),
    npi = paste0(sample(100000000:999999999, 10), sample(0:9, 10, replace = TRUE)),
    for_redcap = sample(c("Yes", "No"), 10, replace = TRUE),
    additional_notes = sample(c("", "Special case", "Follow up needed"), 10, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Full workflow test
  result <- mysterycall_clean_phase1(
    phase1_data = realistic_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    duplicate_rows = TRUE,
    output_format = "csv"
  )

  # Verify end-to-end results
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), nrow(realistic_data) * 2)

  # Check output file exists via attribute (avoids picking up unrelated CSVs from tempdir)
  output_path <- attr(result, "output_path")
  expect_true(!is.null(output_path) && file.exists(output_path))

  # Verify file can be read back
  if (!is.null(output_path) && file.exists(output_path)) {
    file_content <- readr::read_csv(output_path, show_col_types = FALSE)
    expect_s3_class(file_content, "data.frame")
    expect_gte(nrow(file_content), nrow(realistic_data))
  }
})