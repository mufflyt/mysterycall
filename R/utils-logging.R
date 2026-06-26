#' Comprehensive Logging Utilities for mysterycall
#'
#' Provides plain-language logging with progress tracking, timing, and
#' user-friendly output for long-running workflows.
#'
#' @return No return value. Documentation topic grouping related functions; see
#'   each function's own help page for its return value.
#' @examples
#' # Topic group; see individual function help pages for runnable examples.
#' NULL
#' @name logging-utils
#' @seealso [mysterycall_run_workflow_logged()],
#'   [mysterycall_preflight_check()], [mysterycall_multi_progress()]
NULL

# Global environment for tracking workflow state
.mysterycall_workflow <- new.env(parent = emptyenv())

#' Initialize workflow tracking
#'
#' @param workflow_name Name of the workflow (e.g., "Mystery Caller Workflow")
#' @param total_steps Total number of major steps
#' @param log_file Optional path to log file for persistent logging
#' @return `invisible(NULL)`; initializes internal workflow state and prints a
#'   workflow header to the console.
#' @family logging
#' @examples
#' mysterycall:::mysterycall_workflow_start("Demo Workflow", total_steps = 3)
#' @keywords internal
mysterycall_workflow_start <- function(workflow_name, total_steps = NULL, log_file = NULL) {
  .mysterycall_workflow$name <- workflow_name
  .mysterycall_workflow$start_time <- Sys.time()
  .mysterycall_workflow$total_steps <- total_steps
  .mysterycall_workflow$current_step <- 0
  .mysterycall_workflow$log_file <- log_file
  .mysterycall_workflow$step_results <- list()

  # Header
  message(strrep("=", 60))
  message(sprintf("  %s", workflow_name))
  message(sprintf("  Started: %s", format(.mysterycall_workflow$start_time, "%Y-%m-%d %H:%M:%S")))
  if (!is.null(total_steps)) {
    message(sprintf("  Total Steps: %d", total_steps))
  }
  message(strrep("=", 60))
  message("")

  # Write to log file if specified
  if (!is.null(log_file)) {
    dir.create(dirname(log_file), showWarnings = FALSE, recursive = TRUE)
    writeLines(c(
      strrep("=", 60),
      sprintf("Workflow: %s", workflow_name),
      sprintf("Started: %s", format(.mysterycall_workflow$start_time, "%Y-%m-%d %H:%M:%S")),
      strrep("=", 60),
      ""
    ), log_file)
  }

  invisible(NULL)
}

#' Log a step start
#'
#' @param step_name Name of the step
#' @param detail Optional additional details
#' @param n_items Number of items to process (for progress tracking)
#' @return `invisible(NULL)`; updates the internal step counter and emits a
#'   formatted step header to the console.
#' @family logging
#' @examples
#' mysterycall:::mysterycall_workflow_start("Demo", total_steps = 2)
#' mysterycall:::mysterycall_log_step("Step 1: Geocode", n_items = 50)
#' @keywords internal
mysterycall_log_step <- function(step_name, detail = NULL, n_items = NULL) {
  if (exists("current_step", envir = .mysterycall_workflow)) {
    .mysterycall_workflow$current_step <- .mysterycall_workflow$current_step + 1
  } else {
    .mysterycall_workflow$current_step <- 1
  }

  step_num <- .mysterycall_workflow$current_step
  total_steps <- .mysterycall_workflow$total_steps

  # Format step header
  if (!is.null(total_steps)) {
    header <- sprintf("\u25B6 Step %d/%d: %s", step_num, total_steps, step_name)
  } else {
    header <- sprintf("\u25B6 Step %d: %s", step_num, step_name)
  }

  message(header)

  if (!is.null(detail)) {
    message(sprintf("  %s", detail))
  }

  if (!is.null(n_items)) {
    message(sprintf("  Processing %s item(s)...", format(n_items, big.mark = ",")))
  }

  # Store step start time
  .mysterycall_workflow$step_results[[as.character(step_num)]] <- list(
    name = step_name,
    start_time = Sys.time(),
    n_items = n_items
  )

  mysterycall_log_to_file(header)
  if (!is.null(detail)) mysterycall_log_to_file(sprintf("  %s", detail))

  invisible(NULL)
}

#' Log informational message
#'
#' @param msg Message to log
#' @param indent Whether to indent (default TRUE)
#' @return `invisible(NULL)`.
#' @family logging
#' @examples
#' mysterycall:::mysterycall_log_info("Loading provider data")
#' @keywords internal
mysterycall_log_info <- function(msg, indent = TRUE) {
  formatted <- if (indent) sprintf("  \u2139 %s", msg) else sprintf("\u2139 %s", msg)
  message(formatted)
  mysterycall_log_to_file(formatted)
  invisible(NULL)
}

#' Log success message
#'
#' @param msg Message to log
#' @param details Optional named list of additional key-value details to print.
#' @param indent Whether to indent (default TRUE)
#' @return `invisible(NULL)`.
#' @family logging
#' @examples
#' mysterycall:::mysterycall_log_success("Geocoding complete", details = list(n = 120, skipped = 3))
#' @keywords internal
mysterycall_log_success <- function(msg, details = NULL, indent = TRUE) {
  formatted <- if (indent) sprintf("  \u2713 %s", msg) else sprintf("\u2713 %s", msg)
  message(formatted)
  mysterycall_log_to_file(formatted)

  if (!is.null(details)) {
    for (name in names(details)) {
      detail_line <- sprintf("    - %s: %s", name, details[[name]])
      message(detail_line)
      mysterycall_log_to_file(detail_line)
    }
  }

  invisible(NULL)
}

#' Log warning message
#'
#' @param msg Warning message
#' @param fix Optional one-line suggested remediation.
#' @param indent Whether to indent (default TRUE)
#' @return `invisible(NULL)`.
#' @family logging
#' @examples
#' mysterycall:::mysterycall_log_warning("Missing API key", fix = "Set GOOGLE_API_KEY env var")
#' @keywords internal
mysterycall_log_warning <- function(msg, fix = NULL, indent = TRUE) {
  formatted <- if (indent) sprintf("  \u26A0 WARNING: %s", msg) else sprintf("\u26A0 WARNING: %s", msg)
  message(formatted)
  mysterycall_log_to_file(formatted)

  if (!is.null(fix)) {
    fix_line <- sprintf("    Fix: %s", fix)
    message(fix_line)
    mysterycall_log_to_file(fix_line)
  }

  invisible(NULL)
}

#' Log error message with context
#'
#' @param msg Error message
#' @param cause Root cause of error
#' @param fix Suggested fix
#' @param indent Whether to indent (default TRUE)
#' @return `invisible(NULL)`.
#' @family logging
#' @examples
#' mysterycall:::mysterycall_log_error(
#'   "Geocode failed",
#'   cause = "API key missing",
#'   fix = "Set google_maps_api_key"
#' )
#' @keywords internal
mysterycall_log_error <- function(msg, cause = NULL, fix = NULL, indent = TRUE) {
  formatted <- if (indent) sprintf("  \u2717 ERROR: %s", msg) else sprintf("\u2717 ERROR: %s", msg)
  message(formatted)
  mysterycall_log_to_file(formatted)

  if (!is.null(cause)) {
    cause_line <- sprintf("    Cause: %s", cause)
    message(cause_line)
    mysterycall_log_to_file(cause_line)
  }

  if (!is.null(fix)) {
    fix_line <- sprintf("    Fix: %s", fix)
    message(fix_line)
    mysterycall_log_to_file(fix_line)
  }

  invisible(NULL)
}

#' Log progress for batch operations
#'
#' @param current Current item number
#' @param total Total items
#' @param status Optional status message
#' @param show_percent Whether to show percentage (default TRUE)
#' @return `invisible(NULL)`.
#' @family logging
#' @examples
#' mysterycall:::mysterycall_log_progress(50, 100)
#' mysterycall:::mysterycall_log_progress(50, 100, status = "geocoding")
#' @keywords internal
mysterycall_log_progress <- function(current, total, status = NULL, show_percent = TRUE) {
  pct <- if (total > 0) round(current / total * 100, 1) else 0

  if (show_percent) {
    if (!is.null(status)) {
      msg <- sprintf("  \u25B8 Progress: %d/%d (%.1f%%) - %s", current, total, pct, status)
    } else {
      msg <- sprintf("  \u25B8 Progress: %d/%d (%.1f%%)", current, total, pct)
    }
  } else {
    if (!is.null(status)) {
      msg <- sprintf("  \u25B8 Progress: %d/%d - %s", current, total, status)
    } else {
      msg <- sprintf("  \u25B8 Progress: %d/%d", current, total)
    }
  }

  message(msg)
  mysterycall_log_to_file(msg)
  invisible(NULL)
}

#' Log cache hit
#'
#' @param what What was loaded from cache
#' @param n_items Number of cached items
#' @return `invisible(NULL)`.
#' @family logging
#' @examples
#' mysterycall:::mysterycall_log_cache_hit("geocode results", 250)
#' @keywords internal
mysterycall_log_cache_hit <- function(what, n_items) {
  msg <- sprintf("  \u21BB Loaded %s from cache (%s item(s))",
                 what,
                 format(n_items, big.mark = ","))
  message(msg)
  mysterycall_log_to_file(msg)
  invisible(NULL)
}

#' Log file save
#'
#' @param path File path
#' @param n_rows Number of rows (optional)
#' @return `invisible(NULL)`.
#' @family logging
#' @examples
#' mysterycall:::mysterycall_log_save(tempfile(fileext = ".csv"), n_rows = 42)
#' @keywords internal
mysterycall_log_save <- function(path, n_rows = NULL) {
  if (!is.null(n_rows)) {
    msg <- sprintf("  \U0001F4BE Saved to: %s (%s rows)",
                   path,
                   format(n_rows, big.mark = ","))
  } else {
    msg <- sprintf("  \U0001F4BE Saved to: %s", path)
  }
  message(msg)
  mysterycall_log_to_file(msg)
  invisible(NULL)
}

#' Complete current step with timing
#'
#' @param success_rate Optional success rate (0-1)
#' @param n_success Number of successful items
#' @param n_total Total items attempted
#' @return `invisible(NULL)` after printing duration and optional success
#'   metrics for the current step.
#' @family logging
#' @examplesIf interactive()
#' mysterycall:::mysterycall_workflow_start("Demo", total_steps = 1)
#' mysterycall:::mysterycall_log_step("Step 1")
#' mysterycall:::mysterycall_log_step_complete(n_success = 90, n_total = 100)
#' @keywords internal
mysterycall_log_step_complete <- function(success_rate = NULL, n_success = NULL, n_total = NULL) {
  step_num <- .mysterycall_workflow$current_step
  step_info <- .mysterycall_workflow$step_results[[as.character(step_num)]]

  if (!is.null(step_info)) {
    duration <- as.numeric(difftime(Sys.time(), step_info$start_time, units = "secs"))
    duration_str <- mysterycall_format_duration(duration)

    if (!is.null(success_rate)) {
      pct <- round(success_rate * 100, 1)
      msg <- sprintf("  \u2713 Step complete: %.1f%% success in %s", pct, duration_str)
    } else if (!is.null(n_success) && !is.null(n_total)) {
      pct <- if (n_total > 0) round(n_success / n_total * 100, 1) else 0
      msg <- sprintf("  \u2713 Step complete: %d/%d (%.1f%%) in %s",
                     n_success, n_total, pct, duration_str)
    } else {
      msg <- sprintf("  \u2713 Step complete in %s", duration_str)
    }

    message(msg)
    message("")  # Blank line after step
    mysterycall_log_to_file(msg)
    mysterycall_log_to_file("")

    # Store completion info
    step_info$end_time <- Sys.time()
    step_info$duration <- duration
    step_info$success_rate <- success_rate
    step_info$n_success <- n_success
    step_info$n_total <- n_total
    .mysterycall_workflow$step_results[[as.character(step_num)]] <- step_info
  }

  invisible(NULL)
}

#' End workflow and print summary
#'
#' @param final_n Number of final output rows
#' @param input_n Number of input rows
#' @return `invisible(NULL)`.
#' @family logging
#' @examplesIf interactive()
#' mysterycall:::mysterycall_workflow_start("Demo", total_steps = 1)
#' mysterycall:::mysterycall_workflow_end(final_n = 80, input_n = 100)
#' @keywords internal
mysterycall_workflow_end <- function(final_n = NULL, input_n = NULL) {
  if (is.null(.mysterycall_workflow$start_time)) {
    return(invisible(NULL))
  }
  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, .mysterycall_workflow$start_time, units = "secs"))
  duration_str <- mysterycall_format_duration(duration)
  workflow_name <- if (!is.null(.mysterycall_workflow$name)) .mysterycall_workflow$name else "Workflow"

  message("")
  message(strrep("=", 60))
  message(sprintf("  %s - COMPLETE", workflow_name))
  message(strrep("=", 60))
  message("")

  if (!is.null(final_n) && !is.null(input_n) && input_n > 0) {
    pct <- round(final_n / input_n * 100, 1)
    message(sprintf("  Input:  %s records", format(input_n, big.mark = ",")))
    message(sprintf("  Output: %s records (%.1f%%)", format(final_n, big.mark = ","), pct))
    message("")
  }

  # Print step summary
  if (length(.mysterycall_workflow$step_results) > 0) {
    message("  Step Summary:")
    for (step_num in seq_along(.mysterycall_workflow$step_results)) {
      step <- .mysterycall_workflow$step_results[[step_num]]
      if (!is.null(step$duration)) {
        step_dur <- mysterycall_format_duration(step$duration)
        if (!is.null(step$success_rate)) {
          pct <- round(step$success_rate * 100, 1)
          message(sprintf("    %d. %s: %.1f%% success in %s",
                         step_num, step$name, pct, step_dur))
        } else if (!is.null(step$n_success) && !is.null(step$n_total) && step$n_total > 0) {
          pct <- round(step$n_success / step$n_total * 100, 1)
          message(sprintf("    %d. %s: %d/%d (%.1f%%) in %s",
                         step_num, step$name, step$n_success, step$n_total, pct, step_dur))
        } else {
          message(sprintf("    %d. %s: %s", step_num, step$name, step_dur))
        }
      }
    }
    message("")
  }

  message(sprintf("  Total Duration: %s", duration_str))
  message(sprintf("  Completed: %s", format(end_time, "%Y-%m-%d %H:%M:%S")))
  message("")
  message(strrep("=", 60))

  # Write to log file
  if (!is.null(.mysterycall_workflow$log_file)) {
    log_lines <- c(
      "",
      strrep("=", 60),
      "WORKFLOW COMPLETE",
      strrep("=", 60),
      sprintf("Total Duration: %s", duration_str),
      sprintf("Completed: %s", format(end_time, "%Y-%m-%d %H:%M:%S")),
      strrep("=", 60)
    )
    for (ln in log_lines) mysterycall_log_to_file(ln)
  }

  invisible(NULL)
}

#' Format duration in human-readable form
#'
#' @param seconds Duration in seconds
#' @return Formatted string (e.g., "2h 34m 15s")
#' @family logging
#' @examples
#' mysterycall:::mysterycall_format_duration(45)
#' mysterycall:::mysterycall_format_duration(125)
#' mysterycall:::mysterycall_format_duration(3700)
#' @keywords internal
mysterycall_format_duration <- function(seconds) {
  if (seconds < 60) {
    return(sprintf("%.1fs", seconds))
  } else if (seconds < 3600) {
    mins <- floor(seconds / 60)
    secs <- round(seconds %% 60)
    return(sprintf("%dm %ds", mins, secs))
  } else {
    hours <- floor(seconds / 3600)
    mins <- floor((seconds %% 3600) / 60)
    secs <- round(seconds %% 60)
    return(sprintf("%dh %dm %ds", hours, mins, secs))
  }
}

#' Write to log file if configured
#'
#' @param msg Message to write
#' @return `invisible(NULL)`.
#' @family logging
#' @keywords internal
mysterycall_log_to_file <- function(msg) {
  if (!is.null(.mysterycall_workflow$log_file)) {
    # Remove ANSI codes and special characters for file logging
    clean_msg <- gsub("\u2713|\u2717|\u26A0|\u2139|\u25B6|\u25B8|\u21BB|\U0001F4BE", "", msg)
    lock_path <- paste0(.mysterycall_workflow$log_file, ".lock")
    lock_acquired <- FALSE
    for (i in seq_len(100)) {
      lock_acquired <- dir.create(lock_path, showWarnings = FALSE)
      if (lock_acquired) break
      Sys.sleep(0.01)
    }
    if (!lock_acquired) {
      # Stale-lock detection: a lock directory older than 30 s indicates a prior
      # crash. Remove it and retry once rather than stopping the workflow.
      lock_mtime <- tryCatch(file.info(lock_path)$mtime, error = function(e) NA)
      if (!is.na(lock_mtime) &&
          as.numeric(difftime(Sys.time(), lock_mtime, units = "secs")) > 30) {
        unlink(lock_path, recursive = TRUE, force = TRUE)
        lock_acquired <- dir.create(lock_path, showWarnings = FALSE)
      }
    }
    if (!lock_acquired) {
      warning("Could not acquire log file lock; skipping file log write: ",
              .mysterycall_workflow$log_file, call. = FALSE)
      return(invisible(NULL))
    }
    on.exit(unlink(lock_path, recursive = TRUE, force = TRUE), add = TRUE)
    write(clean_msg, file = .mysterycall_workflow$log_file, append = TRUE)
  }
  invisible(NULL)
}

#' Create a simple progress callback for batch operations
#'
#' @param total Total number of items
#' @param label Label for progress messages
#' @return A function that updates progress
#' @family logging
#'
#' @examples
#' \donttest{
#' progress <- mysterycall:::mysterycall_progress_callback(100, "Processing")
#' for (i in 1:100) {
#'   # do work
#'   progress(i)
#' }
#' }
#' @keywords internal
mysterycall_progress_callback <- function(total, label = "Processing") {
  last_reported <- 0
  start_time <- Sys.time()

  function(current) {
    if (total == 0) return(invisible(NULL))
    # Report every 10% or on last item
    pct <- current / total
    should_report <- (pct - last_reported >= 0.1) || (current == total)

    if (should_report) {
      elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      if (elapsed > 0.1 && current > 0) {
        rate <- current / elapsed
        remaining <- (total - current) / rate
        status_str <- sprintf("%s | ETA: %s", label, mysterycall_format_duration(remaining))
      } else {
        status_str <- label
      }
      mysterycall_log_progress(current, total, status_str)
      last_reported <<- pct
    }
  }
}


#' Toggle quiet logging for helper functions
#'
#' @param quiet Logical flag. When `TRUE`, suppress messages emitted by
#'   `mysterycall_log_info()` when using quiet-aware wrappers.
#'
#' @return The previous quiet value (invisibly).
#' @family logging
#' @examples
#' old <- mysterycall:::mysterycall_use_quiet_logging(TRUE)
#' # ... run operations silently ...
#' mysterycall:::mysterycall_use_quiet_logging(old)
#' @keywords internal
mysterycall_use_quiet_logging <- function(quiet = TRUE) {
  old <- getOption("mysterycall.quiet", FALSE)
  options(mysterycall.quiet = quiet)
  invisible(old)
}
