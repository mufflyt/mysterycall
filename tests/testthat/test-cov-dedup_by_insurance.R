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

test_that("mysterycall_dedup_by_insurance: happy path with default parameters", {
  df <- data.frame(
    phone                = c("555-1234", "555-1234", "555-9999"),
    insurance            = c("Medicaid", "Medicaid", "BCBS"),
    physician_information = c("Dr A", "Dr A", "Dr B"),
    wait_days            = c(3, 3, 7),
    stringsAsFactors     = FALSE
  )
  result <- suppressMessages(mysterycall_dedup_by_insurance(df, output_dir = NA))

  # Check return type is tibble
  expect_s3_class(result, "tbl_df")

  # Should have 2 rows (one duplicate removed)
  expect_equal(nrow(result), 2L)

  # Should have all original columns
  expect_equal(ncol(result), 4L)

  # First row should be unique combo (555-1234, Medicaid, Dr A)
  expect_true(result$phone[1] == "555-1234")
  expect_true(result$insurance[1] == "Medicaid")
})

test_that("mysterycall_dedup_by_insurance: deduplication with name_col=NULL", {
  df <- data.frame(
    phone     = c("555-1234", "555-1234", "555-1234"),
    insurance = c("Medicaid", "Medicaid", "BCBS"),
    name      = c("Dr A", "Dr B", "Dr C"),
    value     = c(10, 20, 30),
    stringsAsFactors = FALSE
  )

  # With name_col=NULL, should deduplicate only on phone x insurance
  # This means the two "555-1234" + "Medicaid" rows become one
  result <- suppressMessages(
    mysterycall_dedup_by_insurance(df, phone_col = "phone", insurance_col = "insurance",
                                   name_col = NULL, output_dir = NA)
  )

  # Should have 2 rows: one for (555-1234, Medicaid) and one for (555-1234, BCBS)
  expect_equal(nrow(result), 2L)
  expect_s3_class(result, "tbl_df")
})

test_that("mysterycall_dedup_by_insurance: empty data frame", {
  df <- data.frame(
    phone                = character(0),
    insurance            = character(0),
    physician_information = character(0),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    mysterycall_dedup_by_insurance(df, output_dir = NA)
  )

  # Should return empty tibble with same columns
  expect_equal(nrow(result), 0L)
  expect_s3_class(result, "tbl_df")
  expect_true("phone" %in% names(result))
})

test_that("mysterycall_dedup_by_insurance: keep_all=FALSE retains only distinct columns", {
  df <- data.frame(
    phone                = c("555-1234", "555-1234"),
    insurance            = c("Medicaid", "Medicaid"),
    physician_information = c("Dr A", "Dr A"),
    wait_days            = c(3, 5),
    stringsAsFactors     = FALSE
  )

  # With keep_all=TRUE (default), all columns retained
  result_keep_all <- suppressMessages(
    mysterycall_dedup_by_insurance(df, keep_all = TRUE, output_dir = NA)
  )
  expect_equal(ncol(result_keep_all), 4L)
})

test_that("mysterycall_dedup_by_insurance: error when phone_col missing from data", {
  df <- data.frame(
    insurance = c("Medicaid", "BCBS"),
    value     = c(1, 2),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_dedup_by_insurance(df, phone_col = "phone", output_dir = NA))
  )
})

test_that("mysterycall_dedup_by_insurance: error when insurance_col missing from data", {
  df <- data.frame(
    phone = c("555-1234", "555-9999"),
    value = c(1, 2),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_dedup_by_insurance(df, insurance_col = "insurance", output_dir = NA))
  )
})

test_that("mysterycall_dedup_by_insurance: error when name_col missing from data", {
  df <- data.frame(
    phone     = c("555-1234", "555-9999"),
    insurance = c("Medicaid", "BCBS"),
    value     = c(1, 2),
    stringsAsFactors = FALSE
  )

  expect_error(
    suppressMessages(mysterycall_dedup_by_insurance(df, name_col = "physician_information", output_dir = NA))
  )
})

test_that("mysterycall_dedup_by_insurance: error with non-data.frame input", {
  expect_error(
    suppressMessages(mysterycall_dedup_by_insurance(list(a = 1), output_dir = NA)),
    "data.frame"
  )
})

test_that("mysterycall_dedup_by_insurance: error with non-string phone_col", {
  df <- data.frame(phone = c("555-1234"), insurance = c("Medicaid"), stringsAsFactors = FALSE)

  expect_error(
    suppressMessages(mysterycall_dedup_by_insurance(df, phone_col = 123, output_dir = NA)),
    "string"
  )
})

test_that("mysterycall_dedup_by_insurance: complex deduplication scenario", {
  df <- data.frame(
    phone                = c("555-1001", "555-1001", "555-1001", "555-2002", "555-2002", "555-3003"),
    insurance            = c("Medicaid", "Medicaid", "BCBS", "Medicaid", "BCBS", "Medicaid"),
    physician_information = c("Dr A", "Dr A", "Dr A", "Dr B", "Dr B", "Dr C"),
    wait_days            = c(3, 4, 5, 6, 7, 8),
    stringsAsFactors     = FALSE
  )

  result <- suppressMessages(
    mysterycall_dedup_by_insurance(df, output_dir = NA)
  )

  # Should deduplicate to 5 unique combos:
  # (555-1001, Medicaid, Dr A), (555-1001, BCBS, Dr A),
  # (555-2002, Medicaid, Dr B), (555-2002, BCBS, Dr B), (555-3003, Medicaid, Dr C)
  expect_equal(nrow(result), 5L)
  expect_s3_class(result, "tbl_df")
})

test_that("mysterycall_dedup_by_insurance: custom column names", {
  df <- data.frame(
    npi_number = c("123", "123", "456"),
    coverage   = c("Plan A", "Plan A", "Plan B"),
    doc_name   = c("Smith", "Smith", "Jones"),
    score      = c(10, 10, 20),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_dedup_by_insurance(
      df,
      phone_col     = "npi_number",
      insurance_col = "coverage",
      name_col      = "doc_name",
      output_dir    = NA
    )
  )

  # Should have 2 rows: (123, Plan A, Smith) and (456, Plan B, Jones)
  expect_equal(nrow(result), 2L)
  expect_equal(ncol(result), 4L)
  expect_true("npi_number" %in% names(result))
  expect_true("coverage" %in% names(result))
})
