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

test_that("mysterycall_validate_phone returns correct structure", {
  result <- mysterycall_validate_phone(
    c("(303) 555-1212", "2125551234"),
    practice_state = c("CO", "NY")
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2L)
  expect_named(result, c(
    "phone_e164_valid",
    "phone_npa",
    "phone_state_from_npa",
    "phone_area_code_matches_state",
    "phone_validity_flag"
  ))

  expect_type(result$phone_e164_valid, "logical")
  expect_type(result$phone_npa, "character")
  expect_type(result$phone_state_from_npa, "character")
  expect_type(result$phone_area_code_matches_state, "logical")
  expect_type(result$phone_validity_flag, "character")

  # Happy path: both numbers should be valid
  expect_equal(result$phone_e164_valid, c(TRUE, TRUE))
  expect_equal(result$phone_validity_flag, c("valid", "valid"))
})

test_that("NA and missing phone strings are flagged as missing", {
  result <- mysterycall_validate_phone(
    c(NA, "", "  ", "(303) 555-1212"),
    practice_state = "CO"
  )

  expect_equal(result$phone_validity_flag[1:3], c("missing", "missing", "missing"))
  expect_equal(result$phone_e164_valid[1:3], c(FALSE, FALSE, FALSE))
  expect_equal(result$phone_validity_flag[4], "valid")
  expect_true(result$phone_e164_valid[4])
})

test_that("Invalid phone formats return invalid_format flag", {
  result <- mysterycall_validate_phone(
    c("555-1212", "000-555-1212", "2135111234", "12345"),
    practice_state = NULL
  )

  # All should be invalid_format
  expect_true(all(result$phone_validity_flag == "invalid_format"))
  expect_true(all(!result$phone_e164_valid))
})

test_that("Area code state mismatch is detected correctly", {
  result <- mysterycall_validate_phone(
    "(303) 555-1212",
    practice_state = "NY"
  )

  expect_equal(result$phone_validity_flag, "area_code_state_mismatch")
  expect_false(result$phone_area_code_matches_state)
  expect_false(result$phone_e164_valid)
})

test_that("Invalid input types raise appropriate errors", {
  expect_error(
    mysterycall_validate_phone(123, practice_state = "CO"),
    "phone_str"
  )

  expect_error(
    mysterycall_validate_phone("(303) 555-1212", practice_state = 123),
    "practice_state"
  )

  expect_error(
    mysterycall_validate_phone(
      c("(303) 555-1212", "2125551234"),
      practice_state = c("CO", "NY", "CA")
    ),
    "practice_state"
  )
})

test_that("practice_state = NULL skips state matching", {
  result <- mysterycall_validate_phone(
    c("(303) 555-1212", "2125551234"),
    practice_state = NULL
  )

  expect_true(all(is.na(result$phone_area_code_matches_state)))
  expect_equal(result$phone_npa, c("303", "212"))
  expect_equal(result$phone_validity_flag, c("valid", "valid"))
})

test_that("Country code prefix (leading 1) is stripped correctly", {
  result <- mysterycall_validate_phone(
    c("13035551212", "2125551234"),
    practice_state = c("CO", "NY")
  )

  expect_equal(result$phone_npa, c("303", "212"))
  expect_equal(result$phone_validity_flag, c("valid", "valid"))
  expect_equal(result$phone_e164_valid, c(TRUE, TRUE))
})

test_that("practice_state length 1 is recycled to match phone_str length", {
  result <- mysterycall_validate_phone(
    c("(303) 555-1212", "2125551213", "(303) 555-1214"),
    practice_state = "CO"
  )

  expect_equal(nrow(result), 3L)
  # First and third should match CO, second should not
  expect_equal(result$phone_area_code_matches_state[c(1, 3)], c(TRUE, TRUE))
  expect_false(result$phone_area_code_matches_state[2])
})

test_that("Various phone formats are parsed correctly", {
  result <- mysterycall_validate_phone(
    c(
      "(303) 555-1212",      # formatted with parens
      "303-555-1212",        # formatted with dashes
      "3035551212",          # bare digits
      "303 555 1212"         # formatted with spaces
    ),
    practice_state = "CO"
  )

  expect_equal(result$phone_npa, rep("303", 4L))
  expect_equal(result$phone_validity_flag, rep("valid", 4L))
  expect_equal(result$phone_e164_valid, rep(TRUE, 4L))
})
