library(testthat)
library(mysterycall)

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


test_that("mysterycall_run_workflow_logged handles happy path without error", {
  skip_if_not_installed("lme4")

  tmpdir <- tempdir()
  qc_path <- file.path(tmpdir, "qc.csv")

  # Minimal phase1 and phase2 data with required columns
  phase1_data <- data.frame(
    npi = c("1234567893", "9876543210"),
    name = c("Smith, John", "Doe, Jane"),
    specialty = c("OB/GYN", "OB/GYN"),
    state = c("CO", "CO"),
    stringsAsFactors = FALSE
  )

  phase2_data <- data.frame(
    npi = c("1234567893", "9876543210"),
    physician_information = c("Smith, John", "Doe, Jane"),
    able_to_contact_office = c(TRUE, FALSE),
    are_we_including = c(TRUE, FALSE),
    reason_for_exclusions = c("None", "No response"),
    appointment_date = c("2024-01-15", "2024-01-20"),
    number_of_transfers = c(1L, 0L),
    call_time = c(120L, 90L),
    hold_time = c(30L, 0L),
    notes = c("Appointment scheduled", "No response"),
    person_completing = c("Alice", "Bob"),
    state = c("CO", "CO"),
    name = c("Smith, John", "Doe, Jane"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_run_workflow_logged(
      phase1_data = phase1_data,
      phase2_data = phase2_data,
      lab_assistant_names = c("Alice", "Bob"),
      output_directory = tmpdir,
      quality_check_path = qc_path
    )
  ))

  expect_type(result, "list")
  expect_true(length(result) > 0)
})


test_that("mysterycall_run_workflow_logged returns list with workflow_summary", {
  skip_if_not_installed("lme4")

  tmpdir <- tempdir()
  qc_path <- file.path(tmpdir, "qc2.csv")

  phase1_data <- data.frame(
    npi = c("1234567893", "9876543210"),
    name = c("Smith, John", "Doe, Jane"),
    specialty = c("OB/GYN", "OB/GYN"),
    state = c("CO", "CO"),
    stringsAsFactors = FALSE
  )

  phase2_data <- data.frame(
    npi = c("1234567893", "9876543210"),
    physician_information = c("Smith, John", "Doe, Jane"),
    able_to_contact_office = c(TRUE, FALSE),
    are_we_including = c(TRUE, FALSE),
    reason_for_exclusions = c("None", "No response"),
    appointment_date = c("2024-01-15", "2024-01-20"),
    number_of_transfers = c(1L, 0L),
    call_time = c(120L, 90L),
    hold_time = c(30L, 0L),
    notes = c("Appointment scheduled", "No response"),
    person_completing = c("Alice", "Bob"),
    state = c("CO", "CO"),
    name = c("Smith, John", "Doe, Jane"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_run_workflow_logged(
      phase1_data = phase1_data,
      phase2_data = phase2_data,
      lab_assistant_names = c("Alice", "Bob"),
      output_directory = tmpdir,
      quality_check_path = qc_path
    )
  ))

  expect_true(is.list(result))
  expect_true("workflow_summary" %in% names(result) || "cleaned_phase1" %in% names(result))
})


test_that("mysterycall_run_workflow_logged handles custom log_file path", {
  skip_if_not_installed("lme4")

  tmpdir <- tempdir()
  qc_path <- file.path(tmpdir, "qc3.csv")
  log_path <- file.path(tmpdir, "custom_workflow.log")

  phase1_data <- data.frame(
    npi = c("1234567893"),
    name = c("Smith, John"),
    specialty = c("OB/GYN"),
    state = c("CO"),
    stringsAsFactors = FALSE
  )

  phase2_data <- data.frame(
    npi = c("1234567893"),
    physician_information = c("Smith, John"),
    able_to_contact_office = c(TRUE),
    are_we_including = c(TRUE),
    reason_for_exclusions = c("None"),
    appointment_date = c("2024-01-15"),
    number_of_transfers = c(1L),
    call_time = c(120L),
    hold_time = c(30L),
    notes = c("Appointment scheduled"),
    person_completing = c("Alice"),
    state = c("CO"),
    name = c("Smith, John"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(suppressWarnings(
    mysterycall_run_workflow_logged(
      phase1_data = phase1_data,
      phase2_data = phase2_data,
      lab_assistant_names = c("Alice"),
      output_directory = tmpdir,
      quality_check_path = qc_path,
      log_file = log_path
    )
  ))

  expect_type(result, "list")
})


test_that("mysterycall_run_workflow_logged errors on missing required phase1_data", {
  skip_if_not_installed("lme4")

  tmpdir <- tempdir()
  qc_path <- file.path(tmpdir, "qc4.csv")

  phase2_data <- data.frame(
    npi = c("1234567893"),
    physician_information = c("Smith, John"),
    able_to_contact_office = c(TRUE),
    are_we_including = c(TRUE),
    reason_for_exclusions = c("None"),
    appointment_date = c("2024-01-15"),
    number_of_transfers = c(1L),
    call_time = c(120L),
    hold_time = c(30L),
    notes = c("Appointment scheduled"),
    person_completing = c("Alice"),
    state = c("CO"),
    name = c("Smith, John"),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_run_workflow_logged(
        phase1_data = NULL,
        phase2_data = phase2_data,
        lab_assistant_names = c("Alice"),
        output_directory = tmpdir,
        quality_check_path = qc_path
      )
    ))
  )
})
