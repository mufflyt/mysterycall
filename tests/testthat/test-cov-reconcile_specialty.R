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

# Test 1: Happy path with primary only
test_that("mysterycall_reconcile_specialty handles primary column only (Tier 1)", {
  df <- data.frame(
    specialty_npi = c("Cardiology", "General", NA, "Neurology"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_reconcile_specialty(
      df,
      primary_col = "specialty_npi"
    )
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 4L)
  expect_named(result, c("specialty_npi", "specialty_source", "specialty_confidence"))
  expect_equal(result$specialty_npi[1], "Cardiology")
  expect_equal(result$specialty_npi[2], "General")
  expect_equal(result$specialty_source[1], "specialty_npi")
  expect_equal(result$specialty_confidence[1], "high")
  expect_equal(result$specialty_source[2], "default")
  expect_equal(result$specialty_confidence[2], "low")
})

# Test 2: Three-tier resolution with secondary column (happy path)
test_that("mysterycall_reconcile_specialty applies three-tier logic correctly", {
  df <- data.frame(
    specialty_npi   = c("Otolaryngology", "General", NA, NA),
    specialty_abohns = c(NA, "Laryngology", "Rhinology", NA),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_reconcile_specialty(
      df,
      primary_col   = "specialty_npi",
      secondary_col = "specialty_abohns"
    )
  )

  # Tier 1: primary is informative
  expect_equal(result$specialty_npi[1], "Otolaryngology")
  expect_equal(result$specialty_source[1], "specialty_npi")
  expect_equal(result$specialty_confidence[1], "high")

  # Tier 2: primary is default, secondary fills in
  expect_equal(result$specialty_npi[2], "Laryngology")
  expect_equal(result$specialty_source[2], "specialty_abohns")
  expect_equal(result$specialty_confidence[2], "medium")

  # Tier 3: both missing/default
  expect_equal(result$specialty_npi[4], "General")
  expect_equal(result$specialty_source[4], "default")
  expect_equal(result$specialty_confidence[4], "low")
})

# Test 3: Edge cases with NA, whitespace, and empty strings
test_that("mysterycall_reconcile_specialty handles NA, whitespace, empty strings", {
  df <- data.frame(
    specialty_npi   = c("  ", NA, "", "Dermatology"),
    specialty_abohns = c("Pediatrics", NA, "Mohs Surgery", NA),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_reconcile_specialty(
      df,
      primary_col   = "specialty_npi",
      secondary_col = "specialty_abohns"
    )
  )

  # Whitespace treated as uninformative
  expect_equal(result$specialty_source[1], "specialty_abohns")
  expect_equal(result$specialty_confidence[1], "medium")
  expect_equal(result$specialty_npi[1], "Pediatrics")

  # NA in both → default
  expect_equal(result$specialty_source[2], "default")
  expect_equal(result$specialty_confidence[2], "low")
  expect_equal(result$specialty_npi[2], "General")

  # Empty string in primary, secondary has value
  expect_equal(result$specialty_source[3], "specialty_abohns")
  expect_equal(result$specialty_npi[3], "Mohs Surgery")
})

# Test 4: Custom default label
test_that("mysterycall_reconcile_specialty respects custom default label", {
  df <- data.frame(
    specialty_npi = c("Orthopedics", "Unknown", NA),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_reconcile_specialty(
      df,
      primary_col = "specialty_npi",
      default = "Unknown"
    )
  )

  # "Unknown" is now treated as default
  expect_equal(result$specialty_source[2], "default")
  expect_equal(result$specialty_confidence[2], "low")
  expect_equal(result$specialty_npi[1], "Orthopedics")
  expect_equal(result$specialty_confidence[1], "high")
})

# Test 5: Custom column names for audit columns
test_that("mysterycall_reconcile_specialty uses custom audit column names", {
  df <- data.frame(
    spec = c("Psychiatry", "General", NA),
    spec_cert = c(NA, "Child Psychiatry", "Adult Psychiatry"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_reconcile_specialty(
      df,
      primary_col = "spec",
      secondary_col = "spec_cert",
      source_col = "my_source",
      confidence_col = "my_confidence"
    )
  )

  expect_named(result, c("spec", "spec_cert", "my_source", "my_confidence"))
  expect_equal(result$my_source[1], "spec")
  expect_equal(result$my_confidence[2], "medium")
  expect_equal(result$spec[2], "Child Psychiatry")
})

# Test 6: Error on non-data-frame input
test_that("mysterycall_reconcile_specialty rejects non-data-frame input", {
  expect_error(
    mysterycall_reconcile_specialty(
      list(a = 1, b = 2),
      primary_col = "a"
    ),
    "`data` must be a data frame"
  )
})

# Test 7: Error on missing primary_col
test_that("mysterycall_reconcile_specialty errors when primary_col not in data", {
  df <- data.frame(specialty = c("A", "B"), stringsAsFactors = FALSE)

  expect_error(
    mysterycall_reconcile_specialty(
      df,
      primary_col = "nonexistent"
    ),
    "`primary_col` not found in data"
  )
})

# Test 8: Error on missing secondary_col when specified
test_that("mysterycall_reconcile_specialty errors when secondary_col not in data", {
  df <- data.frame(specialty = c("A", "B"), stringsAsFactors = FALSE)

  expect_error(
    mysterycall_reconcile_specialty(
      df,
      primary_col = "specialty",
      secondary_col = "missing_col"
    ),
    "`secondary_col` not found in data"
  )
})

# Test 9: Single row data frame
test_that("mysterycall_reconcile_specialty works with single row", {
  df <- data.frame(
    specialty = c("Pediatrics"),
    cert = c(NA),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_reconcile_specialty(
      df,
      primary_col = "specialty",
      secondary_col = "cert"
    )
  )

  expect_equal(nrow(result), 1L)
  expect_equal(result$specialty, "Pediatrics")
  expect_equal(result$specialty_source, "specialty")
  expect_equal(result$specialty_confidence, "high")
})

# Test 10: Audit columns are character type
test_that("mysterycall_reconcile_specialty audit columns are character", {
  df <- data.frame(
    spec = c("Surgery", "General"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_reconcile_specialty(
      df,
      primary_col = "spec"
    )
  )

  expect_type(result$specialty_source, "character")
  expect_type(result$specialty_confidence, "character")
})
