# Snapshot regression tests for the audit trail JSON written by
# mysterycall_clean_phase1(). These tests enforce two guarantees:
#
#   1. Schema stability: every required field from tests/fixtures/audit_trail_schema.json
#      is present in every audit file.
#   2. Value stability: flag counts for the canonical 4-row input match
#      tests/fixtures/expected_audit_counts.json.
#
# On the first run, expect_snapshot() creates _snaps/test-audit-trail-snapshot.md.
# Subsequent runs diff against that file. A snapshot failure means the audit
# trail structure or cleaning logic changed; update the snapshot intentionally
# with testthat::snapshot_accept() if the change is deliberate.

library(testthat)

skip_if_not_installed("jsonlite")

# ---------------------------------------------------------------------------
# Canonical 4-row input — fixed for all tests in this file.
# Row 3: empty name + NA NPI  → triggers empty_names_count and generated_id path.
# Row 4: single-word name     → triggers no_last_name_count.
# duplicate_rows = FALSE ensures output_rows == input_rows.
# ---------------------------------------------------------------------------
canonical_input <- data.frame(
  names         = c("Alice Smith", "Bob Jones", "", "Carol"),
  practice_name = c("Clinic A", "Clinic B", "Clinic C", "Clinic D"),
  phone_number  = c("555-0101", "555-0102", "555-0103", "555-0104"),
  state_name    = c("Colorado", "Texas", "Florida", "New York"),
  npi           = c("1234567893", "1234567891", NA_character_, "1234567890"),
  for_redcap    = c("Yes", "No", "Yes", "Yes"),
  stringsAsFactors = FALSE
)

# Run clean_phase1 on the canonical input; return parsed audit JSON.
# Skips (not fails) if no audit file is written (e.g. jsonlite absent).
run_canonical_audit <- function() {
  tmp <- tempfile()
  dir.create(tmp)
  suppressMessages(
    mysterycall_clean_phase1(
      phase1_data      = canonical_input,
      output_directory = tmp,
      verbose          = FALSE,
      notify           = FALSE,
      duplicate_rows   = FALSE
    )
  )
  files <- list.files(tmp, pattern = "audit_trail.*\\.json", full.names = TRUE)
  if (length(files) == 0L) skip("No audit trail JSON was written")
  jsonlite::fromJSON(files[1L], simplifyVector = FALSE)
}

# Strip volatile fields before snapshot comparison so timestamps and
# environment-specific values do not cause spurious failures.
normalize_for_snapshot <- function(audit) {
  volatile <- c("start_time", "end_time", "duration_seconds",
                "r_version", "platform", "package_version", "parameters")
  for (field in volatile) audit[[field]] <- NULL
  # Sort for stable ordering across R versions
  audit[sort(names(audit))]
}

# ---------------------------------------------------------------------------
# 1. Schema presence: every required field must be in the audit JSON
# ---------------------------------------------------------------------------

test_that("Snapshot: audit JSON contains all required schema fields", {
  skip_on_cran()
  audit <- run_canonical_audit()

  required_fields <- c(
    "function_name", "input_rows", "input_cols", "input_colnames",
    "output_rows", "output_cols", "empty_names_count", "no_last_name_count",
    "rows_retained_pct", "rows_duplicated", "original_npi_preserved",
    "quality_metrics"
  )

  missing <- setdiff(required_fields, names(audit))
  expect_equal(missing, character(0L),
               label = paste("Missing required audit fields:", paste(missing, collapse = ", ")))
})

# ---------------------------------------------------------------------------
# 2. Value stability: flag counts match the expected_audit_counts fixture
# ---------------------------------------------------------------------------

test_that("Snapshot: audit counts match expected_audit_counts fixture", {
  skip_on_cran()
  audit <- run_canonical_audit()

  fixture_file <- testthat::test_path("../fixtures/expected_audit_counts.json")
  if (!file.exists(fixture_file)) skip("Fixture file not found")
  expected <- jsonlite::fromJSON(fixture_file, simplifyVector = TRUE)

  expect_equal(audit$function_name,   expected$function_name,
               label = "function_name must match fixture")
  expect_equal(audit$input_rows,      expected$input_rows,
               label = "input_rows must match fixture")
  expect_equal(audit$input_cols,      expected$input_cols,
               label = "input_cols must match fixture")
  expect_equal(audit$output_rows,     expected$output_rows,
               label = "output_rows must match fixture (duplicate_rows=FALSE)")
  expect_equal(audit$empty_names_count, expected$empty_names_count,
               label = "empty_names_count must match fixture")
  expect_equal(audit$no_last_name_count, expected$no_last_name_count,
               label = "no_last_name_count must match fixture")
  expect_equal(audit$rows_retained_pct,  expected$rows_retained_pct,
               label = "rows_retained_pct must be 100 for no-drop run")
  expect_equal(audit$rows_duplicated,    expected$rows_duplicated,
               label = "rows_duplicated must be FALSE when duplicate_rows=FALSE")
  expect_equal(audit$original_npi_preserved, expected$original_npi_preserved,
               label = "original_npi_preserved must be TRUE when npi column present")

  actual_colnames <- sort(unlist(audit$input_colnames))
  expected_colnames <- sort(expected$input_colnames)
  expect_equal(actual_colnames, expected_colnames,
               label = "input_colnames must match fixture column names")
})

# ---------------------------------------------------------------------------
# 3. Structural snapshot: catches silent field additions, removals, renames
# ---------------------------------------------------------------------------

test_that("Snapshot: normalized audit structure is stable", {
  skip_on_cran()
  audit <- run_canonical_audit()
  normalized <- normalize_for_snapshot(audit)

  # Snapshot captures field names and non-volatile values.
  # Update with testthat::snapshot_accept("audit-trail-snapshot") if intentional.
  expect_snapshot(names(normalized))
})

test_that("Snapshot: quality_metrics keys are stable", {
  skip_on_cran()
  audit <- run_canonical_audit()
  expect_snapshot(sort(names(audit$quality_metrics)))
})

# ---------------------------------------------------------------------------
# 4. Fixture consistency: schema fixture itself is valid JSON with required keys
# ---------------------------------------------------------------------------

test_that("Fixture: audit_trail_schema.json is valid and contains required/volatile sections", {
  fixture_file <- testthat::test_path("../fixtures/audit_trail_schema.json")
  if (!file.exists(fixture_file)) skip("Schema fixture file not found")

  schema <- jsonlite::fromJSON(fixture_file, simplifyVector = FALSE)
  expect_true("required"  %in% names(schema),
              label = "Schema fixture must have 'required' section")
  expect_true("volatile"  %in% names(schema),
              label = "Schema fixture must have 'volatile' section")
  expect_true("conditional" %in% names(schema),
              label = "Schema fixture must have 'conditional' section")
  expect_gt(length(schema$required), 5L,
            label = "Schema must document at least 6 required fields")
})

test_that("Fixture: schema_version is declared in audit_trail_schema.json required section", {
  schema_file <- testthat::test_path("../fixtures/audit_trail_schema.json")
  if (!file.exists(schema_file)) skip("Schema fixture file not found")

  schema <- jsonlite::fromJSON(schema_file, simplifyVector = FALSE)
  expect_true("schema_version" %in% names(schema$required),
              label = "schema_version must be listed as a required field in the schema fixture")
  expect_true(is.character(schema$required$schema_version))
  expect_match(schema$required$schema_version, "semantic version|schema",
               ignore.case = TRUE,
               label = "schema_version description must mention semantic versioning")
})

# ---------------------------------------------------------------------------
# 5. schema_version and cohort_hash contracts
# ---------------------------------------------------------------------------

test_that("Audit schema_version is present, semantic, and matches fixture", {
  skip_on_cran()
  audit <- run_canonical_audit()

  fixture_file <- testthat::test_path("../fixtures/expected_audit_counts.json")
  if (!file.exists(fixture_file)) skip("Fixture file not found")
  expected <- jsonlite::fromJSON(fixture_file, simplifyVector = TRUE)

  expect_true("schema_version" %in% names(audit),
              label = paste("schema_version missing. Available fields:",
                            paste(names(audit), collapse = ", ")))
  expect_type(audit$schema_version, "character")
  expect_length(audit$schema_version, 1L)
  expect_match(audit$schema_version, "^\\d+\\.\\d+\\.\\d+$",
               label = "schema_version must follow MAJOR.MINOR.PATCH")
  expect_identical(audit$schema_version, expected$schema_version,
                   label = paste(
                     "Audit schema_version does not match fixture.",
                     "If schema changed intentionally:",
                     "1. Update audit_trail_schema.json",
                     "2. Update expected_audit_counts.json",
                     "3. Refresh snapshot files with testthat::snapshot_accept()"
                   ))
})

test_that("Audit cohort_hash is present and SHA-256 shaped", {
  skip_on_cran()
  audit <- run_canonical_audit()

  expect_true("cohort_hash" %in% names(audit),
              label = "cohort_hash must be present in every audit JSON")
  expect_type(audit$cohort_hash, "character")
  expect_match(audit$cohort_hash, "^[a-f0-9]{64}$",
               label = "cohort_hash must be a 64-character lowercase hex SHA-256 digest")
})

test_that("Audit cohort_hash is deterministic for identical input", {
  skip_on_cran()
  audit1 <- run_canonical_audit()
  audit2 <- run_canonical_audit()

  expect_identical(audit1$cohort_hash, audit2$cohort_hash,
                   label = "Same input must always produce the same cohort_hash")
})

# ---------------------------------------------------------------------------
# 6. artifact_id — content-addressable output identity
# ---------------------------------------------------------------------------

test_that("Artifact: artifact_id is present and SHA-256 shaped", {
  skip_on_cran()
  audit <- run_canonical_audit()

  expect_true("artifact_id" %in% names(audit),
              label = paste("artifact_id missing. Available fields:",
                            paste(names(audit), collapse = ", ")))
  expect_type(audit$artifact_id, "character")
  expect_match(audit$artifact_id, "^[a-f0-9]{64}$",
               label = "artifact_id must be a 64-character lowercase hex SHA-256 digest")
})

test_that("Artifact: artifact_id is deterministic for identical input", {
  skip_on_cran()
  audit1 <- run_canonical_audit()
  audit2 <- run_canonical_audit()

  expect_identical(audit1$artifact_id, audit2$artifact_id,
                   label = "Same input must always produce the same artifact_id")
})

test_that("Artifact: artifact_id differs from cohort_hash (distinct identity layers)", {
  skip_on_cran()
  audit <- run_canonical_audit()

  expect_false(identical(audit$artifact_id, audit$cohort_hash),
               label = "artifact_id (output identity) must differ from cohort_hash (input identity)")
})

test_that("Artifact: artifact_id changes when processing output changes", {
  skip_on_cran()
  skip_if_not_installed("jsonlite")

  input_a <- canonical_input
  input_b <- canonical_input
  input_b$names[1] <- "Different Name Entirely"

  tmp_a <- tempfile(); tmp_b <- tempfile()
  dir.create(tmp_a); dir.create(tmp_b)

  suppressMessages({
    mysterycall_clean_phase1(input_a, tmp_a, verbose = FALSE, notify = FALSE, duplicate_rows = FALSE)
    mysterycall_clean_phase1(input_b, tmp_b, verbose = FALSE, notify = FALSE, duplicate_rows = FALSE)
  })

  files_a <- list.files(tmp_a, pattern = "audit_trail.*\\.json", full.names = TRUE)
  files_b <- list.files(tmp_b, pattern = "audit_trail.*\\.json", full.names = TRUE)
  if (!length(files_a) || !length(files_b)) skip("Audit files not written")

  audit_a <- jsonlite::fromJSON(files_a[1], simplifyVector = FALSE)
  audit_b <- jsonlite::fromJSON(files_b[1], simplifyVector = FALSE)

  expect_false(identical(audit_a$artifact_id, audit_b$artifact_id),
               label = "Different inputs must produce different artifact_ids")
  expect_false(identical(audit_a$cohort_hash, audit_b$cohort_hash),
               label = "Different inputs must produce different cohort_hashes")
})

# ---------------------------------------------------------------------------
# 7. parent_cohort_hash lineage stub
# ---------------------------------------------------------------------------

test_that("Lineage: parent_cohort_hash is NULL when no upstream hash supplied", {
  skip_on_cran()
  audit <- run_canonical_audit()  # run_canonical_audit does not pass parent_cohort_hash

  # Field may be absent (NULL serialises away) or explicitly NULL — both are correct.
  value <- audit[["parent_cohort_hash"]]
  expect_true(is.null(value),
              label = "parent_cohort_hash must be NULL when no upstream hash is supplied")
})

test_that("Lineage: supplied valid parent_cohort_hash is preserved verbatim", {
  skip_on_cran()
  skip_if_not_installed("jsonlite")

  fake_parent <- paste(rep("a", 64), collapse = "")  # valid 64-char hex

  tmp <- tempfile()
  dir.create(tmp)
  suppressMessages(
    mysterycall_clean_phase1(
      phase1_data        = canonical_input,
      output_directory   = tmp,
      verbose            = FALSE,
      notify             = FALSE,
      duplicate_rows     = FALSE,
      parent_cohort_hash = fake_parent
    )
  )
  files <- list.files(tmp, pattern = "audit_trail.*\\.json", full.names = TRUE)
  if (length(files) == 0L) skip("No audit trail JSON was written")
  audit <- jsonlite::fromJSON(files[1L], simplifyVector = FALSE)

  expect_identical(audit$parent_cohort_hash, fake_parent,
                   label = "A valid parent_cohort_hash must be written verbatim to audit JSON")
})

test_that("Lineage: invalid parent_cohort_hash is silently dropped", {
  skip_on_cran()
  skip_if_not_installed("jsonlite")

  tmp <- tempfile()
  dir.create(tmp)
  suppressMessages(
    mysterycall_clean_phase1(
      phase1_data        = canonical_input,
      output_directory   = tmp,
      verbose            = FALSE,
      notify             = FALSE,
      duplicate_rows     = FALSE,
      parent_cohort_hash = "not-a-valid-hash"
    )
  )
  files <- list.files(tmp, pattern = "audit_trail.*\\.json", full.names = TRUE)
  if (length(files) == 0L) skip("No audit trail JSON was written")
  audit <- jsonlite::fromJSON(files[1L], simplifyVector = FALSE)

  expect_true(is.null(audit[["parent_cohort_hash"]]),
              label = "An invalid parent_cohort_hash must be silently dropped (NULL in output)")
})

test_that("Snapshot: schema_version value is locked", {
  skip_on_cran()
  audit <- run_canonical_audit()

  expect_true("schema_version" %in% names(normalize_for_snapshot(audit)),
              label = "schema_version must survive volatile-field stripping")

  legacy_versions <- c("0.0.0", "0.1.0", "legacy", "unversioned", NA_character_, "")
  expect_false(audit$schema_version %in% legacy_versions,
               label = "schema_version must not be a legacy or unversioned placeholder")

  expect_snapshot_value(audit$schema_version, style = "json2")
})

# ---------------------------------------------------------------------------
# 8. Provenance replay verification
# ---------------------------------------------------------------------------

test_that("Replay: mysterycall_verify_artifact() passes on a freshly written audit file", {
  skip_on_cran()
  skip_if_not_installed("jsonlite")

  tmp <- tempfile()
  dir.create(tmp)
  suppressMessages(
    mysterycall_clean_phase1(
      phase1_data      = canonical_input,
      output_directory = tmp,
      verbose          = FALSE,
      notify           = FALSE,
      duplicate_rows   = FALSE
    )
  )
  audit_files <- list.files(tmp, pattern = "audit_trail.*\\.json", full.names = TRUE)
  if (!length(audit_files)) skip("No audit file written")

  expect_true(mysterycall_verify_artifact(audit_files[1]),
              label = "verify_artifact must return TRUE for an unmodified audit file")
})

test_that("Replay: verify_artifact detects manual tampering with a required field", {
  skip_on_cran()
  skip_if_not_installed("jsonlite")

  tmp <- tempfile()
  dir.create(tmp)
  suppressMessages(
    mysterycall_clean_phase1(
      phase1_data      = canonical_input,
      output_directory = tmp,
      verbose          = FALSE,
      notify           = FALSE,
      duplicate_rows   = FALSE
    )
  )
  audit_files <- list.files(tmp, pattern = "audit_trail.*\\.json", full.names = TRUE)
  if (!length(audit_files)) skip("No audit file written")

  # Tamper: change a stable field and rewrite the file
  audit <- jsonlite::fromJSON(audit_files[1], simplifyVector = FALSE)
  audit$input_rows <- audit$input_rows + 99L        # modify a stable field
  jsonlite::write_json(audit, audit_files[1], pretty = TRUE, auto_unbox = TRUE)

  expect_error(
    mysterycall_verify_artifact(audit_files[1]),
    regexp = "Artifact verification FAILED",
    label  = "verify_artifact must throw on a tampered audit file"
  )
})

test_that("Replay: verify_artifact errors on pre-1.2.0 audit file (no artifact_id)", {
  skip_on_cran()
  skip_if_not_installed("jsonlite")

  # Write a minimal audit JSON that has no artifact_id (simulating a legacy file)
  tmp_file <- tempfile(fileext = ".json")
  jsonlite::write_json(
    list(schema_version = "1.0.0", function_name = "mysterycall_clean_phase1",
         input_rows = 4L, output_rows = 4L),
    tmp_file, auto_unbox = TRUE
  )

  expect_error(
    mysterycall_verify_artifact(tmp_file),
    regexp = "schema version < 1.2.0",
    label  = "verify_artifact must error informatively on pre-1.2.0 files"
  )
})

test_that("Replay: volatile-field changes do not invalidate artifact_id", {
  skip_on_cran()
  skip_if_not_installed("jsonlite")

  tmp <- tempfile()
  dir.create(tmp)
  suppressMessages(
    mysterycall_clean_phase1(
      phase1_data      = canonical_input,
      output_directory = tmp,
      verbose          = FALSE,
      notify           = FALSE,
      duplicate_rows   = FALSE
    )
  )
  audit_files <- list.files(tmp, pattern = "audit_trail.*\\.json", full.names = TRUE)
  if (!length(audit_files)) skip("No audit file written")

  # Simulate volatile drift: update timestamps and platform as if re-run on
  # different hardware — artifact_id must still verify correctly
  audit <- jsonlite::fromJSON(audit_files[1], simplifyVector = FALSE)
  audit$start_time       <- "1970-01-01T00:00:00"
  audit$end_time         <- "1970-01-01T00:00:01"
  audit$duration_seconds <- 1.0
  audit$r_version        <- "R version 0.0.0 (simulated)"
  audit$platform         <- "simulated-platform"
  jsonlite::write_json(audit, audit_files[1], pretty = TRUE, auto_unbox = TRUE)

  # Must still pass — volatile fields are excluded from artifact_id computation
  expect_true(mysterycall_verify_artifact(audit_files[1]),
              label = "verify_artifact must pass even when volatile fields are altered")
})
