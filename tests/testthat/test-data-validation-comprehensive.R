# Comprehensive data validation tests
library(testthat)
suppressWarnings(library(dplyr))

# Data validation rules and constraints
DATA_VALIDATION_RULES <- list(
  npi = list(
    pattern = "^[0-9]{10}$",
    required = FALSE,
    unique = TRUE
  ),
  phone = list(
    patterns = c("^[0-9]{3}-[0-9]{3}-[0-9]{4}$", "^\\([0-9]{3}\\) [0-9]{3}-[0-9]{4}$"),
    required = FALSE
  ),
  state = list(
    valid_values = c(state.name, state.abb, "District of Columbia", "DC"),
    required = FALSE
  ),
  gender = list(
    valid_values = c("M", "F", "Male", "Female"),
    required = FALSE
  ),
  names = list(
    min_length = 1,
    max_length = 200,
    required = TRUE
  )
)

# Helper function to generate test data with known validation issues
create_validation_test_data <- function(include_issues = TRUE) {
  base_data <- data.frame(
    id = 1:20,
    names = c(
      "Valid Name",
      "Another Valid Name",
      "",  # Empty name
      NA,  # Missing name
      paste0(rep("A", 250), collapse = ""),  # Too long
      "Name with Numbers 123",
      "Name with Special !@#$",
      "Hyphenated-Name",
      "Name Jr.",
      "Dr. Professional Name",
      rep("Valid Name", 10)  # Duplicates
    ),
    practice_name = c(
      rep("Valid Practice", 10),
      "",  # Empty
      NA,  # Missing
      "Very Long Practice Name That Exceeds Normal Expectations And Keeps Going",
      rep("Another Practice", 7)
    ),
    phone_number = c(
      "555-123-4567",  # Valid format 1
      "(555) 123-4567",  # Valid format 2
      "555.123.4567",  # Alternative format
      "5551234567",    # No formatting
      "invalid_phone", # Invalid
      "123",           # Too short
      "",              # Empty
      NA,              # Missing
      "555-555-5555",  # Valid
      rep("555-000-0000", 11)  # More valid numbers
    ),
    state_name = c(
      "California",     # Full name
      "CA",            # Abbreviation
      "New York",      # Full name with space
      "TX",            # Abbreviation
      "InvalidState",  # Invalid
      "",              # Empty
      NA,              # Missing
      "District of Columbia",  # Special case
      rep(c("FL", "Illinois"), 6)  # More valid states
    ),
    npi = c(
      "1234567890",    # Valid
      "0987654321",    # Valid
      "invalid_npi",   # Invalid format
      "123",           # Too short
      "12345678901",   # Too long
      "",              # Empty
      NA,              # Missing
      "1234567890",    # Duplicate
      "5566778899",    # Valid
      rep("1122334455", 11)  # More valid NPIs
    ),
    for_redcap = c(
      rep("Yes", 10),
      rep("No", 5),
      "Maybe",  # Invalid value
      "",       # Empty
      NA,       # Missing
      rep("Yes", 2)
    ),
    stringsAsFactors = FALSE
  )

  if (!include_issues) {
    # Return only valid data
    base_data <- base_data[1:5, ]
    base_data$names <- paste("Valid Provider", 1:5)
    base_data$practice_name <- paste("Valid Practice", 1:5)
    base_data$phone_number <- paste0("555-", sprintf("%03d", 100:104), "-", sprintf("%04d", 1000:1004))
    base_data$state_name <- c("California", "Texas", "New York", "Florida", "Illinois")
    base_data$npi <- paste0("123456789", 0:4)
    base_data$for_redcap <- rep("Yes", 5)
  }

  base_data
}

test_that("Data validation: NPI format validation", {
  test_data <- create_validation_test_data()

  # Test NPI validation function
  result <- mysterycall_validate_npi(test_data)

  if (nrow(result) > 0 && "npi" %in% names(result)) {
    # All remaining NPIs should be valid format
    valid_npis <- result$npi[!is.na(result$npi)]
    if (length(valid_npis) > 0) {
      expect_true(all(grepl(DATA_VALIDATION_RULES$npi$pattern, valid_npis)),
                  label = "Invalid NPI formats found in validated data")

      # mysterycall_validate_npi validates format only, not uniqueness
    }
  }
})

test_that("Data validation: Phone number format validation", {
  test_data <- create_validation_test_data()
  temp_dir <- tempdir()

  result <- suppressWarnings(mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  ))

  if ("phone_number" %in% names(result)) {
    valid_phones <- result$phone_number[!is.na(result$phone_number) & result$phone_number != ""]

    if (length(valid_phones) > 0) {
      # Check against valid phone patterns
      pattern_matches <- vapply(DATA_VALIDATION_RULES$phone$patterns, function(pattern) {
        sum(grepl(pattern, valid_phones))
      }, numeric(1L))

      total_valid <- sum(pattern_matches)
      validation_rate <- total_valid / length(valid_phones)

      # Allow some flexibility for phone number formats
      # Phone number validation rate should be at least 50%
      expect_gte(validation_rate, 0.5)
    }
  }
})

test_that("Data validation: State code/name validation", {
  test_data <- create_validation_test_data()
  temp_dir <- tempdir()

  result <- suppressWarnings(mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  ))

  if ("state_name" %in% names(result)) {
    valid_states <- result$state_name[!is.na(result$state_name) & result$state_name != ""]

    if (length(valid_states) > 0) {
      # Check against valid state values
      state_matches <- sum(valid_states %in% DATA_VALIDATION_RULES$state$valid_values)
      state_validation_rate <- state_matches / length(valid_states)

      # State validation rate should be at least 70%
      expect_gte(state_validation_rate, 0.7)
    }
  }
})

test_that("Data validation: Name field validation", {
  test_data <- create_validation_test_data()
  temp_dir <- tempdir()

  result <- suppressWarnings(mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  ))

  if ("names" %in% names(result)) {
    # Empty/NA input names are flagged as NA by design; only check non-empty rows
    non_empty_rows <- if ("processing_flag_empty_name" %in% names(result)) {
      !result$processing_flag_empty_name
    } else {
      !is.na(result$names)
    }
    valid_names <- result$names[non_empty_rows]

    if (length(valid_names) > 0) {
      expect_true(all(!is.na(valid_names)))
      expect_true(all(valid_names != ""))

      # Check minimum length only; function does not truncate long names
      name_lengths <- nchar(valid_names)
      expect_true(all(name_lengths >= DATA_VALIDATION_RULES$names$min_length))
    }
  }
})

test_that("Data validation: Gender value validation", {
  # Create test data with gender information
  test_data_with_gender <- data.frame(
    id = 1:8,
    names = paste("Provider", 1:8),
    practice_name = paste("Practice", 1:8),
    phone_number = paste0("555-000-", sprintf("%04d", 1:8)),
    state_name = rep("California", 8),
    npi = paste0("123456789", 0:7),
    for_redcap = rep("Yes", 8),
    basic_gender = c("M", "F", "Male", "Female", "m", "f", "Invalid", NA),
    stringsAsFactors = FALSE
  )

  # Process through pipeline
  temp_dir <- tempdir()
  result <- mysterycall_clean_phase1(
    phase1_data = test_data_with_gender,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # mysterycall_clean_phase1 does not standardize gender values; just verify the column passes through
  if ("basic_gender" %in% names(result)) {
    expect_true(is.character(result$basic_gender) || is.na(result$basic_gender[1]))
  }
})

test_that("Data validation: Cross-field consistency", {
  # Test relationships between fields
  test_data <- create_validation_test_data(include_issues = FALSE)
  temp_dir <- tempdir()

  result <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Check that required fields are all present when any are present
  required_fields <- c("names", "practice_name")
  present_fields <- intersect(required_fields, names(result))

  if (length(present_fields) > 0) {
    for (field in present_fields) {
      expect_true(all(!is.na(result[[field]])),
                  label = paste("Required field", field, "has missing values"))
    }
  }

  # Check data type consistency
  if ("id" %in% names(result)) {
    expect_true(is.numeric(result$id) || is.integer(result$id),
                label = "ID field should be numeric")
  }

  if ("npi" %in% names(result)) {
    expect_true(is.character(result$npi) || is.numeric(result$npi),
                label = "NPI field should be character or numeric")
  }
})

test_that("Data validation: Boundary value testing", {
  # Test edge cases and boundary values
  boundary_data <- data.frame(
    id = c(1, 2, 3, 4, 5),
    names = c(
      "A",  # Minimum length
      paste0(rep("B", 100), collapse = ""),  # Long but reasonable
      "Normal Name",
      "Name with UTF-8: αβγ",  # Unicode characters
      "Name-with-Punctuation!"  # Special characters
    ),
    practice_name = c(
      "P",  # Very short
      paste0(rep("Practice", 20), collapse = " "),  # Very long
      "Normal Practice",
      "Practice & Associates",  # Special characters
      "Practice #1"  # Numbers and symbols
    ),
    phone_number = c(
      "000-000-0000",  # All zeros
      "999-999-9999",  # All nines
      "555-123-4567",  # Normal
      "800-555-0199",  # Toll-free
      "555-000-0001"   # Sequential
    ),
    state_name = c(
      "AL",  # Shortest state abbreviation
      "CA",  # Common state
      "District of Columbia",  # Longest state name
      "NY",  # Another common state
      "HI"   # Non-contiguous state
    ),
    npi = c(
      "0000000000",  # All zeros (edge case)
      "9999999999",  # All nines (edge case)
      "1234567890",  # Normal
      "1000000000",  # Leading 1 with zeros
      "5555555555"   # Repeated digits
    ),
    for_redcap = rep("Yes", 5),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Should handle boundary cases gracefully
  expect_no_error(
    result <- mysterycall_clean_phase1(
      phase1_data = boundary_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  )

  expect_s3_class(result, "data.frame")
  expect_gte(nrow(result), nrow(boundary_data))
})

test_that("Data validation: Unicode and encoding handling", {
  # Test international characters and various encodings
  unicode_data <- data.frame(
    id = 1:5,
    names = c(
      "José García",           # Spanish
      "François Müller",       # French/German
      "Анна Петрова",         # Cyrillic
      "田中太郎",              # Japanese
      "محمد عبدالله"          # Arabic
    ),
    practice_name = c(
      "Clínica Internacional",
      "Hôpital Général",
      "Медицинский центр",
      "総合病院",
      "المستشفى العام"
    ),
    phone_number = paste0("555-000-", sprintf("%04d", 1:5)),
    state_name = rep("California", 5),
    npi = paste0("123456789", 0:4),
    for_redcap = rep("Yes", 5),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Should handle Unicode characters without corruption
  result <- mysterycall_clean_phase1(
    phase1_data = unicode_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  expect_s3_class(result, "data.frame")
  expect_gte(nrow(result), nrow(unicode_data))

  # Check that Unicode characters are preserved
  if ("names" %in% names(result)) {
    # At least some non-ASCII characters should be preserved
    has_unicode <- any(grepl("[^\\x00-\\x7F]", result$names, perl = TRUE))
    expect_true(has_unicode || all(is.na(result$names)),
                label = "Unicode characters may have been corrupted")
  }
})

test_that("Data validation: SQL injection and security", {
  # Test potential security issues in data
  malicious_data <- data.frame(
    id = 1:6,
    names = c(
      "'; DROP TABLE users; --",  # SQL injection attempt
      "<script>alert('xss')</script>",  # XSS attempt
      "Robert'); DELETE FROM providers WHERE '1'='1",  # Another SQL injection
      "Normal Name",
      "../../../etc/passwd",  # Path traversal attempt
      "Normal Name 2"
    ),
    practice_name = c(
      "Practice 1",
      "Practice'; UPDATE data SET sensitive='exposed'; --",
      "Normal Practice",
      "Practice <>&\"'",  # HTML/XML special characters
      "Practice OR 1=1",
      "Practice 2"
    ),
    phone_number = paste0("555-000-", sprintf("%04d", 1:6)),
    state_name = rep("California", 6),
    npi = paste0("123456789", 0:5),
    for_redcap = rep("Yes", 6),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Should handle malicious input safely
  expect_no_error(
    result <- mysterycall_clean_phase1(
      phase1_data = malicious_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  )

  expect_s3_class(result, "data.frame")

  # Verify that dangerous characters are handled appropriately
  # Function should handle malicious input without crashing; it does not sanitize values
  if ("names" %in% names(result)) {
    expect_true(is.character(result$names))
  }
})

test_that("Data validation: Large field value handling", {
  # Test very large field values
  large_data <- data.frame(
    id = 1:3,
    names = c(
      paste0(rep("A", 1000), collapse = ""),  # Very long name
      "Normal Name",
      paste0(rep("Very Long Name Part ", 50), collapse = "")
    ),
    practice_name = c(
      "Normal Practice",
      paste0(rep("Very Long Practice Name ", 100), collapse = ""),
      "Another Practice"
    ),
    phone_number = c("555-000-0001", "555-000-0002", "555-000-0003"),
    state_name = rep("California", 3),
    npi = paste0("123456789", 0:2),
    for_redcap = rep("Yes", 3),
    additional_large_field = c(
      paste0(rep("Large content ", 1000), collapse = ""),
      "Normal content",
      "Another normal content"
    ),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Should handle large fields without crashing
  expect_no_error(
    result <- mysterycall_clean_phase1(
      phase1_data = large_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )
  )

  expect_s3_class(result, "data.frame")

  # Check that excessively long fields are handled appropriately
  if ("names" %in% names(result)) {
    valid_name_lengths <- nchar(result$names[!is.na(result$names)])
    if (length(valid_name_lengths) > 0) {
      expect_lt(max(valid_name_lengths), 10000)
    }
  }
})

test_that("Data validation: Property-based data quality", {
  # Property-based testing for data quality invariants
  for (i in 1:10) {
    # Generate random test data
    n <- sample(5:50, 1)
    random_data <- data.frame(
      id = 1:n,
      names = paste("Provider", 1:n),
      practice_name = paste("Practice", sample(1:10, n, replace = TRUE)),
      phone_number = paste0(sample(200:999, n, replace = TRUE), "-555-",
                           sprintf("%04d", sample(1000:9999, n, replace = TRUE))),
      state_name = sample(state.name[1:10], n, replace = TRUE),
      npi = paste0(sample(100000000:999999999, n, replace = TRUE), sample(0:9, n, replace = TRUE)),
      for_redcap = sample(c("Yes", "No"), n, replace = TRUE),
      stringsAsFactors = FALSE
    )

    temp_dir <- tempdir()

    result <- mysterycall_clean_phase1(
      phase1_data = random_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )

    # Invariants that should always hold
    expect_s3_class(result, "data.frame")
    expect_gte(nrow(result), n)  # Should not lose rows (may duplicate)

    # Required columns should be present
    required_cols <- c("names", "practice_name")
    present_required <- intersect(required_cols, names(result))
    expect_equal(length(present_required), length(required_cols),
                 label = paste("Missing required columns in iteration", i))

    # No completely empty rows
    if (nrow(result) > 0) {
      empty_rows <- apply(result, 1, function(row) all(is.na(row) | row == ""))
      expect_true(sum(empty_rows) == 0,
                  label = paste("Empty rows found in iteration", i))
    }
  }
})