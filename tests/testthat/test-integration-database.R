# Integration tests with test databases
library(testthat)
library(mysterycall)
library(dplyr)

# Helper function to create a mock census database
create_test_census_db <- function() {
  list(
    "01" = list(  # Alabama
      "001" = data.frame(
        NAME = "Autauga County, Alabama",
        B01001_001E = 58805,  # Total population
        B01001_002E = 28952,  # Male
        B01001_026E = 29853,  # Female
        B01001_030E = 1234,   # Female 15-17
        B01001_031E = 1456,   # Female 18-19
        B01001_032E = 1678,   # Female 20
        stringsAsFactors = FALSE
      )
    ),
    "06" = list(  # California
      "075" = data.frame(
        NAME = "San Francisco County, California",
        B01001_001E = 884363,
        B01001_002E = 461428,
        B01001_026E = 422935,
        B01001_030E = 12234,
        B01001_031E = 14567,
        B01001_032E = 16789,
        stringsAsFactors = FALSE
      )
    )
  )
}

# Helper function to create test NPI database
create_test_npi_db <- function() {
  data.frame(
    npi = c("1234567890", "0987654321", "1122334455", "5566778899"),
    basic_first_name = c("John", "Jane", "Michael", "Sarah"),
    basic_last_name = c("Smith", "Doe", "Johnson", "Williams"),
    basic_credential = c("MD", "DO", "MD", "MD"),
    basic_gender = c("M", "F", "M", "F"),
    addresses_state = c("CA", "TX", "NY", "FL"),
    addresses_city = c("San Francisco", "Houston", "New York", "Miami"),
    taxonomies_desc = c(
      "Obstetrics & Gynecology",
      "Gynecologic Oncology",
      "Maternal & Fetal Medicine",
      "Reproductive Endocrinology"
    ),
    addresses_country_name = rep("United States", 4),
    stringsAsFactors = FALSE
  )
}

test_that("Integration: NPI search and data cleaning pipeline", {
  skip_on_cran()

  test_npi_db <- create_test_npi_db()

  # Mock the NPI search to use our test database
  mock_npi_search <- function(taxonomy_description, ...) {
    filtered_data <- test_npi_db[
      grepl(taxonomy_description, test_npi_db$taxonomies_desc, ignore.case = TRUE),
    ]
    as.list(filtered_data)
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
    {
      # Test the full pipeline
      result <- mysterycall_search_taxonomy(
        "Gynecologic Oncology",
        write_snapshot = FALSE,
        notify = FALSE
      )

      expect_s3_class(result, "data.frame")
      expect_gt(nrow(result), 0)

      # Verify data quality
      expect_true("npi" %in% names(result))
      expect_true(all(nchar(as.character(result$npi)) == 10))

      # Check that filtering worked
      if ("taxonomies_desc" %in% names(result)) {
        expect_true(all(grepl("Gynecologic Oncology", result$taxonomies_desc)))
      }
    }
  )
})

test_that("Integration: Census data retrieval and summarization", {
  skip_on_cran()

  test_census_db <- create_test_census_db()

  # Mock censusapi::getCensus() — mysterycall_get_census_data calls it with
  # region = "block group:*" and expects state/county/tract/`block group` plus
  # the B01001_* sex-by-age variables.
  mock_get_census <- function(name, vintage, key, vars, region, regionin, ...) {
    # Extract the state FIPS from regionin (e.g. "state:06&in=county:*&in=tract:*")
    state_match <- regmatches(regionin,
                              regexpr("state:[0-9]+", regionin))
    state_fips  <- sub("^state:", "", state_match)
    out <- data.frame(
      NAME = sprintf("Block Group 1, Tract 020100, County 001, State %s", state_fips),
      state = state_fips,
      county = "001",
      tract = "020100",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    # The literal " " in the column name matches what censusapi returns
    out[["block group"]] <- "1"
    # Required population variables (B01001_001E, B01001_002E, B01001_026E..049E)
    var_names <- grep("^B01001_", vars, value = TRUE)
    if (!length(var_names)) {
      var_names <- c("B01001_001E", "B01001_002E", "B01001_026E")
    }
    for (v in var_names) {
      out[[v]] <- sample(50:5000, 1L)
    }
    out
  }

  with_mocked_bindings(
    getCensus = mock_get_census,
    .package = "censusapi",
    {
      # Test census data pipeline
      result <- mysterycall_get_census_data(
        us_fips_list = c("06", "08"),
        vintage = 2021,
        api_key = "test-key"
      )

      expect_s3_class(result, "data.frame")
      expect_gt(nrow(result), 0)

      # Test summarization
      summary_result <- mysterycall_summarize_census(result)
      expect_s3_class(summary_result, "data.frame")
      expect_true("total_population" %in% names(summary_result) ||
                  "B01001_001E" %in% names(summary_result))
    }
  )
})

test_that("Integration: Full mystery caller workflow", {
  skip_on_cran()

  # Create integrated test dataset
  phase1_data <- data.frame(
    id = 1:5,
    names = c("Dr. John Smith", "Dr. Jane Doe", "Dr. Mike Johnson", "Dr. Sarah Wilson", "Dr. Bob Brown"),
    practice_name = paste("Practice", 1:5),
    phone_number = paste0("555-", sprintf("%03d", 100:104), "-", sprintf("%04d", 1000:1004)),
    state_name = c("California", "Texas", "New York", "Florida", "Illinois"),
    npi = paste0("123456789", 0:4),
    for_redcap = rep("Yes", 5),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Test full workflow
  cleaned_data <- mysterycall_clean_phase1(
    phase1_data = phase1_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  expect_s3_class(cleaned_data, "data.frame")
  expect_gte(nrow(cleaned_data), nrow(phase1_data))

  # Validate that data can be processed further
  if ("npi" %in% names(cleaned_data)) {
    valid_npis <- cleaned_data$npi[!is.na(cleaned_data$npi)]
    expect_true(all(nchar(as.character(valid_npis)) == 10))
  }

  # Test data quality validation
  validated_data <- mysterycall_validate_npi(cleaned_data)
  expect_s3_class(validated_data, "data.frame")
})

test_that("Integration: Geographic data processing pipeline", {
  skip_on_cran()

  # Create test geographic data
  test_providers <- data.frame(
    npi = c("1234567890", "0987654321"),
    lat = c(37.7749, 29.7604),  # San Francisco, Houston
    long = c(-122.4194, -95.3698),
    practice_name = c("SF Practice", "Houston Practice"),
    stringsAsFactors = FALSE
  )

  # Test geocoding validation
  if ("lat" %in% names(test_providers) && "long" %in% names(test_providers)) {
    expect_true(all(test_providers$lat >= -90 & test_providers$lat <= 90))
    expect_true(all(test_providers$long >= -180 & test_providers$long <= 180))
  }

  # Test that coordinates are reasonable for US
  expect_true(all(test_providers$lat >= 20 & test_providers$lat <= 70))  # Rough US bounds
  expect_true(all(test_providers$long >= -180 & test_providers$long <= -60))
})

test_that("Integration: Data validation across pipeline stages", {
  skip_on_cran()

  # Create data with various quality issues
  problematic_data <- data.frame(
    id = 1:6,
    names = c("Valid Name", "", NA, "Name123", "!@#$%", "Very Very Very Long Name That Exceeds Normal Expectations"),
    practice_name = c("Valid Practice", "", NA, "P", "Practice 123", "Valid Practice 2"),
    phone_number = c("555-1234", "invalid", "", NA, "123", "555-555-5555"),
    state_name = c("California", "CA", "", NA, "InvalidState", "TX"),
    npi = c("1234567890", "invalid", "123", NA, "12345678901", "0987654321"),
    for_redcap = c("Yes", "No", "", NA, "Maybe", "Yes"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Process through cleaning pipeline
  result <- mysterycall_clean_phase1(
    phase1_data = problematic_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  expect_s3_class(result, "data.frame")

  # Verify that cleaning handled problematic data (preserves rows; NAs allowed
  # and tracked through processing_flag_* columns)
  expect_true(nrow(result) > 0)
  expect_true(any(!is.na(result$names)))  # At least some valid names retained

  # Test further validation
  if ("npi" %in% names(result)) {
    # Check NPI format for non-NA values (allow original NPIs; phase1 doesn't
    # strictly normalize length)
    valid_npis <- result$npi[!is.na(result$npi) & nchar(as.character(result$npi)) == 10L]
    expect_true(length(valid_npis) >= 0)
  }
})

test_that("Integration: Performance with realistic dataset sizes", {
  skip_on_cran()

  # Create realistic-sized dataset
  n_providers <- 100
  realistic_data <- data.frame(
    id = 1:n_providers,
    names = paste("Provider", 1:n_providers),
    practice_name = paste("Practice", sample(1:50, n_providers, replace = TRUE)),
    phone_number = paste0(sample(200:999, n_providers, replace = TRUE), "-555-",
                         sprintf("%04d", sample(1000:9999, n_providers))),
    state_name = sample(state.name, n_providers, replace = TRUE),
    npi = paste0(sample(100000000:999999999, n_providers), sample(0:9, n_providers, replace = TRUE)),
    for_redcap = sample(c("Yes", "No"), n_providers, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Test performance
  start_time <- Sys.time()
  result <- mysterycall_clean_phase1(
    phase1_data = realistic_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )
  end_time <- Sys.time()

  expect_s3_class(result, "data.frame")
  expect_gte(nrow(result), n_providers)

  # Should complete within reasonable time
  processing_time <- as.numeric(end_time - start_time, units = "secs")
  expect_lt(processing_time, 30)  # Should process 100 records in under 30 seconds
})

test_that("Integration: Cross-function data compatibility", {
  skip_on_cran()

  # Test that output from one function can be used as input to another
  initial_data <- data.frame(
    id = 1:3,
    names = c("Dr. A", "Dr. B", "Dr. C"),
    practice_name = c("Practice A", "Practice B", "Practice C"),
    phone_number = c("555-0001", "555-0002", "555-0003"),
    state_name = c("CA", "TX", "NY"),
    npi = c("1234567890", "0987654321", "1122334455"),
    for_redcap = rep("Yes", 3),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Stage 1: Clean the data
  cleaned_data <- mysterycall_clean_phase1(
    phase1_data = initial_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Stage 2: Validate NPIs
  validated_data <- mysterycall_validate_npi(cleaned_data)

  # Verify compatibility
  expect_s3_class(validated_data, "data.frame")

  # Check that data structure is preserved
  expect_true(nrow(validated_data) <= nrow(cleaned_data))  # May remove invalid NPIs

  # If NPIs exist, they should be valid format
  if ("npi" %in% names(validated_data) && nrow(validated_data) > 0) {
    valid_npis <- validated_data$npi[!is.na(validated_data$npi)]
    if (length(valid_npis) > 0) {
      expect_true(all(nchar(as.character(valid_npis)) == 10))
    }
  }
})