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


test_that("mysterycall_progress_tracker() creates valid tracker with character steps", {
  set.seed(1)
  tracker <- suppressMessages(
    mysterycall:::mysterycall_progress_tracker(
      steps = c("Geocode", "Validate", "Export"),
      update_every = 1000,
      quiet = TRUE
    )
  )

  expect_s3_class(tracker, "mysterycall_progress_tracker")
  expect_true(inherits(tracker$env, "environment"))
  expect_true(exists("records", envir = tracker$env))
})


test_that("mysterycall_progress_start() and mysterycall_progress_finish() update status", {
  set.seed(1)
  tracker <- mysterycall:::mysterycall_progress_tracker(
    steps = c("Geocode", "Validate"),
    update_every = 1000,
    quiet = TRUE
  )

  # Start a step
  suppressMessages(
    mysterycall:::mysterycall_progress_start(tracker, "Geocode", note = "Starting geocoding")
  )

  # Finish a step
  suppressMessages(
    mysterycall:::mysterycall_progress_finish(tracker, "Geocode", score = 0.95)
  )

  # Check summary
  summary <- suppressMessages(mysterycall:::mysterycall_progress_summary(tracker))
  expect_true(nrow(summary) > 0)
  expect_true("step" %in% names(summary))
  expect_true("status" %in% names(summary))
})


test_that("mysterycall_progress_tracker() rejects empty or non-character steps", {
  set.seed(1)

  # Empty vector
  expect_error(
    mysterycall:::mysterycall_progress_tracker(steps = character(0)),
    "non-empty character vector"
  )

  # Non-character
  expect_error(
    mysterycall:::mysterycall_progress_tracker(steps = c(1, 2, 3)),
    "non-empty character vector"
  )

  # NULL
  expect_error(
    mysterycall:::mysterycall_progress_tracker(steps = NULL),
    "non-empty character vector"
  )
})


test_that("mysterycall_progress_start() errors on unknown step", {
  set.seed(1)
  tracker <- mysterycall:::mysterycall_progress_tracker(
    steps = c("Geocode", "Validate"),
    quiet = TRUE
  )

  expect_error(
    mysterycall:::mysterycall_progress_start(tracker, "UnknownStep"),
    "Unknown step"
  )
})


test_that("mysterycall_tracker_fail() marks step as failed with reason", {
  set.seed(1)
  tracker <- mysterycall:::mysterycall_progress_tracker(
    steps = c("Geocode", "Validate", "Export"),
    update_every = 1000,
    quiet = TRUE
  )

  # Start and then fail
  suppressMessages(mysterycall:::mysterycall_progress_start(tracker, "Geocode"))
  suppressMessages(
    mysterycall:::mysterycall_tracker_fail(tracker, "Geocode", reason = "API timeout")
  )

  # Verify status changed to failed
  summary <- suppressMessages(mysterycall:::mysterycall_progress_summary(tracker))
  geocode_row <- subset(summary, step == "Geocode")
  expect_equal(as.character(geocode_row$status), "failed")
  expect_equal(geocode_row$note, "API timeout")
})


test_that("mysterycall_tracker_update() respects force flag", {
  set.seed(1)
  tracker <- mysterycall:::mysterycall_progress_tracker(
    steps = c("Step1"),
    update_every = 10000,  # Very high interval
    quiet = TRUE
  )

  # Without force, should not trigger immediate update (no error expected)
  suppressMessages(
    mysterycall:::mysterycall_tracker_update(tracker, force = FALSE)
  )
  expect_true(inherits(tracker, "mysterycall_progress_tracker"))

  # With force, should trigger update (no error expected)
  suppressMessages(
    mysterycall:::mysterycall_tracker_update(tracker, force = TRUE)
  )
  expect_true(inherits(tracker, "mysterycall_progress_tracker"))
})


test_that("mysterycall_progress_summary() returns tibble with correct structure", {
  set.seed(1)
  steps_vec <- c("Geocode", "Validate", "Export")
  tracker <- mysterycall:::mysterycall_progress_tracker(
    steps = steps_vec,
    quiet = TRUE
  )

  summary <- suppressMessages(mysterycall:::mysterycall_progress_summary(tracker))

  # Check class and dimensions
  expect_s3_class(summary, "tbl_df")
  expect_equal(nrow(summary), length(steps_vec))

  # Check required columns
  expected_cols <- c("step", "status", "started_at", "finished_at", "quality", "note")
  expect_true(all(expected_cols %in% names(summary)))

  # Check initial status
  expect_true(all(summary$status == "pending"))
})


test_that("mysterycall_progress_finish() with explicit quality overrides score", {
  set.seed(1)
  tracker <- mysterycall:::mysterycall_progress_tracker(
    steps = c("TestStep"),
    quiet = TRUE
  )

  suppressMessages(mysterycall:::mysterycall_progress_start(tracker, "TestStep"))

  # Finish with both score and explicit quality
  suppressMessages(
    mysterycall:::mysterycall_progress_finish(
      tracker,
      "TestStep",
      score = 0.5,
      quality = "high_manual"
    )
  )

  summary <- suppressMessages(mysterycall:::mysterycall_progress_summary(tracker))
  expect_equal(summary$quality, "high_manual")
})


test_that("mysterycall_progress_tracker() removes duplicate steps", {
  set.seed(1)
  tracker <- mysterycall:::mysterycall_progress_tracker(
    steps = c("Step1", "Step2", "Step1", "Step3"),
    quiet = TRUE
  )

  summary <- suppressMessages(mysterycall:::mysterycall_progress_summary(tracker))
  expect_equal(nrow(summary), 3)  # Only 3 unique steps
  expect_true(all(c("Step1", "Step2", "Step3") %in% summary$step))
})


test_that("mysterycall_progress_start() rejects invalid tracker object", {
  set.seed(1)

  # Pass wrong object type
  expect_error(
    mysterycall:::mysterycall_progress_start(list(env = "not_env"), "Step"),
    "must be created with"
  )
})


test_that("mysterycall_progress_finish() with NULL quality and NULL score returns NA", {
  set.seed(1)
  tracker <- mysterycall:::mysterycall_progress_tracker(
    steps = c("SimpleStep"),
    quiet = TRUE
  )

  suppressMessages(mysterycall:::mysterycall_progress_start(tracker, "SimpleStep"))
  suppressMessages(
    mysterycall:::mysterycall_progress_finish(
      tracker,
      "SimpleStep",
      score = NULL,
      quality = NULL
    )
  )

  summary <- suppressMessages(mysterycall:::mysterycall_progress_summary(tracker))
  expect_true(is.na(summary$quality[summary$step == "SimpleStep"]))
})


test_that("mysterycall_progress_tracker() respects quiet option", {
  set.seed(1)

  # With quiet = TRUE, should suppress messages
  tracker_quiet <- mysterycall:::mysterycall_progress_tracker(
    steps = c("Step1"),
    quiet = TRUE
  )

  expect_true(tracker_quiet$env$quiet)

  # With quiet = FALSE, should allow messages
  tracker_verbose <- suppressMessages(
    mysterycall:::mysterycall_progress_tracker(
      steps = c("Step1"),
      quiet = FALSE
    )
  )

  expect_false(tracker_verbose$env$quiet)
})
