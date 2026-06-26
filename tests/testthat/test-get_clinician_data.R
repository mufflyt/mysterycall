library(testthat)
testthat::skip_if_not_installed("readr")
testthat::skip_if_not_installed("dplyr")
library(readr)
library(dplyr)

# Luhn-valid 10-digit NPIs (pass mysterycall_validate_npi without mocking)
VALID_NPI_1 <- "1003000126"
VALID_NPI_2 <- "1740283779"

create_temp_csv <- function(data, file_name = "temp_npi_data.csv") {
  temp_file <- file.path(tempdir(), file_name)
  write_csv(data, temp_file)
  temp_file
}

sample_data_valid <- data.frame(
  npi = c(VALID_NPI_1, VALID_NPI_2),
  stringsAsFactors = FALSE
)
sample_data_invalid <- data.frame(
  npi = c("12345", "23456789012", "ABCDE12345", NA, ""),
  stringsAsFactors = FALSE
)
sample_data_mixed <- data.frame(
  npi = c(VALID_NPI_1, "23456789012", VALID_NPI_2, NA, ""),
  stringsAsFactors = FALSE
)

mock_clinicians <- function(npi, ...) {
  if (identical(as.character(npi), VALID_NPI_1)) {
    data.frame(name = "John Doe", specialty = "Cardiology", stringsAsFactors = FALSE)
  } else if (identical(as.character(npi), VALID_NPI_2)) {
    data.frame(name = "Jane Smith", specialty = "Neurology", stringsAsFactors = FALSE)
  } else {
    NULL
  }
}

test_that("Retrieves clinician data for valid NPIs", {
  skip_if_not_installed("provider")
  temp_csv <- create_temp_csv(sample_data_valid)
  with_mocked_bindings(
    clinicians = mock_clinicians,
    .package = "provider",
    {
      result <- mysterycall_get_clinician_data(temp_csv)
      expect_s3_class(result, "data.frame")
    }
  )
})

test_that("Handles invalid NPIs — all dropped by validate_npi", {
  temp_csv <- create_temp_csv(sample_data_invalid)
  result <- mysterycall_get_clinician_data(temp_csv)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0L)
})

test_that("Handles mixed valid and invalid NPIs", {
  skip_if_not_installed("provider")
  temp_csv <- create_temp_csv(sample_data_mixed)
  with_mocked_bindings(
    clinicians = mock_clinicians,
    .package = "provider",
    {
      result <- mysterycall_get_clinician_data(temp_csv)
      expect_s3_class(result, "data.frame")
    }
  )
})

test_that("Handles dataframe input correctly", {
  skip_if_not_installed("provider")
  with_mocked_bindings(
    clinicians = mock_clinicians,
    .package = "provider",
    {
      result <- mysterycall_get_clinician_data(sample_data_mixed)
      expect_s3_class(result, "data.frame")
    }
  )
})
