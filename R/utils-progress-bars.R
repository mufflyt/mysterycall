#' Beautiful Progress Bars for mysterycall
#'
#' Provides animated progress bars with ETA calculations using the cli package.
#' Integrates seamlessly with the logging framework for a modern CLI experience.
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name progress-bars
NULL

#' Create a beautiful progress bar
#'
#' Creates an animated progress bar with ETA, percentage, and custom formatting.
#' Uses the cli package for cross-platform compatibility and beautiful output.
#'
#' @param name Name/description of the operation
#' @param total Total number of items to process
#' @param format Custom format string (uses cli::cli_progress_bar format)
#' @param clear Whether to clear the progress bar when done (default: FALSE)
#' @param show_after Show progress bar after this many seconds (default: 0)
#' @param force Whether to force progress bar even if not in terminal (default: FALSE)
#'
#' @return Progress bar ID (invisible)
#' @family progress
#'
#' @examplesIf interactive()
#' pb_id <- mysterycall_progress_bar("Processing", total = 10)
#' for (i in 1:10) mysterycall_progress_update(pb_id)
#' mysterycall_progress_done(pb_id)
#' @keywords internal
mysterycall_progress_bar <- function(name,
                                total,
                                format = NULL,
                                clear = FALSE,
                                show_after = 0,
                                force = FALSE) {

  make_pb_env <- function(...) {
    env <- list2env(list(...), parent = emptyenv())
    class(env) <- "mysterycall_progress"
    env
  }

  # Check if cli is available
  if (!requireNamespace("cli", quietly = TRUE)) {
    # Fallback to simple message-based progress
    message(sprintf("Starting: %s (%d items)", name, total))
    return(make_pb_env(name = name, total = total, current = 0L,
                       use_cli = FALSE, start_time = Sys.time()))
  }

  # Check if we should show progress bar
  show_progress <- force || (interactive() && cli::is_ansi_tty())

  if (!show_progress) {
    # Fallback to message-based progress
    message(sprintf("Starting: %s (%d items)", name, total))
    return(make_pb_env(name = name, total = total, current = 0L,
                       use_cli = FALSE, start_time = Sys.time()))
  }

  # Default format string
  if (is.null(format)) {
    format <- paste0(
      "{cli::pb_spin} {name} ",
      "{cli::pb_bar} ",
      "{cli::pb_current}/{cli::pb_total} ",
      "({cli::pb_percent}) ",
      "ETA: {cli::pb_eta}"
    )
  }

  # Create progress bar using cli
  pb_id <- cli::cli_progress_bar(
    name = name,
    total = total,
    format = format,
    clear = clear,
    show_after = show_after,
    .auto_close = FALSE
  )

  make_pb_env(id = pb_id, name = name, total = total, current = 0L,
              use_cli = TRUE, start_time = Sys.time())
}


#' Update progress bar
#'
#' Increments the progress bar by a specified amount and optionally updates the
#' status message.
#'
#' @param pb Progress bar object from \code{mysterycall_progress_bar()}.
#' @param amount Amount to increment (default: 1).
#' @param status Optional status message to display.
#' @param set Set to a specific absolute value instead of incrementing.
#'
#' @return `invisible(NULL)`.
#' @family progress
#' @examples
#' pb <- mysterycall:::mysterycall_progress_bar("Processing", total = 10)
#' for (i in seq_len(10)) mysterycall:::mysterycall_progress_update(pb)
#' mysterycall:::mysterycall_progress_done(pb)
#' @keywords internal
mysterycall_progress_update <- function(pb, amount = 1, status = NULL, set = NULL) {
  if (!inherits(pb, "mysterycall_progress")) {
    return(invisible(NULL))
  }

  if (pb$use_cli) {
    # Update with cli
    if (!is.null(set)) {
      cli::cli_progress_update(id = pb$id, set = set, status = status)
      pb$current <- set
    } else {
      cli::cli_progress_update(id = pb$id, inc = amount, status = status)
      pb$current <- pb$current + amount
    }
  } else {
    # Fallback: message-based progress (show every 10%)
    old_current <- pb$current
    if (!is.null(set)) {
      pb$current <- set
    } else {
      pb$current <- pb$current + amount
    }

    pct      <- if (pb$total > 0) round(pb$current  / pb$total * 100) else 0
    prev_pct <- if (pb$total > 0) round(old_current / pb$total * 100) else 0

    # Report every 10%
    if ((pct %/% 10) > (prev_pct %/% 10) || pb$current == pb$total) {
      elapsed <- as.numeric(difftime(Sys.time(), pb$start_time, units = "secs"))
      rate <- if (elapsed > 0) pb$current / elapsed else pb$current
      remaining_secs <- if (rate > 0) (pb$total - pb$current) / rate else 0
      eta_str <- mysterycall_format_duration(remaining_secs)

      message(sprintf("  Progress: %d/%d (%d%%) - ETA: %s",
                     pb$current, pb$total, pct, eta_str))
    }
  }

  invisible(NULL)
}


#' Complete progress bar
#'
#' Marks a progress bar as complete with an optional summary message.
#'
#' @param pb Progress bar object from \code{mysterycall_progress_bar()}.
#' @param result Optional result message to display on completion.
#' @param status Final status label (default: \code{"done"}).
#'
#' @return `invisible(NULL)`.
#' @family progress
#' @examples
#' pb <- mysterycall:::mysterycall_progress_bar("Processing", total = 5)
#' for (i in seq_len(5)) mysterycall:::mysterycall_progress_update(pb)
#' mysterycall:::mysterycall_progress_done(pb, result = "5 items processed")
#' @keywords internal
mysterycall_progress_done <- function(pb, result = NULL, status = "done") {
  if (!inherits(pb, "mysterycall_progress")) {
    return(invisible(NULL))
  }

  if (pb$use_cli) {
    cli::cli_progress_done(id = pb$id, result = result, .auto_close = TRUE)
  } else {
    # Fallback: completion message
    if (!is.null(result)) {
      message(sprintf("  \u2713 %s", result))
    } else {
      message(sprintf("  \u2713 %s complete", pb$name))
    }
  }

  invisible(NULL)
}


#' Fail progress bar
#'
#' Marks a progress bar as failed with an optional error message.
#'
#' @param pb Progress bar object from \code{mysterycall_progress_bar()}.
#' @param msg Optional error message string displayed alongside the failure.
#'
#' @return `invisible(NULL)`.
#' @family progress
#' @examples
#' pb <- mysterycall:::mysterycall_progress_bar("Processing", total = 10)
#' mysterycall:::mysterycall_progress_fail(pb, msg = "Geocoding API unreachable")
#' @keywords internal
mysterycall_progress_fail <- function(pb, msg = NULL) {
  if (!inherits(pb, "mysterycall_progress")) {
    return(invisible(NULL))
  }

  if (pb$use_cli) {
    if (!is.null(msg)) {
      cli::cli_progress_done(id = pb$id, result = "failed", .auto_close = TRUE)
      cli::cli_alert_danger(msg)
    } else {
      cli::cli_progress_done(id = pb$id, result = "failed", .auto_close = TRUE)
    }
  } else {
    # Fallback: error message
    if (!is.null(msg)) {
      message(sprintf("  \u2717 %s failed: %s", pb$name, msg))
    } else {
      message(sprintf("  \u2717 %s failed", pb$name))
    }
  }

  invisible(NULL)
}


#' Create a multi-step progress tracker
#'
#' Creates a progress tracker for workflows with multiple major steps.
#' Shows overall progress plus current step progress.
#'
#' @param steps Character vector of step names
#' @param show_overall Whether to show overall progress bar (default: TRUE)
#'
#' @return Multi-progress tracker object
#' @family progress
#'
#' @examplesIf interactive()
#' tracker <- mysterycall_multi_progress(c("Load Data", "Save"))
#' mysterycall_multi_step(tracker, 1, total = 5)
#' for (i in 1:5) mysterycall_multi_update(tracker)
#' mysterycall_multi_complete(tracker)
#' mysterycall_multi_done(tracker)
#' @keywords internal
mysterycall_multi_progress <- function(steps, show_overall = TRUE) {
  env <- new.env(parent = emptyenv())
  env$steps <- steps
  env$total_steps <- length(steps)
  env$current_step <- 0L
  env$show_overall <- show_overall
  env$overall_pb <- NULL
  env$step_pb <- NULL
  env$use_cli <- requireNamespace("cli", quietly = TRUE)
  class(env) <- "mysterycall_multi_progress"
  env
}


#' Start a step in multi-progress tracker
#'
#' Advances the multi-progress tracker to the given step and creates an inner
#' progress bar for that step's items.
#'
#' @param tracker Multi-progress tracker object from
#'   \code{mysterycall_multi_progress()}.
#' @param step_num Step number (1-based).
#' @param total Total number of items to process in this step.
#' @param detail Optional detail message shown beneath the step header.
#'
#' @return `invisible(NULL)`.
#' @family progress
#' @examples
#' tr <- mysterycall:::mysterycall_multi_progress(c("Geocode", "Validate"))
#' mysterycall:::mysterycall_multi_step(tr, 1, total = 10)
#' @keywords internal
mysterycall_multi_step <- function(tracker, step_num, total, detail = NULL) {
  if (!inherits(tracker, "mysterycall_multi_progress")) {
    return(invisible(NULL))
  }

  if (step_num < 1L || step_num > tracker$total_steps) {
    stop(sprintf("step_num %d is out of range (1-%d).", step_num, tracker$total_steps), call. = FALSE)
  }

  tracker$current_step <- step_num
  step_name <- tracker$steps[step_num]

  # Show step header
  if (tracker$use_cli) {
    cli::cli_h2(sprintf("Step %d/%d: %s", step_num, tracker$total_steps, step_name))
    if (!is.null(detail)) {
      cli::cli_text(detail)
    }
  } else {
    message(sprintf("\n\u25B6 Step %d/%d: %s", step_num, tracker$total_steps, step_name))
    if (!is.null(detail)) {
      message(sprintf("  %s", detail))
    }
  }

  # Create step progress bar
  tracker$step_pb <- mysterycall_progress_bar(
    name = step_name,
    total = total,
    clear = FALSE
  )

  invisible(NULL)
}


#' Update current step in multi-progress tracker
#'
#' Increments the inner progress bar for the current step.
#'
#' @param tracker Multi-progress tracker object from
#'   \code{mysterycall_multi_progress()}.
#' @param amount Amount to increment (default: 1).
#' @param status Optional status message to display.
#'
#' @return `invisible(NULL)`.
#' @family progress
#' @examples
#' tr <- mysterycall:::mysterycall_multi_progress(c("Geocode", "Validate"))
#' mysterycall:::mysterycall_multi_step(tr, 1, total = 5)
#' for (i in seq_len(5)) mysterycall:::mysterycall_multi_update(tr)
#' @keywords internal
mysterycall_multi_update <- function(tracker, amount = 1, status = NULL) {
  if (!inherits(tracker, "mysterycall_multi_progress")) {
    return(invisible(NULL))
  }

  if (!is.null(tracker$step_pb)) {
    mysterycall_progress_update(tracker$step_pb, amount = amount, status = status)
  }

  invisible(NULL)
}


#' Complete current step in multi-progress tracker
#'
#' @param tracker Multi-progress tracker object
#' @param result Optional result message
#'
#' @return `invisible(NULL)`.
#' @examplesIf interactive()
#' tracker <- mysterycall_multi_progress(c("Geocode", "Validate"))
#' mysterycall_multi_step(tracker, 1, total = 5)
#' mysterycall_multi_complete(tracker, result = "ok")
#' @family progress
#' @keywords internal
mysterycall_multi_complete <- function(tracker, result = NULL) {
  if (!inherits(tracker, "mysterycall_multi_progress")) {
    return(invisible(NULL))
  }

  if (!is.null(tracker$step_pb)) {
    mysterycall_progress_done(tracker$step_pb, result = result)
    tracker$step_pb <- NULL
  }

  invisible(NULL)
}


#' Complete multi-step tracker
#'
#' @param tracker Multi-progress tracker object
#'
#' @return `invisible(NULL)`.
#' @examplesIf interactive()
#' tracker <- mysterycall_multi_progress(c("Geocode", "Validate"))
#' mysterycall_multi_done(tracker)
#' @family progress
#' @keywords internal
mysterycall_multi_done <- function(tracker) {
  if (!inherits(tracker, "mysterycall_multi_progress")) {
    return(invisible(NULL))
  }

  if (tracker$use_cli) {
    cli::cli_alert_success("All steps complete!")
  } else {
    message("\n  \u2713 All steps complete!")
  }

  invisible(NULL)
}


#' Create a progress bar for batch processing
#'
#' Convenience wrapper for processing items in batches with automatic progress
#' updates and ETA calculations.
#'
#' @param items Vector of items to process
#' @param fn Function to apply to each item
#' @param name Name of operation (default: "Processing items")
#' @param batch_size Show progress every N items (default: 1, or max(1, length(items) / 100))
#' @param parallel Whether processing is parallel (affects ETA calculation)
#'
#' @return List of results from fn
#' @family progress
#'
#' @examplesIf interactive()
#' results <- mysterycall_progress_map(
#'   items = 1:10,
#'   fn    = function(x) x^2,
#'   name  = "Computing squares"
#' )
#' @keywords internal
mysterycall_progress_map <- function(items,
                                fn,
                                name = "Processing items",
                                batch_size = NULL,
                                parallel = FALSE) {

  n <- length(items)

  # Auto-calculate batch size if not provided
  if (is.null(batch_size)) {
    batch_size <- max(1, floor(n / 100))  # Update ~100 times
  }

  # Create progress bar
  pb <- mysterycall_progress_bar(name = name, total = n)

  # Process items (use single-bracket assignment to preserve NULL elements)
  results <- vector("list", length = n)
  for (i in seq_along(items)) {
    results[i] <- list(fn(items[[i]]))

    # Update progress bar
    if (i %% batch_size == 0 || i == n) {
      mysterycall_progress_update(pb, set = i)
    }
  }

  # Complete
  mysterycall_progress_done(pb, result = sprintf("Processed %d items", n))

  return(results)
}


#' Show a spinner for indeterminate operations
#'
#' Shows an animated spinner for operations where total is unknown.
#'
#' @param name Operation name
#' @param msg Optional message to display
#'
#' @return Spinner ID (a `cli` progress bar ID, or `NULL` if cli is unavailable).
#' @family progress
#' @examplesIf interactive()
#' id <- mysterycall_spinner_start("Loading data")
#' mysterycall_spinner_stop(id)
#' @keywords internal
mysterycall_spinner_start <- function(name, msg = NULL) {
  if (requireNamespace("cli", quietly = TRUE) && cli::is_ansi_tty()) {
    if (is.null(msg)) {
      msg <- sprintf("Working on: %s", name)
    }
    id <- cli::cli_progress_bar(
      name = name,
      total = NA,
      format = paste0("{cli::pb_spin} ", msg)
    )
    return(id)
  } else {
    message(sprintf("  \u21BB %s...", name))
    return(NULL)
  }
}


#' Stop a spinner
#'
#' @param id Spinner ID from mysterycall_spinner_start()
#' @param result Result message
#'
#' @return `invisible(NULL)`
#' @family progress
#' @examplesIf interactive()
#' id <- mysterycall_spinner_start("Loading data")
#' mysterycall_spinner_stop(id, result = "done")
#' @keywords internal
mysterycall_spinner_stop <- function(id, result = "done") {
  if (!is.null(id) && requireNamespace("cli", quietly = TRUE)) {
    cli::cli_progress_done(id = id, result = result)
  }
  invisible(NULL)
}
