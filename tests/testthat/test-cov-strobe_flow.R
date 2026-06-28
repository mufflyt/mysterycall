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


test_that("strobe_flow works with explicit counts (Mode 3 - happy path)", {
  skip_if_not_installed("ggplot2")

  expect_no_error(suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(
      n_total    = 743,
      n_calldate = 737,
      n_included = 141,
      n_waittime = 100,
      output_path = NULL
    )
  )))
})


test_that("strobe_flow returns a ggplot object", {
  skip_if_not_installed("ggplot2")

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(
      n_total    = 743,
      n_calldate = 737,
      n_included = 141,
      n_waittime = 100,
      output_path = NULL
    )
  ))

  expect_s3_class(result, "ggplot")
})


test_that("strobe_flow errors when required counts are missing", {
  skip_if_not_installed("ggplot2")

  # Missing n_waittime should error
  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall_strobe_flow(
        n_total    = 743,
        n_calldate = 737,
        n_included = 141,
        output_path = NULL
      )
    )),
    "Could not determine.*n_waittime"
  )
})


test_that("strobe_flow works with custom labels and title", {
  skip_if_not_installed("ggplot2")

  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(
      n_total    = 100,
      n_calldate = 95,
      n_included = 80,
      n_waittime = 75,
      title      = "Custom STROBE Title",
      label_total = "Custom Total",
      output_path = NULL
    )
  ))

  expect_s3_class(result, "ggplot")
  expect_equal(result$labels$title, "Custom STROBE Title")
})
