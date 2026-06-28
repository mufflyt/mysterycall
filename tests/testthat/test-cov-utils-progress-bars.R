library(testthat)
library(mysterycall)

# All progress-bar helpers are @keywords internal; access via :::

# ---------------------------------------------------------------------------
# Test 1 – mysterycall_multi_progress: happy path
# ---------------------------------------------------------------------------
test_that("mysterycall_multi_progress creates a tracker with correct structure", {
  steps <- c("Load Data", "Process", "Save Results")
  tr <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_multi_progress(steps)
  ))

  expect_s3_class(tr, "mysterycall_multi_progress")
  expect_equal(tr$total_steps, 3L)
  expect_equal(tr$current_step, 0L)
  expect_equal(tr$steps, steps)
  expect_null(tr$step_pb)
  expect_true(is.logical(tr$show_overall))
})

# ---------------------------------------------------------------------------
# Test 2 – mysterycall_progress_bar: returns mysterycall_progress object
# ---------------------------------------------------------------------------
test_that("mysterycall_progress_bar returns a mysterycall_progress with expected fields", {
  pb <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_progress_bar("Test operation", total = 20L)
  ))

  expect_s3_class(pb, "mysterycall_progress")
  expect_equal(pb$total,   20L)
  expect_equal(pb$current, 0L)
  expect_equal(pb$name,    "Test operation")
  expect_true(is.logical(pb$use_cli))
  # start_time must be a POSIXct timestamp
  expect_s3_class(pb$start_time, "POSIXct")
})

# ---------------------------------------------------------------------------
# Test 3 – mysterycall_multi_step: errors on out-of-range step number
# ---------------------------------------------------------------------------
test_that("mysterycall_multi_step errors when step_num is out of range", {
  tr <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_multi_progress(c("Step A", "Step B"))
  ))

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall:::mysterycall_multi_step(tr, step_num = 5L, total = 10L)
    )),
    regexp = "out of range"
  )

  expect_error(
    suppressMessages(suppressWarnings(
      mysterycall:::mysterycall_multi_step(tr, step_num = 0L, total = 10L)
    )),
    regexp = "out of range"
  )
})

# ---------------------------------------------------------------------------
# Test 4 – mysterycall_progress_map: applies function and returns correct list
# ---------------------------------------------------------------------------
test_that("mysterycall_progress_map returns list of correct results", {
  set.seed(119)
  result <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_progress_map(
      items = 1:6,
      fn    = function(x) x * x,
      name  = "Computing squares"
    )
  ))

  expect_type(result, "list")
  expect_length(result, 6L)
  expect_equal(result[[1]], 1L)
  expect_equal(result[[3]], 9L)
  expect_equal(result[[6]], 36L)
})

# ---------------------------------------------------------------------------
# Test 5 – full multi-step workflow completes without error
# ---------------------------------------------------------------------------
test_that("multi-progress full workflow runs without error and resets step_pb", {
  tr <- suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_multi_progress(c("Geocode", "Validate"))
  ))

  # Step 1
  suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_multi_step(tr, step_num = 1L, total = 3L,
                                        detail = "geocoding addresses")
  ))
  expect_equal(tr$current_step, 1L)
  expect_s3_class(tr$step_pb, "mysterycall_progress")

  for (i in seq_len(3L)) {
    suppressMessages(suppressWarnings(
      mysterycall:::mysterycall_multi_update(tr)
    ))
  }

  suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_multi_complete(tr, result = "3 rows geocoded")
  ))
  expect_null(tr$step_pb)   # cleared after complete

  # Final done
  expect_invisible(suppressMessages(suppressWarnings(
    mysterycall:::mysterycall_multi_done(tr)
  )))
})
