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

test_that("mysterycall_verify_artifact() succeeds with valid audit JSON", {
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")

  # Create a minimal audit object with stable fields
  audit_obj <- list(
    phase = "phase1",
    timestamp = "2026-01-15T10:00:00Z",
    total_records = 100L
  )

  # Compute stable keys and artifact_id exactly as the function does
  volatile_fields <- c("start_time", "end_time", "duration_seconds",
                       "r_version", "platform", "package_version", "parameters")
  stable_keys <- sort(setdiff(names(audit_obj), c(volatile_fields, "artifact_id")))
  stable_json <- jsonlite::toJSON(audit_obj[stable_keys], auto_unbox = TRUE, digits = NA)
  artifact_id <- digest::digest(as.character(stable_json), algo = "sha256", serialize = FALSE)

  # Add artifact_id and volatile fields to the object
  audit_obj$artifact_id <- artifact_id
  audit_obj$start_time <- "2026-01-15T09:00:00Z"
  audit_obj$end_time <- "2026-01-15T10:00:00Z"
  audit_obj$duration_seconds <- 3600L
  audit_obj$r_version <- "4.1.0"
  audit_obj$platform <- "x86_64-pc-linux-gnu"
  audit_obj$package_version <- "1.5.0"
  audit_obj$parameters <- list(mode = "test")

  # Write to temporary file
  tmp_file <- tempfile(fileext = ".json")
  jsonlite::write_json(audit_obj, tmp_file, auto_unbox = TRUE, digits = NA)

  # Should pass verification
  result <- suppressMessages(mysterycall_verify_artifact(tmp_file))
  expect_identical(result, TRUE)
  expect_invisible(result)

  # Cleanup
  unlink(tmp_file)
})

test_that("mysterycall_verify_artifact() fails when file does not exist", {
  non_existent <- "/tmp/definitely_does_not_exist_audit_12345.json"

  expect_error(
    mysterycall_verify_artifact(non_existent),
    "Audit file not found"
  )
})

test_that("mysterycall_verify_artifact() fails when artifact_id is missing", {
  skip_if_not_installed("jsonlite")

  # Create an audit object without artifact_id
  audit_obj <- list(
    phase = "phase1",
    total_records = 100L,
    timestamp = "2026-01-15T10:00:00Z"
  )

  # Write to temporary file
  tmp_file <- tempfile(fileext = ".json")
  jsonlite::write_json(audit_obj, tmp_file, auto_unbox = TRUE, digits = NA)

  # Should fail because artifact_id is missing
  expect_error(
    suppressMessages(mysterycall_verify_artifact(tmp_file)),
    "does not contain 'artifact_id'"
  )

  # Cleanup
  unlink(tmp_file)
})

test_that("mysterycall_verify_artifact() fails with invalid JSON", {
  skip_if_not_installed("jsonlite")

  # Create a temporary file with invalid JSON
  tmp_file <- tempfile(fileext = ".json")
  writeLines("{invalid json content", tmp_file)

  # Should fail due to JSON parsing error
  expect_error(
    suppressMessages(mysterycall_verify_artifact(tmp_file)),
    "Could not parse audit JSON"
  )

  # Cleanup
  unlink(tmp_file)
})

test_that("mysterycall_verify_artifact() fails with non-character audit_path", {
  # Pass numeric
  expect_error(
    mysterycall_verify_artifact(123),
    "audit_path must be a non-empty character scalar"
  )

  # Pass NULL
  expect_error(
    mysterycall_verify_artifact(NULL),
    "audit_path must be a non-empty character scalar"
  )

  # Pass logical
  expect_error(
    mysterycall_verify_artifact(TRUE),
    "audit_path must be a non-empty character scalar"
  )
})

test_that("mysterycall_verify_artifact() fails with character vector length > 1", {
  expect_error(
    mysterycall_verify_artifact(c("file1.json", "file2.json")),
    "audit_path must be a non-empty character scalar"
  )
})

test_that("mysterycall_verify_artifact() fails with empty string", {
  expect_error(
    mysterycall_verify_artifact(""),
    "audit_path must be a non-empty character scalar"
  )
})

test_that("mysterycall_verify_artifact() detects modified audit content", {
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("digest")

  # Create a valid audit object
  audit_obj <- list(
    phase = "phase1",
    timestamp = "2026-01-15T10:00:00Z",
    total_records = 100L
  )

  # Compute artifact_id with original content
  volatile_fields <- c("start_time", "end_time", "duration_seconds",
                       "r_version", "platform", "package_version", "parameters")
  stable_keys <- sort(setdiff(names(audit_obj), c(volatile_fields, "artifact_id")))
  stable_json <- jsonlite::toJSON(audit_obj[stable_keys], auto_unbox = TRUE, digits = NA)
  artifact_id <- digest::digest(as.character(stable_json), algo = "sha256", serialize = FALSE)

  # Add artifact_id to object
  audit_obj$artifact_id <- artifact_id

  # Convert to JSON string
  json_str <- jsonlite::toJSON(audit_obj, auto_unbox = TRUE, digits = NA)

  # Now corrupt it by modifying the JSON string directly
  # Change total_records from 100 to 200
  corrupted_json <- gsub("100", "200", json_str, fixed = TRUE)

  # Write the corrupted JSON to temporary file
  tmp_file <- tempfile(fileext = ".json")
  writeLines(corrupted_json, tmp_file)

  # Should fail because content was modified but artifact_id wasn't updated
  expect_error(
    suppressMessages(mysterycall_verify_artifact(tmp_file)),
    "Artifact verification FAILED"
  )

  # Cleanup
  unlink(tmp_file)
})
