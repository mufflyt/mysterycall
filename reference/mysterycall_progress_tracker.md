# Progress tracker for long-running workflows

Provides reusable helpers for emitting periodic progress updates across
multi-stage workflows such as the end-to-end mystery caller pipeline.
The tracker keeps a method-by-method breakdown, surfaces estimated
completion times, and exposes convenience helpers for recording
failures.

## Usage

``` r
mysterycall_progress_tracker(
  steps,
  update_every = 300,
  quiet = getOption("mysterycall.quiet", FALSE)
)
```

## Arguments

- steps:

  Character vector naming each discrete method or stage.

- update_every:

  Number of seconds between automatic status updates. The default (300
  seconds) produces five-minute summaries.

- quiet:

  Logical flag controlling console output. When `TRUE`, suppresses
  status messages.

## Value

An S3 object of class `"mysterycall_progress_tracker"` wrapping an
internal environment. The environment holds a `records` tibble with
columns `step`, `status` (factor: `"pending"`, `"in_progress"`,
`"completed"`, `"failed"`), `started_at`, `finished_at` (POSIXct),
`quality` (character), and `note` (character). Interact with it via
[`mysterycall_progress_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_start.md),
[`mysterycall_progress_finish()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_finish.md),
and
[`mysterycall_progress_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_summary.md).

## See also

Other logging:
[`mysterycall_format_duration()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_format_duration.md),
[`mysterycall_log_cache_hit()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_cache_hit.md),
[`mysterycall_log_error()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_error.md),
[`mysterycall_log_info()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_info.md),
[`mysterycall_log_progress()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_progress.md),
[`mysterycall_log_save()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_save.md),
[`mysterycall_log_step()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_step.md),
[`mysterycall_log_step_complete()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_step_complete.md),
[`mysterycall_log_success()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_success.md),
[`mysterycall_log_to_file()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_to_file.md),
[`mysterycall_log_warning()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_log_warning.md),
[`mysterycall_progress_callback()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_callback.md),
[`mysterycall_progress_finish()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_finish.md),
[`mysterycall_progress_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_start.md),
[`mysterycall_progress_summary()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_progress_summary.md),
[`mysterycall_tracker_fail()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tracker_fail.md),
[`mysterycall_tracker_update()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_tracker_update.md),
[`mysterycall_use_quiet_logging()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_use_quiet_logging.md),
[`mysterycall_workflow_end()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_workflow_end.md),
[`mysterycall_workflow_start()`](https://mufflyt.github.io/mysterycall/reference/mysterycall_workflow_start.md)

## Examples

``` r
tracker <- mysterycall:::mysterycall_progress_tracker(c("Geocode", "Validate", "Export"))
mysterycall:::mysterycall_progress_start(tracker, "Geocode")
#> [15:13:49] Started Geocode
#> [15:13:49] Progress: 0/3 steps complete (0.0%)
Sys.sleep(1)
mysterycall:::mysterycall_progress_finish(tracker, "Geocode", score = 0.95)
#> [15:13:50] Completed Geocode (high)
#> [15:13:50] Progress: 1/3 steps complete (33.3%) - ETA 15:13:52
```
