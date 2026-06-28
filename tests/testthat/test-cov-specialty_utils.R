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

# Tests for mysterycall_parse_certification_subspecialty

test_that("happy path: valid cert strings with matching patterns", {
  cert <- c(
    "Otolaryngology - Head & Neck Surgery + Neurotology",
    "Otolaryngology + Pediatric Otolaryngology + Sleep Medicine",
    "Otolaryngology - Head & Neck Surgery",
    "Facial Plastic Surgery + Something Else"
  )
  result <- mysterycall_parse_certification_subspecialty(cert)

  expect_type(result, "character")
  expect_length(result, 4L)
  expect_equal(result[[1L]], "Otology/Neurotology")
  expect_equal(result[[2L]], "Pediatric Otolaryngology")
  expect_equal(result[[3L]], NA_character_)
  expect_equal(result[[4L]], "Facial Plastic Surgery")
})

test_that("edge case: NA and empty/blank strings return default", {
  cert <- c(NA_character_, "", "   ", NA)
  result <- mysterycall_parse_certification_subspecialty(cert)

  expect_type(result, "character")
  expect_length(result, 4L)
  expect_true(all(is.na(result)))
})

test_that("edge case: no pattern match returns default", {
  # Use inputs that don't match any ENT/ORL subspecialty pattern
  cert <- c("General Surgery", "Internal Medicine", "Oncology")
  result <- mysterycall_parse_certification_subspecialty(cert)

  expect_type(result, "character")
  expect_length(result, 3L)
  expect_true(all(is.na(result)))
})

test_that("parameter: custom default value when no pattern matches", {
  cert <- c("Unrelated Specialty", NA, "")
  result <- mysterycall_parse_certification_subspecialty(cert, default = "General ORL")

  expect_equal(result[[1L]], "General ORL")
  expect_equal(result[[2L]], "General ORL")
  expect_equal(result[[3L]], "General ORL")
})

test_that("case insensitivity: patterns match regardless of case", {
  cert <- c(
    "NEUROTOLOGY",
    "sleep medicine",
    "Facial Plastic Surgery",
    "PEDIATRIC Otolaryngology"
  )
  result <- mysterycall_parse_certification_subspecialty(cert)

  expect_equal(result[[1L]], "Otology/Neurotology")
  expect_equal(result[[2L]], "Sleep Medicine")
  expect_equal(result[[3L]], "Facial Plastic Surgery")
  expect_equal(result[[4L]], "Pediatric Otolaryngology")
})

test_that("priority ordering: Neurotology > Pediatric > Sleep > Facial", {
  # Neurotology takes priority over all others
  result1 <- mysterycall_parse_certification_subspecialty(
    "Neurotology + Pediatric + Sleep + Facial Plastic"
  )
  expect_equal(result1, "Otology/Neurotology")

  # Pediatric takes priority over Sleep and Facial (no Neurotology)
  result2 <- mysterycall_parse_certification_subspecialty(
    "Pediatric Otolaryngology + Sleep Medicine + Facial Plastic"
  )
  expect_equal(result2, "Pediatric Otolaryngology")

  # Sleep takes priority over Facial (no Neurotology or Pediatric)
  result3 <- mysterycall_parse_certification_subspecialty(
    "Sleep Medicine + Facial Plastic Surgery"
  )
  expect_equal(result3, "Sleep Medicine")
})

test_that("bad input: non-character input is coerced", {
  # Numeric input should be coerced to character
  cert <- c(123, NA_real_, 456)
  result <- mysterycall_parse_certification_subspecialty(cert)

  expect_type(result, "character")
  expect_length(result, 3L)
})

test_that("bad input: missing required cert_type argument raises error", {
  expect_error(
    mysterycall_parse_certification_subspecialty()
  )
})
