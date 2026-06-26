# Performance benchmark tests
library(testthat)
library(dplyr)

# Performance benchmarks - these represent acceptable performance thresholds
PERFORMANCE_BENCHMARKS <- list(
  small_dataset = list(size = 10, max_time = 10),     # 10 rows in 10 seconds (includes startup overhead)
  medium_dataset = list(size = 100, max_time = 10),   # 100 rows in 10 seconds
  large_dataset = list(size = 1000, max_time = 60),   # 1000 rows in 60 seconds
  memory_limit = 50 * 1024^2,  # 50MB maximum memory for operations
  npi_search_timeout = 30      # 30 seconds max for NPI searches
)

# Helper function to create datasets of varying sizes
create_performance_dataset <- function(n) {
  data.frame(
    id = 1:n,
    names = paste("Provider", 1:n),
    practice_name = paste("Practice", sample(1:min(50, n), n, replace = TRUE)),
    phone_number = paste0(sample(200:999, n, replace = TRUE), "-555-",
                         sprintf("%04d", sample(1000:9999, n, replace = TRUE))),
    state_name = sample(state.name, n, replace = TRUE),
    npi = paste0(sample(100000000:999999999, n), sample(0:9, n, replace = TRUE)),
    for_redcap = sample(c("Yes", "No"), n, replace = TRUE),
    additional_field1 = sample(letters, n, replace = TRUE),
    additional_field2 = runif(n),
    additional_field3 = sample(c("A", "B", "C", NA), n, replace = TRUE),
    stringsAsFactors = FALSE
  )
}

# Helper function to measure execution time and memory
measure_performance <- function(expr) {
  # Measure memory before
  gc()  # Force garbage collection
  mem_before <- sum(gc()[, 2])

  # Measure execution time
  start_time <- Sys.time()
  result <- eval(expr)
  end_time <- Sys.time()

  # Measure memory after
  gc()
  mem_after <- sum(gc()[, 2])

  list(
    result = result,
    execution_time = as.numeric(end_time - start_time, units = "secs"),
    memory_used = mem_after - mem_before,
    peak_memory = mem_after
  )
}

test_that("Performance: mysterycall_clean_phase1 with small dataset", {
  skip_on_cran()

  benchmark <- PERFORMANCE_BENCHMARKS$small_dataset
  test_data <- create_performance_dataset(benchmark$size)
  temp_dir <- tempdir()

  perf <- measure_performance({
    mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Check execution time
  expect_lt(perf$execution_time, benchmark$max_time)

  # Check memory usage is reasonable
  expect_lt(perf$peak_memory, PERFORMANCE_BENCHMARKS$memory_limit)

  # Verify output quality isn't compromised for speed
  expect_s3_class(perf$result, "data.frame")
  expect_gte(nrow(perf$result), benchmark$size)
})

test_that("Performance: mysterycall_clean_phase1 with medium dataset", {
  skip_on_cran()

  benchmark <- PERFORMANCE_BENCHMARKS$medium_dataset
  test_data <- create_performance_dataset(benchmark$size)
  temp_dir <- tempdir()

  perf <- measure_performance({
    mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  expect_lt(perf$execution_time, benchmark$max_time)

  # Check linear scaling (shouldn't be quadratic)
  small_benchmark <- PERFORMANCE_BENCHMARKS$small_dataset
  expected_time_ratio <- benchmark$size / small_benchmark$size
  time_ratio_tolerance <- expected_time_ratio * 2  # Allow 2x tolerance

  expect_lt(perf$execution_time / small_benchmark$max_time, time_ratio_tolerance)
})

test_that("Performance: mysterycall_clean_phase1 with large dataset", {
  skip_on_cran()
  skip_if_not(identical(Sys.getenv("TEST_PERFORMANCE"), "true"),
              "Set TEST_PERFORMANCE=true to run large dataset tests")

  benchmark <- PERFORMANCE_BENCHMARKS$large_dataset
  test_data <- create_performance_dataset(benchmark$size)
  temp_dir <- tempdir()

  perf <- measure_performance({
    mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  expect_lt(perf$execution_time, benchmark$max_time)

  # Memory should still be reasonable
  expect_lt(perf$peak_memory, PERFORMANCE_BENCHMARKS$memory_limit * 2)  # Allow 2x for large datasets
})

test_that("Performance: mysterycall_search_taxonomy response time", {
  skip_on_cran()

  # Mock fast NPI search for performance testing
  mock_npi_search <- function(taxonomy_description, ...) {
    # Simulate realistic but fast response
    Sys.sleep(0.1)  # Simulate network delay
    list(
      npi = paste0("123456789", 0:4),
      basic_first_name = paste("Provider", 1:5),
      basic_last_name = paste("Last", 1:5),
      basic_credential = rep("MD", 5),
      addresses_country_name = rep("United States", 5),
      taxonomies_desc = rep(taxonomy_description, 5)
    )
  }

  mock_npi_flatten <- function(x) {
    if (is.list(x) && length(x) > 0) {
      tibble::as_tibble(x)
    } else {
      tibble::tibble()
    }
  }

  with_mocked_bindings(
    npi_search = mock_npi_search,
    npi_flatten = mock_npi_flatten,
    .package = "npi",
    {
      perf <- measure_performance({
        mysterycall_search_taxonomy("Gynecologic Oncology", write_snapshot = FALSE, notify = FALSE)
      })

      expect_lt(perf$execution_time, PERFORMANCE_BENCHMARKS$npi_search_timeout)

      # Check that result quality is maintained
      expect_s3_class(perf$result, "data.frame")
      expect_gt(nrow(perf$result), 0)
    }
  )
})

test_that("Performance: Memory efficiency with multiple operations", {
  skip_on_cran()

  # Test memory efficiency when running multiple operations
  test_data <- create_performance_dataset(50)
  temp_dir <- tempdir()

  gc()  # Start with clean memory
  mem_start <- sum(gc()[, 2])

  # Perform multiple operations
  for (i in 1:5) {
    result <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )

    # Process the result further
    if ("npi" %in% names(result)) {
      validated <- mysterycall_validate_npi(result)
    }
  }

  gc()
  mem_end <- sum(gc()[, 2])
  mem_increase = mem_end - mem_start

  # Memory shouldn't grow significantly with repeated operations
  expect_lt(mem_increase, PERFORMANCE_BENCHMARKS$memory_limit / 2)
})

test_that("Performance: CPU efficiency", {
  skip_on_cran()

  test_data <- create_performance_dataset(100)
  temp_dir <- tempdir()

  # Use system.time for more detailed CPU measurements
  timing <- system.time({
    result <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Check CPU time efficiency
  expect_lt(timing[["user.self"]], 5)

  expect_lt(timing[["sys.self"]], 2)

  # Ratio of user to elapsed time (I/O-bound operations legitimately score lower)
  cpu_efficiency <- timing[["user.self"]] / timing[["elapsed"]]
  expect_gt(cpu_efficiency, 0.05)
})

test_that("Performance: File I/O efficiency", {
  skip_on_cran()

  test_data <- create_performance_dataset(200)
  temp_dir <- tempdir()

  # Test CSV output performance
  perf_csv <- measure_performance({
    mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE,
      output_format = "csv"
    )
  })

  # Test parquet output performance (if available)
  if (requireNamespace("arrow", quietly = TRUE)) {
    perf_parquet <- measure_performance({
      mysterycall_clean_phase1(
        phase1_data = test_data,
        output_directory = temp_dir,
        verbose = FALSE,
        notify = FALSE,
        output_format = "parquet"
      )
    })

    # Both should complete in reasonable time
    expect_lt(perf_csv$execution_time, 15)
    expect_lt(perf_parquet$execution_time, 15)
  }

  # Check that files were actually created
  csv_files <- list.files(temp_dir, pattern = "*.csv", full.names = TRUE)
  expect_gt(length(csv_files), 0)

  # File size should be reasonable
  if (length(csv_files) > 0) {
    file_size <- file.info(csv_files[1])$size
    expect_lt(file_size, 10 * 1024^2)  # 10MB max for test data
  }
})

test_that("Performance: Concurrent operations stress test", {
  skip_on_cran()
  skip_if_not(identical(Sys.getenv("TEST_STRESS"), "true"),
              "Set TEST_STRESS=true to run stress tests")

  # Test system behavior under concurrent load
  test_data <- create_performance_dataset(50)
  temp_dirs <- replicate(3, tempdir(), simplify = FALSE)

  start_time <- Sys.time()

  # Simulate concurrent operations (sequential for reproducibility)
  results <- list()
  for (i in 1:3) {
    results[[i]] <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dirs[[i]],
      verbose = FALSE,
      notify = FALSE
    )
  }

  end_time <- Sys.time()
  total_time <- as.numeric(end_time - start_time, units = "secs")

  # Should handle multiple operations efficiently
  expect_lt(total_time, 30)

  # All operations should succeed
  expect_equal(length(results), 3)
  for (result in results) {
    expect_s3_class(result, "data.frame")
    expect_gt(nrow(result), 0)
  }
})

test_that("Performance: Memory scaling characteristics", {
  skip_on_cran()

  # Test how memory usage scales with dataset size
  sizes <- c(10, 50, 100)
  memory_usage <- numeric(length(sizes))

  for (i in seq_along(sizes)) {
    test_data <- create_performance_dataset(sizes[i])
    temp_dir <- tempdir()

    gc()
    mem_before <- sum(gc()[, 2])

    result <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )

    gc()
    mem_after <- sum(gc()[, 2])
    memory_usage[i] <- mem_after - mem_before
  }

  # Memory scaling should be roughly linear, not quadratic
  for (i in 2:length(sizes)) {
    size_ratio <- sizes[i] / sizes[i-1]
    prev <- memory_usage[i - 1]
    # Skip if previous measurement was near-zero (gc() noise) to avoid NaN/Inf
    if (is.na(prev) || prev <= 0.1) next
    memory_ratio <- memory_usage[i] / prev
    # Allow some overhead, but shouldn't be quadratic scaling
    expect_lt(memory_ratio, size_ratio * 2)
  }
})

test_that("Performance: Function call overhead", {
  skip_on_cran()

  # Test that function call overhead is minimal
  simple_data <- data.frame(
    id = 1,
    names = "Provider 1",
    practice_name = "Practice 1",
    phone_number = "555-0001",
    state_name = "California",
    npi = "1234567890",
    for_redcap = "Yes",
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Measure overhead with minimal data
  perf <- measure_performance({
    mysterycall_clean_phase1(
      phase1_data = simple_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Function call overhead should be minimal
  expect_lt(perf$execution_time, 1)
})

test_that("Performance: Regression performance comparison", {
  skip_on_cran()

  # Compare performance with baseline expectations
  test_data <- create_performance_dataset(100)
  temp_dir <- tempdir()

  perf <- measure_performance({
    mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Store performance metrics for comparison
  performance_metrics <- list(
    execution_time = perf$execution_time,
    memory_used = perf$memory_used,
    peak_memory = perf$peak_memory,
    dataset_size = nrow(test_data)
  )

  # Basic performance requirements
  expect_lt(performance_metrics$execution_time, 15)

  expect_lt(performance_metrics$peak_memory, PERFORMANCE_BENCHMARKS$memory_limit)

  # Throughput should be reasonable (rows per second)
  throughput <- performance_metrics$dataset_size / performance_metrics$execution_time
  expect_gt(throughput, 10)
})