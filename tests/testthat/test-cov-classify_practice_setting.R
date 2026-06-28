library(testthat)
library(mysterycall)

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

# -- Tests for mysterycall_classify_practice_setting ---------------------------

test_that("mysterycall_classify_practice_setting classifies academic centers correctly", {
  result <- mysterycall_classify_practice_setting(
    c("University of Colorado Medical Center", "Johns Hopkins Hospital")
  )
  expect_type(result, "character")
  expect_length(result, 2L)
  expect_equal(result, c("Academic", "Academic"))
})

test_that("mysterycall_classify_practice_setting classifies government facilities correctly", {
  result <- mysterycall_classify_practice_setting(
    c("VA Medical Center Denver", "Walter Reed Army Hospital", "Indian Health Service Clinic")
  )
  expect_length(result, 3L)
  expect_equal(result, c("Government", "Government", "Government"))
})

test_that("mysterycall_classify_practice_setting classifies private practices correctly", {
  result <- mysterycall_classify_practice_setting(
    c("Denver ENT Associates LLC", "Smith MD Associates", "Private Practice Group")
  )
  expect_length(result, 3L)
  expect_equal(result, c("Private Practice", "Private Practice", "Private Practice"))
})

test_that("mysterycall_classify_practice_setting handles NA and empty values", {
  result <- mysterycall_classify_practice_setting(
    c(NA, "", "  ", "Harvard Medical School")
  )
  expect_length(result, 4L)
  expect_equal(result[1:3], c("Unknown", "Unknown", "Unknown"))
  expect_equal(result[4], "Academic")
})

test_that("mysterycall_classify_practice_setting respects na_label parameter", {
  result <- mysterycall_classify_practice_setting(
    c(NA, ""),
    na_label = "Missing"
  )
  expect_equal(result, c("Missing", "Missing"))
})

test_that("mysterycall_classify_practice_setting respects custom academic patterns", {
  custom_patterns <- c(mysterycall_academic_patterns(), "regional center")
  result <- mysterycall_classify_practice_setting(
    c("Regional Center Hospital", "Generic Clinic"),
    academic_patterns = custom_patterns
  )
  expect_equal(result[1], "Academic")
  expect_equal(result[2], "Private Practice")
})

test_that("mysterycall_classify_practice_setting respects custom government patterns", {
  custom_patterns <- c(mysterycall_government_patterns(), "county clinic")
  result <- mysterycall_classify_practice_setting(
    c("County Clinic", "Private Facility"),
    government_patterns = custom_patterns
  )
  expect_equal(result[1], "Government")
  expect_equal(result[2], "Private Practice")
})

test_that("mysterycall_classify_practice_setting prioritizes government over academic", {
  # VA Medical Center contains "Medical Center" which is academic, but should classify as Government
  result <- mysterycall_classify_practice_setting(
    "VA Medical Center Denver"
  )
  expect_equal(result, "Government")
})

test_that("mysterycall_classify_practice_setting is case-insensitive", {
  result <- mysterycall_classify_practice_setting(
    c("UNIVERSITY OF COLORADO", "va hospital", "ENT Associates")
  )
  expect_equal(result, c("Academic", "Government", "Private Practice"))
})

test_that("mysterycall_classify_practice_setting handles whitespace correctly", {
  result <- mysterycall_classify_practice_setting(
    c("  Harvard Medical School  ", "\tMayo Clinic\n")
  )
  expect_equal(result, c("Academic", "Academic"))
})

test_that("mysterycall_classify_practice_setting errors on non-character facility_name", {
  expect_error(
    mysterycall_classify_practice_setting(c(123, 456)),
    "`facility_name` must be a character vector."
  )
})

test_that("mysterycall_classify_practice_setting errors on invalid na_label", {
  expect_error(
    mysterycall_classify_practice_setting("Test", na_label = c("A", "B")),
    "`na_label` must be a single character string."
  )
  expect_error(
    mysterycall_classify_practice_setting("Test", na_label = 123),
    "`na_label` must be a single character string."
  )
})

test_that("mysterycall_classify_practice_setting handles regex patterns correctly", {
  # Test that built-in patterns include regex like \\b and \\bpc\\b work
  result <- mysterycall_classify_practice_setting(
    c("Smith PC", "Smith PC Associates")
  )
  expect_equal(result[1], "Private Practice")
  expect_equal(result[2], "Private Practice")
})

test_that("mysterycall_classify_practice_setting returns Private Practice for unmatched non-empty strings", {
  result <- mysterycall_classify_practice_setting(
    c("Random Clinic Name", "XYZ Healthcare")
  )
  expect_equal(result, c("Private Practice", "Private Practice"))
})

# -- Tests for mysterycall_academic_patterns ------------------------------------

test_that("mysterycall_academic_patterns returns built-in patterns", {
  result <- mysterycall_academic_patterns()
  expect_type(result, "character")
  expect_length(result, 46L)
  expect_true("university" %in% result)
  expect_true("medical center" %in% result)
  expect_true("mayo clinic" %in% result)
})

test_that("mysterycall_academic_patterns result can be extended", {
  patterns <- c(mysterycall_academic_patterns(), "my custom term")
  expect_length(patterns, 47L)
  expect_equal(patterns[47], "my custom term")
})

test_that("mysterycall_academic_patterns is a character vector", {
  result <- mysterycall_academic_patterns()
  expect_type(result, "character")
  expect_true(is.vector(result))
})

# -- Tests for mysterycall_government_patterns ----------------------------------

test_that("mysterycall_government_patterns returns built-in patterns", {
  result <- mysterycall_government_patterns()
  expect_type(result, "character")
  expect_true(length(result) > 0L)
  expect_true("va " %in% result)
  expect_true("veterans" %in% result)
  expect_true("military" %in% result)
})

test_that("mysterycall_government_patterns result can be extended", {
  patterns <- c(mysterycall_government_patterns(), "state health")
  expect_true(length(patterns) > length(mysterycall_government_patterns()))
  expect_equal(patterns[length(patterns)], "state health")
})

test_that("mysterycall_government_patterns is a character vector", {
  result <- mysterycall_government_patterns()
  expect_type(result, "character")
  expect_true(is.vector(result))
})

# -- Integration tests --------------------------------------------------------

test_that("mysterycall_classify_practice_setting works with extended patterns from accessors", {
  academic_ext <- c(mysterycall_academic_patterns(), "private university")
  government_ext <- c(mysterycall_government_patterns(), "state facility")

  result <- mysterycall_classify_practice_setting(
    c("Private University Hospital", "State Facility Center", "Random Clinic"),
    academic_patterns = academic_ext,
    government_patterns = government_ext
  )
  expect_equal(result[1], "Academic")
  expect_equal(result[2], "Government")
  expect_equal(result[3], "Private Practice")
})

test_that("mysterycall_classify_practice_setting handles large vectors", {
  names <- rep(
    c("Harvard Medical School", "VA Hospital", "Private Practice Group"),
    100
  )
  result <- mysterycall_classify_practice_setting(names)
  expect_length(result, 300L)
  expect_equal(sum(result == "Academic"), 100L)
  expect_equal(sum(result == "Government"), 100L)
  expect_equal(sum(result == "Private Practice"), 100L)
})

test_that("mysterycall_classify_practice_setting preserves vector order", {
  names <- c("VA Hospital", "Harvard", "Private", "Mayo Clinic", NA, "ENT")
  result <- mysterycall_classify_practice_setting(names)
  expect_equal(
    result,
    c("Government", "Academic", "Private Practice", "Academic", "Unknown", "Private Practice")
  )
})
