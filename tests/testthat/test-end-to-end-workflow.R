# End-to-end workflow tests with real data samples
library(testthat)
library(mysterycall)
library(dplyr)
library(readr)

# Simulate realistic datasets that mirror actual use cases
create_realistic_phase1_data <- function() {
  # Based on actual mystery caller study structure
  data.frame(
    id = 1:25,
    names = c(
      "Dr. Sarah Johnson", "Dr. Michael Chen", "Dr. Jennifer Williams",
      "Dr. Robert Garcia", "Dr. Lisa Thompson", "Dr. David Martinez",
      "Dr. Emily Davis", "Dr. James Wilson", "Dr. Amanda Rodriguez",
      "Dr. Christopher Lee", "Dr. Rachel Brown", "Dr. Matthew Anderson",
      "Dr. Nicole Taylor", "Dr. Kevin Clark", "Dr. Stephanie Lewis",
      "Dr. Thomas Hall", "Dr. Michelle Young", "Dr. Daniel Allen",
      "Dr. Lauren King", "Dr. Andrew Wright", "Dr. Samantha Scott",
      "Dr. Richard Green", "Dr. Jessica Adams", "Dr. Joseph Baker",
      "Dr. Ashley Nelson"
    ),
    practice_name = c(
      "Women's Health Associates", "University Medical Center", "Family Care Clinic",
      "Regional Medical Group", "Downtown Health Center", "Northside OB/GYN",
      "Metro Women's Clinic", "Central Valley Health", "Suburban Medical",
      "City General Practice", "Westside Healthcare", "East End Medical",
      "Southside Women's Health", "Highland Medical Group", "Valley OB/GYN",
      "Riverside Healthcare", "Mountain View Clinic", "Lakeside Medical",
      "Sunset Women's Center", "Sunrise Healthcare", "Midtown Medical",
      "Crossroads Health", "Gateway Medical", "Pinnacle OB/GYN",
      "Heritage Women's Health"
    ),
    phone_number = c(
      "(555) 123-4567", "555-234-5678", "555.345.6789", "5554567890",
      "(555) 567-8901", "555-678-9012", "555.789.0123", "5558901234",
      "(555) 901-2345", "555-012-3456", "555.123.4567", "5552345678",
      "(555) 345-6789", "555-456-7890", "555.567.8901", "5556789012",
      "(555) 789-0123", "555-890-1234", "555.901.2345", "5550123456",
      "(555) 234-5678", "555-345-6789", "555.456.7890", "5557890123",
      "(555) 890-1234"
    ),
    state_name = c(
      "California", "Texas", "Florida", "New York", "Pennsylvania",
      "Illinois", "Ohio", "Georgia", "North Carolina", "Michigan",
      "New Jersey", "Virginia", "Washington", "Arizona", "Massachusetts",
      "Tennessee", "Indiana", "Missouri", "Maryland", "Wisconsin",
      "Colorado", "Minnesota", "South Carolina", "Alabama", "Louisiana"
    ),
    npi = c(
      "1000000368", "1000000681", "1000000889", "1000001614", "1000001838",
      "1000002216", "1000002448", "1000002794", "1000003107", "1000003297",
      "1000004568", "1000005011", "1000005177", "1000006704", "1000008023",
      "1000008353", "1000008528", "1000008783", "1000009104", "1000009278",
      "1000009518", "1000009823", "1000010649", "1000011738", "1000012801"
    ),
    for_redcap = c(rep("Yes", 20), rep("No", 5)),
    insurance_type = sample(c("Medicaid", "Private", "Self-Pay"), 25, replace = TRUE),
    appointment_requested = sample(c("New Patient", "Follow-up", "Urgent"), 25, replace = TRUE),
    caller_age = sample(18:45, 25, replace = TRUE),
    specialty_needed = sample(c("General OBGYN", "High-Risk", "Fertility", "Gynecologic Oncology"), 25, replace = TRUE),
    stringsAsFactors = FALSE
  )
}

create_realistic_census_data <- function() {
  # Simulate census data for testing
  data.frame(
    NAME = c(
      "Los Angeles County, California",
      "Cook County, Illinois",
      "Harris County, Texas",
      "Maricopa County, Arizona",
      "San Diego County, California"
    ),
    state = c("06", "17", "48", "04", "06"),
    county = c("037", "031", "201", "013", "073"),
    B01001_001E = c(10014009, 5275541, 4731145, 4485414, 3343364),  # Total population
    B01001_002E = c(4974799, 2573005, 2386199, 2281960, 1675975),   # Male
    B01001_026E = c(5039210, 2702536, 2344946, 2203454, 1667389),   # Female
    B01001_030E = c(189234, 89234, 78123, 67890, 56789),           # Female 15-17
    B01001_031E = c(145678, 67890, 56789, 45678, 34567),           # Female 18-19
    B01001_032E = c(167890, 78901, 67890, 56789, 45678),           # Female 20
    B01001_033E = c(178901, 89012, 78901, 67890, 56789),           # Female 21
    B01001_034E = c(345678, 167890, 145678, 123456, 98765),        # Female 22-24
    B01001_035E = c(456789, 234567, 201234, 178901, 145678),       # Female 25-29
    B01001_036E = c(467890, 245678, 212345, 189012, 156789),       # Female 30-34
    B01001_037E = c(445678, 223456, 198765, 175432, 142109),       # Female 35-39
    B01001_038E = c(423456, 212345, 189012, 165789, 132456),       # Female 40-44
    stringsAsFactors = FALSE
  )
}

test_that("End-to-end: Complete mystery caller workflow", {
  skip_on_cran()

  # Stage 1: Initial data processing
  phase1_data <- create_realistic_phase1_data()
  temp_dir <- tempdir()

  # Clean Phase 1 results
  cleaned_data <- mysterycall_clean_phase1(
    phase1_data = phase1_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    duplicate_rows = FALSE  # Simplify for testing
  )

  expect_s3_class(cleaned_data, "data.frame")
  expect_gte(nrow(cleaned_data), nrow(phase1_data))

  # Stage 2: NPI validation
  validated_data <- mysterycall_validate_npi(cleaned_data)
  expect_s3_class(validated_data, "data.frame")

  # Stage 3: Geographic analysis (if geographic functions are available)
  if ("state_name" %in% names(validated_data)) {
    # Summarize by state
    state_summary <- validated_data %>%
      count(state_name, sort = TRUE)

    expect_s3_class(state_summary, "data.frame")
    expect_true("n" %in% names(state_summary))
    expect_gt(nrow(state_summary), 0)
  }

  # Stage 4: Quality checks
  expect_true(all(!is.na(validated_data$names)))
  expect_true(all(!is.na(validated_data$practice_name)))

  # Verify data integrity throughout pipeline
  if ("id" %in% names(validated_data)) {
    expect_equal(length(unique(validated_data$id)), length(unique(phase1_data$id)))
  }
})

test_that("End-to-end: NPI search and provider enrichment workflow", {
  skip_on_cran()

  # Mock comprehensive NPI search results
  mock_npi_search <- function(taxonomy_description, ...) {
    taxonomies <- c(
      "Obstetrics & Gynecology" = 50,
      "Gynecologic Oncology" = 15,
      "Maternal & Fetal Medicine" = 12,
      "Reproductive Endocrinology" = 8
    )

    n_results <- taxonomies[taxonomy_description] %||% 5

    list(
      npi = paste0("123456789", seq_len(n_results) %% 10),
      basic_first_name = paste("Provider", seq_len(n_results)),
      basic_last_name = paste("Last", seq_len(n_results)),
      basic_credential = rep("MD", n_results),
      basic_gender = sample(c("M", "F"), n_results, replace = TRUE),
      basic_enumeration_date = sample(
        seq(as.Date("2010-01-01"), as.Date("2023-01-01"), by = "day"),
        n_results, replace = TRUE
      ),
      addresses_country_name = rep("United States", n_results),
      addresses_state = sample(state.abb, n_results, replace = TRUE),
      addresses_city = paste("City", seq_len(n_results)),
      addresses_postal_code = paste0(sprintf("%05d", sample(10000:99999, n_results))),
      taxonomies_desc = rep(taxonomy_description, n_results),
      full_name = paste("Provider", seq_len(n_results), "Last", seq_len(n_results))
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
      # Stage 1: Search by taxonomy
      obgyn_providers <- mysterycall_search_taxonomy(
        "Obstetrics & Gynecology",
        write_snapshot = FALSE,
        notify = FALSE
      )

      expect_s3_class(obgyn_providers, "data.frame")
      expect_gt(nrow(obgyn_providers), 0)

      # Stage 2: Search specialists
      specialists <- mysterycall_search_taxonomy(
        c("Gynecologic Oncology", "Maternal & Fetal Medicine"),
        write_snapshot = FALSE,
        notify = FALSE
      )

      expect_s3_class(specialists, "data.frame")

      # Stage 3: Combine and deduplicate
      all_providers <- bind_rows(
        obgyn_providers %>% mutate(source = "general_obgyn"),
        specialists %>% mutate(source = "specialist")
      )

      if (nrow(all_providers) > 0 && "npi" %in% names(all_providers)) {
        # Deduplicate by NPI
        unique_providers <- all_providers %>%
          distinct(npi, .keep_all = TRUE)

        expect_lte(nrow(unique_providers), nrow(all_providers))

        # Stage 4: Geographic distribution analysis
        if ("addresses_state" %in% names(unique_providers)) {
          state_distribution <- unique_providers %>%
            count(addresses_state, source, .drop = FALSE) %>%
            arrange(desc(n))

          expect_s3_class(state_distribution, "data.frame")
          expect_true(nrow(state_distribution) > 0)
        }

        # Stage 5: Provider characteristics analysis
        if ("basic_gender" %in% names(unique_providers)) {
          gender_summary <- unique_providers %>%
            count(basic_gender, source) %>%
            mutate(percentage = n / sum(n) * 100)

          expect_s3_class(gender_summary, "data.frame")
          expect_true("percentage" %in% names(gender_summary))
        }
      }
    }
  )
})

test_that("End-to-end: Census data integration workflow", {
  skip_on_cran()

  # Mock censusapi::getCensus() — returns block-group level data shaped the
  # way mysterycall_get_census_data expects.  Population estimates use a
  # consistent age/sex breakdown so derived percentages stay in [0, 100].
  mock_get_census <- function(name, vintage, key, vars, region, regionin, ...) {
    state_fips <- sub("^state:", "",
                       regmatches(regionin,
                                  regexpr("state:[0-9]+", regionin)))
    out <- data.frame(
      NAME = sprintf("Block Group 1, Tract 020100, County 001, State %s", state_fips),
      state = state_fips,
      county = "001",
      tract = "020100",
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    out[["block group"]] <- "1"
    # Realistic populations: total = male + female; reproductive-age females
    # (B01001_030..038) are a fraction of total female (B01001_026)
    total_pop <- 2000L
    male_pop  <- 980L
    female_pop <- total_pop - male_pop  # 1020
    # Reproductive-age (15-44) ≈ 45% of female population
    repro_share <- 0.45
    age_buckets <- c(0.02, 0.02, 0.03, 0.03, 0.06, 0.09, 0.09, 0.06, 0.05)
    age_buckets <- age_buckets / sum(age_buckets) * repro_share
    out$B01001_001E <- total_pop
    out$B01001_002E <- male_pop
    out$B01001_026E <- female_pop
    for (i in seq_along(age_buckets)) {
      v <- sprintf("B01001_%03dE", 29L + i)  # 030..038
      out[[v]] <- as.integer(round(female_pop * age_buckets[i]))
    }
    # Any extra requested vars get a zero fallback
    requested <- grep("^B01001_", vars, value = TRUE)
    for (v in setdiff(requested, names(out))) out[[v]] <- 0L
    out
  }

  with_mocked_bindings(
    getCensus = mock_get_census,
    .package = "censusapi",
    {
      # Stage 1: Retrieve census data
      census_data <- mysterycall_get_census_data(
        us_fips_list = c("06", "08"),
        vintage = 2021,
        api_key = "test-key"
      )

      expect_s3_class(census_data, "data.frame")
      expect_gt(nrow(census_data), 0)

      # Stage 2: Summarize census data
      if (nrow(census_data) > 0) {
        census_summary <- mysterycall_summarize_census(census_data)
        expect_s3_class(census_summary, "data.frame")

        # Stage 3: Calculate reproductive age population
        if ("B01001_030E" %in% names(census_data)) {
          reproductive_age_cols <- sprintf("B01001_%03dE", 30:38)
          available_cols <- intersect(reproductive_age_cols, names(census_data))

          if (length(available_cols) > 0) {
            census_with_totals <- census_data %>%
              mutate(
                reproductive_age_female = rowSums(select(., all_of(available_cols)), na.rm = TRUE),
                total_female = B01001_026E
              ) %>%
              mutate(
                reproductive_age_percent = ifelse(total_female > 0,
                  reproductive_age_female / total_female * 100, 0)
              )

            expect_s3_class(census_with_totals, "data.frame")
            expect_true("reproductive_age_percent" %in% names(census_with_totals))

            # Validate percentages are reasonable
            valid_percentages <- census_with_totals$reproductive_age_percent[
              !is.na(census_with_totals$reproductive_age_percent)
            ]
            expect_true(all(valid_percentages >= 0 & valid_percentages <= 100))
          }
        }
      }
    }
  )
})

test_that("End-to-end: Data quality and validation pipeline", {
  skip_on_cran()

  # Create dataset with known quality issues
  problematic_data <- data.frame(
    id = 1:15,
    names = c(
      "Dr. John Smith", "Dr. Jane Doe", "", NA, "Dr. Michael Johnson",
      "Dr. Sarah Wilson", "Invalid Name 123!@#", "Dr. Bob Brown",
      "Dr. Lisa Garcia", "Dr. Tom Clark", "Dr. Amy Davis", "",
      "Dr. Mark Lee", NA, "Dr. Kate Allen"
    ),
    practice_name = c(
      "Valid Practice", "", NA, "Another Practice", "Good Clinic",
      "Health Center", "Clinic Name", "Medical Group", "", "Practice",
      NA, "Healthcare", "Medical Center", "Clinic", "Practice Name"
    ),
    phone_number = c(
      "555-123-4567", "invalid", "", NA, "(555) 234-5678",
      "555.345.6789", "123", "555-456-7890", "5557890123",
      "", NA, "555-901-2345", "invalid_phone", "555-345-6789", "555-012-3456"
    ),
    state_name = c(
      "California", "TX", "", NA, "Florida",
      "InvalidState", "New York", "Illinois", "Ohio",
      "", NA, "Virginia", "Washington", "Invalid", "Colorado"
    ),
    npi = c(
      "1234567890", "invalid", "", NA, "2345678901",
      "123", "3456789012", "4567890123", "5678901234invalid",
      "", NA, "6789012345", "invalid_npi", "7890123456", "8901234567"
    ),
    for_redcap = c(
      "Yes", "No", "", NA, "Yes",
      "Maybe", "Yes", "No", "Invalid",
      "", NA, "Yes", "No", "Unknown", "Yes"
    ),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Stage 1: Initial cleaning
  cleaned_data <- mysterycall_clean_phase1(
    phase1_data = problematic_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  expect_s3_class(cleaned_data, "data.frame")

  # Stage 2: Validate results
  validated_data <- mysterycall_validate_npi(cleaned_data)
  expect_s3_class(validated_data, "data.frame")

  # Stage 3: Quality assessment
  if (nrow(validated_data) > 0) {
    # Check data completeness
    completeness_report <- validated_data %>%
      summarise(
        total_rows = n(),
        complete_names = sum(!is.na(names) & names != ""),
        complete_practices = sum(!is.na(practice_name) & practice_name != ""),
        valid_npis = if ("npi" %in% names(validated_data)) {
          sum(grepl("^[0-9]{10}$", npi, na.rm = TRUE))
        } else { 0 }
      ) %>%
      mutate(
        name_completeness = complete_names / total_rows,
        practice_completeness = complete_practices / total_rows,
        npi_validity = if (total_rows > 0) valid_npis / total_rows else 0
      )

    expect_s3_class(completeness_report, "data.frame")

    # Data quality should meet minimum standards
    expect_gte(completeness_report$name_completeness, 0.8)
    expect_gte(completeness_report$practice_completeness, 0.7)
  }
})

test_that("End-to-end: Geographic analysis workflow", {
  skip_on_cran()

  # Create providers with geographic information
  geographic_data <- data.frame(
    id = 1:10,
    names = paste("Dr.", sample(c("John", "Jane", "Michael", "Sarah"), 10, replace = TRUE),
                  sample(c("Smith", "Johnson", "Williams", "Brown"), 10, replace = TRUE)),
    practice_name = paste("Practice", 1:10),
    phone_number = paste0("555-", sprintf("%03d", 100:109), "-", sprintf("%04d", 1000:1009)),
    state_name = c("California", "Texas", "Florida", "New York", "Pennsylvania",
                   "Illinois", "Ohio", "Georgia", "North Carolina", "Michigan"),
    npi = paste0("123456789", 0:9),
    for_redcap = rep("Yes", 10),
    # Add geographic coordinates
    latitude = c(34.0522, 29.7604, 25.7617, 40.7128, 39.9526,
                 41.8781, 39.9612, 33.4484, 35.7796, 42.3314),
    longitude = c(-118.2437, -95.3698, -80.1918, -74.0060, -75.1652,
                  -87.6298, -82.9988, -84.3880, -78.6382, -84.5467),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Stage 1: Data processing
  cleaned_data <- mysterycall_clean_phase1(
    phase1_data = geographic_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    duplicate_rows = FALSE
  )

  # Stage 2: Geographic validation
  if ("latitude" %in% names(cleaned_data) && "longitude" %in% names(cleaned_data)) {
    # Validate coordinate ranges
    expect_true(all(cleaned_data$latitude >= -90 & cleaned_data$latitude <= 90))
    expect_true(all(cleaned_data$longitude >= -180 & cleaned_data$longitude <= 180))

    # For US data, coordinates should be within reasonable bounds
    expect_true(all(cleaned_data$latitude >= 20 & cleaned_data$latitude <= 70))
    expect_true(all(cleaned_data$longitude >= -170 & cleaned_data$longitude <= -60))
  }

  # Stage 3: State-level aggregation
  state_summary <- cleaned_data %>%
    count(state_name, sort = TRUE) %>%
    mutate(percentage = n / sum(n) * 100)

  expect_s3_class(state_summary, "data.frame")
  expect_true(sum(state_summary$percentage) >= 99)  # Should sum to ~100%

  # Stage 4: Regional analysis
  if ("state_name" %in% names(cleaned_data)) {
    # Define regions
    regions <- list(
      West = c("California", "Oregon", "Washington", "Nevada", "Arizona"),
      South = c("Texas", "Florida", "Georgia", "North Carolina", "South Carolina"),
      Northeast = c("New York", "Pennsylvania", "Massachusetts", "Connecticut"),
      Midwest = c("Illinois", "Ohio", "Michigan", "Wisconsin", "Minnesota")
    )

    regional_data <- cleaned_data %>%
      mutate(
        region = case_when(
          state_name %in% regions$West ~ "West",
          state_name %in% regions$South ~ "South",
          state_name %in% regions$Northeast ~ "Northeast",
          state_name %in% regions$Midwest ~ "Midwest",
          TRUE ~ "Other"
        )
      )

    regional_summary <- regional_data %>%
      count(region, sort = TRUE)

    expect_s3_class(regional_summary, "data.frame")
    expect_true(nrow(regional_summary) > 0)
  }
})

test_that("End-to-end: Error handling and recovery workflow", {
  skip_on_cran()

  temp_dir <- tempdir()

  # Test recovery from various error conditions
  error_scenarios <- list(
    empty_data = data.frame(),
    missing_columns = data.frame(id = 1:3, wrong_col = letters[1:3]),
    all_na_data = data.frame(
      id = 1:3, names = rep(NA, 3), practice_name = rep(NA, 3),
      phone_number = rep(NA, 3), state_name = rep(NA, 3),
      npi = rep(NA, 3), for_redcap = rep(NA, 3)
    )
  )

  # Test that errors are handled gracefully
  expect_error(
    mysterycall_clean_phase1(error_scenarios$empty_data, output_directory = temp_dir),
    "at least one row"
  )

  expect_error(
    mysterycall_clean_phase1(error_scenarios$missing_columns, output_directory = temp_dir),
    "names"
  )

  # All NA data should be handled gracefully (the function uses random_id
  # fallback when NPIs are NA and writes the cleaned output)
  expect_no_error(
    suppressMessages(
      mysterycall_clean_phase1(error_scenarios$all_na_data,
                                output_directory = temp_dir,
                                verbose = FALSE)
    )
  )
})

test_that("End-to-end: Performance and scalability workflow", {
  skip_on_cran()
  skip_if_not(identical(Sys.getenv("TEST_SCALABILITY"), "true"),
              "Set TEST_SCALABILITY=true to run scalability tests")

  # Test with progressively larger datasets
  dataset_sizes <- c(50, 200, 500)
  processing_times <- numeric(length(dataset_sizes))

  for (i in seq_along(dataset_sizes)) {
    n <- dataset_sizes[i]

    # Create scaled dataset
    large_data <- data.frame(
      id = 1:n,
      names = paste("Provider", 1:n),
      practice_name = paste("Practice", sample(1:min(100, n), n, replace = TRUE)),
      phone_number = paste0(sample(200:999, n, replace = TRUE), "-555-",
                           sprintf("%04d", sample(1000:9999, n, replace = TRUE))),
      state_name = sample(state.name, n, replace = TRUE),
      npi = paste0(sample(100000000:999999999, n), sample(0:9, n, replace = TRUE)),
      for_redcap = sample(c("Yes", "No"), n, replace = TRUE),
      stringsAsFactors = FALSE
    )

    temp_dir <- tempdir()

    # Measure processing time
    start_time <- Sys.time()
    result <- mysterycall_clean_phase1(
      phase1_data = large_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
    end_time <- Sys.time()

    processing_times[i] <- as.numeric(end_time - start_time, units = "secs")

    # Verify successful processing
    expect_s3_class(result, "data.frame")
    expect_gte(nrow(result), n)
  }

  # Check that processing time scales reasonably
  for (i in 2:length(dataset_sizes)) {
    size_ratio <- dataset_sizes[i] / dataset_sizes[i-1]
    time_ratio <- processing_times[i] / processing_times[i-1]

    # Time should scale sub-quadratically
    expect_lt(time_ratio, size_ratio^1.5,
              label = paste("Poor scalability detected between size",
                          dataset_sizes[i-1], "and", dataset_sizes[i]))
  }
})
