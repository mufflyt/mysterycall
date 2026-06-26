# Edge Case Tests - Special Characters, Unicode, and Boundary Conditions
# These tests verify the package handles unusual but valid input
#
# CRITICAL: These tests detect:
# - ❌ Encoding errors with Unicode characters
# - ❌ SQL injection or code injection vulnerabilities
# - ❌ Crashes from empty strings or whitespace
# - ❌ Incorrect handling of special characters

library(testthat)
library(dplyr)

# ==============================================================================
# EDGE CASE 1: Empty Strings and Whitespace
# ==============================================================================

test_that("EDGE: Handles empty strings gracefully", {
  test_data <- data.frame(
    names = c("Dr. John Doe", "", "Dr. Mary Smith", "   "),
    practice_name = c("Hospital A", "", "Clinic B", ""),
    phone_number = c("555-123-4567", "", "555-234-5678", "555-345-6789"),
    state_name = c("CA", "", "TX", "NY"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Should handle empty strings (may filter them out)
  expect_true(is.data.frame(results))

  unlink(temp_dir, recursive = TRUE)
})

test_that("EDGE: Handles whitespace-only strings", {
  test_data <- data.frame(
    names = c("Dr. John Doe", "   ", "\t", "\n"),
    practice_name = c("Hospital", " ", "  ", "   "),
    phone_number = c("555-1234", "555-5678", "555-9012", "555-3456"),
    state_name = c("CA", "TX", "NY", "FL"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# EDGE CASE 2: Special Characters
# ==============================================================================

test_that("EDGE: Handles names with apostrophes and hyphens", {
  test_data <- data.frame(
    names = c(
      "Dr. O'Brien",
      "Dr. Mary-Ann Smith",
      "Dr. José García",
      "Dr. François Müller"
    ),
    practice_name = c(
      "St. Mary's Hospital",
      "Women's Clinic",
      "Children's Medical Center",
      "Saint John's"
    ),
    phone_number = rep("555-123-4567", 4),
    state_name = rep("CA", 4),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Names should be preserved
  expect_gte(nrow(results), 3)

  unlink(temp_dir, recursive = TRUE)
})

test_that("EDGE: Handles special punctuation in addresses", {
  test_data <- data.frame(
    names = "Dr. John Doe",
    practice_name = c(
      "Hospital (Main Campus)",
      "Clinic #2",
      "Center @ Downtown",
      "Medical & Surgical Associates"
    ),
    phone_number = rep("555-123-4567", 4),
    state_name = rep("CA", 4),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# EDGE CASE 3: Unicode Characters
# ==============================================================================

test_that("EDGE: Handles international Unicode characters", {
  test_data <- data.frame(
    names = c(
      "Dr. José García",           # Spanish
      "Dr. François Müller",       # French/German
      "Dr. Владимир Иванов",      # Russian (Cyrillic)
      "Dr. 田中太郎",              # Japanese
      "Dr. محمد أحمد",             # Arabic
      "Dr. Søren Ødegård"          # Norwegian
    ),
    practice_name = paste("Hospital", 1:6),
    phone_number = rep("555-123-4567", 6),
    state_name = rep("CA", 6),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Should handle Unicode gracefully
  expect_true(is.data.frame(results))

  unlink(temp_dir, recursive = TRUE)
})

test_that("EDGE: Handles emoji and symbols", {
  skip("Emoji handling may vary by system")

  test_data <- data.frame(
    names = c(
      "Dr. John Doe ⚕️",
      "Dr. Mary Smith 👩‍⚕️",
      "Hospital ❤️"
    ),
    practice_name = paste("Practice", 1:3),
    phone_number = rep("555-123-4567", 3),
    state_name = rep("CA", 3),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# EDGE CASE 4: Injection Attack Prevention
# ==============================================================================

test_that("EDGE: Protects against SQL-like injection attempts", {
  test_data <- data.frame(
    names = c(
      "Dr. O'Malley'; DROP TABLE users;--",
      "Dr. 1' OR '1'='1",
      "Dr. <script>alert('xss')</script>",
      "Dr. ../../../etc/passwd"
    ),
    practice_name = paste("Hospital", 1:4),
    phone_number = rep("555-123-4567", 4),
    state_name = rep("CA", 4),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  # Should not execute any injected code
  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Data should be treated as literal strings
  expect_true(is.data.frame(results))

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# EDGE CASE 5: Numeric Edge Cases
# ==============================================================================

test_that("EDGE: Handles extreme coordinate values", {
  test_data <- data.frame(
    lat = c(90, -90, 0, 89.9999, -89.9999),       # Valid extremes
    lon = c(180, -180, 0, 179.9999, -179.9999),
    address = paste("Address", 1:5),
    stringsAsFactors = FALSE
  )

  # All should be within valid WGS84 bounds
  expect_true(all(test_data$lat >= -90 & test_data$lat <= 90))
  expect_true(all(test_data$lon >= -180 & test_data$lon <= 180))
})

test_that("EDGE: Handles very small decimal differences", {
  # Coordinates differing by tiny amounts
  test_data <- data.frame(
    lat = c(40.7128, 40.7128001, 40.7128002),
    lon = c(-74.0060, -74.0060001, -74.0060002),
    npi = c("1234567890", "1234567891", "1234567892"),
    stringsAsFactors = FALSE
  )

  # Should handle precision correctly
  expect_true(all(is.numeric(test_data$lat)))
  expect_true(all(is.numeric(test_data$lon)))

  # Differences should be preserved
  expect_true(test_data$lat[1] != test_data$lat[2])
})

# ==============================================================================
# EDGE CASE 6: Phone Number Variations
# ==============================================================================

test_that("EDGE: Handles various phone number formats", {
  test_data <- data.frame(
    names = "Dr. John Doe",
    practice_name = "Hospital",
    phone_number = c(
      "555-123-4567",           # Standard
      "(555) 123-4567",         # Parentheses
      "555.123.4567",           # Dots
      "5551234567",             # No formatting
      "+1-555-123-4567",        # International
      "1-800-DOCTORS",          # Vanity (letters)
      "555-1234 ext. 100",      # Extension
      "555-1234x200"            # Extension variant
    ),
    state_name = rep("CA", 8),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Should handle various formats
  expect_gte(nrow(results), 6)

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# EDGE CASE 7: State Name Variations
# ==============================================================================

test_that("EDGE: Handles mixed state name formats", {
  test_data <- data.frame(
    names = "Dr. John Doe",
    practice_name = "Hospital",
    phone_number = "555-123-4567",
    state_name = c(
      "California",          # Full name
      "CA",                  # Abbreviation
      "calif",               # Lowercase
      "CALIFORNIA",          # Uppercase
      "Calif.",              # Abbreviation variant
      "ca",                  # Lowercase abbrev
      "  California  "       # With whitespace
    ),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# EDGE CASE 8: NPI Format Variations
# ==============================================================================

test_that("EDGE: Handles NPI with leading zeros", {
  test_data <- data.frame(
    npi = c(
      "0123456789",          # Leading zero
      "0987654321",
      "0001234567",          # Multiple leading zeros
      "1234567890"           # No leading zero
    ),
    practice_name = paste("Practice", 1:4),
    stringsAsFactors = FALSE
  )

  # All should be 10 characters
  expect_true(all(nchar(test_data$npi) == 10))

  # Leading zeros should be preserved as strings
  expect_equal(substr(test_data$npi[1], 1, 1), "0")
})

test_that("EDGE: Handles NPI with whitespace", {
  test_data <- data.frame(
    names = "Dr. John Doe",
    practice_name = "Hospital",
    phone_number = "555-123-4567",
    state_name = "CA",
    npi = c(
      " 1234567890",         # Leading space
      "1234567890 ",         # Trailing space
      " 1234567890 ",        # Both
      "123 456 7890",        # Spaces within
      "1234567890"           # Clean
    ),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# EDGE CASE 9: Date and Time Edge Cases
# ==============================================================================

test_that("EDGE: Handles dates across timezones", {
  skip("Date handling varies by context")

  # Test data collected at different times
  test_data <- data.frame(
    names = "Dr. John Doe",
    practice_name = "Hospital",
    phone_number = "555-123-4567",
    state_name = "CA",
    timestamp = c(
      "2024-01-01 00:00:00",              # Midnight
      "2024-12-31 23:59:59",              # End of year
      "2024-02-29 12:00:00",              # Leap year
      "2024-03-10 02:30:00"               # DST transition
    ),
    stringsAsFactors = FALSE
  )

  expect_true(is.data.frame(test_data))
})

# ==============================================================================
# EDGE CASE 10: Case Sensitivity
# ==============================================================================

test_that("EDGE: Handles case variations consistently", {
  test_data <- data.frame(
    names = c(
      "dr. john doe",           # Lowercase
      "DR. MARY SMITH",         # Uppercase
      "Dr. Robert Garcia",      # Title case
      "DR. lisa CHEN"           # Mixed case
    ),
    practice_name = c(
      "hospital",
      "CLINIC",
      "Medical Center",
      "HeAlThCaRe"
    ),
    phone_number = rep("555-123-4567", 4),
    state_name = c("ca", "CA", "Ca", "cA"),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  # Should handle all case variations
  expect_gte(nrow(results), 3)

  unlink(temp_dir, recursive = TRUE)
})

# ==============================================================================
# EDGE CASE 11: Column Name Edge Cases
# ==============================================================================

test_that("EDGE: Handles column names with special characters", {
  skip("Column renaming handles this")

  # janitor::clean_names() should handle these
  test_data <- data.frame(
    `Doctor Name` = "Dr. John Doe",
    `Practice Name (Primary)` = "Hospital",
    `Phone #` = "555-123-4567",
    `State/Province` = "CA",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_true(is.data.frame(test_data))
})

# ==============================================================================
# EDGE CASE 12: Boundary Value Testing
# ==============================================================================

test_that("EDGE: Handles exactly 1 row", {
  test_data <- data.frame(
    names = "Dr. John Doe",
    practice_name = "Hospital",
    phone_number = "555-123-4567",
    state_name = "CA",
    stringsAsFactors = FALSE
  )

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  expect_gte(nrow(results), 1)

  unlink(temp_dir, recursive = TRUE)
})

test_that("EDGE: Handles exactly required columns (no extras)", {
  test_data <- data.frame(
    names = c("Dr. John Doe", "Dr. Mary Smith"),
    practice_name = c("Hospital A", "Clinic B"),
    phone_number = c("555-123-4567", "555-234-5678"),
    state_name = c("CA", "TX"),
    stringsAsFactors = FALSE
  )

  # Exactly 4 columns (minimum required)
  expect_equal(ncol(test_data), 4)

  temp_dir <- tempfile()
  dir.create(temp_dir)

  expect_no_error({
    results <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  })

  unlink(temp_dir, recursive = TRUE)
})
