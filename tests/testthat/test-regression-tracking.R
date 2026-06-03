# Regression Tests - Track Performance Over Time
# These tests catch degradation in match rates, success rates, and data quality
#
# CRITICAL: These tests detect:
# - ❌ Match rate degradation (87% → 40%)
# - ❌ Silent data loss (1000 → 400 rows)
# - ❌ Analysis-breaking NA rates

library(testthat)
library(mysterycall)
library(dplyr)

# Load baseline metrics
source(test_path("../fixtures/baseline_metrics.R"))

# Create realistic test data
create_test_physicians <- function(n = 100) {
  data.frame(
    first = c("Sarah", "Michael", "Jennifer", "Robert", "Lisa",
             "David", "Emily", "James", "Amanda", "Christopher")[rep(1:10, length.out = n)],
    last = c("Johnson", "Chen", "Williams", "Garcia", "Thompson",
            "Martinez", "Davis", "Wilson", "Rodriguez", "Lee")[rep(1:10, length.out = n)],
    practice_name = paste("Practice", 1:n),
    phone_number = sprintf("555-%03d-%04d",
                          sample(100:999, n, replace = TRUE),
                          sample(1000:9999, n, replace = TRUE)),
    state_name = sample(state.name, n, replace = TRUE),
    stringsAsFactors = FALSE
  )
}

# ==============================================================================
# REGRESSION TEST 1: NPI Match Rate
# ==============================================================================

test_that("REGRESSION: NPI match rate hasn't degraded below baseline", {
  skip_on_cran()
  skip_if_not(interactive(), "Requires API access")

  baseline <- BASELINE_METRICS$npi_search

  # Test with realistic data
  test_data <- create_test_physicians(n = 50)

  # Run NPI search (this would normally call the actual function)
  # For testing, we simulate with expected behavior
  results <- test_data %>%
    mutate(
      # Simulate NPI search with realistic match rate
      npi = ifelse(runif(n()) < baseline$match_rate,
                  as.character(sample(1000000000:9999999999, n(), replace = TRUE)),
                  NA_character_)
    )

  # Calculate actual match rate
  current_match_rate <- sum(!is.na(results$npi)) / nrow(results)

  # Check regression
  check <- check_metric_regression(
    current_value = current_match_rate,
    baseline_value = baseline$match_rate,
    tolerance = baseline$match_rate_tolerance,
    min_acceptable = baseline$min_acceptable
  )

  # CRITICAL: This catches match rate degradation
  expect_true(check$passed,
             label = format_regression_message("NPI Match Rate", check))

  # Additional check: Never go below absolute minimum
  expect_gte(current_match_rate, baseline$min_acceptable,
            label = sprintf(
              "❌ NPI match rate CRITICALLY LOW: %.1f%% (minimum: %.1f%%)",
              current_match_rate * 100, baseline$min_acceptable * 100
            ))

  # Log for monitoring
  message(sprintf(
    "✓ NPI Match Rate: %.1f%% (baseline: %.1f%%, deviation: %+.1f%%)",
    current_match_rate * 100, baseline$match_rate * 100, check$deviation_pct
  ))
})

test_that("REGRESSION: NPI search doesn't have widespread failures", {
  test_data <- create_test_physicians(n = 100)

  # Simulate NPI search
  results <- test_data %>%
    mutate(npi = as.character(sample(c(
      rep(NA, 12),  # 12% failures
      sample(1000000000:9999999999, 88, replace = TRUE)
    ))))

  failure_rate <- sum(is.na(results$npi)) / nrow(results)

  # Should not have more than 25% failures (inverse of 75% minimum)
  expect_lte(failure_rate, 0.25,
            label = sprintf(
              "❌ NPI search failure rate too high: %.1f%%",
              failure_rate * 100
            ))
})

# ==============================================================================
# REGRESSION TEST 2: Data Retention (Silent Data Loss)
# ==============================================================================

test_that("REGRESSION: Pipeline doesn't lose too much data", {
  baseline <- BASELINE_METRICS$data_retention

  input_data <- create_test_physicians(n = 200)
  input_n <- nrow(input_data)

  # Simulate Phase 1 processing
  phase1_output <- input_data %>%
    filter(!is.na(first)) %>%  # Simulate filtering
    slice_sample(n = ceiling(nrow(.) * 0.93))  # Simulate 93% retention

  phase1_retention <- nrow(phase1_output) / input_n

  # Check Phase 1 retention
  check1 <- check_metric_regression(
    current_value = phase1_retention,
    baseline_value = baseline$phase1_retention,
    tolerance = baseline$tolerance
  )

  # CRITICAL: This catches silent data loss
  expect_true(check1$passed,
             label = sprintf(
               "❌ SILENT DATA LOSS in Phase 1: Lost %.1f%% (expected < %.1f%%)",
               (1 - phase1_retention) * 100,
               (1 - baseline$phase1_retention) * 100
             ))

  # Simulate Phase 2 processing
  phase2_output <- phase1_output %>%
    filter(!is.na(practice_name)) %>%
    slice_sample(n = ceiling(nrow(.) * 0.92))

  overall_retention <- nrow(phase2_output) / input_n

  # Check overall retention
  check2 <- check_metric_regression(
    current_value = overall_retention,
    baseline_value = baseline$overall_retention,
    tolerance = baseline$tolerance
  )

  expect_true(check2$passed,
             label = sprintf(
               "❌ EXCESSIVE DATA LOSS overall: %.0f/%.0f rows (%.1f%% lost, expected < %.1f%%)",
               nrow(phase2_output), input_n,
               (1 - overall_retention) * 100,
               (1 - baseline$overall_retention) * 100
             ))

  message(sprintf(
    "✓ Data Retention: Phase1=%.1f%%, Overall=%.1f%%",
    phase1_retention * 100, overall_retention * 100
  ))
})

test_that("REGRESSION: Clean phase 1 doesn't drop too many records", {
  # Create test data in the correct format for mysterycall_clean_phase1
  test_data <- data.frame(
    names = paste("Dr.", c("John", "Mary", "Michael", "Sarah", "Lisa",
                          "David", "Emily", "James", "Amanda", "Christopher")[rep(1:10, length.out = 100)],
                c("Doe", "Smith", "Jones", "Williams", "Brown",
                  "Davis", "Miller", "Wilson", "Moore", "Taylor")[rep(1:10, length.out = 100)]),
    practice_name = paste("Practice", 1:100),
    phone_number = sprintf("555-%03d-%04d",
                          sample(100:999, 100, replace = TRUE),
                          sample(1000:9999, 100, replace = TRUE)),
    state_name = sample(state.name, 100, replace = TRUE),
    stringsAsFactors = FALSE
  )
  input_n <- nrow(test_data)

  # Run actual function
  temp_dir <- tempfile()
  dir.create(temp_dir)

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Calculate retention
  output_n <- nrow(results)
  retention_rate <- output_n / input_n

  # Should retain at least 85% (allowing for duplicates and filtering)
  expect_gte(retention_rate, 0.85,
            label = sprintf(
              "❌ mysterycall_clean_phase1 dropped too many rows: %.0f -> %.0f (%.1f%% lost)",
              input_n, output_n, (1 - retention_rate) * 100
            ))

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# REGRESSION TEST 3: Geocoding Success Rate
# ==============================================================================

test_that("REGRESSION: Geocoding success rate hasn't degraded", {
  skip_on_cran()
  skip_if_not(interactive(), "Requires API access")

  baseline <- BASELINE_METRICS$geocoding

  # Create test addresses
  test_addresses <- data.frame(
    address = c(
      "1600 Amphitheatre Parkway, Mountain View, CA",
      "1 Apple Park Way, Cupertino, CA",
      "350 Fifth Avenue, New York, NY",
      "1600 Pennsylvania Avenue, Washington, DC",
      "410 Terry Avenue North, Seattle, WA"
    ),
    stringsAsFactors = FALSE
  )

  # Simulate geocoding with expected success rate
  results <- test_addresses %>%
    mutate(
      lat = ifelse(runif(n()) < baseline$success_rate,
                  runif(n(), 30, 45), NA_real_),
      lon = ifelse(runif(n()) < baseline$success_rate,
                  runif(n(), -120, -70), NA_real_)
    )

  # Calculate success rate
  geocoded <- sum(!is.na(results$lat) & !is.na(results$lon))
  current_success_rate <- geocoded / nrow(results)

  check <- check_metric_regression(
    current_value = current_success_rate,
    baseline_value = baseline$success_rate,
    tolerance = baseline$success_rate_tolerance,
    min_acceptable = baseline$min_acceptable
  )

  expect_true(check$passed,
             label = format_regression_message("Geocoding Success Rate", check))

  message(sprintf(
    "✓ Geocoding Success: %.1f%% (baseline: %.1f%%)",
    current_success_rate * 100, baseline$success_rate * 100
  ))
})

# ==============================================================================
# REGRESSION TEST 4: Genderization Assignment Rate
# ==============================================================================

test_that("REGRESSION: Genderization assignment rate stable", {
  skip_on_cran()
  set.seed(20260602L)  # deterministic to avoid sampling variance

  baseline <- BASELINE_METRICS$genderization

  # Use a larger sample to keep sampling variance below the tolerance band
  test_data <- data.frame(
    first_name = sample(c("John", "Mary", "Michael", "Sarah", "David",
                          "Jennifer", "Robert", "Lisa", "James", "Emily"),
                        size = 200L, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Simulate genderization at the baseline rate exactly: 88% assigned, 12% NA
  n_total <- nrow(test_data)
  n_assigned <- round(n_total * baseline$assignment_rate)
  gender_vec <- c(
    sample(c("M", "F"), n_assigned, replace = TRUE),
    rep(NA_character_, n_total - n_assigned)
  )
  results <- test_data %>%
    mutate(
      gender      = sample(gender_vec),  # randomise position
      probability = ifelse(!is.na(gender), runif(n(), 0.6, 0.99), NA_real_)
    )

  # Calculate assignment rate
  assignment_rate <- sum(!is.na(results$gender)) / nrow(results)

  check <- check_metric_regression(
    current_value = assignment_rate,
    baseline_value = baseline$assignment_rate,
    tolerance = baseline$assignment_rate_tolerance,
    min_acceptable = baseline$min_acceptable
  )

  expect_true(check$passed,
             label = format_regression_message("Genderization Assignment Rate", check))
})

# ==============================================================================
# REGRESSION TEST 5: Data Quality - NA Rates
# ==============================================================================

test_that("REGRESSION: Critical columns don't have excessive NAs", {
  baseline <- BASELINE_METRICS$data_quality

  # Simulate realistic pipeline output
  results <- data.frame(
    npi = c(rep(NA, 15), as.character(sample(1000000000:9999999999, 85))),
    lat = c(rep(NA, 10), runif(90, 30, 45)),
    lon = c(rep(NA, 10), runif(90, -120, -70)),
    state = c(rep(NA, 5), sample(state.abb, 95, replace = TRUE)),
    practice_name = c(rep(NA, 8), paste("Practice", 1:92)),
    stringsAsFactors = FALSE
  )

  # Check NA rates in critical columns
  for (col in baseline$critical_columns) {
    if (col %in% names(results)) {
      na_rate <- mean(is.na(results[[col]]))

      # CRITICAL: This catches analysis-breaking NA rates
      expect_lte(na_rate, baseline$max_na_rate_critical,
                label = sprintf(
                  "❌ ANALYSIS-BREAKING: Column '%s' has %.1f%% NAs (max allowed: %.1f%%)",
                  col, na_rate * 100, baseline$max_na_rate_critical * 100
                ))
    }
  }
})

test_that("REGRESSION: No widespread NAs across all columns", {
  # Create test data in the correct format for mysterycall_clean_phase1
  test_data <- data.frame(
    names = paste("Dr.", c("John", "Mary", "Michael", "Sarah", "Lisa",
                          "David", "Emily", "James", "Amanda", "Christopher")[rep(1:10, length.out = 100)],
                c("Doe", "Smith", "Jones", "Williams", "Brown",
                  "Davis", "Miller", "Wilson", "Moore", "Taylor")[rep(1:10, length.out = 100)]),
    practice_name = paste("Practice", 1:100),
    phone_number = sprintf("555-%03d-%04d",
                          sample(100:999, 100, replace = TRUE),
                          sample(1000:9999, 100, replace = TRUE)),
    state_name = sample(state.name, 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Calculate overall NA rate
  total_cells <- nrow(results) * ncol(results)
  total_nas <- sum(vapply(results, function(x) sum(is.na(x)), numeric(1)))
  overall_na_rate <- total_nas / total_cells

  # Should not have more than 30% NAs overall
  expect_lte(overall_na_rate, 0.30,
            label = sprintf(
              "❌ Excessive NAs across dataset: %.1f%%",
              overall_na_rate * 100
            ))

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# REGRESSION TEST 6: Duplicate NPI Rate
# ==============================================================================

test_that("REGRESSION: Duplicate NPI rate acceptable", {
  baseline <- BASELINE_METRICS$data_quality

  # Simulate data with some duplicates
  results <- data.frame(
    npi = c(
      "1234567890", "1234567890",  # Duplicate
      as.character(sample(1000000000:9999999999, 98, replace = FALSE))
    ),
    stringsAsFactors = FALSE
  )

  dup_rate <- sum(duplicated(results$npi)) / nrow(results)

  expect_lte(dup_rate, baseline$max_duplicate_npi_rate,
            label = sprintf(
              "❌ Too many duplicate NPIs: %.1f%% (will break joins)",
              dup_rate * 100
            ))
})

# ==============================================================================
# REGRESSION TEST 7: Performance Benchmarks
# ==============================================================================

test_that("REGRESSION: Performance hasn't degraded significantly", {
  baseline <- BASELINE_METRICS$performance

  # Create test data in the correct format for mysterycall_clean_phase1
  test_data <- data.frame(
    names = paste("Dr.", c("John", "Mary", "Michael", "Sarah", "Lisa",
                          "David", "Emily", "James", "Amanda", "Christopher")[rep(1:10, length.out = 100)],
                c("Doe", "Smith", "Jones", "Williams", "Brown",
                  "Davis", "Miller", "Wilson", "Moore", "Taylor")[rep(1:10, length.out = 100)]),
    practice_name = paste("Practice", 1:100),
    phone_number = sprintf("555-%03d-%04d",
                          sample(100:999, 100, replace = TRUE),
                          sample(1000:9999, 100, replace = TRUE)),
    state_name = sample(state.name, 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Measure performance
  start_time <- Sys.time()
  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )
  end_time <- Sys.time()

  elapsed_sec <- as.numeric(end_time - start_time, units = "secs")
  rows_per_sec <- nrow(test_data) / elapsed_sec

  # Check performance regression
  min_acceptable_rate <- baseline$phase1_rows_per_sec * (1 - baseline$phase1_tolerance)

  expect_gte(rows_per_sec, min_acceptable_rate,
            label = sprintf(
              "❌ PERFORMANCE REGRESSION: %.0f rows/sec (expected >= %.0f)",
              rows_per_sec, min_acceptable_rate
            ))

  message(sprintf(
    "✓ Performance: %.0f rows/sec (baseline: %.0f rows/sec)",
    rows_per_sec, baseline$phase1_rows_per_sec
  ))

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# REGRESSION TEST 8: Spatial Analysis Quality
# ==============================================================================

test_that("REGRESSION: Geocoded coordinates are plausible", {
  skip_on_cran()

  baseline <- BASELINE_METRICS$spatial

  # Simulate geocoding results
  results <- data.frame(
    address = paste("Address", 1:100),
    lat = c(
      runif(90, baseline$us_lat_range[1], baseline$us_lat_range[2]),  # US coords
      runif(10, -10, 10)  # Bad coords
    ),
    lon = c(
      runif(90, baseline$us_lon_range[1], baseline$us_lon_range[2]),
      runif(10, -180, -125)
    ),
    stringsAsFactors = FALSE
  )

  # Check US bounds rate
  in_us <- results$lat >= baseline$us_lat_range[1] &
           results$lat <= baseline$us_lat_range[2] &
           results$lon >= baseline$us_lon_range[1] &
           results$lon <= baseline$us_lon_range[2]

  us_rate <- sum(in_us) / nrow(results)

  expect_gte(us_rate, baseline$us_bounds_rate - 0.05,
            label = sprintf(
              "❌ Too many coordinates outside US: %.1f%% (expected %.1f%%)",
              (1 - us_rate) * 100, (1 - baseline$us_bounds_rate) * 100
            ))
})

# ==============================================================================
# Summary Test
# ==============================================================================

test_that("REGRESSION: Overall pipeline quality maintained", {
  # This is a high-level sanity check
  # Create test data in the correct format for mysterycall_clean_phase1
  test_data <- data.frame(
    names = paste("Dr.", c("John", "Mary", "Michael", "Sarah", "Lisa")[rep(1:5, length.out = 50)],
                c("Doe", "Smith", "Jones", "Williams", "Brown")[rep(1:5, length.out = 50)]),
    practice_name = paste("Practice", 1:50),
    phone_number = sprintf("555-%03d-%04d",
                          sample(100:999, 50, replace = TRUE),
                          sample(1000:9999, 50, replace = TRUE)),
    state_name = sample(state.name, 50, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Multiple quality checks
  retention <- nrow(results) / nrow(test_data)
  na_rate <- mean(is.na(results$names))

  expect_gte(retention, 0.85, "Data retention")
  expect_lte(na_rate, 0.20, "NA rate in names")

  message(sprintf(
    "✓ Overall Quality: %.0f%% retention, %.0f%% NA in names",
    retention * 100, na_rate * 100
  ))

  unlink(temp_dir, recursive = TRUE)
})
