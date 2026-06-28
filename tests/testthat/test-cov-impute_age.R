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
# mysterycall_impute_age tests
# ============================================================================

test_that("mysterycall_impute_age returns integer vector of correct length", {
  result <- mysterycall_impute_age(c(1995, 1980, 2010))
  expect_type(result, "integer")
  expect_length(result, 3L)
})

test_that("mysterycall_impute_age computes age correctly with default parameters", {
  # 1995 -> age = (2026 - 1995) + 27 = 58
  result <- suppressMessages(mysterycall_impute_age(1995, ref_year = 2026L))
  expect_equal(result, 58L)

  # 1980 -> age = (2026 - 1980) + 27 = 73
  result <- suppressMessages(mysterycall_impute_age(1980, ref_year = 2026L))
  expect_equal(result, 73L)
})

test_that("mysterycall_impute_age vectorizes correctly", {
  result <- suppressMessages(mysterycall_impute_age(c(1995, 1980, 2010), ref_year = 2026L))
  expected <- c(58L, 73L, 43L)
  expect_equal(result, expected)
})

test_that("mysterycall_impute_age handles NA values correctly", {
  result <- suppressMessages(mysterycall_impute_age(c(1995, NA, 1980)))
  expect_true(is.na(result[2L]))
  expect_false(is.na(result[1L]))
  expect_false(is.na(result[3L]))
})

test_that("mysterycall_impute_age warns when ages fall outside min_age/max_age bounds", {
  # Age too low: 1995 with high ref_year -> age > 90
  expect_warning(
    mysterycall_impute_age(1920, ref_year = 2026L, max_age = 90),
    "imputed age.*outside"
  )

  # Age too low: 2020 with small offset -> age < 25
  expect_warning(
    mysterycall_impute_age(2020, ref_year = 2026L, min_age = 25),
    "imputed age.*outside"
  )
})

test_that("mysterycall_impute_age sets implausible ages to NA", {
  result <- suppressWarnings(
    mysterycall_impute_age(c(1920, 1995, 2020), ref_year = 2026L, min_age = 25, max_age = 90)
  )
  # 1920 -> age 133, too high -> NA
  # 1995 -> age 58, OK
  # 2020 -> age 13, too low -> NA
  expect_true(is.na(result[1L]))
  expect_false(is.na(result[2L]))
  expect_true(is.na(result[3L]))
})

test_that("mysterycall_impute_age respects custom age_offset", {
  result <- suppressMessages(mysterycall_impute_age(1995, ref_year = 2026L, age_offset = 25L))
  # age = (2026 - 1995) + 25 = 56
  expect_equal(result, 56L)
})

test_that("mysterycall_impute_age respects custom min_age and max_age", {
  result <- suppressWarnings(
    mysterycall_impute_age(c(1970, 1995, 2015), ref_year = 2026L, min_age = 20, max_age = 70)
  )
  # 1970 -> age 83, exceeds max_age=70 -> NA
  # 1995 -> age 58, OK
  # 2015 -> age 28, OK
  expect_true(is.na(result[1L]))
  expect_equal(result[2L], 58L)
  expect_equal(result[3L], 28L)
})

test_that("mysterycall_impute_age messages when graduation year exceeds ref_year", {
  expect_message(
    mysterycall_impute_age(2030, ref_year = 2026L),
    "graduation year.*exceed ref_year"
  )
})

test_that("mysterycall_impute_age rejects non-numeric grad_year", {
  expect_error(
    mysterycall_impute_age("1995"),
    "`grad_year` must be a numeric vector"
  )
  expect_error(
    mysterycall_impute_age(as.Date("1995-01-01")),
    "`grad_year` must be a numeric vector"
  )
})

test_that("mysterycall_impute_age rejects invalid ref_year", {
  expect_error(
    mysterycall_impute_age(1995, ref_year = "2026"),
    "`ref_year` must be a single year"
  )
  expect_error(
    mysterycall_impute_age(1995, ref_year = 1850),
    "`ref_year` must be a single year"
  )
  expect_error(
    mysterycall_impute_age(1995, ref_year = c(2025, 2026)),
    "`ref_year` must be a single year"
  )
  expect_error(
    mysterycall_impute_age(1995, ref_year = NA),
    "`ref_year` must be a single year"
  )
})

test_that("mysterycall_impute_age rejects invalid age_offset", {
  expect_error(
    mysterycall_impute_age(1995, age_offset = "27"),
    "`age_offset` must be a single non-negative number"
  )
  expect_error(
    mysterycall_impute_age(1995, age_offset = -1),
    "`age_offset` must be a single non-negative number"
  )
  expect_error(
    mysterycall_impute_age(1995, age_offset = NA),
    "`age_offset` must be a single non-negative number"
  )
})


# ============================================================================
# mysterycall_age_category tests
# ============================================================================

test_that("mysterycall_age_category returns character vector of correct length", {
  result <- mysterycall_age_category(c(28, 35, 47, 55))
  expect_type(result, "character")
  expect_length(result, 4L)
})

test_that("mysterycall_age_category assigns correct default categories", {
  ages <- c(28, 35, 47, 55, 63, 72)
  result <- mysterycall_age_category(ages)
  expected <- c("<30", "30-39", "40-49", "50-59", "60-69", "70+")
  expect_equal(result, expected)
})

test_that("mysterycall_age_category handles NA values with default label", {
  ages <- c(28, NA, 47, NA)
  result <- mysterycall_age_category(ages)
  expect_equal(result[1L], "<30")
  expect_equal(result[2L], "Unknown")
  expect_equal(result[3L], "40-49")
  expect_equal(result[4L], "Unknown")
})

test_that("mysterycall_age_category uses custom na_label", {
  ages <- c(28, NA, 47)
  result <- mysterycall_age_category(ages, na_label = "Missing")
  expect_equal(result[2L], "Missing")
})

test_that("mysterycall_age_category respects custom breaks", {
  ages <- c(25, 35, 50, 65)
  result <- mysterycall_age_category(ages, breaks = c(40, 60))
  # Default labels: "<40", "40-59", "60+"
  expected <- c("<40", "<40", "40-59", "60+")
  expect_equal(result, expected)
})

test_that("mysterycall_age_category respects custom labels", {
  ages <- c(28, 35, 47, 55)
  custom_labels <- c("Young", "Mid-Early", "Mid-Late", "Senior")
  result <- mysterycall_age_category(ages, breaks = c(35, 50), labels = custom_labels)
  expected <- c("Young", "Mid-Early", "Mid-Late", "Senior")
  expect_equal(result, expected)
})

test_that("mysterycall_age_category returns factor when as_factor=TRUE", {
  ages <- c(28, 35, 47)
  result <- mysterycall_age_category(ages, as_factor = TRUE)
  expect_s3_class(result, "factor")
  expect_true(is.ordered(result))
})

test_that("mysterycall_age_category factor has correct level order", {
  ages <- c(28, 35, 47, 55, 63, 72, NA)
  result <- mysterycall_age_category(ages, as_factor = TRUE)
  expected_levels <- c("<30", "30-39", "40-49", "50-59", "60-69", "70+", "Unknown")
  expect_equal(levels(result), expected_levels)
})

test_that("mysterycall_age_category handles boundary ages correctly", {
  # Age exactly at break point
  result <- mysterycall_age_category(c(30, 40, 50, 60, 70))
  expected <- c("30-39", "40-49", "50-59", "60-69", "70+")
  expect_equal(result, expected)
})

test_that("mysterycall_age_category handles single break value", {
  ages <- c(25, 35, 45)
  result <- mysterycall_age_category(ages, breaks = c(40))
  expected <- c("<40", "<40", "40+")
  expect_equal(result, expected)
})

test_that("mysterycall_age_category handles multiple breaks", {
  ages <- c(20, 30, 40, 50, 60, 70, 80)
  result <- mysterycall_age_category(ages, breaks = c(25, 35, 45, 55, 65, 75))
  expected <- c("<25", "25-34", "35-44", "45-54", "55-64", "65-74", "75+")
  expect_equal(result, expected)
})

test_that("mysterycall_age_category rejects non-numeric age", {
  expect_error(
    mysterycall_age_category("28"),
    "`age` must be a numeric vector"
  )
  expect_error(
    mysterycall_age_category(as.Date("1995-01-01")),
    "`age` must be a numeric vector"
  )
})

test_that("mysterycall_age_category rejects invalid breaks", {
  expect_error(
    mysterycall_age_category(c(28, 35), breaks = "30"),
    "`breaks` must be an increasing numeric vector"
  )
  expect_error(
    mysterycall_age_category(c(28, 35), breaks = c()),
    "`breaks` must be an increasing numeric vector"
  )
  expect_error(
    mysterycall_age_category(c(28, 35), breaks = c(30, NA)),
    "`breaks` must be an increasing numeric vector"
  )
  expect_error(
    mysterycall_age_category(c(28, 35), breaks = c(50, 40, 30)),
    "`breaks` must be an increasing numeric vector"
  )
})

test_that("mysterycall_age_category rejects invalid na_label", {
  expect_error(
    mysterycall_age_category(c(28, NA), na_label = 1),
    "`na_label` must be a single character string"
  )
  expect_error(
    mysterycall_age_category(c(28, NA), na_label = c("Unknown", "Missing")),
    "`na_label` must be a single character string"
  )
})

test_that("mysterycall_age_category rejects labels length mismatch", {
  expect_error(
    mysterycall_age_category(c(28, 35), breaks = c(30, 40), labels = c("A", "B")),
    "`labels` must be a character vector of length 3"
  )
  expect_error(
    mysterycall_age_category(c(28, 35), breaks = c(30), labels = c("A", "B", "C", "D")),
    "`labels` must be a character vector of length 2"
  )
})

test_that("mysterycall_age_category rejects non-character labels", {
  expect_error(
    mysterycall_age_category(c(28, 35), breaks = c(30), labels = c(1, 2, 3)),
    "`labels` must be a character vector"
  )
})
