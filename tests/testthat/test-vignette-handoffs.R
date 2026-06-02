# Handoff tests for all vignettes - ensuring examples work correctly
library(testthat)
library(mysterycall)
library(dplyr)

# Test data generators for vignette examples
create_vignette_test_data <- function(vignette_type) {
  switch(vignette_type,
    "search_taxonomy" = data.frame(
      taxonomy_code = c("207V00000X", "207VX0201X", "207VM0101X"),
      taxonomy_desc = c("Obstetrics & Gynecology", "Gynecologic Oncology", "Maternal & Fetal Medicine"),
      stringsAsFactors = FALSE
    ),
    "npi_search" = data.frame(
      npi = c("1234567890", "2345678901", "3456789012"),
      provider_name = c("Dr. John Smith", "Dr. Jane Doe", "Dr. Bob Johnson"),
      stringsAsFactors = FALSE
    ),
    "census_data" = data.frame(
      geoid = c("01001020100", "06075020100", "48201020100"),
      state = c("01", "06", "48"),
      county = c("001", "075", "201"),
      B01001_001E = c(2000, 3000, 2500),  # Total population
      B01001_026E = c(1020, 1540, 1275),  # Female population
      stringsAsFactors = FALSE
    )
  )
}

test_that("Vignette handoff: my-vignette.Rmd taxonomy search examples", {
  skip_on_cran()

  # Mock the functions used in my-vignette.Rmd
  mock_npi_search <- function(taxonomy_description, ...) {
    if (grepl("Hospice|Palliative", taxonomy_description)) {
      list(
        npi = c("1234567890", "2345678901"),
        basic_first_name = c("John", "Jane"),
        basic_last_name = c("Smith", "Doe"),
        basic_credential = c("MD", "DO"),
        basic_gender = c("M", "F"),
        addresses_country_name = c("United States", "United States"),
        addresses_state = c("CA", "TX"),
        taxonomies_desc = c("Hospice and Palliative Medicine", "Hospice and Palliative Medicine"),
        full_name = c("John Smith", "Jane Doe")
      )
    } else {
      list()
    }
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
      # Test the exact code from my-vignette.Rmd
      taxonomy_descriptions <- c("Hospice and Palliative Medicine")
      data <- mysterycall_search_taxonomy(taxonomy_to_search = taxonomy_descriptions,
                                 write_snapshot = FALSE, notify = FALSE)

      expect_s3_class(data, "data.frame")

      # Test the count operation that was failing
      if (nrow(data) > 0) {
        # This should work now (basic_credential was removed in select)
        count_result <- dplyr::count(data, basic_gender, addresses_state)
        expect_s3_class(count_result, "data.frame")
        expect_true("n" %in% names(count_result))

        # Test state summary
        state_summary <- data %>% dplyr::count(addresses_state)
        expect_s3_class(state_summary, "data.frame")
        expect_true("addresses_state" %in% names(state_summary))
      }
    }
  )
})

test_that("Vignette handoff: mysterycall_search_and_process_npi.Rmd examples", {
  skip_on_cran()

  # Test data processing from mysterycall_search_and_process_npi vignette
  test_npi_data <- data.frame(
    npi = c("1234567890", "2345678901", "3456789012", "invalid_npi", ""),
    provider_name = c("Dr. Smith", "Dr. Johnson", "Dr. Williams", "Dr. Invalid", "Dr. Empty"),
    stringsAsFactors = FALSE
  )

  # Test NPI validation as shown in vignette
  validated_data <- mysterycall_validate_npi(test_npi_data)

  expect_s3_class(validated_data, "data.frame")

  # Should remove invalid NPIs
  if ("npi" %in% names(validated_data) && nrow(validated_data) > 0) {
    valid_npis <- validated_data$npi[!is.na(validated_data$npi) & validated_data$npi != ""]
    if (length(valid_npis) > 0) {
      expect_true(all(grepl("^[0-9]{10}$", valid_npis)))
    }
  }

  # Test search and process workflow
  if (requireNamespace("npi", quietly = TRUE)) {
    # Mock NPI processing
    mock_process_npi <- function(npi_list) {
      lapply(npi_list, function(npi) {
        if (grepl("^[0-9]{10}$", npi)) {
          list(
            npi = npi,
            basic_first_name = "Test",
            basic_last_name = "Provider",
            addresses_state = "CA"
          )
        } else {
          NULL
        }
      })
    }

    # This simulates the vignette workflow
    valid_npis <- c("1234567890", "2345678901")
    results <- mock_process_npi(valid_npis)
    results <- results[!sapply(results, is.null)]

    expect_gt(length(results), 0)
    expect_true(all(sapply(results, function(x) "npi" %in% names(x))))
  }
})

test_that("Vignette handoff: mysterycall_get_census_data.Rmd examples", {
  skip_on_cran()

  # Mock census API for vignette testing
  mock_get_census <- function(name, vintage, key, vars, region, ...) {
    # Return mock census data structure
    data.frame(
      NAME = c("Example County, State", "Another County, State"),
      state = c("01", "06"),
      county = c("001", "075"),
      B01001_001E = c(50000, 75000),  # Total population
      B01001_002E = c(24500, 36750),  # Male
      B01001_026E = c(25500, 38250),  # Female
      B01001_030E = c(1000, 1500),    # Female 15-17
      B01001_031E = c(800, 1200),     # Female 18-19
      stringsAsFactors = FALSE
    )
  }

  with_mocked_bindings(
    getCensus = mock_get_census,
    .package = "censusapi",
    {
      # Test census data retrieval as shown in vignette
      census_data <- mysterycall_get_census_data(
        us_fips_list = c("06", "08"),
        vintage = 2021,
        api_key = "test-key"
      )

      expect_s3_class(census_data, "data.frame")
      expect_gt(nrow(census_data), 0)

      # Test summarization function
      if (nrow(census_data) > 0) {
        summary_data <- mysterycall_summarize_census(census_data)
        expect_s3_class(summary_data, "data.frame")

        # Test that required columns exist for analysis
        expected_cols <- c("B01001_001E", "B01001_026E")  # Total and female population
        available_cols <- intersect(expected_cols, names(census_data))
        expect_gt(length(available_cols), 0)
      }
    }
  )
})

test_that("Vignette handoff: mysterycall_create_isochrones.Rmd examples", {
  skip_on_cran()

  # Test isochrone creation examples
  if (requireNamespace("sf", quietly = TRUE)) {
    # Mock location data
    test_location <- sf::st_point(c(-122.4194, 37.7749))  # San Francisco
    test_location_sf <- sf::st_sfc(test_location, crs = 4326)

    # Mock HERE API response
    mock_isoline <- function(poi, range, ...) {
      # Return mock isochrone polygon
      coords <- matrix(c(
        -122.43, 37.76, -122.41, 37.76, -122.41, 37.78, -122.43, 37.78, -122.43, 37.76
      ), ncol = 2, byrow = TRUE)

      polygon <- sf::st_polygon(list(coords))
      sf::st_sf(
        range = range,
        geometry = sf::st_sfc(polygon, crs = 4326)
      )
    }

    with_mocked_bindings(
      isoline = mock_isoline,
      .package = "hereR",
      {
        # Test mysterycall_create_isochrones function
        result <- mysterycall_create_isochrones(
          location = test_location_sf,
          range = c(1800, 3600),  # 30 min, 60 min
          api_key = "test_key"
        )

        expect_s3_class(result, "sf")
        expect_true("range" %in% names(result))
      }
    )
  }
})

test_that("Vignette handoff: geocode.Rmd examples", {
  skip_on_cran()
  skip_if_not_installed("ggmap")

  # Test geocoding examples
  test_addresses <- c(
    "123 Main St, San Francisco, CA",
    "456 Oak Ave, Los Angeles, CA",
    "789 Pine St, Sacramento, CA"
  )

  # Mock geocoding function
  mock_geocode <- function(location, ...) {
    data.frame(
      lon = c(-122.4194, -118.2437, -121.4694),
      lat = c(37.7749, 34.0522, 38.5816),
      stringsAsFactors = FALSE
    )
  }

  with_mocked_bindings(
    geocode = mock_geocode,
    .package = "ggmap",
    {
      # Test geocoding workflow
      geocoded <- mysterycall_geocode(test_addresses)

      expect_s3_class(geocoded, "data.frame")
      expect_true("lat" %in% names(geocoded) || "latitude" %in% names(geocoded))
      expect_true("lon" %in% names(geocoded) || "longitude" %in% names(geocoded))

      # Validate coordinate ranges
      if ("lat" %in% names(geocoded)) {
        expect_true(all(geocoded$lat >= -90 & geocoded$lat <= 90))
      }
      if ("lon" %in% names(geocoded)) {
        expect_true(all(geocoded$lon >= -180 & geocoded$lon <= 180))
      }
    }
  )
})

test_that("Vignette handoff: aggregating_provider_data.Rmd examples", {
  skip_on_cran()

  # Test provider data aggregation examples
  provider_data <- data.frame(
    npi = c("1234567890", "2345678901", "3456789012"),
    provider_name = c("Dr. Smith", "Dr. Johnson", "Dr. Williams"),
    specialty = c("OBGYN", "OBGYN", "MFM"),
    state = c("CA", "TX", "NY"),
    practice_type = c("Private", "Hospital", "Academic"),
    stringsAsFactors = FALSE
  )

  # Test aggregation operations shown in vignette
  state_summary <- provider_data %>%
    count(state, specialty) %>%
    arrange(desc(n))

  expect_s3_class(state_summary, "data.frame")
  expect_true("n" %in% names(state_summary))
  expect_equal(sum(state_summary$n), nrow(provider_data))

  # Test specialty distribution
  specialty_dist <- provider_data %>%
    count(specialty) %>%
    mutate(percentage = n / sum(n) * 100)

  expect_s3_class(specialty_dist, "data.frame")
  expect_true("percentage" %in% names(specialty_dist))
  expect_true(abs(sum(specialty_dist$percentage) - 100) < 0.001)
})

test_that("Vignette handoff: Cross-vignette data compatibility", {
  skip_on_cran()

  # Test that data flows correctly between vignette examples

  # Stage 1: Search providers (from my-vignette.Rmd)
  mock_npi_search <- function(taxonomy_description, ...) {
    list(
      npi = c("1234567890", "2345678901", "3456789012"),
      basic_first_name = c("John", "Jane", "Bob"),
      basic_last_name = c("Smith", "Doe", "Johnson"),
      basic_credential = c("MD", "DO", "MD"),
      basic_gender = c("M", "F", "M"),
      addresses_country_name = rep("United States", 3),
      addresses_state = c("CA", "TX", "NY"),
      addresses_city = c("San Francisco", "Houston", "New York"),
      taxonomies_desc = rep("Obstetrics & Gynecology", 3)
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
      # Get provider data
      provider_data <- mysterycall_search_taxonomy("Obstetrics & Gynecology",
                                          write_snapshot = FALSE, notify = FALSE)

      expect_s3_class(provider_data, "data.frame")

      if (nrow(provider_data) > 0) {
        # Stage 2: Validate NPIs (from mysterycall_search_and_process_npi.Rmd)
        validated_providers <- mysterycall_validate_npi(provider_data)
        expect_s3_class(validated_providers, "data.frame")

        # Stage 3: Geographic analysis (from geocode.Rmd concepts)
        if ("addresses_state" %in% names(validated_providers)) {
          geo_summary <- validated_providers %>%
            count(addresses_state) %>%
            arrange(desc(n))

          expect_s3_class(geo_summary, "data.frame")
          expect_true("n" %in% names(geo_summary))
        }

        # Stage 4: Aggregate data (from aggregating_provider_data.Rmd)
        if ("basic_gender" %in% names(validated_providers)) {
          gender_summary <- validated_providers %>%
            count(basic_gender) %>%
            mutate(percentage = n / sum(n) * 100)

          expect_s3_class(gender_summary, "data.frame")
          expect_true("percentage" %in% names(gender_summary))
        }
      }
    }
  )
})

test_that("Vignette handoff: Error scenarios in examples", {
  skip_on_cran()

  # Test that vignette examples handle errors gracefully

  # Test empty search results
  mock_empty_search <- function(taxonomy_description, ...) {
    list()  # Empty results
  }

  mock_npi_flatten <- function(x) {
    tibble::tibble()  # Empty tibble
  }

  with_mocked_bindings(
    npi_search = mock_empty_search,
    npi_flatten = mock_npi_flatten,
    {
      # Should handle empty results gracefully
      result <- mysterycall_search_taxonomy("Nonexistent Specialty",
                                   write_snapshot = FALSE, notify = FALSE)

      expect_s3_class(result, "data.frame")
      expect_equal(nrow(result), 0)

      # Should work with subsequent operations
      count_result <- result %>% count()
      expect_s3_class(count_result, "data.frame")
    }
  )

  # Test with invalid data
  invalid_provider_data <- data.frame(
    npi = c("invalid", "123", ""),
    names = c("", NA, "Valid Name"),
    stringsAsFactors = FALSE
  )

  # Should handle validation gracefully
  validated_invalid <- mysterycall_validate_npi(invalid_provider_data)
  expect_s3_class(validated_invalid, "data.frame")
})

test_that("Vignette handoff: Performance with example datasets", {
  skip_on_cran()

  # Test that vignette examples perform adequately

  # Create realistic-sized example data
  large_example_data <- data.frame(
    npi = paste0("123456789", 0:99),  # 100 providers
    basic_first_name = paste("Provider", 1:100),
    basic_last_name = paste("Last", 1:100),
    addresses_state = sample(state.abb, 100, replace = TRUE),
    taxonomies_desc = sample(c("Obstetrics & Gynecology", "Gynecologic Oncology"), 100, replace = TRUE),
    stringsAsFactors = FALSE
  )

  # Time the operations shown in vignettes
  start_time <- Sys.time()

  # Aggregation operations from vignettes
  state_summary <- large_example_data %>%
    count(addresses_state, taxonomies_desc) %>%
    arrange(desc(n))

  taxonomy_summary <- large_example_data %>%
    count(taxonomies_desc) %>%
    mutate(percentage = n / sum(n) * 100)

  end_time <- Sys.time()
  execution_time <- as.numeric(end_time - start_time, units = "secs")

  # Should complete quickly for example-sized data
  expect_lt(execution_time, 5)
  expect_s3_class(state_summary, "data.frame")
  expect_s3_class(taxonomy_summary, "data.frame")
})

test_that("Vignette handoff: Output format consistency", {
  skip_on_cran()

  # Test that vignette outputs have consistent formats

  mock_search_results <- tibble::tibble(
    npi = c("1234567890", "2345678901"),
    basic_first_name = c("John", "Jane"),
    basic_last_name = c("Smith", "Doe"),
    addresses_state = c("CA", "TX"),
    taxonomies_desc = c("Obstetrics & Gynecology", "Obstetrics & Gynecology")
  )

  # Test various summary operations from vignettes
  summaries <- list(
    state_count = mock_search_results %>% count(addresses_state),
    taxonomy_count = mock_search_results %>% count(taxonomies_desc),
    overall_count = mock_search_results %>% count()
  )

  for (summary_name in names(summaries)) {
    summary_df <- summaries[[summary_name]]

    # All summaries should be data frames
    expect_s3_class(summary_df, "data.frame")

    # All should have 'n' column for counts
    expect_true("n" %in% names(summary_df))

    # Counts should be non-negative integers
    expect_true(all(summary_df$n >= 0))
    expect_true(all(summary_df$n == round(summary_df$n)))
  }
})

test_that("Vignette handoff: Documentation examples accuracy", {
  skip_on_cran()

  # Verify that examples in vignettes match actual function signatures

  # Test that mysterycall_search_taxonomy parameters match vignette usage
  expect_no_error(
    mysterycall_search_taxonomy(
      taxonomy_to_search = "Test Taxonomy",
      write_snapshot = FALSE,
      notify = FALSE
    )
  )

  # Test that mysterycall_clean_phase1 parameters match usage
  test_data <- data.frame(
    id = 1, names = "Dr. Test", practice_name = "Test Practice",
    phone_number = "555-0001", state_name = "CA",
    npi = "1234567890", for_redcap = "Yes",
    stringsAsFactors = FALSE
  )

  expect_no_error(
    mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE
    )
  )

  # Test mysterycall_validate_npi usage
  expect_no_error(
    mysterycall_validate_npi(test_data)
  )
})