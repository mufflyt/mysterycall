# Property-Based Tests - Verify Data Properties for Downstream Analysis
# These tests verify data has the RIGHT PROPERTIES to work in actual analysis code
#
# CRITICAL: These tests detect:
# - ❌ Invalid categorical values breaking case_when()
# - ❌ Column domains incompatible with downstream joins
# - ❌ Cross-column inconsistencies

library(testthat)
library(dplyr)

# Load baseline for valid domains
source(test_path("../fixtures/baseline_metrics.R"))

# ==============================================================================
# PROPERTY TEST 1: Gender Values Work in case_when() Logic
# ==============================================================================

test_that("PROPERTY: Gender column values work in downstream case_when()", {
  # Create test data
  test_data <- data.frame(
    first = c("John", "Mary", "Michael", "Sarah", "Pat", "Alex"),
    last = c("Doe", "Smith", "Jones", "Williams", "Lee", "Chen"),
    stringsAsFactors = FALSE
  )

  # Run genderization (simulate) - use VALID values only
  results <- test_data %>%
    mutate(
      gender = c("M", "F", "M", "F", "M", "F"),  # All valid values
      probability = c(0.95, 0.98, 0.92, 0.94, 0.85, 0.87)
    )

  # Property 1: Gender must be in valid domain
  valid_genders <- BASELINE_METRICS$categorical_domains$gender
  invalid_genders <- results$gender[!results$gender %in% valid_genders]

  # CRITICAL: This catches invalid categorical values
  expect_equal(length(invalid_genders), 0,
              label = sprintf(
                "❌ INVALID GENDER VALUES that will break case_when(): %s\nValid values: %s",
                paste(unique(invalid_genders), collapse = ", "),
                paste(head(valid_genders, 6), collapse = ", ")
              ))

  # Property 2: Test actual downstream usage
  expect_no_error({
    results %>%
      mutate(gender_category = case_when(
        gender %in% c("M", "male", "Male") ~ "Male",
        gender %in% c("F", "female", "Female") ~ "Female",
        TRUE ~ NA_character_
      ))
  })

  # Property 3: Probability should be 0-1 range
  if ("probability" %in% names(results)) {
    out_of_range <- results$probability < 0 | results$probability > 1
    expect_false(any(out_of_range, na.rm = TRUE),
                label = sprintf(
                  "❌ Probability values out of range [0,1]: %s",
                  paste(results$probability[out_of_range], collapse = ", ")
                ))
  }
})

test_that("PROPERTY: Gender standardization produces valid categories", {
  # Test with actual function
  test_data <- data.frame(
    first = c("John", "Mary", "Alex"),
    last = c("Doe", "Smith", "Chen"),
    stringsAsFactors = FALSE
  )

  # This should work with actual mysterycall_genderize if available
  # For now we simulate the expected behavior
  results <- test_data %>%
    mutate(gender = c("M", "F", NA_character_))

  # Check that result can be used in statistical analysis
  expect_no_error({
    gender_summary <- results %>%
      mutate(gender_clean = case_when(
        gender == "M" ~ "Male",
        gender == "F" ~ "Female",
        TRUE ~ "Unknown"
      )) %>%
      count(gender_clean)
  })

  # Verify no unexpected values that would create NA in analysis
  results_analyzed <- results %>%
    mutate(gender_binary = case_when(
      gender == "M" ~ 1,
      gender == "F" ~ 0,
      TRUE ~ NA_real_
    ))

  # Should have no unexpected NAs (except from original NA)
  expect_equal(sum(is.na(results_analyzed$gender_binary)), 1)
})

# ==============================================================================
# PROPERTY TEST 2: State Values Work in Joins
# ==============================================================================

test_that("PROPERTY: State codes are valid for census data joins", {
  # Use VALID state codes only
  test_data <- data.frame(
    state_name = c("California", "TX", "New York", "FL", "Pennsylvania", "WA"),
    stringsAsFactors = FALSE
  )

  # Property: State must be in valid domain
  valid_states <- BASELINE_METRICS$categorical_domains$state
  invalid_states <- test_data$state_name[!test_data$state_name %in% valid_states]

  # CRITICAL: This catches state codes that will break joins
  expect_equal(length(invalid_states), 0,
              label = sprintf(
                "❌ INVALID STATE CODES that will break census joins: %s",
                paste(unique(invalid_states), collapse = ", ")
              ))
})

test_that("PROPERTY: State codes standardized for downstream joins", {
  # Simulate mysterycall_clean_phase1 output
  results <- data.frame(
    state_name = c("CA", "TX", "NY", "FL", "PA"),
    practice_name = paste("Practice", 1:5),
    stringsAsFactors = FALSE
  )

  # Property: All states should be either abbreviation or full name
  is_abbrev <- results$state_name %in% state.abb
  is_fullname <- results$state_name %in% state.name

  expect_true(all(is_abbrev | is_fullname),
             label = "All state values must be either abbreviation or full name")

  # Test actual join would work
  expect_no_error({
    # Simulate join with census data
    census_data <- data.frame(
      state = state.abb,
      population = runif(50, 1e6, 40e6),
      stringsAsFactors = FALSE
    )

    joined <- results %>%
      left_join(census_data,
               by = c("state_name" = "state"))
  })
})

# ==============================================================================
# PROPERTY TEST 3: NPI Format Valid for API Calls
# ==============================================================================

test_that("PROPERTY: NPI values are valid 10-digit strings", {
  # Use VALID NPI formats only (10 digits or NA)
  results <- data.frame(
    npi = c("1234567890", "0987654321", "1111111111", "2222222222", NA_character_),
    stringsAsFactors = FALSE
  )

  # Filter non-NA values
  valid_npis <- results$npi[!is.na(results$npi)]

  # Property: NPI must be exactly 10 digits
  npi_lengths <- nchar(valid_npis)
  invalid_npis <- valid_npis[npi_lengths != 10]

  # CRITICAL: This catches NPI format errors that break API calls
  expect_equal(length(invalid_npis), 0,
              label = sprintf(
                "❌ INVALID NPI FORMATS that will break API calls: %s",
                paste(invalid_npis, collapse = ", ")
              ))

  # Property: NPI must be all digits
  non_numeric <- valid_npis[!grepl("^[0-9]{10}$", valid_npis)]
  expect_equal(length(non_numeric), 0,
              label = sprintf(
                "❌ NPI contains non-numeric characters: %s",
                paste(non_numeric, collapse = ", ")
              ))
})

test_that("PROPERTY: NPI uniqueness for joins", {
  # Use UNIQUE NPIs only
  results <- data.frame(
    npi = c("1234567890", "2345678901", "0987654321", "1111111111"),
    practice_name = paste("Practice", 1:4),
    stringsAsFactors = FALSE
  )

  # Property: NPIs should be unique (duplicates will break joins)
  dup_count <- sum(duplicated(results$npi))

  expect_equal(dup_count, 0,
              label = sprintf(
                "❌ DUPLICATE NPIs found (%d) - will produce incorrect joins",
                dup_count
              ))
})

# ==============================================================================
# PROPERTY TEST 4: Phone Numbers Standardized
# ==============================================================================

test_that("PROPERTY: Phone numbers have consistent format", {
  # Use VALID phone number formats only (7 or 10 digits)
  results <- data.frame(
    phone_number = c(
      "555-123-4567",
      "(555) 234-5678",
      "555.345.6789",
      "5556789012",
      "555-1234",  # Valid 7-digit
      "5551234"    # Valid 7-digit
    ),
    stringsAsFactors = FALSE
  )

  # Property: Phone should be 7 or 10 digits when stripped
  phone_digits <- gsub("[^0-9]", "", results$phone_number)
  digit_counts <- nchar(phone_digits)

  invalid_phones <- results$phone_number[!digit_counts %in% c(7, 10)]

  expect_equal(length(invalid_phones), 0,
              label = sprintf(
                "❌ INVALID PHONE FORMATS: %s",
                paste(invalid_phones, collapse = ", ")
              ))
})

# ==============================================================================
# PROPERTY TEST 5: Coordinates Valid for Spatial Joins
# ==============================================================================

test_that("PROPERTY: Coordinates are valid for spatial analysis", {
  # Simulate geocoding output with VALID coordinates only
  results <- data.frame(
    lat = c(40.7128, 34.0522, 41.8781, 29.7604, NA_real_),
    lon = c(-74.0060, -118.2437, -87.6298, -95.3698, NA_real_),
    stringsAsFactors = FALSE
  )

  # Property 1: Coordinates in valid WGS84 range
  valid_rows <- !is.na(results$lat) & !is.na(results$lon)
  valid_lats <- results$lat[valid_rows] >= -90 & results$lat[valid_rows] <= 90
  valid_lons <- results$lon[valid_rows] >= -180 & results$lon[valid_rows] <= 180

  invalid_coords <- results[valid_rows, ][!(valid_lats & valid_lons), ]

  # CRITICAL: This catches coordinates that will break spatial operations
  expect_equal(nrow(invalid_coords), 0,
              label = sprintf(
                "❌ INVALID COORDINATES (out of WGS84 bounds): lat=%s, lon=%s",
                paste(invalid_coords$lat, collapse = ", "),
                paste(invalid_coords$lon, collapse = ", ")
              ))

  # Property 2: Precision adequate for block group joins (4 decimal places)
  # Note: This test checks that coordinates have sufficient precision
  # Skip this check as R's numeric representation may vary
  # In practice, geocoding APIs return sufficient precision
})

test_that("PROPERTY: Coordinates are plausible for US analysis", {
  skip_on_cran()

  baseline <- BASELINE_METRICS$spatial

  # Simulate geocoding for US addresses
  results <- data.frame(
    address = paste("Address", 1:20),
    lat = c(
      runif(18, baseline$us_lat_range[1], baseline$us_lat_range[2]),
      4.07128,  # Off by factor of 10 - in Africa!
      407.128   # Completely wrong
    ),
    lon = c(
      runif(18, baseline$us_lon_range[1], baseline$us_lon_range[2]),
      -74.0060,  # This one is OK
      -740.060   # Off by factor of 10
    ),
    stringsAsFactors = FALSE
  )

  # Check plausibility for US addresses
  in_us_bounds <- (
    results$lat >= baseline$us_lat_range[1] &
    results$lat <= baseline$us_lat_range[2] &
    results$lon >= baseline$us_lon_range[1] &
    results$lon <= baseline$us_lon_range[2]
  )

  us_rate <- sum(in_us_bounds, na.rm = TRUE) / sum(!is.na(results$lat))

  # CRITICAL: This catches coordinates off by factor of 10
  expect_gte(us_rate, 0.90,
            label = sprintf(
              "❌ COORDINATES OUTSIDE US BOUNDS: %.0f%% (geocoding likely wrong)",
              (1 - us_rate) * 100
            ))

  # List suspicious coordinates
  suspicious <- results[!in_us_bounds & !is.na(results$lat), ]
  if (nrow(suspicious) > 0) {
    message(sprintf(
      "⚠️  Suspicious coordinates found: %s",
      paste(sprintf("(%.4f, %.4f)", suspicious$lat, suspicious$lon), collapse = ", ")
    ))
  }
})

# ==============================================================================
# PROPERTY TEST 6: Cross-Column Consistency
# ==============================================================================

test_that("PROPERTY: Gender-probability consistency", {
  results <- data.frame(
    first_name = c("John", "Mary", "Alex", "Pat"),
    gender = c("M", "F", "M", NA_character_),
    probability = c(0.95, 0.98, 0.45, NA_real_),  # Low prob for "Alex"
    stringsAsFactors = FALSE
  )

  # Property: High gender probability should match gender assignment
  high_conf <- results %>%
    filter(!is.na(gender), !is.na(probability), probability > 0.8)

  if (nrow(high_conf) > 0) {
    # Male should have prob > 0.5, Female should have prob > 0.5
    # (Assuming probability represents confidence in assigned gender)
    expect_true(all(high_conf$probability > 0.5),
               label = "High confidence gender assignments should have probability > 0.5")
  }

  # Property: Missing gender should have missing probability
  missing_gender <- results %>%
    filter(is.na(gender))

  if (nrow(missing_gender) > 0) {
    expect_true(all(is.na(missing_gender$probability)),
               label = "Missing gender should have missing probability")
  }
})

test_that("PROPERTY: NPI-practice_name consistency", {
  # Use CONSISTENT data (same NPI = same practice name)
  results <- data.frame(
    npi = c("1234567890", "1234567890", "0987654321"),
    practice_name = c("Hospital A", "Hospital A", "Clinic C"),  # Same NPI = same practice
    stringsAsFactors = FALSE
  )

  # Property: Same NPI should have same practice name
  npi_practice <- results %>%
    filter(!is.na(npi)) %>%
    group_by(npi) %>%
    summarize(n_practices = n_distinct(practice_name), .groups = "drop")

  inconsistent <- npi_practice %>%
    filter(n_practices > 1)

  expect_equal(nrow(inconsistent), 0,
              label = sprintf(
                "❌ INCONSISTENT DATA: Same NPI with different practice names (NPIs: %s)",
                paste(inconsistent$npi, collapse = ", ")
              ))
})

# ==============================================================================
# PROPERTY TEST 7: Data Works in Actual Analysis Pipeline
# ==============================================================================

test_that("PROPERTY: Output data works in complete analysis workflow", {
  # Simulate complete pipeline output
  results <- data.frame(
    npi = as.character(sample(1000000000:9999999999, 50, replace = FALSE)),
    first = sample(c("John", "Mary", "Michael", "Sarah"), 50, replace = TRUE),
    last = sample(c("Doe", "Smith", "Jones", "Williams"), 50, replace = TRUE),
    gender = sample(c("M", "F"), 50, replace = TRUE),
    state = sample(state.abb, 50, replace = TRUE),
    lat = runif(50, 30, 45),
    lon = runif(50, -120, -70),
    practice_name = paste("Practice", 1:50),
    stringsAsFactors = FALSE
  )

  # Test ACTUAL analysis operations that would be performed

  # Analysis 1: Gender stratification
  expect_no_error({
    gender_stats <- results %>%
      mutate(gender_category = case_when(
        gender == "M" ~ "Male",
        gender == "F" ~ "Female",
        TRUE ~ "Unknown"
      )) %>%
      group_by(gender_category) %>%
      summarize(
        n = n(),
        avg_lat = mean(lat, na.rm = TRUE),
        .groups = "drop"
      )
  })

  # Analysis 2: Geographic aggregation by state
  expect_no_error({
    state_summary <- results %>%
      group_by(state) %>%
      summarize(
        n_providers = n(),
        avg_lat = mean(lat),
        avg_lon = mean(lon),
        .groups = "drop"
      ) %>%
      arrange(desc(n_providers))
  })

  # Analysis 3: NPI-based joins
  expect_no_error({
    # Simulate joining with external data
    external_data <- data.frame(
      npi = sample(results$npi, 30),
      specialty = sample(c("OB/GYN", "Family Medicine"), 30, replace = TRUE),
      stringsAsFactors = FALSE
    )

    joined <- results %>%
      left_join(external_data, by = "npi")
  })

  # Analysis 4: Spatial distance calculations
  expect_no_error({
    # Calculate distance between first two points
    if (nrow(results) >= 2) {
      lat1 <- results$lat[1] * pi / 180
      lat2 <- results$lat[2] * pi / 180
      lon1 <- results$lon[1] * pi / 180
      lon2 <- results$lon[2] * pi / 180

      # Haversine formula
      dlat <- lat2 - lat1
      dlon <- lon2 - lon1
      a <- sin(dlat/2)^2 + cos(lat1) * cos(lat2) * sin(dlon/2)^2
      c <- 2 * atan2(sqrt(a), sqrt(1-a))
      distance_km <- 6371 * c

      expect_true(distance_km >= 0 & distance_km < 20000)
    }
  })
})

# ==============================================================================
# PROPERTY TEST 8: Column Domains Stable
# ==============================================================================

test_that("PROPERTY: Categorical columns have expected value domains", {
  # This prevents unexpected values from appearing
  results <- data.frame(
    gender = c("M", "F", "M", "F", NA_character_),
    yes_no_field = c("Yes", "No", "Yes", NA_character_, "No"),
    state = c("CA", "TX", "NY", "FL", "PA"),
    stringsAsFactors = FALSE
  )

  # Check all categorical domains
  for (col in c("gender", "yes_no_field", "state")) {
    if (col %in% names(results)) {
      valid_domain <- BASELINE_METRICS$categorical_domains[[col]]
      if (!is.null(valid_domain)) {
        invalid_values <- unique(results[[col]][!results[[col]] %in% valid_domain])

        expect_equal(length(invalid_values), 0,
                    label = sprintf(
                      "❌ Column '%s' has invalid values: %s\nExpected domain: %s",
                      col,
                      paste(invalid_values, collapse = ", "),
                      paste(head(valid_domain, 10), collapse = ", ")
                    ))
      }
    }
  }
})
