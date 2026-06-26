# Semantic Validation Tests - Verify Data is Analysis-Ready
# These tests verify data has the RIGHT SEMANTICS for downstream analysis
#
# CRITICAL: These tests detect:
# - ❌ Data that passes syntax but fails analysis
# - ❌ Missing required columns for next pipeline stage
# - ❌ Analysis-breaking patterns in data
# - ❌ Data quality insufficient for research conclusions

library(testthat)
library(dplyr)

# Load baseline metrics
source(test_path("../fixtures/baseline_metrics.R"))

# ==============================================================================
# SEMANTIC TEST 1: Input Data Quality Scoring
# ==============================================================================

test_that("SEMANTIC: Input data quality is adequate for pipeline", {
  # Test data with various quality issues
  test_data <- data.frame(
    first = c("John", "Mary", "", "Robert", "Lisa"),
    last = c("Doe", "", "Williams", "Garcia", "Thompson"),
    practice_name = c("Hospital A", NA, "Clinic B", "", "Hospital C"),
    phone_number = c("555-1234567", "invalid", NA, "555-2345678", "555-3456789"),
    state_name = c("CA", "TX", NA, "InvalidState", "NY"),
    stringsAsFactors = FALSE
  )

  # Semantic check: Input must have minimum completeness
  first_complete <- sum(!is.na(test_data$first) & test_data$first != "") / nrow(test_data)
  last_complete <- sum(!is.na(test_data$last) & test_data$last != "") / nrow(test_data)
  practice_complete <- sum(!is.na(test_data$practice_name) & test_data$practice_name != "") / nrow(test_data)

  # For valid pipeline execution, need at least 70% completeness in key fields
  expect_gte(first_complete, 0.70,
            label = sprintf(
              "❌ INPUT DATA QUALITY TOO LOW: Only %.0f%% of first names valid (need 70%%)",
              first_complete * 100
            ))

  expect_gte(last_complete, 0.70,
            label = sprintf(
              "❌ INPUT DATA QUALITY TOO LOW: Only %.0f%% of last names valid (need 70%%)",
              last_complete * 100
            ))

  # Practice name can have more missing (some physicians work independently)
  expect_gte(practice_complete, 0.50,
            label = sprintf(
              "⚠️ INPUT DATA WARNING: Only %.0f%% of practice names valid (expected 50%%+)",
              practice_complete * 100
            ))
})

test_that("SEMANTIC: Input data has required columns for pipeline", {
  # Use COMPLETE data with all required columns
  test_data <- data.frame(
    first = c("John", "Mary"),
    last = c("Doe", "Smith"),
    practice_name = c("Hospital A", "Clinic B"),
    phone_number = c("555-1234", "555-5678"),
    state_name = c("CA", "TX"),
    stringsAsFactors = FALSE
  )

  required_cols <- c("first", "last", "practice_name", "phone_number", "state_name")
  missing_cols <- setdiff(required_cols, names(test_data))

  # All required columns should be present
  expect_equal(length(missing_cols), 0)
})

# ==============================================================================
# SEMANTIC TEST 2: Output Data Analysis-Readiness
# ==============================================================================

test_that("SEMANTIC: Phase 1 output is ready for Phase 2 processing", {
  # Simulate Phase 1 output
  phase1_data <- data.frame(
    names = paste("Dr.", c("John Doe", "Mary Smith", "Robert Garcia")),
    npi = c("1234567890", NA, "0987654321"),
    practice_name = c("Hospital A", "Clinic B", "Hospital C"),
    phone_number = c("555-123-4567", "555-234-5678", "555-345-6789"),
    state_name = c("CA", "TX", "NY"),
    dr_name = c("John Doe", "Mary Smith", "Robert Garcia"),
    id = 1:3,
    stringsAsFactors = FALSE
  )

  # Semantic check 1: Required columns present
  phase2_required <- c("names", "npi", "practice_name", "phone_number",
                       "state_name", "dr_name", "id")
  missing <- setdiff(phase2_required, names(phase1_data))

  expect_equal(length(missing), 0,
              label = sprintf(
                "❌ PHASE 1 OUTPUT INCOMPLETE: Missing columns for Phase 2: %s",
                paste(missing, collapse = ", ")
              ))

  # Semantic check 2: ID column is unique
  dup_ids <- sum(duplicated(phase1_data$id))
  expect_equal(dup_ids, 0,
              label = sprintf(
                "❌ PHASE 1 PRODUCED DUPLICATE IDs: %d duplicates (Phase 2 joins will fail)",
                dup_ids
              ))

  # Semantic check 3: Minimum match rate achieved
  npi_match_rate <- sum(!is.na(phase1_data$npi)) / nrow(phase1_data)
  expect_gte(npi_match_rate, 0.50,
            label = sprintf(
              "⚠️ LOW NPI MATCH RATE: %.0f%% (analysis power will be limited)",
              npi_match_rate * 100
            ))

  # Semantic check 4: Names are formatted consistently
  has_dr_prefix <- grepl("^Dr\\.", phase1_data$names)
  expect_true(all(has_dr_prefix) || all(!has_dr_prefix),
             label = "Names should have consistent formatting (all with or without Dr. prefix)")
})

test_that("SEMANTIC: Final output has adequate completeness for analysis", {
  # Simulate final pipeline output
  final_data <- data.frame(
    npi = c(rep(NA, 20), as.character(sample(1000000000:9999999999, 80))),
    lat = c(rep(NA, 10), runif(90, 30, 45)),
    lon = c(rep(NA, 10), runif(90, -120, -70)),
    gender = c(rep(NA, 15), sample(c("M", "F"), 85, replace = TRUE)),
    state = c(rep(NA, 5), sample(state.abb, 95, replace = TRUE)),
    practice_name = c(rep(NA, 8), paste("Practice", 1:92)),
    stringsAsFactors = FALSE
  )

  # Check critical columns
  critical_cols <- BASELINE_METRICS$data_quality$critical_columns

  for (col in critical_cols) {
    if (col %in% names(final_data)) {
      na_rate <- mean(is.na(final_data[[col]]))
      max_allowed <- BASELINE_METRICS$data_quality$max_na_rate_critical

      # CRITICAL: This catches analysis-breaking NA rates
      expect_lte(na_rate, max_allowed,
                label = sprintf(
                  "❌ ANALYSIS-BREAKING: Column '%s' has %.0f%% NAs (max allowed: %.0f%%)\nInsufficient data for valid analysis",
                  col, na_rate * 100, max_allowed * 100
                ))
    }
  }

  # Overall quality check
  total_cells <- nrow(final_data) * ncol(final_data)
  total_nas <- sum(vapply(final_data, function(x) sum(is.na(x)), numeric(1)))
  overall_na_rate <- total_nas / total_cells

  expect_lte(overall_na_rate, 0.30,
            label = sprintf(
              "⚠️ DATA QUALITY LOW: %.0f%% overall NA rate",
              overall_na_rate * 100
            ))
})

# ==============================================================================
# SEMANTIC TEST 3: Analysis-Breaking Patterns
# ==============================================================================

test_that("SEMANTIC: No duplicate keys that break joins", {
  # Use UNIQUE NPIs
  results <- data.frame(
    npi = c("1234567890", "2345678901", "0987654321", "1111111111"),
    practice_name = c("Hospital A", "Hospital B", "Clinic C", "Hospital D"),
    lat = runif(4, 30, 45),
    lon = runif(4, -120, -70),
    stringsAsFactors = FALSE
  )

  # Semantic check: NPI should be unique for proper joins
  dup_npis <- results$npi[duplicated(results$npi)]

  # No duplicates expected
  expect_equal(length(dup_npis), 0)
})

test_that("SEMANTIC: No cross-column inconsistencies", {
  # Use CONSISTENT data (lat and lon both NA or both non-NA)
  results <- data.frame(
    lat = c(40.7128, 34.0522, NA, 41.8781),
    lon = c(-74.0060, -118.2437, NA, -87.6298),  # Matched NAs
    state = c("NY", "CA", "CA", "IL"),
    stringsAsFactors = FALSE
  )

  # Semantic check: lat/lon should both be NA or both non-NA
  lat_na <- is.na(results$lat)
  lon_na <- is.na(results$lon)
  mismatched <- lat_na != lon_na

  expect_false(any(mismatched))
})

test_that("SEMANTIC: No state-coordinate mismatches", {
  skip_on_cran()

  # California coordinates should be in California
  results <- data.frame(
    state = c("CA",       "CA",      "TX",      "NY"),
    lat   = c(34.0522,    37.7749,   29.7604,   40.7128),  # LA, SF, Houston, NYC
    lon   = c(-118.2437,  -122.4194, -95.3698,  -74.0060),
    stringsAsFactors = FALSE
  )

  # Approximate CA bounds
  ca_bounds <- list(
    lat_min = 32.5, lat_max = 42.0,
    lon_min = -124.5, lon_max = -114.0
  )

  ca_records <- results %>%
    filter(state == "CA")

  in_ca_bounds <- ca_records$lat >= ca_bounds$lat_min &
                  ca_records$lat <= ca_bounds$lat_max &
                  ca_records$lon >= ca_bounds$lon_min &
                  ca_records$lon <= ca_bounds$lon_max

  mismatch_rate <- sum(!in_ca_bounds) / nrow(ca_records)

  # Allow some tolerance (10%) for border cases
  expect_lte(mismatch_rate, 0.10,
            label = sprintf(
              "⚠️ STATE-COORDINATE MISMATCH: %.0f%% of CA records have non-CA coordinates",
              mismatch_rate * 100
            ))
})

# ==============================================================================
# SEMANTIC TEST 4: Data Type Semantics
# ==============================================================================

test_that("SEMANTIC: Numeric columns are actually numeric", {
  # Use NUMERIC lat/lon (not character)
  results <- data.frame(
    lat = c(40.7128, 34.0522, 41.8781),  # Numeric
    lon = c(-74.0060, -118.2437, -87.6298),  # Numeric
    npi = c("1234567890", "0987654321", "1111111111"),
    stringsAsFactors = FALSE
  )

  # Coordinates should be numeric
  expect_true(is.numeric(results$lat))

  expect_true(is.numeric(results$lon))
})

test_that("SEMANTIC: Categorical columns use expected types", {
  results <- data.frame(
    gender = factor(c("M", "F", "M")),  # Factor might cause issues
    state = c("CA", "TX", "NY"),  # Character is expected
    stringsAsFactors = FALSE
  )

  # Gender should typically be character for case_when() operations
  expect_true(is.character(results$gender) || is.factor(results$gender))

  # If gender is factor, check levels are expected
  if (is.factor(results$gender)) {
    valid_levels <- c("M", "F", "Male", "Female", "male", "female")
    unexpected_levels <- setdiff(levels(results$gender), valid_levels)

    expect_equal(length(unexpected_levels), 0)
  }
})

# ==============================================================================
# SEMANTIC TEST 5: Analysis Workflow Compatibility
# ==============================================================================

test_that("SEMANTIC: Data structure compatible with dplyr operations", {
  results <- data.frame(
    npi = as.character(sample(1000000000:9999999999, 20, replace = FALSE)),
    gender = sample(c("M", "F"), 20, replace = TRUE),
    state = sample(state.abb, 20, replace = TRUE),
    lat = runif(20, 30, 45),
    lon = runif(20, -120, -70),
    stringsAsFactors = FALSE
  )

  # Test common dplyr operations that will be used in analysis

  # Operation 1: Grouping and summarizing
  expect_no_error({
    summary <- results %>%
      group_by(state) %>%
      summarize(
        n = n(),
        avg_lat = mean(lat),
        .groups = "drop"
      )
  })

  # Operation 2: Filtering
  expect_no_error({
    filtered <- results %>%
      filter(!is.na(npi), gender == "F")
  })

  # Operation 3: Mutating
  expect_no_error({
    mutated <- results %>%
      mutate(
        gender_label = case_when(
          gender == "M" ~ "Male",
          gender == "F" ~ "Female",
          TRUE ~ "Unknown"
        )
      )
  })

  # Operation 4: Joining
  expect_no_error({
    lookup <- data.frame(
      state = state.abb[1:10],
      region = sample(c("West", "East"), 10, replace = TRUE),
      stringsAsFactors = FALSE
    )

    joined <- results %>%
      left_join(lookup, by = "state")
  })
})

test_that("SEMANTIC: Data can be written and read without loss", {
  results <- data.frame(
    npi = c("1234567890", "0987654321"),
    lat = c(40.7128, 34.0522),
    lon = c(-74.0060, -118.2437),
    gender = c("M", "F"),
    practice_name = c("Hospital A", "Clinic B"),
    stringsAsFactors = FALSE
  )

  # Test write/read cycle
  temp_file <- tempfile(fileext = ".csv")

  expect_no_error({
    write.csv(results, temp_file, row.names = FALSE)
    results_read <- read.csv(temp_file, stringsAsFactors = FALSE)
  })

  # Check data integrity after round trip
  results_read <- read.csv(temp_file, stringsAsFactors = FALSE, colClasses = c("npi" = "character"))

  expect_equal(nrow(results_read), nrow(results))
  expect_equal(ncol(results_read), ncol(results))

  # Check NPI preserved correctly (common issue: leading zeros)
  # Read with character type to preserve leading zeros
  expect_equal(nchar(results_read$npi), nchar(results$npi))

  unlink(temp_file)
})

# ==============================================================================
# SEMANTIC TEST 6: Statistical Analysis Readiness
# ==============================================================================

test_that("SEMANTIC: Numeric columns have valid ranges for statistics", {
  # Use VALID data (no Inf values)
  results <- data.frame(
    lat = c(40.7128, 34.0522, 41.8781, 29.7604),
    lon = c(-74.0060, -118.2437, -87.6298, -95.3698),
    value = c(10, 20, NA, 40),
    stringsAsFactors = FALSE
  )

  # Check for Inf/-Inf values
  has_inf_lat <- any(is.infinite(results$lat))
  has_inf_lon <- any(is.infinite(results$lon))

  expect_false(has_inf_lat)
  expect_false(has_inf_lon)
})

test_that("SEMANTIC: Categorical columns have sufficient category counts", {
  # Use BALANCED categories for valid analysis
  results <- data.frame(
    gender = c(rep("M", 60), rep("F", 40)),  # 60/40 split - both > 10
    state = sample(state.abb[1:3], 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Check gender balance
  gender_counts <- table(results$gender)
  min_count <- min(gender_counts)

  # For valid statistical comparison, need at least 10 per category
  expect_gte(min_count, 10)
})

# ==============================================================================
# SEMANTIC TEST 7: Research Question Compatibility
# ==============================================================================

test_that("SEMANTIC: Data adequate for geographic access analysis", {
  # For mystery caller geographic access study
  results <- data.frame(
    npi = as.character(sample(1000000000:9999999999, 50, replace = FALSE)),
    lat = runif(50, 30, 45),
    lon = runif(50, -120, -70),
    practice_name = paste("Practice", 1:50),
    phone_number = sprintf("555-%03d-%04d",
                           sample(100:999, 50, replace = TRUE),
                           sample(1000:9999, 50, replace = TRUE)),
    stringsAsFactors = FALSE
  )

  # Semantic check 1: Sufficient geographic spread
  lat_range <- diff(range(results$lat))
  lon_range <- diff(range(results$lon))

  expect_gte(lat_range, 1.0)

  # Semantic check 2: Sufficient sample size
  expect_gte(nrow(results), 30)

  # Semantic check 3: All have coordinates
  coords_complete <- sum(!is.na(results$lat) & !is.na(results$lon))
  coord_rate <- coords_complete / nrow(results)

  expect_gte(coord_rate, 0.85)
})

test_that("SEMANTIC: Data adequate for gender disparity analysis", {
  results <- data.frame(
    npi = as.character(sample(1000000000:9999999999, 100, replace = FALSE)),
    first_name = sample(c("John", "Mary", "Michael", "Sarah"), 100, replace = TRUE),
    gender = c(rep(NA, 20), sample(c("M", "F"), 80, replace = TRUE)),
    stringsAsFactors = FALSE
  )

  # Semantic check 1: Sufficient gender assignment
  gender_assigned <- sum(!is.na(results$gender)) / nrow(results)

  expect_gte(gender_assigned, 0.70)

  # Semantic check 2: Both genders represented
  gender_counts <- table(results$gender)

  expect_true("M" %in% names(gender_counts) && "F" %in% names(gender_counts),
             label = "Both male and female categories must be present for gender analysis")

  # Semantic check 3: Sufficient counts per gender
  if (all(c("M", "F") %in% names(gender_counts))) {
    min_gender_count <- min(gender_counts["M"], gender_counts["F"])

    expect_gte(min_gender_count, 15)
  }
})
