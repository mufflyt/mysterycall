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

# ============================================================================
# mysterycall_rename_columns tests
# ============================================================================

test_that("mysterycall_rename_columns: happy path - rename single column by substring", {
  df <- data.frame(
    doctor_info = 1:5,
    patient_contact = 6:10,
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_rename_columns(df, "doctor", "physician_info")
  ))
  expect_s3_class(result, "data.frame")
  expect_true("physician_info" %in% names(result))
  expect_false("doctor_info" %in% names(result))
  expect_equal(nrow(result), 5)
})

test_that("mysterycall_rename_columns: happy path - rename multiple columns", {
  df <- data.frame(
    doctor_info = 1:5,
    patient_contact = 6:10,
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_rename_columns(
      df,
      target_strings = c("doctor", "patient"),
      new_names = c("physician_info", "pt_contact")
    )
  ))
  expect_s3_class(result, "data.frame")
  expect_true("physician_info" %in% names(result))
  expect_true("pt_contact" %in% names(result))
  expect_equal(nrow(result), 5)
})

test_that("mysterycall_rename_columns: happy path - returns rename_log attribute", {
  df <- data.frame(
    doctor_info = 1:5,
    patient_contact = 6:10,
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(suppressWarnings(
    mysterycall_rename_columns(df, "doctor", "physician_info")
  ))
  rename_log <- attr(result, "rename_log")
  expect_true(is.data.frame(rename_log))
  expect_equal(nrow(rename_log), 1)
  expect_true("renamed_from" %in% names(rename_log))
  expect_true("renamed_to" %in% names(rename_log))
  expect_equal(rename_log$renamed_from[1], "doctor_info")
  expect_equal(rename_log$renamed_to[1], "physician_info")
})

test_that("mysterycall_rename_columns: edge case - no matching columns", {
  df <- data.frame(x = 1:5, y = 6:10, stringsAsFactors = FALSE)
  result <- suppressMessages(suppressWarnings(
    mysterycall_rename_columns(df, "nonexistent", "new_col")
  ))
  expect_s3_class(result, "data.frame")
  expect_equal(names(result), c("x", "y"))
  expect_null(attr(result, "rename_log"))
})

test_that("mysterycall_rename_columns: edge case - empty vectors return unchanged dataframe", {
  df <- data.frame(x = 1:5, y = 6:10, stringsAsFactors = FALSE)
  result <- suppressMessages(suppressWarnings(
    mysterycall_rename_columns(df, character(0), character(0))
  ))
  expect_s3_class(result, "data.frame")
  expect_equal(names(result), c("x", "y"))
})

test_that("mysterycall_rename_columns: edge case - case-insensitive matching", {
  df <- data.frame(DOCTOR_INFO = 1:5, stringsAsFactors = FALSE)
  result <- suppressMessages(suppressWarnings(
    mysterycall_rename_columns(df, "doctor", "physician")
  ))
  expect_true("physician" %in% names(result))
  expect_false("DOCTOR_INFO" %in% names(result))
})

test_that("mysterycall_rename_columns: edge case - multiple matches triggers warning", {
  df <- data.frame(
    doctor_info = 1:5,
    doctor_notes = 6:10,
    stringsAsFactors = FALSE
  )
  expect_warning({
    result <- suppressMessages(
      mysterycall_rename_columns(df, "doctor", "physician")
    )
  }, "Multiple columns matched")
  expect_true("physician" %in% names(result))
})

test_that("mysterycall_rename_columns: bad input - length mismatch between vectors", {
  df <- data.frame(x = 1:5, y = 6:10, stringsAsFactors = FALSE)
  expect_error({
    suppressMessages(suppressWarnings(
      mysterycall_rename_columns(df, c("x", "y"), "new_col")
    ))
  }, "same length")
})

test_that("mysterycall_rename_columns: bad input - not a dataframe", {
  expect_error({
    suppressMessages(suppressWarnings(
      mysterycall_rename_columns(list(x = 1:5), "x", "new_x")
    ))
  })
})

test_that("mysterycall_rename_columns: bad input - empty string in target_strings", {
  df <- data.frame(x = 1:5, y = 6:10, stringsAsFactors = FALSE)
  expect_error({
    suppressMessages(suppressWarnings(
      mysterycall_rename_columns(df, c("x", ""), c("a", "b"))
    ))
  }, "empty or whitespace")
})

test_that("mysterycall_rename_columns: bad input - empty string in new_names", {
  df <- data.frame(x = 1:5, y = 6:10, stringsAsFactors = FALSE)
  expect_error({
    suppressMessages(suppressWarnings(
      mysterycall_rename_columns(df, c("x", "y"), c("a", ""))
    ))
  }, "empty or whitespace")
})

test_that("mysterycall_rename_columns: bad input - target already exists as column name", {
  df <- data.frame(x = 1:5, y = 6:10, stringsAsFactors = FALSE)
  expect_error({
    suppressMessages(suppressWarnings(
      mysterycall_rename_columns(df, "x", "y")
    ))
  }, "already exists")
})

# ============================================================================
# mysterycall_clean_phase2 tests
# ============================================================================

test_that("mysterycall_clean_phase2: happy path - dataframe input with matching columns", {
  skip_if_not_installed("janitor")
  df <- data.frame(
    Physician_Information = c("Smith, John", "Doe, Jane"),
    able_to_contact_office = c(TRUE, FALSE),
    stringsAsFactors = FALSE
  )
  tmpdir <- tempfile()
  dir.create(tmpdir, showWarnings = FALSE)

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase2(
      df,
      required_strings = c("physician", "contact"),
      standard_names = c("physician_info", "contact_office"),
      output_directory = tmpdir,
      output_format = "csv"
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_true("physician_info" %in% names(result))
  expect_true("contact_office" %in% names(result))
  expect_equal(nrow(result), 2)
  expect_true("output_path" %in% names(attributes(result)))
})

test_that("mysterycall_clean_phase2: happy path - parquet format output", {
  skip_if_not_installed("janitor")
  skip_if_not_installed("arrow")

  df <- data.frame(
    Physician_Information = c("Smith, John", "Doe, Jane"),
    able_to_contact_office = c(TRUE, FALSE),
    stringsAsFactors = FALSE
  )
  tmpdir <- tempfile()
  dir.create(tmpdir, showWarnings = FALSE)

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase2(
      df,
      required_strings = c("physician", "contact"),
      standard_names = c("physician_info", "contact_office"),
      output_directory = tmpdir,
      output_format = "parquet"
    )
  ))

  expect_s3_class(result, "data.frame")
  output_path <- attr(result, "output_path")
  expect_true(file.exists(output_path))
  expect_true(grepl("\\.parquet$", output_path))
})

test_that("mysterycall_clean_phase2: happy path - column reordering via standard_names", {
  skip_if_not_installed("janitor")
  df <- data.frame(
    col_a = 1:3,
    Physician_Information = c("A", "B", "C"),
    col_c = 4:6,
    stringsAsFactors = FALSE
  )
  tmpdir <- tempfile()
  dir.create(tmpdir, showWarnings = FALSE)

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase2(
      df,
      required_strings = c("physician"),
      standard_names = c("physician_info"),
      output_directory = tmpdir
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_true("physician_info" %in% names(result))
})

test_that("mysterycall_clean_phase2: edge case - partial matches when required_strings absent", {
  skip_if_not_installed("janitor")
  df <- data.frame(
    some_col = 1:3,
    another_col = 4:6,
    stringsAsFactors = FALSE
  )
  tmpdir <- tempfile()
  dir.create(tmpdir, showWarnings = FALSE)

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase2(
      df,
      required_strings = c("nonexistent"),
      standard_names = c("new_name"),
      output_directory = tmpdir
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_equal(ncol(result), 2)
})

test_that("mysterycall_clean_phase2: edge case - zero-row dataframe", {
  skip_if_not_installed("janitor")
  df <- data.frame(
    col_a = integer(0),
    col_b = integer(0),
    stringsAsFactors = FALSE
  )
  tmpdir <- tempfile()
  dir.create(tmpdir, showWarnings = FALSE)

  result <- suppressMessages(suppressWarnings(
    mysterycall_clean_phase2(
      df,
      required_strings = c("col_a"),
      standard_names = c("renamed_col"),
      output_directory = tmpdir
    )
  ))

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("mysterycall_clean_phase2: bad input - missing required_strings", {
  skip_if_not_installed("janitor")
  df <- data.frame(x = 1:5, y = 6:10, stringsAsFactors = FALSE)
  tmpdir <- tempfile()
  dir.create(tmpdir, showWarnings = FALSE)

  expect_error({
    suppressMessages(suppressWarnings(
      mysterycall_clean_phase2(
        df,
        required_strings = character(0),
        standard_names = c("new_col"),
        output_directory = tmpdir
      )
    ))
  }, "at least one")
})

test_that("mysterycall_clean_phase2: bad input - missing standard_names", {
  skip_if_not_installed("janitor")
  df <- data.frame(x = 1:5, y = 6:10, stringsAsFactors = FALSE)
  tmpdir <- tempfile()
  dir.create(tmpdir, showWarnings = FALSE)

  expect_error({
    suppressMessages(suppressWarnings(
      mysterycall_clean_phase2(
        df,
        required_strings = c("x"),
        standard_names = character(0),
        output_directory = tmpdir
      )
    ))
  }, "at least one")
})

test_that("mysterycall_clean_phase2: bad input - length mismatch", {
  skip_if_not_installed("janitor")
  df <- data.frame(x = 1:5, y = 6:10, stringsAsFactors = FALSE)
  tmpdir <- tempfile()
  dir.create(tmpdir, showWarnings = FALSE)

  expect_error({
    suppressMessages(suppressWarnings(
      mysterycall_clean_phase2(
        df,
        required_strings = c("x", "y"),
        standard_names = c("new_x"),
        output_directory = tmpdir
      )
    ))
  }, "same length")
})

test_that("mysterycall_clean_phase2: bad input - wrong type for data_or_path", {
  skip_if_not_installed("janitor")
  tmpdir <- tempfile()
  dir.create(tmpdir, showWarnings = FALSE)

  expect_error({
    suppressMessages(suppressWarnings(
      mysterycall_clean_phase2(
        123,
        required_strings = c("x"),
        standard_names = c("new_x"),
        output_directory = tmpdir
      )
    ))
  }, "dataframe or a valid file path")
})

test_that("mysterycall_clean_phase2: bad input - non-existent file path", {
  skip_if_not_installed("janitor")
  tmpdir <- tempfile()
  dir.create(tmpdir, showWarnings = FALSE)

  expect_error({
    suppressMessages(suppressWarnings(
      mysterycall_clean_phase2(
        "/nonexistent/path/to/file.csv",
        required_strings = c("x"),
        standard_names = c("new_x"),
        output_directory = tmpdir
      )
    ))
  }, "does not exist")
})
