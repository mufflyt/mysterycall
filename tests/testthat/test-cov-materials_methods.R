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


test_that("Happy path: basic call with callers and irb_number", {
  set.seed(100)
  result <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      callers    = c("alice", "bob"),
      irb_number = "IRB-2024-001",
      specialty  = "Family Medicine"
    )
  ))

  expect_s3_class(result, "mysterycall_materials_methods")
  expect_type(result$full_text, "character")
  expect_true(is.list(result$sections))
  expect_length(result$sections, 7L)
  expect_true(grepl("Alice and Bob", result$full_text))
  expect_true(grepl("Family Medicine", result$full_text))
  expect_true(grepl("IRB-2024-001", result$full_text))
})


test_that("Happy path with data: computes statistics from data frame", {
  set.seed(100)
  result <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      data            = AUDIT,
      caller_col      = "caller_id",
      physician_col   = "npi",
      outcome_col     = "wait_days",
      irb_number      = "IRB-2024-002"
    )
  ))

  expect_s3_class(result, "mysterycall_materials_methods")
  expect_equal(result$stats$n_total_calls, 4L)
  expect_equal(result$stats$n_physicians, 2L)
  expect_equal(result$stats$n_callers, 2L)
  expect_equal(result$stats$n_complete, 4L)
  expect_equal(result$stats$pct_complete, 100.0)
  expect_true(grepl("a and b", result$full_text))
})


test_that("Edge case: missing outcome values reduce completion percentage", {
  set.seed(100)
  df_with_na <- AUDIT
  df_with_na$wait_days[1] <- NA

  result <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      data            = df_with_na,
      caller_col      = "caller_id",
      physician_col   = "npi",
      outcome_col     = "wait_days",
      irb_number      = "IRB-2024-003"
    )
  ))

  expect_equal(result$stats$n_complete, 3L)
  expect_equal(result$stats$pct_complete, 75.0)
  expect_true(grepl("3 of 4 calls", result$full_text))
})


test_that("Edge case: no callers provided triggers manual input item", {
  set.seed(100)
  result <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      irb_number = "IRB-2024-004"
    )
  ))

  expect_true("Caller names (provide callers= or caller_col)" %in% result$items_needing_input)
  expect_true(grepl("\\[CALLER NAMES REQUIRED\\]", result$full_text))
})


test_that("Edge case: default irb_number triggers manual input item", {
  set.seed(100)
  result <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      callers = "Jane"
    )
  ))

  expect_true("IRB protocol number" %in% result$items_needing_input)
})


test_that("Edge case: business_days parameters affect output text", {
  set.seed(100)
  result_cal <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      callers                   = "Test",
      irb_number                = "IRB-2024-005",
      business_days_primary     = FALSE,
      business_days_sensitivity = TRUE
    )
  ))

  result_biz <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      callers                   = "Test",
      irb_number                = "IRB-2024-005",
      business_days_primary     = TRUE,
      business_days_sensitivity = FALSE
    )
  ))

  expect_true(grepl("calendar days", result_cal$sections$appointment_definition))
  expect_true(grepl("business days", result_biz$sections$appointment_definition))
  expect_true(grepl("sensitivity analysis", result_cal$sections$business_days))
  expect_false(grepl("sensitivity analysis", result_biz$sections$business_days))
})


test_that("Error path: invalid caller_col is ignored with warning", {
  set.seed(100)
  result <- suppressWarnings(
    mysterycall_materials_methods(
      data       = AUDIT,
      caller_col = "nonexistent_col",
      irb_number = "IRB-2024-006"
    )
  )

  expect_s3_class(result, "mysterycall_materials_methods")
  expect_true(length(result$callers_standardized) == 0L)
})


test_that("Error path: invalid outcome_col is ignored with warning", {
  set.seed(100)
  result <- suppressWarnings(
    mysterycall_materials_methods(
      data         = AUDIT,
      outcome_col  = "nonexistent_outcome",
      irb_number   = "IRB-2024-007"
    )
  )

  expect_s3_class(result, "mysterycall_materials_methods")
  expect_true(is.na(result$stats$n_complete))
})


test_that("Edge case: caller names are title-cased", {
  set.seed(100)
  result <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      callers    = c("jANE", "JOHN", "sarah"),
      irb_number = "IRB-2024-008"
    )
  ))

  expect_equal(result$callers_standardized, c("Jane", "John", "Sarah"))
  expect_true(grepl("Jane, John, and Sarah", result$full_text))
})


test_that("Structure: result has all required list elements", {
  set.seed(100)
  result <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      callers = "Test"
    )
  ))

  expect_true("sections" %in% names(result))
  expect_true("full_text" %in% names(result))
  expect_true("stats" %in% names(result))
  expect_true("reliability" %in% names(result))
  expect_true("callers_standardized" %in% names(result))
  expect_true("items_needing_input" %in% names(result))
})


test_that("Structure: sections list has exactly 7 named elements", {
  set.seed(100)
  result <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      callers = "Test"
    )
  ))

  expected_sections <- c(
    "caller_standardization", "call_spacing", "appointment_definition",
    "physician_selection", "missing_data", "business_days", "irb"
  )
  expect_equal(names(result$sections), expected_sections)
})


test_that("Print method works and returns invisibly", {
  set.seed(100)
  result <- suppressMessages(suppressWarnings(
    mysterycall_materials_methods(
      callers = "Test"
    )
  ))

  output <- suppressMessages(capture.output(print(result)))
  expect_true(length(output) > 0)
  expect_true(any(grepl("Materials & Methods", output)))
})
