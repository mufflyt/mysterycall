library(testthat)
library(mysterycall)

# ---------------------------------------------------------------------------
# utils-logging.R — all functions are @keywords internal; accessed via :::
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# mysterycall_format_duration — pure function, no side effects
# ---------------------------------------------------------------------------

test_that("mysterycall_format_duration formats sub-minute durations correctly", {
  expect_equal(mysterycall:::mysterycall_format_duration(0),    "0.0s")
  expect_equal(mysterycall:::mysterycall_format_duration(1),    "1.0s")
  expect_equal(mysterycall:::mysterycall_format_duration(45),   "45.0s")
  expect_equal(mysterycall:::mysterycall_format_duration(59.9), "59.9s")
  # Return type is character
  expect_type(mysterycall:::mysterycall_format_duration(10), "character")
})

test_that("mysterycall_format_duration formats minute-range durations correctly", {
  expect_equal(mysterycall:::mysterycall_format_duration(60),   "1m 0s")
  expect_equal(mysterycall:::mysterycall_format_duration(90),   "1m 30s")
  expect_equal(mysterycall:::mysterycall_format_duration(125),  "2m 5s")
  expect_equal(mysterycall:::mysterycall_format_duration(3599), "59m 59s")
})

test_that("mysterycall_format_duration formats hour-range durations correctly", {
  expect_equal(mysterycall:::mysterycall_format_duration(3600),  "1h 0m 0s")
  expect_equal(mysterycall:::mysterycall_format_duration(3700),  "1h 1m 40s")
  expect_equal(mysterycall:::mysterycall_format_duration(7384),  "2h 3m 4s")
})

# ---------------------------------------------------------------------------
# mysterycall_use_quiet_logging — sets option, returns previous value
# ---------------------------------------------------------------------------

test_that("mysterycall_use_quiet_logging sets option and returns previous value", {
  # Reset to a known state first
  options(mysterycall.quiet = FALSE)

  old <- mysterycall:::mysterycall_use_quiet_logging(TRUE)
  expect_false(old)                                    # returned the old FALSE
  expect_true(getOption("mysterycall.quiet"))          # option is now TRUE

  restored <- mysterycall:::mysterycall_use_quiet_logging(FALSE)
  expect_true(restored)                                # returned the old TRUE
  expect_false(getOption("mysterycall.quiet"))         # option restored
})

# ---------------------------------------------------------------------------
# Message-emitting helpers — verify they produce messages and return invisibly
# ---------------------------------------------------------------------------

test_that("mysterycall_log_info emits a message containing the supplied text", {
  expect_message(
    mysterycall:::mysterycall_log_info("test info message"),
    "test info message"
  )
})

test_that("mysterycall_log_success emits a message with optional details", {
  # Plain success
  expect_message(
    mysterycall:::mysterycall_log_success("all done"),
    "all done"
  )

  # With named details — extra lines are also emitted as messages
  suppressMessages({
    result <- mysterycall:::mysterycall_log_success(
      "geocoding complete",
      details = list(n = 120, skipped = 3)
    )
  })
  expect_null(result)   # invisible(NULL) returns NULL
})

test_that("mysterycall_log_warning emits a message containing WARNING", {
  expect_message(
    mysterycall:::mysterycall_log_warning("missing key"),
    "WARNING"
  )
  expect_message(
    mysterycall:::mysterycall_log_warning("missing key", fix = "set env var"),
    "Fix"
  )
})

test_that("mysterycall_log_error emits a message containing ERROR with optional cause and fix", {
  expect_message(
    mysterycall:::mysterycall_log_error("geocode failed"),
    "ERROR"
  )
  expect_message(
    mysterycall:::mysterycall_log_error("geocode failed",
                                        cause = "bad key",
                                        fix   = "renew key"),
    "Cause"
  )
})

# ---------------------------------------------------------------------------
# mysterycall_log_progress — progress line formatting
# ---------------------------------------------------------------------------

test_that("mysterycall_log_progress emits a message with current/total and percent", {
  expect_message(
    mysterycall:::mysterycall_log_progress(50, 100),
    "50/100"
  )
  expect_message(
    mysterycall:::mysterycall_log_progress(50, 100),
    "50.0%"
  )
  expect_message(
    mysterycall:::mysterycall_log_progress(50, 100, status = "geocoding"),
    "geocoding"
  )
  # show_percent = FALSE should not include a percent sign
  msg <- suppressMessages(
    capture.output(
      suppressWarnings(mysterycall:::mysterycall_log_progress(10, 20, show_percent = FALSE)),
      type = "message"
    )
  )
  expect_false(any(grepl("%", msg)))
})

test_that("mysterycall_log_progress handles zero total without error", {
  expect_message(
    mysterycall:::mysterycall_log_progress(0, 0),
    "0/0"
  )
})

# ---------------------------------------------------------------------------
# Workflow lifecycle — start → log step → complete step → end
# ---------------------------------------------------------------------------

test_that("full workflow lifecycle runs without error and emits messages", {
  expect_message(
    mysterycall:::mysterycall_workflow_start("Test Workflow", total_steps = 2),
    "Test Workflow"
  )

  suppressMessages(mysterycall:::mysterycall_log_step("Step A", n_items = 10))
  suppressMessages(mysterycall:::mysterycall_log_step_complete(n_success = 9, n_total = 10))

  suppressMessages(mysterycall:::mysterycall_log_step("Step B"))
  suppressMessages(mysterycall:::mysterycall_log_step_complete(success_rate = 0.95))

  expect_message(
    mysterycall:::mysterycall_workflow_end(final_n = 9, input_n = 10),
    "COMPLETE"
  )
})

test_that("mysterycall_workflow_end returns invisibly when no workflow has started", {
  # Clear any existing workflow state
  .mysterycall_env <- getFromNamespace(".mysterycall_workflow", "mysterycall")
  rm(list = ls(.mysterycall_env), envir = .mysterycall_env)

  result <- mysterycall:::mysterycall_workflow_end()
  expect_null(result)
})

# ---------------------------------------------------------------------------
# mysterycall_log_to_file — writes to file when log_file is configured
# ---------------------------------------------------------------------------

test_that("mysterycall_log_to_file writes to a temp log file", {
  log_path <- tempfile(fileext = ".log")

  suppressMessages(
    mysterycall:::mysterycall_workflow_start("File Log Test",
                                             total_steps = 1,
                                             log_file    = log_path)
  )

  mysterycall:::mysterycall_log_to_file("hello from test")

  expect_true(file.exists(log_path))
  lines <- readLines(log_path)
  expect_true(any(grepl("hello from test", lines)))

  # Clean up
  unlink(log_path)
})

# ---------------------------------------------------------------------------
# mysterycall_progress_callback — returns a function; that function updates state
# ---------------------------------------------------------------------------

test_that("mysterycall_progress_callback returns a callable function", {
  cb <- mysterycall:::mysterycall_progress_callback(10, "Test")
  expect_true(is.function(cb))
})

test_that("mysterycall_progress_callback handles zero total gracefully", {
  cb <- mysterycall:::mysterycall_progress_callback(0)
  # Calling with current = 0 on a zero-total callback should be silent
  expect_silent(cb(0))
})
