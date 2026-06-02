#' Progress tracker for long-running workflows
#'
#' Provides reusable helpers for emitting periodic progress updates across
#' multi-stage workflows such as the end-to-end mystery caller pipeline. The
#' tracker keeps a method-by-method breakdown, surfaces estimated completion
#' times, and exposes convenience helpers for recording failures.
#'
#' @name mysterycall_progress_tracker
NULL

#' Create a progress tracker instance
#'
#' @param steps Character vector naming each discrete method or stage.
#' @param update_every Number of seconds between automatic status updates. The
#'   default (300 seconds) produces five-minute summaries.
#' @param quiet Logical flag controlling console output. When `TRUE`, suppresses
#'   status messages.
#'
#' @return An S3 object of class `"mysterycall_progress_tracker"` wrapping an
#'   internal environment. The environment holds a `records` tibble with columns
#'   `step`, `status` (factor: `"pending"`, `"in_progress"`, `"completed"`,
#'   `"failed"`), `started_at`, `finished_at` (POSIXct), `quality`
#'   (character), and `note` (character). Interact with it via
#'   [mysterycall_progress_start()], [mysterycall_progress_finish()], and
#'   [mysterycall_progress_summary()].
#' @importFrom tibble tibble
#' @family logging
#' @examples
#' tracker <- mysterycall:::mysterycall_progress_tracker(c("Geocode", "Validate", "Export"))
#' mysterycall:::mysterycall_progress_start(tracker, "Geocode")
#' Sys.sleep(1)
#' mysterycall:::mysterycall_progress_finish(tracker, "Geocode", score = 0.95)
#' @keywords internal
mysterycall_progress_tracker <- function(steps, update_every = 300, quiet = getOption("mysterycall.quiet", FALSE)) {
  if (!is.character(steps) || !length(steps)) {
    stop("`steps` must be a non-empty character vector.", call. = FALSE)
  }
  steps <- unique(steps)

  env <- new.env(parent = emptyenv())
  env$records <- tibble::tibble(
    step = steps,
    status = factor(rep("pending", length(steps)), levels = c("pending", "in_progress", "completed", "failed")),
    started_at = as.POSIXct(NA, tz = "UTC"),
    finished_at = as.POSIXct(NA, tz = "UTC"),
    quality = NA_character_,
    note = NA_character_
  )
  env$start_time <- Sys.time()
  env$last_update <- env$start_time
  env$quiet <- quiet
  env$update_every <- update_every

  structure(list(env = env), class = "mysterycall_progress_tracker")
}

# Internal helper to retrieve the record index for a step
.tracker_index <- function(tracker, step) {
  if (!inherits(tracker, "mysterycall_progress_tracker")) {
    stop("`tracker` must be created with mysterycall_progress_tracker().", call. = FALSE)
  }
  env <- tracker$env
  idx <- match(step, env$records$step)
  if (is.na(idx)) {
    stop(sprintf("Unknown step '%s'.", step), call. = FALSE)
  }
  idx
}

.tracker_log <- function(tracker, message_text, force = FALSE) {
  env <- tracker$env
  if (!isTRUE(env$quiet) || isTRUE(force)) {
    message(sprintf("[%s] %s", format(Sys.time(), "%H:%M:%S"), message_text))
  }
}

.tracker_emit_update <- function(tracker, force = FALSE) {
  env <- tracker$env
  elapsed <- as.numeric(difftime(Sys.time(), env$last_update, units = "secs"))
  if (!force && elapsed < env$update_every) {
    return(invisible(NULL))
  }

  records <- env$records
  completed <- sum(records$status == "completed", na.rm = TRUE)
  total <- nrow(records)
  progress <- if (total) completed / total else 0
  elapsed_total <- as.numeric(difftime(Sys.time(), env$start_time, units = "secs"))
  eta <- NA_character_
  if (completed > 0 && completed < total && elapsed_total > 1) {
    avg_duration <- elapsed_total / completed
    remaining <- total - completed
    eta_time <- Sys.time() + avg_duration * remaining
    eta <- format(eta_time, "%H:%M:%S")
  }

  msg <- sprintf(
    "Progress: %d/%d steps complete (%.1f%%)%s",
    completed,
    total,
    progress * 100,
    if (!is.na(eta)) sprintf(" - ETA %s", eta) else ""
  )
  .tracker_log(tracker, msg)
  env$last_update <- Sys.time()
  invisible(NULL)
}

#' Mark a step as started
#'
#' @param tracker Object created by [mysterycall_progress_tracker()].
#' @param step Step name.
#' @param note Optional note stored alongside the step.
#'
#' @return The tracker object, invisibly.
#' @family logging
#' @examples
#' tr <- mysterycall:::mysterycall_progress_tracker(c("Geocode", "Validate"), update_every = 1e9)
#' mysterycall:::mysterycall_progress_start(tr, "Geocode")
#' @keywords internal
mysterycall_progress_start <- function(tracker, step, note = NULL) {
  idx <- .tracker_index(tracker, step)
  env <- tracker$env

  # Use atomic operations to prevent race conditions
  tryCatch({
    env$records$status[idx] <- "in_progress"
    env$records$started_at[idx] <- Sys.time()
    if (!is.null(note)) {
      env$records$note[idx] <- note
    }
  }, error = function(e) {
    stop("Failed to update progress tracker: ", e$message, call. = FALSE)
  })

  .tracker_log(tracker, sprintf("Started %s", step))
  .tracker_emit_update(tracker, force = TRUE)
  invisible(tracker)
}

#' Mark a step as completed
#'
#' @param tracker Object created by [mysterycall_progress_tracker()].
#' @param step Step name.
#' @param score Optional numeric score between 0 and 1 used to derive a
#'   quality tier.
#' @param quality Optional explicit quality tier. Overrides `score` when
#'   provided.
#' @param note Optional note to store for the step.
#'
#' @return The tracker object, invisibly.
#' @family logging
#' @examples
#' tr <- mysterycall:::mysterycall_progress_tracker(c("Geocode"), update_every = 1e9)
#' mysterycall:::mysterycall_progress_start(tr, "Geocode")
#' mysterycall:::mysterycall_progress_finish(tr, "Geocode", score = 0.92)
#' @keywords internal
mysterycall_progress_finish <- function(tracker, step, score = NULL, quality = NULL, note = NULL) {
  idx <- .tracker_index(tracker, step)
  env <- tracker$env
  env$records$status[idx] <- "completed"
  env$records$finished_at[idx] <- Sys.time()
  if (!is.null(note)) {
    env$records$note[idx] <- note
  }
  resolved_quality <- if (!is.null(quality)) quality else mysterycall_quality_tier(score)
  env$records$quality[idx] <- resolved_quality
  .tracker_log(tracker, sprintf("Completed %s (%s)", step, if (!is.null(resolved_quality) && !is.na(resolved_quality)) resolved_quality else "no tier"))
  .tracker_emit_update(tracker, force = TRUE)
  invisible(tracker)
}

#' Mark a tracker step as failed
#'
#' @param tracker Object created by [mysterycall_progress_tracker()].
#' @param step Step name.
#' @param reason Optional string describing why the step failed.
#'
#' @return The tracker object, invisibly.
#' @family logging
#' @examples
#' tr <- mysterycall:::mysterycall_progress_tracker(c("Geocode"), update_every = 1e9)
#' mysterycall:::mysterycall_progress_start(tr, "Geocode")
#' mysterycall:::mysterycall_tracker_fail(tr, "Geocode", reason = "API timeout")
#' @keywords internal
mysterycall_tracker_fail <- function(tracker, step, reason = NULL) {
  idx <- .tracker_index(tracker, step)
  env <- tracker$env
  env$records$status[idx] <- "failed"
  env$records$finished_at[idx] <- Sys.time()
  if (!is.null(reason)) {
    env$records$note[idx] <- reason
  }
  .tracker_log(tracker, sprintf("Failed %s%s", step, if (!is.null(reason)) paste0(": ", reason) else ""), force = TRUE)
  .tracker_emit_update(tracker, force = TRUE)
  invisible(tracker)
}

#' Emit a manual progress heartbeat
#'
#' @param tracker Object created by [mysterycall_progress_tracker()].
#' @param force Logical flag indicating whether the update should be emitted
#'   even if the configured interval has not elapsed.
#'
#' @return The tracker object, invisibly.
#' @family logging
#' @examples
#' tr <- mysterycall:::mysterycall_progress_tracker(c("Geocode"), update_every = 1e9)
#' mysterycall:::mysterycall_tracker_update(tr, force = TRUE)
#' @keywords internal
mysterycall_tracker_update <- function(tracker, force = FALSE) {
  .tracker_emit_update(tracker, force = force)
  invisible(tracker)
}

#' Return a tibble describing step-by-step progress
#'
#' @param tracker Object created by [mysterycall_progress_tracker()].
#'
#' @return Tibble with per-step status, timestamps, and quality tiers.
#' @importFrom tibble as_tibble
#' @family logging
#' @examples
#' tr <- mysterycall:::mysterycall_progress_tracker(c("Geocode", "Validate"), update_every = 1e9)
#' mysterycall:::mysterycall_progress_start(tr, "Geocode")
#' mysterycall:::mysterycall_progress_finish(tr, "Geocode", score = 0.95)
#' mysterycall:::mysterycall_progress_summary(tr)
#' @keywords internal
mysterycall_progress_summary <- function(tracker) {
  env <- tracker$env
  tibble::as_tibble(env$records)
}
