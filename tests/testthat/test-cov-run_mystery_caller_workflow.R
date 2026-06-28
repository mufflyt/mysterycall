library(testthat)
library(mysterycall)

# ---------------------------------------------------------------------------
# Shared fixtures
# ---------------------------------------------------------------------------

# Minimal Phase 1 data frame satisfying mysterycall_clean_phase1() requirements
PHASE1 <- data.frame(
  names          = c("Smith, John MD", "Doe, Jane DO"),
  practice_name  = c("General Clinic", "University Hospital"),
  phone_number   = c("3035550100", "7205550200"),
  state_name     = c("Colorado", "Colorado"),
  npi            = c("1234567893", "9876543210"),
  stringsAsFactors = FALSE
)

# Minimal Phase 2 data frame — column names match the default required_strings
PHASE2 <- data.frame(
  physician_information  = c("Smith, John", "Doe, Jane"),
  able_to_contact_office = c("Yes", "No"),
  are_we_including       = c("Yes", "No"),
  reason_for_exclusions  = c("Able to contact", "Excluded"),
  appointment_date       = c("2024-03-01", NA_character_),
  number_of_transfers    = c(0L, 1L),
  call_time              = c("00:05:00", "00:03:00"),
  hold_time              = c("00:01:00", "00:00:30"),
  notes                  = c("", "busy signal"),
  person_completing      = c("Caller A", "Caller B"),
  state                  = c("CO", "CO"),
  npi                    = c("1234567893", "9876543210"),
  name                   = c("Smith", "Doe"),
  stringsAsFactors       = FALSE
)

# Mock return value for mysterycall_clean_phase1(): must include the columns
# expected by mysterycall_split_and_save()
CLEAN1 <- data.frame(
  for_redcap    = c("1, Dr. Smith, Blue Cross/Blue Shield, (303) 555-0100, Colorado, id_abc, Private Practice, id:1",
                    "2, Dr. Doe, Medicaid, (720) 555-0200, Colorado, id_def, University, id:2"),
  id            = 1:2,
  doctor_id     = c("1234567893", "9876543210"),
  insurance     = c("Blue Cross/Blue Shield", "Medicaid"),
  names         = c("Smith, John MD", "Doe, Jane DO"),
  practice_name = c("General Clinic", "University Hospital"),
  phone_number  = c("(303) 555-0100", "(720) 555-0200"),
  state_name    = c("Colorado", "Colorado"),
  npi           = c("1234567893", "9876543210"),
  stringsAsFactors = FALSE
)

# Mock return value for mysterycall_clean_phase2()
CLEAN2 <- data.frame(
  physician_info   = c("Smith, John", "Doe, Jane"),
  contact_office   = c("Yes", "No"),
  npi              = c("1234567893", "9876543210"),
  name             = c("Smith", "Doe"),
  state            = c("CO", "CO"),
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# Helper: build a minimal set of mocked bindings so the workflow completes
# without hitting file I/O, external APIs, or openxlsx.
# ---------------------------------------------------------------------------
run_workflow_mocked <- function(extra_args = list()) {
  with_mocked_bindings(
    mysterycall_clean_phase1 = function(...) CLEAN1,
    mysterycall_split_and_save = function(...) invisible(NULL),
    mysterycall_clean_phase2 = function(...) CLEAN2,
    mysterycall_not_contacted_states = function(...) data.frame(state = "CO", n = 2L),
    mysterycall_save_quality_table = function(...) CLEAN2,
    mysterycall_validate_npi = function(x, ...) x,
    .package = "mysterycall",
    {
      base_args <- list(
        taxonomy_terms     = NULL,
        name_data          = NULL,
        phase1_data        = PHASE1,
        lab_assistant_names = c("Alice", "Bob"),
        output_directory   = tempdir(),
        phase2_data        = PHASE2,
        quality_check_path = file.path(tempdir(), "qc_test.csv"),
        verbose            = FALSE
      )
      do.call(mysterycall_run_workflow, utils::modifyList(base_args, extra_args))
    }
  )
}

# ---------------------------------------------------------------------------
# Test 1 — happy path: mocked sub-functions, result is a named list
# ---------------------------------------------------------------------------
test_that("mysterycall_run_workflow returns a named list on valid inputs", {
  skip_if_not_installed("digest")

  result <- suppressMessages(suppressWarnings(run_workflow_mocked()))

  expect_type(result, "list")
  expected_names <- c(
    "roster", "validated_roster", "cleaned_phase1", "cleaned_phase2",
    "coverage_summary", "quality_check_table", "workflow_summary"
  )
  expect_true(all(expected_names %in% names(result)))
})

# ---------------------------------------------------------------------------
# Test 2 — workflow_summary always present and correctly shaped
# ---------------------------------------------------------------------------
test_that("workflow_summary is a data frame with required columns", {
  skip_if_not_installed("digest")

  result <- suppressMessages(suppressWarnings(run_workflow_mocked()))

  ws <- result$workflow_summary
  expect_s3_class(ws, "data.frame")
  expect_true(all(c("stage", "n_rows", "retention_from_previous", "output_path") %in% names(ws)))
  expect_equal(
    ws$stage,
    c("combined_roster", "validated_roster", "cleaned_phase1",
      "cleaned_phase2", "coverage_summary", "quality_check_table")
  )
})

# ---------------------------------------------------------------------------
# Test 3 — bad input: name_data that is not a data frame raises an error
# ---------------------------------------------------------------------------
test_that("mysterycall_run_workflow errors when name_data is not a data frame", {
  skip_if_not_installed("digest")

  with_mocked_bindings(
    mysterycall_clean_phase1       = function(...) CLEAN1,
    mysterycall_split_and_save     = function(...) invisible(NULL),
    mysterycall_clean_phase2       = function(...) CLEAN2,
    mysterycall_not_contacted_states = function(...) NULL,
    mysterycall_save_quality_table = function(...) NULL,
    mysterycall_validate_npi       = function(x, ...) x,
    .package = "mysterycall",
    {
      expect_error(
        suppressMessages(mysterycall_run_workflow(
          taxonomy_terms      = NULL,
          name_data           = "this_is_not_a_data_frame",
          phase1_data         = PHASE1,
          lab_assistant_names = c("Alice", "Bob"),
          output_directory    = tempdir(),
          phase2_data         = PHASE2,
          quality_check_path  = file.path(tempdir(), "qc_test.csv"),
          verbose             = FALSE
        )),
        regexp = "`name_data` must be a data frame"
      )
    }
  )
})

# ---------------------------------------------------------------------------
# Test 4 — bad input: name_data missing 'first' and 'last' columns
# ---------------------------------------------------------------------------
test_that("mysterycall_run_workflow errors when name_data lacks first/last columns", {
  skip_if_not_installed("digest")

  bad_name_data <- data.frame(physician = "Smith", stringsAsFactors = FALSE)

  with_mocked_bindings(
    mysterycall_clean_phase1       = function(...) CLEAN1,
    mysterycall_split_and_save     = function(...) invisible(NULL),
    mysterycall_clean_phase2       = function(...) CLEAN2,
    mysterycall_not_contacted_states = function(...) NULL,
    mysterycall_save_quality_table = function(...) NULL,
    mysterycall_validate_npi       = function(x, ...) x,
    .package = "mysterycall",
    {
      expect_error(
        suppressMessages(mysterycall_run_workflow(
          taxonomy_terms      = NULL,
          name_data           = bad_name_data,
          phase1_data         = PHASE1,
          lab_assistant_names = c("Alice", "Bob"),
          output_directory    = tempdir(),
          phase2_data         = PHASE2,
          quality_check_path  = file.path(tempdir(), "qc_test.csv"),
          verbose             = FALSE
        )),
        regexp = "`name_data` must contain columns named `first` and `last`"
      )
    }
  )
})

# ---------------------------------------------------------------------------
# Test 5 — cleaned_phase1 from the mocked workflow equals the stub
# ---------------------------------------------------------------------------
test_that("cleaned_phase1 slot matches the mocked clean_phase1 output", {
  skip_if_not_installed("digest")

  result <- suppressMessages(suppressWarnings(run_workflow_mocked()))

  expect_identical(result$cleaned_phase1, CLEAN1)
})
