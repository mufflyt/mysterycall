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


test_that("mysterycall_acceptance_rate_calc: happy path with defaults", {
  set.seed(1)
  df <- data.frame(
    phone                             = paste0("P", seq_len(20)),
    insurance                         = rep(c("Medicaid", "BCBS"), each = 10L),
    reason_for_exclusions             = rep("Able to contact", 20L),
    business_days_until_appointment   = rep(c(5L, 10L), each = 10L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df)
  )

  expect_s3_class(result, "mysterycall_acceptance_rate_calc")
  expect_type(result, "list")
  expect_named(result, c("table", "overall", "sentences", "gap_sentence"))

  # Check table structure
  expect_s3_class(result$table, "data.frame")
  expect_equal(nrow(result$table), 2L)
  expect_named(result$table, c("insurance", "n_total", "n_excluded", "n_numerator",
                                "n_denominator", "rate_pct", "ci_lower_pct",
                                "ci_upper_pct", "sentence"))

  # Check overall is not NULL when 2+ groups
  expect_s3_class(result$overall, "data.frame")
  expect_equal(nrow(result$overall), 1L)

  # Check sentences
  expect_type(result$sentences, "character")
  expect_length(result$sentences, 2L)

  # Check gap_sentence
  expect_type(result$gap_sentence, "character")
  expect_length(result$gap_sentence, 1L)
})


test_that("mysterycall_acceptance_rate_calc: without wait_col filter", {
  set.seed(2)
  df <- data.frame(
    phone                             = paste0("P", seq_len(16)),
    insurance                         = rep(c("Medicaid", "BCBS"), each = 8L),
    reason_for_exclusions             = c(rep("Able to contact", 6L),
                                          rep("No answer", 2L),
                                          rep("Able to contact", 6L),
                                          rep("Line disconnected", 2L)),
    business_days_until_appointment   = c(rep(0L, 4L), rep(5L, 4L),
                                          rep(0L, 4L), rep(10L, 4L)),
    stringsAsFactors = FALSE
  )

  # With wait_col (default)
  result_with_wait <- suppressMessages(
    mysterycall_acceptance_rate_calc(df, wait_col = "business_days_until_appointment")
  )

  # Without wait_col
  result_no_wait <- suppressMessages(
    mysterycall_acceptance_rate_calc(df, wait_col = NULL)
  )

  # Numerator with wait filter should be smaller or equal
  expect_lte(
    result_with_wait$table$n_numerator[1L],
    result_no_wait$table$n_numerator[1L]
  )
  expect_lte(
    result_with_wait$table$n_numerator[2L],
    result_no_wait$table$n_numerator[2L]
  )
})


test_that("mysterycall_acceptance_rate_calc: with medicaid_accept_col", {
  set.seed(3)
  df <- data.frame(
    phone                             = paste0("P", seq_len(12)),
    insurance                         = rep(c("Medicaid", "BCBS"), each = 6L),
    reason_for_exclusions             = rep("Able to contact", 12L),
    business_days_until_appointment   = rep(5L, 12L),
    medicaid_accept                   = c(TRUE, TRUE, NA, FALSE, TRUE, FALSE,
                                          TRUE, FALSE, NA, TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(
      df,
      medicaid_accept_col = "medicaid_accept"
    )
  )

  expect_s3_class(result, "mysterycall_acceptance_rate_calc")
  # Rows with NA in medicaid_accept should be excluded from numerator
  expect_true(all(result$table$n_numerator < result$table$n_denominator))
})


test_that("mysterycall_acceptance_rate_calc: custom insurance_groups", {
  set.seed(4)
  df <- data.frame(
    phone                             = paste0("P", seq_len(15)),
    insurance                         = c(rep("Medicaid", 5L),
                                          rep("BCBS", 5L),
                                          rep("Other", 5L)),
    reason_for_exclusions             = rep("Able to contact", 15L),
    business_days_until_appointment   = rep(5L, 15L),
    stringsAsFactors = FALSE
  )

  # Request only two groups
  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(
      df,
      insurance_groups = c("Medicaid", "BCBS")
    )
  )

  expect_equal(nrow(result$table), 2L)
  expect_equal(result$table$insurance, c("Medicaid", "BCBS"))
})


test_that("mysterycall_acceptance_rate_calc: edge case—all rows excluded", {
  set.seed(5)
  df <- data.frame(
    phone                             = paste0("P", seq_len(10)),
    insurance                         = rep("Medicaid", 10L),
    reason_for_exclusions             = rep("No answer", 10L),  # none are "Able to contact"
    business_days_until_appointment   = rep(5L, 10L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df)
  )

  expect_equal(result$table$n_numerator[1L], 0L)
  expect_equal(result$table$n_denominator[1L], 0L)
  expect_true(is.na(result$table$rate_pct[1L]))
})


test_that("mysterycall_acceptance_rate_calc: edge case—single row", {
  df <- data.frame(
    phone                             = "P1",
    insurance                         = "Medicaid",
    reason_for_exclusions             = "Able to contact",
    business_days_until_appointment   = 5L,
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df)
  )

  expect_s3_class(result, "mysterycall_acceptance_rate_calc")
  expect_equal(nrow(result$table), 1L)
  expect_equal(result$table$n_total[1L], 1L)
  expect_equal(result$table$n_numerator[1L], 1L)
})


test_that("mysterycall_acceptance_rate_calc: edge case—NA insurance values", {
  set.seed(6)
  df <- data.frame(
    phone                             = paste0("P", seq_len(10)),
    insurance                         = c(rep("Medicaid", 5L), rep(NA, 5L)),
    reason_for_exclusions             = rep("Able to contact", 10L),
    business_days_until_appointment   = rep(5L, 10L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df)
  )

  # Only Medicaid group should appear
  expect_equal(nrow(result$table), 1L)
  expect_equal(result$table$insurance[1L], "Medicaid")
})


test_that("mysterycall_acceptance_rate_calc: error—data not a data.frame", {
  expect_error(
    mysterycall_acceptance_rate_calc(list(a = 1, b = 2)),
    "must be a data.frame"
  )
})


test_that("mysterycall_acceptance_rate_calc: error—empty data", {
  df <- data.frame(
    phone                             = character(0),
    insurance                         = character(0),
    reason_for_exclusions             = character(0),
    business_days_until_appointment   = integer(0)
  )

  expect_error(
    mysterycall_acceptance_rate_calc(df),
    "must contain at least one row"
  )
})


test_that("mysterycall_acceptance_rate_calc: error—missing insurance_col", {
  df <- data.frame(
    phone                             = "P1",
    reason_for_exclusions             = "Able to contact",
    business_days_until_appointment   = 5L
  )

  expect_error(
    mysterycall_acceptance_rate_calc(df)
  )
})


test_that("mysterycall_acceptance_rate_calc: error—invalid insurance_col type", {
  df <- data.frame(
    phone                             = "P1",
    insurance                         = "Medicaid",
    reason_for_exclusions             = "Able to contact",
    business_days_until_appointment   = 5L
  )

  expect_error(
    mysterycall_acceptance_rate_calc(df, insurance_col = c("a", "b")),
    "must be a single character string"
  )
})


test_that("mysterycall_acceptance_rate_calc: error—missing inclusion_col", {
  df <- data.frame(
    phone                             = "P1",
    insurance                         = "Medicaid",
    business_days_until_appointment   = 5L
  )

  expect_error(
    mysterycall_acceptance_rate_calc(df, inclusion_col = "reason_for_exclusions")
  )
})


test_that("mysterycall_acceptance_rate_calc: error—empty inclusion_value", {
  df <- data.frame(
    phone                             = "P1",
    insurance                         = "Medicaid",
    reason_for_exclusions             = "Able to contact",
    business_days_until_appointment   = 5L
  )

  expect_error(
    mysterycall_acceptance_rate_calc(df, inclusion_value = ""),
    "must be a single non-empty character string"
  )
})


test_that("mysterycall_acceptance_rate_calc: error—wait_col not numeric", {
  df <- data.frame(
    phone                             = "P1",
    insurance                         = "Medicaid",
    reason_for_exclusions             = "Able to contact",
    business_days_until_appointment   = "not_numeric"
  )

  expect_error(
    mysterycall_acceptance_rate_calc(df),
    "must be numeric"
  )
})


test_that("mysterycall_acceptance_rate_calc: error—conf_level out of bounds", {
  df <- data.frame(
    phone                             = "P1",
    insurance                         = "Medicaid",
    reason_for_exclusions             = "Able to contact",
    business_days_until_appointment   = 5L
  )

  expect_error(
    mysterycall_acceptance_rate_calc(df, conf_level = 1.5),
    "strictly between 0 and 1"
  )

  expect_error(
    mysterycall_acceptance_rate_calc(df, conf_level = 0),
    "strictly between 0 and 1"
  )
})


test_that("mysterycall_acceptance_rate_calc: error—missing medicaid_accept_col", {
  df <- data.frame(
    phone                             = "P1",
    insurance                         = "Medicaid",
    reason_for_exclusions             = "Able to contact",
    business_days_until_appointment   = 5L
  )

  expect_error(
    mysterycall_acceptance_rate_calc(df, medicaid_accept_col = "medicaid_accept")
  )
})


test_that("mysterycall_acceptance_rate_calc: gap_sentence—two groups", {
  set.seed(7)
  df <- data.frame(
    phone                             = paste0("P", seq_len(20)),
    insurance                         = rep(c("Medicaid", "BCBS"), each = 10L),
    reason_for_exclusions             = c(rep("Able to contact", 8L), rep("No answer", 2L),
                                          rep("Able to contact", 7L), rep("No answer", 3L)),
    business_days_until_appointment   = rep(5L, 20L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df)
  )

  expect_type(result$gap_sentence, "character")
  expect_false(is.na(result$gap_sentence))
  expect_true(grepl("gap of", result$gap_sentence))
})


test_that("mysterycall_acceptance_rate_calc: gap_sentence—three groups", {
  set.seed(8)
  df <- data.frame(
    phone                             = paste0("P", seq_len(30)),
    insurance                         = rep(c("Medicaid", "BCBS", "Other"), each = 10L),
    reason_for_exclusions             = rep("Able to contact", 30L),
    business_days_until_appointment   = rep(5L, 30L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df)
  )

  expect_type(result$gap_sentence, "character")
  expect_false(is.na(result$gap_sentence))
  expect_true(grepl("ranged from", result$gap_sentence))
})


test_that("mysterycall_acceptance_rate_calc: gap_sentence—single group", {
  df <- data.frame(
    phone                             = paste0("P", seq_len(10)),
    insurance                         = rep("Medicaid", 10L),
    reason_for_exclusions             = rep("Able to contact", 10L),
    business_days_until_appointment   = rep(5L, 10L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df)
  )

  expect_true(is.na(result$gap_sentence))
  expect_null(result$overall)
})


test_that("print.mysterycall_acceptance_rate_calc: basic output", {
  set.seed(9)
  df <- data.frame(
    phone                             = paste0("P", seq_len(10)),
    insurance                         = rep("Medicaid", 10L),
    reason_for_exclusions             = rep("Able to contact", 10L),
    business_days_until_appointment   = rep(5L, 10L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df)
  )

  # Capture print output
  output <- capture.output(suppressMessages(print(result)))

  expect_type(output, "character")
  expect_length(output, 1L)
  expect_true(grepl("Medicaid", output[1L]))
})


test_that("print.mysterycall_acceptance_rate_calc: with gap_sentence", {
  set.seed(10)
  df <- data.frame(
    phone                             = paste0("P", seq_len(20)),
    insurance                         = rep(c("Medicaid", "BCBS"), each = 10L),
    reason_for_exclusions             = rep("Able to contact", 20L),
    business_days_until_appointment   = rep(5L, 20L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df)
  )

  output <- capture.output(suppressMessages(print(result)))

  # Should have sentences and gap_sentence lines
  expect_gte(length(output), 2L)
})


test_that("mysterycall_acceptance_rate_calc: deduplication on id_col", {
  # Create data with duplicate phone numbers
  df <- data.frame(
    phone                             = c("P1", "P1", "P2", "P2"),
    insurance                         = rep("Medicaid", 4L),
    reason_for_exclusions             = rep("Able to contact", 4L),
    business_days_until_appointment   = rep(5L, 4L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df)
  )

  # Should only count 2 distinct physicians
  expect_equal(result$table$n_total[1L], 2L)
})


test_that("mysterycall_acceptance_rate_calc: custom id_col", {
  df <- data.frame(
    phone                             = c("P1", "P1", "P2", "P2"),
    npi                               = c("111", "222", "333", "444"),
    insurance                         = rep("Medicaid", 4L),
    reason_for_exclusions             = rep("Able to contact", 4L),
    business_days_until_appointment   = rep(5L, 4L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(df, id_col = "npi")
  )

  # Should count 4 distinct NPIs
  expect_equal(result$table$n_total[1L], 4L)
})


test_that("mysterycall_acceptance_rate_calc: custom inclusion_value", {
  df <- data.frame(
    phone                             = paste0("P", seq_len(10)),
    insurance                         = rep("Medicaid", 10L),
    status                            = c(rep("Reached", 6L), rep("Not reached", 4L)),
    business_days_until_appointment   = rep(5L, 10L),
    stringsAsFactors = FALSE
  )

  result <- suppressMessages(
    mysterycall_acceptance_rate_calc(
      df,
      inclusion_col = "status",
      inclusion_value = "Reached"
    )
  )

  expect_equal(result$table$n_denominator[1L], 6L)
})


test_that("mysterycall_acceptance_rate_calc: insurance_groups with missing group", {
  set.seed(11)
  df <- data.frame(
    phone                             = paste0("P", seq_len(10)),
    insurance                         = rep("Medicaid", 10L),
    reason_for_exclusions             = rep("Able to contact", 10L),
    business_days_until_appointment   = rep(5L, 10L),
    stringsAsFactors = FALSE
  )

  result <- suppressWarnings(
    suppressMessages(
      mysterycall_acceptance_rate_calc(
        df,
        insurance_groups = c("Medicaid", "NonExistent")
      )
    )
  )

  # Should only include Medicaid
  expect_equal(nrow(result$table), 1L)
  expect_equal(result$table$insurance[1L], "Medicaid")
})
