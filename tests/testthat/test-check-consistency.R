# Tests for the consistency rule engine

consistency_data <- function() {
  data.frame(
    record_id           = 1:5,
    office_answered     = c(FALSE, TRUE, TRUE, TRUE, TRUE),
    appointment_date    = c("2026-02-01", NA, "2026-03-01", NA, "2026-04-01"),
    taking_new_patients = c("Yes", "Yes", "Yes", "Yes", "No"),
    complete            = c("Complete", "Complete", "Complete", "Unverified",
                            "Complete"),
    call_date           = c("2026-01-01", "2026-01-02", NA, "2026-01-04",
                            "2026-01-05"),
    caller              = c("AB", NA, "CD", "  ", "EF"),
    stringsAsFactors = FALSE
  )
}

test_that("default rules flag the expected rows", {
  d <- consistency_data()
  res <- mysterycall_check_consistency(d, id_col = "record_id")
  expect_s3_class(res, "mysterycall_consistency_report")

  by_flag <- split(res$report$record_id, res$report$flag)
  # row 1: office not answered but appt date present
  expect_true(1 %in% by_flag[["ANSWER_CONFLICT"]])
  # rows with taking_new = Yes but no appointment date: rows 2 and 4
  expect_setequal(by_flag[["MISSING_APPT_DATE"]], c(2L, 4L))
  # row 3: complete but no call_date
  expect_true(3 %in% by_flag[["MISSING_CALL_DATE"]])
  # rows 2 (NA) and 4 (whitespace) missing caller
  expect_setequal(by_flag[["NO_CALLER_ASSIGNED"]], c(2L, 4L))
})

test_that("report is sorted by priority (CRITICAL/HIGH before MEDIUM)", {
  d <- consistency_data()
  res <- mysterycall_check_consistency(d, id_col = "record_id")
  pr <- as.character(res$report$priority)
  first_medium <- which(pr == "MEDIUM")[1]
  last_high    <- max(which(pr == "HIGH"))
  expect_true(last_high < first_medium)
})

test_that("rules referencing absent columns silently no-op", {
  # a log with only some of the default columns
  d <- data.frame(
    office_answered  = c(FALSE, TRUE),
    appointment_date = c("2026-02-01", NA),
    stringsAsFactors = FALSE)
  res <- mysterycall_check_consistency(d)
  # only ANSWER_CONFLICT can fire; the other three lack their columns
  expect_setequal(unique(as.character(res$report$flag)), "ANSWER_CONFLICT")
  expect_equal(nrow(res$report), 1L)
})

test_that("custom rule and priority propagate", {
  d <- data.frame(offered = c(TRUE, FALSE), wait = c(NA, 12))
  rule <- mysterycall_consistency_rule(
    flag = "WAIT_NO_OFFER", priority = "CRITICAL",
    description = "Wait recorded without an offer",
    action = "Fix it",
    predicate = function(x) !is.na(x$wait) & x$offered == FALSE)
  res <- mysterycall_check_consistency(d, rules = list(rule))
  expect_equal(nrow(res$report), 1L)
  expect_equal(res$report$row, 2L)
  expect_equal(as.character(res$report$priority), "CRITICAL")
})

test_that("keep_cols carries context into the report", {
  d <- consistency_data()
  res <- mysterycall_check_consistency(d, id_col = "record_id",
                                       keep_cols = "office_answered")
  expect_true("office_answered" %in% names(res$report))
})

test_that("clean data yields an empty report", {
  d <- data.frame(
    office_answered     = c(TRUE, TRUE),
    appointment_date    = c("2026-02-01", "2026-02-02"),
    taking_new_patients = c("Yes", "Yes"),
    complete            = c("Complete", "Complete"),
    call_date           = c("2026-01-01", "2026-01-02"),
    caller              = c("AB", "CD"),
    stringsAsFactors = FALSE)
  res <- mysterycall_check_consistency(d)
  expect_equal(nrow(res$report), 0L)
  expect_equal(nrow(res$summary), 0L)
})

test_that("summary counts match the report", {
  d <- consistency_data()
  res <- mysterycall_check_consistency(d)
  expect_equal(sum(res$summary$n), nrow(res$report))
})

test_that("custom column mapping is honoured", {
  d <- data.frame(
    answered_flag = c(FALSE, TRUE),
    appt_dt       = c("2026-02-01", NA),
    stringsAsFactors = FALSE)
  rules <- mysterycall_default_consistency_rules(
    cols = list(answered = "answered_flag", appointment_date = "appt_dt"))
  res <- mysterycall_check_consistency(d, rules = rules)
  expect_true(1 %in% res$report$row)
  expect_equal(as.character(res$report$flag[res$report$row == 1][1]),
               "ANSWER_CONFLICT")
})

test_that("a non-rule element in rules errors", {
  d <- consistency_data()
  expect_error(
    mysterycall_check_consistency(d, rules = list("not a rule")),
    "must be a mysterycall_consistency_rule"
  )
})

test_that("a predicate returning the wrong length errors", {
  d <- consistency_data()
  bad <- mysterycall_consistency_rule(
    flag = "BAD", description = "x", action = "y",
    predicate = function(x) TRUE)  # scalar, not nrow-length
  expect_error(
    mysterycall_check_consistency(d, rules = list(bad)),
    "logical vector of length"
  )
})
