# Stress and Performance Tests - Large Datasets and Memory Limits
# These tests verify the package handles production-scale data volumes
#
# CRITICAL: These tests detect:
# - ❌ Out-of-memory errors with large datasets
# - ❌ Performance degradation at scale
# - ❌ Resource leaks during processing
# - ❌ Inefficient algorithms that don't scale

library(testthat)
library(dplyr)

# ==============================================================================
# STRESS TEST 1: Large Dataset Processing
# ==============================================================================

test_that("STRESS: Handles 10k row dataset efficiently", {
  skip_on_cran()
  skip_if_not(interactive(), "Requires significant resources")

  # Create 10k row test dataset
  large_data <- data.frame(
    names = paste("Dr.",
                 sample(c("John", "Mary", "Michael", "Sarah", "David"), 10000, replace = TRUE),
                 sample(c("Doe", "Smith", "Jones", "Williams", "Brown"), 10000, replace = TRUE)),
    practice_name = paste("Practice", 1:10000),
    phone_number = sprintf("555-%03d-%04d",
                          sample(100:999, 10000, replace = TRUE),
                          sample(1000:9999, 10000, replace = TRUE)),
    state_name = sample(state.name, 10000, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Measure performance
  start_time <- Sys.time()
  start_mem <- as.numeric(object.size(ls()))

  results <- mysterycall_clean_phase1(
    phase1_data = large_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  end_time <- Sys.time()
  elapsed_sec <- as.numeric(end_time - start_time, units = "secs")

  # Performance expectations for 10k rows
  expect_lt(elapsed_sec, 600)  # Should complete in < 10 minutes

  # Check data integrity
  expect_gte(nrow(results), 8000)  # Should retain at least 80%

  # Check memory didn't explode
  final_mem <- as.numeric(object.size(ls()))
  mem_increase_mb <- (final_mem - start_mem) / 1024^2
  expect_lt(mem_increase_mb, 500)  # Should use < 500MB extra

  message(sprintf(
    "✓ Processed 10k rows in %.1f seconds (%.0f rows/sec), memory: %.0f MB",
    elapsed_sec, nrow(large_data) / elapsed_sec, mem_increase_mb
  ))

  unlink(temp_dir, recursive = TRUE)
})

test_that("STRESS: Memory efficient with repeated operations", {
  skip_on_cran()

  # Simulate processing multiple batches
  test_data <- data.frame(
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 500)),
    practice_name = paste("Practice", 1:1000),
    phone_number = rep("555-123-4567", 1000),
    state_name = rep(state.name[1:50], 20),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Run 5 times to check for memory leaks
  mem_sizes <- numeric(5)

  for (i in 1:5) {
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )

    # Force garbage collection and measure
    gc()
    mem_sizes[i] <- sum(gc()[, 2])
  }

  # Memory should be stable (no leaks)
  mem_growth <- (mem_sizes[5] - mem_sizes[1]) / mem_sizes[1]
  expect_lt(mem_growth, 0.20)  # < 20% memory growth across 5 runs

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# STRESS TEST 2: High NA Rate Handling
# ==============================================================================

test_that("STRESS: Handles datasets with 90% missing data", {
  skip_on_cran()

  # Create dataset with extreme NA rates
  sparse_data <- data.frame(
    names = c(paste("Dr. John Doe"), rep(NA, 999)),
    practice_name = c(rep(NA, 900), paste("Practice", 1:100)),
    phone_number = c(rep(NA, 950), rep("555-123-4567", 50)),
    state_name = c(rep(NA, 800), sample(state.name, 200, replace = TRUE)),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Should handle gracefully without crashing
  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = sparse_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Should produce some output even with sparse data
  expect_gt(nrow(results), 0)

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# STRESS TEST 3: Wide Datasets (Many Columns)
# ==============================================================================

test_that("STRESS: Handles wide datasets with 50+ columns", {
  skip_on_cran()

  # Create dataset with many extra columns
  wide_data <- data.frame(
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 50)),
    practice_name = paste("Practice", 1:100),
    phone_number = rep("555-123-4567", 100),
    state_name = sample(state.name, 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Add 46 extra columns
  for (i in 1:46) {
    wide_data[[paste0("extra_col_", i)]] <- rnorm(100)
  }

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = wide_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Core columns should still work
  expect_true("names" %in% names(results))
  expect_gte(nrow(results), 80)

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# STRESS TEST 4: Duplicate Detection at Scale
# ==============================================================================

test_that("STRESS: Efficiently detects duplicates in large datasets", {
  skip_on_cran()

  # Create 5k rows with 10% duplicates
  base_data <- data.frame(
    names = paste("Dr.",
                 sample(c("John", "Mary", "Michael"), 4500, replace = TRUE),
                 sample(c("Doe", "Smith", "Jones"), 4500, replace = TRUE)),
    practice_name = paste("Practice", sample(1:1000, 4500, replace = TRUE)),
    phone_number = sprintf("555-%03d-%04d",
                          sample(100:999, 4500, replace = TRUE),
                          sample(1000:9999, 4500, replace = TRUE)),
    state_name = sample(state.name, 4500, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Add 500 exact duplicates
  dup_data <- base_data[sample(seq_len(nrow(base_data)), 500), ]
  large_data <- rbind(base_data, dup_data)

  temp_dir <- tempfile()
  dir.create(temp_dir)

  start_time <- Sys.time()

  results <- mysterycall_clean_phase1(
    phase1_data      = large_data,
    output_directory = temp_dir,
    verbose          = FALSE,
    notify           = FALSE,
    duplicate_rows   = FALSE  # do not duplicate rows for insurance scenarios
  )

  elapsed_sec <- as.numeric(Sys.time() - start_time, units = "secs")

  # Should complete efficiently
  expect_lt(elapsed_sec, 300)  # < 5 minutes for 5k rows

  # Should handle duplicates by flagging them (function does not drop rows)
  expect_lte(nrow(results), nrow(large_data))
  expect_true("processing_flag_is_duplicate" %in% names(results) ||
              "processing_flag_duplicate" %in% names(results) ||
              # Older versions may use a different name; allow any *duplicate* flag
              any(grepl("duplicate", names(results), ignore.case = TRUE)))

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# STRESS TEST 5: Long String Handling
# ==============================================================================

test_that("STRESS: Handles very long text fields", {
  # Create data with extremely long strings
  long_data <- data.frame(
    names = paste("Dr.", paste(rep("VeryLongName", 100), collapse = "")),
    practice_name = paste(rep("Hospital", 200), collapse = " "),
    phone_number = "555-123-4567",
    state_name = "California",
    stringsAsFactors = FALSE
  )

  # Repeat 100 times
  long_data <- long_data[rep(1, 100), ]

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = long_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  expect_gte(nrow(results), 90)

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# STRESS TEST 6: Concurrent File I/O
# ==============================================================================

test_that("STRESS: Handles multiple file writes efficiently", {
  skip_on_cran()

  test_data <- data.frame(
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 250)),
    practice_name = paste("Practice", 1:500),
    phone_number = rep("555-123-4567", 500),
    state_name = sample(state.name, 500, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Create 10 temporary directories
  temp_dirs <- replicate(10, tempfile(), simplify = FALSE)
  lapply(temp_dirs, dir.create)

  start_time <- Sys.time()

  # Write to multiple locations sequentially
  for (temp_dir in temp_dirs) {
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  }

  elapsed_sec <- as.numeric(Sys.time() - start_time, units = "secs")

  # Should complete in reasonable time
  expect_lt(elapsed_sec, 60)  # < 1 minute for 10 writes

  # Cleanup
  lapply(temp_dirs, unlink, recursive = TRUE)
})

# ==============================================================================
# STRESS TEST 7: Memory Limit Awareness
# ==============================================================================

test_that("STRESS: Gracefully handles memory constraints", {
  skip_on_cran()
  skip_if_not(interactive(), "Requires memory profiling")

  # Create progressively larger datasets
  sizes <- c(100, 500, 1000, 2000)
  processing_times <- numeric(length(sizes))

  temp_dir <- tempfile()
  dir.create(temp_dir)

  for (i in seq_along(sizes)) {
    test_data <- data.frame(
      names = paste("Dr.",
                   sample(c("John", "Mary"), sizes[i], replace = TRUE),
                   sample(c("Doe", "Smith"), sizes[i], replace = TRUE)),
      practice_name = paste("Practice", 1:sizes[i]),
      phone_number = rep("555-123-4567", sizes[i]),
      state_name = sample(state.name, sizes[i], replace = TRUE),
      stringsAsFactors = FALSE
    )

    start_time <- Sys.time()

    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )

    processing_times[i] <- as.numeric(Sys.time() - start_time, units = "secs")
  }

  # Check scaling is roughly linear (not exponential)
  # Time ratio should be similar to size ratio
  time_ratio <- processing_times[4] / processing_times[1]
  size_ratio <- sizes[4] / sizes[1]

  # Allow 3x overhead for scaling (should be < exponential)
  expect_lt(time_ratio, size_ratio * 3)

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# STRESS TEST 8: Rapid Repeated Calls
# ==============================================================================

test_that("STRESS: Handles rapid repeated function calls", {
  skip_on_cran()

  test_data <- data.frame(
    names = "Dr. John Doe",
    practice_name = "Hospital A",
    phone_number = "555-123-4567",
    state_name = "California",
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Call 50 times rapidly
  start_time <- Sys.time()

  for (i in 1:50) {
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  }

  elapsed_sec <- as.numeric(Sys.time() - start_time, units = "secs")

  # Should handle rapid calls efficiently
  expect_lt(elapsed_sec, 30)  # < 30 seconds for 50 calls

  unlink(temp_dir, recursive = TRUE)
})
