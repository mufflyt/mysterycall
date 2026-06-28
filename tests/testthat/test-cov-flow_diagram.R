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

# Happy path: minimal inputs
test_that("mysterycall_flow_diagram returns ggplot with minimal inputs", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_flow_diagram(
      n_identified = 500,
      n_analysed   = 400
    )
  ))
  expect_s3_class(result, "ggplot")
})

# Happy path: all parameters specified
test_that("mysterycall_flow_diagram returns ggplot with all parameters", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_flow_diagram(
      n_identified        = 500,
      n_contacted         = 420,
      n_excluded_contact  = 80,
      n_completed         = 369,
      n_excluded_complete = 51,
      n_analysed          = 369,
      exclusion_reasons   = c(
        contact  = "Retired, wrong specialty, or disconnected",
        complete = "No answer after 3 attempts"
      ),
      title = "Custom Flow Diagram",
      output_path = NULL,
      width = 10,
      height = 8
    )
  ))
  expect_s3_class(result, "ggplot")
})

# Edge case: all optional parameters NULL
test_that("mysterycall_flow_diagram handles NULL optional parameters", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_flow_diagram(
      n_identified        = 500,
      n_contacted         = NULL,
      n_excluded_contact  = NULL,
      n_completed         = NULL,
      n_excluded_complete = NULL,
      n_analysed          = 400,
      exclusion_reasons   = NULL
    )
  ))
  expect_s3_class(result, "ggplot")
})

# Edge case: boundary condition where n_analysed equals n_identified
test_that("mysterycall_flow_diagram handles n_analysed == n_identified", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_flow_diagram(
      n_identified = 500,
      n_analysed   = 500
    )
  ))
  expect_s3_class(result, "ggplot")
})

# Bad input: n_analysed > n_identified
test_that("mysterycall_flow_diagram errors when n_analysed > n_identified", {
  expect_error(
    mysterycall_flow_diagram(
      n_identified = 500,
      n_analysed   = 600
    ),
    "cannot exceed"
  )
})

# Bad input: n_identified is not numeric
test_that("mysterycall_flow_diagram errors with non-numeric n_identified", {
  expect_error(
    mysterycall_flow_diagram(
      n_identified = "500",
      n_analysed   = 400
    ),
    "must be a single positive integer"
  )
})

# Bad input: n_analysed is not numeric
test_that("mysterycall_flow_diagram errors with non-numeric n_analysed", {
  expect_error(
    mysterycall_flow_diagram(
      n_identified = 500,
      n_analysed   = "400"
    ),
    "must be a single positive integer"
  )
})

# Bad input: zero or negative values
test_that("mysterycall_flow_diagram errors with zero or negative n_identified", {
  expect_error(
    mysterycall_flow_diagram(
      n_identified = 0,
      n_analysed   = 0
    ),
    "must be a single positive integer"
  )
})

# Bad input: n_analysed is negative
test_that("mysterycall_flow_diagram errors with negative n_analysed", {
  expect_error(
    mysterycall_flow_diagram(
      n_identified = 500,
      n_analysed   = -1
    ),
    "must be a single positive integer"
  )
})

# Edge case: partial flow diagram with only n_contacted
test_that("mysterycall_flow_diagram with only n_contacted specified", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_flow_diagram(
      n_identified = 500,
      n_contacted  = 420,
      n_analysed   = 400
    )
  ))
  expect_s3_class(result, "ggplot")
})

# Edge case: partial flow diagram with only n_completed
test_that("mysterycall_flow_diagram with only n_completed specified", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_flow_diagram(
      n_identified = 500,
      n_completed  = 369,
      n_analysed   = 360
    )
  ))
  expect_s3_class(result, "ggplot")
})

# Edge case: with exclusion_reasons and optional counts for both stages
test_that("mysterycall_flow_diagram with complete exclusion_reasons", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_flow_diagram(
      n_identified        = 500,
      n_contacted         = 420,
      n_excluded_contact  = 80,
      n_completed         = 369,
      n_excluded_complete = 51,
      n_analysed          = 369,
      exclusion_reasons   = c(
        contact  = "Retired or disconnected",
        complete = "No answer"
      )
    )
  ))
  expect_s3_class(result, "ggplot")
})
