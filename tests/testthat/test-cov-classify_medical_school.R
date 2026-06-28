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

# ---- Test mysterycall_classify_medical_school ----

test_that("classify_medical_school: happy path - correctly classifies US_MD, US_DO, CAN_MD, IMG", {
  schools <- c(
    "University of Colorado School of Medicine",           # US_MD (default)
    "Philadelphia College of Osteopathic Medicine",        # US_DO (pcom pattern)
    "McGill University Faculty of Medicine",               # CAN_MD (mcgill pattern)
    "Ross University School of Medicine"                   # IMG (ross university pattern)
  )
  result <- suppressMessages(mysterycall_classify_medical_school(schools))

  expect_type(result, "character")
  expect_length(result, 4L)
  expect_equal(result[1], "US_MD")
  expect_equal(result[2], "US_DO")
  expect_equal(result[3], "CAN_MD")
  expect_equal(result[4], "IMG")
})

test_that("classify_medical_school: edge case - NA and empty string inputs default to 'Unknown'", {
  schools <- c(NA, "", "   ", "University of Michigan")
  result <- suppressMessages(mysterycall_classify_medical_school(schools))

  expect_type(result, "character")
  expect_length(result, 4L)
  expect_equal(result[1], "Unknown")
  expect_equal(result[2], "Unknown")
  expect_equal(result[3], "Unknown")
  expect_equal(result[4], "US_MD")
})

test_that("classify_medical_school: case insensitivity - patterns match regardless of case", {
  schools <- c(
    "PHILADELPHIA COLLEGE OF OSTEOPATHIC MEDICINE",
    "mcgill university faculty of medicine",
    "ROSS UNIVERSITY school of medicine"
  )
  result <- suppressMessages(mysterycall_classify_medical_school(schools))

  expect_equal(result[1], "US_DO")
  expect_equal(result[2], "CAN_MD")
  expect_equal(result[3], "IMG")
})

test_that("classify_medical_school: custom na_label - respects custom NA label", {
  schools <- c(NA, "", "University of Texas")
  result <- suppressMessages(mysterycall_classify_medical_school(schools, na_label = "Missing"))

  expect_equal(result[1], "Missing")
  expect_equal(result[2], "Missing")
  expect_equal(result[3], "US_MD")
})

test_that("classify_medical_school: bad input - rejects non-character school_name", {
  expect_error(
    mysterycall_classify_medical_school(c(123, 456)),
    "`school_name` must be a character vector"
  )
})

test_that("classify_medical_school: bad input - rejects invalid na_label", {
  expect_error(
    mysterycall_classify_medical_school(c("School A"), na_label = 123),
    "`na_label` must be a single character string"
  )

  expect_error(
    mysterycall_classify_medical_school(c("School A"), na_label = c("A", "B")),
    "`na_label` must be a single character string"
  )
})

test_that("classify_medical_school: DO pattern specificity - matches osteopathic patterns correctly", {
  schools <- c(
    "Touro University College of Osteopathic Medicine",
    "Western Virginia School of Osteopathic Medicine",
    "Lake Erie College of Osteopathic Medicine"
  )
  result <- suppressMessages(mysterycall_classify_medical_school(schools))

  expect_true(all(result == "US_DO"))
})

test_that("classify_medical_school: CAN_MD pattern specificity - matches Canadian schools correctly", {
  schools <- c(
    "University of Toronto Faculty of Medicine",
    "University of British Columbia Faculty of Medicine",
    "Dalhousie University Faculty of Medicine"
  )
  result <- suppressMessages(mysterycall_classify_medical_school(schools))

  expect_true(all(result == "CAN_MD"))
})

test_that("classify_medical_school: IMG pattern specificity - matches international indicators correctly", {
  schools <- c(
    "St. George University School of Medicine",
    "American University of the Caribbean School of Medicine",
    "Universidad Nacional de Mexico"
  )
  result <- suppressMessages(mysterycall_classify_medical_school(schools))

  expect_true(all(result == "IMG"))
})

test_that("classify_medical_school: priority order - DO takes precedence over other patterns", {
  # If a school somehow matched both DO and CAN patterns, DO should win
  # Touro is a US_DO school but test that it's classified as DO even if other patterns might apply
  schools <- c("Touro University")
  result <- suppressMessages(mysterycall_classify_medical_school(schools))

  expect_equal(result, "US_DO")
})

test_that("classify_medical_school: return type and length - always returns character vector of same length", {
  schools <- c("Harvard Medical School", "Oxford University", NA, "")
  result <- suppressMessages(mysterycall_classify_medical_school(schools))

  expect_type(result, "character")
  expect_length(result, length(schools))
  expect_true(all(!is.na(result)))  # result should never contain NA
})
