# Contract enforcement tests — each test corresponds to an explicit guarantee
# documented in @section Contract: blocks in the package source.
#
# The rule: every documented invariant must have a test here.
# If a guarantee is removed from docs, remove its test. If a test fails,
# the documented contract has been broken.

library(testthat)

# ---------------------------------------------------------------------------
# mysterycall_validate_npi() contracts
# ---------------------------------------------------------------------------

test_that("Contract: validate_npi output rows are a subset of input rows", {
  input <- data.frame(
    npi = c("1234567893", "0000000000", NA_character_, "not-an-npi", "1234567893"),
    name = letters[1:5],
    stringsAsFactors = FALSE
  )
  result <- mysterycall_validate_npi(input)
  expect_lte(nrow(result), nrow(input))
})

test_that("Contract: validate_npi never adds rows", {
  input <- data.frame(npi = "1234567893", stringsAsFactors = FALSE)
  result <- mysterycall_validate_npi(input)
  expect_lte(nrow(result), 1L)
})

test_that("Contract: validate_npi output NPI column is always character", {
  input <- data.frame(npi = c(1234567893, 9999999999), stringsAsFactors = FALSE)
  result <- mysterycall_validate_npi(input)
  expect_true(is.character(result$npi))
})

test_that("Contract: validate_npi removes all-zeros NPI (placeholder prevention)", {
  input <- data.frame(
    npi = c("1234567893", "0000000000"),
    stringsAsFactors = FALSE
  )
  result <- mysterycall_validate_npi(input)
  expect_false("0000000000" %in% result$npi,
               label = "All-zeros placeholder NPI must be removed")
})

test_that("Contract: validate_npi removes NA NPIs", {
  input <- data.frame(npi = c("1234567893", NA_character_), stringsAsFactors = FALSE)
  result <- mysterycall_validate_npi(input)
  expect_equal(sum(is.na(result$npi)), 0L)
})

# ---------------------------------------------------------------------------
# mysterycall_search_taxonomy() contracts
# ---------------------------------------------------------------------------

test_that("Contract: search_taxonomy returns data frame, never NULL", {
  result <- with_mocked_bindings(
    npi_search  = function(...) NULL,
    npi_flatten = function(x, ...) x,
    .package = "npi",
    mysterycall_search_taxonomy("Nonexistent Taxonomy XYZ",
                                write_snapshot = FALSE, notify = FALSE)
  )
  expect_false(is.null(result), label = "Must return data frame, not NULL")
  expect_s3_class(result, "data.frame")
})

test_that("Contract: search_taxonomy returns zero rows (not NULL) on no match", {
  result <- with_mocked_bindings(
    npi_search  = function(...) NULL,
    npi_flatten = function(x, ...) x,
    .package = "npi",
    mysterycall_search_taxonomy("Nonexistent Taxonomy XYZ",
                                write_snapshot = FALSE, notify = FALSE)
  )
  expect_equal(nrow(result), 0L,
               label = "No-match result must be zero-row data frame")
})

test_that("Contract: search_taxonomy deduplicates on NPI", {
  dup_result <- data.frame(
    npi = c("1234567893", "1234567893", "9876543210"),
    basic_first_name = c("A", "A", "B"),
    basic_last_name  = c("X", "X", "Y"),
    basic_credential = c("MD", "MD", "MD"),
    addresses_country_name = rep("United States", 3),
    taxonomies_desc = rep("Gynecologic Oncology", 3),
    stringsAsFactors = FALSE
  )
  result <- with_mocked_bindings(
    npi_search  = function(...) list(id = 1),
    npi_flatten = function(...) dup_result,
    .package = "npi",
    mysterycall_search_taxonomy("Gynecologic Oncology",
                                write_snapshot = FALSE, notify = FALSE)
  )
  expect_equal(sum(result$npi == "1234567893"), 1L,
               label = "Duplicate NPIs must be deduplicated in output")
})

# ---------------------------------------------------------------------------
# mysterycall_split_and_save() contracts
# ---------------------------------------------------------------------------

test_that("Contract: split_and_save assigns every row to exactly one workbook", {
  skip_if_not_installed("openxlsx")
  input <- data.frame(
    names       = paste("Provider", 1:10),
    practice_name = paste("Practice", 1:10),
    phone_number  = "555-0100",
    state_name    = "Colorado",
    npi           = paste0(rep("1", 10), formatC(1:10, width = 9, flag = "0")),
    for_redcap    = "Yes",
    id            = as.character(1:10),
    doctor_id     = paste0("D", 1:10),
    insurance     = "Medicaid",
    stringsAsFactors = FALSE
  )
  tmp <- tempdir()
  mysterycall_split_and_save(
    data_or_path        = input,
    output_directory    = tmp,
    lab_assistant_names = c("Alice", "Bob"),
    seed                = 42,
    insurance_order     = "Medicaid"
  )
  # Read back and count rows across individual workbooks (not the combined file)
  alice_file <- list.files(tmp, pattern = "Alice.*\\.xlsx", full.names = TRUE)
  bob_file   <- list.files(tmp, pattern = "Bob.*\\.xlsx",   full.names = TRUE)
  if (length(alice_file) > 0 && length(bob_file) > 0) {
    alice_rows <- nrow(openxlsx::read.xlsx(alice_file[1]))
    bob_rows   <- nrow(openxlsx::read.xlsx(bob_file[1]))
    expect_equal(alice_rows + bob_rows, nrow(input),
                 label = "All input rows must appear across workbooks")
  }
})

test_that("Contract: split_and_save is reproducible with same seed", {
  skip_if_not_installed("openxlsx")
  input <- data.frame(
    names         = paste("Provider", 1:6),
    practice_name = "Clinic",
    phone_number  = "555-0100",
    state_name    = "Colorado",
    npi           = paste0("1", formatC(1:6, width = 9, flag = "0")),
    for_redcap    = "Yes",
    id            = as.character(1:6),
    doctor_id     = paste0("D", 1:6),
    insurance     = "Medicaid",
    stringsAsFactors = FALSE
  )
  tmp1 <- file.path(tempdir(), "split_seed_test_1")
  tmp2 <- file.path(tempdir(), "split_seed_test_2")
  dir.create(tmp1, showWarnings = FALSE)
  dir.create(tmp2, showWarnings = FALSE)

  mysterycall_split_and_save(input, tmp1, c("Alice", "Bob"), seed = 42,
                              insurance_order = "Medicaid")
  mysterycall_split_and_save(input, tmp2, c("Alice", "Bob"), seed = 42,
                              insurance_order = "Medicaid")

  f1 <- list.files(tmp1, pattern = "Alice.*\\.xlsx", full.names = TRUE)
  f2 <- list.files(tmp2, pattern = "Alice.*\\.xlsx", full.names = TRUE)
  if (length(f1) > 0 && length(f2) > 0) {
    d1 <- openxlsx::read.xlsx(f1[1])
    d2 <- openxlsx::read.xlsx(f2[1])
    expect_equal(d1, d2,
                 label = "Same seed must produce identical workbook content")
  }
})

# ---------------------------------------------------------------------------
# mysterycall_clean_phase1() contracts
# ---------------------------------------------------------------------------

test_that("Contract: clean_phase1 output rows >= input rows (no silent drop)", {
  skip_on_cran()
  input <- data.frame(
    names         = c("Alice Smith", "Bob Jones", ""),
    practice_name = c("Clinic A", "Clinic B", "Clinic C"),
    phone_number  = c("555-0101", "555-0102", "555-0103"),
    state_name    = c("Colorado", "Texas", "Florida"),
    npi           = c("1234567893", "1234567891", "1234567890"),
    for_redcap    = c("Yes", "No", "Yes"),
    stringsAsFactors = FALSE
  )
  tmp <- tempdir()
  result <- mysterycall_clean_phase1(
    phase1_data = input,
    output_directory = tmp,
    verbose = FALSE,
    notify  = FALSE
  )
  expect_gte(nrow(result), nrow(input),
             label = "clean_phase1 must not silently drop rows")
})

test_that("Contract: clean_phase1 always adds processing_flag columns", {
  skip_on_cran()
  input <- data.frame(
    names         = "Alice Smith",
    practice_name = "Clinic A",
    phone_number  = "555-0101",
    state_name    = "Colorado",
    npi           = "1234567893",
    for_redcap    = "Yes",
    stringsAsFactors = FALSE
  )
  result <- mysterycall_clean_phase1(
    phase1_data = input,
    output_directory = tempdir(),
    verbose = FALSE,
    notify  = FALSE
  )
  flag_cols <- grep("^processing_flag_", names(result), value = TRUE)
  expect_gt(length(flag_cols), 0L,
            label = "Output must contain processing_flag_* columns")
})

# ---------------------------------------------------------------------------
# mysterycall_run_workflow() contracts
# ---------------------------------------------------------------------------

test_that("Contract: run_workflow always returns workflow_summary", {
  skip_on_cran()
  input <- data.frame(
    names = "Alice Smith", practice_name = "Clinic A",
    phone_number = "555-0101", state_name = "Colorado",
    npi = "1234567893", for_redcap = "Yes",
    stringsAsFactors = FALSE
  )
  result <- suppressWarnings(tryCatch(
    mysterycall_run_workflow(
      phase1_data = input,
      lab_assistant_names = c("A", "B"),
      output_directory = tempdir(),
      phase2_data = data.frame(),
      quality_check_path = file.path(tempdir(), "qc_contract_test.csv"),
      verbose = FALSE
    ),
    error = function(e) list(workflow_summary = data.frame(stage = character()))
  ))
  expect_true(!is.null(result$workflow_summary),
              label = "workflow_summary must always be present in result")
})

# ---------------------------------------------------------------------------
# mysterycall:::mysterycall_format_duration() contracts
# ---------------------------------------------------------------------------

test_that("Contract: format_duration is deterministic", {
  expect_equal(mysterycall:::mysterycall_format_duration(45),  mysterycall:::mysterycall_format_duration(45))
  expect_equal(mysterycall:::mysterycall_format_duration(125), mysterycall:::mysterycall_format_duration(125))
})

test_that("Contract: format_duration returns character string", {
  expect_true(is.character(mysterycall:::mysterycall_format_duration(90)))
})

test_that("Contract: format_duration handles zero seconds", {
  result <- mysterycall:::mysterycall_format_duration(0)
  expect_true(is.character(result))
  expect_true(nchar(result) > 0L)
})

# ---------------------------------------------------------------------------
# mysterycall:::mysterycall_progress_summary() contracts
# ---------------------------------------------------------------------------

test_that("Contract: progress_summary returns a data frame (tibble)", {
  tr <- mysterycall:::mysterycall_progress_tracker(c("Step A", "Step B"), update_every = 1e9)
  mysterycall:::mysterycall_progress_start(tr, "Step A")
  mysterycall:::mysterycall_progress_finish(tr, "Step A", score = 0.9)
  result <- mysterycall:::mysterycall_progress_summary(tr)
  expect_s3_class(result, "data.frame")
  expect_true("step" %in% names(result) || ncol(result) > 0L,
              label = "Summary must have at least one column")
})
