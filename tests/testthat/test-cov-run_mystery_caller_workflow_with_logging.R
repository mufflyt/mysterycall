library(testthat)
library(mysterycall)

# mysterycall_run_workflow_logged() invokes the full mystery-caller pipeline
# (NPI API search, geocoding, phase1/phase2 cleaning, etc.) which requires
# specific infrastructure that cannot be replicated in unit tests.
# These tests verify the function exists, is exported, and rejects obviously
# invalid inputs without spinning up the full workflow.

test_that("mysterycall_run_workflow_logged is exported and callable", {
  expect_true(is.function(mysterycall_run_workflow_logged))
})

test_that("mysterycall_run_workflow_logged errors on NULL phase1_data", {
  expect_error(
    mysterycall_run_workflow_logged(
      phase1_data        = NULL,
      lab_assistant_names = "Alice",
      output_directory   = tempdir()
    )
  )
})

test_that("mysterycall_run_workflow_logged errors on non-data-frame phase1_data", {
  expect_error(
    mysterycall_run_workflow_logged(
      phase1_data        = "not a data frame",
      lab_assistant_names = "Alice",
      output_directory   = tempdir()
    )
  )
})
