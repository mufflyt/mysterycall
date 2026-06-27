## testthat 3rd-edition tests for mysterycall_clean_data() and
## mysterycall_clean_data_keep_identifiers()
## All test data built with base R only.

testthat::local_edition(3)

# ---------------------------------------------------------------------------
# Shared minimal fixture (all default column names present)
# ---------------------------------------------------------------------------
make_raw <- function() {
  data.frame(
    phone    = c("303-111-2222", "303-111-2222", "720-555-9999"),
    age      = c(55, 55, 72),
    insurance = c("Medicaid", "Medicaid", "Medicare"),
    gender   = c("Female", "Female", "Male"),
    Provider.Credential.Text              = c("MD", "MD", "DO"),
    academic_affiliation                  = c("University", NA_character_, "Community"),
    cbsatype10                            = c("Metro", "Metro", "Micro"),
    business_days_until_appointment       = c(7L, 7L, 14L),
    central_number_e_g_appointment_center = c("Yes", "Yes", "No"),
    first     = c("Jane", "Jane", "Bob"),
    last      = c("Doe",  "Doe",  "Smith"),
    record_id = 1:3,
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# 1. Returns a data.frame
# ---------------------------------------------------------------------------
test_that("mysterycall_clean_data() returns a data.frame", {
  result <- suppressMessages(mysterycall_clean_data(make_raw()))
  expect_s3_class(result, "data.frame")
})

# ---------------------------------------------------------------------------
# 2. Deduplication reduces rows when id_col has duplicates
# ---------------------------------------------------------------------------
test_that("deduplication removes duplicate id_col rows, keeping first", {
  raw    <- make_raw()   # 3 rows; phone[1] == phone[2]
  result <- suppressMessages(mysterycall_clean_data(raw, id_col = "phone"))
  # phone is PII so it is dropped, but dedup ran first -> 2 unique physicians
  expect_equal(nrow(result), 2L)
})

# ---------------------------------------------------------------------------
# 3. Age category column created when age_col provided
# ---------------------------------------------------------------------------
test_that("age_category column is created in the output when age_col is provided", {
  result <- suppressMessages(mysterycall_clean_data(make_raw()))
  # The column is renamed from 'age_category' -> 'Age category' during step 7
  expect_true("Age category" %in% names(result))
})

# ---------------------------------------------------------------------------
# 4. Age category has the correct labels from age_labels parameter
# ---------------------------------------------------------------------------
test_that("age_category uses the labels supplied via age_labels", {
  custom_labels <- c("Young", "Middle", "Senior")
  result <- suppressMessages(
    mysterycall_clean_data(
      make_raw(),
      age_breaks = c(-Inf, 50, 65, Inf),
      age_labels = custom_labels
    )
  )
  observed_levels <- levels(result[["Age category"]])
  expect_true(all(custom_labels %in% observed_levels))
})

# ---------------------------------------------------------------------------
# 5. Credential recoded: MD -> "Allopathic training"
# ---------------------------------------------------------------------------
test_that("MD credential is recoded to 'Allopathic training'", {
  result <- suppressMessages(mysterycall_clean_data(make_raw()))
  cred_col <- result[["Physician credential"]]
  expect_true("Allopathic training" %in% as.character(cred_col))
  expect_false("MD" %in% as.character(cred_col))
})

# ---------------------------------------------------------------------------
# 6. Rurality recoded: Metro -> "Metropolitan area"
# ---------------------------------------------------------------------------
test_that("Metro rurality is recoded to 'Metropolitan area'", {
  result <- suppressMessages(mysterycall_clean_data(make_raw()))
  rur_col <- result[["Rurality"]]
  expect_true("Metropolitan area" %in% as.character(rur_col))
  expect_false("Metro" %in% as.character(rur_col))
})

# ---------------------------------------------------------------------------
# 7. Academic recoded: University -> "Academic Practice"
# ---------------------------------------------------------------------------
test_that("University academic affiliation is recoded to 'Academic Practice'", {
  result <- suppressMessages(mysterycall_clean_data(make_raw()))
  acad_col <- result[["Academic affiliation"]]
  expect_true("Academic Practice" %in% as.character(acad_col))
  expect_false("University" %in% as.character(acad_col))
})

# ---------------------------------------------------------------------------
# 8. PII columns dropped when drop_pii = TRUE (default)
# ---------------------------------------------------------------------------
test_that("PII columns are absent from output when drop_pii = TRUE", {
  result <- suppressMessages(
    mysterycall_clean_data(make_raw(), drop_pii = TRUE)
  )
  pii <- c("phone", "first", "last", "record_id")
  for (col in pii) {
    expect_false(col %in% names(result),
                 label = paste("column", col, "should be dropped"))
  }
})

# ---------------------------------------------------------------------------
# 9. PII columns retained when drop_pii = FALSE
# ---------------------------------------------------------------------------
test_that("PII columns are present in output when drop_pii = FALSE", {
  result <- suppressMessages(
    mysterycall_clean_data(make_raw(), drop_pii = FALSE)
  )
  # 'phone' is the id_col used for dedup; 'first' and 'last' are PII
  pii <- c("first", "last", "record_id")
  for (col in pii) {
    expect_true(col %in% names(result),
                label = paste("column", col, "should be retained"))
  }
})

# ---------------------------------------------------------------------------
# 10. wait_col renamed to "Business days until appointment"
# ---------------------------------------------------------------------------
test_that("business_days_until_appointment is renamed to 'Business days until appointment'", {
  result <- suppressMessages(mysterycall_clean_data(make_raw()))
  expect_true("Business days until appointment" %in% names(result))
  expect_false("business_days_until_appointment" %in% names(result))
})

# ---------------------------------------------------------------------------
# 11. Error when data is not a data.frame
# ---------------------------------------------------------------------------
test_that("passing a non-data.frame as data throws an error", {
  expect_error(
    suppressMessages(mysterycall_clean_data(list(a = 1, b = 2))),
    regexp = "data frame"
  )
  expect_error(
    suppressMessages(mysterycall_clean_data("not a data frame")),
    regexp = "data frame"
  )
})

# ---------------------------------------------------------------------------
# 12. Missing id_col emits a warning (the code warns, does not stop)
# ---------------------------------------------------------------------------
test_that("id_col absent from data emits a warning and returns a data.frame", {
  raw <- make_raw()
  expect_warning(
    result <- suppressMessages(
      mysterycall_clean_data(raw, id_col = "nonexistent_col")
    ),
    regexp = "nonexistent_col"
  )
  # Despite the warning, a cleaned data.frame is still returned
  expect_s3_class(result, "data.frame")
})

# ---------------------------------------------------------------------------
# 13. mysterycall_clean_data_keep_identifiers() retains all columns
# ---------------------------------------------------------------------------
test_that("mysterycall_clean_data_keep_identifiers() keeps PII columns", {
  result <- suppressMessages(
    mysterycall_clean_data_keep_identifiers(make_raw())
  )
  expect_s3_class(result, "data.frame")
  # PII columns should survive (drop_pii defaults to FALSE in this variant)
  pii <- c("first", "last", "record_id")
  for (col in pii) {
    expect_true(col %in% names(result),
                label = paste("column", col, "should be retained"))
  }
})

# ---------------------------------------------------------------------------
# 14. Works when optional columns (age_col, credential_col) are NULL
# ---------------------------------------------------------------------------
test_that("optional columns skipped gracefully when set to NULL", {
  raw <- make_raw()
  result <- suppressMessages(
    mysterycall_clean_data(
      raw,
      age_col        = NULL,
      credential_col = NULL
    )
  )
  expect_s3_class(result, "data.frame")
  # No age category column because age_col = NULL
  expect_false("Age category" %in% names(result))
  # Raw credential column name should still be present under its original name
  # (no recode or rename applied) -- it is unchanged in the data
  expect_false("Physician credential" %in% names(result))
})

# ---------------------------------------------------------------------------
# 15. fill_cols that exist in data are forward-filled
# ---------------------------------------------------------------------------
test_that("fill_cols propagates last non-NA value forward", {
  # academic_affiliation has NA in row 2; fill should carry 'University' down.
  # After cleaning: column renamed to 'Academic affiliation' and value recoded
  # to 'Academic Practice'.
  raw <- data.frame(
    phone    = c("303-111-0001", "303-111-0002"),
    academic_affiliation = c("University", NA_character_),
    cbsatype10           = c("Metro", "Metro"),
    stringsAsFactors     = FALSE
  )
  result <- suppressMessages(
    mysterycall_clean_data(
      raw,
      id_col         = "phone",
      age_col        = NULL,
      credential_col = NULL,
      insurance_col  = NULL,
      gender_col     = NULL,
      central_col    = NULL,
      wait_col       = NULL,
      fill_cols      = "academic_affiliation"
    )
  )
  # Row 2 should have been forward-filled to "University", then recoded
  acad <- as.character(result[["Academic affiliation"]])
  expect_equal(acad[2L], "Academic Practice")
})
