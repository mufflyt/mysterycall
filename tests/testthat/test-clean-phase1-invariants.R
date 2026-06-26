# test-clean-phase1-invariants.R
#
# Invariant and gold-standard tests for mysterycall_clean_phase1().
#
# Testing tenets satisfied:
#   - Gold-standard manually-verified values (exact output structure for known input)
#   - Enforce domain invariants (insurance only "Medicaid"/"Blue Cross/Blue Shield")
#   - Idempotency-like (id_seed produces same random_ids for same missing-NPI rows)
#   - Test for silent failures (empty name flagged, whitespace name flagged)
#   - Cross-field referential integrity (each physician gets both insurance types)
#   - Boundary conditions (0 rows, 1 row, 3 rows)
#   - Schema contracts (processing_flag_* cols are logical, id col always present)

library(testthat)

skip_if_not_installed("dplyr")
skip_if_not_installed("janitor")
skip_if_not_installed("readr")
skip_if_not_installed("stringr")
skip_if_not_installed("humaniformat")

# ---------------------------------------------------------------------------
# Standard test data factory
# ---------------------------------------------------------------------------
make_phase1 <- function(n = 3) {
  data.frame(
    names         = paste("Doctor", LETTERS[1:n]),
    practice_name = paste("Clinic", seq_len(n)),
    phone_number  = rep("303-555-0100", n),
    state_name    = rep("CO", n),
    npi           = as.character(c(1922051358, 1750344388, 1548520133)[seq_len(n)]),
    stringsAsFactors = FALSE
  )
}

# Wrapper: run with verbose=FALSE and notify=FALSE for cleaner test output
run_clean <- function(df, duplicate_rows = TRUE, id_seed = NULL, output_format = "csv") {
  suppressMessages(suppressWarnings(
    mysterycall_clean_phase1(
      df,
      output_directory = tempdir(),
      verbose          = FALSE,
      notify           = FALSE,
      duplicate_rows   = duplicate_rows,
      id_seed          = id_seed,
      output_format    = output_format
    )
  ))
}

# ---------------------------------------------------------------------------
# 1. Invariant: insurance column contains ONLY "Medicaid" and "Blue Cross/Blue Shield"
# ---------------------------------------------------------------------------

test_that("insurance column contains only 'Medicaid' and 'Blue Cross/Blue Shield'", {
  result <- run_clean(make_phase1(3), duplicate_rows = TRUE)
  allowed <- c("Medicaid", "Blue Cross/Blue Shield")
  unexpected <- setdiff(unique(result$insurance), allowed)
  expect_equal(length(unexpected), 0L,
               label = paste("Unexpected insurance values:", paste(unexpected, collapse = ", ")))
})

test_that("both insurance types present after duplicate_rows=TRUE", {
  result <- run_clean(make_phase1(3), duplicate_rows = TRUE)
  expect_true("Medicaid" %in% result$insurance)
  expect_true("Blue Cross/Blue Shield" %in% result$insurance)
})

# ---------------------------------------------------------------------------
# 2. Invariant: output always has id column
# ---------------------------------------------------------------------------

test_that("output always has an 'id' column", {
  result <- run_clean(make_phase1(3))
  expect_true("id" %in% names(result),
              label = paste("Columns:", paste(names(result), collapse = ", ")))
})

test_that("id column is numeric/integer type", {
  result <- run_clean(make_phase1(3))
  expect_true(is.numeric(result$id) || is.integer(result$id),
              label = paste("id class:", class(result$id)))
})

# ---------------------------------------------------------------------------
# 3. Invariant: duplicate_rows=TRUE → nrow(output) == 2 * nrow(input)
# ---------------------------------------------------------------------------

test_that("duplicate_rows=TRUE produces 2x input rows [gold standard: 3 in → 6 out]", {
  input  <- make_phase1(3)
  result <- run_clean(input, duplicate_rows = TRUE)
  expect_equal(nrow(result), 2L * nrow(input),
               label = paste("nrow(input) =", nrow(input), ", nrow(result) =", nrow(result)))
})

test_that("duplicate_rows=TRUE: 1 row in → 2 rows out", {
  result <- run_clean(make_phase1(1), duplicate_rows = TRUE)
  expect_equal(nrow(result), 2L)
})

test_that("duplicate_rows=TRUE: 2 rows in → 4 rows out", {
  result <- run_clean(make_phase1(2), duplicate_rows = TRUE)
  expect_equal(nrow(result), 4L)
})

# ---------------------------------------------------------------------------
# 4. Invariant: duplicate_rows=FALSE → nrow(output) == nrow(input)
# ---------------------------------------------------------------------------

test_that("duplicate_rows=FALSE preserves original row count", {
  input  <- make_phase1(3)
  result <- run_clean(input, duplicate_rows = FALSE)
  expect_equal(nrow(result), nrow(input),
               label = paste("nrow(input) =", nrow(input), ", nrow(result) =", nrow(result)))
})

test_that("duplicate_rows=FALSE: 1 row in → 1 row out", {
  result <- run_clean(make_phase1(1), duplicate_rows = FALSE)
  expect_equal(nrow(result), 1L)
})

# ---------------------------------------------------------------------------
# 5. Domain constraint: processing_flag_* columns are always logical type
# ---------------------------------------------------------------------------

test_that("all processing_flag_* columns are logical type", {
  result    <- run_clean(make_phase1(3))
  flag_cols <- grep("^processing_flag_", names(result), value = TRUE)

  expect_gte(length(flag_cols), 1L,
             label = "At least one processing_flag_* column must exist")

  for (col in flag_cols) {
    expect_type(result[[col]], "logical")
  }
})

test_that("processing_flag_empty_name column exists", {
  result <- run_clean(make_phase1(3))
  expect_true("processing_flag_empty_name" %in% names(result))
})

test_that("processing_flag_generated_id column exists", {
  result <- run_clean(make_phase1(3))
  expect_true("processing_flag_generated_id" %in% names(result))
})

test_that("processing_flag_is_duplicate column exists when duplicate_rows=TRUE", {
  result <- run_clean(make_phase1(3), duplicate_rows = TRUE)
  expect_true("processing_flag_is_duplicate" %in% names(result))
})

# ---------------------------------------------------------------------------
# 6. id_seed produces same random_ids for same missing-NPI rows
# ---------------------------------------------------------------------------

test_that("id_seed produces identical random_ids on repeated runs", {
  # Use data WITHOUT npi to force random_id generation
  df_no_npi <- data.frame(
    names         = c("Doctor A", "Doctor B"),
    practice_name = c("Clinic 1", "Clinic 2"),
    phone_number  = c("303-555-0100", "303-555-0200"),
    state_name    = c("CO", "CO"),
    stringsAsFactors = FALSE
  )
  result1 <- run_clean(df_no_npi, id_seed = 42)
  result2 <- run_clean(df_no_npi, id_seed = 42)

  expect_identical(result1$random_id, result2$random_id,
                   label = "id_seed=42 must produce identical random_ids both times")
})

# ---------------------------------------------------------------------------
# 7. Silent failure: empty name gets processing_flag_empty_name=TRUE
# ---------------------------------------------------------------------------

test_that("row with empty name gets processing_flag_empty_name == TRUE", {
  df <- make_phase1(3)
  df$names[1] <- ""
  result <- run_clean(df, duplicate_rows = FALSE)
  expect_true(any(result$processing_flag_empty_name == TRUE),
              label = "Empty name row must have processing_flag_empty_name == TRUE")
})

# ---------------------------------------------------------------------------
# 8. Silent failure: whitespace-only name gets processing_flag_empty_name=TRUE
# ---------------------------------------------------------------------------

test_that("row with all-whitespace name gets processing_flag_empty_name == TRUE", {
  df <- make_phase1(3)
  df$names[2] <- "   "
  result <- run_clean(df, duplicate_rows = FALSE)
  expect_true(any(result$processing_flag_empty_name == TRUE),
              label = "Whitespace-only name must have processing_flag_empty_name == TRUE")
})

test_that("empty-named row is NOT silently dropped (it is retained with flag)", {
  df <- make_phase1(3)
  df$names[1] <- ""
  result <- run_clean(df, duplicate_rows = FALSE)
  # Row should still be present (not dropped), just flagged
  expect_equal(nrow(result), 3L,
               label = "Empty-named row should be retained, not silently dropped")
})

# ---------------------------------------------------------------------------
# 9. Cross-field: each physician gets exactly one Medicaid and one BCBS row
#    (after duplicate_rows=TRUE with 3 physicians → 6 rows, each type appears 3 times)
# ---------------------------------------------------------------------------

test_that("each insurance type appears exactly nrow(input) times after duplicate_rows=TRUE", {
  input  <- make_phase1(3)
  result <- run_clean(input, duplicate_rows = TRUE)
  n_medicaid <- sum(result$insurance == "Medicaid")
  n_bcbs     <- sum(result$insurance == "Blue Cross/Blue Shield")
  expect_equal(n_medicaid, nrow(input),
               label = "Medicaid count should equal original row count")
  expect_equal(n_bcbs, nrow(input),
               label = "BCBS count should equal original row count")
})

# ---------------------------------------------------------------------------
# 10. Gold standard: known input → exact output column set
# ---------------------------------------------------------------------------

test_that("mysterycall_clean_phase1 output includes all required columns", {
  result <- run_clean(make_phase1(3))
  required_cols <- c(
    "insurance", "id", "for_redcap", "names",
    "practice_name", "phone_number", "state_name",
    "processing_flag_empty_name", "processing_flag_generated_id",
    "processing_flag_is_duplicate"
  )
  missing <- setdiff(required_cols, names(result))
  expect_equal(length(missing), 0L,
               label = paste("Missing columns:", paste(missing, collapse = ", ")))
})

test_that("for_redcap column is character type", {
  result <- run_clean(make_phase1(3))
  expect_type(result$for_redcap, "character")
})

test_that("for_redcap entries contain the phone number", {
  result <- run_clean(make_phase1(3), duplicate_rows = FALSE)
  # The formatted phone number is "(303) 555-0100" after format_phone_number()
  expect_true(all(grepl("555", result$for_redcap)),
              label = "for_redcap should contain the phone number")
})

# ---------------------------------------------------------------------------
# 11. Boundary: names column with mix of valid and flagged rows
# ---------------------------------------------------------------------------

test_that("output has correct flag distribution for mixed-name data", {
  df <- make_phase1(3)
  df$names[1] <- ""   # flagged as empty
  # Rows 2 and 3 are valid
  result <- run_clean(df, duplicate_rows = FALSE)
  n_flagged <- sum(result$processing_flag_empty_name == TRUE, na.rm = TRUE)
  expect_gte(n_flagged, 1L, label = "At least 1 row should be flagged as empty name")
  # The other 2 should NOT be flagged
  n_not_flagged <- sum(result$processing_flag_empty_name == FALSE, na.rm = TRUE)
  expect_equal(n_not_flagged, 2L)
})
