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

# Test mysterycall_normalize_address_df

test_that("normalize_address_df: happy path with default column names", {
  df <- data.frame(
    practice_address1 = c("123 North Main Street Suite 100", "456 Oak Avenue"),
    practice_address2 = c(NA, "Apartment 4B"),
    practice_city     = c("Denver", "Los Angeles"),
    practice_state    = c("Colorado", "CA"),
    practice_zip      = c("80111-1234", "90210"),
    stringsAsFactors  = FALSE
  )

  result <- suppressMessages(mysterycall_normalize_address_df(df))

  # Check return type
  expect_s3_class(result, "data.frame")

  # Check new columns exist
  expect_true("address1_norm" %in% names(result))
  expect_true("address2_norm" %in% names(result))
  expect_true("address1_no_unit" %in% names(result))
  expect_true("is_po_box" %in% names(result))
  expect_true("has_num" %in% names(result))

  # Check data types
  expect_type(result$address1_norm, "character")
  expect_type(result$is_po_box, "logical")
  expect_type(result$has_num, "logical")

  # Check normalization occurred
  expect_true(grepl("N MAIN", result$address1_norm[1]))
  expect_true(grepl("STE 100", result$address1_norm[1]))
  expect_true(result$has_num[1])
})

test_that("normalize_address_df: edge case with NA values and missing addr2", {
  df <- data.frame(
    practice_address1 = c("123 Main St", NA_character_, "456 Oak Ave"),
    practice_city     = c("Denver", "Boulder", NA_character_),
    practice_state    = c("Colorado", "CO", "CA"),
    practice_zip      = c("80111", NA_character_, "90210"),
    stringsAsFactors  = FALSE
  )

  result <- suppressMessages(mysterycall_normalize_address_df(df))

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)

  # Check NAs are preserved/created
  expect_true(is.na(result$address1_norm[2]))
  expect_true(is.na(result$practice_zip[2]))
  expect_true(is.na(result$practice_city[3]))
})

test_that("normalize_address_df: error on missing required columns", {
  df <- data.frame(
    practice_address1 = c("123 Main St"),
    practice_city     = c("Denver"),
    # Missing practice_state and practice_zip
    stringsAsFactors  = FALSE
  )

  expect_error(
    mysterycall_normalize_address_df(df),
    "Missing columns"
  )
})

test_that("normalize_address_df: custom column names", {
  df <- data.frame(
    street1   = c("123 North Main Street"),
    street2   = c(NA_character_),
    city      = c("Denver"),
    state     = c("Colorado"),
    zip       = c("80111-1234"),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_normalize_address_df(
      df,
      addr1_col = "street1",
      addr2_col = "street2",
      city_col  = "city",
      state_col = "state",
      zip_col   = "zip"
    )
  )

  expect_s3_class(result, "data.frame")
  expect_true("address1_norm" %in% names(result))
  expect_true(grepl("N MAIN", result$address1_norm[1]))
})

test_that("normalize_address_df: various address components normalized", {
  df <- data.frame(
    practice_address1 = c(
      "123 southeast oak boulevard suite 200",
      "456 WEST MAIN ROAD APT 5",
      "789 North Central Court"
    ),
    practice_address2 = c(NA_character_, NA_character_, "UNIT 300"),
    practice_city     = c("denver", "BOULDER", "FortCollins"),
    practice_state    = c("COLORADO", "Colorado", "CO"),
    practice_zip      = c("80111-1234", "80301", "80525"),
    stringsAsFactors  = FALSE
  )

  result <- suppressMessages(mysterycall_normalize_address_df(df))

  # Verify normalization occurred
  # Directionals: southeast -> SE, west -> W, north -> N
  expect_true(grepl("SE", result$address1_norm[1]))
  expect_true(grepl("BLVD", result$address1_norm[1]))
  expect_true(grepl("STE 200", result$address1_norm[1]))

  # Street suffix: ROAD -> RD
  expect_true(grepl("RD", result$address1_norm[2]))

  # State normalization
  expect_equal(result$practice_state[1], "CO")
  expect_equal(result$practice_state[2], "CO")
  expect_equal(result$practice_state[3], "CO")

  # ZIP extraction (5 digits only)
  expect_equal(result$practice_zip[1], "80111")
})
