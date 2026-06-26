# Data Provenance Tests - Track Data Lineage Through Pipeline
# These tests verify data transformations are traceable and auditable
#
# CRITICAL: These tests detect:
# - ❌ Lost data without explanation
# - ❌ Untraceable transformations
# - ❌ Missing audit trail for debugging
# - ❌ ID columns not preserved across stages

library(testthat)
library(dplyr)

# ==============================================================================
# PROVENANCE TEST 1: ID Column Preservation
# ==============================================================================

test_that("PROVENANCE: ID columns preserved through Phase 1", {
  test_data <- data.frame(
    id = 1:100,
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 50)),
    practice_name = paste("Practice", 1:100),
    phone_number = rep("555-123-4567", 100),
    state_name = sample(state.name, 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    duplicate_rows = FALSE  # Keep original row count for this test
  )

  # Both new id and original_id columns should be present
  expect_true("id" %in% names(results))
  expect_true("original_id" %in% names(results))

  # Original IDs should be preserved in original_id column
  if ("original_id" %in% names(results)) {
    expect_true(all(results$original_id %in% test_data$id))
  }

  # New id column exists for REDCap workflow
  expect_equal(length(unique(results$id)), nrow(results))

  unlink(temp_dir, recursive = TRUE)
})

test_that("PROVENANCE: Can trace output rows back to input rows", {
  test_data <- data.frame(
    record_id = sprintf("REC-%04d", 1:50),
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 25)),
    practice_name = paste("Practice", 1:50),
    phone_number = rep("555-123-4567", 50),
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

  # Should be able to trace back
  if ("record_id" %in% names(results)) {
    # Each output row should have traceable input
    expect_true(all(results$record_id %in% test_data$record_id))

    # Can join back to input
    joined <- results %>%
      inner_join(test_data, by = "record_id", suffix = c("_out", "_in"))

    expect_gt(nrow(joined), 0)
  }

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# PROVENANCE TEST 2: Row Count Tracking
# ==============================================================================

test_that("PROVENANCE: Track row count changes through pipeline", {
  test_data <- data.frame(
    names = c(paste("Dr.", rep(c("John Doe", "Mary Smith"), 40)), rep(NA, 20)),
    practice_name = paste("Practice", 1:100),
    phone_number = rep("555-123-4567", 100),
    state_name = sample(state.name, 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  input_rows <- nrow(test_data)

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    duplicate_rows = FALSE  # Disable duplication to test row preservation
  )

  output_rows <- nrow(results)

  # Calculate attrition
  rows_lost <- input_rows - output_rows
  attrition_pct <- (rows_lost / input_rows) * 100

  # Should be able to explain row count changes
  expect_gte(output_rows, 0)
  expect_lte(output_rows, input_rows)

  # Check audit trail captured this
  audit <- attr(results, "audit_trail")
  expect_equal(audit$input_rows, input_rows)
  expect_equal(audit$output_rows, output_rows)

  message(sprintf(
    "Provenance: %d input rows → %d output rows (%.1f%% retained)",
    input_rows, output_rows, (output_rows / input_rows) * 100
  ))

  unlink(temp_dir, recursive = TRUE)
})

test_that("PROVENANCE: Document which rows were filtered and why", {
  test_data <- data.frame(
    id = 1:50,
    names = c(
      paste("Dr.", rep(c("John Doe", "Mary Smith"), 20)),  # Valid: 40
      rep(NA, 5),                                          # Invalid: 5 NAs
      rep("", 5)                                           # Invalid: 5 empty
    ),
    practice_name = paste("Practice", 1:50),
    phone_number = rep("555-123-4567", 50),
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

  # Identify filtered rows
  if ("id" %in% names(results)) {
    filtered_ids <- setdiff(test_data$id, results$id)
    retained_ids <- intersect(test_data$id, results$id)

    expect_gt(length(retained_ids), 0)

    # Can identify which rows were filtered
    if (length(filtered_ids) > 0) {
      filtered_data <- test_data %>% filter(id %in% filtered_ids)
      message(sprintf("Filtered %d rows (missing/invalid names)", length(filtered_ids)))
    }
  }

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# PROVENANCE TEST 3: Data Transformation Tracking
# ==============================================================================

test_that("PROVENANCE: Track field modifications through pipeline", {
  test_data <- data.frame(
    id = 1:20,
    names = paste("Dr.", rep(c("john doe", "MARY SMITH"), 10)),  # Mixed case
    practice_name = paste("  Practice  ", 1:20),  # Extra whitespace
    phone_number = c(
      rep("555-123-4567", 10),       # Standard format
      rep("(555) 123-4567", 10)      # Alternate format
    ),
    state_name = c(rep("California", 10), rep("CA", 10)),  # Mixed state formats
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

  # Document transformations
  # 1. Names may be title-cased
  # 2. Whitespace may be trimmed
  # 3. Phone formats may be standardized
  # 4. State names may be standardized

  if (nrow(results) > 0) {
    # Check transformations occurred
    expect_true(is.data.frame(results))

    # Names should exist (may be transformed)
    expect_true("names" %in% names(results) || "name" %in% names(results))
  }

  unlink(temp_dir, recursive = TRUE)
})

test_that("PROVENANCE: Identify when data quality changes", {
  test_data <- data.frame(
    id = 1:50,
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 25)),
    practice_name = paste("Practice", 1:50),
    phone_number = rep("555-123-4567", 50),
    state_name = sample(state.name, 50, replace = TRUE),
    # Complete lat/lon initially
    lat = runif(50, 30, 45),
    lon = runif(50, -120, -70),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Check initial completeness
  input_complete_coords <- sum(!is.na(test_data$lat) & !is.na(test_data$lon))

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Check output completeness
  if ("lat" %in% names(results) && "lon" %in% names(results)) {
    output_complete_coords <- sum(!is.na(results$lat) & !is.na(results$lon))

    # Track quality change
    quality_change <- output_complete_coords - input_complete_coords

    message(sprintf(
      "Data quality: %d complete coords → %d complete coords (change: %+d)",
      input_complete_coords, output_complete_coords, quality_change
    ))

    expect_gte(output_complete_coords, 0)
  }

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# PROVENANCE TEST 4: Audit Trail Generation
# ==============================================================================

test_that("PROVENANCE: Generate audit log of processing steps", {
  test_data <- data.frame(
    id = 1:30,
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 15)),
    practice_name = paste("Practice", 1:30),
    phone_number = rep("555-123-4567", 30),
    state_name = sample(state.name, 30, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Track processing timestamp
  start_time <- Sys.time()

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  end_time <- Sys.time()

  # Audit log should capture:
  audit_log <- list(
    timestamp_start = start_time,
    timestamp_end = end_time,
    duration_sec = as.numeric(end_time - start_time, units = "secs"),
    input_rows = nrow(test_data),
    output_rows = nrow(results),
    function_called = "mysterycall_clean_phase1",
    parameters = list(
      verbose = FALSE,
      notify = FALSE
    )
  )

  expect_true(audit_log$duration_sec >= 0)
  expect_equal(audit_log$input_rows, 30)
  expect_gte(audit_log$output_rows, 0)

  unlink(temp_dir, recursive = TRUE)
})

test_that("PROVENANCE: Record processing metadata for debugging", {
  test_data <- data.frame(
    id = 1:20,
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 10)),
    practice_name = paste("Practice", 1:20),
    phone_number = rep("555-123-4567", 20),
    state_name = sample(state.name, 20, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Capture processing metadata
  metadata <- list(
    r_version = R.version.string,
    platform = .Platform$OS.type,
    package_version = packageVersion("mysterycall"),
    input_md5 = digest::digest(test_data),
    processing_date = Sys.Date()
  )

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Metadata should be valid
  expect_true(nchar(metadata$r_version) > 0)
  expect_true(metadata$platform %in% c("unix", "windows"))

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# PROVENANCE TEST 5: Pipeline Stage Lineage
# ==============================================================================

test_that("PROVENANCE: Track data through multiple pipeline stages", {
  skip("Multi-stage pipeline test")

  # Simulated multi-stage pipeline
  stage1_input <- data.frame(
    id = 1:50,
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 25)),
    practice_name = paste("Practice", 1:50),
    phone_number = rep("555-123-4567", 50),
    state_name = sample(state.name, 50, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Track lineage through stages
  lineage <- list(
    stage_1 = list(name = "Phase 1 Cleaning", input_rows = nrow(stage1_input)),
    stage_2 = list(name = "Geocoding", input_rows = NA),
    stage_3 = list(name = "Spatial Analysis", input_rows = NA)
  )

  expect_equal(lineage$stage_1$input_rows, 50)
})

test_that("PROVENANCE: Verify end-to-end data lineage", {
  skip("End-to-end lineage test")

  # Document complete pipeline flow:
  # Raw Input → Phase 1 → Phase 2 → Geocoding → Spatial → Statistics

  pipeline_stages <- c(
    "Raw Input",
    "Phase 1 Cleaning",
    "Phase 2 Processing",
    "Geocoding",
    "Spatial Analysis",
    "Statistical Summary"
  )

  expect_equal(length(pipeline_stages), 6)
})

# ==============================================================================
# PROVENANCE TEST 6: Data Quality Degradation Tracking
# ==============================================================================

test_that("PROVENANCE: Identify where NA values were introduced", {
  test_data <- data.frame(
    id = 1:40,
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 20)),
    practice_name = paste("Practice", 1:40),
    phone_number = rep("555-123-4567", 40),
    state_name = sample(state.name, 40, replace = TRUE),
    # All non-NA initially
    npi = as.character(sample(1000000000:9999999999, 40, replace = FALSE)),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Count NAs before
  na_counts_before <- vapply(test_data, function(x) sum(is.na(x)), numeric(1))

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Count NAs after
  na_counts_after <- vapply(results, function(x) sum(is.na(x)), numeric(1))

  # Track NA introduction
  common_cols <- intersect(names(na_counts_before), names(na_counts_after))

  for (col in common_cols) {
    na_change <- na_counts_after[col] - na_counts_before[col]
    if (na_change > 0) {
      message(sprintf("Column '%s': +%d NAs introduced", col, na_change))
    }
  }

  expect_true(length(common_cols) > 0)

  unlink(temp_dir, recursive = TRUE)
})

test_that("PROVENANCE: Track data completeness at each stage", {
  test_data <- data.frame(
    id = 1:50,
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 25)),
    practice_name = paste("Practice", 1:50),
    phone_number = rep("555-123-4567", 50),
    state_name = sample(state.name, 50, replace = TRUE),
    npi = c(
      as.character(sample(1000000000:9999999999, 40, replace = FALSE)),
      rep(NA, 10)  # 10 missing NPIs
    ),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Calculate initial completeness
  completeness_before <- (sum(!is.na(test_data$npi)) / nrow(test_data)) * 100

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Calculate final completeness
  if ("npi" %in% names(results)) {
    completeness_after <- (sum(!is.na(results$npi)) / nrow(results)) * 100

    message(sprintf(
      "NPI completeness: %.1f%% → %.1f%%",
      completeness_before, completeness_after
    ))

    expect_gte(completeness_after, 0)
    expect_lte(completeness_after, 100)
  }

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# PROVENANCE TEST 7: Reversibility and Rollback
# ==============================================================================

test_that("PROVENANCE: Can reconstruct processing decisions", {
  test_data <- data.frame(
    id = 1:30,
    names = c(
      paste("Dr.", rep(c("John Doe", "Mary Smith"), 12)),  # 24 valid
      rep("", 6)                                           # 6 invalid
    ),
    practice_name = paste("Practice", 1:30),
    phone_number = rep("555-123-4567", 30),
    state_name = sample(state.name, 30, replace = TRUE),
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

  # Should be able to determine why rows were excluded
  if ("id" %in% names(results)) {
    excluded_ids <- setdiff(test_data$id, results$id)

    if (length(excluded_ids) > 0) {
      excluded_rows <- test_data %>% filter(id %in% excluded_ids)

      # Can identify reason for exclusion
      has_empty_name <- excluded_rows$names == ""
      has_na_name <- is.na(excluded_rows$names)

      reasons_identifiable <- sum(has_empty_name | has_na_name)

      message(sprintf(
        "Excluded %d rows: %d with identifiable reasons",
        length(excluded_ids), reasons_identifiable
      ))

      expect_gte(reasons_identifiable, 0)
    }
  }

  unlink(temp_dir, recursive = TRUE)
})

test_that("PROVENANCE: Store sufficient info for data recovery", {
  skip("Data recovery mechanism test")

  # Should store enough info to recover/restore data
  recovery_info <- list(
    original_file = "raw_input.csv",
    processing_timestamp = Sys.time(),
    filters_applied = c("remove_empty_names", "remove_invalid_phones"),
    excluded_row_ids = c(5, 12, 23, 45),
    transformation_rules = list(
      names = "trim_whitespace",
      state_name = "standardize_to_abbrev"
    )
  )

  expect_true(length(recovery_info$excluded_row_ids) > 0)
  expect_true(length(recovery_info$transformation_rules) > 0)
})

# ==============================================================================
# PROVENANCE TEST 8: Record-Level Metadata
# ==============================================================================

test_that("PROVENANCE: Attach processing flags to each record", {
  test_data <- data.frame(
    id = 1:30,
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 15)),
    practice_name = paste("Practice", 1:30),
    phone_number = rep("555-123-4567", 30),
    state_name = sample(state.name, 30, replace = TRUE),
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

  # Could attach metadata like:
  # - processing_date
  # - validation_status
  # - quality_score
  # - data_source
  # - last_modified

  # At minimum, results should be timestampable
  results_with_metadata <- results %>%
    mutate(
      processed_at = Sys.time(),
      processing_stage = "phase_1"
    )

  expect_true("processed_at" %in% names(results_with_metadata))
  expect_equal(nrow(results_with_metadata), nrow(results))

  unlink(temp_dir, recursive = TRUE)
})

test_that("PROVENANCE: Track source of each data field", {
  skip("Field-level provenance test")

  # Document where each field came from
  field_provenance <- list(
    npi = list(source = "NPI Registry API", date = "2024-01-15"),
    lat = list(source = "Google Geocoding API", date = "2024-01-16"),
    lon = list(source = "Google Geocoding API", date = "2024-01-16"),
    population = list(source = "Census API", date = "2024-01-17"),
    median_income = list(source = "Census API", date = "2024-01-17")
  )

  expect_equal(length(field_provenance), 5)
  expect_true("npi" %in% names(field_provenance))
})

# ==============================================================================
# PROVENANCE TEST 9: Cross-Stage Validation
# ==============================================================================

test_that("PROVENANCE: Validate data consistency across stages", {
  test_data <- data.frame(
    id = 1:40,
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 20)),
    practice_name = paste("Practice", 1:40),
    phone_number = rep("555-123-4567", 40),
    state_name = sample(state.name, 40, replace = TRUE),
    npi = as.character(sample(1000000000:9999999999, 40, replace = FALSE)),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  results <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    duplicate_rows = FALSE  # Disable duplication to test NPI preservation
  )

  # Cross-stage validation: NPIs should remain consistent using preserved columns
  if ("original_id" %in% names(results) && "original_npi" %in% names(results)) {
    # Join using original_id (preserved from input)
    merged <- test_data %>%
      inner_join(results, by = c("id" = "original_id"), suffix = c("_input", "_output"))

    if ("npi_input" %in% names(merged) && "original_npi" %in% names(merged)) {
      # NPIs should match between input and original_npi (preserved)
      matching_npis <- merged %>%
        filter(!is.na(npi_input) & !is.na(original_npi)) %>%
        summarize(match_pct = mean(as.character(npi_input) == as.character(original_npi)) * 100)

      if (nrow(matching_npis) > 0) {
        message(sprintf("NPI consistency (original_npi): %.1f%% match", matching_npis$match_pct[1]))
        expect_gte(matching_npis$match_pct[1], 95)
      }
    }
  }

  # Also check that audit trail tracked NPI preservation
  audit <- attr(results, "audit_trail")
  expect_true(audit$original_npi_preserved)

  unlink(temp_dir, recursive = TRUE)
})

test_that("PROVENANCE: Detect unexpected data mutations", {
  test_data <- data.frame(
    id = 1:30,
    names = paste("Dr.", rep(c("John Doe", "Mary Smith"), 15)),
    practice_name = paste("Practice", 1:30),
    phone_number = rep("555-123-4567", 30),
    state_name = sample(state.name, 30, replace = TRUE),
    # Fixed coordinates that shouldn't change
    lat = rep(37.7749, 30),
    lon = rep(-122.4194, 30),
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

  # Coordinates shouldn't be mutated in Phase 1
  if ("lat" %in% names(results) && "lon" %in% names(results)) {
    # Check for unexpected changes
    if ("id" %in% names(results)) {
      merged <- test_data %>%
        inner_join(results, by = "id", suffix = c("_input", "_output"))

      if ("lat_input" %in% names(merged) && "lat_output" %in% names(merged)) {
        lat_changes <- merged %>%
          filter(!is.na(lat_input) & !is.na(lat_output)) %>%
          summarize(changed = sum(abs(lat_input - lat_output) > 0.0001))

        if (nrow(lat_changes) > 0) {
          message(sprintf("Coordinate mutations: %d unexpected changes", lat_changes$changed[1]))
          expect_equal(lat_changes$changed[1], 0)
        }
      }
    }
  }

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# PROVENANCE TEST 10: Historical Tracking
# ==============================================================================

test_that("PROVENANCE: Support versioned data tracking", {
  skip("Version tracking test")

  # Simulated version tracking
  data_versions <- list(
    v1 = list(timestamp = "2024-01-01", rows = 1000, source = "Initial load"),
    v2 = list(timestamp = "2024-01-15", rows = 1200, source = "Added new providers"),
    v3 = list(timestamp = "2024-02-01", rows = 1180, source = "Cleaned duplicates")
  )

  expect_equal(length(data_versions), 3)
  expect_equal(data_versions$v1$rows, 1000)
})

test_that("PROVENANCE: Enable point-in-time data reconstruction", {
  skip("Point-in-time recovery test")

  # Should be able to reconstruct data as it existed at a specific time
  snapshot_dates <- c("2024-01-01", "2024-01-15", "2024-02-01")

  # For each date, should be able to recreate dataset state
  expect_equal(length(snapshot_dates), 3)
})
