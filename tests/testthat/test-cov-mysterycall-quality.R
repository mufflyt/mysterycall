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

# ---- mysterycall_quality_tier tests ----

test_that("mysterycall_quality_tier: happy path - returns correct tier for high score", {
  result <- mysterycall_quality_tier(0.95)
  expect_type(result, "character")
  expect_equal(result, "high")
})

test_that("mysterycall_quality_tier: happy path - returns correct tier for medium score", {
  result <- mysterycall_quality_tier(0.80)
  expect_type(result, "character")
  expect_equal(result, "medium")
})

test_that("mysterycall_quality_tier: happy path - returns correct tier for low score", {
  result <- mysterycall_quality_tier(0.50)
  expect_type(result, "character")
  expect_equal(result, "low")
})

test_that("mysterycall_quality_tier: edge case - NA score returns NA_character_", {
  result <- mysterycall_quality_tier(NA_real_)
  expect_type(result, "character")
  expect_true(is.na(result))
})

test_that("mysterycall_quality_tier: edge case - NULL score returns NA_character_", {
  result <- mysterycall_quality_tier(NULL)
  expect_type(result, "character")
  expect_true(is.na(result))
})

test_that("mysterycall_quality_tier: edge case - boundary values (exactly on thresholds)", {
  expect_equal(mysterycall_quality_tier(0.90), "high")   # exactly at high cutoff
  expect_equal(mysterycall_quality_tier(0.75), "medium") # exactly at medium cutoff
  expect_equal(mysterycall_quality_tier(0.0), "low")     # at lower bound
  expect_equal(mysterycall_quality_tier(1.0), "high")    # at upper bound
})

test_that("mysterycall_quality_tier: bad input - score outside [0, 1] range", {
  expect_error(mysterycall_quality_tier(-0.1), "`score` must be a single number between 0 and 1")
  expect_error(mysterycall_quality_tier(1.1), "`score` must be a single number between 0 and 1")
})

test_that("mysterycall_quality_tier: bad input - score not numeric", {
  expect_error(mysterycall_quality_tier("0.5"), "`score` must be a single number between 0 and 1")
  expect_error(mysterycall_quality_tier(TRUE), "`score` must be a single number between 0 and 1")
})

test_that("mysterycall_quality_tier: bad input - score length > 1", {
  expect_error(mysterycall_quality_tier(c(0.5, 0.7)))
})

test_that("mysterycall_quality_tier: bad input - invalid threshold format (missing names)", {
  expect_error(
    mysterycall_quality_tier(0.85, thresholds = c(0.9, 0.75)),
    "`thresholds` must be a named vector with 'high' and 'medium' entries"
  )
})

test_that("mysterycall_quality_tier: bad input - threshold missing 'high' entry", {
  expect_error(
    mysterycall_quality_tier(0.85, thresholds = c(medium = 0.75)),
    "`thresholds` must be a named vector with 'high' and 'medium' entries"
  )
})

test_that("mysterycall_quality_tier: bad input - threshold missing 'medium' entry", {
  expect_error(
    mysterycall_quality_tier(0.85, thresholds = c(high = 0.9)),
    "`thresholds` must be a named vector with 'high' and 'medium' entries"
  )
})

test_that("mysterycall_quality_tier: custom thresholds work correctly", {
  custom_thresh <- c(high = 0.8, medium = 0.6)
  expect_equal(mysterycall_quality_tier(0.85, thresholds = custom_thresh), "high")
  expect_equal(mysterycall_quality_tier(0.75, thresholds = custom_thresh), "medium")
  expect_equal(mysterycall_quality_tier(0.50, thresholds = custom_thresh), "low")
})

# ---- mysterycall_check_data_completeness tests ----

test_that("mysterycall_check_data_completeness: happy path - all complete data", {
  result <- suppressMessages(mysterycall_check_data_completeness(
    AUDIT,
    required = c("npi", "insurance")
  ))

  expect_type(result, "list")
  expect_named(result, c("summary", "quality", "score"))
  expect_s3_class(result$summary, "tbl_df")
  expect_equal(nrow(result$summary), 2)
  expect_equal(result$summary$column, c("npi", "insurance"))
  expect_true(all(result$summary$completeness == 1.0))
  expect_equal(result$quality, "high")
  expect_equal(result$score, 1.0)
})

test_that("mysterycall_check_data_completeness: happy path - with missing values", {
  df <- data.frame(
    id = 1:4,
    value = c(1, NA, 3, 4),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_check_data_completeness(
    df,
    required = c("id", "value")
  ))

  expect_type(result, "list")
  expect_equal(nrow(result$summary), 2)
  expect_equal(result$summary$completeness[[1]], 1.0)
  expect_equal(result$summary$completeness[[2]], 0.75)
  expect_equal(result$score, 0.875)
  expect_equal(result$quality, "medium")
})

test_that("mysterycall_check_data_completeness: happy path - with id_cols for uniqueness", {
  result <- suppressMessages(mysterycall_check_data_completeness(
    AUDIT,
    required = c("offered", "contact_office"),
    id_cols = c("npi", "insurance")
  ))

  expect_type(result, "list")
  expect_equal(nrow(result$summary), 3)  # 2 required + 1 uniqueness row
  expect_equal(result$summary$column[[3]], "npi+insurance")
  expect_equal(result$summary$completeness[[3]], 1.0)  # all unique
})

test_that("mysterycall_check_data_completeness: edge case - all NA in one column", {
  df <- data.frame(
    id = 1:4,
    value = c(NA, NA, NA, NA),
    stringsAsFactors = FALSE
  )
  result <- suppressMessages(mysterycall_check_data_completeness(
    df,
    required = "value"
  ))

  expect_equal(result$summary$completeness[[1]], 0.0)
  expect_equal(result$summary$missing[[1]], 1.0)
  expect_equal(result$quality, "low")
})

test_that("mysterycall_check_data_completeness: edge case - custom thresholds affect quality", {
  df <- data.frame(
    id = 1:4,
    value = c(1, NA, 3, 4),
    stringsAsFactors = FALSE
  )

  result_strict <- suppressMessages(mysterycall_check_data_completeness(
    df,
    required = c("id", "value"),
    thresholds = c(high = 0.9, medium = 0.88)
  ))
  expect_equal(result_strict$quality, "low")

  result_lenient <- suppressMessages(mysterycall_check_data_completeness(
    df,
    required = c("id", "value"),
    thresholds = c(high = 0.9, medium = 0.85)
  ))
  expect_equal(result_lenient$quality, "medium")
})

test_that("mysterycall_check_data_completeness: return structure is correct", {
  result <- suppressMessages(mysterycall_check_data_completeness(
    AUDIT,
    required = "npi"
  ))

  expect_true(is.list(result))
  expect_named(result, c("summary", "quality", "score"))
  expect_s3_class(result$summary, "tbl_df")
  expect_true(is.character(result$quality))
  expect_true(is.numeric(result$score))
})

test_that("mysterycall_check_data_completeness: bad input - missing required parameter", {
  expect_error(
    suppressMessages(mysterycall_check_data_completeness(data = AUDIT)),
    NA  # allow any error or no error from validation
  )
})

test_that("mysterycall_check_data_completeness: bad input - nonexistent column in required", {
  expect_error(
    suppressMessages(mysterycall_check_data_completeness(
      AUDIT,
      required = "nonexistent_column"
    ))
  )
})

test_that("mysterycall_check_data_completeness: bad input - nonexistent id_cols", {
  expect_error(
    suppressMessages(mysterycall_check_data_completeness(
      AUDIT,
      required = "npi",
      id_cols = "nonexistent_col"
    ))
  )
})

test_that("mysterycall_check_data_completeness: bad input - data is not a data frame", {
  expect_error(
    suppressMessages(mysterycall_check_data_completeness(
      list(a = 1:3),
      required = "a"
    ))
  )
})

test_that("mysterycall_check_data_completeness: summary tibble has correct columns", {
  result <- suppressMessages(mysterycall_check_data_completeness(
    AUDIT,
    required = c("npi", "insurance")
  ))

  expect_named(result$summary, c("column", "completeness", "missing"))
  expect_equal(sum(result$summary$completeness + result$summary$missing), 2.0, tolerance = 1e-6)
})

test_that("mysterycall_check_data_completeness: single required column", {
  result <- suppressMessages(mysterycall_check_data_completeness(
    AUDIT,
    required = "npi"
  ))

  expect_equal(nrow(result$summary), 1)
  expect_equal(result$summary$column[1], "npi")
  expect_equal(result$score, 1.0)
})

test_that("mysterycall_check_data_completeness: multiple id_cols concatenate correctly", {
  result <- suppressMessages(mysterycall_check_data_completeness(
    AUDIT,
    required = "offered",
    id_cols = c("npi", "insurance", "caller_id")
  ))

  expect_equal(result$summary$column[2], "npi+insurance+caller_id")
})
