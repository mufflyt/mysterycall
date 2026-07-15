library(testthat)

skip_if_not_installed("openxlsx")
skip_if_not_installed("dplyr")
skip_if_not_installed("janitor")
skip_if_not_installed("readr")
skip_if_not_installed("stringr")
skip_if_not_installed("humaniformat")
skip_if_not_installed("beepr")
skip_if_not_installed("fs")

# nolint start
# The following test exercises the full workflow with real helpers and intentionally
# writes artefacts inside a temporary working directory to verify integration.
# nolint end

test_that("mysterycall_run_workflow orchestrates pipeline without mocks", {
  work_dir <- tempfile("mysterycall-e2e-")
  dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(work_dir, recursive = TRUE), add = TRUE)

  phase1_out <- file.path(work_dir, "phase1")
  splits_dir <- file.path(work_dir, "splits")
  qc_path <- file.path(work_dir, "qc", "quality.csv")

  phase1_data <- data.frame(
    names = c("Jane Doe", "John Smith"),
    practice_name = c("Front Range OBGYN", "Rocky Mountain Health"),
    phone_number = c("303-555-0100", "720-555-0199"),
    state_name = c("Colorado", "Colorado"),
    npi = c("1111111116", "2222222224"),
    stringsAsFactors = FALSE
  )

  phase2_data <- data.frame(
    physician_information = c("Jane Doe", "Jane Doe", "Jane Doe", "John Smith"),
    able_to_contact_office = c("Yes", "Yes", "Yes", "No"),
    are_we_including = c("Yes", "Yes", "Yes", "No"),
    reason_for_exclusions = c(NA_character_, NA_character_, NA_character_, "Closed"),
    appointment_date = as.Date(c("2024-01-01", "2024-01-02", "2024-01-03", "2024-01-04")),
    number_of_transfers = c(0, 1, 0, 1),
    call_time = c(120, 110, 115, 95),
    hold_time = c(30, 35, 25, 40),
    notes = c("Scheduled", "Confirmed", "Reminder", "Try again"),
    person_completing = c("Caller A", "Caller A", "Caller C", "Caller B"),
    state = c("Colorado", "Colorado", "Colorado", "Colorado"),
    npi = c("1111111116", "1111111116", "1111111116", "2222222224"),
    name = c("Jane Doe", "Jane Doe", "Jane Doe", "John Smith"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_run_workflow(
    taxonomy_terms = NULL,
    name_data = data.frame(first = character(), last = character(), stringsAsFactors = FALSE),
    phase1_data = phase1_data,
    lab_assistant_names = c("Alpha", "Bravo"),
    output_directory = splits_dir,
    phase2_data = phase2_data,
    quality_check_path = qc_path,
    phase1_output_directory = phase1_out,
    phase2_output_directory = work_dir,
    all_states = c("Colorado", "Wyoming")
  )

  expect_true(is.list(result))
  expect_equal(sort(names(result)), sort(c(
    "cleaned_phase1", "cleaned_phase2", "coverage_summary",
    "quality_check_table", "roster", "validated_roster", "workflow_summary"
  )))

  expect_s3_class(result$roster, "data.frame")
  expect_equal(nrow(result$roster), 0L)
  expect_s3_class(result$validated_roster, "data.frame")
  expect_equal(nrow(result$validated_roster), 0L)

  expect_true(dir.exists(phase1_out))
  expect_s3_class(result$cleaned_phase1, "data.frame")
  expect_true(all(c("for_redcap", "doctor_id", "insurance") %in% names(result$cleaned_phase1)))
  expect_equal(nrow(result$cleaned_phase1), 4L)

  expect_true(dir.exists(splits_dir))
  split_files <- list.files(splits_dir, pattern = "\\.xlsx$", full.names = TRUE)
  expect_true(any(grepl("complete_non_split_version_", basename(split_files))))
  expect_true(length(split_files) >= 1L)

  expect_s3_class(result$cleaned_phase2, "data.frame")
  expected_phase2_columns <- c(
    "physician_info", "contact_office", "included_in_study", "exclusion_reasons",
    "appt_date", "transfer_count", "call_duration", "hold_duration",
    "notes", "completed_by", "state", "npi", "name"
  )
  expect_true(all(expected_phase2_columns %in% names(result$cleaned_phase2)))

  coverage_message <- "A total of 1 unique physicians were identified in the dataset and were successfully contacted (i.e., with a recorded wait time for an appointment) in 1 states. The excluded states include Wyoming."
  expect_identical(result$coverage_summary, coverage_message)

  expect_true(file.exists(qc_path))
  expect_s3_class(result$quality_check_table, "data.frame")
  expect_equal(nrow(result$quality_check_table), 1L)
  expect_equal(result$quality_check_table$count[[1]], 3)
  expect_equal(result$quality_check_table$npi[[1]], "1111111116")

  phase2_exports <- list.files(work_dir, pattern = "cleaned_phase_2_data_.*\\.csv$", full.names = TRUE)
  expect_true(length(phase2_exports) >= 1L)
})
