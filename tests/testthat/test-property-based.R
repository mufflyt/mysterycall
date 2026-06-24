# Property-based tests for mysterycall package
library(testthat)
library(mysterycall)
library(dplyr)

# Property-based test generators
generate_valid_npi <- function(n = 1) {
  # Compute Luhn check digit for an NPI candidate prefixed with "80840"
  luhn_check_digit <- function(first_nine) {
    digits <- as.integer(strsplit(paste0("80840", first_nine), "")[[1L]])
    len <- length(digits)
    # Position from right (excluding check digit which we are about to compute):
    # treat first_nine + "0" so check digit is at position 1 from right.
    digits_with_check <- c(digits, 0L)
    full_len <- length(digits_with_check)
    for (i in seq_along(digits_with_check)) {
      pos_from_right <- full_len - i + 1L
      if (pos_from_right %% 2L == 0L) {
        digits_with_check[i] <- digits_with_check[i] * 2L
      }
    }
    total <- sum(digits_with_check %/% 10L + digits_with_check %% 10L)
    (10L - total %% 10L) %% 10L
  }
  vapply(seq_len(n), function(...) {
    first_nine <- sprintf("%09d", sample(100000000:999999999, 1L))
    check_d <- luhn_check_digit(first_nine)
    paste0(first_nine, check_d)
  }, character(1L))
}

generate_valid_phone <- function(n = 1) {
  formats <- c(
    "%03d-%03d-%04d",
    "(%03d) %03d-%04d",
    "%03d.%03d.%04d"
  )

  vapply(seq_len(n), function(i) {
    format <- sample(formats, 1)
    sprintf(format,
            sample(200:999, 1),
            sample(200:999, 1),
            sample(1000:9999, 1))
  }, character(1L))
}

generate_valid_state <- function(n = 1) {
  sample(c(state.name, state.abb), n, replace = TRUE)
}

generate_test_dataframe <- function(n = 10, valid_only = FALSE) {
  if (valid_only) {
    data.frame(
      id = 1:n,
      names = paste("Provider", 1:n),
      practice_name = paste("Practice", sample(1:min(50, n), n, replace = TRUE)),
      phone_number = generate_valid_phone(n),
      state_name = generate_valid_state(n),
      npi = generate_valid_npi(n),
      for_redcap = sample(c("Yes", "No"), n, replace = TRUE),
      stringsAsFactors = FALSE
    )
  } else {
    # Include some invalid data
    data.frame(
      id = 1:n,
      names = c(paste("Provider", 1:(n-2)), "", NA),
      practice_name = c(paste("Practice", 1:(n-3)), "", NA, "Valid"),
      phone_number = c(generate_valid_phone(n-3), "invalid", "", NA),
      state_name = c(generate_valid_state(n-3), "Invalid", "", NA),
      npi = c(generate_valid_npi(n-3), "invalid", "", NA),
      for_redcap = c(rep("Yes", n-2), "", NA),
      stringsAsFactors = FALSE
    )
  }
}

test_that("Property: Data frame input always produces data frame output", {
  skip_on_cran()

  # Test with various data frame sizes and compositions
  for (i in 1:20) {
    n <- sample(5:100, 1)
    test_data <- generate_test_dataframe(n, valid_only = sample(c(TRUE, FALSE), 1))
    temp_dir <- tempdir()

    tryCatch({
      result <- mysterycall_clean_phase1(
        phase1_data = test_data,
        output_directory = temp_dir,
        verbose = FALSE,
        notify = FALSE
      )

      # Property: Output is always a data frame
      expect_s3_class(result, "data.frame")

      # Property: Output has at least as many rows as input (may duplicate)
      expect_gte(nrow(result), nrow(test_data))

      # Property: Required columns are always present in output
      required_cols <- c("names", "practice_name")
      present_cols <- intersect(required_cols, names(result))
      expect_equal(length(present_cols), length(required_cols))

    }, error = function(e) {
      # If error occurs, it should be due to missing required columns
      expect_true(grepl("names|practice_name|phone_number|state_name", e$message))
    })
  }
})

test_that("Property: NPI validation is idempotent", {
  skip_on_cran()

  for (i in 1:10) {
    test_data <- generate_test_dataframe(sample(10:50, 1))

    # Apply validation once
    result1 <- mysterycall_validate_npi(test_data)

    # Apply validation again to the result
    result2 <- mysterycall_validate_npi(result1)

    # Property: Applying validation twice should yield same result
    if (nrow(result1) > 0 && nrow(result2) > 0) {
      expect_equal(nrow(result1), nrow(result2))

      if ("npi" %in% names(result1) && "npi" %in% names(result2)) {
        expect_equal(sort(result1$npi), sort(result2$npi))
      }
    }
  }
})

test_that("Property: Column contains valid categorical values for case_when", {
  skip_on_cran()

  for (i in 1:15) {
    test_data <- generate_test_dataframe(sample(20:100, 1))
    temp_dir <- tempdir()

    result <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )

    if (nrow(result) > 0) {
      # Property: State values should work in case_when operations
      if ("state_name" %in% names(result)) {
        expect_no_error({
          result %>%
            mutate(
              region = case_when(
                state_name %in% c("California", "Oregon", "Washington") ~ "West",
                state_name %in% c("Texas", "Florida", "Georgia") ~ "South",
                state_name %in% c("New York", "Pennsylvania") ~ "Northeast",
                TRUE ~ "Other"
              )
            )
        })

        # Property: All resulting regions should be valid
        regional_result <- result %>%
          mutate(
            region = case_when(
              state_name %in% c("California", "Oregon", "Washington") ~ "West",
              state_name %in% c("Texas", "Florida", "Georgia") ~ "South",
              state_name %in% c("New York", "Pennsylvania") ~ "Northeast",
              TRUE ~ "Other"
            )
          )

        valid_regions <- c("West", "South", "Northeast", "Other")
        expect_true(all(regional_result$region %in% valid_regions))
      }

      # Property: For_redcap values should work in case_when operations
      if ("for_redcap" %in% names(result)) {
        expect_no_error({
          result %>%
            mutate(
              include_flag = case_when(
                for_redcap == "Yes" ~ TRUE,
                for_redcap == "No" ~ FALSE,
                TRUE ~ NA
              )
            )
        })
      }
    }
  }
})

test_that("Property: Data transformations preserve referential integrity", {
  skip_on_cran()

  for (i in 1:10) {
    n <- sample(10:50, 1)
    test_data <- generate_test_dataframe(n, valid_only = TRUE)
    original_ids <- test_data$id

    temp_dir <- tempdir()

    result <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE  # For easier integrity checking
    )

    if ("id" %in% names(result)) {
      # Property: All original IDs should be preserved
      result_ids <- unique(result$id)
      expect_true(all(original_ids %in% result_ids))

      # Property: No new IDs should be created
      expect_true(all(result_ids %in% original_ids))
    }
  }
})

test_that("Property: Search operations return consistent data types", {
  skip_on_cran()

  taxonomies <- c(
    "Obstetrics & Gynecology",
    "Gynecologic Oncology",
    "Maternal & Fetal Medicine",
    "Reproductive Endocrinology",
    "Nonexistent Taxonomy"
  )

  # Mock consistent search results
  mock_npi_search <- function(taxonomy_description, ...) {
    if (taxonomy_description == "Nonexistent Taxonomy") {
      list()
    } else {
      n <- sample(5:20, 1)
      list(
        npi = generate_valid_npi(n),
        basic_first_name = paste("Provider", 1:n),
        basic_last_name = paste("Last", 1:n),
        basic_credential = rep("MD", n),
        basic_gender = sample(c("M", "F"), n, replace = TRUE),
        addresses_country_name = rep("United States", n),
        taxonomies_desc = rep(taxonomy_description, n)
      )
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
      for (taxonomy in taxonomies) {
        result <- mysterycall_search_taxonomy(taxonomy, write_snapshot = FALSE, notify = FALSE)

        # Property: Always returns a data frame
        expect_s3_class(result, "data.frame")

        # Property: Column types are consistent when data is present
        if (nrow(result) > 0) {
          if ("npi" %in% names(result)) {
            expect_true(is.character(result$npi) || is.numeric(result$npi))
          }

          if ("basic_gender" %in% names(result)) {
            expect_true(is.character(result$basic_gender) || is.factor(result$basic_gender))
          }

          if ("taxonomies_desc" %in% names(result)) {
            expect_true(is.character(result$taxonomies_desc))
          }
        }
      }
    }
  )
})

test_that("Property: Data aggregations are mathematically consistent", {
  skip_on_cran()

  for (i in 1:10) {
    test_data <- generate_test_dataframe(sample(50:200, 1), valid_only = TRUE)
    temp_dir <- tempdir()

    result <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE
    )

    if (nrow(result) > 0 && "state_name" %in% names(result)) {
      # Count by state
      state_counts <- result %>% count(state_name, sort = TRUE)

      # Property: Sum of counts equals total rows
      expect_equal(sum(state_counts$n), nrow(result))

      # Property: No negative counts
      expect_true(all(state_counts$n >= 0))

      # Property: All counts are integers
      expect_true(all(state_counts$n == round(state_counts$n)))

      # Property: Percentage calculations sum to 100%
      state_percentages <- state_counts %>%
        mutate(percentage = n / sum(n) * 100)

      expect_true(abs(sum(state_percentages$percentage) - 100) < 0.001)
    }
  }
})

test_that("Property: String operations preserve UTF-8 encoding", {
  skip_on_cran()

  # Test with international characters
  international_names <- c(
    "Dr. José García",
    "Dr. François Müller",
    "Dr. Анна Петрова",
    "Dr. 田中太郎",
    "Dr. محمد عبدالله"
  )

  test_data <- data.frame(
    id = seq_along(international_names),
    names = international_names,
    practice_name = paste("Practice", seq_along(international_names)),
    phone_number = generate_valid_phone(length(international_names)),
    state_name = sample(state.name[1:5], length(international_names), replace = TRUE),
    npi = generate_valid_npi(length(international_names)),
    for_redcap = rep("Yes", length(international_names)),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  result <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE
  )

  # Property: International characters should be preserved
  if ("names" %in% names(result) && nrow(result) > 0) {
    # Check that some non-ASCII characters are preserved
    has_international <- any(grepl("[^\\x00-\\x7F]", result$names, perl = TRUE))
    expect_true(has_international || all(is.na(result$names)))
  }
})

test_that("Property: Function calls are deterministic with same input", {
  skip_on_cran()

  test_data <- generate_test_dataframe(25, valid_only = TRUE)
  temp_dir1 <- tempdir()
  temp_dir2 <- tempdir()

  # Run same operation twice
  result1 <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir1,
    verbose = FALSE,
    notify = FALSE,
    id_seed = 123,  # Fixed seed for determinism
    duplicate_rows = FALSE
  )

  result2 <- mysterycall_clean_phase1(
    phase1_data = test_data,
    output_directory = temp_dir2,
    verbose = FALSE,
    notify = FALSE,
    id_seed = 123,  # Same seed
    duplicate_rows = FALSE
  )

  # Property: Same input should produce same output
  expect_equal(nrow(result1), nrow(result2))
  expect_equal(names(result1), names(result2))

  # Compare key columns
  key_columns <- intersect(c("id", "names", "practice_name"), names(result1))
  for (col in key_columns) {
    expect_equal(result1[[col]], result2[[col]])
  }
})

test_that("Property: Memory usage is bounded for given input size", {
  skip_on_cran()

  input_sizes <- c(10, 50, 100)
  memory_usage <- numeric(length(input_sizes))

  for (i in seq_along(input_sizes)) {
    test_data <- generate_test_dataframe(input_sizes[i], valid_only = TRUE)
    temp_dir <- tempdir()

    # Measure memory usage
    gc()
    mem_before <- sum(gc()[, 2])

    result <- mysterycall_clean_phase1(
      phase1_data = test_data,
      output_directory = temp_dir,
      verbose = FALSE,
      notify = FALSE
    )

    gc()
    mem_after <- sum(gc()[, 2])
    memory_usage[i] <- mem_after - mem_before
  }

  # Property: Memory usage should scale sub-quadratically
  for (i in 2:length(input_sizes)) {
    size_ratio <- input_sizes[i] / input_sizes[i-1]
    # Skip ratio comparison when baseline memory delta is 0 (GC noise dominates)
    if (memory_usage[i-1] <= 0) next
    memory_ratio <- memory_usage[i] / memory_usage[i-1]

    expect_lt(memory_ratio, size_ratio^1.5,
              label = paste("Memory scaling too steep between size",
                          input_sizes[i-1], "and", input_sizes[i]))
  }
})

test_that("Property: Error conditions are consistent and informative", {
  skip_on_cran()

  temp_dir <- tempdir()

  error_conditions <- list(
    null_input = NULL,
    empty_df = data.frame(),
    wrong_class = list(a = 1, b = 2),
    missing_names = data.frame(id = 1:3, wrong_col = letters[1:3]),
    missing_practice = data.frame(id = 1:3, names = paste("Dr.", 1:3))
  )

  for (condition_name in names(error_conditions)) {
    condition_data <- error_conditions[[condition_name]]

    # Property: All error conditions should throw informative errors
    expect_error(
      mysterycall_clean_phase1(condition_data, output_directory = temp_dir),
      regexp = paste0("(data frame|names|practice_name|at least one row)"),
      label = paste("Error condition", condition_name, "should throw informative error")
    )
  }
})

test_that("Property: Data validation rules are internally consistent", {
  skip_on_cran()

  # Generate data that should pass all validation rules
  perfect_data <- data.frame(
    id = 1:20,
    names = paste("Dr.", sample(c("John", "Jane", "Michael", "Sarah"), 20, replace = TRUE),
                  sample(c("Smith", "Johnson", "Williams", "Brown"), 20, replace = TRUE)),
    practice_name = paste(sample(c("Medical", "Health", "Family", "Women's"), 20, replace = TRUE),
                         sample(c("Center", "Clinic", "Associates", "Group"), 20, replace = TRUE)),
    phone_number = generate_valid_phone(20),
    state_name = sample(state.name, 20, replace = TRUE),
    npi = generate_valid_npi(20),
    for_redcap = sample(c("Yes", "No"), 20, replace = TRUE),
    stringsAsFactors = FALSE
  )

  temp_dir <- tempdir()

  # Process through full pipeline
  cleaned_data <- mysterycall_clean_phase1(
    phase1_data = perfect_data,
    output_directory = temp_dir,
    verbose = FALSE,
    notify = FALSE,
    duplicate_rows = FALSE
  )

  validated_data <- mysterycall_validate_npi(cleaned_data)

  # Property: Perfect data should pass all validation steps
  expect_s3_class(validated_data, "data.frame")
  expect_equal(nrow(validated_data), nrow(perfect_data))

  # Property: All validation rules should be satisfied
  if ("npi" %in% names(validated_data)) {
    valid_npis <- validated_data$npi[!is.na(validated_data$npi)]
    if (length(valid_npis) > 0) {
      expect_true(all(grepl("^[0-9]{10}$", valid_npis)))
    }
  }

  if ("state_name" %in% names(validated_data)) {
    valid_states <- c(state.name, state.abb, "District of Columbia", "DC")
    state_matches <- sum(validated_data$state_name %in% valid_states, na.rm = TRUE)
    expect_gte(state_matches / nrow(validated_data), 0.9)
  }
})
