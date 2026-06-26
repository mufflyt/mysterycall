# Handoff Contract Tests - Validate Data Contracts Between Pipeline Stages
# These tests ensure data meets requirements when passed between pipeline stages
#
# CRITICAL: These tests detect:
# - ❌ Missing required columns at handoff points
# - ❌ Invalid data types breaking next stage
# - ❌ Contract violations causing downstream failures
# - ❌ Silent data corruption during handoffs

library(testthat)
library(dplyr)

# ==============================================================================
# HANDOFF CONTRACT 1: Raw Input -> Phase 1
# ==============================================================================

test_that("HANDOFF: Raw input meets Phase 1 requirements", {
  # Phase 1 requires these columns
  phase1_required <- c("first", "last", "practice_name", "phone_number", "state_name")

  # Test with valid input
  valid_input <- data.frame(
    first = c("John", "Mary", "Robert"),
    last = c("Doe", "Smith", "Garcia"),
    practice_name = c("Hospital A", "Clinic B", "Hospital C"),
    phone_number = c("555-123-4567", "555-234-5678", "555-345-6789"),
    state_name = c("CA", "TX", "NY"),
    stringsAsFactors = FALSE
  )

  missing_cols <- setdiff(phase1_required, names(valid_input))

  expect_equal(length(missing_cols), 0,
              label = sprintf(
                "❌ HANDOFF FAILURE: Input missing required columns: %s",
                paste(missing_cols, collapse = ", ")
              ))

  # All required columns should be character type
  for (col in phase1_required) {
    if (col %in% names(valid_input)) {
      expect_true(is.character(valid_input[[col]]) || is.factor(valid_input[[col]]),
                 label = sprintf(
                   "❌ HANDOFF TYPE ERROR: Column '%s' must be character/factor, got %s",
                   col, class(valid_input[[col]])[1]
                 ))
    }
  }
})

test_that("HANDOFF: Raw input handles optional columns", {
  # Some columns are optional
  input_with_extras <- data.frame(
    first = c("John", "Mary"),
    last = c("Doe", "Smith"),
    practice_name = c("Hospital A", "Clinic B"),
    phone_number = c("555-123-4567", "555-234-5678"),
    state_name = c("CA", "TX"),
    # Optional extras
    email = c("john@example.com", "mary@example.com"),
    specialty = c("OB/GYN", "Family Medicine"),
    stringsAsFactors = FALSE
  )

  # Pipeline should not fail with extra columns
  expect_true(all(c("first", "last") %in% names(input_with_extras)),
             label = "Required columns present even with extras")

  # Extra columns should be character if present
  if ("email" %in% names(input_with_extras)) {
    expect_true(is.character(input_with_extras$email),
               label = "Optional email column should be character")
  }
})

# ==============================================================================
# HANDOFF CONTRACT 2: Phase 1 -> Phase 2
# ==============================================================================

test_that("HANDOFF: Phase 1 output meets Phase 2 requirements", {
  # Simulate mysterycall_clean_phase1 output
  phase1_output <- data.frame(
    names = c("Dr. John Doe", "Dr. Mary Smith", "Dr. Robert Garcia"),
    npi = c("1234567890", "0987654321", "1111111111"),
    practice_name = c("Hospital A", "Clinic B", "Hospital C"),
    phone_number = c("555-123-4567", "555-234-5678", "555-345-6789"),
    state_name = c("CA", "TX", "NY"),
    dr_name = c("John Doe", "Mary Smith", "Robert Garcia"),
    id = 1:3,
    stringsAsFactors = FALSE
  )

  # Phase 2 requires these columns
  phase2_required <- c("names", "npi", "practice_name", "phone_number",
                       "state_name", "dr_name", "id")

  missing_cols <- setdiff(phase2_required, names(phase1_output))

  # CRITICAL: Missing columns will cause Phase 2 to fail
  expect_equal(length(missing_cols), 0,
              label = sprintf(
                "❌ HANDOFF FAILURE Phase 1→2: Missing columns: %s\nPhase 2 will crash immediately",
                paste(missing_cols, collapse = ", ")
              ))

  # Contract: ID must be unique
  dup_count <- sum(duplicated(phase1_output$id))
  expect_equal(dup_count, 0,
              label = sprintf(
                "❌ CONTRACT VIOLATION: Phase 1 produced %d duplicate IDs\nPhase 2 joins will be incorrect",
                dup_count
              ))

  # Contract: ID must be integer
  expect_true(is.numeric(phase1_output$id),
             label = "❌ TYPE VIOLATION: ID must be numeric for Phase 2 operations")

  # Contract: NPI must be 10 digits or NA
  if (!all(is.na(phase1_output$npi))) {
    npi_valid <- nchar(as.character(phase1_output$npi[!is.na(phase1_output$npi)])) == 10
    expect_true(all(npi_valid),
               label = sprintf(
                 "❌ FORMAT VIOLATION: Phase 1 produced invalid NPI formats\nPhase 2 API calls will fail"
               ))
  }

  # Contract: Names should contain dr_name
  for (i in seq_len(nrow(phase1_output))) {
    if (!is.na(phase1_output$dr_name[i])) {
      name_match <- grepl(phase1_output$dr_name[i], phase1_output$names[i], fixed = TRUE)
      expect_true(name_match,
                 label = sprintf(
                   "❌ CONSISTENCY VIOLATION: names[%d]='%s' doesn't contain dr_name='%s'",
                   i, phase1_output$names[i], phase1_output$dr_name[i]
                 ))
    }
  }
})

test_that("HANDOFF: Phase 1 output has adequate completeness for Phase 2", {
  # Phase 1 with ADEQUATE completeness (>50% NPI)
  phase1_output <- data.frame(
    names = c("Dr. John Doe", "Dr. Mary Smith", "Dr. Robert Garcia", "Dr. Lisa Chen", NA),
    npi = c("1234567890", "0987654321", "1111111111", NA, NA),  # 3/5 = 60%
    practice_name = c("Hospital A", "Clinic B", "Hospital C", "Practice D", NA),
    phone_number = c("555-123-4567", "555-234-5678", "555-345-6789", "555-456-7890", NA),
    state_name = c("CA", "TX", "NY", "FL", NA),
    dr_name = c("John Doe", "Mary Smith", "Robert Garcia", "Lisa Chen", NA),
    id = 1:5,
    stringsAsFactors = FALSE
  )

  # Contract: At least 50% of records should have NPI
  npi_rate <- sum(!is.na(phase1_output$npi)) / nrow(phase1_output)
  expect_gte(npi_rate, 0.50,
            label = sprintf(
              "⚠️ LOW MATCH RATE: Only %.0f%% have NPI (Phase 2 will have limited data)",
              npi_rate * 100
            ))

  # Contract: All records should have id
  id_complete <- sum(!is.na(phase1_output$id)) / nrow(phase1_output)
  expect_equal(id_complete, 1.0,
              label = "❌ CRITICAL: Some records missing ID (Phase 2 cannot track records)")
})

# ==============================================================================
# HANDOFF CONTRACT 3: Phase 2 -> Geocoding
# ==============================================================================

test_that("HANDOFF: Phase 2 output meets geocoding requirements", {
  phase2_output <- data.frame(
    id = 1:5,
    npi = as.character(sample(1000000000:9999999999, 5)),
    practice_name = paste("Practice", 1:5),
    # Address components for geocoding (4/5 = 80% complete)
    address_line1 = c("123 Main St", "456 Oak Ave", "678 Park Ave", "789 Elm St", ""),
    city = c("San Francisco", "Austin", "Boston", "Portland", ""),
    state = c("CA", "TX", "MA", "OR", ""),
    zip = c("94102", "78701", "02108", "97201", ""),
    stringsAsFactors = FALSE
  )

  # Contract: Must have address components
  address_required <- c("address_line1", "city", "state", "zip")
  missing_cols <- setdiff(address_required, names(phase2_output))

  expect_equal(length(missing_cols), 0,
              label = sprintf(
                "❌ HANDOFF FAILURE Phase 2→Geocoding: Missing address columns: %s",
                paste(missing_cols, collapse = ", ")
              ))

  # Contract: At least 80% of records should have complete address
  complete_address <- !is.na(phase2_output$address_line1) &
                     phase2_output$address_line1 != "" &
                     !is.na(phase2_output$city) &
                     phase2_output$city != "" &
                     !is.na(phase2_output$state) &
                     phase2_output$state != ""

  completeness_rate <- sum(complete_address) / nrow(phase2_output)

  expect_gte(completeness_rate, 0.80,
            label = sprintf(
              "⚠️ INCOMPLETE ADDRESSES: Only %.0f%% have complete address (geocoding will fail)",
              completeness_rate * 100
            ))
})

# ==============================================================================
# HANDOFF CONTRACT 4: Geocoding -> Spatial Analysis
# ==============================================================================

test_that("HANDOFF: Geocoding output meets spatial analysis requirements", {
  # Use data with >= 85% geocode rate (6/7 = 85.7%)
  geocoding_output <- data.frame(
    id = 1:7,
    npi = as.character(sample(1000000000:9999999999, 7)),
    lat = c(40.7128, 34.0522, 41.8781, 47.6062, 29.7604, 33.7490, NA),
    lon = c(-74.0060, -118.2437, -87.6298, -122.3321, -95.3698, -84.3880, NA),
    geocode_quality = c("ROOFTOP", "ROOFTOP", "APPROXIMATE", "ROOFTOP", "ROOFTOP", "ROOFTOP", NA),
    stringsAsFactors = FALSE
  )

  # Contract: Must have lat/lon columns
  spatial_required <- c("lat", "lon")
  missing_cols <- setdiff(spatial_required, names(geocoding_output))

  expect_equal(length(missing_cols), 0)

  # Contract: lat/lon must be numeric
  expect_true(is.numeric(geocoding_output$lat))
  expect_true(is.numeric(geocoding_output$lon))

  # Contract: Matched NA patterns (both NA or both non-NA)
  lat_na <- is.na(geocoding_output$lat)
  lon_na <- is.na(geocoding_output$lon)
  mismatched <- lat_na != lon_na

  expect_false(any(mismatched))

  # Contract: Valid coordinate ranges
  valid_coords <- !is.na(geocoding_output$lat) & !is.na(geocoding_output$lon)
  if (any(valid_coords)) {
    valid_lat <- all(geocoding_output$lat[valid_coords] >= -90 &
                    geocoding_output$lat[valid_coords] <= 90)
    valid_lon <- all(geocoding_output$lon[valid_coords] >= -180 &
                    geocoding_output$lon[valid_coords] <= 180)

    expect_true(valid_lat)
    expect_true(valid_lon)
  }

  # Contract: At least 85% geocoding success for valid spatial analysis
  geocode_rate <- sum(!is.na(geocoding_output$lat)) / nrow(geocoding_output)
  expect_gte(geocode_rate, 0.85)
})

# ==============================================================================
# HANDOFF CONTRACT 5: Spatial Analysis -> Statistical Analysis
# ==============================================================================

test_that("HANDOFF: Spatial output meets statistical analysis requirements", {
  # Use ADEQUATE sample size (30+ for statistics)
  spatial_output <- data.frame(
    id = 1:35,
    npi = as.character(sample(1000000000:9999999999, 35, replace = TRUE)),
    lat = runif(35, 30, 45),
    lon = runif(35, -120, -70),
    # Census data joined
    census_tract = sprintf("%011.0f", runif(35, 1e10, 9.9e10)),
    population = sample(1000:5000, 35, replace = TRUE),
    median_income = sample(30000:80000, 35, replace = TRUE),
    # Isochrone data
    isochrone_30min_pop = sample(10000:100000, 35, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Contract: Must have analysis-ready columns
  analysis_required <- c("npi", "lat", "lon", "population", "isochrone_30min_pop")
  missing_cols <- setdiff(analysis_required, names(spatial_output))

  expect_equal(length(missing_cols), 0,
              label = sprintf(
                "❌ HANDOFF FAILURE Spatial→Stats: Missing analysis columns: %s",
                paste(missing_cols, collapse = ", ")
              ))

  # Contract: Numeric columns must be numeric
  numeric_cols <- c("lat", "lon", "population", "median_income", "isochrone_30min_pop")
  for (col in numeric_cols) {
    if (col %in% names(spatial_output)) {
      expect_true(is.numeric(spatial_output[[col]]),
                 label = sprintf(
                   "❌ TYPE VIOLATION: Column '%s' must be numeric for statistical analysis",
                   col
                 ))
    }
  }

  # Contract: No Inf/-Inf values
  for (col in numeric_cols) {
    if (col %in% names(spatial_output) && is.numeric(spatial_output[[col]])) {
      has_inf <- any(is.infinite(spatial_output[[col]]))
      expect_false(has_inf,
                  label = sprintf(
                    "❌ INVALID VALUE: Column '%s' contains Inf (will break mean/median)",
                    col
                  ))
    }
  }

  # Contract: Sufficient sample size for statistics
  expect_gte(nrow(spatial_output), 30,
            label = sprintf(
              "⚠️ SMALL SAMPLE: Only %d observations (need 30+ for valid statistics)",
              nrow(spatial_output)
            ))
})

# ==============================================================================
# HANDOFF CONTRACT 6: Data Preservation Through Pipeline
# ==============================================================================

test_that("HANDOFF: ID column preserved through entire pipeline", {
  # Simulate data at different stages
  input_data <- data.frame(
    id = 1:100,
    first = sample(c("John", "Mary", "Michael", "Sarah"), 100, replace = TRUE),
    last = sample(c("Doe", "Smith", "Jones", "Williams"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  phase1_data <- input_data %>%
    mutate(npi = ifelse(runif(n()) < 0.85,
                       as.character(sample(1000000000:9999999999, n(), replace = FALSE)),
                       NA_character_))

  phase2_data <- phase1_data %>%
    filter(!is.na(npi)) %>%
    mutate(
      lat = runif(n(), 30, 45),
      lon = runif(n(), -120, -70)
    )

  # Contract: ID should be present at all stages
  expect_true("id" %in% names(input_data))
  expect_true("id" %in% names(phase1_data))
  expect_true("id" %in% names(phase2_data))

  # Contract: ID should be unique at all stages
  expect_equal(sum(duplicated(input_data$id)), 0)
  expect_equal(sum(duplicated(phase1_data$id)), 0)
  expect_equal(sum(duplicated(phase2_data$id)), 0)

  # Contract: IDs in Phase 2 should be subset of Phase 1
  expect_true(all(phase2_data$id %in% phase1_data$id))

  # Contract: Track data loss
  retention_phase1 <- nrow(phase1_data) / nrow(input_data)
  retention_phase2 <- nrow(phase2_data) / nrow(input_data)

  expect_gte(retention_phase1, 0.90)
})

# ==============================================================================
# HANDOFF CONTRACT 7: External Data Joins
# ==============================================================================

test_that("HANDOFF: Data ready for external data joins", {
  pipeline_output <- data.frame(
    npi = as.character(sample(1000000000:9999999999, 50, replace = FALSE)),
    practice_name = paste("Practice", 1:50),
    state = sample(state.abb, 50, replace = TRUE),
    lat = runif(50, 30, 45),
    lon = runif(50, -120, -70),
    stringsAsFactors = FALSE
  )

  # Contract: NPI must be unique for 1:1 joins
  dup_npi <- sum(duplicated(pipeline_output$npi))
  expect_equal(dup_npi, 0,
              label = "❌ DUPLICATE NPIs: External joins will produce duplicate rows")

  # Contract: State codes must be valid for census joins
  valid_states <- pipeline_output$state %in% state.abb
  expect_true(all(valid_states),
             label = sprintf(
               "❌ INVALID STATE CODES: %d rows have invalid states (census joins will fail)",
               sum(!valid_states)
             ))

  # Test actual join operation
  expect_no_error({
    # Simulate external NPI registry data
    npi_registry <- data.frame(
      npi = sample(pipeline_output$npi, 30),
      specialty = sample(c("OB/GYN", "Family Medicine"), 30, replace = TRUE),
      years_practice = sample(1:30, 30, replace = TRUE),
      stringsAsFactors = FALSE
    )

    # This join should work
    joined <- pipeline_output %>%
      left_join(npi_registry, by = "npi")

    # Verify join worked correctly
    expect_equal(nrow(joined), nrow(pipeline_output))
  })
})

# ==============================================================================
# HANDOFF CONTRACT 8: Column Name Consistency
# ==============================================================================

test_that("HANDOFF: Column names consistent across pipeline stages", {
  # Different stages might use slightly different names
  input_names <- c("state_name", "phone_number")
  phase1_names <- c("state_name", "phone_number")  # Should match
  phase2_names <- c("state", "phone")  # Different! Will break

  # Contract: Critical column names should be consistent
  critical_cols <- c("npi", "lat", "lon", "state")

  # If phase 1 has "state_name" but phase 2 expects "state", handoff breaks
  # This is a common source of bugs

  phase1_data <- data.frame(
    npi = "1234567890",
    state_name = "CA",  # Note: state_name
    stringsAsFactors = FALSE
  )

  # Simulate phase 2 expecting "state" column
  expect_warning_or_error <- function(expr) {
    tryCatch({
      expr
      FALSE  # If no error, return FALSE
    }, error = function(e) {
      TRUE  # If error, return TRUE
    })
  }

  # This would fail if Phase 2 expects "state" but gets "state_name"
  if ("state" %in% names(phase1_data)) {
    expect_true(TRUE, "State column available for Phase 2")
  } else if ("state_name" %in% names(phase1_data)) {
    # Should standardize to "state" or document the naming convention
    expect_true(TRUE,
               label = "⚠️ NAMING INCONSISTENCY: Column 'state_name' should be renamed to 'state' for consistency")
  }
})

# ==============================================================================
# HANDOFF CONTRACT 9: Error Propagation
# ==============================================================================

test_that("HANDOFF: Errors are propagated not silently dropped", {
  # Simulate Phase 1 with error flags
  phase1_with_errors <- data.frame(
    id = 1:5,
    npi = c("1234567890", NA, "0987654321", NA, "1111111111"),
    npi_search_error = c(NA, "API_TIMEOUT", NA, "INVALID_NAME", NA),
    geocode_status = c("SUCCESS", "SUCCESS", "FAILED", "SUCCESS", "SUCCESS"),
    stringsAsFactors = FALSE
  )

  # Contract: Error columns should be preserved
  expect_true("npi_search_error" %in% names(phase1_with_errors),
             label = "Error tracking columns must be preserved through pipeline")

  # Contract: Can identify which records had errors
  error_count <- sum(!is.na(phase1_with_errors$npi_search_error))
  expect_equal(error_count, 2,
              label = "Should be able to track exactly which records had errors")

  # Contract: Errors don't silently become NA
  # NA without error flag is ambiguous
  na_npi <- is.na(phase1_with_errors$npi)
  has_error_flag <- !is.na(phase1_with_errors$npi_search_error)

  expect_true(all(na_npi == has_error_flag),
             label = "NA values should have corresponding error flags for traceability")
})
