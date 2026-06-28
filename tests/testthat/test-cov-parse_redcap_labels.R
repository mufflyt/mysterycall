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

test_that("parse_redcap_labels: happy path with unnamed vector", {
  raw <- c(
    "1, Yes | 2, No | 3, Prefer not to answer"
  )
  result <- suppressMessages(
    mysterycall_parse_redcap_labels(raw)
  )

  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(result), 3L)
  expect_equal(ncol(result), 3L)
  expect_equal(names(result), c("field", "code", "label"))
  expect_equal(result$field, rep("field_1", 3L))
  expect_equal(result$code, c("1", "2", "3"))
  expect_equal(result$label, c("Yes", "No", "Prefer not to answer"))
})

test_that("parse_redcap_labels: happy path with named vector", {
  raw <- c(
    scenario = "1, Straight couple | 2, Lesbian couple | 3, Single woman",
    accepted = "0, No | 1, Yes | 99, Unknown"
  )
  result <- suppressMessages(
    mysterycall_parse_redcap_labels(raw)
  )

  expect_s3_class(result, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(result), 6L)
  expect_equal(result$field[1:3], rep("scenario", 3L))
  expect_equal(result$field[4:6], rep("accepted", 3L))
  expect_equal(result$code, c("1", "2", "3", "0", "1", "99"))
  expect_equal(result$label[1:3], c("Straight couple", "Lesbian couple", "Single woman"))
  expect_equal(result$label[4:6], c("No", "Yes", "Unknown"))
})

test_that("parse_redcap_labels: custom separators", {
  raw <- c(
    field_a = "A;Label A,Description|B;Label B,Description"
  )
  result <- suppressMessages(
    mysterycall_parse_redcap_labels(raw, sep_choice = "|", sep_code = ";")
  )

  expect_equal(nrow(result), 2L)
  expect_equal(result$code, c("A", "B"))
  expect_equal(result$label, c("Label A,Description", "Label B,Description"))
})

test_that("parse_redcap_labels: trim parameter controls whitespace", {
  raw_with_spaces <- c(
    field_x = "  1  ,  Yes  |  2  ,  No  "
  )

  # With trim = TRUE (default)
  result_trim <- suppressMessages(
    mysterycall_parse_redcap_labels(raw_with_spaces, trim = TRUE)
  )
  expect_equal(result_trim$code, c("1", "2"))
  expect_equal(result_trim$label, c("Yes", "No"))

  # With trim = FALSE
  result_no_trim <- suppressMessages(
    mysterycall_parse_redcap_labels(raw_with_spaces, trim = FALSE)
  )
  expect_equal(result_no_trim$code, c("  1  ", "  2  "))
  expect_equal(result_no_trim$label, c("  Yes  ", "  No  "))
})

test_that("parse_redcap_labels: edge case - NA and empty strings", {
  raw <- c(
    field_a = "1, Yes | 2, No",
    field_b = NA_character_,
    field_c = ""
  )
  result <- suppressMessages(
    mysterycall_parse_redcap_labels(raw)
  )

  # Only field_a contributes rows
  expect_equal(nrow(result), 2L)
  expect_equal(unique(result$field), "field_a")
  expect_equal(result$code, c("1", "2"))
})

test_that("parse_redcap_labels: edge case - code without label", {
  raw <- c(
    field_bad = "1, Label | 2 | 3, Label3"
  )
  result <- suppressMessages(
    mysterycall_parse_redcap_labels(raw)
  )

  expect_equal(nrow(result), 3L)
  expect_equal(result$code, c("1", "2", "3"))
  expect_equal(result$label, c("Label", NA_character_, "Label3"))
})

test_that("parse_redcap_labels: error on invalid labels input", {
  expect_error(
    mysterycall_parse_redcap_labels(123),
    "`labels` must be a non-empty character vector"
  )

  expect_error(
    mysterycall_parse_redcap_labels(character(0)),
    "`labels` must be a non-empty character vector"
  )

  expect_error(
    mysterycall_parse_redcap_labels(NULL),
    "`labels` must be a non-empty character vector"
  )
})

test_that("parse_redcap_labels: error on invalid sep_choice", {
  raw <- "1, Yes"

  expect_error(
    mysterycall_parse_redcap_labels(raw, sep_choice = 123),
    "`sep_choice` must be a single non-empty string"
  )

  expect_error(
    mysterycall_parse_redcap_labels(raw, sep_choice = ""),
    "`sep_choice` must be a single non-empty string"
  )

  expect_error(
    mysterycall_parse_redcap_labels(raw, sep_choice = c(" | ", "|")),
    "`sep_choice` must be a single non-empty string"
  )
})

test_that("parse_redcap_labels: error on invalid sep_code", {
  raw <- "1, Yes"

  expect_error(
    mysterycall_parse_redcap_labels(raw, sep_code = 999),
    "`sep_code` must be a single non-empty string"
  )

  expect_error(
    mysterycall_parse_redcap_labels(raw, sep_code = ""),
    "`sep_code` must be a single non-empty string"
  )

  expect_error(
    mysterycall_parse_redcap_labels(raw, sep_code = c(", ", ":")),
    "`sep_code` must be a single non-empty string"
  )
})

test_that("parse_redcap_labels: partial field names use defaults", {
  raw <- c(
    field_a = "1, A",
    "",
    field_c = "3, C"
  )
  result <- suppressMessages(
    mysterycall_parse_redcap_labels(raw)
  )

  # Unnamed element (index 2) should get field_2
  field_names <- sort(unique(result$field))
  expect_true("field_2" %in% field_names)
  expect_true("field_a" %in% field_names)
  expect_true("field_c" %in% field_names)
})

test_that("parse_redcap_labels: labels with commas in label text", {
  raw <- c(
    field_insurance = "1, Blue Cross, Blue Shield | 2, Aetna, Inc."
  )
  result <- suppressMessages(
    mysterycall_parse_redcap_labels(raw, sep_code = ", ")
  )

  # Should split on FIRST occurrence of sep_code
  expect_equal(nrow(result), 2L)
  expect_equal(result$code, c("1", "2"))
  expect_equal(result$label, c("Blue Cross, Blue Shield", "Aetna, Inc."))
})

test_that("parse_redcap_labels: return type is tibble", {
  raw <- c(scenario = "1, Yes | 2, No")
  result <- suppressMessages(
    mysterycall_parse_redcap_labels(raw)
  )

  expect_s3_class(result, "tbl_df")
  expect_true(inherits(result, "data.frame"))
})
