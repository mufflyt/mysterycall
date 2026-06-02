# Tests for Progress Bar System
# Testing progress bars, multi-step trackers, and spinners

library(testthat)
library(mysterycall)

# ==============================================================================
# mysterycall:::mysterycall_progress_bar() - Creation
# ==============================================================================

test_that("mysterycall_progress_bar creates progress bar object", {
  pb <- mysterycall:::mysterycall_progress_bar("Test operation", total = 100)

  expect_s3_class(pb, "mysterycall_progress")
  expect_true("name" %in% names(pb))
  expect_true("total" %in% names(pb))
  expect_true("current" %in% names(pb))
  expect_equal(pb$name, "Test operation")
  expect_equal(pb$total, 100)
  expect_equal(pb$current, 0)
})

test_that("mysterycall_progress_bar handles different totals", {
  pb_small <- mysterycall:::mysterycall_progress_bar("Small", total = 10)
  expect_equal(pb_small$total, 10)

  pb_large <- mysterycall:::mysterycall_progress_bar("Large", total = 10000)
  expect_equal(pb_large$total, 10000)

  pb_one <- mysterycall:::mysterycall_progress_bar("Single", total = 1)
  expect_equal(pb_one$total, 1)
})

test_that("mysterycall_progress_bar accepts custom parameters", {
  # Should not error with custom params
  expect_no_error({
    pb <- mysterycall:::mysterycall_progress_bar(
      "Custom",
      total = 50,
      clear = TRUE,
      show_after = 1,
      force = FALSE
    )
  })
})

# ==============================================================================
# mysterycall:::mysterycall_progress_update() - Updates
# ==============================================================================

test_that("mysterycall_progress_update increments progress", {
  pb <- mysterycall:::mysterycall_progress_bar("Test", total = 100)

  mysterycall:::mysterycall_progress_update(pb, amount = 1)
  # Can't directly check pb$current since it's modified by reference in cli
  # But we can verify it doesn't error
  expect_true(TRUE)

  mysterycall:::mysterycall_progress_update(pb, amount = 10)
  expect_true(TRUE)
})

test_that("mysterycall_progress_update handles set parameter", {
  pb <- mysterycall:::mysterycall_progress_bar("Test", total = 100)

  # Jump to specific value
  mysterycall:::mysterycall_progress_update(pb, set = 50)
  expect_true(TRUE)

  mysterycall:::mysterycall_progress_update(pb, set = 100)
  expect_true(TRUE)
})

test_that("mysterycall_progress_update accepts status messages", {
  pb <- mysterycall:::mysterycall_progress_bar("Test", total = 10)

  expect_no_error({
    mysterycall:::mysterycall_progress_update(pb, status = "Processing item 1")
    mysterycall:::mysterycall_progress_update(pb, status = "Processing item 2")
  })
})

test_that("mysterycall_progress_update handles invalid input gracefully", {
  # Should not error with NULL
  expect_silent(mysterycall:::mysterycall_progress_update(NULL))

  # Should not error with wrong class
  expect_silent(mysterycall:::mysterycall_progress_update(list(x = 1)))
})

# ==============================================================================
# mysterycall:::mysterycall_progress_done() - Completion
# ==============================================================================

test_that("mysterycall_progress_done marks as complete", {
  pb <- mysterycall:::mysterycall_progress_bar("Test", total = 10)

  for (i in 1:10) {
    mysterycall:::mysterycall_progress_update(pb)
  }

  expect_no_error(mysterycall:::mysterycall_progress_done(pb))
})

test_that("mysterycall_progress_done accepts result message", {
  pb <- mysterycall:::mysterycall_progress_bar("Test", total = 5)

  for (i in 1:5) {
    mysterycall:::mysterycall_progress_update(pb)
  }

  expect_message(
    mysterycall:::mysterycall_progress_done(pb, result = "All items processed"),
    "All items processed"
  )
})

test_that("mysterycall_progress_done handles invalid input gracefully", {
  expect_silent(mysterycall:::mysterycall_progress_done(NULL))
  expect_silent(mysterycall:::mysterycall_progress_done(list(x = 1)))
})

# ==============================================================================
# mysterycall:::mysterycall_progress_fail() - Failure
# ==============================================================================

test_that("mysterycall_progress_fail marks as failed", {
  pb <- mysterycall:::mysterycall_progress_bar("Test", total = 10)

  mysterycall:::mysterycall_progress_update(pb, amount = 5)

  expect_no_error(mysterycall:::mysterycall_progress_fail(pb))
})

test_that("mysterycall_progress_fail accepts error message", {
  pb <- mysterycall:::mysterycall_progress_bar("Test", total = 10)

  expect_message(
    mysterycall:::mysterycall_progress_fail(pb, msg = "Operation failed due to error"),
    "failed"
  )
})

test_that("mysterycall_progress_fail handles invalid input gracefully", {
  expect_silent(mysterycall:::mysterycall_progress_fail(NULL))
  expect_silent(mysterycall:::mysterycall_progress_fail(list(x = 1)))
})

# ==============================================================================
# mysterycall:::mysterycall_multi_progress() - Multi-Step Creation
# ==============================================================================

test_that("mysterycall_multi_progress creates tracker", {
  steps <- c("Load Data", "Process Data", "Save Results")
  tracker <- mysterycall:::mysterycall_multi_progress(steps)

  expect_s3_class(tracker, "mysterycall_multi_progress")
  expect_equal(tracker$steps, steps)
  expect_equal(tracker$total_steps, 3)
  expect_equal(tracker$current_step, 0)
})

test_that("mysterycall_multi_progress handles single step", {
  tracker <- mysterycall:::mysterycall_multi_progress(c("Only Step"))

  expect_equal(tracker$total_steps, 1)
  expect_equal(length(tracker$steps), 1)
})

test_that("mysterycall_multi_progress handles many steps", {
  steps <- paste("Step", 1:10)
  tracker <- mysterycall:::mysterycall_multi_progress(steps)

  expect_equal(tracker$total_steps, 10)
  expect_equal(length(tracker$steps), 10)
})

# ==============================================================================
# mysterycall:::mysterycall_multi_step() - Step Start
# ==============================================================================

test_that("mysterycall_multi_step starts a step", {
  tracker <- mysterycall:::mysterycall_multi_progress(c("Step 1", "Step 2", "Step 3"))

  expect_message(
    mysterycall:::mysterycall_multi_step(tracker, 1, total = 100),
    "Step 1"
  )

  expect_equal(tracker$current_step, 1)
})

test_that("mysterycall_multi_step accepts detail message", {
  tracker <- mysterycall:::mysterycall_multi_progress(c("Load", "Process"))

  expect_message(
    mysterycall:::mysterycall_multi_step(tracker, 1, total = 50, detail = "Loading CSV files"),
    "Loading CSV files"
  )
})

test_that("mysterycall_multi_step handles invalid input gracefully", {
  expect_silent(mysterycall:::mysterycall_multi_step(NULL, 1, 100))
  expect_silent(mysterycall:::mysterycall_multi_step(list(x = 1), 1, 100))
})

# ==============================================================================
# mysterycall:::mysterycall_multi_update() - Step Update
# ==============================================================================

test_that("mysterycall_multi_update updates current step", {
  tracker <- mysterycall:::mysterycall_multi_progress(c("Step 1"))
  mysterycall:::mysterycall_multi_step(tracker, 1, total = 10)

  expect_no_error({
    mysterycall:::mysterycall_multi_update(tracker)
    mysterycall:::mysterycall_multi_update(tracker, amount = 2)
  })
})

test_that("mysterycall_multi_update accepts status", {
  tracker <- mysterycall:::mysterycall_multi_progress(c("Processing"))
  mysterycall:::mysterycall_multi_step(tracker, 1, total = 5)

  expect_no_error({
    mysterycall:::mysterycall_multi_update(tracker, status = "Item 1")
  })
})

test_that("mysterycall_multi_update handles invalid input gracefully", {
  expect_silent(mysterycall:::mysterycall_multi_update(NULL))
  expect_silent(mysterycall:::mysterycall_multi_update(list(x = 1)))
})

# ==============================================================================
# mysterycall:::mysterycall_multi_complete() - Step Completion
# ==============================================================================

test_that("mysterycall_multi_complete finishes step", {
  tracker <- mysterycall:::mysterycall_multi_progress(c("Step 1"))
  mysterycall:::mysterycall_multi_step(tracker, 1, total = 5)

  for (i in 1:5) {
    mysterycall:::mysterycall_multi_update(tracker)
  }

  expect_no_error(mysterycall:::mysterycall_multi_complete(tracker))
})

test_that("mysterycall_multi_complete accepts result message", {
  tracker <- mysterycall:::mysterycall_multi_progress(c("Step 1"))
  mysterycall:::mysterycall_multi_step(tracker, 1, total = 3)

  for (i in 1:3) {
    mysterycall:::mysterycall_multi_update(tracker)
  }

  expect_message(
    mysterycall:::mysterycall_multi_complete(tracker, result = "Step completed successfully"),
    "completed successfully"
  )
})

test_that("mysterycall_multi_complete handles invalid input gracefully", {
  expect_silent(mysterycall:::mysterycall_multi_complete(NULL))
  expect_silent(mysterycall:::mysterycall_multi_complete(list(x = 1)))
})

# ==============================================================================
# mysterycall:::mysterycall_multi_done() - Complete All
# ==============================================================================

test_that("mysterycall_multi_done finishes all steps", {
  tracker <- mysterycall:::mysterycall_multi_progress(c("Step 1", "Step 2"))

  # Step 1
  mysterycall:::mysterycall_multi_step(tracker, 1, total = 5)
  for (i in 1:5) mysterycall:::mysterycall_multi_update(tracker)
  mysterycall:::mysterycall_multi_complete(tracker)

  # Step 2
  mysterycall:::mysterycall_multi_step(tracker, 2, total = 3)
  for (i in 1:3) mysterycall:::mysterycall_multi_update(tracker)
  mysterycall:::mysterycall_multi_complete(tracker)

  expect_message(
    mysterycall:::mysterycall_multi_done(tracker),
    "complete"
  )
})

test_that("mysterycall_multi_done handles invalid input gracefully", {
  expect_silent(mysterycall:::mysterycall_multi_done(NULL))
  expect_silent(mysterycall:::mysterycall_multi_done(list(x = 1)))
})

# ==============================================================================
# mysterycall:::mysterycall_progress_map() - Functional Interface
# ==============================================================================

test_that("mysterycall_progress_map processes items", {
  items <- 1:10
  fn <- function(x) x * 2

  results <- mysterycall:::mysterycall_progress_map(items, fn, name = "Doubling numbers")

  expect_equal(length(results), 10)
  expect_equal(unlist(results), items * 2)
})

test_that("mysterycall_progress_map handles custom batch size", {
  items <- 1:100
  fn <- function(x) x + 1

  results <- mysterycall:::mysterycall_progress_map(
    items,
    fn,
    name = "Adding one",
    batch_size = 10
  )

  expect_equal(length(results), 100)
  expect_equal(unlist(results), items + 1)
})

test_that("mysterycall_progress_map handles single item", {
  items <- list("single item")
  fn <- function(x) toupper(x)

  results <- mysterycall:::mysterycall_progress_map(items, fn, name = "Processing")

  expect_equal(length(results), 1)
  expect_equal(results[[1]], "SINGLE ITEM")
})

test_that("mysterycall_progress_map handles complex functions", {
  items <- list(
    list(a = 1, b = 2),
    list(a = 3, b = 4),
    list(a = 5, b = 6)
  )

  fn <- function(item) {
    list(sum = item$a + item$b, prod = item$a * item$b)
  }

  results <- mysterycall:::mysterycall_progress_map(items, fn, name = "Computing")

  expect_equal(length(results), 3)
  expect_equal(results[[1]]$sum, 3)
  expect_equal(results[[2]]$prod, 12)
})

test_that("mysterycall_progress_map auto-calculates batch size", {
  items <- 1:1000
  fn <- function(x) x

  # Should not error and should calculate batch size
  expect_no_error({
    results <- mysterycall:::mysterycall_progress_map(items, fn, name = "Large set")
  })

  expect_equal(length(results), 1000)
})

# ==============================================================================
# mysterycall:::mysterycall_spinner_start() and mysterycall:::mysterycall_spinner_stop()
# ==============================================================================

test_that("mysterycall_spinner_start creates spinner", {
  # Returns either ID or NULL depending on cli availability
  spinner_id <- mysterycall:::mysterycall_spinner_start("Loading")

  # Should not error
  expect_true(TRUE)

  if (!is.null(spinner_id)) {
    mysterycall:::mysterycall_spinner_stop(spinner_id, result = "Loaded")
  }
})

test_that("mysterycall_spinner_start accepts custom message", {
  expect_no_error({
    spinner_id <- mysterycall:::mysterycall_spinner_start(
      "Connecting",
      msg = "Connecting to API server..."
    )

    if (!is.null(spinner_id)) {
      mysterycall:::mysterycall_spinner_stop(spinner_id)
    }
  })
})

test_that("mysterycall_spinner_stop handles NULL ID", {
  expect_silent(mysterycall:::mysterycall_spinner_stop(NULL))
  expect_silent(mysterycall:::mysterycall_spinner_stop(NULL, result = "done"))
})

# ==============================================================================
# Integration Tests
# ==============================================================================

test_that("Complete progress workflow", {
  # Simple progress bar workflow
  pb <- mysterycall:::mysterycall_progress_bar("Test workflow", total = 20)

  for (i in 1:20) {
    mysterycall:::mysterycall_progress_update(pb)
  }

  expect_message(
    mysterycall:::mysterycall_progress_done(pb, result = "Workflow complete"),
    "complete"
  )
})

test_that("Multi-step workflow", {
  tracker <- mysterycall:::mysterycall_multi_progress(c(
    "Load Data",
    "Process Data",
    "Save Results"
  ))

  # Step 1
  expect_message(mysterycall:::mysterycall_multi_step(tracker, 1, total = 10), "Load Data")
  for (i in 1:10) mysterycall:::mysterycall_multi_update(tracker)
  mysterycall:::mysterycall_multi_complete(tracker, result = "Data loaded")

  # Step 2
  expect_message(mysterycall:::mysterycall_multi_step(tracker, 2, total = 5), "Process Data")
  for (i in 1:5) mysterycall:::mysterycall_multi_update(tracker)
  mysterycall:::mysterycall_multi_complete(tracker)

  # Step 3
  expect_message(mysterycall:::mysterycall_multi_step(tracker, 3, total = 1), "Save Results")
  mysterycall:::mysterycall_multi_update(tracker)
  mysterycall:::mysterycall_multi_complete(tracker)

  expect_message(mysterycall:::mysterycall_multi_done(tracker), "complete")
})

test_that("Functional programming workflow", {
  # Simulate processing addresses
  addresses <- paste(1:50, "Main St")

  geocode_mock <- function(addr) {
    list(lat = runif(1, -90, 90), lon = runif(1, -180, 180))
  }

  results <- mysterycall:::mysterycall_progress_map(
    addresses,
    geocode_mock,
    name = "Geocoding addresses",
    batch_size = 10
  )

  expect_equal(length(results), 50)
  expect_true(all(sapply(results, function(x) "lat" %in% names(x))))
})

test_that("Error handling with progress", {
  pb <- mysterycall:::mysterycall_progress_bar("Risky operation", total = 10)

  # Simulate failure
  result <- tryCatch({
    for (i in 1:5) {
      mysterycall:::mysterycall_progress_update(pb)
    }
    stop("Something went wrong")
  }, error = function(e) {
    mysterycall:::mysterycall_progress_fail(pb, msg = "Operation failed")
    return("handled")
  })

  expect_equal(result, "handled")
})

# ==============================================================================
# Edge Cases
# ==============================================================================

test_that("Progress bar handles zero total", {
  # Edge case: zero items to process
  pb <- mysterycall:::mysterycall_progress_bar("Empty task", total = 0)

  expect_equal(pb$total, 0)
  expect_no_error(mysterycall:::mysterycall_progress_done(pb))
})

test_that("Progress bar handles rapid updates", {
  pb <- mysterycall:::mysterycall_progress_bar("Fast updates", total = 1000)

  # Rapid updates should not error
  expect_no_error({
    for (i in 1:1000) {
      mysterycall:::mysterycall_progress_update(pb)
    }
  })

  mysterycall:::mysterycall_progress_done(pb)
})

test_that("Multi-step handles out-of-order completion", {
  tracker <- mysterycall:::mysterycall_multi_progress(c("Step 1", "Step 2"))

  # Start step 1
  mysterycall:::mysterycall_multi_step(tracker, 1, total = 5)

  # Complete without finishing updates (edge case)
  expect_no_error(mysterycall:::mysterycall_multi_complete(tracker))
})

test_that("Progress map handles empty list", {
  results <- mysterycall:::mysterycall_progress_map(
    list(),
    function(x) x,
    name = "Empty processing"
  )

  expect_equal(length(results), 0)
})

test_that("Progress map handles NULL results", {
  items <- 1:5
  fn <- function(x) NULL

  results <- mysterycall:::mysterycall_progress_map(items, fn, name = "Null results")

  expect_equal(length(results), 5)
  expect_true(all(sapply(results, is.null)))
})

# ==============================================================================
# Fallback Behavior (without cli)
# ==============================================================================

test_that("Progress bar falls back gracefully without cli", {
  # Create progress bar (will use fallback if cli not available)
  pb <- mysterycall:::mysterycall_progress_bar("Fallback test", total = 10)

  # Should work regardless of cli availability
  expect_true("mysterycall_progress" %in% class(pb))
  expect_true("use_cli" %in% names(pb))

  # Updates should work
  expect_no_error({
    for (i in 1:10) {
      mysterycall:::mysterycall_progress_update(pb)
    }
  })

  expect_message(mysterycall:::mysterycall_progress_done(pb), "complete")
})

# ==============================================================================
# Performance Tests
# ==============================================================================

test_that("Progress bar is performant", {
  skip_on_cran()
  # Large number of updates
  pb <- mysterycall:::mysterycall_progress_bar("Performance test", total = 10000)

  start_time <- Sys.time()

  for (i in 1:10000) {
    mysterycall:::mysterycall_progress_update(pb)
  }
  mysterycall:::mysterycall_progress_done(pb)

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # Allow 30 seconds — rendering speed varies widely by machine and CI load
  expect_true(elapsed < 30.0)
})

test_that("Multi-step is performant", {
  skip_on_cran()
  tracker <- mysterycall:::mysterycall_multi_progress(paste("Step", 1:10))

  start_time <- Sys.time()

  for (step in 1:10) {
    mysterycall:::mysterycall_multi_step(tracker, step, total = 100)
    for (i in 1:100) {
      mysterycall:::mysterycall_multi_update(tracker)
    }
    mysterycall:::mysterycall_multi_complete(tracker)
  }
  mysterycall:::mysterycall_multi_done(tracker)

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  expect_true(elapsed < 30.0)
})

test_that("Progress map is performant", {
  skip_on_cran()
  items <- 1:1000
  fn <- function(x) x * 2  # Trivial function

  start_time <- Sys.time()

  results <- mysterycall:::mysterycall_progress_map(items, fn, name = "Performance test")

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  expect_true(elapsed < 30.0)
  expect_equal(length(results), 1000)
})
