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

test_that("mysterycall_strobe_flow warns and degrades on an unnamed excl_detail (bug 51)", {
  # A bare/unnamed excl_detail previously crashed with "subscript out of bounds"
  # from excl_detail[[code]]. It must now warn and ignore the value, not error.
  expect_warning(
    result <- mysterycall_strobe_flow(
      n_total = 960, n_calldate = 900, n_included = 800,
      n_logistic = 790, n_waittime = 780, excl_detail = 18
    ),
    "named integer vector"
  )
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

# --- Validation: impossible waterfalls error, over-itemised details warn ------

test_that("a count that grows down the waterfall is an error", {
  # n_included (98) exceeds n_calldate (95): the screening exclusion would be
  # negative. A funnel only shrinks.
  expect_error(
    mysterycall_strobe_flow(
      n_total    = 100,
      n_calldate = 95,
      n_included = 98,
      n_waittime = 40
    ),
    "cannot increase"
  )
})

test_that("an excl_detail that sums to more than the screening total warns", {
  # screening total = n_calldate - n_included = 82 - 70 = 12, but the itemised
  # codes sum to 18: the parts exceed the whole.
  expect_warning(
    mysterycall_strobe_flow(
      n_total     = 100,
      n_calldate  = 82,
      n_included  = 70,
      n_waittime  = 45,
      excl_detail = c("1" = 10L, "2" = 8L)
    ),
    "exceed the total"
  )
})

test_that("a partial excl_detail (sums to less than the total) does not warn", {
  # 5 + 3 = 8 of the 22 screening exclusions itemised: a partial breakdown is
  # allowed and must not raise the over-count warning.
  seen <- character(0)
  withCallingHandlers(
    suppressMessages(mysterycall_strobe_flow(
      n_total     = 100,
      n_calldate  = 82,
      n_included  = 60,
      n_waittime  = 45,
      excl_detail = c("1" = 5L, "2" = 3L)
    )),
    warning = function(cnd) {
      seen <<- c(seen, conditionMessage(cnd))
      invokeRestart("muffleWarning")
    }
  )
  expect_false(any(grepl("exceed the total", seen)))
})
