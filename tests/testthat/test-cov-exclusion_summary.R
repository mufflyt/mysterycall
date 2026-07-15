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

# Test 1: Happy path - basic call with valid minimal inputs
test_that("mysterycall_exclusion_summary returns correct structure with valid inputs", {
  reasons <- c(
    "Able to contact",
    "Phone not answered or busy signal on repeat calls",
    "Went to voicemail",
    "Number contacted did not correspond to expected office/specialty",
    "Physician referral required before scheduling appointment",
    "Not accepting new patients",
    "Greater than 5 minutes on hold"
  )
  n_each <- c(120L, 40L, 30L, 10L, 15L, 20L, 5L)

  df <- data.frame(
    call_id               = seq_len(sum(n_each)),
    reason_for_exclusions = rep(reasons, n_each),
    stringsAsFactors      = FALSE
  )

  result <- mysterycall_exclusion_summary(df)

  expect_s3_class(result, "mysterycall_exclusion_summary")
  expect_type(result, "list")
  expect_named(result, c("total", "n_reached", "n_unreachable", "pct_reached",
                         "n_included", "n_unrecognized", "counts", "percentages",
                         "paragraph", "table"))
  expect_equal(result$total, 240L)
  expect_type(result$paragraph, "character")
  expect_length(result$paragraph, 1L)
})

# Test 2: Edge case - zero-row data frame
test_that("mysterycall_exclusion_summary handles zero-row data with warning", {
  df <- data.frame(
    reason_for_exclusions = character(0),
    stringsAsFactors = FALSE
  )

  expect_warning(
    mysterycall_exclusion_summary(df),
    "zero rows"
  )

  result <- suppressWarnings(mysterycall_exclusion_summary(df))

  expect_equal(result$total, 0L)
  expect_equal(result$n_reached, 0L)
  expect_equal(result$n_unreachable, 0L)
  expect_true(is.na(result$pct_reached))
  expect_equal(result$n_included, 0L)
})

# Test 3: Bad input - missing required exclusion_col
test_that("mysterycall_exclusion_summary errors when exclusion_col not in data", {
  df <- data.frame(
    outcome = c("Able to contact", "Phone not answered"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_exclusion_summary(df, exclusion_col = "missing_col"),
    "not found"
  )
})

# Test 4: Bad input - non-data.frame input
test_that("mysterycall_exclusion_summary errors on non-data.frame input", {
  expect_error(
    mysterycall_exclusion_summary(list(x = 1:10)),
    "must be a data frame"
  )
})

# Test 5: Custom exclusion column and values
test_that("mysterycall_exclusion_summary works with custom column names and values", {
  df <- data.frame(
    call_outcome = c("Included", "Excluded: No answer", "Included", "Excluded: Wrong number"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_exclusion_summary(
    data          = df,
    exclusion_col = "call_outcome",
    inclusion_value = "Included",
    exclusion_categories = c(
      phone_not_answered = "Excluded: No answer",
      voicemail          = "Excluded: Voicemail",
      wrong_number       = "Excluded: Wrong number",
      referral_required  = "Excluded: Referral",
      not_accepting      = "Excluded: Not accepting",
      on_hold            = "Excluded: On hold"
    )
  )

  expect_equal(result$total, 4L)
  expect_equal(result$counts[["phone_not_answered"]], 1L)
  expect_equal(result$counts[["wrong_number"]], 1L)
  expect_equal(result$n_included, 2L)
})

# Test 6: Deduplication by id_col
test_that("mysterycall_exclusion_summary deduplicates by id_col", {
  df <- data.frame(
    npi                   = c(1L, 1L, 2L, 3L, 3L),
    reason_for_exclusions = c("Able to contact",
                              "Phone not answered or busy signal on repeat calls",
                              "Able to contact",
                              "Able to contact",
                              "Able to contact"),
    stringsAsFactors      = FALSE
  )

  result <- mysterycall_exclusion_summary(df, id_col = "npi")

  # After deduplication, only 3 unique NPIs
  expect_equal(result$total, 3L)
})

# Test 7: Missing required exclusion_categories key
test_that("mysterycall_exclusion_summary errors when exclusion_categories missing required keys", {
  df <- data.frame(
    reason_for_exclusions = c("Able to contact", "Phone not answered"),
    stringsAsFactors = FALSE
  )

  incomplete_categories <- c(
    phone_not_answered = "Phone not answered",
    voicemail          = "Voicemail"
  )

  expect_error(
    mysterycall_exclusion_summary(df, exclusion_categories = incomplete_categories),
    "missing required key"
  )
})

# Test 8: Correct counts and percentages calculation
test_that("mysterycall_exclusion_summary computes correct counts and percentages", {
  reasons <- c(
    "Able to contact",
    "Phone not answered or busy signal on repeat calls",
    "Went to voicemail",
    "Number contacted did not correspond to expected office/specialty",
    "Physician referral required before scheduling appointment",
    "Not accepting new patients",
    "Greater than 5 minutes on hold"
  )
  n_each <- c(100L, 20L, 20L, 10L, 20L, 20L, 10L)

  df <- data.frame(
    call_id               = seq_len(sum(n_each)),
    reason_for_exclusions = rep(reasons, n_each),
    stringsAsFactors      = FALSE
  )

  result <- mysterycall_exclusion_summary(df)

  # sum(n_each) = 100+20+20+10+20+20+10 = 200
  expect_equal(result$total, 200L)
  expect_equal(result$counts[["phone_not_answered"]], 20L)
  expect_equal(result$counts[["voicemail"]], 20L)
  expect_equal(result$counts[["wrong_number"]], 10L)
  expect_equal(result$n_unreachable, 50L)
  expect_equal(result$n_reached, 150L)
  expect_equal(result$n_included, 100L)
  expect_true(abs(result$percentages[["phone_not_answered"]] - (20/200 * 100)) < 0.01)
})

# Test 9: Print method produces output
test_that("print.mysterycall_exclusion_summary outputs paragraph text", {
  df <- data.frame(
    reason_for_exclusions = c("Able to contact",
                              "Phone not answered or busy signal on repeat calls",
                              "Able to contact"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_exclusion_summary(df)
  output <- capture.output(print(result))

  expect_true(length(output) > 0)
  expect_true(any(grepl("phone calls", output)))
})

# Test 10: Table structure and contents
test_that("mysterycall_exclusion_summary$table has correct structure", {
  df <- data.frame(
    reason_for_exclusions = c("Able to contact",
                              "Able to contact",
                              "Phone not answered or busy signal on repeat calls"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_exclusion_summary(df)
  tbl <- result$table

  expect_s3_class(tbl, "data.frame")
  expect_named(tbl, c("category", "label", "n", "pct"))
  # Should have 1 included + 6 exclusion categories = 7 rows
  expect_equal(nrow(tbl), 7L)
  expect_true(all(is.integer(tbl$n)))
  expect_true(all(is.numeric(tbl$pct)))
  # First row should be "included"
  expect_equal(tbl$category[1], "included")
})

# Test 11: Bad input - empty inclusion_value
test_that("mysterycall_exclusion_summary errors on invalid inclusion_value", {
  df <- data.frame(
    reason_for_exclusions = c("Able to contact"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_exclusion_summary(df, inclusion_value = character(0)),
    "must be a single character string"
  )
})

# Test 12: Bad input - invalid exclusion_col
test_that("mysterycall_exclusion_summary errors on invalid exclusion_col type", {
  df <- data.frame(
    reason_for_exclusions = c("Able to contact"),
    stringsAsFactors = FALSE
  )

  expect_error(
    mysterycall_exclusion_summary(df, exclusion_col = 123),
    "must be a single non-empty character string"
  )
})

# Test 13: Unrecognized exclusion values are silently ignored
test_that("mysterycall_exclusion_summary handles unrecognized exclusion values", {
  df <- data.frame(
    reason_for_exclusions = c("Able to contact",
                              "Able to contact",
                              "Unknown reason",
                              "Another unknown"),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_exclusion_summary(df)

  # Unknown values contribute to total but are now their own "unrecognized"
  # bucket (bug 22 fix); they no longer inflate n_included.
  expect_equal(result$total, 4L)
  expect_equal(result$n_included, 2L)      # only the two "Able to contact" rows
  expect_equal(result$n_unrecognized, 2L)  # the two unknown reasons
  expect_equal(sum(result$counts), 0L)     # No recognized exclusions
})

# Test 14: All calls are included (no exclusions)
test_that("mysterycall_exclusion_summary handles all-included scenario", {
  df <- data.frame(
    reason_for_exclusions = rep("Able to contact", 100L),
    stringsAsFactors = FALSE
  )

  result <- mysterycall_exclusion_summary(df)

  expect_equal(result$total, 100L)
  expect_equal(result$n_included, 100L)
  expect_equal(result$n_reached, 100L)
  expect_equal(result$n_unreachable, 0L)
  expect_equal(sum(result$counts), 0L)
  expect_true(result$pct_reached == 100)
})

# Test 15: id_col with all duplicates
test_that("mysterycall_exclusion_summary with id_col where all rows are same ID", {
  df <- data.frame(
    npi                   = rep(1L, 10),
    reason_for_exclusions = c("Able to contact",
                              "Phone not answered or busy signal on repeat calls",
                              "Went to voicemail",
                              "Number contacted did not correspond to expected office/specialty",
                              "Physician referral required before scheduling appointment",
                              "Not accepting new patients",
                              "Greater than 5 minutes on hold",
                              "Able to contact",
                              "Able to contact",
                              "Able to contact"),
    stringsAsFactors      = FALSE
  )

  result <- mysterycall_exclusion_summary(df, id_col = "npi")

  # After deduplication, only 1 unique ID
  expect_equal(result$total, 1L)
})

# Test 16: Named character vector for exclusion_categories must have non-empty names
test_that("mysterycall_exclusion_summary errors on unnamed exclusion_categories", {
  df <- data.frame(
    reason_for_exclusions = c("Able to contact"),
    stringsAsFactors = FALSE
  )

  unnamed_categories <- c(
    "Phone not answered",
    "Voicemail",
    "Wrong number",
    "Referral",
    "Not accepting",
    "On hold"
  )

  expect_error(
    mysterycall_exclusion_summary(df, exclusion_categories = unnamed_categories),
    "must be a named character vector"
  )
})
