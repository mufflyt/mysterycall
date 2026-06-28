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

# Test 1: Create a progress tracker - happy path
test_that("mysterycall_progress_tracker creates valid S3 object", {
  tracker <- mysterycall_progress_tracker(c("Step1", "Step2", "Step3"))
  expect_s3_class(tracker, "mysterycall_progress_tracker")
  expect_true(is.list(tracker))
  expect_true(exists("env", where = tracker))
})

# Test 2: Progress tracker records initialization
test_that("mysterycall_progress_tracker initializes records tibble correctly", {
  tracker <- mysterycall_progress_tracker(c("Alpha", "Beta"))
  summary <- mysterycall_progress_summary(tracker)
  expect_equal(nrow(summary), 2L)
  expect_equal(summary$step, c("Alpha", "Beta"))
  expect_true(all(summary$status == "pending"))
  expect_true(all(is.na(summary$started_at)))
  expect_true(all(is.na(summary$finished_at)))
})

# Test 3: Start a step
test_that("mysterycall_progress_start marks step as in_progress", {
  tracker <- mysterycall_progress_tracker(c("Task1"))
  suppressMessages(mysterycall_progress_start(tracker, "Task1", note = "Starting task"))
  summary <- mysterycall_progress_summary(tracker)
  expect_equal(as.character(summary$status[1]), "in_progress")
  expect_equal(summary$note[1], "Starting task")
  expect_false(is.na(summary$started_at[1]))
})

# Test 4: Finish a step with score
test_that("mysterycall_progress_finish marks step completed with quality", {
  tracker <- mysterycall_progress_tracker(c("Work"))
  suppressMessages(mysterycall_progress_start(tracker, "Work"))
  suppressMessages(mysterycall_progress_finish(tracker, "Work", score = 0.95))
  summary <- mysterycall_progress_summary(tracker)
  expect_equal(as.character(summary$status[1]), "completed")
  expect_false(is.na(summary$finished_at[1]))
  expect_false(is.na(summary$quality[1]))
})

# Test 5: Finish a step with explicit quality overrides score
test_that("mysterycall_progress_finish with explicit quality overrides score", {
  tracker <- mysterycall_progress_tracker(c("Check"))
  suppressMessages(mysterycall_progress_start(tracker, "Check"))
  suppressMessages(mysterycall_progress_finish(tracker, "Check", score = 0.5, quality = "Excellent"))
  summary <- mysterycall_progress_summary(tracker)
  expect_equal(summary$quality[1], "Excellent")
})

# Test 6: Mark step as failed
test_that("mysterycall_tracker_fail marks step as failed", {
  tracker <- mysterycall_progress_tracker(c("Risky"))
  suppressMessages(mysterycall_progress_start(tracker, "Risky"))
  suppressMessages(mysterycall_tracker_fail(tracker, "Risky", reason = "Timeout occurred"))
  summary <- mysterycall_progress_summary(tracker)
  expect_equal(as.character(summary$status[1]), "failed")
  expect_equal(summary$note[1], "Timeout occurred")
  expect_false(is.na(summary$finished_at[1]))
})

# Test 7: Update tracker with heartbeat
test_that("mysterycall_tracker_update emits progress update", {
  tracker <- mysterycall_progress_tracker(c("X", "Y"), update_every = 1e9)
  suppressMessages(mysterycall_progress_start(tracker, "X"))
  suppressMessages(mysterycall_progress_finish(tracker, "X"))
  expect_invisible(suppressMessages(mysterycall_tracker_update(tracker, force = TRUE)))
})

# Test 8: Progress tracker with duplicates removes them
test_that("mysterycall_progress_tracker removes duplicate steps", {
  tracker <- mysterycall_progress_tracker(c("A", "B", "A", "C"))
  summary <- mysterycall_progress_summary(tracker)
  expect_equal(nrow(summary), 3L)
  expect_equal(summary$step, c("A", "B", "C"))
})

# Test 9: Progress tracker with quiet flag
test_that("mysterycall_progress_tracker respects quiet flag", {
  tracker <- mysterycall_progress_tracker(c("Silent"), quiet = TRUE)
  expect_equal(tracker$env$quiet, TRUE)
})

# Test 10: Error on non-character steps
test_that("mysterycall_progress_tracker errors on non-character steps", {
  expect_error(
    mysterycall_progress_tracker(c(1, 2, 3)),
    "`steps` must be a non-empty character vector."
  )
})

# Test 11: Error on empty steps
test_that("mysterycall_progress_tracker errors on empty steps", {
  expect_error(
    mysterycall_progress_tracker(character(0)),
    "`steps` must be a non-empty character vector."
  )
})

# Test 12: Error on unknown step in progress_start
test_that("mysterycall_progress_start errors on unknown step", {
  tracker <- mysterycall_progress_tracker(c("Known"))
  expect_error(
    mysterycall_progress_start(tracker, "Unknown"),
    "Unknown step 'Unknown'."
  )
})

# Test 13: Error on unknown step in progress_finish
test_that("mysterycall_progress_finish errors on unknown step", {
  tracker <- mysterycall_progress_tracker(c("Known"))
  expect_error(
    mysterycall_progress_finish(tracker, "Unknown"),
    "Unknown step 'Unknown'."
  )
})

# Test 14: Error on unknown step in tracker_fail
test_that("mysterycall_tracker_fail errors on unknown step", {
  tracker <- mysterycall_progress_tracker(c("Known"))
  expect_error(
    mysterycall_tracker_fail(tracker, "Unknown"),
    "Unknown step 'Unknown'."
  )
})

# Test 15: Error on invalid tracker object
test_that("mysterycall_progress_start errors on invalid tracker", {
  expect_error(
    mysterycall_progress_start(list(), "Step"),
    "`tracker` must be created with mysterycall_progress_tracker()."
  )
})

# Test 16: Progress summary returns tibble
test_that("mysterycall_progress_summary returns tibble", {
  tracker <- mysterycall_progress_tracker(c("A", "B"))
  summary <- mysterycall_progress_summary(tracker)
  expect_s3_class(summary, c("tbl_df", "tbl", "data.frame"))
  expect_equal(ncol(summary), 6L)
  expect_named(summary, c("step", "status", "started_at", "finished_at", "quality", "note"))
})

# Test 17: Multiple steps can be managed independently
test_that("multiple steps can be managed independently", {
  tracker <- mysterycall_progress_tracker(c("First", "Second", "Third"))
  suppressMessages({
    mysterycall_progress_start(tracker, "First")
    mysterycall_progress_finish(tracker, "First", score = 0.9)
    mysterycall_progress_start(tracker, "Second")
  })
  summary <- mysterycall_progress_summary(tracker)
  expect_equal(as.character(summary$status[1]), "completed")
  expect_equal(as.character(summary$status[2]), "in_progress")
  expect_equal(as.character(summary$status[3]), "pending")
})

# Test 18: Finish step without prior start
test_that("mysterycall_progress_finish works on pending step", {
  tracker <- mysterycall_progress_tracker(c("Jump"))
  suppressMessages(mysterycall_progress_finish(tracker, "Jump", score = 0.8))
  summary <- mysterycall_progress_summary(tracker)
  expect_equal(as.character(summary$status[1]), "completed")
})

# Test 19: Fail step without prior start
test_that("mysterycall_tracker_fail works on pending step", {
  tracker <- mysterycall_progress_tracker(c("Pending"))
  suppressMessages(mysterycall_tracker_fail(tracker, "Pending", reason = "Never started"))
  summary <- mysterycall_progress_summary(tracker)
  expect_equal(as.character(summary$status[1]), "failed")
})

# Test 20: Tracker functions return invisibly
test_that("tracker functions return invisibly", {
  tracker <- mysterycall_progress_tracker(c("A", "B"))
  expect_invisible(suppressMessages(mysterycall_progress_start(tracker, "A")))
  expect_invisible(suppressMessages(mysterycall_progress_finish(tracker, "B")))
  expect_invisible(suppressMessages(mysterycall_tracker_fail(tracker, "B")))
  expect_invisible(suppressMessages(mysterycall_tracker_update(tracker)))
})

# Test 21: Update_every parameter is stored
test_that("mysterycall_progress_tracker stores update_every parameter", {
  tracker <- mysterycall_progress_tracker(c("X"), update_every = 60)
  expect_equal(tracker$env$update_every, 60)
})

# Test 22: Start without note
test_that("mysterycall_progress_start without note keeps NA", {
  tracker <- mysterycall_progress_tracker(c("NoNote"))
  suppressMessages(mysterycall_progress_start(tracker, "NoNote"))
  summary <- mysterycall_progress_summary(tracker)
  expect_true(is.na(summary$note[1]))
})

# Test 23: Finish without score or quality
test_that("mysterycall_progress_finish without score or quality", {
  tracker <- mysterycall_progress_tracker(c("NoScore"))
  suppressMessages(mysterycall_progress_finish(tracker, "NoScore"))
  summary <- mysterycall_progress_summary(tracker)
  expect_equal(as.character(summary$status[1]), "completed")
})

# Test 24: Fail without reason
test_that("mysterycall_tracker_fail without reason keeps NA", {
  tracker <- mysterycall_progress_tracker(c("NoReason"))
  suppressMessages(mysterycall_tracker_fail(tracker, "NoReason"))
  summary <- mysterycall_progress_summary(tracker)
  expect_true(is.na(summary$note[1]))
})
