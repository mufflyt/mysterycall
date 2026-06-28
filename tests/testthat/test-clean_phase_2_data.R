library(testthat)

# The clean_phase_2_data helpers rely on packages declared in Imports.
# These are loaded lazily inside the functions, so we just ensure they
# are available for the tests.
testthat::skip_if_not_installed("janitor")
testthat::skip_if_not_installed("readr")


test_that("rename_columns_by_substring prioritises first match", {
  raw <- data.frame(
    doctor_info = 1:2,
    doctor_notes = 3:4,
    contact_number = 5:6,
    stringsAsFactors = FALSE
  )

  expect_warning(
    renamed <- withCallingHandlers(
      rename_columns_by_substring(
        raw,
        target_strings = c("doctor", "contact"),
        new_names = c("physician", "contact_info")
      ),
      warning = function(w) {
        if (grepl("deprecated", conditionMessage(w), ignore.case = TRUE)) {
          invokeRestart("muffleWarning")
        }
      }
    ),
    "Multiple columns match"
  )

  expect_equal(names(renamed), c("physician", "doctor_notes", "contact_info"))
  expect_identical(renamed$physician, raw$doctor_info)
  expect_identical(renamed$contact_info, raw$contact_number)
})


test_that("clean_phase_2_data standardises Phase 2 exports", {
  tmp_dir <- tempfile("phase2-regression-")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  raw <- data.frame(
    PhysicianInformation = c("Jane Doe", "John Smith"),
    AbleToContactOffice = c("Yes", "No"),
    AreWeIncluding = c("Yes", "No"),
    ReasonForExclusions = c(NA, "Closed"),
    AppointmentDate = c("2024-01-01", "2024-01-02"),
    NumberOfTransfers = c(0, 1),
    CallTime = c(120, 95),
    HoldTime = c(30, 40),
    Notes = c("Scheduled", "Try again"),
    PersonCompleting = c("Caller A", "Caller B"),
    stringsAsFactors = FALSE
  )

  required_strings <- c(
    "physician_information",
    "able_to_contact_office",
    "are_we_including",
    "reason_for_exclusions",
    "appointment_date",
    "number_of_transfers",
    "call_time",
    "hold_time",
    "notes",
    "person_completing"
  )

  standard_names <- c(
    "physician_info",
    "contact_office",
    "included_in_study",
    "exclusion_reasons",
    "appt_date",
    "transfer_count",
    "call_duration",
    "hold_duration",
    "caller_notes",
    "completed_by"
  )

  expected <- data.frame(
    physician_info = raw$PhysicianInformation,
    contact_office = raw$AbleToContactOffice,
    included_in_study = raw$AreWeIncluding,
    exclusion_reasons = raw$ReasonForExclusions,
    appt_date = raw$AppointmentDate,
    transfer_count = raw$NumberOfTransfers,
    call_duration = raw$CallTime,
    hold_duration = raw$HoldTime,
    caller_notes = raw$Notes,
    completed_by = raw$PersonCompleting,
    stringsAsFactors = FALSE
  )

  cleaned <- suppressWarnings(clean_phase_2_data(
    raw,
    required_strings,
    standard_names,
    output_directory = tmp_dir
  ))

  expect_equal(as.data.frame(cleaned), expected, ignore_attr = TRUE)

  output_files <- list.files(tmp_dir, pattern = "^cleaned_phase_2_data_.*\\.csv$")
  expect_length(output_files, 1L)

  persisted <- readr::read_csv(
    file.path(tmp_dir, output_files[[1]]),
    col_types = readr::cols(appt_date = readr::col_character()),
    show_col_types = FALSE
  )
  expect_equal(as.data.frame(persisted), expected, ignore_attr = TRUE)
})


test_that("clean_phase_2_data reads from file paths", {
  tmp_dir <- tempfile("phase2-regression-file-")
  dir.create(tmp_dir)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  raw <- data.frame(
    PhysicianInformation = c("Alex Roe"),
    AbleToContactOffice = c("Yes"),
    AreWeIncluding = c("Yes"),
    ReasonForExclusions = c(NA),
    AppointmentDate = c("2024-02-14"),
    NumberOfTransfers = c(0),
    CallTime = c(105),
    HoldTime = c(12),
    Notes = c("Follow up"),
    PersonCompleting = c("Caller C"),
    stringsAsFactors = FALSE
  )

  required_strings <- c(
    "physician_information",
    "able_to_contact_office",
    "are_we_including",
    "reason_for_exclusions",
    "appointment_date",
    "number_of_transfers",
    "call_time",
    "hold_time",
    "notes",
    "person_completing"
  )

  standard_names <- c(
    "physician_info",
    "contact_office",
    "included_in_study",
    "exclusion_reasons",
    "appt_date",
    "transfer_count",
    "call_duration",
    "hold_duration",
    "caller_notes",
    "completed_by"
  )

  input_path <- file.path(tmp_dir, "phase2.csv")
  readr::write_csv(raw, input_path)

  cleaned <- suppressWarnings(clean_phase_2_data(
    input_path,
    required_strings,
    standard_names,
    output_directory = tmp_dir
  ))

  expect_s3_class(cleaned, "data.frame")
  expect_equal(names(cleaned), standard_names)
  expect_identical(cleaned$physician_info, raw$PhysicianInformation)

  output_files <- list.files(tmp_dir, pattern = "^cleaned_phase_2_data_.*\\.csv$")
  expect_true(any(output_files != "phase2.csv"))
})
