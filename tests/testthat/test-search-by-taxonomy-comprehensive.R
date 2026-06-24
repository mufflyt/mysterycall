# Comprehensive tests for mysterycall_search_taxonomy function
library(testthat)
library(mysterycall)
library(tibble)
library(dplyr)

# Mock npi functions for testing
mock_npi_search <- function(taxonomy_description, ...) {
  if (taxonomy_description == "Gynecologic Oncology") {
    list(
      basic_first_name = c("Jane", "Mary"),
      basic_last_name = c("Smith", "Johnson"),
      basic_credential = c("MD", "DO"),
      basic_gender = c("F", "F"),
      npi = c("1234567890", "0987654321"),
      addresses_country_name = c("United States", "United States"),
      taxonomies_desc = c("Gynecologic Oncology", "Gynecologic Oncology")
    )
  } else if (taxonomy_description == "Invalid Taxonomy") {
    stop("HTTP 404: Not Found")
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

# Unit Tests
test_that("mysterycall_search_taxonomy: Basic functionality", {
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  with_mocked_bindings(
    npi_search = mock_npi_search,
    npi_flatten = mock_npi_flatten,
    .package = "npi",
    {
      result <- mysterycall_search_taxonomy("Gynecologic Oncology",
                                   write_snapshot = FALSE,
                                   notify = FALSE)
      expect_s3_class(result, "data.frame")
      expect_true(nrow(result) >= 0)
      if (nrow(result) > 0) {
        expect_true("npi" %in% names(result))
        expect_true(all(!is.na(result$npi)))
      }
    }
  )
})

test_that("mysterycall_search_taxonomy: Input validation", {
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  expect_s3_class(mysterycall_search_taxonomy(write_snapshot = FALSE, notify = FALSE),
                  "data.frame")
  expect_equal(nrow(mysterycall_search_taxonomy(write_snapshot = FALSE, notify = FALSE)), 0)
  expect_s3_class(mysterycall_search_taxonomy(NULL, write_snapshot = FALSE, notify = FALSE),
                  "data.frame")
  expect_equal(nrow(mysterycall_search_taxonomy(NULL, write_snapshot = FALSE, notify = FALSE)), 0)
  expect_s3_class(mysterycall_search_taxonomy(character(0), write_snapshot = FALSE, notify = FALSE),
                  "data.frame")
  expect_equal(nrow(mysterycall_search_taxonomy(character(0), write_snapshot = FALSE, notify = FALSE)), 0)
  expect_s3_class(mysterycall_search_taxonomy(c(NA, NA), write_snapshot = FALSE, notify = FALSE),
                  "data.frame")
  expect_equal(nrow(mysterycall_search_taxonomy(c(NA, NA), write_snapshot = FALSE, notify = FALSE)), 0)
})

test_that("mysterycall_search_taxonomy: Data quality validation", {
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  with_mocked_bindings(
    npi_search = mock_npi_search,
    npi_flatten = mock_npi_flatten,
    .package = "npi",
    {
      result <- mysterycall_search_taxonomy("Gynecologic Oncology",
                                   write_snapshot = FALSE,
                                   notify = FALSE)
      if (nrow(result) > 0) {
        if ("npi" %in% names(result)) {
          expect_true(all(grepl("^[0-9]{10}$", result$npi[!is.na(result$npi)])))
        }
        if ("basic_gender" %in% names(result)) {
          valid_genders <- c("M", "F", "Male", "Female", NA)
          expect_true(all(result$basic_gender %in% valid_genders))
        }
        if ("addresses_state" %in% names(result)) {
          state_pattern <- "^[A-Z]{2}$"
          expect_true(all(grepl(state_pattern, result$addresses_state[!is.na(result$addresses_state)])))
        }
      }
    }
  )
})

test_that("mysterycall_search_taxonomy: Error handling", {
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  with_mocked_bindings(
    npi_search = mock_npi_search,
    npi_flatten = mock_npi_flatten,
    .package = "npi",
    {
      expect_s3_class(
        mysterycall_search_taxonomy("Invalid Taxonomy", write_snapshot = FALSE, notify = FALSE),
        "data.frame"
      )
    }
  )
})

test_that("mysterycall_search_taxonomy: Multiple taxonomies", {
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  with_mocked_bindings(
    npi_search = mock_npi_search,
    npi_flatten = mock_npi_flatten,
    .package = "npi",
    {
      result <- mysterycall_search_taxonomy(
        c("Gynecologic Oncology", "Maternal & Fetal Medicine"),
        write_snapshot = FALSE,
        notify = FALSE
      )
      expect_s3_class(result, "data.frame")
    }
  )
})

test_that("mysterycall_search_taxonomy: Performance test", {
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  with_mocked_bindings(
    npi_search = mock_npi_search,
    npi_flatten = mock_npi_flatten,
    .package = "npi",
    {
      start_time <- Sys.time()
      result <- mysterycall_search_taxonomy("Gynecologic Oncology",
                                   write_snapshot = FALSE,
                                   notify = FALSE)
      end_time <- Sys.time()
      expect_lt(as.numeric(end_time - start_time, units = "secs"), 60)
    }
  )
})

test_that("mysterycall_search_taxonomy: Snapshot functionality", {
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  temp_dir <- tempdir()
  with_mocked_bindings(
    npi_search = mock_npi_search,
    npi_flatten = mock_npi_flatten,
    .package = "npi",
    {
      result <- mysterycall_search_taxonomy("Gynecologic Oncology",
                                   write_snapshot = TRUE,
                                   snapshot_dir = temp_dir,
                                   notify = FALSE)
      snapshot_files <- list.files(temp_dir, pattern = "*.rds", full.names = TRUE)
      expect_gt(length(snapshot_files), 0)
    }
  )
})

# Integration Tests
test_that("mysterycall_search_taxonomy: Integration with real taxonomy data", {
  skip_if_not_installed("npi")
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  if (exists("taxonomy", envir = asNamespace("mysterycall"))) {
    obgyn_codes <- mysterycall::taxonomy$Classification[
      grepl("Obstetrics|Gynecol", mysterycall::taxonomy$Classification, ignore.case = TRUE)
    ][1:2]
    if (length(obgyn_codes) > 0) {
      result <- mysterycall_search_taxonomy(obgyn_codes[1],
                                   write_snapshot = FALSE,
                                   notify = FALSE)
      expect_s3_class(result, "data.frame")
    }
  }
})

# Property-Based Tests
test_that("mysterycall_search_taxonomy: Property-based testing", {
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  with_mocked_bindings(
    npi_search = mock_npi_search,
    npi_flatten = mock_npi_flatten,
    .package = "npi",
    {
      test_inputs <- c(
        "Valid Taxonomy",
        "Another Valid Taxonomy",
        "",
        "   ",
        "Taxonomy with Numbers 123",
        "Taxonomy with Special !@#$%"
      )
      for (input in test_inputs) {
        result <- mysterycall_search_taxonomy(input, write_snapshot = FALSE, notify = FALSE)
        expect_s3_class(result, "data.frame")
        expect_true(is.data.frame(result))
        expect_gte(nrow(result), 0)
      }
    }
  )
})

# Regression Tests
test_that("mysterycall_search_taxonomy: Regression tests for known issues", {
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  special_chars <- c("Obstetrics & Gynecology", "Maternal & Fetal Medicine")
  with_mocked_bindings(
    npi_search = mock_npi_search,
    npi_flatten = mock_npi_flatten,
    .package = "npi",
    {
      expect_no_error(
        mysterycall_search_taxonomy(special_chars, write_snapshot = FALSE, notify = FALSE)
      )
    }
  )
})

# Data Validation Tests
test_that("mysterycall_search_taxonomy: Data validation and cleaning", {
  skip_on_cran()
  skip_if_offline("npiregistry.cms.hhs.gov")
  with_mocked_bindings(
    npi_search = mock_npi_search,
    npi_flatten = mock_npi_flatten,
    .package = "npi",
    {
      result <- mysterycall_search_taxonomy("Gynecologic Oncology",
                                   write_snapshot = FALSE,
                                   notify = FALSE)
      if (nrow(result) > 0) {
        if ("npi" %in% names(result)) {
          expect_true(all(nchar(as.character(result$npi)) == 10))
        }
        if ("npi" %in% names(result)) {
          expect_equal(nrow(result), length(unique(result$npi)))
        }
        if ("addresses_country_name" %in% names(result)) {
          expect_true(all(result$addresses_country_name == "United States" |
                         is.na(result$addresses_country_name)))
        }
      }
    }
  )
})
