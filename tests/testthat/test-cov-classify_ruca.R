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

test_that("mysterycall_classify_ruca() classifies codes with default parameters", {
  codes <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
  result <- mysterycall_classify_ruca(codes)

  expect_type(result, "character")
  expect_length(result, 10L)
  expect_equal(result[1:3], c("Urban", "Urban", "Urban"))
  expect_equal(result[4:6], c("Suburban", "Suburban", "Suburban"))
  expect_equal(result[7:10], c("Rural", "Rural", "Rural", "Rural"))
})

test_that("mysterycall_classify_ruca() handles NA values correctly", {
  codes <- c(1, NA, 5, NA, 9)
  result <- mysterycall_classify_ruca(codes)

  expect_type(result, "character")
  expect_equal(result, c("Urban", "Unknown", "Suburban", "Unknown", "Rural"))
})

test_that("mysterycall_classify_ruca() returns ordered factor when as_factor=TRUE", {
  codes <- c(1, 5, 9, NA)
  result <- mysterycall_classify_ruca(codes, as_factor = TRUE)

  expect_s3_class(result, c("ordered", "factor"))
  expect_equal(levels(result), c("Urban", "Suburban", "Rural", "Unknown"))
  expect_equal(as.character(result), c("Urban", "Suburban", "Rural", "Unknown"))
})

test_that("mysterycall_classify_ruca() handles decimal RUCA codes", {
  codes <- c(1.5, 3.0, 3.1, 6.0, 6.1, 10.6)
  result <- mysterycall_classify_ruca(codes)

  expect_equal(result[1:2], c("Urban", "Urban"))
  expect_equal(result[3:4], c("Suburban", "Suburban"))
  expect_equal(result[5:6], c("Rural", "Rural"))
})

test_that("mysterycall_classify_ruca() respects custom thresholds", {
  codes <- c(1, 2, 3, 4, 5)
  result <- mysterycall_classify_ruca(codes, urban_max = 2, suburban_max = 4)

  expect_equal(result, c("Urban", "Urban", "Suburban", "Suburban", "Rural"))
})

test_that("mysterycall_classify_ruca() respects custom labels", {
  codes <- c(1, 4, 7)
  custom_labels <- c("City", "Town", "Country")
  result <- mysterycall_classify_ruca(codes, labels = custom_labels)

  expect_equal(result, c("City", "Town", "Country"))
})

test_that("mysterycall_classify_ruca() respects custom na_label", {
  codes <- c(1, NA, 7)
  result <- mysterycall_classify_ruca(codes, na_label = "Missing")

  expect_equal(result, c("Urban", "Missing", "Rural"))
})

test_that("mysterycall_classify_ruca() errors when ruca_code is not numeric", {
  expect_error(
    mysterycall_classify_ruca(c("1", "2", "3")),
    "ruca_code.*must be a numeric vector"
  )
})

test_that("mysterycall_classify_ruca() errors when urban_max is not a single number", {
  expect_error(
    mysterycall_classify_ruca(c(1, 2, 3), urban_max = c(2, 3)),
    "urban_max.*must be a single number"
  )
  expect_error(
    mysterycall_classify_ruca(c(1, 2, 3), urban_max = NA),
    "urban_max.*must be a single number"
  )
})

test_that("mysterycall_classify_ruca() errors when suburban_max is not a single number", {
  expect_error(
    mysterycall_classify_ruca(c(1, 2, 3), suburban_max = c(5, 6)),
    "suburban_max.*must be a single number"
  )
  expect_error(
    mysterycall_classify_ruca(c(1, 2, 3), suburban_max = NA),
    "suburban_max.*must be a single number"
  )
})

test_that("mysterycall_classify_ruca() errors when suburban_max <= urban_max", {
  expect_error(
    mysterycall_classify_ruca(c(1, 2, 3), urban_max = 5, suburban_max = 5),
    "suburban_max.*must be greater than.*urban_max"
  )
  expect_error(
    mysterycall_classify_ruca(c(1, 2, 3), urban_max = 6, suburban_max = 3),
    "suburban_max.*must be greater than.*urban_max"
  )
})

test_that("mysterycall_classify_ruca() errors when labels is not character of length 3", {
  expect_error(
    mysterycall_classify_ruca(c(1, 2, 3), labels = c("A", "B")),
    "labels.*must be a character vector of length 3"
  )
  expect_error(
    mysterycall_classify_ruca(c(1, 2, 3), labels = c(1, 2, 3)),
    "labels.*must be a character vector of length 3"
  )
})

test_that("mysterycall_classify_ruca() errors when na_label is not a single character", {
  expect_error(
    mysterycall_classify_ruca(c(1, 2, 3), na_label = c("A", "B")),
    "na_label.*must be a single character string"
  )
  expect_error(
    mysterycall_classify_ruca(c(1, 2, 3), na_label = 123),
    "na_label.*must be a single character string"
  )
})

test_that("mysterycall_classify_ruca() preserves vector length with all NA", {
  codes <- c(NA, NA, NA)
  result <- mysterycall_classify_ruca(codes)

  expect_length(result, 3L)
  expect_equal(result, c("Unknown", "Unknown", "Unknown"))
})

test_that("mysterycall_classify_ruca() factor maintains custom levels order", {
  codes <- c(7, 4, 1, NA)
  custom_labels <- c("A", "B", "C")
  result <- mysterycall_classify_ruca(
    codes,
    labels = custom_labels,
    na_label = "D",
    as_factor = TRUE
  )

  expect_equal(levels(result), c("A", "B", "C", "D"))
  expect_true(is.ordered(result))
})

test_that("mysterycall_classify_ruca() handles empty numeric vector", {
  codes <- numeric(0)
  result <- mysterycall_classify_ruca(codes)

  expect_type(result, "character")
  expect_length(result, 0L)
})

test_that("mysterycall_classify_ruca() handles boundary at exact thresholds", {
  codes <- c(3, 3.0001, 6, 6.0001)
  result <- mysterycall_classify_ruca(codes, urban_max = 3, suburban_max = 6)

  expect_equal(result[1], "Urban")
  expect_equal(result[2], "Suburban")
  expect_equal(result[3], "Suburban")
  expect_equal(result[4], "Rural")
})
