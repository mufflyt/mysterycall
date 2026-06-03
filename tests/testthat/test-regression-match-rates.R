# Regression tests for match rates and data quality
library(testthat)
library(mysterycall)
library(dplyr)

# Store baseline match rates and quality metrics
# These represent "known good" performance that should not degrade
BASELINE_METRICS <- list(
  mysterycall_search_taxonomy = list(
    min_match_rate = 0.8,  # At least 80% of searches should return results
    max_error_rate = 0.1,  # No more than 10% should fail
    min_data_quality = 0.95  # 95% of returned data should be valid
  ),
  mysterycall_clean_phase1 = list(
    min_retention_rate = 0.9,  # Should retain at least 90% of input rows
    max_error_rate = 0.05,     # No more than 5% processing errors
    required_columns_present = 1.0  # 100% of required columns should be present
  ),
  npi_validation = list(
    min_valid_npi_rate = 0.95,  # 95% of NPIs should be valid format
    max_duplicate_rate = 0.01   # No more than 1% duplicates
  )
)

# Helper function to create consistent test datasets
create_regression_test_data <- function(scenario = "standard") {
  switch(scenario,
    "standard" = data.frame(
      id = 1:10,
      names = paste("Provider", 1:10),
      practice_name = paste("Practice", 1:10),
      phone_number = paste0("555-000-", sprintf("%04d", 1:10)),
      state_name = sample(c("California", "Texas", "New York"), 10, replace = TRUE),
      npi = c(paste0("123456789", 0:8), "1234567899"),
      for_redcap = rep("Yes", 10),
      stringsAsFactors = FALSE
    ),
    "challenging" = data.frame(
      id = 1:20,
      names = c(paste("Dr.", sample(c("John", "Jane", "Michael", "Sarah"), 15, replace = TRUE),
                     sample(c("Smith", "Johnson", "Williams", "Brown"), 15, replace = TRUE)),
                rep("", 3), rep(NA, 2)),  # Some problematic entries
      practice_name = c(paste("Practice", 1:17), "", NA, "Single"),
      phone_number = c(paste0("555-", sprintf("%03d", 100:116)), "invalid", "123", ""),
      state_name = c(sample(state.name[1:10], 17, replace = TRUE), "", "InvalidState", NA),
      npi = c(paste0("123456789", 0:9), paste0("098765432", 0:6), "invalid", "123", NA),
      for_redcap = c(rep("Yes", 15), rep("No", 3), "Maybe", NA),
      stringsAsFactors = FALSE
    )
  )
}

test_that("Regression: mysterycall_search_taxonomy match rates", {
  skip_on_cran()

  # Test known taxonomy terms that should consistently return results
  known_taxonomies <- c(
    "Obstetrics & Gynecology",
    "Gynecologic Oncology",
    "Maternal & Fetal Medicine"
  )

  # Mock stable search results for regression testing
  mock_npi_search <- function(taxonomy_description, ...) {
    # Simulate consistent results for known taxonomies
    if (taxonomy_description %in% known_taxonomies) {
      n_results <- switch(taxonomy_description,
        "Obstetrics & Gynecology" = 50,
        "Gynecologic Oncology" = 20,
        "Maternal & Fetal Medicine" = 15,
        5
      )

      list(
        npi = paste0("123456789", 0:(n_results-1)),
        basic_first_name = paste("Provider", 1:n_results),
        basic_last_name = paste("Last", 1:n_results),
        basic_credential = rep("MD", n_results),
        basic_gender = sample(c("M", "F"), n_results, replace = TRUE),
        addresses_country_name = rep("United States", n_results),
        taxonomies_desc = rep(taxonomy_description, n_results)
      )
    } else {
      list()  # Empty result for unknown taxonomies
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
    {
      results <- list()
      errors <- 0

      for (taxonomy in known_taxonomies) {
        tryCatch({
          result <- mysterycall_search_taxonomy(taxonomy, write_snapshot = FALSE, notify = FALSE)
          results[[taxonomy]] <- result
        }, error = function(e) {
          errors <<- errors + 1
        })
      }

      # Calculate match rate
      successful_searches <- length(results)
      match_rate <- successful_searches / length(known_taxonomies)

      # Calculate error rate
      error_rate <- errors / length(known_taxonomies)

      # Regression checks
      expect_gte(match_rate, BASELINE_METRICS$mysterycall_search_taxonomy$min_match_rate)

      expect_lte(error_rate, BASELINE_METRICS$mysterycall_search_taxonomy$max_error_rate)

      # Data quality checks
      for (result in results) {
        if (nrow(result) > 0) {
          # Check NPI format validity
          valid_npis <- sum(grepl("^[0-9]{10}$", result$npi[!is.na(result$npi)]))
          npi_quality_rate <- valid_npis / nrow(result)

          expect_gte(npi_quality_rate, BASELINE_METRICS$mysterycall_search_taxonomy$min_data_quality)
        }
      }
    }
  )
})

test_that("Regression: mysterycall_clean_phase1 retention rates", {
  test_scenarios <- c("standard", "challenging")

  for (scenario in test_scenarios) {
    test_data <- create_regression_test_data(scenario)
    original_rows <- nrow(test_data)

    temp_dir <- tempdir()

    tryCatch({
      result <- mysterycall_clean_phase1(
        phase1_data = test_data,
        output_directory = temp_dir,
        verbose = FALSE,
        notify = FALSE,
        duplicate_rows = FALSE  # For easier comparison
      )

      # Calculate retention rate
      retention_rate <- nrow(result) / original_rows

      # Check against baseline
      expect_gte(retention_rate, BASELINE_METRICS$mysterycall_clean_phase1$min_retention_rate)

      # Check required columns are present
      required_cols <- c("names", "practice_name", "phone_number", "state_name")
      present_cols <- sum(required_cols %in% names(result))
      column_presence_rate <- present_cols / length(required_cols)

      expect_equal(column_presence_rate,
                   BASELINE_METRICS$mysterycall_clean_phase1$required_columns_present)

    }, error = function(e) {
      # Should not have processing errors for valid input
      if (scenario == "standard") {
        fail(paste("Unexpected error in standard scenario:", e$message))
      }
    })
  }
})

test_that("Regression: NPI validation accuracy", {
  # Test data with known valid and invalid NPIs
  test_npis <- c(
    "1234567890",  # Valid format
    "0987654321",  # Valid format
    "1122334455",  # Valid format
    "invalid_npi", # Invalid format
    "123",         # Too short
    "12345678901", # Too long
    "",            # Empty
    NA             # Missing
  )

  test_data <- data.frame(
    id = seq_along(test_npis),
    npi = test_npis,
    names = paste("Provider", seq_along(test_npis)),
    practice_name = paste("Practice", seq_along(test_npis)),
    phone_number = paste0("555-000-", sprintf("%04d", seq_along(test_npis))),
    state_name = rep("California", length(test_npis)),
    for_redcap = rep("Yes", length(test_npis)),
    stringsAsFactors = FALSE
  )

  # Validate NPIs
  result <- mysterycall_validate_npi(test_data)

  # Calculate validation accuracy
  valid_npis_in_result <- if (nrow(result) > 0 && "npi" %in% names(result)) {
    sum(grepl("^[0-9]{10}$", result$npi[!is.na(result$npi)]))
  } else {
    0
  }

  total_npis_in_result <- if (nrow(result) > 0 && "npi" %in% names(result)) {
    sum(!is.na(result$npi))
  } else {
    0
  }

  if (total_npis_in_result > 0) {
    validation_accuracy <- valid_npis_in_result / total_npis_in_result

    expect_gte(validation_accuracy, BASELINE_METRICS$npi_validation$min_valid_npi_rate)
  }

  # Check for duplicates
  if (nrow(result) > 0 && "npi" %in% names(result)) {
    unique_npis <- length(unique(result$npi[!is.na(result$npi)]))
    total_npis <- sum(!is.na(result$npi))

    if (total_npis > 0) {
      duplicate_rate <- 1 - (unique_npis / total_npis)
      expect_lte(duplicate_rate, BASELINE_METRICS$npi_validation$max_duplicate_rate)
    }
  }
})

test_that("Regression: Taxonomy data completeness", {
  # Test that taxonomy reference data meets quality standards
  if (exists("taxonomy", envir = asNamespace("mysterycall"))) {
    taxonomy_data <- mysterycall::taxonomy

    expect_s3_class(taxonomy_data, "data.frame")
    expect_gt(nrow(taxonomy_data), 0)

    # Check required columns exist
    required_taxonomy_cols <- c("Code", "Classification")
    expect_true(all(required_taxonomy_cols %in% names(taxonomy_data)))

    # Check data quality
    if ("Code" %in% names(taxonomy_data)) {
      # Taxonomy codes should be 10 characters
      valid_codes <- sum(nchar(as.character(taxonomy_data$Code)) == 10, na.rm = TRUE)
      code_quality_rate <- valid_codes / nrow(taxonomy_data)

      expect_gte(code_quality_rate, 0.95)
    }

    # Check for OBGYN-related entries
    if ("Classification" %in% names(taxonomy_data)) {
      obgyn_entries <- sum(grepl("Obstetrics|Gynecol", taxonomy_data$Classification, ignore.case = TRUE))
      expect_gt(obgyn_entries, 5)
    }
  }
})

test_that("Regression: Performance benchmarks", {
  # Test that performance hasn't degraded
  performance_data <- create_regression_test_data("standard")
  temp_dir <- tempdir()

  # Benchmark mysterycall_clean_phase1
  start_time <- Sys.time()
  result <- mysterycall_clean_phase1(
    phase1_data = performance_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )
  end_time <- Sys.time()

  processing_time <- as.numeric(end_time - start_time, units = "secs")

  # Should process small dataset quickly
  expect_lt(processing_time, 5)

  # Memory usage should be reasonable
  expect_s3_class(result, "data.frame")
  expect_true(object.size(result) < 1e6)  # Less than 1MB for small dataset
})

test_that("Regression: Cross-version data compatibility", {
  # Test that data structures remain consistent across versions
  test_data <- create_regression_test_data("standard")
  temp_dir <- tempdir()

  result <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Check that column names follow expected patterns
  expect_true(all(names(result) == janitor::make_clean_names(names(result))))

  # Check that data types are consistent
  if ("npi" %in% names(result)) {
    expect_true(is.character(result$npi) || is.numeric(result$npi))
  }

  if ("names" %in% names(result)) {
    expect_true(is.character(result$names))
  }

  # Check that row structure is preserved
  expect_equal(ncol(result), length(unique(names(result))))  # No duplicate column names
})

test_that("Regression: Error handling consistency", {
  # Test that error handling remains consistent

  temp_dir <- tempdir()

  # Test with completely invalid data
  invalid_data <- data.frame(
    invalid_col1 = 1:3,
    invalid_col2 = letters[1:3]
  )

  expect_error(
    mysterycall_clean_phase1(invalid_data, output_directory = temp_dir),
    "names"  # Should mention missing required column
  )

  # Test with NULL input
  expect_error(
    mysterycall_clean_phase1(NULL, output_directory = temp_dir),
    "data frame"
  )

  # Test with empty data frame
  expect_error(
    mysterycall_clean_phase1(data.frame(), output_directory = temp_dir),
    "at least one row"
  )
})

test_that("Regression: State and geographic data validation", {
  # Test geographic data consistency
  test_data <- data.frame(
    id = 1:5,
    names = paste("Provider", 1:5),
    practice_name = paste("Practice", 1:5),
    phone_number = paste0("555-000-", 1:5),
    state_name = c("California", "Texas", "New York", "Florida", "Illinois"),
    npi = paste0("123456789", 0:4),
    for_redcap = rep("Yes", 5),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  result <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Check that state information is preserved and valid
  if ("state_name" %in% names(result)) {
    valid_states <- c(state.name, state.abb, "District of Columbia", "DC")
    state_validity_rate <- sum(result$state_name %in% valid_states, na.rm = TRUE) / nrow(result)

    # Allow some flexibility for state name variations
    expect_gte(state_validity_rate, 0.8)
  }
})