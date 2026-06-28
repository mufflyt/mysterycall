library(testthat)

AUDIT <- data.frame(
  npi                              = c("1234567893","1234567893","9876543210","9876543210"),
  insurance                        = c("Medicaid","BCBS","Medicaid","BCBS"),
  offered                          = c(TRUE, TRUE, FALSE, TRUE),
  contact_office                   = c(TRUE, TRUE, FALSE, TRUE),
  wait_days                        = c(5L, 12L, 3L, 7L),
  business_days_until_appointment  = c(5L, 12L, 3L, 7L),
  caller_id                        = c("A","A","B","B"),
  wave                             = c(1L, 1L, 2L, 2L),
  specialty                        = c("OB/GYN","OB/GYN","OB/GYN","OB/GYN"),
  phone                            = c("3035550100","3035550100","7205550200","7205550200"),
  physician_information            = c("Smith, John","Smith, John","Doe, Jane","Doe, Jane"),
  reason_for_exclusions            = rep("Able to contact", 4L),
  stringsAsFactors = FALSE
)

set.seed(1)
COUNT_DF <- data.frame(
  days      = c(rpois(40, 5), rpois(40, 10)),
  insurance = rep(c("Medicaid","BCBS"), each = 40L),
  stringsAsFactors = FALSE
)

test_that("mysterycall_clean_phase1 happy path with valid minimal data", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith", "Jane Doe"),
    practice_name = c("Smith Clinic", "Doe Hospital"),
    phone_number = c("3035550100", "7205550200"),
    state_name = c("Colorado", "Wyoming"),
    npi = c("1234567893", "9876543210"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 42
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_true(!is.null(attr(result, "audit_trail")))
  expect_true(!is.null(attr(result, "processing_timestamp")))
  expect_equal(attr(result, "function_version"), "2.0")
  expect_true("processing_flag_empty_name" %in% names(result))
  expect_true("processing_flag_generated_id" %in% names(result))
  expect_true("processing_flag_is_duplicate" %in% names(result))
})

test_that("mysterycall_clean_phase1 handles empty and whitespace-only names", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith", "   ", NA_character_),
    practice_name = c("Clinic A", "Clinic B", "Clinic C"),
    phone_number = c("3035550100", "7205550200", "5555550300"),
    state_name = c("CO", "WY", "UT"),
    npi = c("1111111111", "2222222222", "3333333333"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 42
    )
  ))

  expect_equal(sum(result$processing_flag_empty_name), 2L)
  expect_true(is.na(result$names[2]))
  expect_true(is.na(result$names[3]))
})

test_that("mysterycall_clean_phase1 generates IDs when NPI column missing", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith", "Jane Doe"),
    practice_name = c("Clinic A", "Clinic B"),
    phone_number = c("3035550100", "7205550200"),
    state_name = c("CO", "WY"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 42
    )
  ))

  expect_true("random_id" %in% names(result))
  expect_equal(sum(result$processing_flag_generated_id), 2L)
  expect_true(all(grepl("^id_", result$random_id)))
})

test_that("mysterycall_clean_phase1 errors on missing required columns", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith", "Jane Doe"),
    practice_name = c("Clinic A", "Clinic B"),
    npi = c("1234567893", "9876543210"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_clean_phase1(
        input_data,
        output_directory = tempdir(),
        verbose = FALSE,
        notify = FALSE
      )
    ))
  )
})

test_that("mysterycall_clean_phase1 respects duplicate_rows parameter", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith", "Jane Doe"),
    practice_name = c("Clinic A", "Clinic B"),
    phone_number = c("3035550100", "7205550200"),
    state_name = c("CO", "WY"),
    npi = c("1234567893", "9876543210"),
    stringsAsFactors = FALSE
  )

  result_with_dup <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = TRUE,
      id_seed = 42
    )
  ))

  result_no_dup <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 42
    )
  ))

  expect_equal(nrow(result_with_dup), nrow(input_data) * 2)
  expect_equal(nrow(result_no_dup), nrow(input_data))
  expect_equal(sum(result_with_dup$insurance == "Blue Cross/Blue Shield"), 2L)
  expect_equal(sum(result_with_dup$insurance == "Medicaid"), 2L)
})

test_that("mysterycall_clean_phase1 id_seed ensures reproducibility", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith", "Jane Doe"),
    practice_name = c("Clinic A", "Clinic B"),
    phone_number = c("3035550100", "7205550200"),
    state_name = c("CO", "WY"),
    npi = c(NA_character_, NA_character_),
    stringsAsFactors = FALSE
  )

  result1 <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 99
    )
  ))

  result2 <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 99
    )
  ))

  expect_equal(result1$random_id, result2$random_id)
})

test_that("mysterycall_clean_phase1 errors on non-dataframe input", {
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_clean_phase1(
        list(names = "John", practice_name = "Clinic"),
        output_directory = tempdir(),
        verbose = FALSE,
        notify = FALSE
      )
    ))
  )
})

test_that("mysterycall_clean_phase1 preserves original NPI when present", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith"),
    practice_name = c("Clinic A"),
    phone_number = c("3035550100"),
    state_name = c("CO"),
    npi = c("1234567893"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 42
    )
  ))

  expect_true("original_npi" %in% names(result))
  expect_equal(result$original_npi[1], "1234567893")
})

test_that("mysterycall_clean_phase1 audit trail contains expected fields", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith"),
    practice_name = c("Clinic A"),
    phone_number = c("3035550100"),
    state_name = c("CO"),
    npi = c("1234567893"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 42
    )
  ))

  audit <- attr(result, "audit_trail")
  expect_true(is.list(audit))
  expect_true("function_name" %in% names(audit))
  expect_true("input_rows" %in% names(audit))
  expect_true("output_rows" %in% names(audit))
  expect_true("start_time" %in% names(audit))
  expect_equal(audit$function_name, "mysterycall_clean_phase1")
  expect_true(audit$input_rows > 0)
})

test_that("mysterycall_clean_phase1 extracts last names successfully", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith", "Jane Doe"),
    practice_name = c("Clinic A", "Clinic B"),
    phone_number = c("3035550100", "7205550200"),
    state_name = c("CO", "WY"),
    npi = c("1234567893", "9876543210"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 42
    )
  ))

  expect_true("last_name" %in% names(result))
  expect_true("dr_name" %in% names(result))
  # Function sorts by names, so Jane Doe comes before John Smith
  expect_true(all(grepl("^Dr\\.", result$dr_name[!is.na(result$dr_name)])))
  expect_equal(length(unique(result$dr_name)), 2L)
})

test_that("mysterycall_clean_phase1 identifies academic vs private practice", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith", "Jane Doe", "Bob Jones"),
    practice_name = c("University Medical Center", "Private Clinic", "College Hospital"),
    phone_number = c("3035550100", "7205550200", "5555550300"),
    state_name = c("CO", "WY", "UT"),
    npi = c("1111111111", "2222222222", "3333333333"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 42
    )
  ))

  expect_true("academic" %in% names(result))
  expect_true(all(result$academic %in% c("University", "Private Practice")))
  # Only "University Medical Center" matches the pattern; "College Hospital" does not
  expect_equal(sum(result$academic == "University"), 1L)
  expect_equal(sum(result$academic == "Private Practice"), 2L)
})

test_that("mysterycall_clean_phase1 handles missing id column correctly", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith"),
    practice_name = c("Clinic A"),
    phone_number = c("3035550100"),
    state_name = c("CO"),
    npi = c("1234567893"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 42
    )
  ))

  expect_false("original_id" %in% names(result))
  expect_true("id" %in% names(result))
  expect_equal(result$id[1], 1L)
})

test_that("mysterycall_clean_phase1 handles data with no NPI column", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("janitor")
  skip_if_not_installed("readr")
  skip_if_not_installed("stringr")
  skip_if_not_installed("humaniformat")

  input_data <- data.frame(
    names = c("John Smith", "Jane Doe"),
    practice_name = c("Clinic A", "Clinic B"),
    phone_number = c("3035550100", "7205550200"),
    state_name = c("CO", "WY"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      input_data,
      output_directory = tempdir(),
      verbose = FALSE,
      notify = FALSE,
      duplicate_rows = FALSE,
      id_seed = 42
    )
  ))

  expect_true("random_id" %in% names(result))
  expect_equal(sum(result$processing_flag_generated_id), 2L)
  expect_true(all(grepl("^id_", result$random_id)))
})
