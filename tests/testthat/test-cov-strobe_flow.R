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

test_that("mysterycall_strobe_flow returns ggplot with minimal explicit counts", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(
      n_total    = 100,
      n_calldate = 95,
      n_included = 50,
      n_waittime = 40
    )
  ))
  expect_s3_class(result, "ggplot")
  expect_equal(result$labels$title, "STROBE Flow Diagram - Mystery-Caller Study")
})

test_that("mysterycall_strobe_flow respects custom labels and title", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(
      n_total    = 500,
      n_calldate = 450,
      n_included = 200,
      n_waittime = 150,
      label_total    = "Calls Logged",
      label_included = "Included Records",
      title          = "My STROBE Diagram"
    )
  ))
  expect_s3_class(result, "ggplot")
  expect_equal(result$labels$title, "My STROBE Diagram")
})

test_that("mysterycall_strobe_flow includes exclusion details when provided", {
  # Must be a named list so missing code lookups return NULL rather than error
  excl_codes <- list("1" = 5L, "2" = 3L, "3" = 0L, "5" = 0L,
                     "6" = 0L, "7" = 0L, "8" = 10L, "9" = 0L, "10" = 0L, "NA" = 0L)
  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(
      n_total          = 100,
      n_calldate       = 82,
      n_included       = 60,
      n_waittime       = 45,
      excl_detail      = excl_codes,
      excl_no_calldate = 18
    )
  ))
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_strobe_flow handles small sample sizes (edge case)", {
  result <- suppressMessages(suppressWarnings(
    mysterycall_strobe_flow(
      n_total    = 1,
      n_calldate = 1,
      n_included = 1,
      n_waittime = 1
    )
  ))
  expect_s3_class(result, "ggplot")
})

test_that("mysterycall_strobe_flow errors when required n_* arguments missing", {
  expect_error(
    mysterycall_strobe_flow(),
    "Could not determine"
  )
})

test_that("mysterycall_strobe_flow rejects invalid prepared object", {
  expect_error(
    mysterycall_strobe_flow(prepared = list(invalid = TRUE)),
    "mysterycall_prepared"
  )
})
